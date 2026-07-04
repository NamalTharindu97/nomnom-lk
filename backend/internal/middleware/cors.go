package middleware

import (
	"strings"

	"github.com/gin-gonic/gin"
)

func CORS(origins string) gin.HandlerFunc {
	allowedOrigins := strings.Split(origins, ",")

	return func(c *gin.Context) {
		origin := c.Request.Header.Get("Origin")
		allowed := false

		for _, allowedOrigin := range allowedOrigins {
			ao := strings.TrimSpace(allowedOrigin)
			if ao == "*" || origin == ao {
				allowed = true
				break
			}
		}

		if allowed {
			c.Header("Access-Control-Allow-Origin", origin)
			c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
			c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Authorization, Accept-Language")
			c.Header("Access-Control-Allow-Credentials", "true")
			c.Header("Access-Control-Max-Age", "86400")
		}

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}
