package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type NotificationTemplate struct {
	ID        uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	Name      string    `gorm:"size:255;not null;uniqueIndex" json:"name"`
	Title     string    `gorm:"size:255;not null" json:"title"`
	Body      string    `gorm:"type:text;not null" json:"body"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

func (t *NotificationTemplate) BeforeCreate(tx *gorm.DB) error {
	if t.ID == uuid.Nil {
		t.ID = uuid.New()
	}
	return nil
}
