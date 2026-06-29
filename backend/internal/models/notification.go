package models

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Notification struct {
	ID        uuid.UUID        `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID    uuid.UUID        `gorm:"type:uuid;not null;index" json:"user_id"`
	User      *User            `gorm:"foreignKey:UserID" json:"user,omitempty"`
	OfferID   *uuid.UUID       `gorm:"type:uuid;index" json:"offer_id,omitempty"`
	Type      string           `gorm:"size:50;not null" json:"type"`
	Title     string           `gorm:"size:255;not null" json:"title"`
	Body      *string          `gorm:"type:text" json:"body,omitempty"`
	Data      *json.RawMessage `gorm:"type:jsonb" json:"data,omitempty"`
	IsRead    bool             `gorm:"default:false;index" json:"is_read"`
	CreatedAt time.Time        `json:"created_at"`
}

func (n *Notification) BeforeCreate(tx *gorm.DB) error {
	if n.ID == uuid.Nil {
		n.ID = uuid.New()
	}
	return nil
}
