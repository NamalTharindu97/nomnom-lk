package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/middleware"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/nomnom-lk/backend/pkg/response"
)

type SocialPlatformHandler struct {
	repo *repository.SocialPlatformRepo
}

func NewSocialPlatformHandler(repo *repository.SocialPlatformRepo) *SocialPlatformHandler {
	return &SocialPlatformHandler{repo: repo}
}

func (h *SocialPlatformHandler) List(c *gin.Context) {
	platforms, err := h.repo.FindAll()
	if err != nil {
		response.InternalError(c, "failed to list social platforms")
		return
	}
	if platforms == nil {
		platforms = []models.SocialPlatform{}
	}
	if middleware.IsPortfolioViewer(c) {
		data := make([]gin.H, len(platforms))
		for i, platform := range platforms {
			data[i] = gin.H{
				"id": platform.ID, "name": platform.Name, "slug": platform.Slug,
				"display_name": platform.DisplayName, "primary_color": platform.PrimaryColor,
				"logo_url": platform.LogoURL, "sort_order": platform.SortOrder,
			}
		}
		response.Success(c, data)
		return
	}
	response.Success(c, platforms)
}

type socialPlatformRequest struct {
	Name         string  `json:"name" binding:"required,max=100"`
	DisplayName  string  `json:"display_name" binding:"required,max=100"`
	PrimaryColor string  `json:"primary_color" binding:"required,max=9"`
	LogoURL      *string `json:"logo_url,omitempty"`
	SortOrder    int     `json:"sort_order"`
}

func (h *SocialPlatformHandler) Create(c *gin.Context) {
	var req socialPlatformRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "body", Message: err.Error()}})
		return
	}
	slug := slugFromName(req.Name)
	platform := &models.SocialPlatform{
		Name:         req.Name,
		Slug:         slug,
		DisplayName:  req.DisplayName,
		PrimaryColor: req.PrimaryColor,
		LogoURL:      req.LogoURL,
		SortOrder:    req.SortOrder,
	}
	if err := h.repo.Create(platform); err != nil {
		response.InternalError(c, "failed to create social platform")
		return
	}
	c.JSON(http.StatusCreated, platform)
}

func (h *SocialPlatformHandler) Update(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "id", Message: "invalid id"}})
		return
	}
	var req socialPlatformRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "body", Message: err.Error()}})
		return
	}
	if err := h.repo.Update(id, req.Name, req.DisplayName, req.PrimaryColor, req.LogoURL, req.SortOrder); err != nil {
		response.InternalError(c, "failed to update social platform")
		return
	}
	response.Success(c, gin.H{"id": id, "updated": true})
}

func (h *SocialPlatformHandler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "id", Message: "invalid id"}})
		return
	}
	if err := h.repo.Delete(id); err != nil {
		response.InternalError(c, "failed to delete social platform")
		return
	}
	c.Status(http.StatusNoContent)
}

func slugFromName(name string) string {
	slug := ""
	for _, c := range name {
		if c >= 'A' && c <= 'Z' {
			slug += string(c + 32)
		} else if (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') {
			slug += string(c)
		} else if c == ' ' || c == '-' {
			slug += "_"
		}
	}
	return slug
}
