package services

import (
	"errors"

	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/dto/request"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/nomnom-lk/backend/pkg/locale"
	"gorm.io/gorm"
)

type DashboardService struct {
	restaurantRepo *repository.RestaurantRepo
	offerRepo      *repository.OfferRepo
}

func NewDashboardService(restaurantRepo *repository.RestaurantRepo, offerRepo *repository.OfferRepo) *DashboardService {
	return &DashboardService{
		restaurantRepo: restaurantRepo,
		offerRepo:      offerRepo,
	}
}

func (s *DashboardService) ListRestaurants(ownerID uuid.UUID, status, query string, page, perPage int) ([]models.Restaurant, int64, error) {
	return s.restaurantRepo.FindAllByOwner(ownerID, status, query, page, perPage)
}

func (s *DashboardService) ListOffers(ownerID uuid.UUID, status, query string, page, perPage int, sort string) ([]models.Offer, int64, error) {
	return s.offerRepo.FindAllByOwner(ownerID, status, query, page, perPage, sort)
}

func (s *DashboardService) GetRestaurantByIDForOwner(ownerID, restaurantID uuid.UUID) (*models.Restaurant, error) {
	restaurant, err := s.restaurantRepo.FindByID(restaurantID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("restaurant not found")
		}
		return nil, err
	}
	if ownerID != uuid.Nil && (restaurant.OwnerID == nil || *restaurant.OwnerID != ownerID) {
		return nil, errors.New("restaurant not found")
	}
	return restaurant, nil
}

func (s *DashboardService) GetOfferByIDForOwner(ownerID, offerID uuid.UUID) (*models.Offer, error) {
	offer, err := s.offerRepo.FindByID(offerID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("offer not found")
		}
		return nil, err
	}
	if ownerID != uuid.Nil && (offer.CreatedBy == nil || *offer.CreatedBy != ownerID) {
		return nil, errors.New("offer not found")
	}
	return offer, nil
}

func (s *DashboardService) Stats(ownerID uuid.UUID) (map[string]interface{}, error) {
	var totalRestaurants, totalOffers, pendingRestaurants, pendingOffers int64

	restaurants, err := s.restaurantRepo.FindByOwnerID(ownerID)
	if err != nil {
		return nil, err
	}
	totalRestaurants = int64(len(restaurants))

	for _, r := range restaurants {
		if r.Status == models.RestaurantPending {
			pendingRestaurants++
		}
		offers, err := s.offerRepo.FindByRestaurantID(r.ID)
		if err != nil {
			continue
		}
		totalOffers += int64(len(offers))
		for _, o := range offers {
			if o.Status == models.OfferPending {
				pendingOffers++
			}
		}
	}

	return map[string]interface{}{
		"total_restaurants":   totalRestaurants,
		"total_offers":        totalOffers,
		"pending_restaurants": pendingRestaurants,
		"pending_offers":      pendingOffers,
	}, nil
}

func (s *DashboardService) CreateRestaurant(req *request.CreateRestaurantRequest, ownerID uuid.UUID) (*models.Restaurant, error) {
	restaurant := &models.Restaurant{
		Name:         req.Name,
		Description:  strPtr(req.Description),
		Address:      req.Address,
		Latitude:     req.Latitude,
		Longitude:    req.Longitude,
		ContactPhone: strPtr(req.ContactPhone),
		CuisineTags:  req.CuisineTags,
		CoverImage:   strPtr(req.CoverImage),
		OwnerID:      &ownerID,
		Status:       models.RestaurantPending,
	}

	translations := locale.BuildTranslations(req.NameSi, req.NameTa, req.DescriptionSi, req.DescriptionTa)
	restaurant.Translations = translations

	if err := restaurant.Validate(); err != nil {
		return nil, err
	}
	if err := s.restaurantRepo.Create(restaurant); err != nil {
		return nil, err
	}
	return restaurant, nil
}

func (s *DashboardService) UpdateRestaurant(id uuid.UUID, ownerID uuid.UUID, req *request.UpdateRestaurantRequest) (*models.Restaurant, error) {
	restaurant, err := s.restaurantRepo.FindByID(id)
	if err != nil {
		return nil, errors.New("restaurant not found")
	}
	if ownerID != uuid.Nil && (restaurant.OwnerID == nil || *restaurant.OwnerID != ownerID) {
		return nil, errors.New("restaurant not found")
	}

	if req.Name != nil {
		restaurant.Name = *req.Name
	}
	if req.Description != nil {
		restaurant.Description = req.Description
	}
	if req.Address != nil {
		restaurant.Address = *req.Address
	}
	if req.Latitude != nil {
		restaurant.Latitude = req.Latitude
	}
	if req.Longitude != nil {
		restaurant.Longitude = req.Longitude
	}
	if req.ContactPhone != nil {
		restaurant.ContactPhone = req.ContactPhone
	}
	if req.CuisineTags != nil {
		restaurant.CuisineTags = *req.CuisineTags
	}
	if req.CoverImage != nil {
		restaurant.CoverImage = req.CoverImage
	}

	translations := locale.BuildTranslations(
		derefStr(req.NameSi), derefStr(req.NameTa),
		derefStr(req.DescriptionSi), derefStr(req.DescriptionTa),
	)
	if translations != nil {
		restaurant.Translations = translations
	}

	if err := s.restaurantRepo.Update(restaurant); err != nil {
		return nil, err
	}
	return restaurant, nil
}

