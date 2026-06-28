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
	); err != nil {
		log.Fatalf("Failed to auto-migrate: %v", err)
	}

	runIndexMigrations(db)

	log.Println("[DB] Connected and migrated successfully")
	return db
}

func runIndexMigrations(db *gorm.DB) {
	indexes := []string{
		`CREATE INDEX IF NOT EXISTS idx_offers_status_created
		 ON offers(status, created_at DESC)`,
		`CREATE INDEX IF NOT EXISTS idx_offers_end_date
		 ON offers(end_date) WHERE status = 'approved'`,
		`CREATE INDEX IF NOT EXISTS idx_offers_restaurant_id
		 ON offers(restaurant_id)`,
	}
	for _, idx := range indexes {
		if err := db.Exec(idx).Error; err != nil {
			log.Printf("[DB] Warning: could not create index: %v", err)
		}
	}
	log.Println("[DB] Index migrations complete")
}
