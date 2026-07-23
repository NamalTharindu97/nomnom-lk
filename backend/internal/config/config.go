package config

import (
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/mail"
	"net/url"
	"os"
	"strconv"
	"strings"

	"github.com/spf13/viper"
)

type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	Redis    RedisConfig
	JWT      JWTConfig
	Firebase FirebaseConfig
	R2       R2Config
	Sentry   SentryConfig
	CORS     CORSConfig
	Browser  BrowserSessionConfig
	Admin    AdminConfig
	SMTP     SMTPConfig
}

type SMTPConfig struct {
	Host     string
	Port     int
	Username string
	Password string
	From     string
}

type ServerConfig struct {
	Port        string
	Host        string
	Environment string
}

type DatabaseConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	Name     string
	SSLMode  string
}

type RedisConfig struct {
	Host     string
	Port     string
	Password string
}

type JWTConfig struct {
	Secret        string
	AccessExpiry  string
	RefreshExpiry string
}

type FirebaseConfig struct {
	CredentialsPath string
}

type R2Config struct {
	Region          string
	AccessKeyID     string
	SecretAccessKey string
	Bucket          string
	Endpoint        string
	Secure          bool
	ForcePathStyle  bool
	Prefix          string
}

type SentryConfig struct {
	DSN string
}

type CORSConfig struct {
	Origins string
}

type BrowserSessionConfig struct {
	CookieSecure bool
}

type AdminConfig struct {
	Email    string
	Password string
}

type parsedDBConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	DBName   string
	SSLMode  string
}

const maxSecretFileSize = 64 * 1024

var secretFileMappings = []struct {
	fileVariable string
	target       string
}{
	{"DATABASE_PASSWORD_FILE", "DATABASE_PASSWORD"},
	{"REDIS_PASSWORD_FILE", "REDIS_PASSWORD"},
	{"JWT_SECRET_FILE", "JWT_SECRET"},
	{"R2_ACCESS_KEY_FILE", "R2_ACCESS_KEY_ID"},
	{"R2_SECRET_KEY_FILE", "R2_SECRET_ACCESS_KEY"},
	{"SMTP_PASSWORD_FILE", "SMTP_PASSWORD"},
	{"ADMIN_PASSWORD_FILE", "ADMIN_PASSWORD"},
}

func applySecretFiles(v *viper.Viper) error {
	for _, mapping := range secretFileMappings {
		path := strings.TrimSpace(v.GetString(mapping.fileVariable))
		if path == "" {
			continue
		}
		value, err := readSecretFile(path)
		if err != nil {
			return fmt.Errorf("%s is invalid: %w", mapping.fileVariable, err)
		}
		v.Set(mapping.target, value)
	}
	return nil
}

func readSecretFile(path string) (string, error) {
	info, err := os.Lstat(path)
	if err != nil {
		return "", errors.New("file is unavailable")
	}
	if !info.Mode().IsRegular() || info.Mode()&os.ModeSymlink != 0 {
		return "", errors.New("path must be a regular file")
	}
	if info.Size() == 0 {
		return "", errors.New("file is empty")
	}
	if info.Size() > maxSecretFileSize {
		return "", errors.New("file is too large")
	}
	raw, err := os.ReadFile(path)
	if err != nil {
		return "", errors.New("file cannot be read")
	}
	value := string(raw)
	if strings.HasSuffix(value, "\n") {
		value = strings.TrimSuffix(value, "\n")
		value = strings.TrimSuffix(value, "\r")
	}
	if value == "" {
		return "", errors.New("file is empty")
	}
	return value, nil
}

func parseDatabaseURL(databaseURL string) (*parsedDBConfig, error) {
	u, err := url.Parse(databaseURL)
	if err != nil || (u.Scheme != "postgres" && u.Scheme != "postgresql") || u.User == nil || u.Hostname() == "" {
		return nil, errors.New("invalid DATABASE_URL")
	}

	password, hasPassword := u.User.Password()
	dbName := strings.TrimPrefix(u.Path, "/")
	if u.User.Username() == "" || !hasPassword || password == "" || dbName == "" {
		return nil, errors.New("invalid DATABASE_URL")
	}

	host := u.Hostname()
	port := u.Port()
	if port == "" {
		port = "5432"
	}

	sslmode := u.Query().Get("sslmode")
	if sslmode == "" {
		sslmode = "require"
	}

	return &parsedDBConfig{
		Host:     host,
		Port:     port,
		User:     u.User.Username(),
		Password: password,
		DBName:   dbName,
		SSLMode:  sslmode,
	}, nil
}

