//go:build integration

package handlers_test

import (
	"net/http"
	"testing"

	"github.com/nomnom-lk/backend/internal/testutil"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestIntegration_HealthEndpoint(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/health", nil, "")

	assert.Equal(t, http.StatusOK, w.Code)
}

func TestIntegration_GetOffers_Unauthenticated(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/offers", nil, "")

	assert.Equal(t, http.StatusOK, w.Code)

	var resp map[string]interface{}
	err = testutil.ParseResponse(w, &resp)
	require.NoError(t, err)

	data, ok := resp["data"].([]interface{})
	assert.True(t, ok)
}

func TestIntegration_GetRestaurants_Public(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/restaurants", nil, "")
	assert.Equal(t, http.StatusOK, w.Code)

	var resp map[string]interface{}
	err = testutil.ParseResponse(w, &resp)
	require.NoError(t, err)
	assert.Contains(t, resp, "data")
}

func TestIntegration_AdminStats_RequiresAuth(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/admin/stats", nil, "")
	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestIntegration_AdminStats_AdminToken(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	token := testutil.GenerateAdminToken()
	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/admin/stats", nil, token)

	assert.Equal(t, http.StatusOK, w.Code)

	var resp map[string]interface{}
	err = testutil.ParseResponse(w, &resp)
	require.NoError(t, err)
	assert.Contains(t, resp, "data")
}

func TestIntegration_UserMe_RequiresAuth(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/users/me", nil, "")
	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestIntegration_UserMe_WithToken(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	token := testutil.GenerateAdminToken()
	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/users/me", nil, token)

	assert.Equal(t, http.StatusOK, w.Code)

	var resp map[string]interface{}
	err = testutil.ParseResponse(w, &resp)
	require.NoError(t, err)
	assert.Contains(t, resp, "data")
}

func TestIntegration_Login_FailsWithWrongCredentials(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	body := testutil.JSONBody(map[string]string{
		"email":    "nonexistent@test.com",
		"password": "wrongpassword",
	})
	w := testutil.PerformRequest(engine, http.MethodPost, "/api/v1/auth/login", body, "")
	assert.Equal(t, http.StatusUnauthorized, w.Code)

	var resp map[string]interface{}
	err = testutil.ParseResponse(w, &resp)
	require.NoError(t, err)
	assert.Contains(t, resp, "error")
}

func TestIntegration_Search_NoQuery(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/search", nil, "")
	assert.Equal(t, http.StatusOK, w.Code)
}

func TestIntegration_CreateOffer_RequiresAuth(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	body := testutil.JSONBody(map[string]string{"title": "test"})
	w := testutil.PerformRequest(engine, http.MethodPost, "/api/v1/offers", body, "")
	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestIntegration_CreateOffer_WithUserToken(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	token := testutil.GenerateAdminToken()
	body := testutil.JSONBody(map[string]interface{}{
		"title":            "E2E Test Offer",
		"description":      "Created during integration test",
		"original_price":   1000,
		"discounted_price": 700,
		"restaurant_id":    "00000000-0000-0000-0000-000000000000",
		"start_date":       "2026-01-01T00:00:00Z",
		"end_date":         "2027-01-01T00:00:00Z",
	})
	w := testutil.PerformRequest(engine, http.MethodPost, "/api/v1/offers", body, token)

	assert.Equal(t, http.StatusBadRequest, w.Code)

	var resp map[string]interface{}
	err = testutil.ParseResponse(w, &resp)
	require.NoError(t, err)
	assert.Contains(t, resp, "error")
}
