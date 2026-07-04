package repository

import (
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"gorm.io/gorm"
)

type NotificationTemplateRepo struct {
	db *gorm.DB
}

func NewNotificationTemplateRepo(db *gorm.DB) *NotificationTemplateRepo {
	return &NotificationTemplateRepo{db: db}
}

func (r *NotificationTemplateRepo) Create(template *models.NotificationTemplate) error {
	return r.db.Create(template).Error
}

func (r *NotificationTemplateRepo) FindAll() ([]models.NotificationTemplate, error) {
	var templates []models.NotificationTemplate
	err := r.db.Order("created_at DESC").Find(&templates).Error
	return templates, err
}

func (r *NotificationTemplateRepo) FindByID(id uuid.UUID) (*models.NotificationTemplate, error) {
	var template models.NotificationTemplate
	err := r.db.Where("id = ?", id).First(&template).Error
	if err != nil {
		return nil, err
	}
	return &template, nil
}

func (r *NotificationTemplateRepo) Update(template *models.NotificationTemplate) error {
	return r.db.Save(template).Error
}

func (r *NotificationTemplateRepo) Delete(id uuid.UUID) error {
	return r.db.Delete(&models.NotificationTemplate{}, id).Error
}
