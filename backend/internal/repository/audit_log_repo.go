package repository

import (
	"github.com/nomnom-lk/backend/internal/models"
	"gorm.io/gorm"
)

type AuditLogRepo struct {
	db *gorm.DB
}

func NewAuditLogRepo(db *gorm.DB) *AuditLogRepo {
	return &AuditLogRepo{db: db}
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
