package services

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/dto/request"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/gorm"
)

type mockOfferRepo struct {
	offers map[uuid.UUID]*models.Offer
}

func newMockOfferRepo() *mockOfferRepo {
	return &mockOfferRepo{offers: make(map[uuid.UUID]*models.Offer)}
}

func (m *mockOfferRepo) Create(offer *models.Offer) error {
	if offer.ID == uuid.Nil {
		offer.ID = uuid.New()
	}
	m.offers[offer.ID] = offer
	return nil
}

func (m *mockOfferRepo) FindByID(id uuid.UUID) (*models.Offer, error) {
	o, ok := m.offers[id]
	if !ok {
		return nil, gorm.ErrRecordNotFound
	}
	return o, nil
}

func (m *mockOfferRepo) Update(offer *models.Offer) error {
	m.offers[offer.ID] = offer
	return nil
}

func (m *mockOfferRepo) Delete(id uuid.UUID) error {
	delete(m.offers, id)
	return nil
}

func (m *mockOfferRepo) UpdateStatus(id uuid.UUID, status models.OfferStatus) error {
	o, ok := m.offers[id]
	if !ok {
		return errors.New("not found")
	}
	o.Status = status
	return nil
}

func (m *mockOfferRepo) FindAll(status, query string, page, perPage int, sort string) ([]models.Offer, int64, error) {
	var result []models.Offer
	for _, o := range m.offers {
		if status == "" || string(o.Status) == status {
			result = append(result, *o)
		}
	}
	return result, int64(len(result)), nil
}

func (m *mockOfferRepo) FindPending(page, perPage int) ([]models.Offer, int64, error) {
	return m.FindAll("pending", "", page, perPage, "")
}

func (m *mockOfferRepo) ExpirePastOffers() error {
	return nil
}

func (m *mockOfferRepo) FindByRestaurantID(restaurantID uuid.UUID) ([]models.Offer, error) {
	return nil, nil
}

func (m *mockOfferRepo) CountAll(count *int64) error {
	*count = int64(len(m.offers))
	return nil
}

func (m *mockOfferRepo) CountByStatus(status string, count *int64) error {
	var c int64
	for _, o := range m.offers {
		if string(o.Status) == status {
			c++
		}
	}
	*count = c
	return nil
}

func (m *mockOfferRepo) CountByDate(days int) ([]map[string]interface{}, error) {
	return nil, nil
}

func (m *mockOfferRepo) IncrementViewCount(id uuid.UUID) error {
	return nil
}
func (m *mockOfferRepo) FindAllByOwner(ownerID uuid.UUID, status, query string, page, perPage int, sort string) ([]models.Offer, int64, error) {
	return nil, 0, nil
}
func (m *mockOfferRepo) BulkUpdateStatus(ids []uuid.UUID, status models.OfferStatus) error {
	return nil
}
func (m *mockOfferRepo) BulkDelete(ids []uuid.UUID) error {
	return nil
}
func (m *mockOfferRepo) TopByFavorites(limit int) ([]map[string]interface{}, error) {
	return nil, nil
}
func (m *mockOfferRepo) TopByViews(limit int) ([]models.Offer, error) {
	return nil, nil
}

type mockRestaurantRepo struct {
	restaurants map[uuid.UUID]*models.Restaurant
}

func newMockRestaurantRepo() *mockRestaurantRepo {
	return &mockRestaurantRepo{restaurants: make(map[uuid.UUID]*models.Restaurant)}
}

func (m *mockRestaurantRepo) FindByID(id uuid.UUID) (*models.Restaurant, error) {
	r, ok := m.restaurants[id]
	if !ok {
		return nil, gorm.ErrRecordNotFound
	}
	return r, nil
}

func (m *mockRestaurantRepo) Create(restaurant *models.Restaurant) error {
	return nil
}

func (m *mockRestaurantRepo) FindAll(status, query string, page, perPage int) ([]models.Restaurant, int64, error) {
	return nil, 0, nil
}

