package handlers

import (
	"fmt"
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

type RestaurantHandler struct {
	service      *services.RestaurantService
	sseService   *services.SSEService
	auditService *services.AuditService
}

func NewRestaurantHandler(service *services.RestaurantService, sseService *services.SSEService, auditService *services.AuditService) *RestaurantHandler {
	return &RestaurantHandler{
		service:      service,
		sseService:   sseService,
		auditService: auditService,
	}
}

func (h *RestaurantHandler) List(c *gin.Context) {
	status := c.DefaultQuery("status", "approved")
	query := c.Query("q")
	params := pagination.Extract(c)

	restaurants, total, err := h.service.List(status, query, params.Page, params.PerPage)
	if err != nil {
		response.InternalError(c, "failed to list restaurants")
		return
	}

	data := make([]gin.H, len(restaurants))
	for i, r := range restaurants {
		data[i] = h.restaurantToMap(&r, c)
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

	response.Success(c, h.restaurantDetailToMap(restaurant, c))
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

	h.sseService.Emit("restaurant.created", gin.H{"id": restaurant.ID, "slug": restaurant.Slug})

	if uid, ok := middleware.GetUserID(c); ok {
		n, _ := middleware.GetUserName(c)
		r, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(uid, n, r, "restaurant.create", "restaurant", restaurant.ID.String(),
			fmt.Sprintf("Created restaurant: %s", restaurant.Name))
	}

	c.JSON(http.StatusCreated, h.restaurantToMap(restaurant, c))
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

	h.sseService.Emit("restaurant.updated", gin.H{"id": restaurant.ID, "slug": restaurant.Slug})

	if uid, ok := middleware.GetUserID(c); ok {
		n, _ := middleware.GetUserName(c)
		r, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(uid, n, r, "restaurant.update", "restaurant", restaurant.ID.String(),
			fmt.Sprintf("Updated restaurant: %s", restaurant.Name))
	}

	response.Success(c, h.restaurantToMap(restaurant, c))
}

func (h *RestaurantHandler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid restaurant id"},
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

	if uid, ok := middleware.GetUserID(c); ok {
		n, _ := middleware.GetUserName(c)
		r, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(uid, n, r, "restaurant.delete", "restaurant", id.String(),
			"Deleted restaurant")
	}

	h.sseService.Emit("restaurant.deleted", gin.H{"id": id})
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

	h.sseService.Emit("restaurant.approved", gin.H{"id": restaurant.ID, "slug": restaurant.Slug})

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(userID, userName, userRole, "restaurant.approve", "restaurant", restaurant.ID.String(),
			fmt.Sprintf("Approved restaurant: %s", restaurant.Name))
	}

	response.Success(c, h.restaurantToMap(restaurant, c))
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

	h.sseService.Emit("restaurant.rejected", gin.H{"id": restaurant.ID, "slug": restaurant.Slug})

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(userID, userName, userRole, "restaurant.reject", "restaurant", restaurant.ID.String(),
			fmt.Sprintf("Rejected restaurant: %s", restaurant.Name))
	}

	response.Success(c, h.restaurantToMap(restaurant, c))
}

func (h *RestaurantHandler) restaurantToMap(r *models.Restaurant, c *gin.Context) gin.H {
	lang := middleware.GetLanguage(c)
	m := gin.H{
		"id":               r.ID,
		"name":             r.Name,
		"slug":             r.Slug,
		"address":          r.Address,
		"description":      r.Description,
		"contact_phone":    r.ContactPhone,
		"cuisine_tags":     r.CuisineTags,
		"cover_image":      r.CoverImage,
		"instagram_url":    r.InstagramURL,
		"facebook_url":     r.FacebookURL,
		"website_url":      r.WebsiteURL,
		"order_platforms":  r.OrderPlatforms,
		"status":           r.Status,
		"active_offer_count": len(r.Offers),
	}

	if r.Translations != nil {
		locale.MergeTranslations(m, r.Translations, lang)
		locale.FlattenTranslations(m, r.Translations, map[string]string{
			"name":        "name",
			"description": "description",
		})
	}

	return m
}

func (h *RestaurantHandler) restaurantDetailToMap(r *models.Restaurant, c *gin.Context) gin.H {
	lang := middleware.GetLanguage(c)
	m := gin.H{
		"id":              r.ID,
		"name":            r.Name,
		"slug":            r.Slug,
		"description":     r.Description,
		"address":         r.Address,
		"latitude":        r.Latitude,
		"longitude":       r.Longitude,
		"contact_phone":   r.ContactPhone,
		"cuisine_tags":    r.CuisineTags,
		"cover_image":     r.CoverImage,
		"instagram_url":   r.InstagramURL,
		"facebook_url":    r.FacebookURL,
		"website_url":     r.WebsiteURL,
		"order_platforms": r.OrderPlatforms,
		"status":          r.Status,
		"created_at":      r.CreatedAt,
	}

	if r.Translations != nil {
		locale.MergeTranslations(m, r.Translations, lang)
	}

	return m
}