func Load() (*Config, error) {
	v := viper.New()
	v.AutomaticEnv()
	v.SetEnvPrefix("")

	v.SetConfigFile(".env")
	if err := v.MergeInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			if !os.IsNotExist(err) {
				return nil, err
			}
		}
	}

	v.SetDefault("SERVER_PORT", "8080")
	// Fallback to PORT env var (Render, Heroku, cloud convention)
	if _, serverSet := os.LookupEnv("SERVER_PORT"); !serverSet {
		if port, portSet := os.LookupEnv("PORT"); portSet {
			v.Set("SERVER_PORT", port)
		}
	}
	v.SetDefault("SERVER_HOST", "0.0.0.0")
	v.SetDefault("ENVIRONMENT", "development")

	v.SetDefault("DATABASE_HOST", "localhost")
	v.SetDefault("DATABASE_PORT", "5432")
	v.SetDefault("DATABASE_USER", "nomnom")
	v.SetDefault("DATABASE_PASSWORD", "nomnom123")
	v.SetDefault("DATABASE_NAME", "nomnom")
	v.SetDefault("DATABASE_SSLMODE", "disable")

	v.SetDefault("REDIS_HOST", "localhost")
	v.SetDefault("REDIS_PORT", "6379")
	v.SetDefault("REDIS_PASSWORD", "")

	v.SetDefault("JWT_SECRET", "change-me")
	v.SetDefault("JWT_ACCESS_EXPIRY", "15m")
	v.SetDefault("JWT_REFRESH_EXPIRY", "720h")

	v.SetDefault("FIREBASE_CREDENTIALS_PATH", "./config/firebase-credentials.json")

	v.SetDefault("R2_REGION", "ap-southeast-1")
	v.SetDefault("R2_ACCESS_KEY_ID", "minioadmin")
	v.SetDefault("R2_SECRET_ACCESS_KEY", "minioadmin")
	v.SetDefault("R2_BUCKET", "nomnom-images")
	v.SetDefault("R2_ENDPOINT", "localhost:9000")
	v.SetDefault("R2_SECURE", false)
	v.SetDefault("R2_FORCE_PATH_STYLE", true)
	v.SetDefault("R2_PREFIX", "dev")

	v.SetDefault("SENTRY_DSN", "")

	v.SetDefault("CORS_ORIGINS", "http://localhost:3000,http://localhost:8080")
	v.SetDefault("BROWSER_COOKIE_SECURE", strings.EqualFold(v.GetString("ENVIRONMENT"), "production"))

	v.SetDefault("ADMIN_EMAIL", "admin@nomnom.lk")
	v.SetDefault("ADMIN_PASSWORD", "")

	v.SetDefault("SMTP_HOST", "")
	v.SetDefault("SMTP_PORT", 587)
	v.SetDefault("SMTP_USERNAME", "")
	v.SetDefault("SMTP_PASSWORD", "")
	v.SetDefault("SMTP_FROM", "NomNom LK <noreply@nomnom.lk>")

	// Parse DATABASE_URL (Render/Heroku style) — overrides individual DB vars
	if dbURL := os.Getenv("DATABASE_URL"); dbURL != "" {
		dbCfg, err := parseDatabaseURL(dbURL)
		if err != nil {
			return nil, fmt.Errorf("failed to parse DATABASE_URL: %w", err)
		}
		v.Set("DATABASE_HOST", dbCfg.Host)
		v.Set("DATABASE_PORT", dbCfg.Port)
		v.Set("DATABASE_USER", dbCfg.User)
		v.Set("DATABASE_PASSWORD", dbCfg.Password)
		v.Set("DATABASE_NAME", dbCfg.DBName)
		v.Set("DATABASE_SSLMODE", dbCfg.SSLMode)
	}

	// Parse REDIS_URL (Render/Upstash style) — overrides individual Redis vars
	if redisURL := os.Getenv("REDIS_URL"); redisURL != "" {
		u, err := url.Parse(redisURL)
		if err != nil || (u.Scheme != "redis" && u.Scheme != "rediss") || u.Hostname() == "" {
			return nil, errors.New("invalid REDIS_URL")
		}
		password := ""
		if u.User != nil {
			password, _ = u.User.Password()
		}
		v.Set("REDIS_PASSWORD", password)
		v.Set("REDIS_HOST", u.Hostname())
		if port := u.Port(); port != "" {
			v.Set("REDIS_PORT", port)
		}
	}
	if err := applySecretFiles(v); err != nil {
		return nil, err
	}

	cfg := &Config{
		Server: ServerConfig{
			Port:        v.GetString("SERVER_PORT"),
			Host:        v.GetString("SERVER_HOST"),
			Environment: v.GetString("ENVIRONMENT"),
		},
		Database: DatabaseConfig{
			Host:     v.GetString("DATABASE_HOST"),
			Port:     v.GetString("DATABASE_PORT"),
			User:     v.GetString("DATABASE_USER"),
			Password: v.GetString("DATABASE_PASSWORD"),
			Name:     v.GetString("DATABASE_NAME"),
			SSLMode:  v.GetString("DATABASE_SSLMODE"),
		},
		Redis: RedisConfig{
			Host:     v.GetString("REDIS_HOST"),
			Port:     v.GetString("REDIS_PORT"),
			Password: v.GetString("REDIS_PASSWORD"),
		},
		JWT: JWTConfig{
			Secret:        v.GetString("JWT_SECRET"),
			AccessExpiry:  v.GetString("JWT_ACCESS_EXPIRY"),
			RefreshExpiry: v.GetString("JWT_REFRESH_EXPIRY"),
		},
		Firebase: FirebaseConfig{
			CredentialsPath: v.GetString("FIREBASE_CREDENTIALS_PATH"),
		},
		R2: R2Config{
			Region:          v.GetString("R2_REGION"),
			AccessKeyID:     v.GetString("R2_ACCESS_KEY_ID"),
			SecretAccessKey: v.GetString("R2_SECRET_ACCESS_KEY"),
			Bucket:          v.GetString("R2_BUCKET"),
			Endpoint:        v.GetString("R2_ENDPOINT"),
			Secure:          v.GetBool("R2_SECURE"),
			ForcePathStyle:  v.GetBool("R2_FORCE_PATH_STYLE"),
			Prefix:          v.GetString("R2_PREFIX"),
		},
		Sentry: SentryConfig{
			DSN: v.GetString("SENTRY_DSN"),
		},
		CORS: CORSConfig{
			Origins: v.GetString("CORS_ORIGINS"),
		},
		Browser: BrowserSessionConfig{
			CookieSecure: v.GetBool("BROWSER_COOKIE_SECURE"),
		},
		Admin: AdminConfig{
			Email:    v.GetString("ADMIN_EMAIL"),
			Password: v.GetString("ADMIN_PASSWORD"),
		},
		SMTP: SMTPConfig{
			Host:     v.GetString("SMTP_HOST"),
			Port:     v.GetInt("SMTP_PORT"),
			Username: v.GetString("SMTP_USERNAME"),
			Password: v.GetString("SMTP_PASSWORD"),
			From:     v.GetString("SMTP_FROM"),
		},
	}
	if err := cfg.Validate(); err != nil {
		return nil, err
	}
	return cfg, nil
}

