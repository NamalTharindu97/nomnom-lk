package services

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"

	"github.com/nomnom-lk/backend/internal/config"
	"github.com/nomnom-lk/backend/internal/dto/response"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/nomnom-lk/backend/pkg/hash"
	"github.com/nomnom-lk/backend/pkg/jwt"
	"gorm.io/gorm"
)

type AuthService struct {
	userRepo         *repository.UserRepo
	refreshTokenRepo *repository.RefreshTokenRepo
	cfg              *config.JWTConfig
	rdb              *redis.Client
	emailService     *EmailService
}

func NewAuthService(
	userRepo *repository.UserRepo,
	refreshTokenRepo *repository.RefreshTokenRepo,
	cfg *config.JWTConfig,
	rdb *redis.Client,
	emailService *EmailService,
) *AuthService {
	return &AuthService{
		userRepo:         userRepo,
		refreshTokenRepo: refreshTokenRepo,
		cfg:              cfg,
		rdb:              rdb,
		emailService:     emailService,
	}
}

func (s *AuthService) Register(email, password, name string) error {
	existing, err := s.userRepo.FindByEmail(email)
	if err == nil && existing != nil {
		return errors.New("email already registered")
	}

	hashedPassword, err := hash.HashPassword(password)
	if err != nil {
		return fmt.Errorf("failed to hash password: %w", err)
	}

	user := &models.User{
		Email:        email,
		PasswordHash: hashedPassword,
		Name:         name,
		Role:         models.RoleUser,
		IsActive:     true,
	}

	if err := s.userRepo.Create(user); err != nil {
		return fmt.Errorf("failed to create user: %w", err)
	}

	return nil
}

func (s *AuthService) Login(email, password string) (*response.AuthResponse, error) {
	user, err := s.userRepo.FindByEmail(email)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("invalid email or password")
		}
		return nil, fmt.Errorf("failed to find user: %w", err)
	}

	if !user.IsActive {
		return nil, errors.New("account is deactivated")
	}

	if user.PasswordHash == "" {
		return nil, errors.New("please sign in with Google")
	}

	if !hash.CheckPassword(password, user.PasswordHash) {
		return nil, errors.New("invalid email or password")
	}

	if user.EmailVerifiedAt == nil {
		return nil, errors.New("please verify your email first")
	}

	return s.generateAuthResponse(user)
}

func (s *AuthService) SendVerificationCode(email string) error {
	user, err := s.userRepo.FindByEmail(email)
	if err != nil {
		return errors.New("email not found")
	}

	if user.EmailVerifiedAt != nil {
		return errors.New("email already verified")
	}

	code, err := s.emailService.GenerateCode()
	if err != nil {
		return fmt.Errorf("failed to generate code: %w", err)
	}

	ctx := context.Background()
	key := fmt.Sprintf("verify:%s", email)
	if err := s.rdb.Set(ctx, key, code, 10*time.Minute).Err(); err != nil {
		return fmt.Errorf("failed to store code: %w", err)
	}

	if err := s.emailService.SendVerificationCode(email, code); err != nil {
		return err
	}

	return nil
}

func (s *AuthService) VerifyEmail(email, code string) (*response.AuthResponse, error) {
	ctx := context.Background()
	key := fmt.Sprintf("verify:%s", email)

	storedCode, err := s.rdb.Get(ctx, key).Result()
	if err != nil {
		return nil, errors.New("invalid or expired verification code")
	}

	if storedCode != code {
		return nil, errors.New("invalid verification code")
	}

	s.rdb.Del(ctx, key)

	user, err := s.userRepo.FindByEmail(email)
	if err != nil {
		return nil, errors.New("user not found")
	}

	now := time.Now()
	user.EmailVerifiedAt = &now
	if err := s.userRepo.Update(user); err != nil {
		return nil, fmt.Errorf("failed to update user: %w", err)
	}

	return s.generateAuthResponse(user)
}

