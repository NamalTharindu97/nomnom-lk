package services

import (
	"fmt"
	"strings"

	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/pkg/pagination"
	"gorm.io/gorm"
)

type SearchService struct {
	db *gorm.DB
}

func NewSearchService(db *gorm.DB) *SearchService {
	return &SearchService{db: db}
}

type SearchFilters struct {
	Query    string
	Lat      *float64
	Lng      *float64
	RadiusKm float64
	Cuisine  []string
	Sort     string
	Params   pagination.Params
}

type SearchResult struct {
	Offers      []models.Offer      `json:"offers"`
	Restaurants []models.Restaurant `json:"restaurants,omitempty"`
	Total       int64               `json:"total"`
}

func (s *SearchService) buildOfferBase(filters SearchFilters) *gorm.DB {
	tx := s.db.Model(&models.Offer{}).
		Joins("JOIN restaurants ON restaurants.id = offers.restaurant_id").
		Where("offers.status = ?", models.OfferApproved).
		Where("offers.end_date > NOW()").
		Where("restaurants.status = ?", models.RestaurantApproved)

	if filters.Query != "" {
		tsQuery := strings.Join(strings.Fields(filters.Query), " & ")
		tx = tx.Where(
			"offers.search_vector @@ to_tsquery('simple', ?)",
			tsQuery,
		)
	}

	if len(filters.Cuisine) > 0 {
		tx = tx.Where("restaurants.cuisine_tags && ?", filters.Cuisine)
	}

	if filters.Lat != nil && filters.Lng != nil {
		haversine := `(
			6371 * acos(
				cos(radians(?)) * cos(radians(restaurants.latitude)) *
				cos(radians(restaurants.longitude) - radians(?)) +
				sin(radians(?)) * sin(radians(restaurants.latitude))
			)
		) <= ?`
		tx = tx.Where(haversine, *filters.Lat, *filters.Lng, *filters.Lat, filters.RadiusKm)
	}

	return tx
}

func (s *SearchService) SearchOffers(filters SearchFilters) ([]models.Offer, int64, error) {
	var total int64
	if err := s.buildOfferBase(filters).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	if total == 0 {
		return []models.Offer{}, 0, nil
	}

	tx := s.buildOfferBase(filters)

	switch filters.Sort {
	case "oldest":
		tx = tx.Order("offers.created_at ASC")
	case "discount":
		tx = tx.Order("offers.discount_percent DESC NULLS LAST")
	case "price_low":
		tx = tx.Order("offers.offer_price ASC")
	case "price_high":
		tx = tx.Order("offers.offer_price DESC")
	case "nearest":
		if filters.Lat != nil && filters.Lng != nil {
			order := fmt.Sprintf(`(
				6371 * acos(
					cos(radians(%f)) * cos(radians(restaurants.latitude)) *
					cos(radians(restaurants.longitude) - radians(%f)) +
					sin(radians(%f)) * sin(radians(restaurants.latitude))
				)
			) ASC`, *filters.Lat, *filters.Lng, *filters.Lat)
			tx = tx.Order(order)
		} else {
			tx = tx.Order("offers.created_at DESC")
		}
	default:
		tx = tx.Order("offers.created_at DESC")
	}

	var offers []models.Offer
	if err := tx.
		Preload("Restaurant").
		Select("offers.*").
		Offset(filters.Params.Offset).
		Limit(filters.Params.PerPage).
		Find(&offers).Error; err != nil {
		return nil, 0, err
	}

	if offers == nil {
		offers = []models.Offer{}
	}

	return offers, total, nil
}

func (s *SearchService) buildRestaurantBase(filters SearchFilters) *gorm.DB {
	tx := s.db.Model(&models.Restaurant{}).
		Where("status = ?", models.RestaurantApproved)

	if filters.Query != "" {
		like := "%" + filters.Query + "%"
		tx = tx.Where(
			"name ILIKE ? OR COALESCE(description, '') ILIKE ?",
			like, like,
		)
	}

	if len(filters.Cuisine) > 0 {
		tx = tx.Where("cuisine_tags && ?", filters.Cuisine)
	}

	if filters.Lat != nil && filters.Lng != nil {
		haversine := `(
			6371 * acos(
				cos(radians(?)) * cos(radians(latitude)) *
				cos(radians(longitude) - radians(?)) +
				sin(radians(?)) * sin(radians(latitude))
			)
		) <= ?`
		tx = tx.Where(haversine, *filters.Lat, *filters.Lng, *filters.Lat, filters.RadiusKm)
	}

	return tx
}

func (s *SearchService) SearchRestaurants(filters SearchFilters) ([]models.Restaurant, int64, error) {
	var total int64
	if err := s.buildRestaurantBase(filters).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	if total == 0 {
		return []models.Restaurant{}, 0, nil
	}

	tx := s.buildRestaurantBase(filters)

	switch filters.Sort {
	case "oldest":
		tx = tx.Order("created_at ASC")
	case "nearest":
		if filters.Lat != nil && filters.Lng != nil {
			order := fmt.Sprintf(`(
				6371 * acos(
					cos(radians(%f)) * cos(radians(latitude)) *
					cos(radians(longitude) - radians(%f)) +
					sin(radians(%f)) * sin(radians(latitude))
				)
			) ASC`, *filters.Lat, *filters.Lng, *filters.Lat)
			tx = tx.Order(order)
		} else {
			tx = tx.Order("created_at DESC")
		}
	default:
		tx = tx.Order("created_at DESC")
	}

	var restaurants []models.Restaurant
	if err := tx.
		Offset(filters.Params.Offset).
		Limit(filters.Params.PerPage).
		Find(&restaurants).Error; err != nil {
		return nil, 0, err
	}

	if restaurants == nil {
		restaurants = []models.Restaurant{}
	}

	return restaurants, total, nil
}

func (s *SearchService) SearchAll(filters SearchFilters) (SearchResult, error) {
	offers, offerTotal, err := s.SearchOffers(filters)
	if err != nil {
		return SearchResult{}, err
	}

	return SearchResult{
		Offers: offers,
		Total:  offerTotal,
	}, nil
}
