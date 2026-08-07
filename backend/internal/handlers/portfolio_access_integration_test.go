//go:build integration

package handlers_test

import (
	"bytes"
	"net/http"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/testutil"
	"github.com/stretchr/testify/require"
)

func TestIntegration_PortfolioViewerRouteMatrix(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)
	viewerToken := testutil.GenerateViewerToken()
	restaurant, offer := createPortfolioReadFixtures(t)

	allowed := []string{
		"/api/v1/auth/browser/session",
		"/api/v1/dashboard/stats",
		"/api/v1/dashboard/restaurants",
		"/api/v1/dashboard/restaurants/" + restaurant.ID.String(),
		"/api/v1/dashboard/offers",
		"/api/v1/dashboard/offers/" + offer.ID.String(),
		"/api/v1/admin/stats",
		"/api/v1/admin/stats/timeline",
		"/api/v1/admin/analytics/top-restaurants",
		"/api/v1/admin/analytics/top-offers",
		"/api/v1/admin/analytics/offer-stats",
		"/api/v1/admin/analytics/expiring-offers",
		"/api/v1/admin/categories",
		"/api/v1/admin/cuisine-tags",
		"/api/v1/admin/order-platforms",
		"/api/v1/admin/social-platforms",
		"/api/v1/admin/banners",
	}
	for _, path := range allowed {
		t.Run("allows "+path, func(t *testing.T) {
			w := testutil.PerformRequest(engine, http.MethodGet, path, nil, viewerToken)
			require.Equal(t, http.StatusOK, w.Code, w.Body.String())
		})
	}

	deniedReads := []string{
		"/api/v1/users", "/api/v1/users/me", "/api/v1/admin/owners",
		"/api/v1/admin/notifications", "/api/v1/admin/notification-templates",
		"/api/v1/admin/notification-analytics", "/api/v1/admin/audit-log",
		"/api/v1/admin/analytics/user-growth", "/api/v1/admin/analytics/device-stats",
		"/api/v1/admin/analytics/recent-activity", "/api/v1/admin/coupons",
		"/api/v1/admin/impersonate/status", "/api/v1/dashboard/banners",
		"/api/v1/notifications", "/api/v1/favorites",
	}
	for _, path := range deniedReads {
		t.Run("denies "+path, func(t *testing.T) {
			w := testutil.PerformRequest(engine, http.MethodGet, path, nil, viewerToken)
			require.Equal(t, http.StatusForbidden, w.Code, w.Body.String())
			require.Contains(t, w.Body.String(), "PORTFOLIO_DEMO_READ_ONLY")
		})
	}

	mutations := []struct {
		method string
		path   string
	}{
		{http.MethodPost, "/api/v1/dashboard/restaurants"},
		{http.MethodPut, "/api/v1/dashboard/restaurants/00000000-0000-0000-0000-000000000001"},
		{http.MethodDelete, "/api/v1/dashboard/offers/00000000-0000-0000-0000-000000000001"},
		{http.MethodPost, "/api/v1/admin/offers/bulk"},
		{http.MethodPost, "/api/v1/admin/notifications/push"},
		{http.MethodPost, "/api/v1/upload"},
		{http.MethodPost, "/api/v1/admin/impersonate"},
	}
	for _, mutation := range mutations {
		t.Run("denies "+mutation.method+" "+mutation.path, func(t *testing.T) {
			w := testutil.PerformRequest(engine, mutation.method, mutation.path, bytes.NewBufferString("{}"), viewerToken)
			require.Equal(t, http.StatusForbidden, w.Code, w.Body.String())
			require.Contains(t, w.Body.String(), "PORTFOLIO_DEMO_READ_ONLY")
		})
	}
}

func TestIntegration_DemoEndpointDisabled(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)
	w := testutil.PerformRequest(engine, http.MethodPost, "/api/v1/auth/browser/demo", nil, "")
	require.Equal(t, http.StatusNotFound, w.Code, w.Body.String())
}

