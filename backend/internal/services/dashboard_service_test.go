package services

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/dto/request"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/redis/go-redis/v9"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func setupDashboardService() (*DashboardService, *mockRestaurantRepo, *mockOfferRepo, *mockBannerRepo) {
	restRepo := newMockRestaurantRepo()
	offerRepo := newMockOfferRepo()
	bannerRepo := newMockBannerRepo()
	svc := NewDashboardService(restRepo, offerRepo, bannerRepo, nil)
	return svc, restRepo, offerRepo, bannerRepo
}

func TestDashboardService_Stats_Admin(t *testing.T) {
	svc, restRepo, offerRepo, bannerRepo := setupDashboardService()
	adminID := uuid.Nil

	restRepo.restaurants[uuid.New()] = &models.Restaurant{ID: uuid.New(), Status: models.RestaurantApproved}
	restRepo.restaurants[uuid.New()] = &models.Restaurant{ID: uuid.New(), Status: models.RestaurantPending}
	offerRepo.offers[uuid.New()] = &models.Offer{ID: uuid.New(), Status: models.OfferApproved}
	bannerRepo.metrics[adminID] = &repository.OwnerBannerMetrics{Total: 3, Active: 2}

	stats, err := svc.Stats(adminID)
	require.NoError(t, err)
	assert.Equal(t, int64(1), stats["total_offers"])
	assert.Equal(t, int64(3), stats["total_banners"])
}

func TestDashboardService_Stats_Owner(t *testing.T) {
	svc, restRepo, offerRepo, _ := setupDashboardService()
	ownerID := uuid.New()

	restRepo.restaurants[uuid.New()] = &models.Restaurant{ID: uuid.New(), OwnerID: &ownerID, Status: models.RestaurantApproved}
	offerRepo.offers[uuid.New()] = &models.Offer{ID: uuid.New(), Status: models.OfferApproved}

	stats, err := svc.Stats(ownerID)
	require.NoError(t, err)
	assert.Equal(t, int64(1), stats["total_restaurants"])
	assert.Equal(t, int64(1), stats["total_offers"])
}

func TestDashboardService_CreateRestaurant_Success(t *testing.T) {
	svc, _, _, _ := setupDashboardService()
	ownerID := uuid.New()

	req := &request.CreateRestaurantRequest{Name: "Owner Restaurant"}
	r, err := svc.CreateRestaurant(req, ownerID)
	require.NoError(t, err)
	assert.Equal(t, "Owner Restaurant", r.Name)
	assert.NotNil(t, r.OwnerID)
	assert.Equal(t, ownerID, *r.OwnerID)
	assert.Equal(t, models.RestaurantPending, r.Status)
}

func TestDashboardService_CreateRestaurant_Admin(t *testing.T) {
	svc, _, _, _ := setupDashboardService()

	req := &request.CreateRestaurantRequest{Name: "Admin Restaurant"}
	r, err := svc.CreateRestaurant(req, uuid.Nil)
	require.NoError(t, err)
	assert.Nil(t, r.OwnerID)
}

func TestDashboardService_UpdateRestaurant_Success(t *testing.T) {
	svc, restRepo, _, _ := setupDashboardService()
	ownerID := uuid.New()

	rest := &models.Restaurant{ID: uuid.New(), Name: "Original", OwnerID: &ownerID, Status: models.RestaurantPending}
	restRepo.restaurants[rest.ID] = rest

	newName := "Updated"
	updated, err := svc.UpdateRestaurant(rest.ID, ownerID, &request.UpdateRestaurantRequest{Name: &newName})
	require.NoError(t, err)
	assert.Equal(t, "Updated", updated.Name)
}

func TestDashboardService_UpdateRestaurant_OtherOwner(t *testing.T) {
	svc, restRepo, _, _ := setupDashboardService()
	ownerID := uuid.New()
	otherOwnerID := uuid.New()

	rest := &models.Restaurant{ID: uuid.New(), Name: "Owner", OwnerID: &ownerID, Status: models.RestaurantPending}
	restRepo.restaurants[rest.ID] = rest

	newName := "Hacked"
	_, err := svc.UpdateRestaurant(rest.ID, otherOwnerID, &request.UpdateRestaurantRequest{Name: &newName})
	assert.Error(t, err)
}

func TestDashboardService_DeleteRestaurant_Success(t *testing.T) {
	svc, restRepo, _, _ := setupDashboardService()

	rest := &models.Restaurant{ID: uuid.New(), Name: "Delete Me", Status: models.RestaurantPending}
	restRepo.restaurants[rest.ID] = rest

	err := svc.DeleteRestaurant(rest.ID, uuid.Nil)
	assert.NoError(t, err)
	_, ok := restRepo.restaurants[rest.ID]
	assert.False(t, ok)
}

