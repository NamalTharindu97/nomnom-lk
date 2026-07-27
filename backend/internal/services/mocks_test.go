package services

import (
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
)

// --- BannerRepo mock ---

type mockBannerRepo struct {
	metrics map[uuid.UUID]*repository.OwnerBannerMetrics
}

func newMockBannerRepo() *mockBannerRepo {
	return &mockBannerRepo{metrics: make(map[uuid.UUID]*repository.OwnerBannerMetrics)}
}

func (m *mockBannerRepo) CountStatsByOwner(ownerID uuid.UUID) (*repository.OwnerBannerMetrics, error) {
	if metrics, ok := m.metrics[ownerID]; ok {
		return metrics, nil
	}
	return &repository.OwnerBannerMetrics{}, nil
}

// --- FavoriteRepo mock ---

type mockFavoriteRepo struct {
	favorites map[string]models.Favorite
}

func newMockFavoriteRepo() *mockFavoriteRepo {
	return &mockFavoriteRepo{favorites: make(map[string]models.Favorite)}
}

func favKey(userID, offerID uuid.UUID) string {
	return userID.String() + ":" + offerID.String()
}

func (m *mockFavoriteRepo) Add(userID, offerID uuid.UUID) error {
	m.favorites[favKey(userID, offerID)] = models.Favorite{
		UserID:  userID,
		OfferID: offerID,
	}
	return nil
}

func (m *mockFavoriteRepo) Remove(userID, offerID uuid.UUID) error {
	delete(m.favorites, favKey(userID, offerID))
	return nil
}

func (m *mockFavoriteRepo) FindByUser(userID uuid.UUID, page, perPage int) ([]models.Favorite, int64, error) {
	var result []models.Favorite
	for _, f := range m.favorites {
		if f.UserID == userID {
			result = append(result, f)
		}
	}
	return result, int64(len(result)), nil
}

func (m *mockFavoriteRepo) IsFavorited(userID, offerID uuid.UUID) (bool, error) {
	_, ok := m.favorites[favKey(userID, offerID)]
	return ok, nil
}

func (m *mockFavoriteRepo) GetFavoriteOfferIDs(userID uuid.UUID) ([]uuid.UUID, error) {
	var ids []uuid.UUID
	for _, f := range m.favorites {
		if f.UserID == userID {
			ids = append(ids, f.OfferID)
		}
	}
	return ids, nil
}

// --- AuditLogRepo mock ---

type mockAuditLogRepo struct {
	logs []models.AuditLog
}

func newMockAuditLogRepo() *mockAuditLogRepo {
	return &mockAuditLogRepo{}
}

func (m *mockAuditLogRepo) Create(log *models.AuditLog) error {
	if log.ID == uuid.Nil {
		log.ID = uuid.New()
	}
	m.logs = append(m.logs, *log)
	return nil
}
