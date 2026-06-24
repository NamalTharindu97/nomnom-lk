package services

import (
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/dto/request"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/nomnom-lk/backend/pkg/locale"
	"gorm.io/gorm"
)

type RestaurantService struct {
	repo *repository.RestaurantRepo
}

func NewRestaurantService(repo *repository.RestaurantRepo) *RestaurantService {
	return &RestaurantService{repo: repo}
}

func (s *RestaurantService) Create(req *request.CreateRestaurantRequest, ownerID *uuid.UUID, isAdmin bool) (*models.Restaurant, error) {
	restaurant := &models.Restaurant{
		Name:         req.Name,
		Description:  strPtr(req.Description),
		Address:      req.Address,
		Latitude:     req.Latitude,
		Longitude:    req.Longitude,
		ContactPhone: strPtr(req.ContactPhone),
		CuisineTags:  req.CuisineTags,
		CoverImage:   strPtr(req.CoverImage),
	}

	if ownerID != nil && !isAdmin {
		restaurant.OwnerID = ownerID
		restaurant.Status = models.RestaurantPending
	} else {
		restaurant.Status = models.RestaurantApproved
	}

	translations := locale.BuildTranslations(req.NameSi, req.NameTa, req.DescriptionSi, req.DescriptionTa)
	restaurant.Translations = translations

	if err := restaurant.Validate(); err != nil {
		return nil, err
	}

	if err := s.repo.Create(restaurant); err != nil {
		return nil, fmt.Errorf("failed to create restaurant: %w", err)
	}
	return restaurant, nil
}

func (s *RestaurantService) GetByID(id uuid.UUID) (*models.Restaurant, error) {
	restaurant, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("restaurant not found")
		}
		return nil, fmt.Errorf("failed to find restaurant: %w", err)
	}
	return restaurant, nil
}

func (s *RestaurantService) List(status string, page, perPage int) ([]models.Restaurant, int64, error) {
	return s.repo.FindAll(status, page, perPage)
}

func (s *RestaurantService) Update(id uuid.UUID, req *request.UpdateRestaurantRequest, requesterID uuid.UUID, isAdmin bool) (*models.Restaurant, error) {
	restaurant, err := s.repo.FindByID(id)
	if err != nil {
		return nil, errors.New("restaurant not found")
	}

	if !isAdmin && (restaurant.OwnerID == nil || *restaurant.OwnerID != requesterID) {
		return nil, errors.New("not authorized to update this restaurant")
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

	if err := s.repo.Update(restaurant); err != nil {
		return nil, fmt.Errorf("failed to update restaurant: %w", err)
	}
	return restaurant, nil
}

func (s *RestaurantService) Delete(id uuid.UUID) error {
	return s.repo.Delete(id)
}

func (s *RestaurantService) Approve(id uuid.UUID) (*models.Restaurant, error) {
	restaurant, err := s.repo.FindByID(id)
	if err != nil {
		return nil, errors.New("restaurant not found")
	}
	if err := s.repo.UpdateStatus(id, models.RestaurantApproved); err != nil {
		return nil, err
	}
	restaurant.Status = models.RestaurantApproved
	return restaurant, nil
}

func (s *RestaurantService) Reject(id uuid.UUID) (*models.Restaurant, error) {
	restaurant, err := s.repo.FindByID(id)
	if err != nil {
		return nil, errors.New("restaurant not found")
	}
	if err := s.repo.UpdateStatus(id, models.RestaurantRejected); err != nil {
		return nil, err
	}
	restaurant.Status = models.RestaurantRejected
	return restaurant, nil
}

func (s *RestaurantService) ListPending(page, perPage int) ([]models.Restaurant, int64, error) {
	return s.repo.FindPending(page, perPage)
}

func strPtr(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

func derefStr(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}
