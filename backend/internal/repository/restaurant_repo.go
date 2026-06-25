package repository

import (
	"time"

	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"gorm.io/gorm"
)

type RestaurantRepo struct {
	db *gorm.DB
}

func NewRestaurantRepo(db *gorm.DB) *RestaurantRepo {
	return &RestaurantRepo{db: db}
}

func (r *RestaurantRepo) Create(restaurant *models.Restaurant) error {
	return r.db.Create(restaurant).Error
}

func (r *RestaurantRepo) FindByID(id uuid.UUID) (*models.Restaurant, error) {
	var restaurant models.Restaurant
	err := r.db.Preload("Owner").
		Where("id = ?", id).First(&restaurant).Error
	if err != nil {
		return nil, err
	}
	return &restaurant, nil
}

func (r *RestaurantRepo) FindAll(status string, page, perPage int) ([]models.Restaurant, int64, error) {
	var restaurants []models.Restaurant
	var total int64

	query := r.db.Model(&models.Restaurant{})
	if status != "" {
		query = query.Where("status = ?", status)
	}
	query.Count(&total)

	err := query.
		Preload("Owner").
		Offset((page - 1) * perPage).
		Limit(perPage).
		Order("created_at DESC").
		Find(&restaurants).Error
	if err != nil {
		return nil, 0, err
	}
	return restaurants, total, nil
}

func (r *RestaurantRepo) Update(restaurant *models.Restaurant) error {
	return r.db.Save(restaurant).Error
}

func (r *RestaurantRepo) Delete(id uuid.UUID) error {
	return r.db.Delete(&models.Restaurant{}, id).Error
}

func (r *RestaurantRepo) UpdateStatus(id uuid.UUID, status models.RestaurantStatus) error {
	return r.db.Model(&models.Restaurant{}).Where("id = ?", id).Update("status", status).Error
}

func (r *RestaurantRepo) CountAll(count *int64) error {
	return r.db.Model(&models.Restaurant{}).Count(count).Error
}

func (r *RestaurantRepo) CountByDate(days int) ([]map[string]interface{}, error) {
	type DailyCount struct {
		Date  string `json:"date"`
		Count int64  `json:"count"`
	}
	var results []DailyCount
	err := r.db.Raw(
		"SELECT DATE(created_at) as date, COUNT(*) as count FROM restaurants WHERE created_at >= NOW() - INTERVAL '1 day' * ? GROUP BY DATE(created_at) ORDER BY date",
		days,
	).Scan(&results).Error
	if err != nil {
		return nil, err
	}

	filled := make([]map[string]interface{}, 0)
	for i := days - 1; i >= 0; i-- {
		t := time.Now().AddDate(0, 0, -i)
		dateStr := t.Format("2006-01-02")
		count := int64(0)
		for _, r := range results {
			if r.Date == dateStr {
				count = r.Count
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

func (r *RestaurantRepo) CountByStatus(status string, count *int64) error {
	return r.db.Model(&models.Restaurant{}).Where("status = ?", status).Count(count).Error
}

func (r *RestaurantRepo) FindByOwnerID(ownerID uuid.UUID) ([]models.Restaurant, error) {
	var restaurants []models.Restaurant
	err := r.db.Where("owner_id = ?", ownerID).Find(&restaurants).Error
	return restaurants, err
}

func (r *RestaurantRepo) FindPending(page, perPage int) ([]models.Restaurant, int64, error) {
	return r.FindAll(string(models.RestaurantPending), page, perPage)
}
