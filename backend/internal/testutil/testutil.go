package testutil

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http/httptest"
	"os"
	"path/filepath"
	"runtime"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/nomnom-lk/backend/internal/config"
	"github.com/nomnom-lk/backend/internal/database"
	"github.com/nomnom-lk/backend/internal/router"
	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog"
	"gorm.io/gorm"
)

var (
	initDB       *gorm.DB
	initRDB      *redis.Client
	initEngine   *gin.Engine
	initToken    string
	initAdminTok string
	initOnce     bool
)

const (
	TestUserID  = "00000000-0000-0000-0000-000000000001"
	TestAdminID = "00000000-0000-0000-0000-000000000002"
	TestOwnerID = "00000000-0000-0000-0000-000000000003"
)

func init() {
	gin.SetMode(gin.TestMode)
}

func Setup() (*gin.Engine, string, error) {
	if initOnce {
		return initEngine, initToken, nil
	}

	l := zerolog.New(zerolog.ConsoleWriter{Out: os.Stderr}).Level(zerolog.WarnLevel)

	cfg := &config.Config{
		Server: config.ServerConfig{
			Port:        "8080",
			Host:        "0.0.0.0",
			Environment: "test",
		},
		Database: config.DatabaseConfig{
			Host:     envOrDefault("TEST_DB_HOST", "localhost"),
			Port:     envOrDefault("TEST_DB_PORT", "5432"),
			User:     envOrDefault("TEST_DB_USER", "nomnom"),
			Password: envOrDefault("TEST_DB_PASSWORD", "nomnom123"),
			Name:     envOrDefault("TEST_DB_NAME", "nomnom_test"),
			SSLMode:  "disable",
		},
		Redis: config.RedisConfig{
			Host:     envOrDefault("TEST_REDIS_HOST", "localhost"),
			Port:     envOrDefault("TEST_REDIS_PORT", "6379"),
			Password: "",
		},
		JWT: config.JWTConfig{
			Secret:        "test-secret-key-for-testing-only",
			AccessExpiry:  "24h",
			RefreshExpiry: "720h",
		},
		R2: config.R2Config{
			Region:          "ap-southeast-1",
			AccessKeyID:     envOrDefault("TEST_MINIO_ACCESS_KEY", "minioadmin"),
			SecretAccessKey: envOrDefault("TEST_MINIO_SECRET", "minioadmin"),
			Bucket:          "nomnom-test-images",
			Endpoint:        fmt.Sprintf("%s:9000", envOrDefault("TEST_MINIO_HOST", "localhost")),
			ForcePathStyle:  true,
		},
		CORS: config.CORSConfig{
			Origins: "*",
		},
	}

	db := database.NewPostgresDB(&cfg.Database)

	rdb := redis.NewClient(&redis.Options{
		Addr: cfg.Redis.Addr(),
	})

	db.Exec(`INSERT INTO users (id, email, name, role, is_active, created_at, updated_at)
		VALUES (?::uuid, 'testuser@test.com', 'Test User', 'user', true, NOW(), NOW())
		ON CONFLICT (id) DO NOTHING`, TestUserID)
	db.Exec(`INSERT INTO users (id, email, name, role, is_active, created_at, updated_at)
		VALUES (?::uuid, 'testadmin@test.com', 'Test Admin', 'admin', true, NOW(), NOW())
		ON CONFLICT (id) DO NOTHING`, TestAdminID)
	db.Exec(`INSERT INTO users (id, email, name, role, is_active, created_at, updated_at)
		VALUES (?::uuid, 'testowner@test.com', 'Test Owner', 'restaurant_owner', true, NOW(), NOW())
		ON CONFLICT (id) DO NOTHING`, TestOwnerID)

	engine, _ := router.SetupRouter(cfg, db, rdb, l)

	initDB = db
	initRDB = rdb
	initEngine = engine
	initOnce = true
	initToken = generateTestToken()

	return engine, initToken, nil
}

func GenerateAdminToken() string {
	return generateAdminTestToken()
}

func GenerateOwnerToken() string {
	claims := jwt.MapClaims{
		"sub":  TestOwnerID,
		"role": "restaurant_owner",
		"exp":  time.Now().Add(24 * time.Hour).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	s, _ := token.SignedString([]byte("test-secret-key-for-testing-only"))
	return s
}

func generateTestToken() string {
	claims := jwt.MapClaims{
		"sub":  TestUserID,
		"role": "user",
		"exp":  time.Now().Add(24 * time.Hour).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	s, _ := token.SignedString([]byte("test-secret-key-for-testing-only"))
	return s
}

func generateAdminTestToken() string {
	claims := jwt.MapClaims{
		"sub":  TestAdminID,
		"role": "admin",
		"exp":  time.Now().Add(24 * time.Hour).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	s, _ := token.SignedString([]byte("test-secret-key-for-testing-only"))
	return s
}

func GetTestDB() *gorm.DB {
	return initDB
}

func SeedTestData(db *gorm.DB) error {
	type Restaurant struct {
		Name string
		Slug string
	}
	restaurants := []Restaurant{
		{Name: "Test Restaurant", Slug: "test-restaurant"},
	}
	for _, r := range restaurants {
		db.Exec("INSERT INTO restaurants (id, name, slug, status, created_at, updated_at) VALUES (gen_random_uuid(), ?, ?, 'approved', NOW(), NOW())", r.Name, r.Slug)
	}

	type OfferData struct {
		Title string
	}
	offers := []OfferData{
		{Title: "Test Offer"},
	}
	for _, o := range offers {
		db.Exec("INSERT INTO offers (id, title, description, original_price, offer_price, status, restaurant_id, start_date, end_date, created_at, updated_at) VALUES (gen_random_uuid(), ?, 'desc', 1000, 700, 'approved', (SELECT id FROM restaurants LIMIT 1), NOW(), NOW() + INTERVAL '7 days', NOW(), NOW())", o.Title)
	}

	return nil
}

func JSONBody(v interface{}) *bytes.Buffer {
	b, _ := json.Marshal(v)
	return bytes.NewBuffer(b)
}

func PerformRequest(engine *gin.Engine, method, path string, body io.Reader, token string) *httptest.ResponseRecorder {
	w := httptest.NewRecorder()
	req := httptest.NewRequest(method, path, body)
	req.Header.Set("Content-Type", "application/json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	engine.ServeHTTP(w, req)
	return w
}

func ParseResponse(w *httptest.ResponseRecorder, v interface{}) error {
	return json.NewDecoder(w.Body).Decode(v)
}

func ProjectRoot() string {
	_, f, _, _ := runtime.Caller(0)
	return filepath.Dir(filepath.Dir(filepath.Dir(f)))
}

func envOrDefault(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}
