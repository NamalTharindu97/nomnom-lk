package handlers

import (
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/middleware"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/nomnom-lk/backend/internal/services"
	"github.com/nomnom-lk/backend/pkg/response"
)

type BannerHandler struct {
	repo           *repository.BannerRepo
	offerRepo      *repository.OfferRepo
	restaurantRepo *repository.RestaurantRepo
	auditService   *services.AuditService
	sseService     *services.SSEService
}

func NewBannerHandler(repo *repository.BannerRepo, offerRepo *repository.OfferRepo, restaurantRepo *repository.RestaurantRepo, auditService *services.AuditService, sseService *services.SSEService) *BannerHandler {
	return &BannerHandler{
		repo:           repo,
		offerRepo:      offerRepo,
		restaurantRepo: restaurantRepo,
		auditService:   auditService,
		sseService:     sseService,
	}
}

type bannerRequest struct {
	Image       string  `json:"image" binding:"required"`
	LinkType    string  `json:"link_type" binding:"required"`
	LinkValue   string  `json:"link_value" binding:"required"`
	Title       string  `json:"title,omitempty"`
	SponsorName string  `json:"sponsor_name,omitempty"`
	SortOrder   int     `json:"sort_order"`
	StartDate   *string `json:"start_date,omitempty"`
	EndDate     *string `json:"end_date,omitempty"`
	OfferID     *string `json:"offer_id,omitempty"`
}

type ownerBannerRequest struct {
	OfferID string `json:"offer_id" binding:"required"`
	Image   string `json:"image" binding:"required"`
	Title   string `json:"title,omitempty"`
}

func validateBannerImage(image string) error {
	image = strings.TrimSpace(image)
	if image == "" {
		return fmt.Errorf("image is required")
	}
	if strings.HasPrefix(image, "/api/v1/uploads/") {
		return nil
	}
	parsed, err := url.ParseRequestURI(image)
	if err != nil || (parsed.Scheme != "http" && parsed.Scheme != "https") || parsed.Host == "" {
		return fmt.Errorf("image must be an uploaded image path or a valid HTTP(S) URL")
	}
	return nil
}

func isOfferPublic(offer *models.Offer, now time.Time) bool {
	return offer.Status == models.OfferApproved &&
		(offer.StartDate == nil || !offer.StartDate.After(now)) &&
		!offer.EndDate.Before(now) &&
		(offer.PublishAt == nil || !offer.PublishAt.After(now)) &&
		offer.Restaurant != nil && offer.Restaurant.Status == models.RestaurantApproved
}

func (h *BannerHandler) applyTarget(banner *models.Banner, linkType, linkValue string, requirePublic bool) error {
	linkType = strings.TrimSpace(linkType)
	linkValue = strings.TrimSpace(linkValue)
	if linkValue == "" {
		return fmt.Errorf("link value is required")
	}

	switch linkType {
	case "offer":
		id, err := uuid.Parse(linkValue)
		if err != nil {
			return fmt.Errorf("invalid offer id")
		}
		offer, err := h.offerRepo.FindByID(id)
		if err != nil {
			return fmt.Errorf("offer not found")
		}
		if requirePublic && !isOfferPublic(offer, time.Now()) {
			return fmt.Errorf("offer is not currently public")
		}
		banner.LinkType = "offer"
		banner.LinkValue = id.String()
		banner.OfferID = &id
		if offer.Restaurant != nil {
			banner.OwnerID = offer.Restaurant.OwnerID
			if strings.TrimSpace(banner.SponsorName) == "" {
				banner.SponsorName = offer.Restaurant.Name
			}
		}
	case "restaurant":
		id, err := uuid.Parse(linkValue)
		if err != nil {
			return fmt.Errorf("invalid restaurant id")
		}
		restaurant, err := h.restaurantRepo.FindByID(id)
		if err != nil {
			return fmt.Errorf("restaurant not found")
		}
		if requirePublic && restaurant.Status != models.RestaurantApproved {
			return fmt.Errorf("restaurant is not currently public")
		}
		banner.LinkType = "restaurant"
		banner.LinkValue = id.String()
		banner.OfferID = nil
		banner.OwnerID = restaurant.OwnerID
		if strings.TrimSpace(banner.SponsorName) == "" {
			banner.SponsorName = restaurant.Name
		}
	case "external":
		parsed, err := url.ParseRequestURI(linkValue)
		if err != nil || (parsed.Scheme != "http" && parsed.Scheme != "https") || parsed.Host == "" {
			return fmt.Errorf("invalid external URL")
		}
		banner.LinkType = "external"
		banner.LinkValue = parsed.String()
		banner.OfferID = nil
		banner.OwnerID = nil
	default:
		return fmt.Errorf("unsupported link type")
	}
	return nil
}

