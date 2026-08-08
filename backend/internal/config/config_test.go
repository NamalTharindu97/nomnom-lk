package config

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/spf13/viper"
	"github.com/stretchr/testify/require"
)

func TestValidatePreservesNonProductionDefaults(t *testing.T) {
	for _, environment := range []string{"development", "test", ""} {
		t.Run(environment, func(t *testing.T) {
			cfg := &Config{Server: ServerConfig{Environment: environment}}
			require.NoError(t, cfg.Validate())
		})
	}
}

func TestLoadPreservesDevelopmentDefaults(t *testing.T) {
	t.Setenv("ENVIRONMENT", "development")
	t.Setenv("DATABASE_URL", "")
	t.Setenv("REDIS_URL", "")

	cfg, err := Load()

	require.NoError(t, err)
	require.Equal(t, "localhost", cfg.Database.Host)
	require.Equal(t, "localhost", cfg.Redis.Host)
	require.Equal(t, "dev", cfg.R2.Prefix)
	require.False(t, cfg.Browser.CookieSecure)
}

func TestApplySecretFilesMapsEverySupportedSecret(t *testing.T) {
	for _, mapping := range secretFileMappings {
		t.Run(mapping.fileVariable, func(t *testing.T) {
			path := writeSecretFile(t, "file-secret")
			v := viper.New()
			v.Set(mapping.fileVariable, path)
			v.Set(mapping.target, "direct-secret")

			require.NoError(t, applySecretFiles(v))
			require.Equal(t, "file-secret", v.GetString(mapping.target))
		})
	}
}

func TestReadSecretFileRemovesOneTerminalLineEnding(t *testing.T) {
	for _, tt := range []struct {
		name     string
		contents string
		expected string
	}{
		{"lf", "secret-value\n", "secret-value"},
		{"crlf", "secret-value\r\n", "secret-value"},
		{"none", "secret-value", "secret-value"},
		{"preserve whitespace", " secret-value ", " secret-value "},
		{"remove one only", "secret-value\n\n", "secret-value\n"},
	} {
		t.Run(tt.name, func(t *testing.T) {
			value, err := readSecretFile(writeSecretFile(t, tt.contents))
			require.NoError(t, err)
			require.Equal(t, tt.expected, value)
		})
	}
}

func TestReadSecretFileRejectsUnsafeInputs(t *testing.T) {
	t.Run("missing", func(t *testing.T) {
		_, err := readSecretFile(filepath.Join(t.TempDir(), "missing"))
		require.Error(t, err)
	})
	t.Run("empty", func(t *testing.T) {
		_, err := readSecretFile(writeSecretFile(t, ""))
		require.Error(t, err)
	})
	t.Run("directory", func(t *testing.T) {
		_, err := readSecretFile(t.TempDir())
		require.Error(t, err)
	})
	t.Run("symlink", func(t *testing.T) {
		target := writeSecretFile(t, "secret")
		link := filepath.Join(t.TempDir(), "secret-link")
		require.NoError(t, os.Symlink(target, link))
		_, err := readSecretFile(link)
		require.Error(t, err)
	})
	t.Run("oversized", func(t *testing.T) {
		_, err := readSecretFile(writeSecretFile(t, strings.Repeat("x", maxSecretFileSize+1)))
		require.Error(t, err)
	})
}

func TestApplySecretFilesDoesNotExposePathOrContents(t *testing.T) {
	const sentinel = "private-sentinel"
	path := filepath.Join(t.TempDir(), sentinel)
	v := viper.New()
	v.Set("JWT_SECRET_FILE", path)

	err := applySecretFiles(v)
	require.Error(t, err)
	require.Contains(t, err.Error(), "JWT_SECRET_FILE")
	require.NotContains(t, err.Error(), sentinel)
}

func TestLoadSecretFilesOverrideURLPasswords(t *testing.T) {
	databaseSecret := writeSecretFile(t, "database-file-password")
	redisSecret := writeSecretFile(t, "redis-file-password")
	t.Setenv("ENVIRONMENT", "development")
	t.Setenv("DATABASE_URL", "postgres://user:url-password@database.internal:5432/nomnom?sslmode=require")
	t.Setenv("REDIS_URL", "redis://user:url-password@redis.internal:6379")
	t.Setenv("DATABASE_PASSWORD_FILE", databaseSecret)
	t.Setenv("REDIS_PASSWORD_FILE", redisSecret)

	cfg, err := Load()

	require.NoError(t, err)
	require.Equal(t, "database-file-password", cfg.Database.Password)
	require.Equal(t, "redis-file-password", cfg.Redis.Password)
}

