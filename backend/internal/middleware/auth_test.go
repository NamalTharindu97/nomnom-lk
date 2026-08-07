package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	appjwt "github.com/nomnom-lk/backend/pkg/jwt"
	"github.com/stretchr/testify/require"
)

const authTestSecret = "test-secret-key-for-browser-auth-tests"

func TestAuthPreservesBearerAndAcceptsBrowserCookie(t *testing.T) {
	token, err := appjwt.GenerateAccessToken(authTestSecret, uuid.New(), "admin@example.test", "Admin", "admin", "15m")
	require.NoError(t, err)

	tests := []struct {
		name       string
		method     string
		bearer     string
		cookie     string
		csrfCookie string
		csrfHeader string
		wantStatus int
		wantCookie bool
	}{
		{name: "bearer mutation", method: http.MethodPost, bearer: token, wantStatus: http.StatusOK},
		{name: "cookie safe request", method: http.MethodGet, cookie: token, wantStatus: http.StatusOK, wantCookie: true},
		{name: "cookie mutation with csrf", method: http.MethodPost, cookie: token, csrfCookie: "proof", csrfHeader: "proof", wantStatus: http.StatusOK, wantCookie: true},
		{name: "cookie mutation without csrf", method: http.MethodPost, cookie: token, wantStatus: http.StatusForbidden},
		{name: "bearer takes precedence", method: http.MethodPost, bearer: token, cookie: "invalid", wantStatus: http.StatusOK},
		{name: "missing authentication", method: http.MethodGet, wantStatus: http.StatusUnauthorized},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			gin.SetMode(gin.TestMode)
			router := gin.New()
			router.Use(Auth(authTestSecret))
			router.Handle(tt.method, "/test", func(c *gin.Context) {
				require.Equal(t, tt.wantCookie, IsCookieAuth(c))
				role, exists := GetUserRole(c)
				require.True(t, exists)
				require.Equal(t, "admin", role)
				c.Status(http.StatusOK)
			})

			recorder := httptest.NewRecorder()
			request := httptest.NewRequest(tt.method, "/test", nil)
			if tt.bearer != "" {
				request.Header.Set("Authorization", "Bearer "+tt.bearer)
			}
			if tt.cookie != "" {
				request.AddCookie(&http.Cookie{Name: BrowserAccessCookie, Value: tt.cookie})
			}
			if tt.csrfCookie != "" {
				request.AddCookie(&http.Cookie{Name: BrowserCSRFCookie, Value: tt.csrfCookie})
			}
			if tt.csrfHeader != "" {
				request.Header.Set(BrowserCSRFHeader, tt.csrfHeader)
			}

			router.ServeHTTP(recorder, request)
			require.Equal(t, tt.wantStatus, recorder.Code)
		})
	}
}

