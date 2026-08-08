package handlers

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/nomnom-lk/backend/internal/config"
	"github.com/nomnom-lk/backend/internal/middleware"
	"github.com/stretchr/testify/require"
)

func TestBrowserSessionCookies(t *testing.T) {
	gin.SetMode(gin.TestMode)
	session := newBrowserSession(
		&config.BrowserSessionConfig{CookieSecure: true},
		&config.JWTConfig{AccessExpiry: "15m", RefreshExpiry: "720h"},
	)
	recorder := httptest.NewRecorder()
	context, _ := gin.CreateTestContext(recorder)

	require.NoError(t, session.set(context, "access-token", "refresh-token"))
	cookies := recorder.Result().Cookies()
	require.Len(t, cookies, 3)

	byName := make(map[string]*http.Cookie, len(cookies))
	for _, cookie := range cookies {
		byName[cookie.Name] = cookie
		require.True(t, cookie.Secure)
		require.Equal(t, http.SameSiteLaxMode, cookie.SameSite)
	}
	require.True(t, byName[middleware.BrowserAccessCookie].HttpOnly)
	require.Equal(t, "/", byName[middleware.BrowserAccessCookie].Path)
	require.True(t, byName[browserRefreshCookie].HttpOnly)
	require.Equal(t, "/api/v1/auth/browser", byName[browserRefreshCookie].Path)
	require.False(t, byName[middleware.BrowserCSRFCookie].HttpOnly)
	require.NotEmpty(t, byName[middleware.BrowserCSRFCookie].Value)
}

func TestBrowserSessionClearMatchesCookieScope(t *testing.T) {
	session := newBrowserSession(
		&config.BrowserSessionConfig{CookieSecure: true},
		&config.JWTConfig{AccessExpiry: "15m", RefreshExpiry: "720h"},
	)
	recorder := httptest.NewRecorder()
	context, _ := gin.CreateTestContext(recorder)

	session.clear(context)
	cookies := recorder.Result().Cookies()
	require.Len(t, cookies, 3)
	for _, cookie := range cookies {
		require.Equal(t, -1, cookie.MaxAge)
		require.True(t, cookie.Secure)
	}
}
