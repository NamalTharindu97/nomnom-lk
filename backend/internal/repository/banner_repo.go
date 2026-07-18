package repository

import (
	"time"

	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"gorm.io/gorm"
)

type BannerRepo struct {
	db *gorm.DB
}

func NewBannerRepo(db *gorm.DB) *BannerRepo {
	return &BannerRepo{db: db}
}

func (r *BannerRepo) Create(banner *models.Banner) error {
	return r.db.Create(banner).Error
}

func (r *BannerRepo) FindAll() ([]models.Banner, error) {
	var banners []models.Banner
	err := r.db.Order("sort_order ASC, created_at DESC").Find(&banners).Error
	return banners, err
}

func (r *BannerRepo) FindAllByOwner(ownerID uuid.UUID) ([]models.Banner, error) {
	var banners []models.Banner
	err := r.db.Where("owner_id = ?", ownerID).
		Order("sort_order ASC, created_at DESC").
		Find(&banners).Error
	return banners, err
}

func (r *BannerRepo) FindAllActive() ([]models.Banner, error) {
	var banners []models.Banner
	now := time.Now()
	err := r.db.Where("status = ?", models.BannerApproved).
		Where("(start_date IS NULL OR start_date <= ?)", now).
		Where("(end_date IS NULL OR end_date >= ?)", now).
		Order("sort_order ASC, created_at DESC").
		Find(&banners).Error
	return banners, err
}

func (r *BannerRepo) FindByID(id uuid.UUID) (*models.Banner, error) {
	var banner models.Banner
	err := r.db.Where("id = ?", id).First(&banner).Error
	if err != nil {
		return nil, err
	}
	return &banner, nil
}

func (r *BannerRepo) Update(banner *models.Banner) error {
	return r.db.Save(banner).Error
}

func (r *BannerRepo) Delete(id uuid.UUID) error {
	return r.db.Delete(&models.Banner{}, id).Error
}

func (r *BannerRepo) Approve(id uuid.UUID) error {
	return r.db.Model(&models.Banner{}).
		Where("id = ?", id).
		Update("status", models.BannerApproved).Error
}

func (r *BannerRepo) Reject(id uuid.UUID) error {
	return r.db.Model(&models.Banner{}).
		Where("id = ?", id).
		Update("status", models.BannerRejected).Error
}

func (r *BannerRepo) IncrementClickCount(id uuid.UUID) error {
	return r.db.Model(&models.Banner{}).
		Where("id = ?", id).
		UpdateColumn("click_count", gorm.Expr("click_count + 1")).Error
}

func (r *BannerRepo) DeactivateByOfferID(offerID uuid.UUID) error {
	return r.db.Model(&models.Banner{}).
		Where("offer_id = ?", offerID).
		Update("status", models.BannerRejected).Error
}

func (r *BannerRepo) CountStats() (total int64, pending int64, totalClicks int64, err error) {
	err = r.db.Model(&models.Banner{}).Count(&total).Error
	if err != nil {
		return
	}
	err = r.db.Model(&models.Banner{}).Where("status = ?", models.BannerPending).Count(&pending).Error
	if err != nil {
		return
	}
	err = r.db.Model(&models.Banner{}).Select("COALESCE(SUM(click_count), 0)").Row().Scan(&totalClicks)
	return
}
