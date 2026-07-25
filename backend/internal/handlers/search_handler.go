package handlers

import (
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
		Query:   req.Query,
		Sort:    c.DefaultQuery("sort", "newest"),
		Cuisine: c.QueryArray("cuisine"),
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

	if req.Type == "restaurants" {
		restaurants, total, err := h.service.SearchRestaurants(filters)
		if err != nil {
			response.InternalError(c, "search failed")
			return
		}

		data := make([]gin.H, len(restaurants))
		for i, r := range restaurants {
			data[i] = gin.H{
				"id":            r.ID,
				"name":          r.Name,
				"slug":          r.Slug,
				"cuisine_tags":  r.CuisineTags,
				"cover_image":   r.CoverImage,
				"is_featured":   r.IsFeatured,
				"active_offers": 0,
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
		data[i] = gin.H{
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
	}

	response.SuccessPaginated(c, gin.H{"offers": data}, pagination.Meta(filters.Params, total))
}
