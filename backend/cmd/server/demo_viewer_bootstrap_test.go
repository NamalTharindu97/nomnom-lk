//go:build integration

package main

import (
	"testing"

	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/config"
	"github.com/nomnom-lk/backend/internal/database"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/rs/zerolog"
	"github.com/stretchr/testify/require"
)

func TestBootstrapDemoViewer(t *testing.T) {
	db := database.NewPostgresDB(&config.DatabaseConfig{
		Host: "localhost", Port: "5432", User: "nomnom", Password: "nomnom123", Name: "nomnom_test", SSLMode: "disable",
	})
	logger := zerolog.Nop()

	t.Run("disabled does nothing", func(t *testing.T) {
		email := "disabled_" + uuid.New().String()[:8] + "@test.com"
		bootstrapDemoViewer(db, &config.DemoViewerConfig{Enabled: false, Email: email}, logger)
		var count int64
		require.NoError(t, db.Model(&models.User{}).Where("email = ?", email).Count(&count).Error)
		require.Zero(t, count)
	})

	t.Run("creates active verified passwordless viewer idempotently", func(t *testing.T) {
		email := "viewer_" + uuid.New().String()[:8] + "@test.com"
		cfg := &config.DemoViewerConfig{Enabled: true, Email: email, Name: "Recruiter Demo", SessionTTL: "30m"}
		bootstrapDemoViewer(db, cfg, logger)
		bootstrapDemoViewer(db, cfg, logger)
		var users []models.User
		require.NoError(t, db.Where("email = ?", email).Find(&users).Error)
		require.Len(t, users, 1)
		require.Equal(t, models.RolePortfolioViewer, users[0].Role)
		require.True(t, users[0].IsActive)
		require.NotNil(t, users[0].EmailVerifiedAt)
		require.Empty(t, users[0].PasswordHash)
	})

	t.Run("wrong role is not overwritten", func(t *testing.T) {
		email := "admin_" + uuid.New().String()[:8] + "@test.com"
		admin := &models.User{Email: email, Name: "Existing Admin", Role: models.RoleAdmin, IsActive: true, PasswordHash: "existing"}
		require.NoError(t, db.Create(admin).Error)
		bootstrapDemoViewer(db, &config.DemoViewerConfig{Enabled: true, Email: email, Name: "Recruiter Demo"}, logger)
		var actual models.User
		require.NoError(t, db.Where("email = ?", email).First(&actual).Error)
		require.Equal(t, models.RoleAdmin, actual.Role)
		require.Equal(t, "Existing Admin", actual.Name)
		require.Equal(t, "existing", actual.PasswordHash)
	})
}