func TestValidateAcceptsCompleteProductionConfig(t *testing.T) {
	cfg := validProductionConfig(t)
	require.NoError(t, cfg.Validate())
}

func TestValidateRejectsUnsafeProductionSubsystems(t *testing.T) {
	tests := []struct {
		name     string
		modify   func(*Config)
		expected string
	}{
		{"database", func(c *Config) { c.Database.Host = "localhost" }, "DATABASE_HOST"},
		{"database tls", func(c *Config) { c.Database.SSLMode = "disable" }, "DATABASE_SSLMODE"},
		{"redis", func(c *Config) { c.Redis.Host = "127.0.0.1" }, "REDIS_HOST"},
		{"jwt", func(c *Config) { c.JWT.Secret = "short" }, "JWT_SECRET"},
		{"browser cookie", func(c *Config) { c.Browser.CookieSecure = false }, "BROWSER_COOKIE_SECURE"},
		{"r2 transport", func(c *Config) { c.R2.Secure = false }, "R2_SECURE"},
		{"r2 endpoint", func(c *Config) { c.R2.Endpoint = "http://localhost:9000" }, "R2_ENDPOINT"},
		{"firebase", func(c *Config) { c.Firebase.CredentialsPath = "missing.json" }, "FIREBASE_CREDENTIALS_PATH"},
		{"admin password", func(c *Config) { c.Admin.Password = "short" }, "ADMIN_PASSWORD"},
		{"smtp partial", func(c *Config) { c.SMTP = SMTPConfig{Host: "smtp.example.com", Port: 587} }, "SMTP_USERNAME"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cfg := validProductionConfig(t)
			tt.modify(cfg)
			err := cfg.Validate()
			require.Error(t, err)
			require.Contains(t, err.Error(), tt.expected)
		})
	}
}

func TestValidateDoesNotExposeSecretValues(t *testing.T) {
	cfg := validProductionConfig(t)
	const sentinel = "private-value-that-must-not-appear"
	cfg.Database.Password = sentinel
	cfg.JWT.Secret = "short"

	err := cfg.Validate()
	require.Error(t, err)
	require.NotContains(t, err.Error(), sentinel)
}

func TestParseDatabaseURLRejectsMalformedValuesWithoutEchoingThem(t *testing.T) {
	const malformed = "postgres://private-user:private-password@"
	_, err := parseDatabaseURL(malformed)
	require.Error(t, err)
	require.NotContains(t, err.Error(), malformed)
	require.NotContains(t, err.Error(), "private-password")
}

func TestLoadRejectsMalformedRedisURLWithoutEchoingIt(t *testing.T) {
	const malformed = "redis://private-user:private-password@"
	t.Setenv("REDIS_URL", malformed)
	t.Setenv("DATABASE_URL", "")

	_, err := Load()
	require.Error(t, err)
	require.NotContains(t, err.Error(), malformed)
	require.NotContains(t, err.Error(), "private-password")
}

func validProductionConfig(t *testing.T) *Config {
	t.Helper()
	credentialsPath := filepath.Join(t.TempDir(), "firebase.json")
	err := os.WriteFile(credentialsPath, []byte(`{
  "type": "service_account",
  "project_id": "test-project",
  "client_email": "firebase@example.test",
  "private_key": "test-private-key"
}`), 0o600)
	require.NoError(t, err)

	return &Config{
		Server: ServerConfig{Environment: "production"},
		Database: DatabaseConfig{
			Host: "database.internal", Port: "5432", User: "app",
			Password: "database-password", Name: "nomnom", SSLMode: "require",
		},
		Redis:    RedisConfig{Host: "redis.internal", Port: "6379"},
		JWT:      JWTConfig{Secret: strings.Repeat("a", 32)},
		Browser:  BrowserSessionConfig{CookieSecure: true},
		Firebase: FirebaseConfig{CredentialsPath: credentialsPath},
		R2: R2Config{
			Region: "auto", AccessKeyID: "access-key", SecretAccessKey: "secret-key",
			Bucket: "images", Endpoint: "account.example.test", Secure: true, Prefix: "production",
		},
		Admin: AdminConfig{Email: "admin@example.test", Password: "strong-admin-password"},
	}
}

func writeSecretFile(t *testing.T, contents string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "secret")
	require.NoError(t, os.WriteFile(path, []byte(contents), 0o600))
	return path
}