func (m *mockRestaurantRepo) FindPending(page, perPage int) ([]models.Restaurant, int64, error) {
	return nil, 0, nil
}

func (m *mockRestaurantRepo) FindByOwnerID(ownerID uuid.UUID) ([]models.Restaurant, error) {
	return nil, nil
}

func (m *mockRestaurantRepo) Update(restaurant *models.Restaurant) error {
	return nil
}

func (m *mockRestaurantRepo) Delete(id uuid.UUID) error {
	return nil
}

func (m *mockRestaurantRepo) UpdateStatus(id uuid.UUID, status models.RestaurantStatus) error {
	return nil
}

func (m *mockRestaurantRepo) CountAll(count *int64) error {
	return nil
}

func (m *mockRestaurantRepo) CountByStatus(status string, count *int64) error {
	return nil
}

func (m *mockRestaurantRepo) CountByDate(days int) ([]map[string]interface{}, error) {
	return nil, nil
}
func (m *mockRestaurantRepo) FindAllByOwner(ownerID uuid.UUID, status, query string, page, perPage int) ([]models.Restaurant, int64, error) {
	return nil, 0, nil
}
func (m *mockRestaurantRepo) BulkUpdateStatus(ids []uuid.UUID, status models.RestaurantStatus) error {
	return nil
}
func (m *mockRestaurantRepo) BulkDelete(ids []uuid.UUID) error {
	return nil
}
func (m *mockRestaurantRepo) TopByOfferCount(limit int) ([]map[string]interface{}, error) {
	return nil, nil
}

func TestOfferService_Create_Success(t *testing.T) {
	restID := uuid.New()
	userID := uuid.New()
	now := time.Now()

	mockOffer := newMockOfferRepo()
	mockRest := newMockRestaurantRepo()
	mockRest.restaurants[restID] = &models.Restaurant{ID: restID, Name: "Test"}

	svc := NewOfferService(mockOffer, mockRest, nil)

	req := &request.CreateOfferRequest{
		RestaurantID:  restID.String(),
		Title:         "Test Offer",
		Description:   "A description",
		OriginalPrice: 1000,
		OfferPrice:    700,
		StartDate:     &now,
		EndDate:       now.Add(72 * time.Hour),
	}

	offer, err := svc.Create(req, userID, false)
	require.NoError(t, err)
	require.NotNil(t, offer)
	assert.Equal(t, "Test Offer", offer.Title)
	assert.Equal(t, models.OfferPending, offer.Status)
	assert.Equal(t, restID, offer.RestaurantID)
}

func TestOfferService_Create_AdminAutoApproves(t *testing.T) {
	restID := uuid.New()
	userID := uuid.New()
	now := time.Now()

	mockOffer := newMockOfferRepo()
	mockRest := newMockRestaurantRepo()
	mockRest.restaurants[restID] = &models.Restaurant{ID: restID, Name: "Test"}

	svc := NewOfferService(mockOffer, mockRest, nil)

	req := &request.CreateOfferRequest{
		RestaurantID:  restID.String(),
		Title:         "Admin Offer",
		OriginalPrice: 500,
		OfferPrice:    400,
		EndDate:       now.Add(72 * time.Hour),
	}

	offer, err := svc.Create(req, userID, true)
	require.NoError(t, err)
	assert.Equal(t, models.OfferApproved, offer.Status)
}

func TestOfferService_Create_InvalidRestaurantID(t *testing.T) {
	svc := NewOfferService(newMockOfferRepo(), newMockRestaurantRepo(), nil)
	req := &request.CreateOfferRequest{
		RestaurantID:  "not-a-uuid",
		Title:         "Test",
		OriginalPrice: 100,
		OfferPrice:    50,
	}

	_, err := svc.Create(req, uuid.New(), false)
	assert.ErrorContains(t, err, "invalid restaurant_id")
}

func TestOfferService_Create_RestaurantNotFound(t *testing.T) {
	svc := NewOfferService(newMockOfferRepo(), newMockRestaurantRepo(), nil)
	req := &request.CreateOfferRequest{
		RestaurantID:  uuid.New().String(),
		Title:         "Test",
		OriginalPrice: 100,
		OfferPrice:    50,
	}

	_, err := svc.Create(req, uuid.New(), false)
	assert.ErrorContains(t, err, "restaurant not found")
}

