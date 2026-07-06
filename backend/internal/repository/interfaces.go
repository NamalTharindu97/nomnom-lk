package repository

import (
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
)

type OfferRepoInterface interface {
	Create(offer *models.Offer) error
	FindByID(id uuid.UUID) (*models.Offer, error)
	FindAll(status, query string, page, perPage int, sort string) ([]models.Offer, int64, error)
	FindAllByOwner(ownerID uuid.UUID, status, query string, page, perPage int, sort string) ([]models.Offer, int64, error)
	FindPending(page, perPage int) ([]models.Offer, int64, error)
	FindByRestaurantID(restaurantID uuid.UUID) ([]models.Offer, error)
	Update(offer *models.Offer) error
	Delete(id uuid.UUID) error
	UpdateStatus(id uuid.UUID, status models.OfferStatus) error
	BulkUpdateStatus(ids []uuid.UUID, status models.OfferStatus) error
	BulkDelete(ids []uuid.UUID) error
	CountAll(count *int64) error
	CountByStatus(status string, count *int64) error
	CountByDate(days int) ([]map[string]interface{}, error)
	ExpirePastOffers() error
	IncrementViewCount(id uuid.UUID) error
	TopByFavorites(limit int) ([]map[string]interface{}, error)
	TopByViews(limit int) ([]models.Offer, error)
}

type RestaurantRepoInterface interface {
	Create(restaurant *models.Restaurant) error
	FindByID(id uuid.UUID) (*models.Restaurant, error)
	FindAll(status, query string, page, perPage int) ([]models.Restaurant, int64, error)
	FindAllByOwner(ownerID uuid.UUID, status, query string, page, perPage int) ([]models.Restaurant, int64, error)
	FindPending(page, perPage int) ([]models.Restaurant, int64, error)
	FindByOwnerID(ownerID uuid.UUID) ([]models.Restaurant, error)
	Update(restaurant *models.Restaurant) error
	Delete(id uuid.UUID) error
	UpdateStatus(id uuid.UUID, status models.RestaurantStatus) error
	BulkUpdateStatus(ids []uuid.UUID, status models.RestaurantStatus) error
	BulkDelete(ids []uuid.UUID) error
	CountAll(count *int64) error
	CountByStatus(status string, count *int64) error
	CountByDate(days int) ([]map[string]interface{}, error)
	TopByOfferCount(limit int) ([]map[string]interface{}, error)
}

type UserRepoInterface interface {
	Create(user *models.User) error
	FindByID(id uuid.UUID) (*models.User, error)
	FindByEmail(email string) (*models.User, error)
	FindByFirebaseUID(uid string) (*models.User, error)
	Update(user *models.User) error
	SoftDelete(id uuid.UUID) error
	CountAll(count *int64) error
	FindAll(page, perPage int) ([]models.User, int64, error)
}

type FavoriteRepoInterface interface {
	Add(userID, offerID uuid.UUID) error
	Remove(userID, offerID uuid.UUID) error
	FindByUser(userID uuid.UUID) ([]models.Favorite, error)
	IsFavorited(userID, offerID uuid.UUID) (bool, error)
	GetFavoriteOfferIDs(userID uuid.UUID) ([]uuid.UUID, error)
}

type NotificationRepoInterface interface {
	Create(notification *models.Notification) error
	CreateBatch(notifications []models.Notification) error
	FindByUserID(userID uuid.UUID, page, perPage int) ([]models.Notification, int64, error)
	MarkAsRead(id uuid.UUID) error
	MarkAllAsRead(userID uuid.UUID) error
	GetUnreadCount(userID uuid.UUID) (int64, error)
	FindAllAdmin(page, perPage int) ([]models.Notification, int64, error)
	Delete(id uuid.UUID) error
	DeleteByOfferIDs(offerIDs []uuid.UUID) error
}

type DeviceTokenRepoInterface interface {
	Upsert(token *models.DeviceToken) error
	Delete(id uuid.UUID) error
	DeleteByToken(userID uuid.UUID, token string) error
	DeleteByTokenValue(token string) error
	FindByUserID(userID uuid.UUID) ([]models.DeviceToken, error)
	FindAll() ([]models.DeviceToken, error)
}

type RefreshTokenRepoInterface interface {
	Create(token *models.RefreshToken) error
	FindByHash(hash string) (*models.RefreshToken, error)
	DeleteByUserID(userID uuid.UUID) error
	DeleteByID(id uuid.UUID) error
	DeleteExpired() error
}
