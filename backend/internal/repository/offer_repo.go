package repository

import (
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"gorm.io/gorm"
)

type OfferRepo struct {
	db *gorm.DB
}

func NewOfferRepo(db *gorm.DB) *OfferRepo {
	return &OfferRepo{db: db}
}

func (r *OfferRepo) Create(offer *models.Offer) error {
	return r.db.Create(offer).Error
}

func (r *OfferRepo) FindByID(id uuid.UUID) (*models.Offer, error) {
	var offer models.Offer
	err := r.db.Preload("Restaurant").
		Where("id = ?", id).First(&offer).Error
	if err != nil {
		return nil, err
	}
	return &offer, nil
}

func (r *OfferRepo) FindAll(status, queryStr string, page, perPage int, sort string) ([]models.Offer, int64, error) {
	var offers []models.Offer
	var total int64

	query := r.db.Model(&models.Offer{})
	if status != "" && status != "all" {
		query = query.Where("offers.status = ?", status)
	}
	if queryStr != "" {
		tsQuery := strings.Join(strings.Fields(queryStr), " & ")
		prefixQuery := strings.ReplaceAll(tsQuery, " & ", ":* & ") + ":*"
		query = query.Where("offers.search_vector @@ to_tsquery('simple', ?)", prefixQuery)
	}
	query.Count(&total)

	order := "created_at DESC"
	switch sort {
	case "newest":
		order = "created_at DESC"
	case "price_low":
		order = "offer_price ASC"
	case "price_high":
		order = "offer_price DESC"
	case "ending_soon":
		order = "end_date ASC"
	case "popular":
		order = "view_count DESC"
	}

	err := query.
		Preload("Restaurant", func(db *gorm.DB) *gorm.DB {
			return db.Select("id, name, slug, address, cuisine_tags, cover_image")
		}).
		Offset((page - 1) * perPage).
		Limit(perPage).
		Order(order).
		Find(&offers).Error
	if err != nil {
		return nil, 0, err
	}
	return offers, total, nil
}

func (r *OfferRepo) Update(offer *models.Offer) error {
	return r.db.Save(offer).Error
}

func (r *OfferRepo) Delete(id uuid.UUID) error {
	return r.db.Delete(&models.Offer{}, id).Error
}

func (r *OfferRepo) BulkUpdateStatus(ids []uuid.UUID, status models.OfferStatus) error {
	return r.db.Model(&models.Offer{}).Where("id IN ?", ids).Update("status", status).Error
}

func (r *OfferRepo) BulkDelete(ids []uuid.UUID) error {
	return r.db.Delete(&models.Offer{}, "id IN ?", ids).Error
}

func (r *OfferRepo) UpdateStatus(id uuid.UUID, status models.OfferStatus) error {
	return r.db.Model(&models.Offer{}).Where("id = ?", id).Update("status", status).Error
}

func (r *OfferRepo) FindByRestaurantID(restaurantID uuid.UUID) ([]models.Offer, error) {
	var offers []models.Offer
	err := r.db.Where("restaurant_id = ?", restaurantID).Find(&offers).Error
	return offers, err
}

func (r *OfferRepo) FindPending(page, perPage int) ([]models.Offer, int64, error) {
	return r.FindAll(string(models.OfferPending), "", page, perPage, "newest")
}

func (r *OfferRepo) CountAll(count *int64) error {
	return r.db.Model(&models.Offer{}).Count(count).Error
}

func (r *OfferRepo) CountByStatus(status string, count *int64) error {
	return r.db.Model(&models.Offer{}).Where("status = ?", status).Count(count).Error
}

func (r *OfferRepo) CountByDate(days int) ([]map[string]interface{}, error) {
	sql := fmt.Sprintf(
		"SELECT DATE(created_at)::text as date, COUNT(*)::bigint as count FROM offers WHERE created_at >= NOW() - INTERVAL '1 day' * %d GROUP BY DATE(created_at) ORDER BY date",
		days,
	)
	rows, err := r.db.Raw(sql).Rows()
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	results := make([]map[string]interface{}, 0)
	for rows.Next() {
		var dateStr string
		var count int64
		if err := rows.Scan(&dateStr, &count); err != nil {
			return nil, err
		}
		results = append(results, map[string]interface{}{
			"date":  dateStr,
			"count": count,
		})
	}

	filled := make([]map[string]interface{}, 0)
	for i := days - 1; i >= 0; i-- {
		t := time.Now().AddDate(0, 0, -i)
		dateStr := t.Format("2006-01-02")
		count := int64(0)
		for _, r := range results {
			if r["date"] == dateStr {
				if c, ok := r["count"].(int64); ok {
					count = c
				}
				break
			}
		}
		filled = append(filled, map[string]interface{}{
			"date":  dateStr,
			"count": count,
		})
	}
	return filled, nil
}

func (r *OfferRepo) ExpirePastOffers() error {
	return r.db.Model(&models.Offer{}).
		Where("end_date < ? AND status = ?", time.Now(), models.OfferApproved).
		Update("status", models.OfferExpired).Error
}

func (r *OfferRepo) IncrementViewCount(id uuid.UUID) error {
	return r.db.Model(&models.Offer{}).
		Where("id = ?", id).
		UpdateColumn("view_count", gorm.Expr("view_count + 1")).Error
}
