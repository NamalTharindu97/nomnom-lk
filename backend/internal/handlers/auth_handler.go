package handlers

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/config"
	"github.com/nomnom-lk/backend/internal/dto/request"
	"github.com/nomnom-lk/backend/internal/middleware"
	"github.com/nomnom-lk/backend/internal/services"
	"github.com/nomnom-lk/backend/pkg/response"
)

type AuthHandler struct {
	authService     *services.AuthService
	firebaseService *services.FirebaseService
	auditService    *services.AuditService
	browserSession  *browserSession
}

func NewAuthHandler(authService *services.AuthService, firebaseService *services.FirebaseService, auditService *services.AuditService, browserCfg *config.BrowserSessionConfig, jwtCfg *config.JWTConfig) *AuthHandler {
	return &AuthHandler{
		authService:     authService,
		firebaseService: firebaseService,
		auditService:    auditService,
		browserSession:  newBrowserSession(browserCfg, jwtCfg),
	}
}

// BrowserLogin creates a dashboard-only session without exposing JWTs to JavaScript.
func (h *AuthHandler) BrowserLogin(c *gin.Context) {
	var req request.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{{Field: "body", Message: err.Error()}})
		return
	}

	result, err := h.authService.LoginDashboard(req.Email, req.Password)
	if err != nil {
		status := http.StatusUnauthorized
		if err.Error() == "your account has been suspended. contact an administrator" || err.Error() == "access restricted to administrators and restaurant owners only" {
			status = http.StatusForbidden
		}
		h.auditService.LogAction(uuid.Nil, req.Email, "", "auth.login.failed", "user", "",
			fmt.Sprintf("Failed dashboard login attempt for: %s", req.Email))
		response.Error(c, status, "UNAUTHORIZED", err.Error())
		return
	}

	if err := h.browserSession.set(c, result.AccessToken, result.RefreshToken); err != nil {
		response.InternalError(c, "failed to create browser session")
		return
	}
	h.auditService.LogAction(result.User.ID, result.User.Name, result.User.Role, "auth.login", "user", result.User.ID.String(),
		fmt.Sprintf("Dashboard user logged in: %s (%s)", result.User.Name, result.User.Email))
	c.JSON(http.StatusOK, gin.H{"user": result.User, "expires_in": result.ExpiresIn})
}

func (h *AuthHandler) BrowserRefresh(c *gin.Context) {
	refreshToken, err := c.Cookie(browserRefreshCookie)
	if err != nil || refreshToken == "" {
		h.browserSession.clear(c)
		response.Unauthorized(c, "browser session expired")
		return
	}
	currentAccessToken, _ := c.Cookie(middleware.BrowserAccessCookie)
	result, err := h.authService.RefreshDashboard(refreshToken, currentAccessToken)
	if err != nil {
		h.browserSession.clear(c)
		response.Error(c, http.StatusUnauthorized, "UNAUTHORIZED", err.Error())
		return
	}
	if err := h.browserSession.set(c, result.AccessToken, result.RefreshToken); err != nil {
		response.InternalError(c, "failed to refresh browser session")
		return
	}
	c.JSON(http.StatusOK, gin.H{"expires_in": result.ExpiresIn})
}

func (h *AuthHandler) BrowserLogout(c *gin.Context) {
	refreshToken, _ := c.Cookie(browserRefreshCookie)
	h.browserSession.clear(c)
	if refreshToken == "" {
		c.Status(http.StatusNoContent)
		return
	}
	user, err := h.authService.LogoutRefreshToken(refreshToken)
	if err != nil {
		response.InternalError(c, "failed to revoke browser session")
		return
	}
	if user != nil {
		h.auditService.LogAction(user.ID, user.Name, string(user.Role), "auth.logout", "user", user.ID.String(),
			fmt.Sprintf("Dashboard user logged out: %s", user.Name))
	}
	c.Status(http.StatusNoContent)
}

func (h *AuthHandler) BrowserSession(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)
	email, _ := middleware.GetUserEmail(c)
	name, _ := middleware.GetUserName(c)
	role, _ := middleware.GetUserRole(c)
	impersonatedBy, _ := middleware.GetImpersonatedBy(c)
	c.JSON(http.StatusOK, gin.H{
		"user":            gin.H{"id": userID, "email": email, "name": name, "role": role},
		"impersonated_by": impersonatedBy,
	})
}