func applyBannerSchedule(banner *models.Banner, startDate, endDate *string) error {
	if startDate != nil && strings.TrimSpace(*startDate) != "" {
		parsed, err := parseBannerTime(*startDate, false)
		if err != nil {
			return fmt.Errorf("invalid start date")
		}
		banner.StartDate = &parsed
	} else {
		banner.StartDate = nil
	}
	if endDate != nil && strings.TrimSpace(*endDate) != "" {
		parsed, err := parseBannerTime(*endDate, true)
		if err != nil {
			return fmt.Errorf("invalid end date")
		}
		banner.EndDate = &parsed
	} else {
		banner.EndDate = nil
	}
	if banner.StartDate != nil && banner.EndDate != nil && banner.EndDate.Before(*banner.StartDate) {
		return fmt.Errorf("end date must be on or after start date")
	}
	return nil
}

// --- Admin routes ---

func (h *BannerHandler) List(c *gin.Context) {
	banners, err := h.repo.FindAll()
	if err != nil {
		response.InternalError(c, "failed to list banners")
		return
	}
	if banners == nil {
		banners = []models.Banner{}
	}
	response.Success(c, banners)
}

func (h *BannerHandler) Create(c *gin.Context) {
	var req bannerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	if err := validateBannerImage(req.Image); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "image", Message: err.Error()}})
		return
	}
	banner := &models.Banner{
		Image:       strings.TrimSpace(req.Image),
		Title:       req.Title,
		SponsorName: req.SponsorName,
		SortOrder:   req.SortOrder,
		Status:      models.BannerApproved,
	}
	if err := applyBannerSchedule(banner, req.StartDate, req.EndDate); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "schedule", Message: err.Error()}})
		return
	}
	if err := h.applyTarget(banner, req.LinkType, req.LinkValue, true); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "link_value", Message: err.Error()}})
		return
	}

	if err := h.repo.Create(banner); err != nil {
		response.InternalError(c, "failed to create banner")
		return
	}

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(userID, userName, userRole, "banner.create", "banner", banner.ID.String(),
			fmt.Sprintf("Created banner: %s", banner.Title))
	}
	h.sseService.Emit("banner.created", gin.H{"id": banner.ID, "status": banner.Status})

	response.SuccessCreated(c, banner)
}

func (h *BannerHandler) Update(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid banner id"},
		})
		return
	}

	banner, err := h.repo.FindByID(id)
	if err != nil {
		response.NotFound(c, "banner not found")
		return
	}

	var req bannerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	if err := validateBannerImage(req.Image); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "image", Message: err.Error()}})
		return
	}
	banner.Image = strings.TrimSpace(req.Image)
	banner.Title = req.Title
	banner.SponsorName = req.SponsorName
	banner.SortOrder = req.SortOrder
	if err := applyBannerSchedule(banner, req.StartDate, req.EndDate); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "schedule", Message: err.Error()}})
		return
	}
	if err := h.applyTarget(banner, req.LinkType, req.LinkValue, banner.Status == models.BannerApproved); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "link_value", Message: err.Error()}})
		return
	}

	if err := h.repo.Update(banner); err != nil {
		response.InternalError(c, "failed to update banner")
		return
	}

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(userID, userName, userRole, "banner.update", "banner", banner.ID.String(),
			fmt.Sprintf("Updated banner: %s", banner.Title))
	}
	h.sseService.Emit("banner.updated", gin.H{"id": banner.ID, "status": banner.Status})

	response.Success(c, banner)
}