func (c *Config) Validate() error {
	if !strings.EqualFold(strings.TrimSpace(c.Server.Environment), "production") {
		return nil
	}

	var problems []string
	require := func(name, value string) {
		if strings.TrimSpace(value) == "" {
			problems = append(problems, name+" is required")
		}
	}
	validPort := func(name, value string) {
		port, err := strconv.Atoi(value)
		if err != nil || port < 1 || port > 65535 {
			problems = append(problems, name+" is invalid")
		}
	}

	require("DATABASE_HOST", c.Database.Host)
	require("DATABASE_PORT", c.Database.Port)
	require("DATABASE_USER", c.Database.User)
	require("DATABASE_PASSWORD", c.Database.Password)
	require("DATABASE_NAME", c.Database.Name)
	validPort("DATABASE_PORT", c.Database.Port)
	if isLocalHost(c.Database.Host) {
		problems = append(problems, "DATABASE_HOST must not be local")
	}
	if mode := strings.ToLower(strings.TrimSpace(c.Database.SSLMode)); mode == "" || mode == "disable" {
		problems = append(problems, "DATABASE_SSLMODE must enable TLS")
	}

	require("REDIS_HOST", c.Redis.Host)
	require("REDIS_PORT", c.Redis.Port)
	validPort("REDIS_PORT", c.Redis.Port)
	if isLocalHost(c.Redis.Host) {
		problems = append(problems, "REDIS_HOST must not be local")
	}

	if len(strings.TrimSpace(c.JWT.Secret)) < 32 {
		problems = append(problems, "JWT_SECRET must contain at least 32 characters")
	}
	if !c.Browser.CookieSecure {
		problems = append(problems, "BROWSER_COOKIE_SECURE must be true")
	}

	require("R2_REGION", c.R2.Region)
	require("R2_ACCESS_KEY_ID", c.R2.AccessKeyID)
	require("R2_SECRET_ACCESS_KEY", c.R2.SecretAccessKey)
	require("R2_BUCKET", c.R2.Bucket)
	require("R2_ENDPOINT", c.R2.Endpoint)
	require("R2_PREFIX", c.R2.Prefix)
	if strings.Contains(c.R2.Endpoint, "://") || isLocalHost(endpointHost(c.R2.Endpoint)) {
		problems = append(problems, "R2_ENDPOINT must be a non-local host without a URL scheme")
	}
	if !c.R2.Secure {
		problems = append(problems, "R2_SECURE must be true")
	}
	if strings.EqualFold(strings.TrimSpace(c.R2.Prefix), "dev") {
		problems = append(problems, "R2_PREFIX must not use the development prefix")
	}

	require("FIREBASE_CREDENTIALS_PATH", c.Firebase.CredentialsPath)
	if c.Firebase.CredentialsPath != "" && !validFirebaseCredentials(c.Firebase.CredentialsPath) {
		problems = append(problems, "FIREBASE_CREDENTIALS_PATH must reference valid service-account credentials")
	}

	if _, err := mail.ParseAddress(c.Admin.Email); err != nil || !strings.Contains(c.Admin.Email, "@") {
		problems = append(problems, "ADMIN_EMAIL is invalid")
	}
	if len(c.Admin.Password) < 12 {
		problems = append(problems, "ADMIN_PASSWORD must contain at least 12 characters")
	}

	if strings.TrimSpace(c.SMTP.Host) != "" {
		require("SMTP_USERNAME", c.SMTP.Username)
		require("SMTP_PASSWORD", c.SMTP.Password)
		require("SMTP_FROM", c.SMTP.From)
		if c.SMTP.Port < 1 || c.SMTP.Port > 65535 {
			problems = append(problems, "SMTP_PORT is invalid")
		}
		if _, err := mail.ParseAddress(c.SMTP.From); err != nil {
			problems = append(problems, "SMTP_FROM is invalid")
		}
	}

	if len(problems) > 0 {
		return fmt.Errorf("invalid production configuration: %s", strings.Join(problems, "; "))
	}
	return nil
}

