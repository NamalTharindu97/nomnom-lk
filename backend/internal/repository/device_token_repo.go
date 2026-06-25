package repository

import (
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type DeviceTokenRepo struct {
	db *gorm.DB
}

func NewDeviceTokenRepo(db *gorm.DB) *DeviceTokenRepo {
	return &DeviceTokenRepo{db: db}
}

func (r *DeviceTokenRepo) Upsert(token *models.DeviceToken) error {
	return r.db.Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "user_id"}},
		UpdateAll: true,
	}).Create(token).Error
}

func (r *DeviceTokenRepo) Delete(userID uuid.UUID) error {
	return r.db.Where("user_id = ?", userID).
		Delete(&models.DeviceToken{}).Error
}

func (r *DeviceTokenRepo) DeleteByToken(userID uuid.UUID, token string) error {
	return r.db.Where("user_id = ? AND token = ?", userID, token).
		Delete(&models.DeviceToken{}).Error
}

func (r *DeviceTokenRepo) FindByUserID(userID uuid.UUID) ([]models.DeviceToken, error) {
	var tokens []models.DeviceToken
	err := r.db.Where("user_id = ?", userID).Find(&tokens).Error
	return tokens, err
}

func (r *DeviceTokenRepo) FindAll() ([]models.DeviceToken, error) {
	var tokens []models.DeviceToken
	err := r.db.Find(&tokens).Error
	return tokens, err
}