func TestIntegration_PortfolioResponsesExcludePrivateFields(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)
	token := testutil.GenerateViewerToken()
	restaurant, offer := createPortfolioReadFixtures(t)
	db := testutil.GetTestDB()
	ownerID := uuid.MustParse(testutil.TestOwnerID)
	banner := &models.Banner{
		Image: "https://example.test/banner.jpg", LinkType: models.BannerLinkOffer,
		LinkValue: offer.ID.String(), OfferID: &offer.ID, OwnerID: &ownerID,
		Title: "Portfolio Banner", SponsorName: restaurant.Name, Status: models.BannerRejected,
	}
	require.NoError(t, db.Create(banner).Error)
	t.Cleanup(func() { db.Unscoped().Delete(banner) })

	tests := []struct {
		name   string
		path   string
		denied []string
	}{
		{name: "session", path: "/api/v1/auth/browser/session", denied: []string{"portfolio-viewer-integration@nomnom.test", `"id"`}},
		{name: "restaurants", path: "/api/v1/dashboard/restaurants/" + restaurant.ID.String(), denied: []string{"owner_id", "owner_email", "contact_phone", "+94 77 123 4567"}},
		{name: "offers", path: "/api/v1/dashboard/offers/" + offer.ID.String(), denied: []string{"created_by", "rejection_reason", "owner_id", "contact_phone", "internal rejection note"}},
		{name: "banners", path: "/api/v1/admin/banners", denied: []string{"owner_id", "offer_id", "link_value", "updated_at", offer.ID.String()}},
		{name: "stats", path: "/api/v1/admin/stats", denied: []string{"total_notifications", "active_coupons", "total_coupon_redemptions"}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			w := testutil.PerformRequest(engine, http.MethodGet, tt.path, nil, token)
			require.Equal(t, http.StatusOK, w.Code, w.Body.String())
			for _, field := range tt.denied {
				require.NotContains(t, w.Body.String(), field)
			}
		})
	}
}

func TestIntegration_AdminAndOwnerDashboardReadsRemainAllowed(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)
	restaurant, _ := createPortfolioReadFixtures(t)

	for _, tt := range []struct {
		name  string
		token string
	}{
		{name: "admin", token: testutil.GenerateAdminToken()},
		{name: "owner", token: testutil.GenerateOwnerToken()},
	} {
		t.Run(tt.name, func(t *testing.T) {
			w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/dashboard/restaurants/"+restaurant.ID.String(), nil, tt.token)
			require.Equal(t, http.StatusOK, w.Code, w.Body.String())
			require.Contains(t, w.Body.String(), "owner_id")
			require.Contains(t, w.Body.String(), "contact_phone")
		})
	}
}

func TestIntegration_PortfolioViewerGETsAreSideEffectFree(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)
	db := testutil.GetTestDB()
	viewerID, err := uuid.Parse(testutil.ViewerID())
	require.NoError(t, err)

	var before int64
	require.NoError(t, db.Model(&models.AuditLog{}).Where("admin_id = ?", viewerID).Count(&before).Error)
	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/dashboard/stats", nil, testutil.GenerateViewerToken())
	require.Equal(t, http.StatusOK, w.Code, w.Body.String())
	var after int64
	require.NoError(t, db.Model(&models.AuditLog{}).Where("admin_id = ?", viewerID).Count(&after).Error)
	require.Equal(t, before, after)
}

func createPortfolioReadFixtures(t *testing.T) (*models.Restaurant, *models.Offer) {
	t.Helper()
	db := testutil.GetTestDB()
	require.NotNil(t, db)
	ownerID := uuid.MustParse(testutil.TestOwnerID)
	phone := "+94 77 123 4567"
	restaurant := &models.Restaurant{
		Name: "Portfolio Restaurant " + uuid.NewString(), OwnerID: &ownerID,
		ContactPhone: &phone, Status: models.RestaurantApproved,
	}
	require.NoError(t, db.Create(restaurant).Error)
	creatorID := ownerID
	rejectionReason := "internal rejection note"
	offer := &models.Offer{
		RestaurantID: restaurant.ID, Title: "Portfolio Offer", OriginalPrice: 100,
		OfferPrice: 75, EndDate: time.Now().Add(24 * time.Hour), Status: models.OfferRejected,
		CreatedBy: &creatorID, RejectionReason: &rejectionReason,
	}
	require.NoError(t, db.Create(offer).Error)
	t.Cleanup(func() {
		db.Unscoped().Delete(offer)
		db.Unscoped().Delete(restaurant)
	})
	return restaurant, offer
}
