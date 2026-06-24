package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/nomnom-lk/backend/internal/dto/request"
	"github.com/nomnom-lk/backend/internal/services"
	"github.com/nomnom-lk/backend/internal/middleware"
	"github.com/nomnom-lk/backend/pkg/response"
)

type AuthHandler struct {
	authService *services.AuthService
}

func NewAuthHandler(authService *services.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

// Register creates a new user with email & password.
// @Summary Register a new user
// @Tags Auth
// @Accept json
// @Produce json
// @Param body body request.RegisterRequest true "Registration details"
// @Success 201 {object} response.AuthResponse
// @Failure 400 {object} response.ErrorBody
// @Failure 409 {object} response.ErrorBody
// @Router /auth/register [post]
func (h *AuthHandler) Register(c *gin.Context) {
	var req request.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	result, err := h.authService.Register(req.Email, req.Password, req.Name)
	if err != nil {
		if err.Error() == "email already registered" {
			response.Error(c, http.StatusConflict, "CONFLICT", err.Error())
			return
		}
		response.InternalError(c, err.Error())
		return
	}

	c.JSON(http.StatusCreated, result)
}

// Login authenticates a user with email & password.
// @Summary Login with email & password
// @Tags Auth
// @Accept json
// @Produce json
// @Param body body request.LoginRequest true "Login credentials"
// @Success 200 {object} response.AuthResponse
// @Failure 401 {object} response.ErrorBody
// @Router /auth/login [post]
func (h *AuthHandler) Login(c *gin.Context) {
	var req request.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	result, err := h.authService.Login(req.Email, req.Password)
	if err != nil {
		response.Error(c, http.StatusUnauthorized, "UNAUTHORIZED", err.Error())
		return
	}

	c.JSON(http.StatusOK, result)
}

// FirebaseLogin authenticates with a Firebase ID token.
// @Summary Authenticate with Firebase
// @Tags Auth
// @Accept json
// @Produce json
// @Param body body request.FirebaseRequest true "Firebase ID token"
// @Success 200 {object} response.AuthResponse
// @Router /auth/firebase [post]
func (h *AuthHandler) FirebaseLogin(c *gin.Context) {
	var req request.FirebaseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	// TODO: Verify Firebase token using firebase-admin-go SDK
	// For now, extract mock claims from context
	firebaseUID := c.GetString("firebase_uid")
	email := c.GetString("firebase_email")
	name := c.GetString("firebase_name")

	if firebaseUID == "" {
		firebaseUID = req.FirebaseToken
		email = "user@firebase.com"
		name = "Firebase User"
	}

	result, err := h.authService.FirebaseLogin(firebaseUID, email, name)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}

	c.JSON(http.StatusOK, result)
}

// Refresh issues a new access token using a refresh token.
// @Summary Refresh access token
// @Tags Auth
// @Accept json
// @Produce json
// @Param body body request.RefreshRequest true "Refresh token"
// @Success 200 {object} response.TokenPairResponse
// @Failure 401 {object} response.ErrorBody
// @Router /auth/refresh [post]
func (h *AuthHandler) Refresh(c *gin.Context) {
	var req request.RefreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	result, err := h.authService.Refresh(req.RefreshToken)
	if err != nil {
		response.Error(c, http.StatusUnauthorized, "UNAUTHORIZED", err.Error())
		return
	}

	c.JSON(http.StatusOK, result)
}

// Logout invalidates all refresh tokens for the authenticated user.
// @Summary Logout
// @Tags Auth
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 204
// @Router /auth/logout [post]
func (h *AuthHandler) Logout(c *gin.Context) {
	userID, exists := middleware.GetUserID(c)
	if !exists {
		response.Unauthorized(c, "authentication required")
		return
	}

	if err := h.authService.Logout(userID); err != nil {
		response.InternalError(c, err.Error())
		return
	}

	c.Status(http.StatusNoContent)
}
