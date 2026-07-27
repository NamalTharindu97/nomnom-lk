//go:build integration

package services

import (
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/config"
	"github.com/nomnom-lk/backend/internal/database"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/gorm"
)

var (
	testDB  *gorm.DB
	testRDB *redis.Client
)

func TestMain(m *testing.M) {
	cfg := &config.DatabaseConfig{
		Host:     envOrDefault("TEST_DB_HOST", "localhost"),
		Port:     envOrDefault("TEST_DB_PORT", "5432"),
		User:     envOrDefault("TEST_DB_USER", "nomnom"),
		Password: envOrDefault("TEST_DB_PASSWORD", "nomnom123"),
		Name:     envOrDefault("TEST_DB_NAME", "nomnom_test"),
		SSLMode:  "disable",
	}
	testDB = database.NewPostgresDB(cfg)

	testRDB = redis.NewClient(&redis.Options{
		Addr: fmt.Sprintf("%s:%s",
			envOrDefault("TEST_REDIS_HOST", "localhost"),
			envOrDefault("TEST_REDIS_PORT", "6379")),
		Password: "",
	})

	os.Exit(m.Run())
}

func envOrDefault(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func setupAuthServiceTest(t *testing.T) (*AuthService, *repository.UserRepo, *repository.RefreshTokenRepo) {
	t.Helper()
	userRepo := repository.NewUserRepo(testDB)
	refreshRepo := repository.NewRefreshTokenRepo(testDB)

	cfg := &config.JWTConfig{
		Secret:        "test-secret-key-for-testing-only",
		AccessExpiry:  "15m",
		RefreshExpiry: "720h",
	}
	emailService := NewEmailService(&config.SMTPConfig{}, zerolog.Nop())
	svc := NewAuthService(userRepo, refreshRepo, cfg, testRDB, emailService)
	return svc, userRepo, refreshRepo
}

func cleanupUser(t *testing.T, userRepo *repository.UserRepo, email string) {
	t.Helper()
	user, err := userRepo.FindByEmail(email)
	if err == nil {
		userRepo.SoftDelete(user.ID)
	}
}

func TestAuthService_Register_Success(t *testing.T) {
	svc, userRepo, _ := setupAuthServiceTest(t)
	email := "reg_" + uuid.New().String()[:8] + "@test.com"
	defer cleanupUser(t, userRepo, email)

	err := svc.Register(email, "password123", "Test User")
	require.NoError(t, err)

	user, err := userRepo.FindByEmail(email)
	require.NoError(t, err)
	assert.Equal(t, "Test User", user.Name)
	assert.Equal(t, models.RoleUser, user.Role)
	assert.True(t, user.IsActive)
	assert.NotEmpty(t, user.PasswordHash)
}

func TestAuthService_Register_DuplicateEmail(t *testing.T) {
	svc, userRepo, _ := setupAuthServiceTest(t)
	email := "dup_" + uuid.New().String()[:8] + "@test.com"
	defer cleanupUser(t, userRepo, email)

	require.NoError(t, svc.Register(email, "password123", "User One"))
	err := svc.Register(email, "password456", "User Two")
	assert.ErrorContains(t, err, "email already registered")
}

func TestAuthService_Login_Success(t *testing.T) {
	svc, userRepo, _ := setupAuthServiceTest(t)
	email := "login_" + uuid.New().String()[:8] + "@test.com"
	defer cleanupUser(t, userRepo, email)

	require.NoError(t, svc.Register(email, "password123", "Login User"))

	user, err := userRepo.FindByEmail(email)
	require.NoError(t, err)
	now := time.Now()
	user.EmailVerifiedAt = &now
	require.NoError(t, userRepo.Update(user))

	resp, err := svc.Login(email, "password123")
	require.NoError(t, err)
	assert.NotEmpty(t, resp.AccessToken)
	assert.NotEmpty(t, resp.RefreshToken)
	assert.Equal(t, "Login User", resp.User.Name)
	assert.Equal(t, email, resp.User.Email)
}

func TestAuthService_Login_WrongPassword(t *testing.T) {
	svc, userRepo, _ := setupAuthServiceTest(t)
	email := "wpw_" + uuid.New().String()[:8] + "@test.com"
	defer cleanupUser(t, userRepo, email)

	require.NoError(t, svc.Register(email, "password123", "Wrong PW User"))

	_, err := svc.Login(email, "wrongpassword")
	assert.ErrorContains(t, err, "invalid email or password")
}

func TestAuthService_Login_EmailNotFound(t *testing.T) {
	svc, _, _ := setupAuthServiceTest(t)

	_, err := svc.Login("noexist_"+uuid.New().String()[:8]+"@test.com", "password123")
	assert.ErrorContains(t, err, "invalid email or password")
}

func TestAuthService_Login_InactiveAccount(t *testing.T) {
	svc, userRepo, _ := setupAuthServiceTest(t)
	email := "inactive_" + uuid.New().String()[:8] + "@test.com"
	defer cleanupUser(t, userRepo, email)

	require.NoError(t, svc.Register(email, "password123", "Inactive User"))

	user, err := userRepo.FindByEmail(email)
	require.NoError(t, err)
	user.IsActive = false
	require.NoError(t, userRepo.Update(user))

	_, err = svc.Login(email, "password123")
	assert.ErrorContains(t, err, "suspended")
}

func TestAuthService_Login_UnverifiedEmail(t *testing.T) {
	svc, userRepo, _ := setupAuthServiceTest(t)
	email := "unverified_" + uuid.New().String()[:8] + "@test.com"
	defer cleanupUser(t, userRepo, email)

	require.NoError(t, svc.Register(email, "password123", "Unverified User"))

	_, err := svc.Login(email, "password123")
	assert.ErrorContains(t, err, "verify your email")
}

func TestAuthService_Login_LockoutAfter10Failures(t *testing.T) {
	svc, userRepo, _ := setupAuthServiceTest(t)
	email := "lockout_" + uuid.New().String()[:8] + "@test.com"
	defer cleanupUser(t, userRepo, email)

	require.NoError(t, svc.Register(email, "password123", "Lockout User"))

	for i := 0; i < 10; i++ {
		svc.Login(email, "wrongpassword")
	}

	user, err := userRepo.FindByEmail(email)
	require.NoError(t, err)
	assert.True(t, user.IsLocked(), "user should be locked after 10 failed attempts")

	_, err = svc.Login(email, "password123")
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "locked")
}

