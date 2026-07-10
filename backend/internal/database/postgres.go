package database

import (
	"log"

	"github.com/nomnom-lk/backend/internal/config"
	"github.com/nomnom-lk/backend/internal/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func NewPostgresDB(cfg *config.DatabaseConfig) *gorm.DB {
	db, err := gorm.Open(postgres.Open(cfg.DSN()), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Warn),
	})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		log.Fatalf("Failed to get underlying sql.DB: %v", err)
	}

	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetMaxOpenConns(100)

	if err := db.AutoMigrate(
		&models.User{},
		&models.Restaurant{},
		&models.Offer{},
		&models.Favorite{},
		&models.Notification{},
		&models.DeviceToken{},
		&models.RefreshToken{},
		&models.AuditLog{},
		&models.NotificationTemplate{},
		&models.ScheduledNotification{},
		&models.Coupon{},
		&models.Category{},
		&models.Banner{},
	); err != nil {
		log.Fatalf("Failed to auto-migrate: %v", err)
	}

	runIndexMigrations(db)

	log.Println("[DB] Connected and migrated successfully")
	return db
}

func runIndexMigrations(db *gorm.DB) {
	statements := []string{
		// Add search_vector generated column (from schema.sql / 003_create_offers.up.sql)
		`ALTER TABLE offers ADD COLUMN IF NOT EXISTS search_vector TSVECTOR
		 GENERATED ALWAYS AS (
			 to_tsvector('simple',
				 coalesce(title, '') || ' ' || coalesce(description, '')
			 )
		 ) STORED`,
		`CREATE INDEX IF NOT EXISTS idx_offers_search ON offers USING GIN(search_vector)`,
		`CREATE INDEX IF NOT EXISTS idx_offers_status_created
		 ON offers(status, created_at DESC)`,
		`CREATE INDEX IF NOT EXISTS idx_offers_end_date
		 ON offers(end_date) WHERE status = 'approved'`,
		`CREATE INDEX IF NOT EXISTS idx_offers_restaurant_id
		 ON offers(restaurant_id)`,
	}
	for _, stmt := range statements {
		if err := db.Exec(stmt).Error; err != nil {
			log.Printf("[DB] Warning: could not execute migration: %v", err)
		}
	}
	log.Println("[DB] Index migrations complete")
}
