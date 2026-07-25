package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type CuisineTag struct {
	ID        uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	Name      string    `gorm:"uniqueIndex;not null;size:100" json:"name"`
	CreatedAt time.Time `json:"created_at"`
}

func (c *CuisineTag) BeforeCreate(tx *gorm.DB) error {
	if c.ID == uuid.Nil {
		c.ID = uuid.New()
	}
	return nil
}