func TestAuthService_SendVerificationCode_Success(t *testing.T) {
	svc, userRepo, _ := setupAuthServiceTest(t)
	email := "vcode_" + uuid.New().String()[:8] + "@test.com"
	defer cleanupUser(t, userRepo, email)

	require.NoError(t, svc.Register(email, "password123", "VCode User"))

	err := svc.SendVerificationCode(email)
	assert.NoError(t, err)
}

func TestAuthService_SendVerificationCode_AlreadyVerified(t *testing.T) {
	svc, userRepo, _ := setupAuthServiceTest(t)
	email := "verified_" + uuid.New().String()[:8] + "@test.com"
	defer cleanupUser(t, userRepo, email)

	require.NoError(t, svc.Register(email, "password123", "Verified User"))

	user, err := userRepo.FindByEmail(email)
	require.NoError(t, err)
	now := time.Now()
	user.EmailVerifiedAt = &now
	require.NoError(t, userRepo.Update(user))

	err = svc.SendVerificationCode(email)
	assert.ErrorContains(t, err, "already verified")
}

func TestAuthService_SendVerificationCode_EmailNotFound(t *testing.T) {
	svc, _, _ := setupAuthServiceTest(t)

	err := svc.SendVerificationCode("noexist_"+uuid.New().String()[:8]+"@test.com")
	assert.ErrorContains(t, err, "email not found")
}

