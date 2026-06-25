package services

import (
	"context"
	"fmt"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"github.com/nomnom-lk/backend/internal/config"
	"google.golang.org/api/option"
)

type FirebaseService struct {
	authClient *auth.Client
}

func NewFirebaseService(cfg *config.FirebaseConfig) *FirebaseService {
	if cfg.CredentialsPath == "" {
		fmt.Println("WARN: FIREBASE_CREDENTIALS_PATH not set, Firebase auth disabled")
		return &FirebaseService{}
	}

	opt := option.WithCredentialsFile(cfg.CredentialsPath)
	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		fmt.Printf("WARN: failed to initialize Firebase app: %v\n", err)
		return &FirebaseService{}
	}

	client, err := app.Auth(context.Background())
	if err != nil {
		fmt.Printf("WARN: failed to initialize Firebase auth client: %v\n", err)
		return &FirebaseService{}
	}

	return &FirebaseService{authClient: client}
}

func (s *FirebaseService) VerifyIDToken(idToken string) (*auth.Token, error) {
	if s.authClient == nil {
		return nil, fmt.Errorf("firebase auth not initialized")
	}
	token, err := s.authClient.VerifyIDToken(context.Background(), idToken)
	if err != nil {
		return nil, fmt.Errorf("failed to verify Firebase ID token: %w", err)
	}
	return token, nil
}

func (s *FirebaseService) IsEnabled() bool {
	return s.authClient != nil
}
