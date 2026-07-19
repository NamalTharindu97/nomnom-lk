package repository

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"gorm.io/gorm"
)

type BannerRepo struct {
	db *gorm.DB
}

type OwnerBannerMetrics struct {
	Total        int64 `json:"total"`
	Active       int64 `json:"active"`
	Pending      int64 `json:"pending"`
	Rejected     int64 `json:"rejected"`
	TotalClicks  int64 `json:"total_clicks"`
	ActiveClicks int64 `json:"active_clicks"`
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
		Where(`(
			(link_type = 'offer' AND EXISTS (
				SELECT 1 FROM offers o
				JOIN restaurants r ON r.id = o.restaurant_id
				WHERE (o.id = banners.offer_id OR o.id::text = banners.link_value)
				  AND o.status = 'approved'
				  AND (o.start_date IS NULL OR o.start_date <= ?)
				  AND o.end_date >= ?
				  AND (o.publish_at IS NULL OR o.publish_at <= ?)
				  AND r.status = 'approved'
			)) OR
			(link_type = 'restaurant' AND EXISTS (
				SELECT 1 FROM restaurants r
				WHERE r.id::text = banners.link_value AND r.status = 'approved'
			)) OR
			link_type = 'external'
		)`, now, now, now).
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
	result := r.db.Model(&models.Banner{}).
		Where("id = ?", id).
		Update("status", models.BannerApproved)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (r *BannerRepo) Reject(id uuid.UUID) error {
	result := r.db.Model(&models.Banner{}).
		Where("id = ?", id).
		Update("status", models.BannerRejected)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (r *BannerRepo) IncrementClickCount(id uuid.UUID) error {
	now := time.Now()
	result := r.db.Model(&models.Banner{}).
		Where("id = ?", id).
		Where("status = ?", models.BannerApproved).
		Where("(start_date IS NULL OR start_date <= ?)", now).
		Where("(end_date IS NULL OR end_date >= ?)", now).
		Where(`(
			(link_type = 'offer' AND EXISTS (
				SELECT 1 FROM offers o JOIN restaurants r ON r.id = o.restaurant_id
				WHERE (o.id = banners.offer_id OR o.id::text = banners.link_value)
				  AND o.status = 'approved'
				  AND (o.start_date IS NULL OR o.start_date <= ?)
				  AND o.end_date >= ?
				  AND (o.publish_at IS NULL OR o.publish_at <= ?)
				  AND r.status = 'approved'
			)) OR
			(link_type = 'restaurant' AND EXISTS (
				SELECT 1 FROM restaurants r WHERE r.id::text = banners.link_value AND r.status = 'approved'
			)) OR link_type = 'external'
		)`, now, now, now).
		UpdateColumn("click_count", gorm.Expr("click_count + 1"))
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (r *BannerRepo) DeactivateByOfferID(offerID uuid.UUID) error {
	return r.db.Model(&models.Banner{}).
		Where("offer_id = ? OR (link_type = 'offer' AND link_value = ?)", offerID, offerID.String()).
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

func (r *BannerRepo) CountStatsByOwner(ownerID uuid.UUID) (*OwnerBannerMetrics, error) {
	metrics := &OwnerBannerMetrics{}
	ownerFilter := ""
	args := make([]interface{}, 0, 4)
	if ownerID != uuid.Nil {
		ownerFilter = "WHERE b.owner_id = ? OR offer_restaurant.owner_id = ? OR direct_restaurant.owner_id = ?"
		args = append(args, ownerID, ownerID, ownerID)
	}

	query := `
		WITH attributed AS (
			SELECT DISTINCT b.id, b.status, b.click_count, b.start_date, b.end_date,
				CASE
					WHEN b.link_type = 'external' THEN TRUE
					WHEN b.link_type = 'offer' THEN o.id IS NOT NULL
						AND o.status = 'approved'
						AND (o.start_date IS NULL OR o.start_date <= NOW())
						AND o.end_date >= NOW()
						AND (o.publish_at IS NULL OR o.publish_at <= NOW())
						AND offer_restaurant.status = 'approved'
					WHEN b.link_type = 'restaurant' THEN direct_restaurant.status = 'approved'
					ELSE FALSE
				END AS target_public
			FROM banners b
			LEFT JOIN offers o ON b.link_type = 'offer'
				AND (o.id = b.offer_id OR o.id::text = b.link_value)
			LEFT JOIN restaurants offer_restaurant ON offer_restaurant.id = o.restaurant_id
			LEFT JOIN restaurants direct_restaurant ON b.link_type = 'restaurant'
				AND direct_restaurant.id::text = b.link_value
			` + ownerFilter + `
		)
		SELECT
			COUNT(*) AS total,
			COALESCE(SUM(CASE WHEN status = 'approved' AND target_public AND (start_date IS NULL OR start_date <= NOW()) AND (end_date IS NULL OR end_date >= NOW()) THEN 1 ELSE 0 END), 0) AS active,
			COALESCE(SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END), 0) AS pending,
			COALESCE(SUM(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END), 0) AS rejected,
			COALESCE(SUM(click_count), 0) AS total_clicks,
			COALESCE(SUM(CASE WHEN status = 'approved' AND target_public AND (start_date IS NULL OR start_date <= NOW()) AND (end_date IS NULL OR end_date >= NOW()) THEN click_count ELSE 0 END), 0) AS active_clicks
		FROM attributed`
	if err := r.db.Raw(query, args...).Scan(metrics).Error; err != nil {
		return nil, err
	}
	return metrics, nil
}

func IsNotFound(err error) bool {
	return errors.Is(err, gorm.ErrRecordNotFound)
}