func (h *BannerHandler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid banner id"},
		})
		return
	}

	banner, err := h.repo.FindByID(id)
	if err != nil {
		response.NotFound(c, "banner not found")
		return
	}
	bannerTitle := banner.Title

	if err := h.repo.Delete(id); err != nil {
		response.InternalError(c, "failed to delete banner")
		return
	}

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(userID, userName, userRole, "banner.delete", "banner", id.String(),
			fmt.Sprintf("Deleted banner: %s", bannerTitle))
	}
	h.sseService.Emit("banner.deleted", gin.H{"id": id})

	response.SuccessNoContent(c)
}

func (h *BannerHandler) Approve(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid banner id"},
		})
		return
	}

	banner, err := h.repo.FindByID(id)
	if err != nil {
		response.NotFound(c, "banner not found")
		return
	}
	if err := validateBannerImage(banner.Image); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "image", Message: err.Error()}})
		return
	}
	if err := h.applyTarget(banner, banner.LinkType, banner.LinkValue, true); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "link_value", Message: err.Error()}})
		return
	}
	banner.Status = models.BannerApproved
	if err := h.repo.Update(banner); err != nil {
		response.InternalError(c, "failed to approve banner")
		return
	}

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(userID, userName, userRole, "banner.approve", "banner", id.String(),
			fmt.Sprintf("Approved banner: %s", id))
	}
	h.sseService.Emit("banner.approved", gin.H{"id": id})

	response.Success(c, gin.H{"id": id, "status": models.BannerApproved})
}

func (h *BannerHandler) Reject(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid banner id"},
		})
		return
	}

	if _, err := h.repo.FindByID(id); err != nil {
		response.NotFound(c, "banner not found")
		return
	}
	if err := h.repo.Reject(id); err != nil {
		response.InternalError(c, "failed to reject banner")
		return
	}

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(userID, userName, userRole, "banner.reject", "banner", id.String(),
			fmt.Sprintf("Rejected banner: %s", id))
	}
	h.sseService.Emit("banner.rejected", gin.H{"id": id})

	response.Success(c, gin.H{"id": id, "status": models.BannerRejected})
}

// --- Owner dashboard routes ---

func (h *BannerHandler) ListOwner(c *gin.Context) {
	ownerID, _ := middleware.GetOwnerScopeID(c)

	banners, err := h.repo.FindAllByOwner(ownerID)
	if err != nil {
		response.InternalError(c, "failed to list banners")
		return
	}
	if banners == nil {
		banners = []models.Banner{}
	}
	response.Success(c, banners)
}

func (h *BannerHandler) CreateOwner(c *gin.Context) {
	ownerID, _ := middleware.GetOwnerScopeID(c)

	var req ownerBannerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	if err := validateBannerImage(req.Image); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "image", Message: err.Error()}})
		return
	}
	banner := &models.Banner{
		Image:  strings.TrimSpace(req.Image),
		Title:  req.Title,
		Status: models.BannerPending,
	}
	if err := h.applyTarget(banner, "offer", req.OfferID, false); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "offer_id", Message: err.Error()}})
		return
	}
	if banner.OwnerID == nil || *banner.OwnerID != ownerID {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", "offer does not belong to you")
		return
	}

	if err := h.repo.Create(banner); err != nil {
		response.InternalError(c, "failed to create banner")
		return
	}

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(userID, userName, userRole, "banner.create", "banner", banner.ID.String(),
			fmt.Sprintf("Created banner for offer: %s", banner.LinkValue))
	}
	h.sseService.Emit("banner.created", gin.H{"id": banner.ID, "status": banner.Status})

	response.SuccessCreated(c, banner)
}

