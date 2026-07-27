//go:build integration

package handlers_test

import (
	"net/http"
	"testing"

	"github.com/nomnom-lk/backend/internal/testutil"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestIntegration_Notification_List_RequiresAuth(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/notifications", nil, "")
	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestIntegration_Notification_List_Success(t *testing.T) {
	engine, token, err := testutil.Setup()
	require.NoError(t, err)
	db := testutil.GetTestDB()
	require.NotNil(t, db)

	db.Exec(`DELETE FROM notifications WHERE user_id = ?::uuid`, testutil.TestUserID)
	t.Cleanup(func() {
		db.Exec(`DELETE FROM notifications WHERE user_id = ?::uuid`, testutil.TestUserID)
	})

	require.NoError(t, db.Exec(`INSERT INTO notifications (id, user_id, type, title, is_read, created_at)
		VALUES (gen_random_uuid(), ?::uuid, 'admin', 'Notif One', false, NOW())`, testutil.TestUserID).Error)
	require.NoError(t, db.Exec(`INSERT INTO notifications (id, user_id, type, title, is_read, created_at)
		VALUES (gen_random_uuid(), ?::uuid, 'admin', 'Notif Two', true, NOW())`, testutil.TestUserID).Error)

	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/notifications", nil, token)
	require.Equal(t, http.StatusOK, w.Code)

	var resp map[string]interface{}
	err = testutil.ParseResponse(w, &resp)
	require.NoError(t, err)
	data, ok := resp["data"].([]interface{})
	assert.True(t, ok)
	assert.GreaterOrEqual(t, len(data), 2)
}

func TestIntegration_Notification_UnreadCount_Success(t *testing.T) {
	engine, token, err := testutil.Setup()
	require.NoError(t, err)
	db := testutil.GetTestDB()
	require.NotNil(t, db)

	db.Exec(`DELETE FROM notifications WHERE user_id = ?::uuid`, testutil.TestUserID)
	t.Cleanup(func() {
		db.Exec(`DELETE FROM notifications WHERE user_id = ?::uuid`, testutil.TestUserID)
	})

	for i := 0; i < 3; i++ {
		require.NoError(t, db.Exec(`INSERT INTO notifications (id, user_id, type, title, is_read, created_at)
			VALUES (gen_random_uuid(), ?::uuid, 'admin', 'Unread Notif', false, NOW())`, testutil.TestUserID).Error)
	}
	require.NoError(t, db.Exec(`INSERT INTO notifications (id, user_id, type, title, is_read, created_at)
		VALUES (gen_random_uuid(), ?::uuid, 'admin', 'Read Notif', true, NOW())`, testutil.TestUserID).Error)

	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/notifications/unread-count", nil, token)
	require.Equal(t, http.StatusOK, w.Code)

	var resp map[string]interface{}
	err = testutil.ParseResponse(w, &resp)
	require.NoError(t, err)
	data, ok := resp["data"].(map[string]interface{})
	require.True(t, ok)
	assert.Equal(t, float64(3), data["unread_count"])
}

func TestIntegration_Notification_MarkAsRead_Success(t *testing.T) {
	engine, token, err := testutil.Setup()
	require.NoError(t, err)
	db := testutil.GetTestDB()
	require.NotNil(t, db)

	db.Exec(`DELETE FROM notifications WHERE user_id = ?::uuid`, testutil.TestUserID)
	t.Cleanup(func() {
		db.Exec(`DELETE FROM notifications WHERE user_id = ?::uuid`, testutil.TestUserID)
	})

	var notifID string
	require.NoError(t, db.Exec(`INSERT INTO notifications (id, user_id, type, title, is_read, created_at)
		VALUES (gen_random_uuid(), ?::uuid, 'admin', 'Mark Read Test', false, NOW())`, testutil.TestUserID).Error)
	rows := db.Raw(`SELECT id FROM notifications WHERE user_id = ?::uuid AND title = 'Mark Read Test' LIMIT 1`, testutil.TestUserID).Row()
	require.NoError(t, rows.Scan(&notifID))

	w := testutil.PerformRequest(engine, http.MethodPut, "/api/v1/notifications/"+notifID+"/read", nil, token)
	assert.Equal(t, http.StatusNoContent, w.Code)

	countW := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/notifications/unread-count", nil, token)
	require.Equal(t, http.StatusOK, countW.Code)
	var countResp map[string]interface{}
	require.NoError(t, testutil.ParseResponse(countW, &countResp))
	data := countResp["data"].(map[string]interface{})
	assert.Equal(t, float64(0), data["unread_count"])
}

func TestIntegration_Notification_MarkAllAsRead_Success(t *testing.T) {
	engine, token, err := testutil.Setup()
	require.NoError(t, err)
	db := testutil.GetTestDB()
	require.NotNil(t, db)

	db.Exec(`DELETE FROM notifications WHERE user_id = ?::uuid`, testutil.TestUserID)
	t.Cleanup(func() {
		db.Exec(`DELETE FROM notifications WHERE user_id = ?::uuid`, testutil.TestUserID)
	})

	for i := 0; i < 5; i++ {
		require.NoError(t, db.Exec(`INSERT INTO notifications (id, user_id, type, title, is_read, created_at)
			VALUES (gen_random_uuid(), ?::uuid, 'admin', 'MarkAll Test', false, NOW())`, testutil.TestUserID).Error)
	}

	w := testutil.PerformRequest(engine, http.MethodPut, "/api/v1/notifications/read-all", nil, token)
	assert.Equal(t, http.StatusNoContent, w.Code)

	countW := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/notifications/unread-count", nil, token)
	require.Equal(t, http.StatusOK, countW.Code)
	var countResp map[string]interface{}
	require.NoError(t, testutil.ParseResponse(countW, &countResp))
	data := countResp["data"].(map[string]interface{})
	assert.Equal(t, float64(0), data["unread_count"])
}

func TestIntegration_AdminNotifications_List_Success(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)
	db := testutil.GetTestDB()
	require.NotNil(t, db)

	db.Exec(`DELETE FROM notifications WHERE user_id = ?::uuid`, testutil.TestUserID)
	t.Cleanup(func() {
		db.Exec(`DELETE FROM notifications WHERE user_id = ?::uuid`, testutil.TestUserID)
	})

	require.NoError(t, db.Exec(`INSERT INTO notifications (id, user_id, type, title, is_read, created_at)
		VALUES (gen_random_uuid(), ?::uuid, 'admin', 'Admin Notif One', false, NOW())`, testutil.TestUserID).Error)
	require.NoError(t, db.Exec(`INSERT INTO notifications (id, user_id, type, title, is_read, created_at)
		VALUES (gen_random_uuid(), ?::uuid, 'admin', 'Admin Notif Two', false, NOW())`, testutil.TestUserID).Error)

	token := testutil.GenerateAdminToken()
	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/admin/notifications", nil, token)
	require.Equal(t, http.StatusOK, w.Code)

	var resp map[string]interface{}
	err = testutil.ParseResponse(w, &resp)
	require.NoError(t, err)
	_, ok := resp["data"].([]interface{})
	assert.True(t, ok)
}

func TestIntegration_AdminNotifications_SendPush_RequiresAdmin(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	token := testutil.GenerateOwnerToken()
	body := testutil.JSONBody(map[string]interface{}{
		"title": "Test Push",
		"body":  "Test message",
	})
	w := testutil.PerformRequest(engine, http.MethodPost, "/api/v1/admin/notifications/push", body, token)
	assert.Equal(t, http.StatusForbidden, w.Code)
}

func TestIntegration_NotificationCategories_Public(t *testing.T) {
	engine, _, err := testutil.Setup()
	require.NoError(t, err)

	w := testutil.PerformRequest(engine, http.MethodGet, "/api/v1/notification-categories", nil, "")
	require.Equal(t, http.StatusOK, w.Code)

	var resp map[string]interface{}
	err = testutil.ParseResponse(w, &resp)
	require.NoError(t, err)
	data, ok := resp["data"].([]interface{})
	require.True(t, ok)
	assert.Len(t, data, 3)
}
