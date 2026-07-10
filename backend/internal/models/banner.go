package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type BannerStatus string

const (
	BannerPending  BannerStatus = "pending"
	BannerApproved BannerStatus = "approved"
	BannerRejected BannerStatus = "rejected"
)

type Banner struct {
	ID          uuid.UUID    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	Image       string       `gorm:"not null" json:"image"`
	LinkType    string       `gorm:"not null;size:20" json:"link_type"`
	LinkValue   string       `gorm:"not null;size:255" json:"link_value"`
	Title       string       `gorm:"size:100" json:"title,omitempty"`
	SponsorName string       `gorm:"size:100" json:"sponsor_name,omitempty"`
	SortOrder   int          `gorm:"default:0" json:"sort_order"`
	Status      BannerStatus `gorm:"type:varchar(20);default:pending;index" json:"status"`
	ClickCount  int          `gorm:"default:0" json:"click_count"`
	StartDate   *time.Time   `json:"start_date,omitempty"`
	EndDate     *time.Time   `json:"end_date,omitempty"`
	OwnerID     *uuid.UUID   `gorm:"type:uuid;index" json:"owner_id,omitempty"`
	OfferID     *uuid.UUID   `gorm:"type:uuid" json:"offer_id,omitempty"`
	CreatedAt   time.Time    `json:"created_at"`
	UpdatedAt   time.Time    `json:"updated_at"`
}

func (b *Banner) BeforeCreate(tx *gorm.DB) error {
	if b.ID == uuid.Nil {
		b.ID = uuid.New()
	}
	if b.Status == "" {
		b.Status = BannerPending
	}
	return nil
}
