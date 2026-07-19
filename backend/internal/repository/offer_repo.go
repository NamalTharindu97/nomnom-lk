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

type OwnerTopOffer struct {
	OfferID       uuid.UUID `json:"offer_id"`
	Title         string    `json:"title"`
	ViewCount     int64     `json:"view_count"`
	FavoriteCount int64     `json:"favorite_count"`
}

type OwnerExpiringOffer struct {
	OfferID        uuid.UUID `json:"offer_id"`
	Title          string    `json:"title"`
	RestaurantName string    `json:"restaurant_name"`
	EndDate        time.Time `json:"end_date"`
}

type OwnerOfferMetrics struct {
	Total          int64                `json:"total"`
	Approved       int64                `json:"approved"`
	Pending        int64                `json:"pending"`
	Rejected       int64                `json:"rejected"`
	Expired        int64                `json:"expired"`
	TotalViews     int64                `json:"total_views"`
	TotalFavorites int64                `json:"total_favorites"`
	TopOffers      []OwnerTopOffer      `json:"top_offers"`
	ExpiringOffers []OwnerExpiringOffer `json:"expiring_offers"`
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

func (r *OfferRepo) FindByIDForOwner(id, ownerID uuid.UUID) (*models.Offer, error) {
	var offer models.Offer
	query := r.db.Model(&models.Offer{}).
		Joins("JOIN restaurants ON restaurants.id = offers.restaurant_id").
		Where("offers.id = ?", id)
	if ownerID != uuid.Nil {
		query = query.Where("restaurants.owner_id = ?", ownerID)
	}
	if err := query.Preload("Restaurant").First(&offer).Error; err != nil {
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

	order := "offers.created_at DESC"
	switch sort {
	case "newest":
		order = "offers.created_at DESC"
	case "price_low":
		order = "offers.offer_price ASC"
	case "price_high":
		order = "offers.offer_price DESC"
	case "ending_soon":
		order = "offers.end_date ASC"
	case "popular":
		order = "offers.view_count DESC"
	}

	err := query.
		Preload("Restaurant", func(db *gorm.DB) *gorm.DB {
			return db.Select("id, name, slug, address, cuisine_tags, cover_image, instagram_url, facebook_url, website_url, order_platforms")
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

func (r *OfferRepo) OwnerMetrics(ownerID uuid.UUID) (*OwnerOfferMetrics, error) {
	metrics := &OwnerOfferMetrics{
		TopOffers:      make([]OwnerTopOffer, 0),
		ExpiringOffers: make([]OwnerExpiringOffer, 0),
	}
	var aggregate struct {
		Total      int64
		Approved   int64
		Pending    int64
		Rejected   int64
		Expired    int64
		TotalViews int64
	}

	scope := func(query *gorm.DB) *gorm.DB {
		query = query.Joins("JOIN restaurants ON restaurants.id = offers.restaurant_id")
		if ownerID != uuid.Nil {
			query = query.Where("restaurants.owner_id = ?", ownerID)
		}
		return query
	}

	if err := scope(r.db.Model(&models.Offer{})).
		Select(`COUNT(offers.id) AS total,
			COALESCE(SUM(CASE WHEN offers.status = 'approved' THEN 1 ELSE 0 END), 0) AS approved,
			COALESCE(SUM(CASE WHEN offers.status = 'pending' THEN 1 ELSE 0 END), 0) AS pending,
			COALESCE(SUM(CASE WHEN offers.status = 'rejected' THEN 1 ELSE 0 END), 0) AS rejected,
			COALESCE(SUM(CASE WHEN offers.status = 'expired' THEN 1 ELSE 0 END), 0) AS expired,
			COALESCE(SUM(offers.view_count), 0) AS total_views`).
		Scan(&aggregate).Error; err != nil {
		return nil, err
	}
	metrics.Total = aggregate.Total
	metrics.Approved = aggregate.Approved
	metrics.Pending = aggregate.Pending
	metrics.Rejected = aggregate.Rejected
	metrics.Expired = aggregate.Expired
	metrics.TotalViews = aggregate.TotalViews

	favorites := r.db.Table("favorites").
		Joins("JOIN offers ON offers.id = favorites.offer_id").
		Joins("JOIN restaurants ON restaurants.id = offers.restaurant_id")
	if ownerID != uuid.Nil {
		favorites = favorites.Where("restaurants.owner_id = ?", ownerID)
	}
	if err := favorites.Count(&metrics.TotalFavorites).Error; err != nil {
		return nil, err
	}

	topOffers := r.db.Table("offers").
		Select("offers.id AS offer_id, offers.title, offers.view_count, COUNT(favorites.user_id) AS favorite_count").
		Joins("JOIN restaurants ON restaurants.id = offers.restaurant_id").
		Joins("LEFT JOIN favorites ON favorites.offer_id = offers.id")
	if ownerID != uuid.Nil {
		topOffers = topOffers.Where("restaurants.owner_id = ?", ownerID)
	}
	if err := topOffers.
		Group("offers.id, offers.title, offers.view_count").
		Order("offers.view_count DESC, favorite_count DESC").
		Limit(5).
		Scan(&metrics.TopOffers).Error; err != nil {
		return nil, err
	}

	expiring := r.db.Table("offers").
		Select("offers.id AS offer_id, offers.title, restaurants.name AS restaurant_name, offers.end_date").
		Joins("JOIN restaurants ON restaurants.id = offers.restaurant_id").
		Where("offers.status = ?", models.OfferApproved).
		Where("offers.end_date BETWEEN ? AND ?", time.Now(), time.Now().AddDate(0, 0, 7))
	if ownerID != uuid.Nil {
		expiring = expiring.Where("restaurants.owner_id = ?", ownerID)
	}
	if err := expiring.Order("offers.end_date ASC").Limit(5).Scan(&metrics.ExpiringOffers).Error; err != nil {
		return nil, err
	}

	return metrics, nil
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

func (r *OfferRepo) FindAllByOwner(ownerID uuid.UUID, status, queryStr string, page, perPage int, sort string) ([]models.Offer, int64, error) {
	var offers []models.Offer
	var total int64

	query := r.db.Model(&models.Offer{}).
		Joins("JOIN restaurants ON restaurants.id = offers.restaurant_id")
	if ownerID != uuid.Nil {
		query = query.Where("restaurants.owner_id = ?", ownerID)
	}

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
			return db.Select("id, name, slug, address, cuisine_tags, cover_image, instagram_url, facebook_url, website_url, order_platforms")
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

func (r *OfferRepo) TopByFavorites(limit int) ([]map[string]interface{}, error) {
	var results []struct {
		OfferID       uuid.UUID `json:"offer_id"`
		Title         string    `json:"title"`
		FavoriteCount int64     `json:"favorite_count"`
	}
	err := r.db.Model(&models.Favorite{}).
		Select("favorites.offer_id, offers.title, COUNT(*) as favorite_count").
		Joins("JOIN offers ON offers.id = favorites.offer_id").
		Group("favorites.offer_id, offers.title").
		Order("favorite_count DESC").
		Limit(limit).
		Scan(&results).Error
	if err != nil {
		return nil, err
	}
	out := make([]map[string]interface{}, len(results))
	for i, r := range results {
		out[i] = map[string]interface{}{
			"offer_id":       r.OfferID,
			"title":          r.Title,
			"favorite_count": r.FavoriteCount,
		}
	}
	return out, nil
}

func (r *OfferRepo) TopByViews(limit int) ([]models.Offer, error) {
	var offers []models.Offer
	err := r.db.Where("view_count > 0").Order("view_count DESC").Limit(limit).Find(&offers).Error
	return offers, err
}

func (r *OfferRepo) FindExpiringOffers(days int) ([]models.Offer, error) {
	var offers []models.Offer
	err := r.db.
		Preload("Restaurant", func(db *gorm.DB) *gorm.DB {
			return db.Select("id, name")
		}).
		Where("end_date IS NOT NULL AND end_date > NOW() AND end_date < NOW() + INTERVAL '1 day' * ? AND status = ?", days, models.OfferApproved).
		Order("end_date ASC").
		Limit(10).
		Find(&offers).Error
	return offers, err
}
