//go:build integration

package services

import (
	"testing"

	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/config"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func setupImpersonationTest(t *testing.T) (*ImpersonationService, *repository.UserRepo) {
	t.Helper()

	userRepo := repository.NewUserRepo(testDB)
	auditRepo := repository.NewAuditLogRepo(testDB)
	auditService := NewAuditService(auditRepo)

	cfg := &config.JWTConfig{
		Secret:        "test-secret-key-for-testing-only",
		AccessExpiry:  "15m",
		RefreshExpiry: "720h",
	}

	svc := NewImpersonationService(userRepo, cfg, testRDB, auditService)
	return svc, userRepo
}

func createTestAdmin(t *testing.T, userRepo *repository.UserRepo) *models.User {
	t.Helper()
	admin := &models.User{
		Email:        "impadmin_" + uuid.New().String()[:8] + "@test.com",
		Name:         "Test Admin",
		Role:         models.RoleAdmin,
		IsActive:     true,
		PasswordHash: "$2a$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012",
	}
	require.NoError(t, userRepo.Create(admin))
	t.Cleanup(func() { userRepo.SoftDelete(admin.ID) })
	return admin
}

func createTestOwner(t *testing.T, userRepo *repository.UserRepo) *models.User {
	t.Helper()
	owner := &models.User{
		Email:        "impowner_" + uuid.New().String()[:8] + "@test.com",
		Name:         "Test Owner",
		Role:         models.RoleRestaurantOwner,
		IsActive:     true,
		PasswordHash: "$2a$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012",
	}
	require.NoError(t, userRepo.Create(owner))
	t.Cleanup(func() { userRepo.SoftDelete(owner.ID) })
	return owner
}

func TestImpersonation_Start_Success(t *testing.T) {
	svc, userRepo := setupImpersonationTest(t)
	admin := createTestAdmin(t, userRepo)
	owner := createTestOwner(t, userRepo)

	token, target, err := svc.StartImpersonation(admin.ID, owner.ID)
	require.NoError(t, err)
	assert.NotEmpty(t, token)
	assert.Equal(t, owner.ID, target.ID)
	assert.Equal(t, owner.Name, target.Name)
}

func TestImpersonation_Start_NonAdminRejected(t *testing.T) {
	svc, userRepo := setupImpersonationTest(t)
	owner := createTestOwner(t, userRepo)
	otherOwner := createTestOwner(t, userRepo)

	_, _, err := svc.StartImpersonation(owner.ID, otherOwner.ID)
	assert.ErrorContains(t, err, "only admins can impersonate")
}

func TestImpersonation_Start_TargetNotFound(t *testing.T) {
	svc, userRepo := setupImpersonationTest(t)
	admin := createTestAdmin(t, userRepo)

	_, _, err := svc.StartImpersonation(admin.ID, uuid.New())
	assert.ErrorContains(t, err, "user not found")
}

func TestImpersonation_Start_CannotImpersonateInactive(t *testing.T) {
	svc, userRepo := setupImpersonationTest(t)
	admin := createTestAdmin(t, userRepo)
	owner := createTestOwner(t, userRepo)

	owner.IsActive = false
	require.NoError(t, userRepo.Update(owner))

	_, _, err := svc.StartImpersonation(admin.ID, owner.ID)
	assert.ErrorContains(t, err, "inactive")
}

func TestImpersonation_Stop_Success(t *testing.T) {
	svc, userRepo := setupImpersonationTest(t)
	admin := createTestAdmin(t, userRepo)
	owner := createTestOwner(t, userRepo)

	_, _, err := svc.StartImpersonation(admin.ID, owner.ID)
	require.NoError(t, err)

	adminToken, restoredAdmin, err := svc.StopImpersonation(admin.ID)
	require.NoError(t, err)
	assert.NotEmpty(t, adminToken)
	assert.Equal(t, admin.ID, restoredAdmin.ID)
	assert.Equal(t, admin.Name, restoredAdmin.Name)
}

func TestImpersonation_Stop_NoActiveSession(t *testing.T) {
	svc, userRepo := setupImpersonationTest(t)
	admin := createTestAdmin(t, userRepo)

	_, _, err := svc.StopImpersonation(admin.ID)
	assert.ErrorContains(t, err, "no active impersonation")
}

func TestImpersonation_Status_NoSession(t *testing.T) {
	svc, userRepo := setupImpersonationTest(t)
	admin := createTestAdmin(t, userRepo)

	active, target, _, err := svc.GetImpersonationStatus(admin.ID)
	require.NoError(t, err)
	assert.False(t, active)
	assert.Nil(t, target)
}

func TestImpersonation_Status_ActiveSession(t *testing.T) {
	svc, userRepo := setupImpersonationTest(t)
	admin := createTestAdmin(t, userRepo)
	owner := createTestOwner(t, userRepo)

	_, _, err := svc.StartImpersonation(admin.ID, owner.ID)
	require.NoError(t, err)

	active, target, startedAt, err := svc.GetImpersonationStatus(admin.ID)
	require.NoError(t, err)
	assert.True(t, active)
	assert.Equal(t, admin.ID, target.ID)
	assert.False(t, startedAt.IsZero())
}
