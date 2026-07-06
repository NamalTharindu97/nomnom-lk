package handlers

import (
	"fmt"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/dto/request"
	"github.com/nomnom-lk/backend/internal/middleware"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/nomnom-lk/backend/internal/services"
	"github.com/nomnom-lk/backend/pkg/pagination"
	"github.com/nomnom-lk/backend/pkg/response"
)

type rateLimiter struct {
	mu       sync.Mutex
	attempts map[string]time.Time
}

func (rl *rateLimiter) Allow(key string, interval time.Duration) bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()
	last, ok := rl.attempts[key]
	now := time.Now()
	if ok && now.Sub(last) < interval {
		return false
	}
	rl.attempts[key] = now
	return true
}

var pushRateLimiter = &rateLimiter{attempts: make(map[string]time.Time)}

type NotificationHandler struct {
	service        *services.NotificationService
	scheduledRepo  *repository.ScheduledNotificationRepo
	auditService   *services.AuditService
}

func NewNotificationHandler(service *services.NotificationService, auditService *services.AuditService) *NotificationHandler {
	return &NotificationHandler{
		service:      service,
		auditService: auditService,
	}
}

func (h *NotificationHandler) SetScheduledRepo(repo *repository.ScheduledNotificationRepo) {
	h.scheduledRepo = repo
}

func (h *NotificationHandler) RegisterDevice(c *gin.Context) {
	var req request.RegisterDeviceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	userID, _ := middleware.GetUserID(c)

	if err := h.service.RegisterDevice(userID, req.Token, req.Platform); err != nil {
		response.InternalError(c, "failed to register device")
		return
	}

	response.Success(c, gin.H{"message": "device registered"})
}

func (h *NotificationHandler) UnregisterDevice(c *gin.Context) {
	var req request.UnregisterDeviceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	userID, _ := middleware.GetUserID(c)

	if err := h.service.UnregisterDevice(userID, req.Token); err != nil {
		response.InternalError(c, "failed to unregister device")
		return
	}

	response.SuccessNoContent(c)
}

func (h *NotificationHandler) List(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)
	params := pagination.Extract(c)

	notifications, total, err := h.service.ListNotifications(userID, params)
	if err != nil {
		response.InternalError(c, "failed to list notifications")
		return
	}

	data := make([]gin.H, len(notifications))
	for i, n := range notifications {
		data[i] = gin.H{
			"id":         n.ID,
			"type":       n.Type,
			"title":      n.Title,
			"body":       n.Body,
			"data":       n.Data,
			"offer_id":   n.OfferID,
			"is_read":    n.IsRead,
			"created_at": n.CreatedAt,
		}
	}

	response.SuccessPaginated(c, data, pagination.Meta(params, total))
}

func (h *NotificationHandler) MarkAsRead(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid notification id"},
		})
		return
	}

	userID, _ := middleware.GetUserID(c)
	if err := h.service.MarkAsRead(id, userID); err != nil {
		response.InternalError(c, "failed to mark notification as read")
		return
	}

	response.SuccessNoContent(c)
}

func (h *NotificationHandler) MarkAllAsRead(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)
	if err := h.service.MarkAllAsRead(userID); err != nil {
		response.InternalError(c, "failed to mark all as read")
		return
	}

	response.SuccessNoContent(c)
}

func (h *NotificationHandler) UnreadCount(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)
	count, err := h.service.GetUnreadCount(userID)
	if err != nil {
		response.InternalError(c, "failed to get unread count")
		return
	}

	response.Success(c, gin.H{"unread_count": count})
}

func (h *NotificationHandler) SendPush(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)
	if !pushRateLimiter.Allow(userID.String(), 10*time.Second) {
		response.Error(c, 429, "rate_limit", "rate limit exceeded, try again later")
		return
	}

	var req request.SendPushRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	if req.ScheduleAt != "" {
		scheduledAt, err := time.Parse(time.RFC3339, req.ScheduleAt)
		if err != nil {
			response.ValidationError(c, []response.ErrorDetail{
				{Field: "schedule_at", Message: "invalid date format, use RFC3339"},
			})
			return
		}

		if h.scheduledRepo == nil {
			response.InternalError(c, "scheduling not available")
			return
		}

		sn := &models.ScheduledNotification{
			Title:       req.Title,
			Body:        req.Body,
			Target:      req.Target,
			Status:      "pending",
			ScheduledAt: scheduledAt,
		}

		if req.Target == "user" && req.UserID != "" {
			uid, err := uuid.Parse(req.UserID)
			if err == nil {
				sn.UserID = &uid
			}
		}
		if req.OfferID != "" {
			oid, err := uuid.Parse(req.OfferID)
			if err == nil {
				sn.OfferID = &oid
			}
		}

		if err := h.scheduledRepo.Create(sn); err != nil {
			response.InternalError(c, "failed to schedule notification")
			return
		}
		if userID, ok := middleware.GetUserID(c); ok {
			userName, _ := middleware.GetUserName(c)
			userRole, _ := middleware.GetUserRole(c)
			h.auditService.LogAction(userID, userName, userRole, "notification.push", "notification", sn.ID.String(),
				fmt.Sprintf("Scheduled push notification: %s (target: %s)", req.Title, req.Target))
		}
		response.Success(c, gin.H{"message": "notification scheduled", "id": sn.ID})
		return
	}

	input := services.SendPushInput{
		Title: req.Title,
		Body:  req.Body,
		Type:  "admin",
	}

	if req.Target == "user" && req.UserID != "" {
		uid, err := uuid.Parse(req.UserID)
		if err == nil {
			input.UserID = &uid
		}
	}

	if req.OfferID != "" {
		oid, err := uuid.Parse(req.OfferID)
		if err == nil {
			input.OfferID = &oid
		}
	}

	if err := h.service.SendPush(input); err != nil {
		response.InternalError(c, "failed to send push notification")
		return
	}

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(userID, userName, userRole, "notification.push", "notification", "",
			fmt.Sprintf("Sent push notification: %s (target: %s)", req.Title, req.Target))
	}

	response.Success(c, gin.H{"message": "push notification sent"})
}
