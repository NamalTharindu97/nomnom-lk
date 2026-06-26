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

type OfferService struct {
	repo       *repository.OfferRepo
	restRepo   *repository.RestaurantRepo
}

func NewOfferService(repo *repository.OfferRepo, restRepo *repository.RestaurantRepo) *OfferService {
	return &OfferService{
		repo:     repo,
		restRepo: restRepo,
	}
}

func (s *OfferService) Create(req *request.CreateOfferRequest, createdBy uuid.UUID, isAdmin bool) (*models.Offer, error) {
	restaurantID, err := uuid.Parse(req.RestaurantID)
	if err != nil {
		return nil, errors.New("invalid restaurant_id")
	}

	_, err = s.restRepo.FindByID(restaurantID)
	if err != nil {
		return nil, errors.New("restaurant not found")
	}

	offer := &models.Offer{
		RestaurantID:  restaurantID,
		Title:         req.Title,
		Description:   strPtr(req.Description),
		OriginalPrice: req.OriginalPrice,
		OfferPrice:    req.OfferPrice,
		ImageURLs:     req.ImageURLs,
		StartDate:     req.StartDate,
		EndDate:       req.EndDate,
		CreatedBy:     &createdBy,
	}

	if isAdmin {
		offer.Status = models.OfferApproved
	} else {
		offer.Status = models.OfferPending
	}

	translations := locale.BuildTranslations(req.TitleSi, req.TitleTa, req.DescriptionSi, req.DescriptionTa)
	if translations != nil {
		offer.Translations = translations
	}

	if err := offer.Validate(); err != nil {
		return nil, err
	}

	if err := s.repo.Create(offer); err != nil {
		return nil, fmt.Errorf("failed to create offer: %w", err)
	}
	return offer, nil
}

func (s *OfferService) GetByID(id uuid.UUID) (*models.Offer, error) {
	offer, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("offer not found")
		}
		return nil, fmt.Errorf("failed to find offer: %w", err)
	}
	return offer, nil
}

func (s *OfferService) List(status string, page, perPage int, sort string) ([]models.Offer, int64, error) {
	return s.repo.FindAll(status, page, perPage, sort)
}

func (s *OfferService) Update(id uuid.UUID, req *request.UpdateOfferRequest, requesterID uuid.UUID, isAdmin bool) (*models.Offer, error) {
	offer, err := s.repo.FindByID(id)
	if err != nil {
		return nil, errors.New("offer not found")
	}

	if !isAdmin && (offer.CreatedBy == nil || *offer.CreatedBy != requesterID) {
		return nil, errors.New("not authorized to update this offer")
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

	translations := locale.BuildTranslations(
		derefStr(req.TitleSi), derefStr(req.TitleTa),
		derefStr(req.DescriptionSi), derefStr(req.DescriptionTa),
	)
	if translations != nil {
		offer.Translations = translations
	}

	if err := s.repo.Update(offer); err != nil {
		return nil, fmt.Errorf("failed to update offer: %w", err)
	}
	return offer, nil
}

func (s *OfferService) Delete(id uuid.UUID, requesterID uuid.UUID, isAdmin bool) error {
	offer, err := s.repo.FindByID(id)
	if err != nil {
		return errors.New("offer not found")
	}

	if !isAdmin && (offer.CreatedBy == nil || *offer.CreatedBy != requesterID) {
		return errors.New("not authorized to delete this offer")
	}

	return s.repo.Delete(id)
}

func (s *OfferService) Approve(id uuid.UUID) (*models.Offer, error) {
	offer, err := s.repo.FindByID(id)
	if err != nil {
		return nil, errors.New("offer not found")
	}
	if err := s.repo.UpdateStatus(id, models.OfferApproved); err != nil {
		return nil, err
	}
	offer.Status = models.OfferApproved
	return offer, nil
}

func (s *OfferService) Reject(id uuid.UUID) (*models.Offer, error) {
	offer, err := s.repo.FindByID(id)
	if err != nil {
		return nil, errors.New("offer not found")
	}
	if err := s.repo.UpdateStatus(id, models.OfferRejected); err != nil {
		return nil, err
	}
	offer.Status = models.OfferRejected
	return offer, nil
}

func (s *OfferService) ListPending(page, perPage int) ([]models.Offer, int64, error) {
	return s.repo.FindPending(page, perPage)
}

func (s *OfferService) IncrementView(id uuid.UUID) error {
	return s.repo.IncrementViewCount(id)
}