func (h *BannerHandler) UpdateOwner(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid banner id"},
		})
		return
	}

	ownerID, _ := middleware.GetOwnerScopeID(c)

	banner, err := h.repo.FindByID(id)
	if err != nil {
		response.NotFound(c, "banner not found")
		return
	}

	if banner.OwnerID == nil || *banner.OwnerID != ownerID {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", "banner does not belong to you")
		return
	}

	if banner.Status != models.BannerPending && banner.Status != models.BannerRejected {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", "can only edit pending or rejected banners")
		return
	}

	var req ownerBannerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	if err := validateBannerImage(req.Image); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "image", Message: err.Error()}})
		return
	}
	if err := h.applyTarget(banner, "offer", req.OfferID, false); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "offer_id", Message: err.Error()}})
		return
	}
	if banner.OwnerID == nil || *banner.OwnerID != ownerID {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", "offer does not belong to you")
		return
	}
	banner.Image = strings.TrimSpace(req.Image)
	banner.Title = req.Title
	banner.Status = models.BannerPending

	if err := h.repo.Update(banner); err != nil {
		response.InternalError(c, "failed to update banner")
		return
	}

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(userID, userName, userRole, "banner.update", "banner", banner.ID.String(),
			fmt.Sprintf("Updated banner: %s", banner.Title))
	}
	h.sseService.Emit("banner.updated", gin.H{"id": banner.ID, "status": banner.Status})

	response.Success(c, banner)
}

func (h *BannerHandler) DeleteOwner(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid banner id"},
		})
		return
	}

	ownerID, _ := middleware.GetOwnerScopeID(c)

	banner, err := h.repo.FindByID(id)
	if err != nil {
		response.NotFound(c, "banner not found")
		return
	}

	if banner.OwnerID == nil || *banner.OwnerID != ownerID {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", "banner does not belong to you")
		return
	}

	bannerTitle := banner.Title
	if err := h.repo.Delete(id); err != nil {
		response.InternalError(c, "failed to delete banner")
		return
	}

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(userID, userName, userRole, "banner.delete", "banner", id.String(),
			fmt.Sprintf("Deleted banner: %s", bannerTitle))
	}
	h.sseService.Emit("banner.deleted", gin.H{"id": id})

	response.SuccessNoContent(c)
}

// --- Public routes ---

func (h *BannerHandler) ListActive(c *gin.Context) {
	banners, err := h.repo.FindAllActive()
	if err != nil {
		response.InternalError(c, "failed to list active banners")
		return
	}
	if banners == nil {
		banners = []models.Banner{}
	}
	response.Success(c, banners)
}

func (h *BannerHandler) TrackClick(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid banner id"},
		})
		return
	}

	if err := h.repo.IncrementClickCount(id); err != nil {
		if repository.IsNotFound(err) {
			response.NotFound(c, "active banner not found")
			return
		}
		response.InternalError(c, "failed to track click")
		return
	}

	response.SuccessNoContent(c)
}

func parseBannerTime(value string, endOfDay bool) (time.Time, error) {
	value = strings.TrimSpace(value)
	if parsed, err := time.Parse(time.RFC3339, value); err == nil {
		return parsed, nil
	}
	location, err := time.LoadLocation("Asia/Colombo")
	if err != nil {
		location = time.FixedZone("Asia/Colombo", 5*60*60+30*60)
	}
	parsed, err := time.ParseInLocation("2006-01-02", value, location)
	if err != nil {
		return time.Time{}, fmt.Errorf("unable to parse time: %s", value)
	}
	if endOfDay {
		parsed = parsed.Add(24*time.Hour - time.Nanosecond)
	}
	return parsed, nil
}
