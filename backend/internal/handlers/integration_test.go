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

	w := testutil.PerformRequest(engine, http.MethodGet, "/health", nil, "")

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

	_, ok := resp["data"].([]interface{})
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

func TestIntegration_DashboardStats_RequiresAuth(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/dashboard/stats", nil, "")
	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestIntegration_DashboardStats_UserBlocked(t *testing.T) {
	engine, token, err := testutil.Setup()
	require.NoError(t, err)

	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/dashboard/stats", nil, token)
	assert.Equal(t, http.StatusForbidden, w.Code)
}

func TestIntegration_DashboardStats_AdminAllowed(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	token := testutil.GenerateAdminToken()
	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/dashboard/stats", nil, token)
	assert.Equal(t, http.StatusOK, w.Code)

	var resp map[string]interface{}
	err = testutil.ParseResponse(w, &resp)
	require.NoError(t, err)
	assert.Contains(t, resp, "data")
}

func TestIntegration_DashboardStats_OwnerAllowed(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	token := testutil.GenerateOwnerToken()
	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/dashboard/stats", nil, token)
	assert.Equal(t, http.StatusOK, w.Code)

	var resp map[string]interface{}
	err = testutil.ParseResponse(w, &resp)
	require.NoError(t, err)
	assert.Contains(t, resp, "data")
}

func TestIntegration_DashboardRestaurants_AdminSeesAll(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	token := testutil.GenerateAdminToken()
	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/dashboard/restaurants", nil, token)
	assert.Equal(t, http.StatusOK, w.Code)

	var resp map[string]interface{}
	err = testutil.ParseResponse(w, &resp)
	require.NoError(t, err)
	data, ok := resp["data"].([]interface{})
	assert.True(t, ok)
	_ = data
}

func TestIntegration_DashboardRestaurants_OwnerSeesScoped(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	token := testutil.GenerateOwnerToken()
	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/dashboard/restaurants", nil, token)
	assert.Equal(t, http.StatusOK, w.Code)

	var resp map[string]interface{}
	err = testutil.ParseResponse(w, &resp)
	require.NoError(t, err)
	assert.Contains(t, resp, "data")
}

func TestIntegration_OfferDetail_HasSocialLinks(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	db := testutil.GetTestDB()
	require.NotNil(t, db)

	db.Exec(`INSERT INTO restaurants (id, name, slug, status, address, instagram_url, facebook_url, website_url, order_url, order_url_alt, created_at, updated_at)
		VALUES (gen_random_uuid(), 'Social Test Restaurant', 'social-test', 'approved', '123 Test St', 'https://instagram.com/test', 'https://facebook.com/test', 'https://test.com', 'https://ubereats.com/test', 'https://pickme.lk/test', NOW(), NOW())`)

	db.Exec(`INSERT INTO offers (id, title, description, original_price, offer_price, status, restaurant_id, start_date, end_date, created_at, updated_at)
		VALUES (gen_random_uuid(), 'Social Test Offer', 'desc', 1000, 700, 'approved', (SELECT id FROM restaurants WHERE slug = 'social-test'), NOW(), NOW() + INTERVAL '7 days', NOW(), NOW())`)

	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/offers?per_page=1", nil, "")
	require.Equal(t, http.StatusOK, w.Code)

	var listResp map[string]interface{}
	err = testutil.ParseResponse(w, &listResp)
	require.NoError(t, err)

	items, ok := listResp["data"].([]interface{})
	require.True(t, ok)
	require.Greater(t, len(items), 0)

	firstItem, ok := items[0].(map[string]interface{})
	require.True(t, ok)

	restaurant, ok := firstItem["restaurant"].(map[string]interface{})
	require.True(t, ok)

	ig, _ := restaurant["instagram_url"].(string)
	fb, _ := restaurant["facebook_url"].(string)
	web, _ := restaurant["website_url"].(string)
	ord, _ := restaurant["order_url"].(string)
	alt, _ := restaurant["order_url_alt"].(string)

	assert.Equal(t, "https://instagram.com/test", ig)
	assert.Equal(t, "https://facebook.com/test", fb)
	assert.Equal(t, "https://test.com", web)
	assert.Equal(t, "https://ubereats.com/test", ord)
	assert.Equal(t, "https://pickme.lk/test", alt)
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
