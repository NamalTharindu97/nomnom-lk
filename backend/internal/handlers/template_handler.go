package handlers

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/nomnom-lk/backend/pkg/response"
)

type TemplateHandler struct {
	repo *repository.NotificationTemplateRepo
}

func NewTemplateHandler(repo *repository.NotificationTemplateRepo) *TemplateHandler {
	return &TemplateHandler{repo: repo}
}

type templateRequest struct {
	Name  string `json:"name" binding:"required,max=255"`
	Title string `json:"title" binding:"required,max=255"`
	Body  string `json:"body" binding:"required"`
}

func (h *TemplateHandler) List(c *gin.Context) {
	templates, err := h.repo.FindAll()
	if err != nil {
		response.InternalError(c, "failed to list templates")
		return
	}
	if templates == nil {
		templates = []models.NotificationTemplate{}
	}
	response.Success(c, gin.H{"data": templates})
}

func (h *TemplateHandler) Create(c *gin.Context) {
	var req templateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	template := &models.NotificationTemplate{
		Name:  req.Name,
		Title: req.Title,
		Body:  req.Body,
	}
	if err := h.repo.Create(template); err != nil {
		response.InternalError(c, "failed to create template")
		return
	}
	response.SuccessCreated(c, template)
}

func (h *TemplateHandler) Update(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid template id"},
		})
		return
	}

	var req templateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	template, err := h.repo.FindByID(id)
	if err != nil {
		response.NotFound(c, "template not found")
		return
	}

	template.Name = req.Name
	template.Title = req.Title
	template.Body = req.Body
	if err := h.repo.Update(template); err != nil {
		response.InternalError(c, "failed to update template")
		return
	}
	response.Success(c, template)
}

func (h *TemplateHandler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "id", Message: "invalid template id"},
		})
		return
	}
	if err := h.repo.Delete(id); err != nil {
		response.InternalError(c, "failed to delete template")
		return
	}
	response.SuccessNoContent(c)
}
