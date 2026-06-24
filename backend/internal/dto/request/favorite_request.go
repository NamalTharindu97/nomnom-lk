package request

type AddFavoriteRequest struct {
	OfferID string `json:"offer_id" binding:"required,uuid"`
}