func TestAuthEnforcesPortfolioViewerReadOnlyAccess(t *testing.T) {
	viewerToken, err := appjwt.GenerateAccessToken(authTestSecret, uuid.New(), "viewer@example.test", "Recruiter Demo", "portfolio_viewer", "15m")
	require.NoError(t, err)
	adminToken, err := appjwt.GenerateAccessToken(authTestSecret, uuid.New(), "admin@example.test", "Admin", "admin", "15m")
	require.NoError(t, err)

	tests := []struct {
		name        string
		method      string
		path        string
		token       string
		wantStatus  int
		wantCode    string
		wantHandled bool
	}{
		{name: "viewer safe get", method: http.MethodGet, path: "/api/v1/dashboard/restaurants", token: viewerToken, wantStatus: http.StatusOK, wantHandled: true},
		{name: "viewer head is not allowlisted", method: http.MethodHead, path: "/api/v1/admin/stats", token: viewerToken, wantStatus: http.StatusForbidden, wantCode: "PORTFOLIO_DEMO_READ_ONLY"},
		{name: "viewer sensitive get", method: http.MethodGet, path: "/api/v1/users/me", token: viewerToken, wantStatus: http.StatusForbidden, wantCode: "PORTFOLIO_DEMO_READ_ONLY"},
		{name: "viewer options", method: http.MethodOptions, path: "/test", token: viewerToken, wantStatus: http.StatusOK, wantHandled: true},
		{name: "viewer post", method: http.MethodPost, path: "/test", token: viewerToken, wantStatus: http.StatusForbidden, wantCode: "PORTFOLIO_DEMO_READ_ONLY"},
		{name: "viewer put", method: http.MethodPut, path: "/test", token: viewerToken, wantStatus: http.StatusForbidden, wantCode: "PORTFOLIO_DEMO_READ_ONLY"},
		{name: "viewer patch", method: http.MethodPatch, path: "/test", token: viewerToken, wantStatus: http.StatusForbidden, wantCode: "PORTFOLIO_DEMO_READ_ONLY"},
		{name: "viewer delete", method: http.MethodDelete, path: "/test", token: viewerToken, wantStatus: http.StatusForbidden, wantCode: "PORTFOLIO_DEMO_READ_ONLY"},
		{name: "viewer logout", method: http.MethodPost, path: "/api/v1/auth/logout", token: viewerToken, wantStatus: http.StatusOK, wantHandled: true},
		{name: "admin post unchanged", method: http.MethodPost, path: "/test", token: adminToken, wantStatus: http.StatusOK, wantHandled: true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			gin.SetMode(gin.TestMode)
			handled := false
			router := gin.New()
			router.Use(Auth(authTestSecret))
			router.Handle(tt.method, tt.path, func(c *gin.Context) {
				handled = true
				c.Status(http.StatusOK)
			})

			recorder := httptest.NewRecorder()
			request := httptest.NewRequest(tt.method, tt.path, nil)
			request.Header.Set("Authorization", "Bearer "+tt.token)
			router.ServeHTTP(recorder, request)

			require.Equal(t, tt.wantStatus, recorder.Code)
			require.Equal(t, tt.wantHandled, handled)
			if tt.wantCode != "" {
				require.Contains(t, recorder.Body.String(), `"code":"`+tt.wantCode+`"`)
			}
		})
	}
}

func TestPortfolioViewerReadAllowlist(t *testing.T) {
	allowed := []string{
		"/api/v1/auth/browser/session",
		"/api/v1/dashboard/stats",
		"/api/v1/dashboard/restaurants",
		"/api/v1/dashboard/restaurants/00000000-0000-0000-0000-000000000001",
		"/api/v1/dashboard/offers",
		"/api/v1/dashboard/offers/00000000-0000-0000-0000-000000000001",
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
		t.Run("allowed "+path, func(t *testing.T) {
			require.True(t, viewerReadAllowed(path))
		})
	}

	denied := []string{
		"/api/v1/users", "/api/v1/users/me", "/api/v1/admin/owners",
		"/api/v1/admin/notifications", "/api/v1/admin/notification-templates",
		"/api/v1/admin/notification-analytics", "/api/v1/admin/audit-log",
		"/api/v1/admin/analytics/user-growth", "/api/v1/admin/analytics/device-stats",
		"/api/v1/admin/analytics/recent-activity", "/api/v1/admin/coupons",
		"/api/v1/admin/impersonate/status", "/api/v1/dashboard/banners",
		"/api/v1/notifications", "/api/v1/devices", "/api/v1/favorites",
	}
	for _, path := range denied {
		t.Run("denied "+path, func(t *testing.T) {
			require.False(t, viewerReadAllowed(path))
		})
	}
}

func TestRequireBrowserCSRF(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.Use(RequireBrowserCSRF())
	router.POST("/test", func(c *gin.Context) { c.Status(http.StatusNoContent) })

	for _, tt := range []struct {
		name       string
		cookie     string
		header     string
		wantStatus int
	}{
		{name: "matching", cookie: "proof", header: "proof", wantStatus: http.StatusNoContent},
		{name: "missing", wantStatus: http.StatusForbidden},
		{name: "mismatch", cookie: "proof", header: "other", wantStatus: http.StatusForbidden},
	} {
		t.Run(tt.name, func(t *testing.T) {
			recorder := httptest.NewRecorder()
			request := httptest.NewRequest(http.MethodPost, "/test", nil)
			if tt.cookie != "" {
				request.AddCookie(&http.Cookie{Name: BrowserCSRFCookie, Value: tt.cookie})
			}
			request.Header.Set(BrowserCSRFHeader, tt.header)
			router.ServeHTTP(recorder, request)
			require.Equal(t, tt.wantStatus, recorder.Code)
		})
	}
}
