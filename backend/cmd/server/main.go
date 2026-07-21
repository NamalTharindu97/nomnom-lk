package main

import (
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

	logger := zerolog.New(os.Stderr).With().Timestamp().Logger()

	if cfg.Sentry.DSN != "" {
		if err := sentry.Init(sentry.ClientOptions{
			Dsn:              cfg.Sentry.DSN,
			Environment:      cfg.Server.Environment,
			TracesSampleRate: 0.2,
		}); err != nil {
			logger.Warn().Err(err).Msg("Failed to initialize Sentry")
		} else {
			defer sentry.Flush(2 * 1000)
			logger.Info().Msg("Sentry initialized")
		}
	}

	db := database.NewPostgresDB(&cfg.Database)
	rdb := database.NewRedisClient(&cfg.Redis)

	bootstrapAdmin(db, &cfg.Admin, logger)

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
		logger.Fatal().Err(err).Msg("Failed to start server")
	}
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

	admin := models.User{
		Email:        adminCfg.Email,
		PasswordHash: hashedPassword,
		Name:         "Admin",
		Role:         models.RoleAdmin,
		IsActive:     true,
	}

	result := db.Create(&admin)
	if result.Error != nil {
		logger.Warn().Err(result.Error).Msg("Failed to create admin user, skipping bootstrap")
		return
	}

	logger.Info().Str("email", adminCfg.Email).Msg("Admin user created successfully")
}
