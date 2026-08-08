package handlers

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/nomnom-lk/backend/pkg/response"
)

type OrderPlatformHandler struct {
	repo *repository.OrderPlatformRepo
}

func NewOrderPlatformHandler(repo *repository.OrderPlatformRepo) *OrderPlatformHandler {
	return &OrderPlatformHandler{repo: repo}
}

func (h *OrderPlatformHandler) List(c *gin.Context) {
	platforms, err := h.repo.FindAll()
	if err != nil {
		response.InternalError(c, "failed to list order platforms")
		return
	}
	if platforms == nil {
		platforms = []models.OrderPlatform{}
	}
	response.Success(c, platforms)
}

type orderPlatformRequest struct {
	Name           string  `json:"name" binding:"required,max=100"`
	DisplayName    string  `json:"display_name" binding:"required,max=100"`
	PrimaryColor   string  `json:"primary_color" binding:"required,max=9"`
	DeepLinkScheme string  `json:"deep_link_scheme" binding:"required,max=100"`
	LogoURL        *string `json:"logo_url,omitempty"`
}

func (h *OrderPlatformHandler) Create(c *gin.Context) {
	var req orderPlatformRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "body", Message: err.Error()}})
		return
	}

	name := strings.TrimSpace(req.Name)
	if name == "" {
		response.ValidationError(c, []response.ErrorDetail{{Field: "name", Message: "name is required"}})
		return
	}

	slug := strings.ToLower(strings.ReplaceAll(name, " ", "_"))
	platform := &models.OrderPlatform{
		Name:           name,
		Slug:           slug,
		DisplayName:    req.DisplayName,
		PrimaryColor:   req.PrimaryColor,
		DeepLinkScheme: req.DeepLinkScheme,
		LogoURL:        req.LogoURL,
	}

	if err := h.repo.Create(platform); err != nil {
		response.InternalError(c, "failed to create order platform")
		return
	}

	c.JSON(http.StatusCreated, platform)
}

func (h *OrderPlatformHandler) Update(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "id", Message: "invalid id"}})
		return
	}

	var req orderPlatformRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "body", Message: err.Error()}})
		return
	}

	if err := h.repo.Update(id, req.Name, req.DisplayName, req.PrimaryColor, req.DeepLinkScheme, req.LogoURL); err != nil {
		response.InternalError(c, "failed to update order platform")
		return
	}

	response.Success(c, gin.H{"id": id, "updated": true})
}

func (h *OrderPlatformHandler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "id", Message: "invalid id"}})
		return
	}

	if err := h.repo.Delete(id); err != nil {
		response.InternalError(c, "failed to delete order platform")
		return
	}

	c.Status(http.StatusNoContent)
}
