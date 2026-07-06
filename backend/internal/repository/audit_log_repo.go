package repository

import (
	"time"

	"github.com/nomnom-lk/backend/internal/models"
	"gorm.io/gorm"
)

type AuditLogRepo struct {
	db *gorm.DB
}

func NewAuditLogRepo(db *gorm.DB) *AuditLogRepo {
	return &AuditLogRepo{db: db}
}

type AuditLogFilterParams struct {
	Action     string
	EntityType string
	Search     string
	Role       string
	From       time.Time
	To         time.Time
	Page       int
	PerPage    int
}

func (r *AuditLogRepo) DeleteOlderThan(days int) error {
	return r.db.Where("created_at < NOW() - ? * INTERVAL '1 day'", days).Delete(&models.AuditLog{}).Error
}

func (r *AuditLogRepo) DeleteAll() error {
	return r.db.Where("1=1").Delete(&models.AuditLog{}).Error
}

func (r *AuditLogRepo) Create(log *models.AuditLog) error {
	return r.db.Create(log).Error
}

func (r *AuditLogRepo) FindAll(page, perPage int) ([]models.AuditLog, int64, error) {
	var logs []models.AuditLog
	var total int64

	r.db.Model(&models.AuditLog{}).Count(&total)
	err := r.db.Order("created_at DESC").Offset((page - 1) * perPage).Limit(perPage).Find(&logs).Error
	if err != nil {
		return nil, 0, err
	}
	return logs, total, nil
}

func (r *AuditLogRepo) FindAllFiltered(params AuditLogFilterParams) ([]models.AuditLog, int64, error) {
	var logs []models.AuditLog
	var total int64

	query := r.db.Model(&models.AuditLog{})

	if params.Action != "" {
		query = query.Where("action ILIKE ?", "%"+params.Action+"%")
	}
	if params.EntityType != "" {
		query = query.Where("entity_type ILIKE ?", "%"+params.EntityType+"%")
	}
	if params.Role != "" {
		query = query.Where("admin_role = ?", params.Role)
	}
	if params.Search != "" {
		searchTerm := "%" + params.Search + "%"
		query = query.Where("admin_name ILIKE ? OR action ILIKE ? OR entity_type ILIKE ? OR entity_id ILIKE ? OR details ILIKE ?",
			searchTerm, searchTerm, searchTerm, searchTerm, searchTerm)
	}
	if !params.From.IsZero() {
		query = query.Where("created_at >= ?", params.From)
	}
	if !params.To.IsZero() {
		query = query.Where("created_at <= ?", params.To)
	}

	query.Count(&total)

	err := query.Order("created_at DESC").
		Offset((params.Page - 1) * params.PerPage).
		Limit(params.PerPage).
		Find(&logs).Error
	if err != nil {
		return nil, 0, err
	}
	return logs, total, nil
}
