package middleware

import (
	"crypto/subtle"
	"net/http"

	"github.com/gin-gonic/gin"
)

const (
	BrowserCSRFCookie = "nomnom_csrf"
	BrowserCSRFHeader = "X-CSRF-Token"
)

func RequireBrowserCSRF() gin.HandlerFunc {
	return func(c *gin.Context) {
		if !validCSRF(c) {
			abortCSRF(c)
			return
		}
		c.Next()
	}
}

func validCSRF(c *gin.Context) bool {
	if c.Request.Method == http.MethodGet || c.Request.Method == http.MethodHead || c.Request.Method == http.MethodOptions {
		return true
	}
	cookieToken, err := c.Cookie(BrowserCSRFCookie)
	headerToken := c.GetHeader(BrowserCSRFHeader)
	if err != nil || cookieToken == "" || len(cookieToken) != len(headerToken) {
		return false
	}
	return subtle.ConstantTimeCompare([]byte(cookieToken), []byte(headerToken)) == 1
}

func abortCSRF(c *gin.Context) {
	c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
		"error": gin.H{
			"code":    "CSRF_VALIDATION_FAILED",
			"message": "Invalid or missing CSRF token",
		},
	})
}
