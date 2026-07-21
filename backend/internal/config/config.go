package config

import (
	"fmt"
	"net"
	"net/url"
	"os"
	"strings"

	"github.com/spf13/viper"
)

type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	Redis    RedisConfig
	JWT      JWTConfig
	Firebase FirebaseConfig
	R2 R2Config
	Sentry   SentryConfig
	CORS     CORSConfig
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

func parseDatabaseURL(databaseURL string) (*parsedDBConfig, error) {
	u, err := url.Parse(databaseURL)
	if err != nil {
		return nil, err
	}

	password, _ := u.User.Password()
	host, port, err := net.SplitHostPort(u.Host)
	if err != nil {
		host = u.Host
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
		DBName:   strings.TrimPrefix(u.Path, "/"),
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

	v.SetDefault("ADMIN_EMAIL", "admin@nomnom.lk")
	v.SetDefault("ADMIN_PASSWORD", "Admin@123")

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
		if err != nil {
			return nil, fmt.Errorf("failed to parse REDIS_URL: %w", err)
		}
		password, _ := u.User.Password()
		v.Set("REDIS_PASSWORD", password)
		host, port, err := net.SplitHostPort(u.Host)
		if err == nil {
			v.Set("REDIS_HOST", host)
			v.Set("REDIS_PORT", port)
		} else {
			v.Set("REDIS_HOST", u.Host)
		}
	}

	return &Config{
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
	}, nil
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
