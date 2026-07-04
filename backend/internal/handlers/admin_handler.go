package handlers

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/nomnom-lk/backend/pkg/pagination"
	"github.com/nomnom-lk/backend/pkg/response"
)

type BulkActionRequest struct {
	Action string      `json:"action" binding:"required"`
	IDs    []uuid.UUID `json:"ids" binding:"required,min=1"`
}

type AdminHandler struct {
	restaurantRepo *repository.RestaurantRepo
	offerRepo      *repository.OfferRepo
	userRepo       *repository.UserRepo
	notificationRepo *repository.NotificationRepo
}

func NewAdminHandler(
	restaurantRepo *repository.RestaurantRepo,
	offerRepo *repository.OfferRepo,
	userRepo *repository.UserRepo,
	notificationRepo *repository.NotificationRepo,
) *AdminHandler {
	return &AdminHandler{
		restaurantRepo:  restaurantRepo,
		offerRepo:       offerRepo,
		userRepo:        userRepo,
		notificationRepo: notificationRepo,
	}
}

func (h *AdminHandler) Stats(c *gin.Context) {
	var totalRestaurants, totalOffers, totalUsers, pendingRestaurants, pendingOffers int64

	h.restaurantRepo.CountAll(&totalRestaurants)
	h.offerRepo.CountAll(&totalOffers)
	h.userRepo.CountAll(&totalUsers)
	h.restaurantRepo.CountByStatus("pending", &pendingRestaurants)
	h.offerRepo.CountByStatus("pending", &pendingOffers)

	response.Success(c, gin.H{
		"total_restaurants":   totalRestaurants,
		"total_offers":        totalOffers,
		"total_users":         totalUsers,
		"pending_restaurants": pendingRestaurants,
		"pending_offers":      pendingOffers,
	})
}

func (h *AdminHandler) StatsTimeline(c *gin.Context) {
	daysStr := c.DefaultQuery("days", "7")
	days, err := strconv.Atoi(daysStr)
	if err != nil || days < 1 || days > 90 {
		days = 7
	}

	offers, err := h.offerRepo.CountByDate(days)
	if err != nil {
		response.InternalError(c, "failed to get offer timeline")
		return
	}

	restaurants, err := h.restaurantRepo.CountByDate(days)
	if err != nil {
		response.InternalError(c, "failed to get restaurant timeline")
		return
	}

	response.Success(c, gin.H{
		"offers":      offers,
		"restaurants": restaurants,
	})
}

func (h *AdminHandler) ListNotifications(c *gin.Context) {
	params := pagination.Extract(c)

	notifications, total, err := h.notificationRepo.FindAllAdmin(params.Offset, params.PerPage)
	if err != nil {
		response.InternalError(c, "failed to list notifications")
		return
	}

	data := make([]gin.H, len(notifications))
	for i, n := range notifications {
		userName := ""
		if n.User != nil {
			userName = n.User.Name
		}
		data[i] = gin.H{
			"id":         n.ID,
			"user_id":    n.UserID,
			"user_name":  userName,
			"type":       n.Type,
			"title":      n.Title,
			"body":       n.Body,
			"offer_id":   n.OfferID,
			"is_read":    n.IsRead,
			"created_at": n.CreatedAt,
		}
	}

	response.SuccessPaginated(c, data, pagination.Meta(params, total))
}

func (h *AdminHandler) BulkRestaurants(c *gin.Context) {
	var req BulkActionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	switch req.Action {
	case "approve":
		if err := h.restaurantRepo.BulkUpdateStatus(req.IDs, models.RestaurantApproved); err != nil {
			response.InternalError(c, "failed to approve restaurants")
			return
		}
	case "reject":
		if err := h.restaurantRepo.BulkUpdateStatus(req.IDs, models.RestaurantRejected); err != nil {
			response.InternalError(c, "failed to reject restaurants")
			return
		}
	case "delete":
		if err := h.restaurantRepo.BulkDelete(req.IDs); err != nil {
			response.InternalError(c, "failed to delete restaurants")
			return
		}
	default:
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "action", Message: "invalid action; must be approve, reject, or delete"},
		})
		return
	}

	response.Success(c, gin.H{"affected": len(req.IDs)})
}

