package request

type CreateRestaurantRequest struct {
	Name         string   `json:"name" binding:"required,max=255"`
	NameSi       string   `json:"name_si,omitempty"`
	NameTa       string   `json:"name_ta,omitempty"`
	Description  string   `json:"description,omitempty"`
	DescriptionSi string  `json:"description_si,omitempty"`
	DescriptionTa string  `json:"description_ta,omitempty"`
	Address      string   `json:"address" binding:"required"`
	Latitude     *float64 `json:"latitude,omitempty"`
	Longitude    *float64 `json:"longitude,omitempty"`
	ContactPhone string   `json:"contact_phone,omitempty"`
	CuisineTags  []string `json:"cuisine_tags,omitempty"`
	CoverImage   string   `json:"cover_image,omitempty"`
}

type UpdateRestaurantRequest struct {
	Name         *string   `json:"name,omitempty"`
	NameSi       *string   `json:"name_si,omitempty"`
	NameTa       *string   `json:"name_ta,omitempty"`
	Description  *string   `json:"description,omitempty"`
	DescriptionSi *string  `json:"description_si,omitempty"`
	DescriptionTa *string  `json:"description_ta,omitempty"`
	Address      *string   `json:"address,omitempty"`
	Latitude     *float64  `json:"latitude,omitempty"`
	Longitude    *float64  `json:"longitude,omitempty"`
	ContactPhone *string   `json:"contact_phone,omitempty"`
	CuisineTags  *[]string `json:"cuisine_tags,omitempty"`
	CoverImage   *string   `json:"cover_image,omitempty"`
}

type ApproveRejectRequest struct {
	Reason string `json:"reason,omitempty"`
}
