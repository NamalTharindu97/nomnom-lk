package repository

import (
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"gorm.io/gorm"
)

type FavoriteRepo struct {
	db *gorm.DB
}

func NewFavoriteRepo(db *gorm.DB) *FavoriteRepo {
	return &FavoriteRepo{db: db}
}

func (r *FavoriteRepo) Add(userID, offerID uuid.UUID) error {
	favorite := &models.Favorite{
		UserID:  userID,
		OfferID: offerID,
	}
	return r.db.FirstOrCreate(favorite, "user_id = ? AND offer_id = ?", userID, offerID).Error
}

func (r *FavoriteRepo) Remove(userID, offerID uuid.UUID) error {
	return r.db.Where("user_id = ? AND offer_id = ?", userID, offerID).
		Delete(&models.Favorite{}).Error
}

func (r *FavoriteRepo) FindByUser(userID uuid.UUID, page, perPage int) ([]models.Favorite, int64, error) {
	var favorites []models.Favorite
	var total int64

	r.db.Model(&models.Favorite{}).Where("user_id = ?", userID).Count(&total)

	err := r.db.
		Preload("Offer.Restaurant").
		Where("user_id = ?", userID).
		Offset((page - 1) * perPage).
		Limit(perPage).
		Order("created_at DESC").
		Find(&favorites).Error
	if err != nil {
		return nil, 0, err
	}
	return favorites, total, nil
}

func (r *FavoriteRepo) IsFavorited(userID, offerID uuid.UUID) (bool, error) {
	var count int64
	err := r.db.Model(&models.Favorite{}).
		Where("user_id = ? AND offer_id = ?", userID, offerID).
		Count(&count).Error
	return count > 0, err
}

func (r *FavoriteRepo) GetFavoriteOfferIDs(userID uuid.UUID) ([]uuid.UUID, error) {
	var ids []uuid.UUID
	err := r.db.Model(&models.Favorite{}).
		Where("user_id = ?", userID).
		Pluck("offer_id", &ids).Error
	return ids, err
}
