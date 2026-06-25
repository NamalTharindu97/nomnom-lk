package handlers

import (
	"github.com/gin-gonic/gin"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/nomnom-lk/backend/pkg/pagination"
	"github.com/nomnom-lk/backend/pkg/response"

)

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
			"is_read":    n.IsRead,
			"created_at": n.CreatedAt,
		}
	}

	response.SuccessPaginated(c, data, pagination.Meta(params, total))
}
