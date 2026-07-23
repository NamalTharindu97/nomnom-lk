package middleware

import (
	"net/url"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
)

func Logger(log zerolog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		query := sanitizeQuery(c.Request.URL.RawQuery)

		c.Next()

		latency := time.Since(start)
		status := c.Writer.Status()
		requestID := GetRequestID(c)

		logger := log.Info()
		if status >= 500 {
			logger = log.Error()
		} else if status >= 400 {
			logger = log.Warn()
		}

		logger.
			Str("request_id", requestID).
			Str("method", c.Request.Method).
			Str("path", path).
			Str("query", query).
			Int("status", status).
			Dur("latency", latency).
			Str("ip", c.ClientIP()).
			Msg("request")
	}
}

func sanitizeQuery(rawQuery string) string {
	if rawQuery == "" {
		return ""
	}
	values, err := url.ParseQuery(rawQuery)
	if err != nil {
		return "[invalid query omitted]"
	}
	for key := range values {
		if isSensitiveQueryKey(key) {
			values[key] = []string{"[REDACTED]"}
		}
	}
	return values.Encode()
}

func isSensitiveQueryKey(key string) bool {
	key = strings.ToLower(strings.TrimSpace(key))
	if key == "key" || key == "code" {
		return true
	}
	for _, fragment := range []string{
		"token", "password", "secret", "authorization", "cookie", "verification", "reset",
	} {
		if strings.Contains(key, fragment) {
			return true
		}
	}
	return strings.HasSuffix(key, "_key")
}