func TestOfferService_GetByID_Found(t *testing.T) {
	mockOffer := newMockOfferRepo()
	mockRest := newMockRestaurantRepo()
	svc := NewOfferService(mockOffer, mockRest, nil)

	restID := uuid.New()
	mockRest.restaurants[restID] = &models.Restaurant{ID: restID, Name: "Test"}
	now := time.Now()
	req := &request.CreateOfferRequest{
		RestaurantID:  restID.String(),
		Title:         "Find Me",
		OriginalPrice: 100,
		OfferPrice:    50,
		EndDate:       now.Add(72 * time.Hour),
	}
	created, err := svc.Create(req, uuid.New(), false)
	require.NoError(t, err)

	found, err := svc.GetByID(created.ID)
	require.NoError(t, err)
	assert.Equal(t, created.ID, found.ID)
	assert.Equal(t, "Find Me", found.Title)
}

func TestOfferService_GetByID_NotFound(t *testing.T) {
	svc := NewOfferService(newMockOfferRepo(), newMockRestaurantRepo(), nil)
	_, err := svc.GetByID(uuid.New())
	assert.ErrorContains(t, err, "offer not found")
}

func TestOfferService_Update_OwnerCanUpdate(t *testing.T) {
	mockOffer := newMockOfferRepo()
	mockRest := newMockRestaurantRepo()
	restID := uuid.New()
	userID := uuid.New()
	mockRest.restaurants[restID] = &models.Restaurant{ID: restID, Name: "Test"}
	svc := NewOfferService(mockOffer, mockRest, nil)

	now := time.Now()
	req := &request.CreateOfferRequest{
		RestaurantID:  restID.String(),
		Title:         "Original",
		OriginalPrice: 100,
		OfferPrice:    50,
		EndDate:       now.Add(72 * time.Hour),
	}
	created, err := svc.Create(req, userID, false)
	require.NoError(t, err)

	newTitle := "Updated Title"
	updated, err := svc.Update(created.ID, &request.UpdateOfferRequest{Title: &newTitle}, userID, false)
	require.NoError(t, err)
	assert.Equal(t, "Updated Title", updated.Title)
}

func TestOfferService_Update_NonOwnerCannotUpdate(t *testing.T) {
	mockOffer := newMockOfferRepo()
	mockRest := newMockRestaurantRepo()
	restID := uuid.New()
	ownerID := uuid.New()
	otherUserID := uuid.New()
	mockRest.restaurants[restID] = &models.Restaurant{ID: restID, Name: "Test"}
	svc := NewOfferService(mockOffer, mockRest, nil)

	now := time.Now()
	req := &request.CreateOfferRequest{
		RestaurantID:  restID.String(),
		Title:         "Original",
		OriginalPrice: 100,
		OfferPrice:    50,
		EndDate:       now.Add(72 * time.Hour),
	}
	created, err := svc.Create(req, ownerID, false)
	require.NoError(t, err)

	newTitle := "Hacked"
	_, err = svc.Update(created.ID, &request.UpdateOfferRequest{Title: &newTitle}, otherUserID, false)
	assert.ErrorContains(t, err, "not authorized")
}

func TestOfferService_Update_AdminCanUpdateAny(t *testing.T) {
	mockOffer := newMockOfferRepo()
	mockRest := newMockRestaurantRepo()
	restID := uuid.New()
	mockRest.restaurants[restID] = &models.Restaurant{ID: restID, Name: "Test"}
	svc := NewOfferService(mockOffer, mockRest, nil)

	now := time.Now()
	req := &request.CreateOfferRequest{
		RestaurantID:  restID.String(),
		Title:         "Original",
		OriginalPrice: 100,
		OfferPrice:    50,
		EndDate:       now.Add(72 * time.Hour),
	}
	created, err := svc.Create(req, uuid.New(), false)
	require.NoError(t, err)

	newTitle := "Admin Updated"
	updated, err := svc.Update(created.ID, &request.UpdateOfferRequest{Title: &newTitle}, uuid.New(), true)
	require.NoError(t, err)
	assert.Equal(t, "Admin Updated", updated.Title)
}

