package handlers

import (
	"math"

	"github.com/gin-gonic/gin"
	"github.com/nomnom-lk/backend/internal/dto/request"
	"github.com/nomnom-lk/backend/internal/services"
	"github.com/nomnom-lk/backend/pkg/pagination"
	"github.com/nomnom-lk/backend/pkg/response"
)

type SearchHandler struct {
	service *services.SearchService
}

func NewSearchHandler(service *services.SearchService) *SearchHandler {
	return &SearchHandler{service: service}
}

func (h *SearchHandler) Search(c *gin.Context) {
	var req request.SearchQuery
	if err := c.ShouldBindQuery(&req); err != nil {
		response.ValidationError(c, []response.ErrorDetail{
			{Field: "query", Message: err.Error()},
		})
		return
	}

	filters := services.SearchFilters{
		Query:    req.Query,
		RadiusKm: req.RadiusKm,
		Sort:     c.DefaultQuery("sort", "newest"),
		Cuisine:  c.QueryArray("cuisine"),
		Params: pagination.Params{
			Page:    req.Page,
			PerPage: req.PerPage,
		},
	}

	if req.Page < 1 {
		filters.Params.Page = 1
	}
	if req.PerPage < 1 || req.PerPage > 100 {
		filters.Params.PerPage = 20
	}
	filters.Params.Offset = (filters.Params.Page - 1) * filters.Params.PerPage

	if req.Lat != 0 && req.Lng != 0 {
		filters.Lat = &req.Lat
		filters.Lng = &req.Lng
	}

	if req.Type == "restaurants" {
		restaurants, total, err := h.service.SearchRestaurants(filters)
		if err != nil {
			response.InternalError(c, "search failed")
			return
		}

		data := make([]gin.H, len(restaurants))
		for i, r := range restaurants {
			data[i] = gin.H{
				"id":             r.ID,
				"name":           r.Name,
				"slug":           r.Slug,
				"address":        r.Address,
				"cuisine_tags":   r.CuisineTags,
				"cover_image":    r.CoverImage,
				"latitude":       r.Latitude,
				"longitude":      r.Longitude,
				"is_featured":    r.IsFeatured,
				"active_offers":  0,
			}
		}

		response.SuccessPaginated(c, gin.H{"restaurants": data}, pagination.Meta(filters.Params, total))
		return
	}

	offers, total, err := h.service.SearchOffers(filters)
	if err != nil {
		response.InternalError(c, "search failed")
		return
	}

	data := make([]gin.H, len(offers))
	for i, o := range offers {
		item := gin.H{
			"id": o.ID,
			"restaurant": gin.H{
				"id":   o.RestaurantID,
				"name": o.Restaurant.Name,
				"slug": o.Restaurant.Slug,
			},
			"title":            o.Title,
			"description":      o.Description,
			"original_price":   o.OriginalPrice,
			"offer_price":      o.OfferPrice,
			"discount_percent": int((1 - o.OfferPrice/o.OriginalPrice) * 100),
			"image_urls":       o.ImageURLs,
			"end_date":         o.EndDate,
			"is_favorited":     false,
		}

		if filters.Lat != nil && filters.Lng != nil && o.Restaurant.Latitude != nil && o.Restaurant.Longitude != nil {
			item["distance_km"] = haversineDistance(
				*filters.Lat, *filters.Lng,
				*o.Restaurant.Latitude, *o.Restaurant.Longitude,
			)
		}

		data[i] = item
	}

	response.SuccessPaginated(c, gin.H{"offers": data}, pagination.Meta(filters.Params, total))
}

func haversineDistance(lat1, lng1, lat2, lng2 float64) float64 {
	const R = 6371
	dLat := (lat2 - lat1) * math.Pi / 180
	dLng := (lng2 - lng1) * math.Pi / 180
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*math.Pi/180)*math.Cos(lat2*math.Pi/180)*
			math.Sin(dLng/2)*math.Sin(dLng/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return R * c
}
