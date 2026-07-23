package services

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"

	"github.com/nomnom-lk/backend/internal/config"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/nomnom-lk/backend/pkg/jwt"
	"gorm.io/gorm"
)

const impersonationRedisPrefix = "impersonation:"
const impersonationTTL = 2 * time.Hour

type ImpersonationService struct {
	userRepo     *repository.UserRepo
	jwtCfg       *config.JWTConfig
	rdb          *redis.Client
	auditService *AuditService
}

func NewImpersonationService(
	userRepo *repository.UserRepo,
	jwtCfg *config.JWTConfig,
	rdb *redis.Client,
	auditService *AuditService,
) *ImpersonationService {
	return &ImpersonationService{
		userRepo:     userRepo,
		jwtCfg:       jwtCfg,
		rdb:          rdb,
		auditService: auditService,
	}
}

func (s *ImpersonationService) StartImpersonation(adminID uuid.UUID, targetUserID uuid.UUID) (string, *models.User, error) {
	admin, err := s.userRepo.FindByID(adminID)
	if err != nil {
		return "", nil, errors.New("admin not found")
	}
	if admin.Role != models.RoleAdmin {
		return "", nil, errors.New("only admins can impersonate users")
	}

	target, err := s.userRepo.FindByID(targetUserID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return "", nil, errors.New("user not found")
		}
		return "", nil, fmt.Errorf("failed to find target user: %w", err)
	}

	if target.Role != models.RoleRestaurantOwner {
		return "", nil, errors.New("can only impersonate restaurant owners")
	}
	if !target.IsActive {
		return "", nil, errors.New("cannot impersonate an inactive user")
	}

	adminToken, err := jwt.GenerateAccessToken(s.jwtCfg.Secret, admin.ID, admin.Email, admin.Name, string(admin.Role), s.jwtCfg.AccessExpiry)
	if err != nil {
		return "", nil, fmt.Errorf("failed to generate admin token backup: %w", err)
	}

	ctx := context.Background()
	redisKey := fmt.Sprintf("%s%s", impersonationRedisPrefix, adminID.String())
	if err := s.rdb.Set(ctx, redisKey, adminToken, impersonationTTL).Err(); err != nil {
		return "", nil, fmt.Errorf("failed to store admin session: %w", err)
	}

	impersonationToken, err := jwt.GenerateImpersonationToken(
		s.jwtCfg.Secret,
		target.ID,
		target.Email,
		target.Name,
		string(target.Role),
		s.jwtCfg.AccessExpiry,
		adminID,
	)
	if err != nil {
		s.rdb.Del(ctx, redisKey)
		return "", nil, fmt.Errorf("failed to generate impersonation token: %w", err)
	}

	s.auditService.LogAction(admin.ID, admin.Name, string(admin.Role), "admin.impersonate.start", "user", target.ID.String(),
		fmt.Sprintf("Admin %s (%s) started impersonating %s (%s)", admin.Name, admin.Email, target.Name, target.Email))

	return impersonationToken, target, nil
}

func (s *ImpersonationService) StopImpersonation(adminID uuid.UUID) (string, *models.User, error) {
	admin, err := s.userRepo.FindByID(adminID)
	if err != nil {
		return "", nil, errors.New("admin not found")
	}

	ctx := context.Background()
	redisKey := fmt.Sprintf("%s%s", impersonationRedisPrefix, adminID.String())

	_, err = s.rdb.Get(ctx, redisKey).Result()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return "", nil, errors.New("no active impersonation session found")
		}
		return "", nil, fmt.Errorf("failed to retrieve admin session: %w", err)
	}

	s.rdb.Del(ctx, redisKey)

	adminToken, err := jwt.GenerateAccessToken(s.jwtCfg.Secret, admin.ID, admin.Email, admin.Name, string(admin.Role), s.jwtCfg.AccessExpiry)
	if err != nil {
		return "", nil, fmt.Errorf("failed to restore admin session: %w", err)
	}

	s.auditService.LogAction(admin.ID, admin.Name, string(admin.Role), "admin.impersonate.stop", "user", adminID.String(),
		fmt.Sprintf("Admin %s (%s) stopped impersonating", admin.Name, admin.Email))

	return adminToken, admin, nil
}

func (s *ImpersonationService) GetImpersonationStatus(adminID uuid.UUID) (bool, *models.User, time.Time, error) {
	ctx := context.Background()
	redisKey := fmt.Sprintf("%s%s", impersonationRedisPrefix, adminID.String())

	adminToken, err := s.rdb.Get(ctx, redisKey).Result()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return false, nil, time.Time{}, nil
		}
		return false, nil, time.Time{}, fmt.Errorf("failed to check impersonation status: %w", err)
	}

	claims, err := jwt.ValidateToken(s.jwtCfg.Secret, adminToken)
	if err != nil {
		return false, nil, time.Time{}, nil
	}

	impersonatedUserID, _ := uuid.Parse(claims.Sub)
	target, err := s.userRepo.FindByID(impersonatedUserID)
	if err != nil {
		return true, nil, time.Unix(claims.IssuedAt.Unix(), 0), nil
	}

	return true, target, time.Unix(claims.IssuedAt.Unix(), 0), nil
}

func (s *ImpersonationService) isActiveImpersonation(adminID uuid.UUID) bool {
	ctx := context.Background()
	redisKey := fmt.Sprintf("%s%s", impersonationRedisPrefix, adminID.String())
	err := s.rdb.Get(ctx, redisKey).Err()
	return err == nil
}