func TestAuthService_VerifyEmail_Success(t *testing.T) {
	svc, userRepo, _ := setupAuthServiceTest(t)
	email := "e2eve_" + uuid.New().String()[:8] + "@test.com"
	defer cleanupUser(t, userRepo, email)

	require.NoError(t, svc.Register(email, "password123", "E2E Verify User"))

	code := "123456"
	testRDB.Set(t.Context(), "verify:"+email, code, 10*time.Minute)

	resp, err := svc.VerifyEmail(email, code)
	require.NoError(t, err)
	assert.NotEmpty(t, resp.AccessToken)

	user, err := userRepo.FindByEmail(email)
	require.NoError(t, err)
	assert.NotNil(t, user.EmailVerifiedAt)
}

func TestAuthService_VerifyEmail_WrongCode(t *testing.T) {
	svc, userRepo, _ := setupAuthServiceTest(t)
	email := "wrongcode_" + uuid.New().String()[:8] + "@test.com"
	defer cleanupUser(t, userRepo, email)

	require.NoError(t, svc.Register(email, "password123", "Wrong Code User"))

	testRDB.Set(t.Context(), "verify:"+email, "123456", 10*time.Minute)

	_, err := svc.VerifyEmail(email, "999999")
	assert.ErrorContains(t, err, "invalid verification code")
}

func TestAuthService_FirebaseLogin_NewUser(t *testing.T) {
	svc, userRepo, _ := setupAuthServiceTest(t)
	fbUID := "fb_" + uuid.New().String()[:8]
	fbEmail := "fbnew_" + uuid.New().String()[:8] + "@test.com"
	defer func() {
		user, err := userRepo.FindByFirebaseUID(fbUID)
		if err == nil {
			userRepo.SoftDelete(user.ID)
		}
	}()

	resp, err := svc.FirebaseLogin(fbUID, fbEmail, "FB New User")
	require.NoError(t, err)
	assert.NotEmpty(t, resp.AccessToken)
	assert.Equal(t, "FB New User", resp.User.Name)

	user, err := userRepo.FindByFirebaseUID(fbUID)
	require.NoError(t, err)
	assert.Equal(t, fbEmail, user.Email)
	assert.NotNil(t, user.EmailVerifiedAt)
}

func TestAuthService_FirebaseLogin_ExistingEmailLinks(t *testing.T) {
	svc, userRepo, _ := setupAuthServiceTest(t)
	email := "fblink_" + uuid.New().String()[:8] + "@test.com"
	fbUID := "fblink_" + uuid.New().String()[:8]
	defer cleanupUser(t, userRepo, email)

	require.NoError(t, svc.Register(email, "password123", "Link User"))

	user, err := userRepo.FindByEmail(email)
	require.NoError(t, err)
	now := time.Now()
	user.EmailVerifiedAt = &now
	require.NoError(t, userRepo.Update(user))

	resp, err := svc.FirebaseLogin(fbUID, email, "Link User")
	require.NoError(t, err)
	assert.NotEmpty(t, resp.AccessToken)

	updated, err := userRepo.FindByEmail(email)
	require.NoError(t, err)
	require.NotNil(t, updated.FirebaseUID)
	assert.Equal(t, fbUID, *updated.FirebaseUID)
}

func TestAuthService_FirebaseLogin_InactiveUser(t *testing.T) {
	svc, userRepo, _ := setupAuthServiceTest(t)
	fbUID := "fbinact_" + uuid.New().String()[:8]
	fbEmail := "fbinact_" + uuid.New().String()[:8] + "@test.com"
	defer func() {
		user, _ := userRepo.FindByFirebaseUID(fbUID)
		if user != nil {
			userRepo.SoftDelete(user.ID)
		}
	}()

	_, err := svc.FirebaseLogin(fbUID, fbEmail, "Inactive FB User")
	require.NoError(t, err)

	user, err := userRepo.FindByFirebaseUID(fbUID)
	require.NoError(t, err)
	user.IsActive = false
	require.NoError(t, userRepo.Update(user))

	_, err = svc.FirebaseLogin(fbUID, fbEmail, "Inactive FB User")
	assert.ErrorContains(t, err, "suspended")
}

