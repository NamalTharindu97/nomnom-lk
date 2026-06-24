package request

import (
	"time"

	"github.com/nomnom-lk/backend/internal/models"
)

type CreateOfferRequest struct {
	RestaurantID  string                 `json:"restaurant_id" binding:"required,uuid"`
	Title         string                 `json:"title" binding:"required"`
	TitleSi       string                 `json:"title_si,omitempty"`
	TitleTa       string                 `json:"title_ta,omitempty"`
	Description   string                 `json:"description,omitempty"`
	DescriptionSi string                 `json:"description_si,omitempty"`
	DescriptionTa string                 `json:"description_ta,omitempty"`
	OriginalPrice float64                `json:"original_price" binding:"required,gt=0"`
	OfferPrice    float64                `json:"offer_price" binding:"required,gt=0"`
	ImageURLs     models.JSONStringSlice `json:"image_urls,omitempty"`
	StartDate     *time.Time             `json:"start_date,omitempty"`
	EndDate       time.Time              `json:"end_date" binding:"required"`
}

type UpdateOfferRequest struct {
	Title         *string                 `json:"title,omitempty"`
	TitleSi       *string                 `json:"title_si,omitempty"`
	TitleTa       *string                 `json:"title_ta,omitempty"`
	Description   *string                 `json:"description,omitempty"`
	DescriptionSi *string                 `json:"description_si,omitempty"`
	DescriptionTa *string                 `json:"description_ta,omitempty"`
	OriginalPrice *float64                `json:"original_price,omitempty"`
	OfferPrice    *float64                `json:"offer_price,omitempty"`
	ImageURLs     *models.JSONStringSlice `json:"image_urls,omitempty"`
	StartDate     *time.Time              `json:"start_date,omitempty"`
	EndDate       *time.Time              `json:"end_date,omitempty"`
}
