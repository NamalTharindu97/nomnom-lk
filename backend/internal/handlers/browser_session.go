package handlers

import (
	"crypto/rand"
	"encoding/base64"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/nomnom-lk/backend/internal/config"
	"github.com/nomnom-lk/backend/internal/middleware"
)

const browserRefreshCookie = "nomnom_refresh"

type browserSession struct {
	secure        bool
	accessExpiry  time.Duration
	refreshExpiry time.Duration
}

func newBrowserSession(browserCfg *config.BrowserSessionConfig, jwtCfg *config.JWTConfig) *browserSession {
	accessExpiry, err := time.ParseDuration(jwtCfg.AccessExpiry)
	if err != nil {
		accessExpiry = 15 * time.Minute
	}
	refreshExpiry, err := time.ParseDuration(jwtCfg.RefreshExpiry)
	if err != nil {
		refreshExpiry = 30 * 24 * time.Hour
	}
	return &browserSession{
		secure:        browserCfg.CookieSecure,
		accessExpiry:  accessExpiry,
		refreshExpiry: refreshExpiry,
	}
}

func (s *browserSession) set(c *gin.Context, accessToken, refreshToken string) error {
	csrfToken, err := newCSRFToken()
	if err != nil {
		return err
	}
	s.setAccess(c, accessToken)
	s.setCookie(c, browserRefreshCookie, refreshToken, "/api/v1/auth/browser", s.refreshExpiry, true)
	s.setCookie(c, middleware.BrowserCSRFCookie, csrfToken, "/", s.refreshExpiry, false)
	return nil
}

func (s *browserSession) setAccess(c *gin.Context, accessToken string) {
	s.setCookie(c, middleware.BrowserAccessCookie, accessToken, "/", s.accessExpiry, true)
}

func (s *browserSession) clear(c *gin.Context) {
	s.clearCookie(c, middleware.BrowserAccessCookie, "/", true)
	s.clearCookie(c, browserRefreshCookie, "/api/v1/auth/browser", true)
	s.clearCookie(c, middleware.BrowserCSRFCookie, "/", false)
}

func (s *browserSession) setCookie(c *gin.Context, name, value, path string, expiry time.Duration, httpOnly bool) {
	http.SetCookie(c.Writer, &http.Cookie{
		Name:     name,
		Value:    value,
		Path:     path,
		Expires:  time.Now().Add(expiry),
		MaxAge:   int(expiry.Seconds()),
		HttpOnly: httpOnly,
		Secure:   s.secure,
		SameSite: http.SameSiteLaxMode,
	})
}

func (s *browserSession) clearCookie(c *gin.Context, name, path string, httpOnly bool) {
	http.SetCookie(c.Writer, &http.Cookie{
		Name:     name,
		Path:     path,
		Expires:  time.Unix(1, 0),
		MaxAge:   -1,
		HttpOnly: httpOnly,
		Secure:   s.secure,
		SameSite: http.SameSiteLaxMode,
	})
}

func newCSRFToken() (string, error) {
	buffer := make([]byte, 32)
	if _, err := rand.Read(buffer); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(buffer), nil
}
