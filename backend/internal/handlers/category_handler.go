package handlers

import (
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/nomnom-lk/backend/pkg/response"
)

type CategoryHandler struct {
	repo *repository.CategoryRepo
}

func NewCategoryHandler(repo *repository.CategoryRepo) *CategoryHandler {
	return &CategoryHandler{repo: repo}
}

type categoryRequest struct {
	Name string `json:"name" binding:"required,max=100"`
}

func slugify(name string) string {
	s := strings.ToLower(strings.TrimSpace(name))
	s = strings.ReplaceAll(s, " ", "-")
	return s
}

func (h *CategoryHandler) List(c *gin.Context) {
	cats, err := h.repo.FindAll()
	if err != nil {
		response.InternalError(c, "failed to list categories")
		return
	}
	if cats == nil {
		cats = []models.Category{}
	}
	response.Success(c, cats)
}

func (h *CategoryHandler) Create(c *gin.Context) {
	var req categoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "body", Message: err.Error()}})
		return
	}

	cat := &models.Category{
		Name: req.Name,
		Slug: slugify(req.Name),
	}
	if err := h.repo.Create(cat); err != nil {
		response.InternalError(c, "failed to create category")
		return
	}
	response.SuccessCreated(c, cat)
}

func (h *CategoryHandler) Update(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "id", Message: "invalid category id"}})
		return
	}

	var req categoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "body", Message: err.Error()}})
		return
	}

	cat, err := h.repo.FindByID(id)
	if err != nil {
		response.NotFound(c, "category not found")
		return
	}

	cat.Name = req.Name
	cat.Slug = slugify(req.Name)
	if err := h.repo.Update(cat); err != nil {
		response.InternalError(c, "failed to update category")
		return
	}
	response.Success(c, cat)
}

func (h *CategoryHandler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "id", Message: "invalid category id"}})
		return
	}
	if err := h.repo.Delete(id); err != nil {
		response.InternalError(c, "failed to delete category")
		return
	}
	response.SuccessNoContent(c)
}
