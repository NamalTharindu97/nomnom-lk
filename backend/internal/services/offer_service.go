package services

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/dto/request"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/nomnom-lk/backend/pkg/locale"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

type OfferService struct {
	repo       repository.OfferRepoInterface
	restRepo   repository.RestaurantRepoInterface
	rdb        *redis.Client
}

func NewOfferService(repo repository.OfferRepoInterface, restRepo repository.RestaurantRepoInterface, rdb *redis.Client) *OfferService {
	return &OfferService{
		repo:     repo,
		restRepo: restRepo,
		rdb:      rdb,
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
		CategoryIDs:   req.CategoryIDs,
		StartDate:     req.StartDate,
		EndDate:       req.EndDate,
		PublishAt:     req.PublishAt,
		CreatedBy:     &createdBy,
	}

	if req.PublishAt != nil && req.PublishAt.After(time.Now()) {
		offer.Status = models.OfferPending
	} else if isAdmin {
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
	s.bumpOfferCacheVersion(context.Background())
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

func (s *OfferService) List(ctx context.Context, status, query string, page, perPage int, sort string) ([]models.Offer, int64, error) {
	if s.rdb == nil {
		return s.repo.FindAll(status, query, page, perPage, sort)
	}

	version := s.rdb.Get(ctx, "offers:cache_version").Val()
	cacheKey := fmt.Sprintf("offers:list:%s:%s:%d:%d:v%s", status, query, page, perPage, version)

	if cached, err := s.rdb.Get(ctx, cacheKey).Result(); err == nil {
		var result struct {
			Offers []models.Offer `json:"offers"`
			Total  int64          `json:"total"`
		}
		if err := json.Unmarshal([]byte(cached), &result); err == nil {
			return result.Offers, result.Total, nil
		}
	}

	offers, total, err := s.repo.FindAll(status, query, page, perPage, sort)
	if err != nil {
		return nil, 0, err
	}

	if data, err := json.Marshal(map[string]any{"offers": offers, "total": total}); err == nil {
		s.rdb.Set(ctx, cacheKey, string(data), 30*time.Second)
	}

	return offers, total, nil
}

func (s *OfferService) bumpOfferCacheVersion(ctx context.Context) {
	if s.rdb != nil {
		s.rdb.Incr(ctx, "offers:cache_version")
	}
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
	if req.CategoryIDs != nil {
		offer.CategoryIDs = *req.CategoryIDs
	}
	if req.PublishAt != nil {
		offer.PublishAt = req.PublishAt
		if req.PublishAt.After(time.Now()) {
			offer.Status = models.OfferPending
		}
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
	s.bumpOfferCacheVersion(context.Background())
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

	err = s.repo.Delete(id)
	if err == nil {
		s.bumpOfferCacheVersion(context.Background())
	}
	return err
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
	s.bumpOfferCacheVersion(context.Background())
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
	s.bumpOfferCacheVersion(context.Background())
	return offer, nil
}

func (s *OfferService) ListPending(page, perPage int) ([]models.Offer, int64, error) {
	return s.repo.FindPending(page, perPage)
}

func (s *OfferService) Expire(id uuid.UUID) (*models.Offer, error) {
	offer, err := s.repo.FindByID(id)
	if err != nil {
		return nil, errors.New("offer not found")
	}
	if err := s.repo.UpdateStatus(id, models.OfferExpired); err != nil {
		return nil, err
	}
	offer.Status = models.OfferExpired
	s.bumpOfferCacheVersion(context.Background())
	return offer, nil
}

func (s *OfferService) IncrementView(id uuid.UUID) error {
	return s.repo.IncrementViewCount(id)
}
