package repository

import (
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"gorm.io/gorm"
)

type CouponRepo struct {
	db *gorm.DB
}

func NewCouponRepo(db *gorm.DB) *CouponRepo {
	return &CouponRepo{db: db}
}

func (r *CouponRepo) Create(coupon *models.Coupon) error {
	return r.db.Create(coupon).Error
}

func (r *CouponRepo) FindAll(page, perPage int) ([]models.Coupon, int64, error) {
	var coupons []models.Coupon
	var total int64
	r.db.Model(&models.Coupon{}).Count(&total)
	err := r.db.Offset((page - 1) * perPage).Limit(perPage).Order("created_at DESC").Find(&coupons).Error
	return coupons, total, err
}

func (r *CouponRepo) FindByID(id uuid.UUID) (*models.Coupon, error) {
	var coupon models.Coupon
	err := r.db.Where("id = ?", id).First(&coupon).Error
	if err != nil {
		return nil, err
	}
	return &coupon, nil
}

func (r *CouponRepo) Update(coupon *models.Coupon) error {
	return r.db.Save(coupon).Error
}

func (r *CouponRepo) Delete(id uuid.UUID) error {
	return r.db.Delete(&models.Coupon{}, id).Error
}

func (r *CouponRepo) Activate(id uuid.UUID) error {
	return r.db.Model(&models.Coupon{}).Where("id = ?", id).Update("is_active", true).Error
}

func (r *CouponRepo) Deactivate(id uuid.UUID) error {
	return r.db.Model(&models.Coupon{}).Where("id = ?", id).Update("is_active", false).Error
}

func (r *CouponRepo) CountStats() (active int64, totalRedemptions int64, err error) {
	err = r.db.Model(&models.Coupon{}).Where("is_active = ?", true).Count(&active).Error
	if err != nil {
		return
	}
	err = r.db.Model(&models.Coupon{}).Select("COALESCE(SUM(current_uses), 0)").Row().Scan(&totalRedemptions)
	return
}