func (h *AdminHandler) BulkOffers(c *gin.Context) {
	var req BulkActionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	switch req.Action {
	case "approve":
		if err := h.offerRepo.BulkUpdateStatus(req.IDs, models.OfferApproved); err != nil {
			response.InternalError(c, "failed to approve offers")
			return
		}
	case "reject":
		if err := h.offerRepo.BulkUpdateStatus(req.IDs, models.OfferRejected); err != nil {
			response.InternalError(c, "failed to reject offers")
			return
		}
	case "delete":
		if err := h.offerRepo.BulkDelete(req.IDs); err != nil {
			response.InternalError(c, "failed to delete offers")
			return
		}
	default:
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "action", Message: "invalid action; must be approve, reject, or delete"},
		})
		return
	}

	response.Success(c, gin.H{"affected": len(req.IDs)})
}

func (h *AdminHandler) AnalyticsTopRestaurants(c *gin.Context) {
	top, err := h.restaurantRepo.TopByOfferCount(5)
	if err != nil {
		response.InternalError(c, "failed to get top restaurants")
		return
	}
	response.Success(c, top)
}

func (h *AdminHandler) AnalyticsTopOffers(c *gin.Context) {
	byFavorites, _ := h.offerRepo.TopByFavorites(5)
	byViews, _ := h.offerRepo.TopByViews(5)

	viewData := make([]gin.H, len(byViews))
	for i, o := range byViews {
		viewData[i] = gin.H{
			"offer_id":   o.ID,
			"title":      o.Title,
			"view_count": o.ViewCount,
		}
	}

	response.Success(c, gin.H{
		"by_favorites": byFavorites,
		"by_views":     viewData,
	})
}

func (h *AdminHandler) AnalyticsUserGrowth(c *gin.Context) {
	daysStr := c.DefaultQuery("days", "30")
	days, err := strconv.Atoi(daysStr)
	if err != nil || days < 1 || days > 365 {
		days = 30
	}

	growth, err := h.userRepo.CountByDate(days)
	if err != nil {
		response.InternalError(c, "failed to get user growth")
		return
	}
	response.Success(c, growth)
}

func (h *AdminHandler) AnalyticsOfferStats(c *gin.Context) {
	var total, approved, pending, rejected, expired int64
	h.offerRepo.CountAll(&total)
	h.offerRepo.CountByStatus("approved", &approved)
	h.offerRepo.CountByStatus("pending", &pending)
	h.offerRepo.CountByStatus("rejected", &rejected)
	h.offerRepo.CountByStatus("expired", &expired)

	approvalRate := float64(0)
	if total > 0 {
		approvalRate = float64(approved) / float64(total) * 100
	}

	response.Success(c, gin.H{
		"total":         total,
		"approved":      approved,
		"pending":       pending,
		"rejected":      rejected,
		"expired":       expired,
		"approval_rate": approvalRate,
	})
}

func (h *AdminHandler) BulkUsers(c *gin.Context) {
	var req BulkActionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	switch req.Action {
	case "activate":
		if err := h.userRepo.BulkActivate(req.IDs); err != nil {
			response.InternalError(c, "failed to activate users")
			return
		}
	case "deactivate":
		if err := h.userRepo.BulkSoftDelete(req.IDs); err != nil {
			response.InternalError(c, "failed to deactivate users")
			return
		}
	case "delete":
		if err := h.userRepo.BulkDelete(req.IDs); err != nil {
			response.InternalError(c, "failed to delete users")
			return
		}
	default:
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "action", Message: "invalid action; must be activate, deactivate, or delete"},
		})
		return
	}

	response.Success(c, gin.H{"affected": len(req.IDs)})
}
