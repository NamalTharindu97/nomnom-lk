package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/dto/request"
	"github.com/nomnom-lk/backend/internal/middleware"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/services"
	"github.com/nomnom-lk/backend/pkg/pagination"
	"github.com/nomnom-lk/backend/pkg/response"
)

type RestaurantHandler struct {
	service *services.RestaurantService
}

func NewRestaurantHandler(service *services.RestaurantService) *RestaurantHandler {
	return &RestaurantHandler{service: service}
}

func (h *RestaurantHandler) List(c *gin.Context) {
	status := c.DefaultQuery("status", "approved")
	params := pagination.Extract(c)

	restaurants, total, err := h.service.List(status, params.Page, params.PerPage)
	if err != nil {
		response.InternalError(c, "failed to list restaurants")
		return
	}

	data := make([]gin.H, len(restaurants))
	for i, r := range restaurants {
		data[i] = h.restaurantToMap(&r)
	}

	response.SuccessPaginated(c, data, pagination.Meta(params, total))
}

func (h *RestaurantHandler) Get(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid restaurant id"},
		})
		return
	}

	restaurant, err := h.service.GetByID(id)
	if err != nil {
		response.NotFound(c, err.Error())
		return
	}

	response.Success(c, h.restaurantDetailToMap(restaurant))
}

func (h *RestaurantHandler) Create(c *gin.Context) {
	var req request.CreateRestaurantRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	userID, _ := middleware.GetUserID(c)
	role, _ := middleware.GetUserRole(c)
	isAdmin := role == "admin"

	restaurant, err := h.service.Create(&req, &userID, isAdmin)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}

	c.JSON(http.StatusCreated, h.restaurantToMap(restaurant))
}

func (h *RestaurantHandler) Update(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid restaurant id"},
		})
		return
	}

	var req request.UpdateRestaurantRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	userID, _ := middleware.GetUserID(c)
	role, _ := middleware.GetUserRole(c)
	isAdmin := role == "admin"

	restaurant, err := h.service.Update(id, &req, userID, isAdmin)
	if err != nil {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", err.Error())
		return
	}

	response.Success(c, h.restaurantToMap(restaurant))
}

func (h *RestaurantHandler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid restaurant id"},
		})
		return
	}

	if err := h.service.Delete(id); err != nil {
		response.InternalError(c, err.Error())
		return
	}

	c.Status(http.StatusNoContent)
}

func (h *RestaurantHandler) Approve(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid restaurant id"},
		})
		return
	}

	restaurant, err := h.service.Approve(id)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}

	response.Success(c, h.restaurantToMap(restaurant))
}

func (h *RestaurantHandler) Reject(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid restaurant id"},
		})
		return
	}

	restaurant, err := h.service.Reject(id)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}

	response.Success(c, h.restaurantToMap(restaurant))
}

func (h *RestaurantHandler) restaurantToMap(r *models.Restaurant) gin.H {
	return gin.H{
		"id":        r.ID,
		"name":      r.Name,
		"slug":      r.Slug,
		"address":   r.Address,
		"cuisine_tags": r.CuisineTags,
		"cover_image": r.CoverImage,
		"status":    r.Status,
		"active_offer_count": len(r.Offers),
	}
}

func (h *RestaurantHandler) restaurantDetailToMap(r *models.Restaurant) gin.H {
	return gin.H{
		"id":           r.ID,
		"name":         r.Name,
		"slug":         r.Slug,
		"description":  r.Description,
		"address":      r.Address,
		"latitude":     r.Latitude,
		"longitude":    r.Longitude,
		"contact_phone": r.ContactPhone,
		"cuisine_tags": r.CuisineTags,
		"cover_image":  r.CoverImage,
		"status":       r.Status,
		"created_at":   r.CreatedAt,
	}
}
