//go:build integration

package handlers

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/config"
	"github.com/nomnom-lk/backend/internal/database"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/nomnom-lk/backend/internal/services"
	"github.com/rs/zerolog"
	"github.com/stretchr/testify/require"
)

func TestIntegration_BrowserDemoCreatesAuditedAccessOnlySession(t *testing.T) {
	db := database.NewPostgresDB(&config.DatabaseConfig{
		Host: "localhost", Port: "5432", User: "nomnom", Password: "nomnom123", Name: "nomnom_test", SSLMode: "disable",
	})
	email := "demo_handler_" + uuid.New().String()[:8] + "@test.com"
	now := time.Now()
	viewer := &models.User{Email: email, Name: "Recruiter Demo", Role: models.RolePortfolioViewer, IsActive: true, EmailVerifiedAt: &now}
	require.NoError(t, db.Create(viewer).Error)
	t.Cleanup(func() {
		db.Where("admin_id = ?", viewer.ID).Delete(&models.AuditLog{})
		db.Delete(viewer)
	})

	jwtCfg := &config.JWTConfig{Secret: "test-secret-key-for-testing-only", AccessExpiry: "15m", RefreshExpiry: "720h"}
	userRepo := repository.NewUserRepo(db)
	authService := services.NewAuthService(userRepo, repository.NewRefreshTokenRepo(db), jwtCfg, nil, services.NewEmailService(&config.SMTPConfig{}, zerolog.Nop()))
	auditService := services.NewAuditService(repository.NewAuditLogRepo(db))
	handler := NewAuthHandler(authService, nil, auditService, &config.BrowserSessionConfig{CookieSecure: true}, jwtCfg, &config.DemoViewerConfig{
		Enabled: true, Email: email, Name: "Recruiter Demo", SessionTTL: "30m",
	})
	recorder := httptest.NewRecorder()
	context, _ := gin.CreateTestContext(recorder)
	context.Request = httptest.NewRequest(http.MethodPost, "/api/v1/auth/browser/demo", nil)

	handler.BrowserDemo(context)
	require.Equal(t, http.StatusOK, recorder.Code, recorder.Body.String())
	require.NotContains(t, recorder.Body.String(), email)
	require.NotContains(t, recorder.Body.String(), "token")
	cookies := recorder.Result().Cookies()
	require.Len(t, cookies, 2)
	for _, cookie := range cookies {
		require.NotEqual(t, browserRefreshCookie, cookie.Name)
		require.True(t, cookie.Secure)
	}
	var auditCount int64
	require.NoError(t, db.Model(&models.AuditLog{}).Where("admin_id = ? AND action = ?", viewer.ID, "auth.demo.session").Count(&auditCount).Error)
	require.Equal(t, int64(1), auditCount)
}