func (s *DashboardService) DeleteRestaurant(id uuid.UUID, ownerID uuid.UUID) error {
	restaurant, err := s.restaurantRepo.FindByID(id)
	if err != nil {
		return errors.New("restaurant not found")
	}
	if ownerID != uuid.Nil && (restaurant.OwnerID == nil || *restaurant.OwnerID != ownerID) {
		return errors.New("restaurant not found")
	}
	return s.restaurantRepo.Delete(id)
}

func (s *DashboardService) CreateOffer(req *request.CreateOfferRequest, ownerID uuid.UUID) (*models.Offer, error) {
	restaurantID, err := uuid.Parse(req.RestaurantID)
	if err != nil {
		return nil, errors.New("invalid restaurant_id")
	}

	restaurant, err := s.restaurantRepo.FindByID(restaurantID)
	if err != nil {
		return nil, errors.New("restaurant not found")
	}
	if ownerID != uuid.Nil && (restaurant.OwnerID == nil || *restaurant.OwnerID != ownerID) {
		return nil, errors.New("restaurant not found")
	}

	offer := &models.Offer{
		RestaurantID:  restaurantID,
		Title:         req.Title,
		Description:   strPtr(req.Description),
		OriginalPrice: req.OriginalPrice,
		OfferPrice:    req.OfferPrice,
		ImageURLs:     req.ImageURLs,
		CategoryIDs:   req.CategoryIDs,
		StartDate:     req.StartDate,
		EndDate:       req.EndDate,
		PublishAt:     req.PublishAt,
		CreatedBy:     &ownerID,
		Status:        models.OfferPending,
	}

	translations := locale.BuildTranslations(req.TitleSi, req.TitleTa, req.DescriptionSi, req.DescriptionTa)
	if translations != nil {
		offer.Translations = translations
	}

	if err := offer.Validate(); err != nil {
		return nil, err
	}
	if err := s.offerRepo.Create(offer); err != nil {
		return nil, err
	}
	return offer, nil
}

func (s *DashboardService) UpdateOffer(id uuid.UUID, ownerID uuid.UUID, req *request.UpdateOfferRequest) (*models.Offer, error) {
	offer, err := s.offerRepo.FindByID(id)
	if err != nil {
		return nil, errors.New("offer not found")
	}
	if ownerID != uuid.Nil && (offer.CreatedBy == nil || *offer.CreatedBy != ownerID) {
		return nil, errors.New("offer not found")
	}

	if req.RestaurantID != nil {
		if rid, err := uuid.Parse(*req.RestaurantID); err == nil {
			offer.RestaurantID = rid
		}
	}
	if req.Title != nil {
		offer.Title = *req.Title
	}
	if req.Description != nil {
		offer.Description = req.Description
	}
	if req.OriginalPrice != nil {
		offer.OriginalPrice = *req.OriginalPrice
	}
	if req.OfferPrice != nil {
		offer.OfferPrice = *req.OfferPrice
	}
	if req.ImageURLs != nil {
		offer.ImageURLs = *req.ImageURLs
	}
	if req.StartDate != nil {
		offer.StartDate = req.StartDate
	}
	if req.EndDate != nil {
		offer.EndDate = *req.EndDate
	}
	if req.CategoryIDs != nil {
		offer.CategoryIDs = *req.CategoryIDs
	}
	if req.PublishAt != nil {
		offer.PublishAt = req.PublishAt
	}

	translations := locale.BuildTranslations(
		derefStr(req.TitleSi), derefStr(req.TitleTa),
		derefStr(req.DescriptionSi), derefStr(req.DescriptionTa),
	)
	if translations != nil {
		offer.Translations = translations
	}

	if err := s.offerRepo.Update(offer); err != nil {
		return nil, err
	}
	return offer, nil
}

func (s *DashboardService) DeleteOffer(id uuid.UUID, ownerID uuid.UUID) error {
	offer, err := s.offerRepo.FindByID(id)
	if err != nil {
		return errors.New("offer not found")
	}
	if ownerID != uuid.Nil && (offer.CreatedBy == nil || *offer.CreatedBy != ownerID) {
		return errors.New("offer not found")
	}
	return s.offerRepo.Delete(id)
}
