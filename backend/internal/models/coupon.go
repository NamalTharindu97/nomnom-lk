package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Coupon struct {
	ID              uuid.UUID  `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	Code            string     `gorm:"size:50;not null;uniqueIndex" json:"code"`
	DiscountType    string     `gorm:"size:20;not null;default:percentage" json:"discount_type"`
	DiscountValue   float64    `gorm:"not null" json:"discount_value"`
	MinOrderAmount  float64    `gorm:"default:0" json:"min_order_amount"`
	MaxUses         int        `gorm:"default:0" json:"max_uses"`
	CurrentUses     int        `gorm:"default:0" json:"current_uses"`
	IsActive        bool       `gorm:"default:true;index" json:"is_active"`
	StartsAt        *time.Time `json:"starts_at,omitempty"`
	ExpiresAt       *time.Time `json:"expires_at,omitempty"`
	CreatedAt       time.Time  `json:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at"`
}

func (c *Coupon) BeforeCreate(tx *gorm.DB) error {
	if c.ID == uuid.Nil {
		c.ID = uuid.New()
	}
	return nil
}
