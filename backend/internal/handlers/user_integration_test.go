//go:build integration

package handlers_test

import (
	"fmt"
	"net/http"
	"testing"
	"time"

	"github.com/nomnom-lk/backend/internal/testutil"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestIntegration_UserList_RequiresAuth(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/users", nil, "")
	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestIntegration_UserList_AdminAllowed(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	token := testutil.GenerateAdminToken()
	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/users", nil, token)
	assert.Equal(t, http.StatusOK, w.Code)

	var resp map[string]interface{}
	err = testutil.ParseResponse(w, &resp)
	require.NoError(t, err)

	data, ok := resp["data"].([]interface{})
	assert.True(t, ok)
	assert.Greater(t, len(data), 0)
}

func TestIntegration_UserList_OwnerBlocked(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	token := testutil.GenerateOwnerToken()
	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/users", nil, token)
	assert.Equal(t, http.StatusForbidden, w.Code)
}

func TestIntegration_UserList_FilterByRole(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)
	db := testutil.GetTestDB()
	require.NotNil(t, db)

	email1 := fmt.Sprintf("testfilter-user-%d@test.com", time.Now().UnixNano())
	email2 := fmt.Sprintf("testfilter-owner-%d@test.com", time.Now().UnixNano())
	pwdHash := "$2a$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012"

	require.NoError(t, db.Exec(`INSERT INTO users (id, email, name, role, is_active, password_hash, created_at, updated_at)
		VALUES (gen_random_uuid(), ?, ?, 'user', true, ?, NOW(), NOW())`, email1, "Filter User", pwdHash).Error)
	require.NoError(t, db.Exec(`INSERT INTO users (id, email, name, role, is_active, password_hash, created_at, updated_at)
		VALUES (gen_random_uuid(), ?, ?, 'restaurant_owner', true, ?, NOW(), NOW())`, email2, "Filter Owner", pwdHash).Error)

	t.Cleanup(func() {
		db.Exec("DELETE FROM users WHERE email IN (?, ?)", email1, email2)
	})

	token := testutil.GenerateAdminToken()
	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/users?role=restaurant_owner", nil, token)
	require.Equal(t, http.StatusOK, w.Code)

	var resp map[string]interface{}
	err = testutil.ParseResponse(w, &resp)
	require.NoError(t, err)

	data, ok := resp["data"].([]interface{})
	require.True(t, ok)

	for _, item := range data {
		user := item.(map[string]interface{})
		assert.Equal(t, "restaurant_owner", user["role"])
	}
}

func TestIntegration_UserCreate_AdminAllowed(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)
	db := testutil.GetTestDB()
	require.NotNil(t, db)

	email := fmt.Sprintf("testcreate-%d@test.com", time.Now().UnixNano())
	var createdEmail string
	t.Cleanup(func() {
		if createdEmail != "" {
			db.Exec("DELETE FROM users WHERE email = ?", createdEmail)
		}
	})

	token := testutil.GenerateAdminToken()
	body := testutil.JSONBody(map[string]interface{}{
		"email":    email,
		"name":     "Created User",
		"password": "password123",
		"role":     "user",
	})
	w := testutil.PerformRequest(engine, http.MethodPost, "/api/v1/users", body, token)
	require.Equal(t, http.StatusOK, w.Code)

	var resp map[string]interface{}
	err = testutil.ParseResponse(w, &resp)
	require.NoError(t, err)
	data := resp["data"].(map[string]interface{})
	assert.Equal(t, email, data["email"])
	assert.Equal(t, "Created User", data["name"])
	assert.Equal(t, "user", data["role"])
	createdEmail = email
}

func TestIntegration_UserCreate_OwnerBlocked(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	token := testutil.GenerateOwnerToken()
	body := testutil.JSONBody(map[string]interface{}{
		"email":    fmt.Sprintf("owner-create-%d@test.com", time.Now().UnixNano()),
		"name":     "Should Not Create",
		"password": "password123",
	})
	w := testutil.PerformRequest(engine, http.MethodPost, "/api/v1/users", body, token)
	assert.Equal(t, http.StatusForbidden, w.Code)
}

func TestIntegration_UserCreate_DuplicateEmail(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)
	db := testutil.GetTestDB()
	require.NotNil(t, db)

	email := fmt.Sprintf("dup-%d@test.com", time.Now().UnixNano())
	pwdHash := "$2a$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012"

	require.NoError(t, db.Exec(`INSERT INTO users (id, email, name, role, is_active, password_hash, created_at, updated_at)
		VALUES (gen_random_uuid(), ?, 'Dup User', 'user', true, ?, NOW(), NOW())`, email, pwdHash).Error)

	t.Cleanup(func() {
		db.Exec("DELETE FROM users WHERE email = ?", email)
	})

	token := testutil.GenerateAdminToken()
	body := testutil.JSONBody(map[string]interface{}{
		"email":    email,
		"name":     "Dup Create",
		"password": "password123",
	})
	w := testutil.PerformRequest(engine, http.MethodPost, "/api/v1/users", body, token)
	assert.Equal(t, http.StatusConflict, w.Code)
}

