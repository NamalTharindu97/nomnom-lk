package services

import (
	"testing"

	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/dto/request"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestRestaurantService_Create_Success(t *testing.T) {
	repo := newMockRestaurantRepo()
	svc := NewRestaurantService(repo)
	ownerID := uuid.New()

	req := &request.CreateRestaurantRequest{
		Name:        "Test Restaurant",
		Description: "A test restaurant",
	}

	r, err := svc.Create(req, &ownerID, false)
	require.NoError(t, err)
	assert.Equal(t, "Test Restaurant", r.Name)
	assert.Equal(t, models.RestaurantPending, r.Status)
	assert.NotNil(t, r.OwnerID)
	assert.Equal(t, ownerID, *r.OwnerID)
}

func TestRestaurantService_Create_AdminAutoApproves(t *testing.T) {
	repo := newMockRestaurantRepo()
	svc := NewRestaurantService(repo)
	adminID := uuid.New()

	req := &request.CreateRestaurantRequest{
		Name: "Admin Restaurant",
	}

	r, err := svc.Create(req, &adminID, true)
	require.NoError(t, err)
	assert.Equal(t, models.RestaurantApproved, r.Status)
}

func TestRestaurantService_Update_Success(t *testing.T) {
	repo := newMockRestaurantRepo()
	svc := NewRestaurantService(repo)
	ownerID := uuid.New()

	created, err := svc.Create(&request.CreateRestaurantRequest{Name: "Original"}, &ownerID, false)
	require.NoError(t, err)

	newName := "Updated Name"
	updated, err := svc.Update(created.ID, &request.UpdateRestaurantRequest{Name: &newName}, ownerID, false)
	require.NoError(t, err)
	assert.Equal(t, "Updated Name", updated.Name)
}

func TestRestaurantService_Update_OtherOwnerFails(t *testing.T) {
	repo := newMockRestaurantRepo()
	svc := NewRestaurantService(repo)
	ownerID := uuid.New()
	otherOwnerID := uuid.New()

	created, err := svc.Create(&request.CreateRestaurantRequest{Name: "Owner Restaurant"}, &ownerID, false)
	require.NoError(t, err)

	newName := "Hacked"
	_, err = svc.Update(created.ID, &request.UpdateRestaurantRequest{Name: &newName}, otherOwnerID, false)
	assert.Error(t, err)
}

func TestRestaurantService_Delete_Success(t *testing.T) {
	repo := newMockRestaurantRepo()
	svc := NewRestaurantService(repo)
	adminID := uuid.New()

	created, err := svc.Create(&request.CreateRestaurantRequest{Name: "Delete Me"}, nil, true)
	require.NoError(t, err)

	err = svc.Delete(created.ID, adminID, true)
	assert.NoError(t, err)

	_, err = repo.FindByID(created.ID)
	assert.Error(t, err)
}

func TestRestaurantService_Delete_OwnerCannotDeleteOther(t *testing.T) {
	repo := newMockRestaurantRepo()
	svc := NewRestaurantService(repo)
	ownerID := uuid.New()
	otherOwnerID := uuid.New()

	created, err := svc.Create(&request.CreateRestaurantRequest{Name: "Owner Restaurant"}, &ownerID, false)
	require.NoError(t, err)

	err = svc.Delete(created.ID, otherOwnerID, false)
	assert.Error(t, err)
}

func TestRestaurantService_Approve(t *testing.T) {
	repo := newMockRestaurantRepo()
	svc := NewRestaurantService(repo)
	ownerID := uuid.New()

	created, err := svc.Create(&request.CreateRestaurantRequest{Name: "Approve Me"}, &ownerID, false)
	require.NoError(t, err)
	assert.Equal(t, models.RestaurantPending, created.Status)

	approved, err := svc.Approve(created.ID)
	require.NoError(t, err)
	assert.Equal(t, models.RestaurantApproved, approved.Status)
}

func TestRestaurantService_Reject(t *testing.T) {
	repo := newMockRestaurantRepo()
	svc := NewRestaurantService(repo)
	ownerID := uuid.New()

	created, err := svc.Create(&request.CreateRestaurantRequest{Name: "Reject Me"}, &ownerID, false)
	require.NoError(t, err)
	assert.Equal(t, models.RestaurantPending, created.Status)

	rejected, err := svc.Reject(created.ID)
	require.NoError(t, err)
	assert.Equal(t, models.RestaurantRejected, rejected.Status)
}
