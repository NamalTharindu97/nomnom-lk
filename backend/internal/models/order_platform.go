package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type OrderPlatform struct {
	ID             uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	Name           string    `gorm:"uniqueIndex;not null;size:100" json:"name"`
	Slug           string    `gorm:"uniqueIndex;not null;size:50" json:"slug"`
	DisplayName    string    `gorm:"not null;size:100" json:"display_name"`
	PrimaryColor   string    `gorm:"not null;size:9" json:"primary_color"`
	DeepLinkScheme string    `gorm:"not null;size:100" json:"deep_link_scheme"`
	CreatedAt      time.Time `json:"created_at"`
}

func (p *OrderPlatform) BeforeCreate(tx *gorm.DB) error {
	if p.ID == uuid.Nil {
		p.ID = uuid.New()
	}
	return nil
}
