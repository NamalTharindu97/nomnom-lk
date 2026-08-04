package middleware

import (
	"net/http"
	"runtime/debug"

	"github.com/getsentry/sentry-go"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
)

func Recovery(log zerolog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				requestID := GetRequestID(c)
				path := c.FullPath()
				if path == "" {
					path = "[unmatched route]"
				}
				log.Error().
					Str("request_id", requestID).
					Str("method", c.Request.Method).
					Str("path", path).
					Interface("panic", err).
					Str("stack", string(debug.Stack())).
					Msg("panic recovered")

				hub := sentry.CurrentHub().Clone()
				hub.Scope().SetTag("request_id", requestID)
				hub.Scope().SetContext("request", sentry.Context{
					"method": c.Request.Method,
					"path":   path,
				})
				hub.RecoverWithContext(c.Request.Context(), err)

				c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
					"error": gin.H{
						"code":    "INTERNAL_ERROR",
						"message": "An unexpected error occurred",
					},
					"request_id": requestID,
				})
			}
		}()
		c.Next()
	}
}
