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

func TestIntegration_DashboardOwnerMetricsAndOfferIsolation(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)
	db := testutil.GetTestDB()
	require.NotNil(t, db)

	const (
		otherOwnerID     = "00000000-0000-0000-0000-000000000004"
		ownerRestaurant  = "00000000-0000-0000-0000-000000000101"
		otherRestaurant  = "00000000-0000-0000-0000-000000000102"
		ownerOffer       = "00000000-0000-0000-0000-000000000201"
		otherOffer       = "00000000-0000-0000-0000-000000000202"
		ownerBanner      = "00000000-0000-0000-0000-000000000301"
		otherOwnerBanner = "00000000-0000-0000-0000-000000000302"
	)

	cleanup := func() {
		db.Exec("DELETE FROM favorites WHERE offer_id IN (?::uuid, ?::uuid)", ownerOffer, otherOffer)
		db.Exec("DELETE FROM banners WHERE id IN (?::uuid, ?::uuid)", ownerBanner, otherOwnerBanner)
		db.Exec("DELETE FROM offers WHERE id IN (?::uuid, ?::uuid)", ownerOffer, otherOffer)
		db.Exec("DELETE FROM restaurants WHERE id IN (?::uuid, ?::uuid)", ownerRestaurant, otherRestaurant)
		db.Exec("DELETE FROM users WHERE id = ?::uuid", otherOwnerID)
	}
	cleanup()
	t.Cleanup(cleanup)

	require.NoError(t, db.Exec(`INSERT INTO users (id, email, name, role, is_active, created_at, updated_at)
		VALUES (?::uuid, 'other-owner@test.com', 'Other Owner', 'restaurant_owner', true, NOW(), NOW())`, otherOwnerID).Error)
	require.NoError(t, db.Exec(`INSERT INTO restaurants (id, name, slug, status, address, owner_id, created_at, updated_at)
		VALUES (?::uuid, 'Scoped Owner Restaurant', 'scoped-owner-restaurant', 'approved', 'Owner address', ?::uuid, NOW(), NOW()),
		       (?::uuid, 'Other Owner Restaurant', 'other-owner-restaurant', 'approved', 'Other address', ?::uuid, NOW(), NOW())`,
		ownerRestaurant, testutil.TestOwnerID, otherRestaurant, otherOwnerID).Error)
	require.NoError(t, db.Exec(`INSERT INTO offers (id, restaurant_id, title, original_price, offer_price, status, end_date, created_by, view_count, created_at, updated_at)
		VALUES (?::uuid, ?::uuid, 'Owner Usage Offer', 1000, 700, 'approved', NOW() + INTERVAL '5 days', ?::uuid, 12, NOW(), NOW()),
		       (?::uuid, ?::uuid, 'Other Usage Offer', 1000, 700, 'approved', NOW() + INTERVAL '5 days', ?::uuid, 99, NOW(), NOW())`,
		ownerOffer, ownerRestaurant, testutil.TestAdminID, otherOffer, otherRestaurant, otherOwnerID).Error)
	require.NoError(t, db.Exec(`INSERT INTO favorites (user_id, offer_id, created_at)
		VALUES (?::uuid, ?::uuid, NOW())`, testutil.TestUserID, ownerOffer).Error)
	require.NoError(t, db.Exec(`INSERT INTO banners (id, image, link_type, link_value, status, click_count, owner_id, created_at, updated_at)
		VALUES (?::uuid, 'owner.jpg', 'offer', ?::text, 'approved', 7, ?::uuid, NOW(), NOW()),
		       (?::uuid, 'other.jpg', 'offer', ?::text, 'approved', 100, ?::uuid, NOW(), NOW())`,
		ownerBanner, ownerOffer, testutil.TestOwnerID, otherOwnerBanner, otherOffer, otherOwnerID).Error)

	token := testutil.GenerateOwnerToken()
	statsResponse := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/dashboard/stats", nil, token)
	require.Equal(t, http.StatusOK, statsResponse.Code)
	var statsBody map[string]interface{}
	require.NoError(t, testutil.ParseResponse(statsResponse, &statsBody))
	stats := statsBody["data"].(map[string]interface{})
	assert.Equal(t, float64(1), stats["total_restaurants"])
	assert.Equal(t, float64(1), stats["total_offers"])
	assert.Equal(t, float64(12), stats["total_views"])
	assert.Equal(t, float64(1), stats["total_favorites"])
	assert.Equal(t, float64(1), stats["total_banners"])
	assert.Equal(t, float64(7), stats["total_banner_clicks"])

	ownedResponse := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/dashboard/offers/"+ownerOffer, nil, token)
	assert.Equal(t, http.StatusOK, ownedResponse.Code, "restaurant owner must manage an admin-created offer")

	otherResponse := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/dashboard/offers/"+otherOffer, nil, token)
	assert.Equal(t, http.StatusNotFound, otherResponse.Code)

	moveBody := testutil.JSONBody(map[string]string{"restaurant_id": otherRestaurant})
	moveResponse := testutil.PerformRequest(engine, http.MethodPut, "/api/v1/dashboard/offers/"+ownerOffer, moveBody, token)
	assert.Equal(t, http.StatusForbidden, moveResponse.Code)
}

