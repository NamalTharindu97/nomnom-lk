package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ScheduledNotification struct {
	ID         uuid.UUID  `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	Title      string     `gorm:"size:255;not null" json:"title"`
	Body       string     `gorm:"type:text;not null" json:"body"`
	Target     string     `gorm:"size:20;default:all" json:"target"`
	UserID     *uuid.UUID `gorm:"type:uuid;index" json:"user_id,omitempty"`
	OfferID    *uuid.UUID `gorm:"type:uuid;index" json:"offer_id,omitempty"`
	Status     string     `gorm:"size:20;default:pending;index" json:"status"`
	ScheduledAt time.Time `gorm:"not null;index" json:"scheduled_at"`
	SentAt     *time.Time `json:"sent_at,omitempty"`
	CreatedAt  time.Time  `json:"created_at"`
	UpdatedAt  time.Time  `json:"updated_at"`
}

func (s *ScheduledNotification) BeforeCreate(tx *gorm.DB) error {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	return nil
}
