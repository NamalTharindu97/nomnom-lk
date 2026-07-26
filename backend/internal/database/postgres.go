package database

import (
	"fmt"
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
		&models.CuisineTag{},
		&models.OrderPlatform{},
		&models.SocialPlatform{},
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
		fmt.Sprintf(`UPDATE banners b
		 SET offer_id = NULL, owner_id = NULL
		 WHERE b.link_type = '%s'
		   AND NOT EXISTS (SELECT 1 FROM offers o WHERE o.id::text = b.link_value)`, models.BannerLinkOffer),
		fmt.Sprintf(`UPDATE banners b
		 SET offer_id = o.id, owner_id = r.owner_id
		 FROM offers o
		 JOIN restaurants r ON r.id = o.restaurant_id
		 WHERE b.link_type = '%s' AND o.id::text = b.link_value`, models.BannerLinkOffer),
		fmt.Sprintf(`UPDATE banners b
		 SET offer_id = NULL, owner_id = r.owner_id
		 FROM restaurants r
		 WHERE b.link_type = '%s' AND r.id::text = b.link_value`, models.BannerLinkRestaurant),
		fmt.Sprintf(`UPDATE banners SET offer_id = NULL, owner_id = NULL WHERE link_type = '%s'`, models.BannerLinkExternal),
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
		`DO $$
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='failed_login_attempts') THEN
				ALTER TABLE users ADD COLUMN failed_login_attempts INTEGER DEFAULT 0;
			END IF;
			IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='locked_until') THEN
				ALTER TABLE users ADD COLUMN locked_until TIMESTAMPTZ;
			END IF;
		END $$`,
		`UPDATE restaurants
		 SET order_platforms = order_platforms || '["uber_eats","pickme"]'::jsonb
		 WHERE order_platforms IS NULL OR jsonb_array_length(order_platforms) = 0`,
		`ALTER TABLE restaurants DROP COLUMN IF EXISTS address`,
		`ALTER TABLE restaurants DROP COLUMN IF EXISTS latitude`,
		`ALTER TABLE restaurants DROP COLUMN IF EXISTS longitude`,
		`INSERT INTO cuisine_tags (id, name, created_at)
		 VALUES (gen_random_uuid(), 'Pizza', NOW()),
		        (gen_random_uuid(), 'Italian', NOW()),
		        (gen_random_uuid(), 'Fast Food', NOW()),
		        (gen_random_uuid(), 'Fried Chicken', NOW()),
		        (gen_random_uuid(), 'Burgers', NOW()),
		        (gen_random_uuid(), 'Bakery', NOW()),
		        (gen_random_uuid(), 'Cakes', NOW()),
		        (gen_random_uuid(), 'Pastries', NOW()),
		        (gen_random_uuid(), 'Snacks', NOW()),
		        (gen_random_uuid(), 'Desserts', NOW()),
		        (gen_random_uuid(), 'Sweets', NOW()),
		        (gen_random_uuid(), 'Rice Bowls', NOW()),
		        (gen_random_uuid(), 'Asian', NOW()),
		        (gen_random_uuid(), 'Noodles', NOW()),
		        (gen_random_uuid(), 'American', NOW()),
		        (gen_random_uuid(), 'Sandwiches', NOW()),
		        (gen_random_uuid(), 'Healthy', NOW()),
		        (gen_random_uuid(), 'Mexican', NOW()),
		        (gen_random_uuid(), 'Tacos', NOW())
		 ON CONFLICT (name) DO NOTHING`,
		`INSERT INTO order_platforms (id, name, slug, display_name, primary_color, deep_link_scheme, created_at)
		 VALUES (gen_random_uuid(), 'Uber Eats', 'uber_eats', 'Uber Eats', '#06C167', 'ubereats://', NOW()),
		        (gen_random_uuid(), 'PickMe', 'pickme', 'PickMe', '#00B14F', 'pickme://', NOW())
		 ON CONFLICT (name) DO NOTHING`,
		// Migrate instagram_url/facebook_url/website_url to social_links JSONB
		`DO $$
		BEGIN
			IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='restaurants' AND column_name='instagram_url') THEN
				UPDATE restaurants SET social_links = (
					SELECT jsonb_agg(link) FROM (
						SELECT jsonb_build_object('platform', 'instagram', 'url', instagram_url) AS link
						WHERE instagram_url IS NOT NULL AND instagram_url != ''
						UNION ALL
						SELECT jsonb_build_object('platform', 'facebook', 'url', facebook_url)
						WHERE facebook_url IS NOT NULL AND facebook_url != ''
						UNION ALL
						SELECT jsonb_build_object('platform', 'website', 'url', website_url)
						WHERE website_url IS NOT NULL AND website_url != ''
					) t
				)
				WHERE social_links IS NULL OR jsonb_array_length(social_links) = 0;
				ALTER TABLE restaurants DROP COLUMN IF EXISTS instagram_url;
				ALTER TABLE restaurants DROP COLUMN IF EXISTS facebook_url;
				ALTER TABLE restaurants DROP COLUMN IF EXISTS website_url;
			END IF;
		END $$`,
		`INSERT INTO social_platforms (id, name, slug, display_name, primary_color, sort_order, created_at)
		 VALUES (gen_random_uuid(), 'Instagram', 'instagram', 'Instagram', '#E4405F', 0, NOW()),
		        (gen_random_uuid(), 'Facebook', 'facebook', 'Facebook', '#1877F2', 1, NOW()),
		        (gen_random_uuid(), 'Website', 'website', 'Website', '#E38D12', 2, NOW())
		 ON CONFLICT (name) DO NOTHING`,
	}
	for _, stmt := range statements {
		if err := db.Exec(stmt).Error; err != nil {
			log.Printf("[DB] Warning: could not execute migration: %v", err)
		}
	}
	log.Println("[DB] Index migrations complete")
}
