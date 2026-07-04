package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AuditLog struct {
	ID         uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	AdminID    uuid.UUID `gorm:"type:uuid;not null;index" json:"admin_id"`
	AdminName  string    `gorm:"size:255" json:"admin_name"`
	Action     string    `gorm:"size:50;not null;index" json:"action"`
	EntityType string    `gorm:"size:50;not null;index" json:"entity_type"`
	EntityID   string    `gorm:"size:255" json:"entity_id"`
	Details    string    `gorm:"type:text" json:"details,omitempty"`
	CreatedAt  time.Time `json:"created_at"`
}

func (a *AuditLog) BeforeCreate(tx *gorm.DB) error {
	if a.ID == uuid.Nil {
		a.ID = uuid.New()
	}
	return nil
}