func TestDashboardService_DeleteRestaurant_OwnerOther(t *testing.T) {
	svc, restRepo, _, _ := setupDashboardService()
	ownerID := uuid.New()
	otherOwnerID := uuid.New()

	rest := &models.Restaurant{ID: uuid.New(), Name: "Owner", OwnerID: &ownerID, Status: models.RestaurantPending}
	restRepo.restaurants[rest.ID] = rest

	err := svc.DeleteRestaurant(rest.ID, otherOwnerID)
	assert.Error(t, err)
}

func TestDashboardService_CreateOffer_Success(t *testing.T) {
	svc, restRepo, offerRepo, _ := setupDashboardService()
	ownerID := uuid.New()
	createdBy := uuid.New()

	rest := &models.Restaurant{ID: uuid.New(), Name: "R", OwnerID: &ownerID, Status: models.RestaurantApproved}
	restRepo.restaurants[rest.ID] = rest

	now := time.Now()
	req := &request.CreateOfferRequest{
		RestaurantID:  rest.ID.String(),
		Title:         "Test Offer",
		OriginalPrice: 1000,
		OfferPrice:    700,
		EndDate:       now.Add(72 * time.Hour),
	}

	offer, err := svc.CreateOffer(req, ownerID, createdBy)
	require.NoError(t, err)
	assert.Equal(t, "Test Offer", offer.Title)
	assert.Equal(t, models.OfferPending, offer.Status)
	assert.NotNil(t, offerRepo.offers[offer.ID])
}

func TestDashboardService_UpdateOffer_Success(t *testing.T) {
	svc, restRepo, offerRepo, _ := setupDashboardService()
	ownerID := uuid.New()

	rest := &models.Restaurant{ID: uuid.New(), Name: "R", OwnerID: &ownerID, Status: models.RestaurantApproved}
	restRepo.restaurants[rest.ID] = rest

	offer := &models.Offer{ID: uuid.New(), RestaurantID: rest.ID, Title: "Original", Status: models.OfferPending}
	offerRepo.offers[offer.ID] = offer

	newTitle := "Updated Offer"
	updated, err := svc.UpdateOffer(offer.ID, ownerID, &request.UpdateOfferRequest{Title: &newTitle})
	require.NoError(t, err)
	assert.Equal(t, "Updated Offer", updated.Title)
}

func TestDashboardService_DeleteOffer_Success(t *testing.T) {
	svc, restRepo, offerRepo, _ := setupDashboardService()
	ownerID := uuid.New()

	rest := &models.Restaurant{ID: uuid.New(), Name: "R", OwnerID: &ownerID, Status: models.RestaurantApproved}
	restRepo.restaurants[rest.ID] = rest

	offer := &models.Offer{ID: uuid.New(), RestaurantID: rest.ID, Title: "Delete Me", Status: models.OfferPending}
	offerRepo.offers[offer.ID] = offer

	err := svc.DeleteOffer(offer.ID, ownerID)
	assert.NoError(t, err)
	_, ok := offerRepo.offers[offer.ID]
	assert.False(t, ok)
}

func TestDashboardService_ListOffers_CacheDisabled(t *testing.T) {
	svc, _, offerRepo, _ := setupDashboardService()
	ownerID := uuid.New()

	offerRepo.offers[uuid.New()] = &models.Offer{ID: uuid.New(), Status: models.OfferApproved}
	offerRepo.offers[uuid.New()] = &models.Offer{ID: uuid.New(), Status: models.OfferPending}

	// rdb is nil, so caching is disabled — goes straight to repo
	offers, total, err := svc.ListOffers(context.Background(), ownerID, "", "", 1, 10, "", true)
	require.NoError(t, err)
	assert.Equal(t, int64(2), total)
	assert.Len(t, offers, 2)
}

func TestDashboardService_ListOffers_PortfolioReadDoesNotTouchCache(t *testing.T) {
	svc, _, offerRepo, _ := setupDashboardService()
	svc.rdb = redis.NewClient(&redis.Options{Addr: "127.0.0.1:1"})
	offerRepo.offers[uuid.New()] = &models.Offer{ID: uuid.New(), Status: models.OfferApproved}

	offers, total, err := svc.ListOffers(context.Background(), uuid.Nil, "", "", 1, 10, "", false)
	require.NoError(t, err)
	require.Equal(t, int64(1), total)
	require.Len(t, offers, 1)
}