func TestIntegration_OwnerBannerApprovalLifecycle(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)
	db := testutil.GetTestDB()
	require.NotNil(t, db)

	const (
		restaurantID = "00000000-0000-0000-0000-000000000111"
		offerID      = "00000000-0000-0000-0000-000000000211"
	)
	var createdBannerIDs []string
	cleanup := func() {
		if len(createdBannerIDs) > 0 {
			db.Exec("DELETE FROM banners WHERE id IN ?", createdBannerIDs)
		}
		db.Exec("DELETE FROM banners WHERE link_value = ? OR offer_id = ?::uuid", offerID, offerID)
		db.Exec("DELETE FROM offers WHERE id = ?::uuid", offerID)
		db.Exec("DELETE FROM restaurants WHERE id = ?::uuid", restaurantID)
	}
	cleanup()
	t.Cleanup(cleanup)

	require.NoError(t, db.Exec(`INSERT INTO restaurants (id, name, slug, status, address, owner_id, created_at, updated_at)
		VALUES (?::uuid, 'Banner Lifecycle Restaurant', 'banner-lifecycle-restaurant', 'approved', 'Owner address', ?::uuid, NOW(), NOW())`,
		restaurantID, testutil.TestOwnerID).Error)
	require.NoError(t, db.Exec(`INSERT INTO offers (id, restaurant_id, title, original_price, offer_price, status, start_date, end_date, created_by, created_at, updated_at)
		VALUES (?::uuid, ?::uuid, 'Banner Lifecycle Offer', 1000, 700, 'approved', NOW() - INTERVAL '1 day', NOW() + INTERVAL '5 days', ?::uuid, NOW(), NOW())`,
		offerID, restaurantID, testutil.TestAdminID).Error)

	ownerToken := testutil.GenerateOwnerToken()
	adminToken := testutil.GenerateAdminToken()
	createBody := testutil.JSONBody(map[string]interface{}{
		"offer_id": offerID,
		"image":    "https://images.unsplash.com/photo-1547592180-85f173990554?w=1024&h=360&fit=crop",
		"title":    "Owner Banner Lifecycle",
	})
	createResponse := testutil.PerformRequest(engine, http.MethodPost, "/api/v1/dashboard/banners", createBody, ownerToken)
	require.Equal(t, http.StatusCreated, createResponse.Code)
	var createResult map[string]interface{}
	require.NoError(t, testutil.ParseResponse(createResponse, &createResult))
	created := createResult["data"].(map[string]interface{})
	bannerID := created["id"].(string)
	createdBannerIDs = append(createdBannerIDs, bannerID)
	assert.Equal(t, "pending", created["status"])
	assert.Equal(t, offerID, created["offer_id"])
	assert.Equal(t, offerID, created["link_value"])
	assert.Equal(t, testutil.TestOwnerID, created["owner_id"])

	activeBefore := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/banners/active", nil, "")
	require.Equal(t, http.StatusOK, activeBefore.Code)
	assert.NotContains(t, activeBefore.Body.String(), bannerID)

	approveResponse := testutil.PerformRequest(engine, http.MethodPost, "/api/v1/admin/banners/"+bannerID+"/approve", nil, adminToken)
	require.Equal(t, http.StatusOK, approveResponse.Code)

	activeAfter := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/banners/active", nil, "")
	require.Equal(t, http.StatusOK, activeAfter.Code)
	assert.Contains(t, activeAfter.Body.String(), bannerID)

	clickResponse := testutil.PerformRequest(engine, http.MethodPost, "/api/v1/banners/"+bannerID+"/click", nil, ownerToken)
	assert.Equal(t, http.StatusNoContent, clickResponse.Code)

	adminCreateBody := testutil.JSONBody(map[string]interface{}{
		"image":      "https://images.unsplash.com/photo-1563379926898-05f4575a45d8?w=1024&h=360&fit=crop",
		"link_type":  "offer",
		"link_value": offerID,
		"offer_id":   "00000000-0000-0000-0000-000000000999",
		"title":      "Admin Promotion for Owner",
	})
	adminCreateResponse := testutil.PerformRequest(engine, http.MethodPost, "/api/v1/admin/banners", adminCreateBody, adminToken)
	require.Equal(t, http.StatusCreated, adminCreateResponse.Code)
	var adminCreateResult map[string]interface{}
	require.NoError(t, testutil.ParseResponse(adminCreateResponse, &adminCreateResult))
	adminCreated := adminCreateResult["data"].(map[string]interface{})
	createdBannerIDs = append(createdBannerIDs, adminCreated["id"].(string))
	assert.Equal(t, offerID, adminCreated["offer_id"], "offer_id must be derived from link_value")
	assert.Equal(t, testutil.TestOwnerID, adminCreated["owner_id"], "admin promotion must be attributed to the offer owner")

	statsResponse := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/dashboard/stats", nil, ownerToken)
	require.Equal(t, http.StatusOK, statsResponse.Code)
	var statsResult map[string]interface{}
	require.NoError(t, testutil.ParseResponse(statsResponse, &statsResult))
	stats := statsResult["data"].(map[string]interface{})
	assert.Equal(t, float64(2), stats["total_banners"])
	assert.Equal(t, float64(2), stats["active_banners"])
	assert.Equal(t, float64(1), stats["total_banner_clicks"])
	assert.Equal(t, float64(1), stats["active_banner_clicks"])

	missingApproval := testutil.PerformRequest(engine, http.MethodPost, "/api/v1/admin/banners/00000000-0000-0000-0000-000000000999/approve", nil, adminToken)
	assert.Equal(t, http.StatusNotFound, missingApproval.Code)
}

func TestIntegration_OfferDetail_HasSocialLinks(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	db := testutil.GetTestDB()
	require.NotNil(t, db)

	db.Exec(`INSERT INTO restaurants (id, name, slug, status, address, instagram_url, facebook_url, website_url, order_platforms, created_at, updated_at)
		VALUES (gen_random_uuid(), 'Social Test Restaurant', 'social-test', 'approved', '123 Test St', 'https://instagram.com/test', 'https://facebook.com/test', 'https://test.com', '["uber_eats","pickme"]'::jsonb, NOW(), NOW())`)

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
	platforms, _ := restaurant["order_platforms"].([]interface{})

	assert.Equal(t, "https://instagram.com/test", ig)
	assert.Equal(t, "https://facebook.com/test", fb)
	assert.Equal(t, "https://test.com", web)
	assert.Contains(t, platforms, "uber_eats")
	assert.Contains(t, platforms, "pickme")
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
