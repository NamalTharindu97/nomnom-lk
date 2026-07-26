package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SocialPlatform struct {
	ID           uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	Name         string    `gorm:"uniqueIndex;not null;size:100" json:"name"`
	Slug         string    `gorm:"uniqueIndex;not null;size:50" json:"slug"`
	DisplayName  string    `gorm:"not null;size:100" json:"display_name"`
	PrimaryColor string    `gorm:"not null;size:9" json:"primary_color"`
	LogoURL      *string   `gorm:"type:text" json:"logo_url,omitempty"`
	SortOrder    int       `gorm:"default:0" json:"sort_order"`
	CreatedAt    time.Time `json:"created_at"`
}

func (p *SocialPlatform) BeforeCreate(tx *gorm.DB) error {
	if p.ID == uuid.Nil {
		p.ID = uuid.New()
	}
	return nil
}

type SocialLink struct {
	Platform string `json:"platform"`
	URL      string `json:"url"`
}
