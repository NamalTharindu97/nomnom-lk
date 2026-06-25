package main

import (
	"fmt"
	"log"

	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/config"
	"github.com/nomnom-lk/backend/internal/database"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/pkg/hash"
	"gorm.io/gorm"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	db := database.NewPostgresDB(&cfg.Database)

	sqlDB, err := db.DB()
	if err != nil {
		log.Fatalf("Failed to get underlying DB: %v", err)
	}
	defer sqlDB.Close()

	adminID := createAdmin(db, cfg)
	_ = adminID
	fmt.Println("Seed completed successfully")
}

func createAdmin(db *gorm.DB, cfg *config.Config) uuid.UUID {
	hashedPassword, err := hash.HashPassword(cfg.Admin.Password)
	if err != nil {
		log.Fatalf("Failed to hash admin password: %v", err)
	}

	admin := models.User{
		Email:        cfg.Admin.Email,
		PasswordHash: hashedPassword,
		Name:         "Admin",
		Role:         models.RoleAdmin,
		IsActive:     true,
	}

	result := db.Where("email = ?", admin.Email).FirstOrCreate(&admin)
	if result.Error != nil {
		log.Fatalf("Failed to create admin user: %v", result.Error)
	}
	fmt.Printf("Admin user created: %s (%s)\n", admin.Email, admin.ID.String())
	return admin.ID
}