// Register creates a new user with email & password and sends verification code.
// @Summary Register a new user
// @Tags Auth
// @Accept json
// @Produce json
// @Param body body request.RegisterRequest true "Registration details"
// @Success 201 {object} map[string]string
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

	if err := h.authService.Register(req.Email, req.Password, req.Name); err != nil {
		if err.Error() == "email already registered" {
			response.Error(c, http.StatusConflict, "CONFLICT", err.Error())
			return
		}
		response.InternalError(c, err.Error())
		return
	}

	h.auditService.LogAction(uuid.Nil, req.Email, "", "auth.register", "user", "",
		fmt.Sprintf("New user registered: %s (%s)", req.Name, req.Email))

	if err := h.authService.SendVerificationCode(req.Email); err != nil {
		c.JSON(http.StatusCreated, gin.H{"message": "Account created. Verification email could not be sent. Try resending."})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Verification code sent to your email"})
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
		status := http.StatusUnauthorized
		if err.Error() == "your account has been suspended. contact an administrator" {
			status = http.StatusForbidden
		}
		h.auditService.LogAction(uuid.Nil, req.Email, "", "auth.login.failed", "user", "",
			fmt.Sprintf("Failed login attempt for: %s", req.Email))
		response.Error(c, status, "UNAUTHORIZED", err.Error())
		return
	}

	h.auditService.LogAction(result.User.ID, result.User.Name, string(result.User.Role), "auth.login", "user", result.User.ID.String(),
		fmt.Sprintf("User logged in: %s (%s)", result.User.Name, result.User.Email))

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

	var firebaseUID, email, name string

	if h.firebaseService.IsEnabled() {
		token, err := h.firebaseService.VerifyIDToken(req.FirebaseToken)
		if err != nil {
			response.Error(c, http.StatusUnauthorized, "UNAUTHORIZED", "invalid firebase token")
			return
		}
		firebaseUID = token.UID
		if claims, ok := token.Claims["email"]; ok {
			email, _ = claims.(string)
		}
		if claims, ok := token.Claims["name"]; ok {
			name, _ = claims.(string)
		}
	} else {
		firebaseUID = req.FirebaseToken
		email = "user@firebase.com"
		name = "Firebase User"
	}

	result, err := h.authService.FirebaseLogin(firebaseUID, email, name)
	if err != nil {
		status := http.StatusInternalServerError
		if err.Error() == "your account has been suspended. contact an administrator" {
			status = http.StatusForbidden
		}
		h.auditService.LogAction(uuid.Nil, email, "", "auth.firebase.failed", "user", "",
			fmt.Sprintf("Failed Firebase login attempt for: %s", email))
		response.Error(c, status, "UNAUTHORIZED", err.Error())
		return
	}

	h.auditService.LogAction(result.User.ID, result.User.Name, string(result.User.Role), "auth.firebase", "user", result.User.ID.String(),
		fmt.Sprintf("User logged in via Firebase: %s (%s)", result.User.Name, result.User.Email))

	c.JSON(http.StatusOK, result)
}

// SendVerification sends a verification code to the user's email.
// @Summary Send verification code
// @Tags Auth
// @Accept json
// @Produce json
// @Param body body request.SendVerificationRequest true "Email"
// @Success 200 {object} map[string]string
// @Failure 400 {object} response.ErrorBody
// @Router /auth/send-verification [post]
func (h *AuthHandler) SendVerification(c *gin.Context) {
	var req request.SendVerificationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	if err := h.authService.SendVerificationCode(req.Email); err != nil {
		response.Error(c, http.StatusBadRequest, "BAD_REQUEST", err.Error())
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Verification code sent"})
}

// VerifyEmail verifies a user's email with the code sent to their email.
// @Summary Verify email with code
// @Tags Auth
// @Accept json
// @Produce json
// @Param body body request.VerifyEmailRequest true "Email and verification code"
// @Success 200 {object} response.AuthResponse
// @Failure 400 {object} response.ErrorBody
// @Router /auth/verify-email [post]
func (h *AuthHandler) VerifyEmail(c *gin.Context) {
	var req request.VerifyEmailRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "body", Message: err.Error()},
		})
		return
	}

	result, err := h.authService.VerifyEmail(req.Email, req.Code)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "BAD_REQUEST", err.Error())
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

	userName, _ := middleware.GetUserName(c)
	if userName == "" {
		userName, _ = middleware.GetUserEmail(c)
	}
	userRole, _ := middleware.GetUserRole(c)

	if err := h.authService.Logout(userID); err != nil {
		response.InternalError(c, err.Error())
		return
	}

	h.auditService.LogAction(userID, userName, userRole, "auth.logout", "user", userID.String(),
		fmt.Sprintf("User logged out: %s", userName))

	c.Status(http.StatusNoContent)
}
