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
