package main

import (
	"log"
	"os"
	"time"

	"github.com/getsentry/sentry-go"
	"github.com/rs/zerolog"

	"github.com/nomnom-lk/backend/internal/config"
	"github.com/nomnom-lk/backend/internal/database"
	"github.com/nomnom-lk/backend/internal/router"
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
