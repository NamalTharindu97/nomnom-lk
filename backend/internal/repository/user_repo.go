package repository

import (
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"gorm.io/gorm"
)

type UserRepo struct {
	db *gorm.DB
}

func NewUserRepo(db *gorm.DB) *UserRepo {
	return &UserRepo{db: db}
}

func (r *UserRepo) Create(user *models.User) error {
	return r.db.Create(user).Error
}

func (r *UserRepo) FindByID(id uuid.UUID) (*models.User, error) {
	var user models.User
	err := r.db.Where("id = ?", id).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *UserRepo) FindByEmail(email string) (*models.User, error) {
	var user models.User
	err := r.db.Where("email = ?", email).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *UserRepo) FindByFirebaseUID(uid string) (*models.User, error) {
	var user models.User
	err := r.db.Where("firebase_uid = ?", uid).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *UserRepo) Update(user *models.User) error {
	return r.db.Save(user).Error
}

func (r *UserRepo) SoftDelete(id uuid.UUID) error {
	return r.db.Model(&models.User{}).Where("id = ?", id).Update("is_active", false).Error
}

func (r *UserRepo) BulkSoftDelete(ids []uuid.UUID) error {
	return r.db.Model(&models.User{}).Where("id IN ?", ids).Update("is_active", false).Error
}

func (r *UserRepo) BulkActivate(ids []uuid.UUID) error {
	return r.db.Model(&models.User{}).Where("id IN ?", ids).Update("is_active", true).Error
}

func (r *UserRepo) BulkDelete(ids []uuid.UUID) error {
	return r.db.Delete(&models.User{}, "id IN ?", ids).Error
}

type OwnerWithStats struct {
	ID               uuid.UUID `json:"id"`
	Email            string    `json:"email"`
	Name             string    `json:"name"`
	IsActive         bool      `json:"is_active"`
	RestaurantCount  int64     `json:"restaurant_count"`
	OfferCount       int64     `json:"offer_count"`
	CreatedAt        time.Time `json:"created_at"`
}

func (r *UserRepo) FindOwnersWithStats(page, perPage int) ([]OwnerWithStats, int64, error) {
	var results []OwnerWithStats
	var total int64

	r.db.Model(&models.User{}).Where("role = ?", models.RoleRestaurantOwner).Count(&total)

	err := r.db.Raw(`
		SELECT u.id, u.email, u.name, u.is_active, u.created_at,
			COALESCE(rc.count, 0) as restaurant_count,
			COALESCE(oc.count, 0) as offer_count
		FROM users u
		LEFT JOIN (SELECT owner_id, COUNT(*) as count FROM restaurants GROUP BY owner_id) rc ON rc.owner_id = u.id
		LEFT JOIN (SELECT r.owner_id, COUNT(*) as count FROM offers o JOIN restaurants r ON r.id = o.restaurant_id GROUP BY r.owner_id) oc ON oc.owner_id = u.id
		WHERE u.role = ?
		ORDER BY u.created_at DESC
		LIMIT ? OFFSET ?
	`, models.RoleRestaurantOwner, perPage, (page-1)*perPage).Scan(&results).Error

	return results, total, err
}

func (r *UserRepo) CountAll(count *int64) error {
	return r.db.Model(&models.User{}).Count(count).Error
}

func (r *UserRepo) CountByDate(days int) ([]map[string]interface{}, error) {
	sql := fmt.Sprintf(
		"SELECT DATE(created_at)::text as date, COUNT(*)::bigint as count FROM users WHERE created_at >= NOW() - INTERVAL '1 day' * %d GROUP BY DATE(created_at) ORDER BY date",
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

func (r *UserRepo) FindAll(page, perPage int, emailFilter, roleFilter string) ([]models.User, int64, error) {
	var users []models.User
	var total int64

	query := r.db.Model(&models.User{})
	if emailFilter != "" {
		query = query.Where("email ILIKE ?", "%"+emailFilter+"%")
	}
	if roleFilter != "" {
		query = query.Where("role = ?", roleFilter)
	}

	query.Count(&total)
	err := query.Offset((page-1)*perPage).Limit(perPage).Order("created_at DESC").Find(&users).Error
	if err != nil {
		return nil, 0, err
	}
	return users, total, nil
}
