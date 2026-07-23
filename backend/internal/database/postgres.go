package database

import (
	"log"
	"time"

	"github.com/nomnom-lk/backend/internal/config"
	"github.com/nomnom-lk/backend/internal/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func NewPostgresDB(cfg *config.DatabaseConfig) *gorm.DB {
	db, err := gorm.Open(postgres.Open(cfg.DSN()), &gorm.Config{
		Logger: logger.New(log.New(log.Writer(), "\r\n", log.LstdFlags), logger.Config{
			SlowThreshold:        time.Second,
			LogLevel:             logger.Warn,
			ParameterizedQueries: true,
			Colorful:             false,
		}),
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
		`DO $$
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='restaurants' AND column_name='order_platforms') THEN
				ALTER TABLE restaurants ADD COLUMN order_platforms JSONB DEFAULT '[]';
			END IF;
			IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='restaurants' AND column_name='order_url') THEN
				UPDATE restaurants SET order_platforms = CASE
					WHEN order_url ILIKE '%ubereats%' AND order_url_alt ILIKE '%pickme%' THEN '["uber_eats","pickme"]'::jsonb
					WHEN order_url ILIKE '%ubereats%' THEN '["uber_eats"]'::jsonb
					WHEN order_url ILIKE '%pickme%' THEN '["pickme"]'::jsonb
					WHEN order_url_alt ILIKE '%pickme%' THEN '["pickme"]'::jsonb
					WHEN order_url_alt ILIKE '%ubereats%' THEN '["uber_eats"]'::jsonb
					ELSE '[]'::jsonb
					END
					WHERE order_url IS NOT NULL OR order_url_alt IS NOT NULL;
				ALTER TABLE restaurants DROP COLUMN order_url;
				ALTER TABLE restaurants DROP COLUMN order_url_alt;
			END IF;
		END $$`,
		`UPDATE banners b
		 SET offer_id = NULL, owner_id = NULL
		 WHERE b.link_type = 'offer'
		   AND NOT EXISTS (SELECT 1 FROM offers o WHERE o.id::text = b.link_value)`,
		`UPDATE banners b
		 SET offer_id = o.id, owner_id = r.owner_id
		 FROM offers o
		 JOIN restaurants r ON r.id = o.restaurant_id
		 WHERE b.link_type = 'offer' AND o.id::text = b.link_value`,
		`UPDATE banners b
		 SET offer_id = NULL, owner_id = r.owner_id
		 FROM restaurants r
		 WHERE b.link_type = 'restaurant' AND r.id::text = b.link_value`,
		`UPDATE banners SET offer_id = NULL, owner_id = NULL WHERE link_type = 'external'`,
		`CREATE INDEX IF NOT EXISTS idx_banners_offer_id ON banners(offer_id)`,
		`CREATE INDEX IF NOT EXISTS idx_banners_owner_status ON banners(owner_id, status)`,
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
