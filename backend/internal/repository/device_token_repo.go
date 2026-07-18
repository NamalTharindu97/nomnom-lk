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
	// Remove stale rows with same token belonging to other users
	if err := r.db.Where("token = ? AND user_id != ?", token.Token, token.UserID).
		Delete(&models.DeviceToken{}).Error; err != nil {
		return err
	}

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

func (r *DeviceTokenRepo) DeleteByTokenValue(token string) error {
	return r.db.Where("token = ?", token).
		Delete(&models.DeviceToken{}).Error
}

func (r *DeviceTokenRepo) FindAll() ([]models.DeviceToken, error) {
	var tokens []models.DeviceToken
	err := r.db.Find(&tokens).Error
	return tokens, err
}

func (r *DeviceTokenRepo) CountByPlatform() (map[string]int64, error) {
	type platformCount struct {
		Platform string
		Count    int64
	}
	var results []platformCount
	err := r.db.Model(&models.DeviceToken{}).
		Select("platform, COUNT(*) as count").
		Group("platform").
		Scan(&results).Error
	if err != nil {
		return nil, err
	}
	out := map[string]int64{"ios": 0, "android": 0}
	for _, r := range results {
		out[r.Platform] = r.Count
	}
	return out, nil
}
