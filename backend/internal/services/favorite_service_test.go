package services

import (
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestFavoriteService_Add(t *testing.T) {
	repo := newMockFavoriteRepo()
	svc := NewFavoriteService(repo)
	userID := uuid.New()
	offerID := uuid.New()

	err := svc.Add(userID, offerID)
	assert.NoError(t, err)

	fav, err := repo.IsFavorited(userID, offerID)
	require.NoError(t, err)
	assert.True(t, fav)
}

func TestFavoriteService_Remove(t *testing.T) {
	repo := newMockFavoriteRepo()
	svc := NewFavoriteService(repo)
	userID := uuid.New()
	offerID := uuid.New()

	require.NoError(t, svc.Add(userID, offerID))

	err := svc.Remove(userID, offerID)
	assert.NoError(t, err)

	fav, err := repo.IsFavorited(userID, offerID)
	require.NoError(t, err)
	assert.False(t, fav)
}

func TestFavoriteService_List(t *testing.T) {
	repo := newMockFavoriteRepo()
	svc := NewFavoriteService(repo)
	userID := uuid.New()

	require.NoError(t, svc.Add(userID, uuid.New()))
	require.NoError(t, svc.Add(userID, uuid.New()))

	favorites, total, err := svc.List(userID, 1, 10)
	require.NoError(t, err)
	assert.Equal(t, int64(2), total)
	assert.Len(t, favorites, 2)
}

func TestFavoriteService_IsFavorited(t *testing.T) {
	repo := newMockFavoriteRepo()
	svc := NewFavoriteService(repo)
	userID := uuid.New()
	offerID := uuid.New()

	isFav, err := svc.IsFavorited(userID, offerID)
	require.NoError(t, err)
	assert.False(t, isFav)

	require.NoError(t, svc.Add(userID, offerID))

	isFav, err = svc.IsFavorited(userID, offerID)
	require.NoError(t, err)
	assert.True(t, isFav)
}
