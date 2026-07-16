package handlers

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/dto/request"
	"github.com/nomnom-lk/backend/internal/middleware"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/nomnom-lk/backend/internal/services"
	"github.com/nomnom-lk/backend/pkg/locale"
	"github.com/nomnom-lk/backend/pkg/pagination"
	"github.com/nomnom-lk/backend/pkg/response"
)

type DashboardHandler struct {
	dashboardService *services.DashboardService
	sseService       *services.SSEService
	auditService     *services.AuditService
	bannerRepo       *repository.BannerRepo
}

func NewDashboardHandler(dashboardService *services.DashboardService, sseService *services.SSEService, auditService *services.AuditService, bannerRepo *repository.BannerRepo) *DashboardHandler {
	return &DashboardHandler{
		dashboardService: dashboardService,
		sseService:       sseService,
		auditService:     auditService,
		bannerRepo:       bannerRepo,
	}
}

func (h *DashboardHandler) Stats(c *gin.Context) {
	ownerID, _ := middleware.GetOwnerScopeID(c)

	stats, err := h.dashboardService.Stats(ownerID)
	if err != nil {
		response.InternalError(c, "failed to get stats")
		return
	}
	response.Success(c, stats)
}

func (h *DashboardHandler) ListRestaurants(c *gin.Context) {
	ownerID, _ := middleware.GetOwnerScopeID(c)
	status := c.DefaultQuery("status", "all")
	query := c.Query("q")
	params := pagination.Extract(c)

	restaurants, total, err := h.dashboardService.ListRestaurants(ownerID, status, query, params.Page, params.PerPage)
	if err != nil {
		response.InternalError(c, "failed to list restaurants")
		return
	}

	data := make([]gin.H, len(restaurants))
	for i, r := range restaurants {
		data[i] = dashboardRestaurantToMap(&r, c)
	}

	response.SuccessPaginated(c, data, pagination.Meta(params, total))
}

func (h *DashboardHandler) GetRestaurant(c *gin.Context) {
	ownerID, _ := middleware.GetOwnerScopeID(c)
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid restaurant id"},
		})
		return
	}

	restaurant, err := h.dashboardService.GetRestaurantByIDForOwner(ownerID, id)
	if err != nil {
		response.NotFound(c, err.Error())
		return
	}

	response.Success(c, dashboardRestaurantDetailToMap(restaurant, c))
}

func (h *DashboardHandler) CreateRestaurant(c *gin.Context) {
	var req request.CreateRestaurantRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	ownerID, _ := middleware.GetOwnerScopeID(c)

	restaurant, err := h.dashboardService.CreateRestaurant(&req, ownerID)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}

	h.sseService.Emit("restaurant.created", gin.H{"id": restaurant.ID, "slug": restaurant.Slug})

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(userID, userName, userRole, "restaurant.create", "restaurant", restaurant.ID.String(),
			fmt.Sprintf("Created restaurant: %s", restaurant.Name))
	}

	c.JSON(http.StatusCreated, dashboardRestaurantDetailToMap(restaurant, c))
}

func (h *DashboardHandler) UpdateRestaurant(c *gin.Context) {
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

	ownerID, _ := middleware.GetOwnerScopeID(c)

	restaurant, err := h.dashboardService.UpdateRestaurant(id, ownerID, &req)
	if err != nil {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", err.Error())
		return
	}

	h.sseService.Emit("restaurant.updated", gin.H{"id": restaurant.ID, "slug": restaurant.Slug})

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(userID, userName, userRole, "restaurant.update", "restaurant", restaurant.ID.String(),
			fmt.Sprintf("Updated restaurant: %s", restaurant.Name))
	}

	response.Success(c, dashboardRestaurantDetailToMap(restaurant, c))
}

func (h *DashboardHandler) DeleteRestaurant(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid restaurant id"},
		})
		return
	}

	ownerID, _ := middleware.GetOwnerScopeID(c)

	restaurant, _ := h.dashboardService.GetRestaurantByIDForOwner(ownerID, id)
	restaurantName := ""
	if restaurant != nil {
		restaurantName = restaurant.Name
	}

	if err := h.dashboardService.DeleteRestaurant(id, ownerID); err != nil {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", err.Error())
		return
	}

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(userID, userName, userRole, "restaurant.delete", "restaurant", id.String(),
			fmt.Sprintf("Deleted restaurant: %s", restaurantName))
	}

	h.sseService.Emit("restaurant.deleted", gin.H{"id": id})
	c.Status(http.StatusNoContent)
}

func (h *DashboardHandler) ListOffers(c *gin.Context) {
	ownerID, _ := middleware.GetOwnerScopeID(c)
	status := c.DefaultQuery("status", "all")
	sort := c.DefaultQuery("sort", "newest")
	query := c.Query("q")
	params := pagination.Extract(c)

	offers, total, err := h.dashboardService.ListOffers(c.Request.Context(), ownerID, status, query, params.Page, params.PerPage, sort)
	if err != nil {
		response.InternalError(c, "failed to list offers")
		return
	}

	data := make([]gin.H, len(offers))
	for i, o := range offers {
		data[i] = dashboardOfferToMap(&o, c)
	}

	response.SuccessPaginated(c, data, pagination.Meta(params, total))
}

func (h *DashboardHandler) GetOffer(c *gin.Context) {
	ownerID, _ := middleware.GetOwnerScopeID(c)
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid offer id"},
		})
		return
	}

	offer, err := h.dashboardService.GetOfferByIDForOwner(ownerID, id)
	if err != nil {
		response.NotFound(c, err.Error())
		return
	}

	response.Success(c, dashboardOfferToMap(offer, c))
}

