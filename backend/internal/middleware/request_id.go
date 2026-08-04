package middleware

import (
	"regexp"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

var validRequestID = regexp.MustCompile(`^[A-Za-z0-9._:-]{1,128}$`)

func RequestID() gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := strings.TrimSpace(c.GetHeader("X-Request-ID"))
		if !validRequestID.MatchString(requestID) {
			requestID = uuid.New().String()
		}
		c.Set("request_id", requestID)
		c.Header("X-Request-ID", requestID)
		c.Next()
	}
}

func GetRequestID(c *gin.Context) string {
	id, exists := c.Get("request_id")
	if !exists {
		return ""
	}
	return id.(string)
}
