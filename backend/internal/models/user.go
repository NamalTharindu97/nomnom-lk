package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type UserRole string

const (
	RoleUser           UserRole = "user"
	RoleRestaurantOwner UserRole = "restaurant_owner"
	RoleAdmin          UserRole = "admin"
)

type User struct {
	ID           uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	Email        string    `gorm:"uniqueIndex;not null;size:255" json:"email"`
	PasswordHash string    `gorm:"size:255" json:"-"`
	Name         string    `gorm:"not null;size:255" json:"name"`
	AvatarURL    *string   `gorm:"type:text" json:"avatar_url,omitempty"`
	Role         UserRole  `gorm:"not null;default:'user';size:20" json:"role"`
	FirebaseUID  *string   `gorm:"uniqueIndex;size:128" json:"-"`
	Phone        *string   `gorm:"size:20" json:"phone,omitempty"`
	IsActive     bool      `gorm:"default:true" json:"is_active"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

func (u *User) BeforeCreate(tx *gorm.DB) error {
	if u.ID == uuid.Nil {
		u.ID = uuid.New()
	}
	return nil
}