func (h *DashboardHandler) CreateOffer(c *gin.Context) {
	var req request.CreateOfferRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	ownerID, _ := middleware.GetOwnerScopeID(c)

	offer, err := h.dashboardService.CreateOffer(&req, ownerID)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}

	if reloaded, err := h.dashboardService.GetOfferByIDForOwner(ownerID, offer.ID); err == nil {
		offer = reloaded
	}

	h.sseService.Emit("offer.created", gin.H{"id": offer.ID, "title": offer.Title})

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(userID, userName, userRole, "offer.create", "offer", offer.ID.String(),
			fmt.Sprintf("Created offer: %s", offer.Title))
	}

	c.JSON(http.StatusCreated, dashboardOfferToMap(offer, c))
}

func (h *DashboardHandler) UpdateOffer(c *gin.Context) {
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

	ownerID, _ := middleware.GetOwnerScopeID(c)

	offer, err := h.dashboardService.UpdateOffer(id, ownerID, &req)
	if err != nil {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", err.Error())
		return
	}

	h.sseService.Emit("offer.updated", gin.H{"id": offer.ID, "title": offer.Title})

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(userID, userName, userRole, "offer.update", "offer", offer.ID.String(),
			fmt.Sprintf("Updated offer: %s", offer.Title))
	}

	response.Success(c, dashboardOfferToMap(offer, c))
}

func (h *DashboardHandler) DeleteOffer(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid offer id"},
		})
		return
	}

	ownerID, _ := middleware.GetOwnerScopeID(c)

	offer, _ := h.dashboardService.GetOfferByIDForOwner(ownerID, id)
	offerTitle := ""
	if offer != nil {
		offerTitle = offer.Title
	}

	if err := h.dashboardService.DeleteOffer(id, ownerID); err != nil {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", err.Error())
		return
	}

	_ = h.bannerRepo.DeactivateByOfferID(id)

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(userID, userName, userRole, "offer.delete", "offer", id.String(),
			fmt.Sprintf("Deleted offer: %s", offerTitle))
	}

	h.sseService.Emit("offer.deleted", gin.H{"id": id})
	c.Status(http.StatusNoContent)
}

func dashboardRestaurantToMap(r *models.Restaurant, c *gin.Context) gin.H {
	lang := middleware.GetLanguage(c)
	m := gin.H{
		"id":           r.ID,
		"name":         r.Name,
		"slug":         r.Slug,
		"address":      r.Address,
		"description":  r.Description,
		"contact_phone": r.ContactPhone,
		"cuisine_tags": r.CuisineTags,
		"cover_image":   r.CoverImage,
		"instagram_url": r.InstagramURL,
		"facebook_url":  r.FacebookURL,
		"website_url":   r.WebsiteURL,
		"order_url":     r.OrderURL,
		"order_url_alt": r.OrderURLAlt,
		"owner_id":      r.OwnerID,
		"status":        r.Status,
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

func dashboardRestaurantDetailToMap(r *models.Restaurant, c *gin.Context) gin.H {
	lang := middleware.GetLanguage(c)
	m := gin.H{
		"id":            r.ID,
		"name":          r.Name,
		"slug":          r.Slug,
		"description":   r.Description,
		"address":       r.Address,
		"latitude":      r.Latitude,
		"longitude":     r.Longitude,
		"contact_phone": r.ContactPhone,
		"cuisine_tags":  r.CuisineTags,
		"cover_image":   r.CoverImage,
		"instagram_url": r.InstagramURL,
		"facebook_url":  r.FacebookURL,
		"website_url":   r.WebsiteURL,
		"order_url":     r.OrderURL,
		"order_url_alt": r.OrderURLAlt,
		"owner_id":      r.OwnerID,
		"status":        r.Status,
		"created_at":    r.CreatedAt,
	}

	if r.Translations != nil {
		locale.MergeTranslations(m, r.Translations, lang)
	}

	return m
}

func dashboardOfferToMap(o *models.Offer, c *gin.Context) gin.H {
	lang := middleware.GetLanguage(c)

	restaurant := gin.H{"id": o.RestaurantID}
	if o.Restaurant != nil {
		restaurant["name"] = o.Restaurant.Name
		restaurant["slug"] = o.Restaurant.Slug
		restaurant["address"] = o.Restaurant.Address
		restaurant["instagram_url"] = o.Restaurant.InstagramURL
		restaurant["facebook_url"] = o.Restaurant.FacebookURL
		restaurant["website_url"] = o.Restaurant.WebsiteURL
		restaurant["order_url"] = o.Restaurant.OrderURL
		restaurant["order_url_alt"] = o.Restaurant.OrderURLAlt
	}

	m := gin.H{
		"id":               o.ID,
		"restaurant":       restaurant,
		"restaurant_id":    o.RestaurantID,
		"restaurant_name":  func() string { if o.Restaurant != nil { return o.Restaurant.Name }; return "" }(),
		"title":            o.Title,
		"description":      o.Description,
		"original_price":   o.OriginalPrice,
		"offer_price":      o.OfferPrice,
		"discount_percent": int((1 - o.OfferPrice/o.OriginalPrice) * 100),
		"saving":           o.OriginalPrice - o.OfferPrice,
		"image_urls":       o.ImageURLs,
		"category_ids":     o.CategoryIDs,
		"status":           o.Status,
		"start_date":       o.StartDate,
		"end_date":         o.EndDate,
		"publish_at":       o.PublishAt,
		"created_at":       o.CreatedAt,
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
