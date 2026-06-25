package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/dto/request"
	"github.com/nomnom-lk/backend/internal/middleware"
	"github.com/nomnom-lk/backend/internal/services"
	"github.com/nomnom-lk/backend/pkg/pagination"
	"github.com/nomnom-lk/backend/pkg/response"
)

type FavoriteHandler struct {
	service    *services.FavoriteService
	sseService *services.SSEService
}

func NewFavoriteHandler(service *services.FavoriteService, sseService *services.SSEService) *FavoriteHandler {
	return &FavoriteHandler{
		service:    service,
		sseService: sseService,
	}
}

func (h *FavoriteHandler) List(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)
	params := pagination.Extract(c)

	favorites, total, err := h.service.List(userID, params.Page, params.PerPage)
	if err != nil {
		response.InternalError(c, "failed to list favorites")
		return
	}

	data := make([]gin.H, len(favorites))
	for i, f := range favorites {
		data[i] = gin.H{
			"id": f.OfferID,
			"restaurant": gin.H{
				"id":   f.Offer.RestaurantID,
				"name": f.Offer.Restaurant.Name,
				"slug": f.Offer.Restaurant.Slug,
			},
			"title":            f.Offer.Title,
			"original_price":   f.Offer.OriginalPrice,
			"offer_price":      f.Offer.OfferPrice,
			"discount_percent": int((1 - f.Offer.OfferPrice/f.Offer.OriginalPrice) * 100),
			"image_urls":       f.Offer.ImageURLs,
			"end_date":         f.Offer.EndDate,
			"is_favorited":     true,
			"favorited_at":     f.CreatedAt,
		}
	}

	response.SuccessPaginated(c, data, pagination.Meta(params, total))
}

func (h *FavoriteHandler) Add(c *gin.Context) {
	var req request.AddFavoriteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	userID, _ := middleware.GetUserID(c)
	offerID, _ := uuid.Parse(req.OfferID)

	if err := h.service.Add(userID, offerID); err != nil {
		response.InternalError(c, "failed to add favorite")
		return
	}

	h.sseService.Emit("favorite.added", gin.H{"user_id": userID, "offer_id": offerID})
	c.Status(http.StatusCreated)
}

func (h *FavoriteHandler) Remove(c *gin.Context) {
	offerID, err := uuid.Parse(c.Param("offerId"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "offerId", Message: "invalid offer id"},
		})
		return
	}

	userID, _ := middleware.GetUserID(c)

	if err := h.service.Remove(userID, offerID); err != nil {
		response.InternalError(c, "failed to remove favorite")
		return
	}

	h.sseService.Emit("favorite.removed", gin.H{"user_id": userID, "offer_id": offerID})
	c.Status(http.StatusNoContent)
}
