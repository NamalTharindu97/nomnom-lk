package repository

import (
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"gorm.io/gorm"
)

type SocialPlatformRepo struct {
	db *gorm.DB
}

func NewSocialPlatformRepo(db *gorm.DB) *SocialPlatformRepo {
	return &SocialPlatformRepo{db: db}
}

func (r *SocialPlatformRepo) FindAll() ([]models.SocialPlatform, error) {
	var platforms []models.SocialPlatform
	err := r.db.Order("sort_order ASC, name ASC").Find(&platforms).Error
	return platforms, err
}

func (r *SocialPlatformRepo) Create(platform *models.SocialPlatform) error {
	return r.db.Create(platform).Error
}

func (r *SocialPlatformRepo) Update(id uuid.UUID, name, displayName, primaryColor string, logoURL *string, sortOrder int) error {
	return r.db.Model(&models.SocialPlatform{}).Where("id = ?", id).Updates(map[string]interface{}{
		"name":          name,
		"display_name":  displayName,
		"primary_color": primaryColor,
		"logo_url":      logoURL,
		"sort_order":    sortOrder,
	}).Error
}

func (r *SocialPlatformRepo) Delete(id uuid.UUID) error {
	return r.db.Delete(&models.SocialPlatform{}, id).Error
}
