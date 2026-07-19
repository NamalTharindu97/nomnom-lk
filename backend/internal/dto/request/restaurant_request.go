package request

import "github.com/nomnom-lk/backend/internal/models"

type CreateRestaurantRequest struct {
	Name          string                 `json:"name" binding:"required,max=255"`
	NameSi        string                 `json:"name_si,omitempty"`
	NameTa        string                 `json:"name_ta,omitempty"`
	Description   string                 `json:"description,omitempty"`
	DescriptionSi string                 `json:"description_si,omitempty"`
	DescriptionTa string                 `json:"description_ta,omitempty"`
	Address       string                 `json:"address" binding:"required"`
	Latitude      *float64               `json:"latitude,omitempty"`
	Longitude     *float64               `json:"longitude,omitempty"`
	ContactPhone  string                 `json:"contact_phone,omitempty"`
	CuisineTags   models.JSONStringSlice `json:"cuisine_tags,omitempty"`
	CoverImage    string                 `json:"cover_image,omitempty"`
	OwnerID       *string                `json:"owner_id,omitempty"`
	InstagramURL  string                 `json:"instagram_url,omitempty"`
	FacebookURL   string                 `json:"facebook_url,omitempty"`
	WebsiteURL    string                 `json:"website_url,omitempty"`
	OrderPlatforms models.JSONStringSlice `json:"order_platforms,omitempty"`
}

type UpdateRestaurantRequest struct {
	Name          *string                 `json:"name,omitempty"`
	NameSi        *string                 `json:"name_si,omitempty"`
	NameTa        *string                 `json:"name_ta,omitempty"`
	Description   *string                 `json:"description,omitempty"`
	DescriptionSi *string                 `json:"description_si,omitempty"`
	DescriptionTa *string                 `json:"description_ta,omitempty"`
	Address       *string                 `json:"address,omitempty"`
	Latitude      *float64                `json:"latitude,omitempty"`
	Longitude     *float64                `json:"longitude,omitempty"`
	ContactPhone  *string                 `json:"contact_phone,omitempty"`
	CuisineTags   *models.JSONStringSlice `json:"cuisine_tags,omitempty"`
	CoverImage    *string                 `json:"cover_image,omitempty"`
	OwnerID       *string                 `json:"owner_id,omitempty"`
	InstagramURL  *string                 `json:"instagram_url,omitempty"`
	FacebookURL   *string                 `json:"facebook_url,omitempty"`
	WebsiteURL    *string                 `json:"website_url,omitempty"`
	OrderPlatforms *models.JSONStringSlice `json:"order_platforms,omitempty"`
}

type ApproveRejectRequest struct {
	Reason string `json:"reason,omitempty"`
}
