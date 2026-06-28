package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/dto/request"
	"github.com/nomnom-lk/backend/internal/middleware"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/services"
	"github.com/nomnom-lk/backend/pkg/locale"
	"github.com/nomnom-lk/backend/pkg/pagination"
	"github.com/nomnom-lk/backend/pkg/response"
)

type OfferHandler struct {
	service    *services.OfferService
	sseService *services.SSEService
}

func NewOfferHandler(service *services.OfferService, sseService *services.SSEService) *OfferHandler {
	return &OfferHandler{
		service:    service,
		sseService: sseService,
	}
}

func (h *OfferHandler) List(c *gin.Context) {
	status := c.DefaultQuery("status", "approved")
	sort := c.DefaultQuery("sort", "newest")
	query := c.Query("q")
	params := pagination.Extract(c)

	offers, total, err := h.service.List(status, query, params.Page, params.PerPage, sort)
	if err != nil {
		response.InternalError(c, "failed to list offers")
		return
	}

	data := make([]gin.H, len(offers))
	for i, o := range offers {
		data[i] = h.offerToMap(&o, c)
	}

	response.SuccessPaginated(c, data, pagination.Meta(params, total))
}

func (h *OfferHandler) Get(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid offer id"},
		})
		return
	}

	offer, err := h.service.GetByID(id)
	if err != nil {
		response.NotFound(c, err.Error())
		return
	}

	h.service.IncrementView(id)
	response.Success(c, h.offerDetailToMap(offer, c))
}

func (h *OfferHandler) Create(c *gin.Context) {
	var req request.CreateOfferRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	userID, _ := middleware.GetUserID(c)
	role, _ := middleware.GetUserRole(c)
	isAdmin := role == "admin"

	offer, err := h.service.Create(&req, userID, isAdmin)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}

	// Reload to get preloaded Restaurant association for response
	if reloaded, err := h.service.GetByID(offer.ID); err == nil {
		offer = reloaded
	}

	h.sseService.Emit("offer.created", gin.H{"id": offer.ID, "title": offer.Title})
	c.JSON(http.StatusCreated, h.offerToMap(offer, c))
}

func (h *OfferHandler) Update(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid offer id"},
		})
		return
	}

	var req request.UpdateOfferRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	userID, _ := middleware.GetUserID(c)
	role, _ := middleware.GetUserRole(c)
	isAdmin := role == "admin"

	offer, err := h.service.Update(id, &req, userID, isAdmin)
	if err != nil {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", err.Error())
		return
	}

	h.sseService.Emit("offer.updated", gin.H{"id": offer.ID, "title": offer.Title})
	response.Success(c, h.offerToMap(offer, c))
}

func (h *OfferHandler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid offer id"},
		})
		return
	}

	userID, _ := middleware.GetUserID(c)
	role, _ := middleware.GetUserRole(c)
	isAdmin := role == "admin"

	if err := h.service.Delete(id, userID, isAdmin); err != nil {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", err.Error())
		return
	}

	h.sseService.Emit("offer.deleted", gin.H{"id": id})
	c.Status(http.StatusNoContent)
}

func (h *OfferHandler) Approve(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid offer id"},
		})
		return
	}

	offer, err := h.service.Approve(id)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}

	h.sseService.Emit("offer.approved", gin.H{"id": offer.ID})
	response.Success(c, gin.H{"id": offer.ID, "status": offer.Status})
}

func (h *OfferHandler) Reject(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid offer id"},
		})
		return
	}

	offer, err := h.service.Reject(id)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}

	h.sseService.Emit("offer.rejected", gin.H{"id": offer.ID})
	response.Success(c, gin.H{"id": offer.ID, "status": offer.Status})
}

func (h *OfferHandler) offerToMap(o *models.Offer, c *gin.Context) gin.H {
	lang := middleware.GetLanguage(c)
	m := gin.H{
		"id": o.ID,
		"restaurant": gin.H{
			"id":      o.RestaurantID,
			"name":    o.Restaurant.Name,
			"slug":    o.Restaurant.Slug,
			"address": o.Restaurant.Address,
		},
		"restaurant_id":    o.RestaurantID,
		"title":            o.Title,
		"description":      o.Description,
		"original_price":   o.OriginalPrice,
		"offer_price":      o.OfferPrice,
		"discount_percent": int((1 - o.OfferPrice/o.OriginalPrice) * 100),
		"saving":           o.OriginalPrice - o.OfferPrice,
		"image_urls":       o.ImageURLs,
		"status":           o.Status,
		"start_date":       o.StartDate,
		"end_date":         o.EndDate,
		"is_favorited":     false,
	}

	if o.Translations != nil {
		locale.MergeTranslations(m, o.Translations, lang)
		locale.FlattenTranslations(m, o.Translations, map[string]string{
			"name":        "title",
			"description": "description",
		})
	}

	return m
}

func (h *OfferHandler) offerDetailToMap(o *models.Offer, c *gin.Context) gin.H {
	m := h.offerToMap(o, c)
	m["view_count"] = o.ViewCount
	m["created_at"] = o.CreatedAt

	restDetail := m["restaurant"].(gin.H)
	restDetail["address"] = o.Restaurant.Address
	restDetail["cuisine_tags"] = o.Restaurant.CuisineTags
	restDetail["cover_image"] = o.Restaurant.CoverImage

	return m
}
