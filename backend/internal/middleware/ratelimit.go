package middleware

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
)

func RateLimit(rdb *redis.Client, limit int, window time.Duration, prefix string) gin.HandlerFunc {
	return func(c *gin.Context) {
		if rdb == nil || os.Getenv("ENVIRONMENT") == "test" {
			c.Next()
			return
		}

		key := prefix + ":" + c.ClientIP()
		ctx := context.Background()

		count, err := rdb.Incr(ctx, key).Result()
		if err != nil {
			c.Next()
			return
		}

		if count == 1 {
			rdb.Expire(ctx, key, window)
		}

		remaining := limit - int(count)
		if remaining < 0 {
			remaining = 0
		}

		c.Header("X-RateLimit-Limit", strconv.Itoa(limit))
		c.Header("X-RateLimit-Remaining", strconv.Itoa(remaining))
		c.Header("X-RateLimit-Reset", strconv.FormatInt(time.Now().Add(window).Unix(), 10))

		if count > int64(limit) {
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"error": gin.H{
					"code":    "RATE_LIMITED",
					"message": "Too many requests, please try again later",
				},
			})
			return
		}

		c.Next()
	}
}

// RateLimitStrict fails closed when its shared counter is unavailable.
func RateLimitStrict(rdb *redis.Client, limit int, window time.Duration, prefix string) gin.HandlerFunc {
	return func(c *gin.Context) {
		if rdb == nil {
			c.AbortWithStatusJSON(http.StatusServiceUnavailable, gin.H{"error": gin.H{"code": "SERVICE_UNAVAILABLE", "message": "Service temporarily unavailable"}})
			return
		}
		key := prefix + ":" + c.ClientIP()
		count, err := rdb.Incr(c.Request.Context(), key).Result()
		if err != nil {
			c.AbortWithStatusJSON(http.StatusServiceUnavailable, gin.H{"error": gin.H{"code": "SERVICE_UNAVAILABLE", "message": "Service temporarily unavailable"}})
			return
		}
		if count == 1 {
			if err := rdb.Expire(c.Request.Context(), key, window).Err(); err != nil {
				c.AbortWithStatusJSON(http.StatusServiceUnavailable, gin.H{"error": gin.H{"code": "SERVICE_UNAVAILABLE", "message": "Service temporarily unavailable"}})
				return
			}
		}
		c.Header("X-RateLimit-Limit", strconv.Itoa(limit))
		remaining := limit - int(count)
		if remaining < 0 {
			remaining = 0
		}
		c.Header("X-RateLimit-Remaining", strconv.Itoa(remaining))
		if count > int64(limit) {
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{"error": gin.H{"code": "RATE_LIMITED", "message": "Too many requests, please try again later"}})
			return
		}
		c.Next()
	}
}

func RateLimitByEmail(rdb *redis.Client, limit int, window time.Duration, prefix string) gin.HandlerFunc {
	return func(c *gin.Context) {
		if rdb == nil || os.Getenv("ENVIRONMENT") == "test" {
			c.Next()
			return
		}

		data, err := io.ReadAll(c.Request.Body)
		if err != nil {
			c.Next()
			return
		}
		c.Request.Body = io.NopCloser(bytes.NewBuffer(data))

		var body struct {
			Email string `json:"email"`
		}
		_ = json.Unmarshal(data, &body)
		if body.Email == "" {
			c.Next()
			return
		}

		key := prefix + ":" + body.Email
		ctx := context.Background()

		count, err := rdb.Incr(ctx, key).Result()
		if err != nil {
			c.Next()
			return
		}

		if count == 1 {
			rdb.Expire(ctx, key, window)
		}

		if count > int64(limit) {
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"error": gin.H{
					"code":    "RATE_LIMITED",
					"message": "Too many login attempts, please try again later",
				},
			})
			return
		}

		c.Next()
	}
}
