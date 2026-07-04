package handlers

import (
	"github.com/gin-gonic/gin"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/nomnom-lk/backend/pkg/pagination"
	"github.com/nomnom-lk/backend/pkg/response"
)

type AuditLogHandler struct {
	repo *repository.AuditLogRepo
}

func NewAuditLogHandler(repo *repository.AuditLogRepo) *AuditLogHandler {
	return &AuditLogHandler{repo: repo}
}

func (h *AuditLogHandler) List(c *gin.Context) {
	params := pagination.Extract(c)

	logs, total, err := h.repo.FindAll(params.Page, params.PerPage)
	if err != nil {
		response.InternalError(c, "failed to list audit logs")
		return
	}

	data := make([]gin.H, len(logs))
	for i, l := range logs {
		data[i] = gin.H{
			"id":          l.ID,
			"admin_id":    l.AdminID,
			"admin_name":  l.AdminName,
			"action":      l.Action,
			"entity_type": l.EntityType,
			"entity_id":   l.EntityID,
			"details":     l.Details,
			"created_at":  l.CreatedAt,
		}
	}

	response.SuccessPaginated(c, data, pagination.Meta(params, total))
}
