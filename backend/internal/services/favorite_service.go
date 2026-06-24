package services

import (
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
)

type FavoriteService struct {
	repo *repository.FavoriteRepo
}

func NewFavoriteService(repo *repository.FavoriteRepo) *FavoriteService {
	return &FavoriteService{repo: repo}
}

func (s *FavoriteService) Add(userID, offerID uuid.UUID) error {
	return s.repo.Add(userID, offerID)
}

func (s *FavoriteService) Remove(userID, offerID uuid.UUID) error {
	return s.repo.Remove(userID, offerID)
}

func (s *FavoriteService) List(userID uuid.UUID, page, perPage int) ([]models.Favorite, int64, error) {
	return s.repo.FindByUser(userID, page, perPage)
}

func (s *FavoriteService) IsFavorited(userID, offerID uuid.UUID) (bool, error) {
	return s.repo.IsFavorited(userID, offerID)
}

func (s *FavoriteService) GetFavoritedOfferIDs(userID uuid.UUID) ([]uuid.UUID, error) {
	return s.repo.GetFavoriteOfferIDs(userID)
}
