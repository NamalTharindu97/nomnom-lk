package handlers

import (
	"fmt"
	"net/http"
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
	repo       *repository.BannerRepo
	offerRepo  *repository.OfferRepo
	auditService *services.AuditService
}

func NewBannerHandler(repo *repository.BannerRepo, offerRepo *repository.OfferRepo, auditService *services.AuditService) *BannerHandler {
	return &BannerHandler{
		repo:         repo,
		offerRepo:    offerRepo,
		auditService: auditService,
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

	banner := &models.Banner{
		Image:       req.Image,
		LinkType:    req.LinkType,
		LinkValue:   req.LinkValue,
		Title:       req.Title,
		SponsorName: req.SponsorName,
		SortOrder:   req.SortOrder,
		Status:      models.BannerApproved,
	}
	if req.StartDate != nil {
		if t, err := parseTime(*req.StartDate); err == nil {
			banner.StartDate = &t
		}
	}
	if req.EndDate != nil {
		if t, err := parseTime(*req.EndDate); err == nil {
			banner.EndDate = &t
		}
	}
	if req.OfferID != nil {
		if id, err := uuid.Parse(*req.OfferID); err == nil {
			banner.OfferID = &id
		}
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

	banner.Image = req.Image
	banner.LinkType = req.LinkType
	banner.LinkValue = req.LinkValue
	banner.Title = req.Title
	banner.SponsorName = req.SponsorName
	banner.SortOrder = req.SortOrder
	if req.StartDate != nil {
		if t, err := parseTime(*req.StartDate); err == nil {
			banner.StartDate = &t
		}
	} else {
		banner.StartDate = nil
	}
	if req.EndDate != nil {
		if t, err := parseTime(*req.EndDate); err == nil {
			banner.EndDate = &t
		}
	} else {
		banner.EndDate = nil
	}
	if req.OfferID != nil {
		if id, err := uuid.Parse(*req.OfferID); err == nil {
			banner.OfferID = &id
		}
	} else {
		banner.OfferID = nil
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

	banner, _ := h.repo.FindByID(id)
	bannerTitle := ""
	if banner != nil {
		bannerTitle = banner.Title
	}

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

	if err := h.repo.Approve(id); err != nil {
		response.InternalError(c, "failed to approve banner")
		return
	}

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(userID, userName, userRole, "banner.approve", "banner", id.String(),
			fmt.Sprintf("Approved banner: %s", id))
	}

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

	offerID, err := uuid.Parse(req.OfferID)
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "offer_id", Message: "invalid offer id"},
		})
		return
	}

	offer, err := h.offerRepo.FindByID(offerID)
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "offer_id", Message: "offer not found"},
		})
		return
	}

	if offer.Restaurant == nil || offer.Restaurant.OwnerID == nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "offer_id", Message: "offer has no restaurant owner"},
		})
		return
	}

	if *offer.Restaurant.OwnerID != ownerID {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", "offer does not belong to you")
		return
	}

	banner := &models.Banner{
		Image:     req.Image,
		LinkType:  "offer",
		LinkValue: offerID.String(),
		Title:     req.Title,
		Status:    models.BannerPending,
		OwnerID:   &ownerID,
		OfferID:   &offerID,
	}

	if err := h.repo.Create(banner); err != nil {
		response.InternalError(c, "failed to create banner")
		return
	}

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(userID, userName, userRole, "banner.create", "banner", banner.ID.String(),
			fmt.Sprintf("Created banner for offer: %s", offerID))
	}

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

	banner.Image = req.Image
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
		response.InternalError(c, "failed to track click")
		return
	}

	response.SuccessNoContent(c)
}

func parseTime(s string) (time.Time, error) {
	formats := []string{
		"2006-01-02T15:04:05Z",
		"2006-01-02T15:04:05-07:00",
	}
	for _, f := range formats {
		if t, err := time.Parse(f, s); err == nil {
			return t, nil
		}
	}
	if t, err := time.ParseInLocation("2006-01-02", s, time.Local); err == nil {
		return t, nil
	}
	return time.Time{}, fmt.Errorf("unable to parse time: %s", s)
}
