package main

import (
	"errors"
	"log"
	"os"
	"time"

	"github.com/getsentry/sentry-go"
	"github.com/rs/zerolog"
	"gorm.io/gorm"

	"github.com/nomnom-lk/backend/internal/config"
	"github.com/nomnom-lk/backend/internal/database"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/router"
	"github.com/nomnom-lk/backend/pkg/hash"
)

// @title NomNom LK API
// @version 1.0.0
// @description Backend API for the Sri Lanka-focused food offers discovery app.

// @contact.name NomNom LK Team

// @host localhost:8080
// @BasePath /api/v1

// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	logger := zerolog.New(os.Stderr).With().
		Timestamp().
		Str("service", "backend").
		Str("environment", cfg.Server.Environment).
		Logger()

	if cfg.Sentry.DSN != "" {
		if err := sentry.Init(sentry.ClientOptions{
			Dsn:              cfg.Sentry.DSN,
			Environment:      cfg.Server.Environment,
			AttachStacktrace: true,
			TracesSampleRate: 0.2,
		}); err != nil {
			logger.Warn().Err(err).Msg("Failed to initialize Sentry")
		} else {
			defer sentry.Flush(2 * time.Second)
			logger.Info().Msg("Sentry initialized")
		}
	}

	db := database.NewPostgresDB(&cfg.Database)
	rdb := database.NewRedisClient(&cfg.Redis)

	bootstrapAdmin(db, &cfg.Admin, logger)
	bootstrapDemoViewer(db, &cfg.DemoViewer, logger)

	r, cronSvc := router.SetupRouter(cfg, db, rdb, logger)

	go func() {
		cronSvc.RunAll()
		ticker := time.NewTicker(15 * time.Minute)
		defer ticker.Stop()
		for range ticker.C {
			cronSvc.RunAll()
		}
	}()

	addr := cfg.Server.Host + ":" + cfg.Server.Port
	logger.Info().Str("addr", addr).Msg("Starting server")
	if err := r.Run(addr); err != nil {
		logger.Error().Err(err).Msg("Failed to start server")
		sentry.Flush(2 * time.Second)
		os.Exit(1)
	}
}

func bootstrapDemoViewer(db *gorm.DB, viewerCfg *config.DemoViewerConfig, logger zerolog.Logger) {
	if viewerCfg == nil || !viewerCfg.Enabled {
		return
	}

	var existing models.User
	err := db.Where("email = ?", viewerCfg.Email).First(&existing).Error
	if err == nil {
		if existing.Role != models.RolePortfolioViewer {
			logger.Error().Str("email", viewerCfg.Email).Msg("Demo viewer email belongs to another role; refusing to modify account")
			return
		}
		now := time.Now()
		updates := map[string]interface{}{
			"name": viewerCfg.Name, "is_active": true, "email_verified_at": now,
			"password_hash": "", "firebase_uid": nil,
		}
		if updateErr := db.Model(&existing).Updates(updates).Error; updateErr != nil {
			logger.Warn().Err(updateErr).Msg("Failed to reconcile demo viewer account")
		}
		return
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		logger.Warn().Err(err).Msg("Failed to look up demo viewer account")
		return
	}

	now := time.Now()
	viewer := models.User{
		Email: viewerCfg.Email, Name: viewerCfg.Name, Role: models.RolePortfolioViewer,
		IsActive: true, EmailVerifiedAt: &now,
	}
	if err := db.Create(&viewer).Error; err != nil {
		logger.Warn().Err(err).Msg("Failed to create demo viewer account")
		return
	}
	logger.Info().Str("email", viewerCfg.Email).Msg("Demo viewer account created")
}

func bootstrapAdmin(db *gorm.DB, adminCfg *config.AdminConfig, logger zerolog.Logger) {
	if adminCfg.Email == "" || adminCfg.Password == "" {
		logger.Warn().Msg("Admin email/password not set, skipping admin bootstrap")
		return
	}

	var count int64
	db.Model(&models.User{}).Where("role = ?", models.RoleAdmin).Count(&count)
	if count > 0 {
		logger.Info().Int64("count", count).Msg("Admin user(s) already exist, skipping bootstrap")
		return
	}

	hashedPassword, err := hash.HashPassword(adminCfg.Password)
	if err != nil {
		logger.Warn().Err(err).Msg("Failed to hash admin password, skipping bootstrap")
		return
	}

	now := time.Now()
	admin := models.User{
		Email:           adminCfg.Email,
		PasswordHash:    hashedPassword,
		Name:            "Admin",
		Role:            models.RoleAdmin,
		IsActive:        true,
		EmailVerifiedAt: &now,
	}

	result := db.Create(&admin)
	if result.Error != nil {
		logger.Warn().Err(result.Error).Msg("Failed to create admin user, skipping bootstrap")
		return
	}

	logger.Info().Str("email", adminCfg.Email).Msg("Admin user created successfully")
}
