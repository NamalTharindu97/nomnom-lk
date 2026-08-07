package handlers

import (
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/config"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/stretchr/testify/require"
)

func TestDashboardRestaurantPortfolioSanitization(t *testing.T) {
	ownerID := uuid.New()
	phone := "+94 77 123 4567"
	restaurant := &models.Restaurant{
		ID: uuid.New(), OwnerID: &ownerID, Name: "Safe Restaurant", Slug: "safe-restaurant",
		ContactPhone: &phone, SocialLinks: models.SocialLinks{{Platform: "instagram", URL: "https://example.test"}},
	}
	context, _ := gin.CreateTestContext(httptest.NewRecorder())

	viewer := dashboardRestaurantDetailToMap(restaurant, context, true)
	require.NotContains(t, viewer, "owner_id")
	require.NotContains(t, viewer, "contact_phone")
	require.Contains(t, viewer, "social_links")

	admin := dashboardRestaurantDetailToMap(restaurant, context, false)
	require.Equal(t, &ownerID, admin["owner_id"])
	require.Equal(t, &phone, admin["contact_phone"])
}

func TestDashboardOfferPortfolioResponseExcludesPrivateFields(t *testing.T) {
	creatorID := uuid.New()
	reason := "internal rejection note"
	offer := &models.Offer{
		ID: uuid.New(), RestaurantID: uuid.New(), Title: "Safe Offer", OriginalPrice: 100,
		OfferPrice: 75, EndDate: time.Now().Add(time.Hour), CreatedBy: &creatorID,
		RejectionReason: &reason, Restaurant: &models.Restaurant{Name: "Restaurant"},
	}
	context, _ := gin.CreateTestContext(httptest.NewRecorder())

	viewer := dashboardOfferToMap(offer, context, true)
	require.NotContains(t, viewer, "created_by")
	require.NotContains(t, viewer, "rejection_reason")
	require.NotContains(t, viewer, "owner_id")
	require.NotContains(t, viewer, "contact_phone")

	admin := dashboardOfferToMap(offer, context, false)
	require.Equal(t, viewer["title"], admin["title"])
}

func TestViewerBrowserSessionOmitsEmailAndAccountID(t *testing.T) {
	gin.SetMode(gin.TestMode)
	handler := &AuthHandler{}
	router := gin.New()
	router.GET("/session", func(c *gin.Context) {
		c.Set("user_id", uuid.New().String())
		c.Set("user_email", "recruiter-demo@example.test")
		c.Set("user_name", "Recruiter Demo")
		c.Set("user_role", "portfolio_viewer")
		handler.BrowserSession(c)
	})
	recorder := httptest.NewRecorder()
	router.ServeHTTP(recorder, httptest.NewRequest("GET", "/session", nil))

	require.Equal(t, 200, recorder.Code)
	require.NotContains(t, recorder.Body.String(), "recruiter-demo@example.test")
	require.NotContains(t, recorder.Body.String(), `"id"`)
	require.Contains(t, recorder.Body.String(), `"read_only":true`)
}

func TestBrowserDemoDisabledReturnsNotFound(t *testing.T) {
	handler := &AuthHandler{demoViewer: &config.DemoViewerConfig{Enabled: false}}
	recorder := httptest.NewRecorder()
	context, _ := gin.CreateTestContext(recorder)
	handler.BrowserDemo(context)
	require.Equal(t, 404, recorder.Code)
}
