package models

import (
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type RestaurantStatus string

const (
	RestaurantPending  RestaurantStatus = "pending"
	RestaurantApproved RestaurantStatus = "approved"
	RestaurantRejected RestaurantStatus = "rejected"
)

type Translations map[string]map[string]string

type Restaurant struct {
	ID           uuid.UUID        `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	OwnerID      *uuid.UUID       `gorm:"type:uuid" json:"owner_id,omitempty"`
	Owner        *User            `gorm:"foreignKey:OwnerID" json:"owner,omitempty"`
	Name         string           `gorm:"not null;size:255" json:"name"`
	Slug         string           `gorm:"uniqueIndex;not null;size:255" json:"slug"`
	Description  *string          `gorm:"type:text" json:"description,omitempty"`
	Address      string           `gorm:"not null;type:text" json:"address"`
	Latitude     *float64         `gorm:"type:decimal(10,7)" json:"latitude,omitempty"`
	Longitude    *float64         `gorm:"type:decimal(10,7)" json:"longitude,omitempty"`
	ContactPhone *string          `gorm:"size:20" json:"contact_phone,omitempty"`
	CuisineTags  JSONStringSlice  `gorm:"type:jsonb;default:'[]'" json:"cuisine_tags"`
	CoverImage   *string          `gorm:"type:text" json:"cover_image,omitempty"`
	InstagramURL *string          `gorm:"type:text" json:"instagram_url,omitempty"`
	FacebookURL  *string          `gorm:"type:text" json:"facebook_url,omitempty"`
	WebsiteURL    *string          `gorm:"type:text" json:"website_url,omitempty"`
	OrderPlatforms JSONStringSlice `gorm:"type:jsonb;default:'[]'" json:"order_platforms"`
	Translations  *json.RawMessage `gorm:"type:jsonb;default:'{}'" json:"translations,omitempty"`
	Status       RestaurantStatus `gorm:"not null;default:'pending';size:20" json:"status"`
	IsFeatured   bool             `gorm:"default:false" json:"is_featured"`
	CreatedAt    time.Time        `json:"created_at"`
	UpdatedAt    time.Time        `json:"updated_at"`

	Offers []Offer `gorm:"foreignKey:RestaurantID" json:"offers,omitempty"`
}

func (r *Restaurant) BeforeCreate(tx *gorm.DB) error {
	if r.ID == uuid.Nil {
		r.ID = uuid.New()
	}
	if r.Slug == "" {
		r.Slug = createSlug(r.Name)
	}
	return nil
}

func (r *Restaurant) Validate() error {
	if r.Name == "" {
		return errors.New("restaurant name is required")
	}
	if r.Address == "" {
		return errors.New("restaurant address is required")
	}
	return nil
}

func createSlug(name string) string {
	result := make([]byte, 0, len(name))
	for _, c := range name {
		if c >= 'a' && c <= 'z' || c >= '0' && c <= '9' {
			result = append(result, byte(c))
		} else if c >= 'A' && c <= 'Z' {
			result = append(result, byte(c+32))
		} else if c == ' ' || c == '-' {
			result = append(result, '-')
		}
	}
	return string(result)
}
