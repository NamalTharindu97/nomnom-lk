package models

import (
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type OfferStatus string

const (
	OfferPending  OfferStatus = "pending"
	OfferApproved OfferStatus = "approved"
	OfferRejected OfferStatus = "rejected"
	OfferExpired  OfferStatus = "expired"
)

type Offer struct {
	ID               uuid.UUID        `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	RestaurantID     uuid.UUID        `gorm:"type:uuid;not null;index" json:"restaurant_id"`
	Restaurant       *Restaurant      `gorm:"foreignKey:RestaurantID" json:"restaurant,omitempty"`
	Title            string           `gorm:"not null;size:255" json:"title"`
	Description      *string          `gorm:"type:text" json:"description,omitempty"`
	OriginalPrice    float64          `gorm:"type:decimal(10,2);not null;check:original_price > 0" json:"original_price"`
	OfferPrice       float64          `gorm:"type:decimal(10,2);not null;check:offer_price > 0" json:"offer_price"`
	DiscountPercent  int              `gorm:"-" json:"discount_percent"`
	ImageURLs        JSONStringSlice  `gorm:"type:jsonb;default:'[]'" json:"image_urls"`
	Translations     *json.RawMessage `gorm:"type:jsonb;default:'{}'" json:"translations,omitempty"`
	StartDate        *time.Time       `json:"start_date,omitempty"`
	EndDate          time.Time        `gorm:"not null" json:"end_date"`
	Status           OfferStatus      `gorm:"not null;default:'pending';size:20;index" json:"status"`
	RejectionReason  *string          `gorm:"type:text" json:"rejection_reason,omitempty"`
	CreatedBy        *uuid.UUID       `gorm:"type:uuid" json:"created_by,omitempty"`
	ViewCount        int64            `gorm:"default:0" json:"view_count"`
	CategoryIDs      JSONStringSlice  `gorm:"type:jsonb;default:'[]'" json:"category_ids"`
	PublishAt        *time.Time       `json:"publish_at,omitempty"`
	CreatedAt        time.Time        `json:"created_at"`
	UpdatedAt        time.Time        `json:"updated_at"`
}

func (o *Offer) BeforeCreate(tx *gorm.DB) error {
	if o.ID == uuid.Nil {
		o.ID = uuid.New()
	}
	if o.StartDate == nil {
		now := time.Now()
		o.StartDate = &now
	}
	return nil
}

func (o *Offer) Validate() error {
	if o.Title == "" {
		return errors.New("offer title is required")
	}
	if o.RestaurantID == uuid.Nil {
		return errors.New("restaurant_id is required")
	}
	if o.OriginalPrice <= 0 {
		return errors.New("original_price must be greater than 0")
	}
	if o.OfferPrice <= 0 {
		return errors.New("offer_price must be greater than 0")
	}
	if o.OfferPrice >= o.OriginalPrice {
		return errors.New("offer_price must be less than original_price")
	}
	if o.EndDate.Before(time.Now()) {
		return errors.New("end_date must be in the future")
	}
	return nil
}
