package models

import (
	"time"

	"github.com/google/uuid"
)

type Favorite struct {
	UserID    uuid.UUID `gorm:"type:uuid;not null;primaryKey" json:"user_id"`
	User      *User     `gorm:"foreignKey:UserID" json:"user,omitempty"`
	OfferID   uuid.UUID `gorm:"type:uuid;not null;primaryKey" json:"offer_id"`
	Offer     *Offer    `gorm:"foreignKey:OfferID" json:"offer,omitempty"`
	CreatedAt time.Time `json:"created_at"`
}
