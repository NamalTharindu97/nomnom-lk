package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/nomnom-lk/backend/internal/middleware"
	"github.com/nomnom-lk/backend/internal/services"
	"github.com/nomnom-lk/backend/pkg/response"
)

type ImpersonationHandler struct {
	impersonationService *services.ImpersonationService
}

func NewImpersonationHandler(impersonationService *services.ImpersonationService) *ImpersonationHandler {
	return &ImpersonationHandler{impersonationService: impersonationService}
}

type startImpersonationRequest struct {
	UserID string `json:"user_id" binding:"required,uuid"`
}

func (h *ImpersonationHandler) Start(c *gin.Context) {
	adminID, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "authentication required")
		return
	}

	var req startImpersonationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "user_id", Message: "valid user id is required"},
		})
		return
	}

	targetUserID, err := uuid.Parse(req.UserID)
	if err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "user_id", Message: "invalid user id"},
		})
		return
	}

	impersonationToken, target, err := h.impersonationService.StartImpersonation(adminID, targetUserID)
	if err != nil {
		code := http.StatusBadRequest
		if err.Error() == "user not found" {
			code = http.StatusNotFound
		}
		response.Error(c, code, "BAD_REQUEST", err.Error())
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"access_token":    impersonationToken,
		"user": gin.H{
			"id":    target.ID,
			"email": target.Email,
			"name":  target.Name,
			"role":  target.Role,
		},
		"impersonated_by": adminID,
	})
}

func (h *ImpersonationHandler) Stop(c *gin.Context) {
	impersonatedBy, exists := middleware.GetImpersonatedBy(c)
	if !exists {
		response.Error(c, http.StatusBadRequest, "BAD_REQUEST", "not currently impersonating")
		return
	}

	adminID, err := uuid.Parse(impersonatedBy)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "BAD_REQUEST", "invalid impersonation session")
		return
	}

	adminToken, target, err := h.impersonationService.StopImpersonation(adminID)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "BAD_REQUEST", err.Error())
		return
	}

	userInfo := gin.H{}
	if target != nil {
		userInfo = gin.H{
			"id":    target.ID,
			"email": target.Email,
			"name":  target.Name,
			"role":  target.Role,
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"access_token": adminToken,
		"user":         userInfo,
	})
}

func (h *ImpersonationHandler) Status(c *gin.Context) {
	impersonatedBy, exists := middleware.GetImpersonatedBy(c)
	if !exists {
		response.Success(c, gin.H{
			"is_impersonating": false,
		})
		return
	}

	adminID, err := uuid.Parse(impersonatedBy)
	if err != nil {
		response.Success(c, gin.H{
			"is_impersonating": false,
		})
		return
	}

	isActive, target, startedAt, err := h.impersonationService.GetImpersonationStatus(adminID)
	if err != nil || !isActive {
		response.Success(c, gin.H{
			"is_impersonating": false,
		})
		return
	}

	userInfo := gin.H{}
	if target != nil {
		userInfo = gin.H{
			"id":    target.ID,
			"email": target.Email,
			"name":  target.Name,
			"role":  target.Role,
		}
	}

	response.Success(c, gin.H{
		"is_impersonating": true,
		"impersonated_user": userInfo,
		"started_at":        startedAt,
	})
}