func TestAuthService_Logout_DeletesRefreshTokens(t *testing.T) {
	svc, userRepo, refreshRepo := setupAuthServiceTest(t)
	email := "logout_" + uuid.New().String()[:8] + "@test.com"
	defer cleanupUser(t, userRepo, email)

	require.NoError(t, svc.Register(email, "password123", "Logout User"))

	user, err := userRepo.FindByEmail(email)
	require.NoError(t, err)
	now := time.Now()
	user.EmailVerifiedAt = &now
	require.NoError(t, userRepo.Update(user))

	resp, err := svc.Login(email, "password123")
	require.NoError(t, err)
	require.NotNil(t, resp)

	err = svc.Logout(user.ID)
	assert.NoError(t, err)

	tokenHash := hashToken(resp.RefreshToken)
	_, err = refreshRepo.FindByHash(tokenHash)
	assert.Error(t, err, "refresh token should be deleted after logout")
}

func TestAuthService_LoginDashboard_AdminAllowed(t *testing.T) {
	svc, userRepo, _ := setupAuthServiceTest(t)
	email := "dashadmin_" + uuid.New().String()[:8] + "@test.com"
	defer cleanupUser(t, userRepo, email)

	require.NoError(t, svc.Register(email, "password123", "Dash Admin"))

	user, err := userRepo.FindByEmail(email)
	require.NoError(t, err)
	user.Role = models.RoleAdmin
	now := time.Now()
	user.EmailVerifiedAt = &now
	require.NoError(t, userRepo.Update(user))

	resp, err := svc.LoginDashboard(email, "password123")
	require.NoError(t, err)
	assert.NotEmpty(t, resp.AccessToken)
}

func TestAuthService_LoginDashboard_OwnerAllowed(t *testing.T) {
	svc, userRepo, _ := setupAuthServiceTest(t)
	email := "dashown_" + uuid.New().String()[:8] + "@test.com"
	defer cleanupUser(t, userRepo, email)

	require.NoError(t, svc.Register(email, "password123", "Dash Owner"))

	user, err := userRepo.FindByEmail(email)
	require.NoError(t, err)
	user.Role = models.RoleRestaurantOwner
	now := time.Now()
	user.EmailVerifiedAt = &now
	require.NoError(t, userRepo.Update(user))

	resp, err := svc.LoginDashboard(email, "password123")
	require.NoError(t, err)
	assert.NotEmpty(t, resp.AccessToken)
}

func TestAuthService_LoginDashboard_RegularUserRejected(t *testing.T) {
	svc, userRepo, _ := setupAuthServiceTest(t)
	email := "dashuser_" + uuid.New().String()[:8] + "@test.com"
	defer cleanupUser(t, userRepo, email)

	require.NoError(t, svc.Register(email, "password123", "Dash Regular"))

	user, err := userRepo.FindByEmail(email)
	require.NoError(t, err)
	now := time.Now()
	user.EmailVerifiedAt = &now
	require.NoError(t, userRepo.Update(user))

	_, err = svc.LoginDashboard(email, "password123")
	assert.ErrorContains(t, err, "restricted to administrators and restaurant owners")
}

func TestAuthService_Refresh_Success(t *testing.T) {
	svc, userRepo, _ := setupAuthServiceTest(t)
	email := "refresh_" + uuid.New().String()[:8] + "@test.com"
	defer cleanupUser(t, userRepo, email)

	require.NoError(t, svc.Register(email, "password123", "Refresh User"))

	user, err := userRepo.FindByEmail(email)
	require.NoError(t, err)
	now := time.Now()
	user.EmailVerifiedAt = &now
	require.NoError(t, userRepo.Update(user))

	resp, err := svc.Login(email, "password123")
	require.NoError(t, err)

	tokenPair, err := svc.Refresh(resp.RefreshToken)
	require.NoError(t, err)
	assert.NotEmpty(t, tokenPair.AccessToken)
	assert.NotEmpty(t, tokenPair.RefreshToken)
	assert.Greater(t, tokenPair.ExpiresIn, 0)
}

func TestAuthService_Refresh_InvalidToken(t *testing.T) {
	svc, _, _ := setupAuthServiceTest(t)

	_, err := svc.Refresh("completely-invalid-token")
	assert.ErrorContains(t, err, "invalid or expired refresh token")
}
