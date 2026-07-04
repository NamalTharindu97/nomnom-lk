package repository

import (
	"time"

	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"gorm.io/gorm"
)

type ScheduledNotificationRepo struct {
	db *gorm.DB
}

func NewScheduledNotificationRepo(db *gorm.DB) *ScheduledNotificationRepo {
	return &ScheduledNotificationRepo{db: db}
}

func (r *ScheduledNotificationRepo) Create(sn *models.ScheduledNotification) error {
	return r.db.Create(sn).Error
}

func (r *ScheduledNotificationRepo) FindDue() ([]models.ScheduledNotification, error) {
	var notifications []models.ScheduledNotification
	err := r.db.Where("status = ? AND scheduled_at <= ?", "pending", time.Now()).
		Find(&notifications).Error
	return notifications, err
}

func (r *ScheduledNotificationRepo) MarkSent(id uuid.UUID) error {
	return r.db.Model(&models.ScheduledNotification{}).
		Where("id = ?", id).
		Updates(map[string]interface{}{"status": "sent", "sent_at": time.Now()}).Error
}

func (r *ScheduledNotificationRepo) MarkFailed(id uuid.UUID) error {
	return r.db.Model(&models.ScheduledNotification{}).
		Where("id = ?", id).
		Update("status", "failed").Error
}

func (r *ScheduledNotificationRepo) FindAll(page, perPage int) ([]models.ScheduledNotification, int64, error) {
	var results []models.ScheduledNotification
	var total int64
	r.db.Model(&models.ScheduledNotification{}).Count(&total)
	err := r.db.Offset((page - 1) * perPage).Limit(perPage).
		Order("scheduled_at DESC").Find(&results).Error
	return results, total, err
}

func (r *ScheduledNotificationRepo) Stats() (map[string]interface{}, error) {
	var total, sent, pending, failed int64
	r.db.Model(&models.ScheduledNotification{}).Count(&total)
	r.db.Model(&models.ScheduledNotification{}).Where("status = ?", "sent").Count(&sent)
	r.db.Model(&models.ScheduledNotification{}).Where("status = ?", "pending").Count(&pending)
	r.db.Model(&models.ScheduledNotification{}).Where("status = ?", "failed").Count(&failed)
	return map[string]interface{}{
		"total":   total,
		"sent":    sent,
		"pending": pending,
		"failed":  failed,
	}, nil
}
