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
	"github.com/nomnom-lk/backend/pkg/hash"
	"github.com/nomnom-lk/backend/pkg/pagination"
	"github.com/nomnom-lk/backend/pkg/response"
)

type UserHandler struct {
	repo         *repository.UserRepo
	auditService *services.AuditService
}

func NewUserHandler(repo *repository.UserRepo, auditService *services.AuditService) *UserHandler {
	return &UserHandler{
		repo:         repo,
		auditService: auditService,
	}
}

func (h *UserHandler) Me(c *gin.Context) {
	userID, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "authentication required")
		return
	}

	user, err := h.repo.FindByID(userID)
	if err != nil {
		response.NotFound(c, "user not found")
		return
	}

	response.Success(c, gin.H{
		"id":           user.ID,
		"email":        user.Email,
		"name":         user.Name,
		"avatar_url":   user.AvatarURL,
		"phone":        user.Phone,
		"role":         user.Role,
		"is_onboarded": true,
		"created_at":   user.CreatedAt,
	})
}

func (h *UserHandler) List(c *gin.Context) {
	params := pagination.Extract(c)
	email := c.Query("email")
	role := c.Query("role")
	status := c.DefaultQuery("status", "active")

	users, total, err := h.repo.FindAll(params.Page, params.PerPage, email, role, status)
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

func (h *UserHandler) Create(c *gin.Context) {
	var req struct {
		Email    string `json:"email" binding:"required,email"`
		Name     string `json:"name" binding:"required"`
		Password string `json:"password" binding:"required,min=6"`
		Role     string `json:"role"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	role := models.RoleUser
	if req.Role == "restaurant_owner" || req.Role == "admin" {
		role = models.UserRole(req.Role)
	}

	hashedPassword, err := hash.HashPassword(req.Password)
	if err != nil {
		response.InternalError(c, "failed to hash password")
		return
	}

	now := time.Now()
	user := &models.User{
		Email:           req.Email,
		Name:            req.Name,
		PasswordHash:    hashedPassword,
		Role:            role,
		IsActive:        true,
		EmailVerifiedAt: &now,
	}

	if err := h.repo.Create(user); err != nil {
		response.Error(c, http.StatusConflict, "CONFLICT", "user with this email already exists")
		return
	}

	if uid, ok := middleware.GetUserID(c); ok {
		n, _ := middleware.GetUserName(c)
		r, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(uid, n, r, "user.create", "user", user.ID.String(),
			fmt.Sprintf("Created user: %s (%s)", user.Email, user.Role))
	}

	response.Success(c, gin.H{
		"id":         user.ID,
		"email":      user.Email,
		"name":       user.Name,
		"role":       user.Role,
		"is_active":  user.IsActive,
		"created_at": user.CreatedAt,
	})
}

func (h *UserHandler) Update(c *gin.Context) {
	var req struct {
		Role     *string `json:"role"`
		Name     *string `json:"name"`
		IsActive *bool   `json:"is_active"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "BAD_REQUEST", "invalid request body")
		return
	}

	userID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.Error(c, http.StatusBadRequest, "BAD_REQUEST", "invalid user id")
		return
	}

	user, err := h.repo.FindByID(userID)
	if err != nil {
		response.NotFound(c, "user not found")
		return
	}

	if req.Role != nil {
		user.Role = models.UserRole(*req.Role)
	}
	if req.Name != nil {
		user.Name = *req.Name
	}
	if req.IsActive != nil {
		user.IsActive = *req.IsActive
	}

	if err := h.repo.Update(user); err != nil {
		response.InternalError(c, "failed to update user")
		return
	}

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		changes := ""
		if req.Role != nil {
			changes = fmt.Sprintf("role changed to %s", *req.Role)
		}
		if req.IsActive != nil {
			if changes != "" {
				changes += "; "
			}
			if *req.IsActive {
				changes += "status: activated"
			} else {
				changes += "status: deactivated"
			}
		}
		if changes != "" {
			h.auditService.LogAction(userID, userName, userRole, "user.update", "user", user.ID.String(),
				fmt.Sprintf("User %s (%s): %s", user.Name, user.Email, changes))
		}
	}

	response.Success(c, gin.H{
		"id":    user.ID,
		"email": user.Email,
		"name":  user.Name,
		"role":  user.Role,
	})
}

