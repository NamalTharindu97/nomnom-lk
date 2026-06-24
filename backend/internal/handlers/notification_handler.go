package handlers

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/dto/request"
	"github.com/nomnom-lk/backend/internal/middleware"
	"github.com/nomnom-lk/backend/internal/services"
	"github.com/nomnom-lk/backend/pkg/pagination"
	"github.com/nomnom-lk/backend/pkg/response"
)

type NotificationHandler struct {
	service *services.NotificationService
}

func NewNotificationHandler(service *services.NotificationService) *NotificationHandler {
	return &NotificationHandler{service: service}
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
	userID, _ := middleware.GetUserID(c)

	if err := h.service.UnregisterDevice(userID); err != nil {
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
	var req request.SendPushRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
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

	if err := h.service.SendPush(input); err != nil {
		response.InternalError(c, "failed to send push notification")
		return
	}

	response.Success(c, gin.H{"message": "push notification sent"})
}
