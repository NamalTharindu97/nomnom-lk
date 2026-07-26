package models

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SocialLinks []SocialLink

func (s *SocialLinks) Scan(src interface{}) error {
	if src == nil {
		*s = nil
		return nil
	}
	var source string
	switch v := src.(type) {
	case string:
		source = v
	case []byte:
		source = string(v)
	default:
		return fmt.Errorf("unsupported scan type for SocialLinks: %T", src)
	}
	return json.Unmarshal([]byte(source), s)
}

func (s SocialLinks) Value() (driver.Value, error) {
	if s == nil {
		return "[]", nil
	}
	return json.Marshal(s)
}

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
	ContactPhone *string          `gorm:"size:20" json:"contact_phone,omitempty"`
	CuisineTags  JSONStringSlice  `gorm:"type:jsonb;default:'[]'" json:"cuisine_tags"`
	CoverImage   *string          `gorm:"type:text" json:"cover_image,omitempty"`
	SocialLinks  SocialLinks      `gorm:"type:jsonb;default:'[]'" json:"social_links"`
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