func (h *UserHandler) UpdateProfile(c *gin.Context) {
	var req struct {
		Name      *string `json:"name"`
		Phone     *string `json:"phone"`
		AvatarURL *string `json:"avatar_url"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "BAD_REQUEST", "invalid request body")
		return
	}

	userID, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "authentication required")
		return
	}

	user, err := h.repo.FindByID(userID)
	if err != nil {
		response.NotFound(c, "user not found")
		return
	}

	if req.Name != nil {
		user.Name = *req.Name
	}
	if req.Phone != nil {
		user.Phone = req.Phone
	}
	if req.AvatarURL != nil {
		user.AvatarURL = req.AvatarURL
	}

	if err := h.repo.Update(user); err != nil {
		response.InternalError(c, "failed to update profile")
		return
	}

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(userID, userName, userRole, "user.profile_updated", "user", user.ID.String(),
			fmt.Sprintf("Profile updated for user: %s (%s)", user.Name, user.Email))
	}

	response.Success(c, gin.H{
		"id":         user.ID,
		"email":      user.Email,
		"name":       user.Name,
		"avatar_url": user.AvatarURL,
		"phone":      user.Phone,
		"role":       user.Role,
		"created_at": user.CreatedAt,
	})
}

func (h *UserHandler) ChangePassword(c *gin.Context) {
	var req struct {
		CurrentPassword string `json:"current_password" binding:"required"`
		NewPassword     string `json:"new_password" binding:"required,min=6"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	userID, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "authentication required")
		return
	}

	user, err := h.repo.FindByID(userID)
	if err != nil {
		response.NotFound(c, "user not found")
		return
	}

	if !hash.CheckPassword(req.CurrentPassword, user.PasswordHash) {
		response.Error(c, http.StatusUnauthorized, "INVALID_PASSWORD", "current password is incorrect")
		return
	}

	newHash, err := hash.HashPassword(req.NewPassword)
	if err != nil {
		response.InternalError(c, "failed to hash password")
		return
	}

	user.PasswordHash = newHash
	if err := h.repo.Update(user); err != nil {
		response.InternalError(c, "failed to update password")
		return
	}

	if userID, ok := middleware.GetUserID(c); ok {
		userName, _ := middleware.GetUserName(c)
		userRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(userID, userName, userRole, "user.password_changed", "user", user.ID.String(),
			fmt.Sprintf("Password changed for user: %s (%s)", user.Name, user.Email))
	}

	response.Success(c, gin.H{"message": "password updated successfully"})
}

func (h *UserHandler) Delete(c *gin.Context) {
	userID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.Error(c, http.StatusBadRequest, "BAD_REQUEST", "invalid user id")
		return
	}

	user, err := h.repo.FindByID(userID)
	if err != nil {
		response.NotFound(c, "user not found")
		return
	}

	if err := h.repo.SoftDelete(userID); err != nil {
		response.InternalError(c, "failed to delete user")
		return
	}

	if adminID, ok := middleware.GetUserID(c); ok {
		adminName, _ := middleware.GetUserName(c)
		adminRole, _ := middleware.GetUserRole(c)
		h.auditService.LogAction(adminID, adminName, adminRole, "user.delete", "user", userID.String(),
			fmt.Sprintf("Deleted user: %s (%s)", user.Name, user.Email))
	}

	response.SuccessNoContent(c)
}

func (h *UserHandler) RequestDeletion(c *gin.Context) {
	userID, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "authentication required")
		return
	}

	user, err := h.repo.FindByID(userID)
	if err != nil {
		response.NotFound(c, "user not found")
		return
	}

	if !user.CanSelfDelete() {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", "only consumer accounts can self-delete. contact support for other account types")
		return
	}

	if user.IsPendingDeletion() {
		response.Error(c, http.StatusConflict, "CONFLICT", "deletion already requested")
		return
	}

	now := time.Now()
	deletionTime := now.Add(30 * 24 * time.Hour)
	user.DeletionRequestedAt = &now
	user.DeletionScheduledAt = &deletionTime

	if err := h.repo.Update(user); err != nil {
		response.InternalError(c, "failed to schedule deletion")
		return
	}

	h.auditService.LogAction(userID, user.Name, string(user.Role), "user.deletion.request", "user", userID.String(),
		fmt.Sprintf("User requested account deletion: %s (%s), scheduled for %s", user.Name, user.Email, deletionTime.Format(time.RFC3339)))

	c.JSON(http.StatusOK, gin.H{
		"message":         "account deletion scheduled",
		"scheduled_at":    deletionTime,
		"recovery_window": "30 days",
	})
}

func (h *UserHandler) CancelDeletion(c *gin.Context) {
	userID, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "authentication required")
		return
	}

	user, err := h.repo.FindByID(userID)
	if err != nil {
		response.NotFound(c, "user not found")
		return
	}

	if !user.IsPendingDeletion() {
		response.Error(c, http.StatusBadRequest, "BAD_REQUEST", "no pending deletion request")
		return
	}

	user.DeletionRequestedAt = nil
	user.DeletionScheduledAt = nil

	if err := h.repo.Update(user); err != nil {
		response.InternalError(c, "failed to cancel deletion")
		return
	}

	h.auditService.LogAction(userID, user.Name, string(user.Role), "user.deletion.cancel", "user", userID.String(),
		fmt.Sprintf("User cancelled account deletion: %s (%s)", user.Name, user.Email))

	c.JSON(http.StatusOK, gin.H{"message": "account deletion cancelled"})
}
