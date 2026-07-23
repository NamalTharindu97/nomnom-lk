package services

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"

	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/config"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/nomnom-lk/backend/pkg/pagination"
	"golang.org/x/oauth2/google"
)

type NotificationService struct {
	notificationRepo *repository.NotificationRepo
	deviceTokenRepo  *repository.DeviceTokenRepo
	credsPath        string
}

func NewNotificationService(
	notificationRepo *repository.NotificationRepo,
	deviceTokenRepo *repository.DeviceTokenRepo,
	cfg *config.FirebaseConfig,
) *NotificationService {
	if cfg.CredentialsPath != "" {
		fmt.Printf("INFO: using Firebase credentials from: %s\n", cfg.CredentialsPath)
	}
	return &NotificationService{
		notificationRepo: notificationRepo,
		deviceTokenRepo:  deviceTokenRepo,
		credsPath:        cfg.CredentialsPath,
	}
}

func (s *NotificationService) RegisterDevice(userID uuid.UUID, token, platform string) error {
	device := &models.DeviceToken{
		UserID:   userID,
		Token:    token,
		Platform: platform,
	}
	return s.deviceTokenRepo.Upsert(device)
}

func (s *NotificationService) UnregisterDevice(userID uuid.UUID, token string) error {
	return s.deviceTokenRepo.DeleteByToken(userID, token)
}

func (s *NotificationService) ListNotifications(userID uuid.UUID, params pagination.Params) ([]models.Notification, int64, error) {
	return s.notificationRepo.FindByUserID(userID, params.Offset, params.PerPage)
}

func (s *NotificationService) MarkAsRead(notificationID, userID uuid.UUID) error {
	return s.notificationRepo.MarkAsRead(notificationID, userID)
}

func (s *NotificationService) MarkAllAsRead(userID uuid.UUID) error {
	return s.notificationRepo.MarkAllAsRead(userID)
}

func (s *NotificationService) GetUnreadCount(userID uuid.UUID) (int64, error) {
	return s.notificationRepo.GetUnreadCount(userID)
}

type SendPushInput struct {
	Title   string
	Body    string
	Data    map[string]string
	UserID  *uuid.UUID
	Type    string
	OfferID *uuid.UUID
}

func (s *NotificationService) SendPush(input SendPushInput) error {
	var tokens []models.DeviceToken
	var err error

	if input.UserID != nil {
		tokens, err = s.deviceTokenRepo.FindByUserID(*input.UserID)
	} else {
		tokens, err = s.deviceTokenRepo.FindAll()
	}
	if err != nil {
		return fmt.Errorf("failed to fetch device tokens: %w", err)
	}

	if len(tokens) == 0 {
		return fmt.Errorf("no registered devices for target")
	}

	// Create notifications for ALL users (each sees it in their list)
	notifications := make([]models.Notification, len(tokens))
	for i, token := range tokens {
		n := models.Notification{
			UserID:  token.UserID,
			Type:    input.Type,
			Title:   input.Title,
			Body:    strPtr(input.Body),
			OfferID: input.OfferID,
		}
		if input.Data != nil {
			data, _ := json.Marshal(input.Data)
			raw := json.RawMessage(data)
			n.Data = &raw
		}
		notifications[i] = n
	}

	if err := s.notificationRepo.CreateBatch(notifications); err != nil {
		return fmt.Errorf("failed to save notifications: %w", err)
	}

	// Deduplicate by token value so one device doesn't get duplicate FCM pushes
	seen := make(map[string]bool)
	var fcmTokens []models.DeviceToken
	for _, t := range tokens {
		if seen[t.Token] {
			continue
		}
		seen[t.Token] = true
		fcmTokens = append(fcmTokens, t)
	}

	go s.sendFCMNotifications(fcmTokens, input)

	return nil
}

func (s *NotificationService) sendFCMNotifications(tokens []models.DeviceToken, input SendPushInput) {
	ctx := context.Background()

	for _, t := range tokens {
		s.sendFCMDirect(ctx, t.Token, input)
	}
}

func (s *NotificationService) sendFCMDirect(ctx context.Context, token string, input SendPushInput) {
	raw, err := os.ReadFile(s.credsPath)
	if err != nil {
		fmt.Printf("WARN: failed to read Firebase credentials: %v\n", err)
		return
	}

	var credsJSON struct {
		ProjectID string `json:"project_id"`
	}
	if err := json.Unmarshal(raw, &credsJSON); err != nil || credsJSON.ProjectID == "" {
		fmt.Println("WARN: could not determine Firebase project ID")
		return
	}

	// Use cloud-platform scope token for FCM API auth
	creds, err := google.CredentialsFromJSON(ctx, raw, "https://www.googleapis.com/auth/cloud-platform")
	if err != nil {
		fmt.Printf("WARN: failed to create credentials: %v\n", err)
		return
	}

	if creds.TokenSource == nil {
		fmt.Println("WARN: no token source from credentials")
		return
	}

	tok, err := creds.TokenSource.Token()
	if err != nil {
		fmt.Printf("WARN: failed to get access token: %v\n", err)
		return
	}

	data := make(map[string]string)
	if input.Data != nil {
		for k, v := range input.Data {
			data[k] = v
		}
	}
	if input.Type != "" {
		data["type"] = input.Type
	}

	msg := map[string]any{
		"token": token,
		"notification": map[string]string{
			"title": input.Title,
			"body":  input.Body,
		},
		"android": map[string]any{
			"priority": "high",
			"notification": map[string]string{
				"channel_id": "nomnom_notifications",
			},
		},
	}
	if len(data) > 0 {
		msg["data"] = data
	}

	body, _ := json.Marshal(map[string]any{"message": msg})

	url := fmt.Sprintf("https://fcm.googleapis.com/v1/projects/%s/messages:send", credsJSON.ProjectID)

	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewReader(body))
	if err != nil {
		fmt.Printf("WARN: failed to create FCM request: %v\n", err)
		return
	}
	req.Header.Set("Authorization", "Bearer "+tok.AccessToken)
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Printf("WARN: FCM HTTP request failed: %v\n", err)
		return
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)
	if resp.StatusCode == 200 {
		fmt.Println("INFO: FCM notification sent")
		return
	}

	status, stale := parseFCMError(respBody)
	fmt.Printf("WARN: FCM HTTP error status_code=%d fcm_status=%s stale_token=%t\n", resp.StatusCode, status, stale)
	if stale {
		if delErr := s.deviceTokenRepo.DeleteByTokenValue(token); delErr != nil {
			fmt.Println("WARN: failed to delete stale FCM token")
		}
	}
}

func parseFCMError(body []byte) (string, bool) {
	var fcmResp struct {
		Error struct {
			Message string `json:"message"`
			Status  string `json:"status"`
		} `json:"error"`
	}
	if json.Unmarshal(body, &fcmResp) != nil {
		return "unknown", false
	}
	status := fcmResp.Error.Status
	if status == "" {
		status = "unknown"
	}
	return status, isUnregisteredByMessage(fcmResp.Error.Message)
}

func isUnregisteredByMessage(msg string) bool {
	return strings.Contains(msg, "NotRegistered") ||
		strings.Contains(msg, "Unregistered") ||
		strings.Contains(msg, "UNREGISTERED")
}
