package services

import (
	"context"
	"encoding/json"
	"fmt"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/config"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/nomnom-lk/backend/pkg/pagination"
	"google.golang.org/api/option"
)

type NotificationService struct {
	notificationRepo *repository.NotificationRepo
	deviceTokenRepo  *repository.DeviceTokenRepo
	fcmClient        *messaging.Client
}

func NewNotificationService(
	notificationRepo *repository.NotificationRepo,
	deviceTokenRepo *repository.DeviceTokenRepo,
	cfg *config.FirebaseConfig,
) *NotificationService {
	fcmClient := initFCMClient(cfg)
	return &NotificationService{
		notificationRepo: notificationRepo,
		deviceTokenRepo:  deviceTokenRepo,
		fcmClient:        fcmClient,
	}
}

func initFCMClient(cfg *config.FirebaseConfig) *messaging.Client {
	if cfg.CredentialsPath == "" {
		return nil
	}

	opt := option.WithCredentialsFile(cfg.CredentialsPath)
	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		fmt.Printf("WARN: failed to initialize Firebase app: %v\n", err)
		return nil
	}

	client, err := app.Messaging(context.Background())
	if err != nil {
		fmt.Printf("WARN: failed to initialize FCM client: %v\n", err)
		return nil
	}

	return client
}

func (s *NotificationService) RegisterDevice(userID uuid.UUID, token, platform string) error {
	device := &models.DeviceToken{
		UserID:   userID,
		Token:    token,
		Platform: platform,
	}
	return s.deviceTokenRepo.Upsert(device)
}

func (s *NotificationService) UnregisterDevice(userID uuid.UUID) error {
	return s.deviceTokenRepo.Delete(userID)
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
	Title  string
	Body   string
	Data   map[string]string
	UserID *uuid.UUID
	Type   string
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
		return nil
	}

	notifications := make([]models.Notification, len(tokens))
	for i, token := range tokens {
		notifications[i] = models.Notification{
			UserID: token.UserID,
			Type:   input.Type,
			Title:  input.Title,
			Body:   strPtr(input.Body),
		}
		if input.Data != nil {
			data, _ := json.Marshal(input.Data)
			raw := json.RawMessage(data)
			notifications[i].Data = &raw
		}
	}

	if err := s.notificationRepo.CreateBatch(notifications); err != nil {
		return fmt.Errorf("failed to save notifications: %w", err)
	}

	if s.fcmClient == nil {
		return nil
	}

	go s.sendFCMNotifications(tokens, input)

	return nil
}

func (s *NotificationService) sendFCMNotifications(tokens []models.DeviceToken, input SendPushInput) {
	ctx := context.Background()

	for _, t := range tokens {
		message := &messaging.Message{
			Token: t.Token,
			Notification: &messaging.Notification{
				Title: input.Title,
				Body:  input.Body,
			},
		}

		if input.Data != nil {
			message.Data = input.Data
		}

		if input.Type != "" {
			if message.Data == nil {
				message.Data = make(map[string]string)
			}
			message.Data["type"] = input.Type
		}

		if _, err := s.fcmClient.Send(ctx, message); err != nil {
			fmt.Printf("WARN: FCM send failed for token %s: %v\n", t.Token[:20], err)
		}
	}
}


