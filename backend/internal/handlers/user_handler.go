package handlers

import (
	"github.com/gin-gonic/gin"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/nomnom-lk/backend/pkg/pagination"
	"github.com/nomnom-lk/backend/pkg/response"
)

type UserHandler struct {
	repo *repository.UserRepo
}

func NewUserHandler(repo *repository.UserRepo) *UserHandler {
	return &UserHandler{repo: repo}
}

func (h *UserHandler) List(c *gin.Context) {
	params := pagination.Extract(c)

	users, total, err := h.repo.FindAll(params.Page, params.PerPage)
	if err != nil {
		response.InternalError(c, "failed to list users")
		return
	}

	data := make([]gin.H, len(users))
	for i, u := range users {
		data[i] = gin.H{
			"id":         u.ID,
			"email":      u.Email,
			"name":       u.Name,
			"role":       u.Role,
			"is_active":  u.IsActive,
			"created_at": u.CreatedAt,
		}
	}

	response.SuccessPaginated(c, data, pagination.Meta(params, total))
}
