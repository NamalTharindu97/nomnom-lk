package handlers

import (
	"time"

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

	var from, to time.Time
	if fromStr := c.Query("from"); fromStr != "" {
		from, _ = time.Parse("2006-01-02", fromStr)
	}
	if toStr := c.Query("to"); toStr != "" {
		to, _ = time.Parse("2006-01-02 15:04:05", toStr+" 23:59:59")
	}

	filterParams := repository.AuditLogFilterParams{
		Action:     c.Query("action"),
		EntityType: c.Query("entity_type"),
		Search:     c.Query("search"),
		Role:       c.Query("role"),
		From:       from,
		To:         to,
		Page:       params.Page,
		PerPage:    params.PerPage,
	}

	logs, total, err := h.repo.FindAllFiltered(filterParams)
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
			"admin_role":  l.AdminRole,
			"action":      l.Action,
			"entity_type": l.EntityType,
			"entity_id":   l.EntityID,
			"details":     l.Details,
			"created_at":  l.CreatedAt,
		}
	}

	response.SuccessPaginated(c, data, pagination.Meta(params, total))
}
