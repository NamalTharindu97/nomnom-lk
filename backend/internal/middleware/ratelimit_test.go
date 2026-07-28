package middleware

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestRateLimit_NilRedis_PassThrough(t *testing.T) {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	r.Use(RateLimit(nil, 5, 1*time.Minute, "rl:test"))
	r.GET("/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.NotContains(t, w.Header(), "X-RateLimit-Limit")
}

func TestRateLimit_TestEnvironment_PassThrough(t *testing.T) {
	t.Setenv("ENVIRONMENT", "test")
	gin.SetMode(gin.TestMode)

	rdb := redis.NewClient(&redis.Options{Addr: "127.0.0.1:1"})
	r := gin.New()
	r.Use(RateLimit(rdb, 0, time.Minute, "rl:test"))
	r.GET("/test", func(c *gin.Context) {
		c.Status(http.StatusOK)
	})

	w := httptest.NewRecorder()
	r.ServeHTTP(w, httptest.NewRequest(http.MethodGet, "/test", nil))

	assert.Equal(t, http.StatusOK, w.Code)
	assert.NotContains(t, w.Header(), "X-RateLimit-Limit")
}

func TestRateLimit_EnforcesLimit(t *testing.T) {
	gin.SetMode(gin.TestMode)

	rdb := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
	ctx := context.Background()
	if err := rdb.Ping(ctx).Err(); err != nil {
		t.Skip("Redis not available, skipping rate limit test")
	}
	defer func() {
		keys, _ := rdb.Keys(ctx, "rl:test:*").Result()
		for _, k := range keys {
			rdb.Del(ctx, k)
		}
	}()

	limit := 2
	r := gin.New()
	r.Use(RateLimit(rdb, limit, 1*time.Minute, "rl:test"))
	r.POST("/login", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	for i := 1; i <= limit; i++ {
		w := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodPost, "/login", nil)
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusOK, w.Code, "request %d should be allowed", i)
	}

	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/login", nil)
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusTooManyRequests, w.Code)
}

func TestRateLimitByEmail_NilRedis_PassThrough(t *testing.T) {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	r.Use(RateLimitByEmail(nil, 5, 15*time.Minute, "rl:login:email"))
	r.POST("/login", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	body, _ := json.Marshal(map[string]string{"email": "test@example.com"})
	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/login", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
}

func TestRateLimitByEmail_NoEmail_PassThrough(t *testing.T) {
	gin.SetMode(gin.TestMode)

	rdb := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
	ctx := context.Background()
	if err := rdb.Ping(ctx).Err(); err != nil {
		t.Skip("Redis not available")
	}

	r := gin.New()
	r.Use(RateLimitByEmail(rdb, 5, 15*time.Minute, "rl:login:email"))
	r.POST("/login", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	body, _ := json.Marshal(map[string]string{"password": "secret"})
	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/login", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
}

func TestRateLimitByEmail_EnforcesLimit(t *testing.T) {
	gin.SetMode(gin.TestMode)

	rdb := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
	ctx := context.Background()
	if err := rdb.Ping(ctx).Err(); err != nil {
		t.Skip("Redis not available, skipping rate limit test")
	}
	defer func() {
		keys, _ := rdb.Keys(ctx, "rl:test:email:*").Result()
		for _, k := range keys {
			rdb.Del(ctx, k)
		}
	}()

	limit := 3
	r := gin.New()
	r.Use(RateLimitByEmail(rdb, limit, 15*time.Minute, "rl:test:email"))
	r.POST("/login", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	email := "ratelimit-test@example.com"

	for i := 1; i <= limit; i++ {
		body, _ := json.Marshal(map[string]string{"email": email})
		w := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodPost, "/login", bytes.NewBuffer(body))
		req.Header.Set("Content-Type", "application/json")
		r.ServeHTTP(w, req)
		require.Equal(t, http.StatusOK, w.Code, "request %d should be allowed", i)
	}

	body, _ := json.Marshal(map[string]string{"email": email})
	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/login", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusTooManyRequests, w.Code)
}

func TestRateLimitByEmail_DifferentEmailsIndependent(t *testing.T) {
	gin.SetMode(gin.TestMode)

	rdb := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
	ctx := context.Background()
	if err := rdb.Ping(ctx).Err(); err != nil {
		t.Skip("Redis not available")
	}
	defer func() {
		keys, _ := rdb.Keys(ctx, "rl:test:email:*").Result()
		for _, k := range keys {
			rdb.Del(ctx, k)
		}
	}()

	limit := 1
	r := gin.New()
	r.Use(RateLimitByEmail(rdb, limit, 15*time.Minute, "rl:test:email"))
	r.POST("/login", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	body1, _ := json.Marshal(map[string]string{"email": "user1@test.com"})
	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/login", bytes.NewBuffer(body1))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)

	body2, _ := json.Marshal(map[string]string{"email": "user2@test.com"})
	w = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodPost, "/login", bytes.NewBuffer(body2))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)
}