func TestIntegration_UserMe_Success(t *testing.T) {
	engine, token, err := testutil.Setup()
	require.NoError(t, err)

	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/users/me", nil, token)
	require.Equal(t, http.StatusOK, w.Code)

	var resp map[string]interface{}
	err = testutil.ParseResponse(w, &resp)
	require.NoError(t, err)

	data := resp["data"].(map[string]interface{})
	assert.NotEmpty(t, data["id"])
	assert.NotEmpty(t, data["email"])
	assert.Equal(t, "user", data["role"])
}

func TestIntegration_UserUpdate_AdminAllowed(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)
	db := testutil.GetTestDB()
	require.NotNil(t, db)

	email := fmt.Sprintf("testupdate-%d@test.com", time.Now().UnixNano())
	var userID string

	row := db.Raw(`INSERT INTO users (id, email, name, role, is_active, password_hash, created_at, updated_at)
		VALUES (gen_random_uuid(), ?, 'Update Me', 'user', true, '$2a$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012', NOW(), NOW())
		RETURNING id`, email).Row()
	require.NoError(t, row.Scan(&userID))

	t.Cleanup(func() {
		db.Exec("DELETE FROM users WHERE id = ?::uuid", userID)
	})

	token := testutil.GenerateAdminToken()
	body := testutil.JSONBody(map[string]interface{}{
		"name": "Updated",
	})
	w := testutil.PerformRequest(engine, http.MethodPut, "/api/v1/users/"+userID, body, token)
	require.Equal(t, http.StatusOK, w.Code)

	var resp map[string]interface{}
	err = testutil.ParseResponse(w, &resp)
	require.NoError(t, err)
	data := resp["data"].(map[string]interface{})
	assert.Equal(t, "Updated", data["name"])
}

func TestIntegration_UserUpdate_OwnerBlocked(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	token := testutil.GenerateOwnerToken()
	body := testutil.JSONBody(map[string]interface{}{
		"name": "Should Not Update",
	})
	w := testutil.PerformRequest(engine, http.MethodPut, "/api/v1/users/"+testutil.TestUserID, body, token)
	assert.Equal(t, http.StatusForbidden, w.Code)
}

func TestIntegration_UserDelete_AdminAllowed(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)
	db := testutil.GetTestDB()
	require.NotNil(t, db)

	email := fmt.Sprintf("testdelete-%d@test.com", time.Now().UnixNano())
	var userID string

	row := db.Raw(`INSERT INTO users (id, email, name, role, is_active, password_hash, created_at, updated_at)
		VALUES (gen_random_uuid(), ?, 'Delete Me', 'user', true, '$2a$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012', NOW(), NOW())
		RETURNING id`, email).Row()
	require.NoError(t, row.Scan(&userID))

	t.Cleanup(func() {
		db.Exec("DELETE FROM users WHERE id = ?::uuid", userID)
	})

	token := testutil.GenerateAdminToken()
	w := testutil.PerformRequest(engine, http.MethodDelete, "/api/v1/users/"+userID, nil, token)
	assert.Equal(t, http.StatusNoContent, w.Code)
}

func TestIntegration_UserBulkActivate_AdminAllowed(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)
	db := testutil.GetTestDB()
	require.NotNil(t, db)

	email1 := fmt.Sprintf("testbulk1-%d@test.com", time.Now().UnixNano())
	email2 := fmt.Sprintf("testbulk2-%d@test.com", time.Now().UnixNano())
	pwdHash := "$2a$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012"

	var id1, id2 string
	row1 := db.Raw(`INSERT INTO users (id, email, name, role, is_active, password_hash, created_at, updated_at)
		VALUES (gen_random_uuid(), ?, 'Bulk User 1', 'user', false, ?, NOW(), NOW())
		RETURNING id`, email1, pwdHash).Row()
	require.NoError(t, row1.Scan(&id1))

	row2 := db.Raw(`INSERT INTO users (id, email, name, role, is_active, password_hash, created_at, updated_at)
		VALUES (gen_random_uuid(), ?, 'Bulk User 2', 'user', false, ?, NOW(), NOW())
		RETURNING id`, email2, pwdHash).Row()
	require.NoError(t, row2.Scan(&id2))

	t.Cleanup(func() {
		db.Exec("DELETE FROM users WHERE id IN (?::uuid, ?::uuid)", id1, id2)
	})

	token := testutil.GenerateAdminToken()
	body := testutil.JSONBody(map[string]interface{}{
		"action": "activate",
		"ids":    []string{id1, id2},
	})
	w := testutil.PerformRequest(engine, http.MethodPost, "/api/v1/admin/users/bulk", body, token)
	require.Equal(t, http.StatusOK, w.Code)

	var resp map[string]interface{}
	err = testutil.ParseResponse(w, &resp)
	require.NoError(t, err)
	data := resp["data"].(map[string]interface{})
	assert.Equal(t, float64(2), data["affected"])
}
