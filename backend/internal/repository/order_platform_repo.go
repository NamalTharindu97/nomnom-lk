package repository

import (
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"gorm.io/gorm"
)

type OrderPlatformRepo struct {
	db *gorm.DB
}

func NewOrderPlatformRepo(db *gorm.DB) *OrderPlatformRepo {
	return &OrderPlatformRepo{db: db}
}

func (r *OrderPlatformRepo) FindAll() ([]models.OrderPlatform, error) {
	var platforms []models.OrderPlatform
	err := r.db.Order("name ASC").Find(&platforms).Error
	return platforms, err
}

func (r *OrderPlatformRepo) Create(platform *models.OrderPlatform) error {
	return r.db.Create(platform).Error
}

func (r *OrderPlatformRepo) Update(id uuid.UUID, name, displayName, primaryColor, deepLinkScheme string) error {
	return r.db.Model(&models.OrderPlatform{}).Where("id = ?", id).Updates(map[string]interface{}{
		"name":             name,
		"display_name":     displayName,
		"primary_color":    primaryColor,
		"deep_link_scheme": deepLinkScheme,
	}).Error
}

func (r *OrderPlatformRepo) Delete(id uuid.UUID) error {
	return r.db.Delete(&models.OrderPlatform{}, id).Error
}
