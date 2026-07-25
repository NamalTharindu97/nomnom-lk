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

type CuisineTagHandler struct {
	repo *repository.CuisineTagRepo
}

func NewCuisineTagHandler(repo *repository.CuisineTagRepo) *CuisineTagHandler {
	return &CuisineTagHandler{repo: repo}
}

func (h *CuisineTagHandler) List(c *gin.Context) {
	tags, err := h.repo.FindAll()
	if err != nil {
		response.InternalError(c, "failed to list cuisine tags")
		return
	}
	if tags == nil {
		tags = []models.CuisineTag{}
	}
	response.Success(c, tags)
}

type cuisineTagRequest struct {
	Name string `json:"name" binding:"required,max=100"`
}

func (h *CuisineTagHandler) Create(c *gin.Context) {
	var req cuisineTagRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "name", Message: err.Error()}})
		return
	}

	name := strings.TrimSpace(req.Name)
	if name == "" {
		response.ValidationError(c, []response.ErrorDetail{{Field: "name", Message: "name is required"}})
		return
	}

	tag := &models.CuisineTag{Name: name}
	if err := h.repo.Create(tag); err != nil {
		response.InternalError(c, "failed to create cuisine tag")
		return
	}

	c.JSON(http.StatusCreated, tag)
}

func (h *CuisineTagHandler) Update(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "id", Message: "invalid id"}})
		return
	}

	var req cuisineTagRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "name", Message: err.Error()}})
		return
	}

	name := strings.TrimSpace(req.Name)
	if name == "" {
		response.ValidationError(c, []response.ErrorDetail{{Field: "name", Message: "name is required"}})
		return
	}

	if err := h.repo.Update(id, name); err != nil {
		response.InternalError(c, "failed to update cuisine tag")
		return
	}

	response.Success(c, gin.H{"id": id, "name": name})
}

func (h *CuisineTagHandler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "id", Message: "invalid id"}})
		return
	}

	if err := h.repo.Delete(id); err != nil {
		response.InternalError(c, "failed to delete cuisine tag")
		return
	}

	c.Status(http.StatusNoContent)
}
