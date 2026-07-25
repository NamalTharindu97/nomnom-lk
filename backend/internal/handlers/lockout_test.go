//go:build integration

package handlers_test

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"testing"
	"time"

	"github.com/nomnom-lk/backend/internal/testutil"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestIntegration_LoginLockout_AfterTenFailures(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	email := fmt.Sprintf("lockout-test-%d@test.com", time.Now().UnixNano())

	registerBody, _ := json.Marshal(map[string]string{
		"name":     "Lockout Test User",
		"email":    email,
		"password": "correct-password123",
	})
	w := testutil.PerformRequest(engine, http.MethodPost, "/api/v1/auth/register", bytes.NewBuffer(registerBody), "")
	require.Equal(t, http.StatusCreated, w.Code)

	db := testutil.GetTestDB()
	db.Exec("UPDATE users SET email_verified_at = NOW() WHERE email = ?", email)

	rdb := testutil.GetTestRDB()
	ctx := context.Background()

	makeBody := func() *bytes.Buffer {
		b, _ := json.Marshal(map[string]string{"email": email, "password": "wrong-password"})
		return bytes.NewBuffer(b)
	}

	for i := 1; i <= 5; i++ {
		w = testutil.PerformRequest(engine, http.MethodPost, "/api/v1/auth/login", makeBody(), "")
		assert.Equal(t, http.StatusUnauthorized, w.Code, "attempt %d/5", i)
	}

	rdb.Del(ctx, "rl:login:email:"+email)
	for i := 6; i <= 10; i++ {
		w = testutil.PerformRequest(engine, http.MethodPost, "/api/v1/auth/login", makeBody(), "")
		assert.Equal(t, http.StatusUnauthorized, w.Code, "attempt %d/10", i)
	}

	rdb.Del(ctx, "rl:login:email:"+email)
	w = testutil.PerformRequest(engine, http.MethodPost, "/api/v1/auth/login", makeBody(), "")
	assert.Equal(t, http.StatusLocked, w.Code)
}

func TestIntegration_LoginLockout_ResetOnSuccess(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	email := fmt.Sprintf("lockout-reset-%d@test.com", time.Now().UnixNano())

	registerBody, _ := json.Marshal(map[string]string{
		"name":     "Lockout Reset User",
		"email":    email,
		"password": "correct-password123",
	})
	w := testutil.PerformRequest(engine, http.MethodPost, "/api/v1/auth/register", bytes.NewBuffer(registerBody), "")
	require.Equal(t, http.StatusCreated, w.Code)

	db := testutil.GetTestDB()
	db.Exec("UPDATE users SET email_verified_at = NOW() WHERE email = ?", email)

	for i := 1; i <= 3; i++ {
		b, _ := json.Marshal(map[string]string{"email": email, "password": "wrong-password"})
		w = testutil.PerformRequest(engine, http.MethodPost, "/api/v1/auth/login", bytes.NewBuffer(b), "")
		assert.Equal(t, http.StatusUnauthorized, w.Code)
	}

	rdb := testutil.GetTestRDB()
	ctx := context.Background()
	rdb.Del(ctx, "rl:login:email:"+email)

	b, _ := json.Marshal(map[string]string{"email": email, "password": "correct-password123"})
	w = testutil.PerformRequest(engine, http.MethodPost, "/api/v1/auth/login", bytes.NewBuffer(b), "")
	assert.Equal(t, http.StatusOK, w.Code)

	b, _ = json.Marshal(map[string]string{"email": email, "password": "correct-password123"})
	w = testutil.PerformRequest(engine, http.MethodPost, "/api/v1/auth/login", bytes.NewBuffer(b), "")
	assert.Equal(t, http.StatusOK, w.Code)
}

func TestIntegration_RateLimitByEmail_LoginThrottled(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	email := fmt.Sprintf("ratelimit-email-%d@test.com", time.Now().UnixNano())

	makeBody := func() *bytes.Buffer {
		b, _ := json.Marshal(map[string]string{"email": email, "password": "doesnt-matter"})
		return bytes.NewBuffer(b)
	}

	for i := 1; i <= 5; i++ {
		w := testutil.PerformRequest(engine, http.MethodPost, "/api/v1/auth/login", makeBody(), "")
		assert.NotEqual(t, http.StatusTooManyRequests, w.Code, "attempt %d should pass", i)
	}

	w := testutil.PerformRequest(engine, http.MethodPost, "/api/v1/auth/login", makeBody(), "")
	assert.Equal(t, http.StatusTooManyRequests, w.Code)
}