func TestOfferService_Delete_OwnerCanDelete(t *testing.T) {
	mockOffer := newMockOfferRepo()
	mockRest := newMockRestaurantRepo()
	restID := uuid.New()
	userID := uuid.New()
	mockRest.restaurants[restID] = &models.Restaurant{ID: restID, Name: "Test"}
	svc := NewOfferService(mockOffer, mockRest, nil)

	now := time.Now()
	req := &request.CreateOfferRequest{
		RestaurantID:  restID.String(),
		Title:         "Delete Me",
		OriginalPrice: 100,
		OfferPrice:    50,
		EndDate:       now.Add(72 * time.Hour),
	}
	created, err := svc.Create(req, userID, false)
	require.NoError(t, err)

	err = svc.Delete(created.ID, userID, false)
	assert.NoError(t, err)

	_, err = svc.GetByID(created.ID)
	assert.Error(t, err)
}

func TestOfferService_Delete_NonOwnerFails(t *testing.T) {
	mockOffer := newMockOfferRepo()
	mockRest := newMockRestaurantRepo()
	restID := uuid.New()
	mockRest.restaurants[restID] = &models.Restaurant{ID: restID, Name: "Test"}
	svc := NewOfferService(mockOffer, mockRest, nil)

	now := time.Now()
	req := &request.CreateOfferRequest{
		RestaurantID:  restID.String(),
		Title:         "Delete Me",
		OriginalPrice: 100,
		OfferPrice:    50,
		EndDate:       now.Add(72 * time.Hour),
	}
	created, err := svc.Create(req, uuid.New(), false)
	require.NoError(t, err)

	err = svc.Delete(created.ID, uuid.New(), false)
	assert.ErrorContains(t, err, "not authorized")
}

func TestOfferService_Approve(t *testing.T) {
	mockOffer := newMockOfferRepo()
	mockRest := newMockRestaurantRepo()
	restID := uuid.New()
	mockRest.restaurants[restID] = &models.Restaurant{ID: restID, Name: "Test"}
	svc := NewOfferService(mockOffer, mockRest, nil)

	now := time.Now()
	req := &request.CreateOfferRequest{
		RestaurantID:  restID.String(),
		Title:         "Approve Me",
		OriginalPrice: 100,
		OfferPrice:    50,
		EndDate:       now.Add(72 * time.Hour),
	}
	created, err := svc.Create(req, uuid.New(), false)
	require.NoError(t, err)
	assert.Equal(t, models.OfferPending, created.Status)

	approved, err := svc.Approve(created.ID)
	require.NoError(t, err)
	assert.Equal(t, models.OfferApproved, approved.Status)
}

func TestOfferService_Reject(t *testing.T) {
	mockOffer := newMockOfferRepo()
	mockRest := newMockRestaurantRepo()
	restID := uuid.New()
	mockRest.restaurants[restID] = &models.Restaurant{ID: restID, Name: "Test"}
	svc := NewOfferService(mockOffer, mockRest, nil)

	now := time.Now()
	req := &request.CreateOfferRequest{
		RestaurantID:  restID.String(),
		Title:         "Reject Me",
		OriginalPrice: 100,
		OfferPrice:    50,
		EndDate:       now.Add(72 * time.Hour),
	}
	created, err := svc.Create(req, uuid.New(), false)
	require.NoError(t, err)
	assert.Equal(t, models.OfferPending, created.Status)

	rejected, err := svc.Reject(created.ID)
	require.NoError(t, err)
	assert.Equal(t, models.OfferRejected, rejected.Status)
}