func (s *AuthService) FirebaseLogin(firebaseUID, email, name string) (*response.AuthResponse, error) {
	user, err := s.userRepo.FindByFirebaseUID(firebaseUID)
	if err != nil {
		if !errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("failed to find user: %w", err)
		}

		user, err = s.userRepo.FindByEmail(email)
		if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("failed to find user by email: %w", err)
		}

		if user != nil {
			user.FirebaseUID = &firebaseUID
			if err := s.userRepo.Update(user); err != nil {
				return nil, fmt.Errorf("failed to link firebase account: %w", err)
			}
		} else {
			now := time.Now()
			user = &models.User{
				Email:           email,
				Name:            name,
				Role:            models.RoleUser,
				FirebaseUID:     &firebaseUID,
				IsActive:        true,
				EmailVerifiedAt: &now,
			}
			if err := s.userRepo.Create(user); err != nil {
				return nil, fmt.Errorf("failed to create user: %w", err)
			}
		}
	}

	if !user.IsActive {
		return nil, errors.New("account is deactivated")
	}

	return s.generateAuthResponse(user)
}

func (s *AuthService) Refresh(refreshTokenStr string) (*response.TokenPairResponse, error) {
	tokenHash := hashToken(refreshTokenStr)

	storedToken, err := s.refreshTokenRepo.FindByHash(tokenHash)
	if err != nil {
		return nil, errors.New("invalid or expired refresh token")
	}

	if storedToken.IsExpired() {
		s.refreshTokenRepo.DeleteByID(storedToken.ID)
		return nil, errors.New("refresh token expired")
	}

	user, err := s.userRepo.FindByID(storedToken.UserID)
	if err != nil {
		return nil, errors.New("user not found")
	}

	s.refreshTokenRepo.DeleteByID(storedToken.ID)

	accessToken, err := jwt.GenerateAccessToken(s.cfg.Secret, user.ID, user.Email, string(user.Role), s.cfg.AccessExpiry)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	newRefreshToken, err := jwt.GenerateRefreshToken(s.cfg.Secret, user.ID, s.cfg.RefreshExpiry)
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	expiryDuration, _ := time.ParseDuration(s.cfg.AccessExpiry)

	if err := s.storeRefreshToken(user.ID, newRefreshToken); err != nil {
		return nil, err
	}

	return &response.TokenPairResponse{
		AccessToken:  accessToken,
		RefreshToken: newRefreshToken,
		ExpiresIn:    int(expiryDuration.Seconds()),
	}, nil
}

func (s *AuthService) Logout(userID uuid.UUID) error {
	return s.refreshTokenRepo.DeleteByUserID(userID)
}

func (s *AuthService) generateAuthResponse(user *models.User) (*response.AuthResponse, error) {
	accessToken, err := jwt.GenerateAccessToken(s.cfg.Secret, user.ID, user.Email, string(user.Role), s.cfg.AccessExpiry)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	refreshTokenStr, err := jwt.GenerateRefreshToken(s.cfg.Secret, user.ID, s.cfg.RefreshExpiry)
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	expiryDuration, _ := time.ParseDuration(s.cfg.AccessExpiry)

	if err := s.storeRefreshToken(user.ID, refreshTokenStr); err != nil {
		return nil, err
	}

	return &response.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshTokenStr,
		ExpiresIn:    int(expiryDuration.Seconds()),
		User: response.UserResponse{
			ID:          user.ID,
			Email:       user.Email,
			Name:        user.Name,
			AvatarURL:   user.AvatarURL,
			Role:        string(user.Role),
			Phone:       user.Phone,
			IsOnboarded: true,
			CreatedAt:   user.CreatedAt,
		},
	}, nil
}

func (s *AuthService) storeRefreshToken(userID uuid.UUID, tokenStr string) error {
	expiryDuration, _ := time.ParseDuration(s.cfg.RefreshExpiry)

	refreshToken := &models.RefreshToken{
		UserID:    userID,
		TokenHash: hashToken(tokenStr),
		ExpiresAt: time.Now().Add(expiryDuration),
	}

	return s.refreshTokenRepo.Create(refreshToken)
}

func hashToken(token string) string {
	h := sha256.Sum256([]byte(token))
	return hex.EncodeToString(h[:])
}