func endpointHost(endpoint string) string {
	host, _, err := net.SplitHostPort(strings.TrimSpace(endpoint))
	if err == nil {
		return host
	}
	return strings.TrimSpace(endpoint)
}

func isLocalHost(host string) bool {
	host = strings.Trim(strings.TrimSpace(host), "[]")
	if strings.EqualFold(host, "localhost") {
		return true
	}
	ip := net.ParseIP(host)
	return ip != nil && (ip.IsLoopback() || ip.IsUnspecified())
}

func validFirebaseCredentials(path string) bool {
	raw, err := os.ReadFile(path)
	if err != nil {
		return false
	}
	var credentials struct {
		Type        string `json:"type"`
		ProjectID   string `json:"project_id"`
		ClientEmail string `json:"client_email"`
		PrivateKey  string `json:"private_key"`
	}
	if err := json.Unmarshal(raw, &credentials); err != nil {
		return false
	}
	return credentials.Type == "service_account" &&
		credentials.ProjectID != "" &&
		credentials.ClientEmail != "" &&
		credentials.PrivateKey != ""
}

func (c *DatabaseConfig) DSN() string {
	return "host=" + c.Host +
		" port=" + c.Port +
		" user=" + c.User +
		" password=" + c.Password +
		" dbname=" + c.Name +
		" sslmode=" + c.SSLMode
}

func (c *RedisConfig) Addr() string {
	return c.Host + ":" + c.Port
}