func TestOfferService_List(t *testing.T) {
	mockOffer := newMockOfferRepo()
	mockRest := newMockRestaurantRepo()
	restID := uuid.New()
	mockRest.restaurants[restID] = &models.Restaurant{ID: restID, Name: "Test"}
	svc := NewOfferService(mockOffer, mockRest, nil)

	now := time.Now()
	for i := 0; i < 5; i++ {
		req := &request.CreateOfferRequest{
			RestaurantID:  restID.String(),
			Title:         "Offer",
			OriginalPrice: 100,
			OfferPrice:    50,
			EndDate:       now.Add(72 * time.Hour),
		}
		svc.Create(req, uuid.New(), true)
	}

	offers, total, err := svc.List(context.Background(), "", "", 1, 10, "")
	require.NoError(t, err)
	assert.Equal(t, int64(5), total)
	assert.Len(t, offers, 5)
}

func TestOfferService_IncrementView(t *testing.T) {
	svc := NewOfferService(newMockOfferRepo(), newMockRestaurantRepo(), nil)
	err := svc.IncrementView(uuid.New())
	assert.NoError(t, err)
}

func TestOfferService_Create_ValidatesRestaurantSocialLinks(t *testing.T) {
	restID := uuid.New()
	userID := uuid.New()
	now := time.Now()

	ig := "https://instagram.com/test"
	fb := "https://facebook.com/test"
	web := "https://test.com"

	mockOffer := newMockOfferRepo()
	mockRest := newMockRestaurantRepo()
	mockRest.restaurants[restID] = &models.Restaurant{
		ID:             restID,
		Name:           "Test",
		InstagramURL:   &ig,
		FacebookURL:    &fb,
		WebsiteURL:     &web,
		OrderPlatforms: models.JSONStringSlice{"uber_eats"},
	}

	svc := NewOfferService(mockOffer, mockRest, nil)

	req := &request.CreateOfferRequest{
		RestaurantID:  restID.String(),
		Title:         "Social Links Test",
		Description:   "Testing social link validation",
		OriginalPrice: 1000,
		OfferPrice:    700,
		StartDate:     &now,
		EndDate:       now.Add(72 * time.Hour),
	}

	offer, err := svc.Create(req, userID, false)
	require.NoError(t, err)
	require.NotNil(t, offer)
	assert.Equal(t, restID, offer.RestaurantID)

	restaurant := mockRest.restaurants[restID]
	require.NotNil(t, restaurant)
	assert.Equal(t, ig, *restaurant.InstagramURL)
	assert.Equal(t, fb, *restaurant.FacebookURL)
	assert.Equal(t, web, *restaurant.WebsiteURL)
	assert.Contains(t, restaurant.OrderPlatforms, "uber_eats")
}

func TestOfferService_Create_WithAlternateOrderPlatforms(t *testing.T) {
	restID := uuid.New()
	userID := uuid.New()
	now := time.Now()

	ig := "https://instagram.com/test"
	fb := "https://facebook.com/test"

	mockOffer := newMockOfferRepo()
	mockRest := newMockRestaurantRepo()
	mockRest.restaurants[restID] = &models.Restaurant{
		ID:             restID,
		Name:           "Test",
		InstagramURL:   &ig,
		FacebookURL:    &fb,
		OrderPlatforms: models.JSONStringSlice{"uber_eats", "pickme"},
	}

	svc := NewOfferService(mockOffer, mockRest, nil)

	req := &request.CreateOfferRequest{
		RestaurantID:  restID.String(),
		Title:         "Alt Order URL Test",
		Description:   "Testing alternate order URL",
		OriginalPrice: 1000,
		OfferPrice:    700,
		StartDate:     &now,
		EndDate:       now.Add(72 * time.Hour),
	}

	offer, err := svc.Create(req, userID, false)
	require.NoError(t, err)
	require.NotNil(t, offer)
	assert.Equal(t, restID, offer.RestaurantID)

	restaurant := mockRest.restaurants[restID]
	require.NotNil(t, restaurant)
	assert.Contains(t, restaurant.OrderPlatforms, "uber_eats")
	assert.Contains(t, restaurant.OrderPlatforms, "pickme")
}


