package config

import (
	"github.com/spf13/viper"
)

type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	Redis    RedisConfig
	JWT      JWTConfig
	Firebase FirebaseConfig
	AWS      AWSConfig
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

type AWSConfig struct {
	Region          string
	AccessKeyID     string
	SecretAccessKey string
	S3Bucket        string
	S3Endpoint      string
	ForcePathStyle  bool
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

func Load() (*Config, error) {
	v := viper.New()
	v.AutomaticEnv()
	v.SetEnvPrefix("")

	v.SetConfigFile(".env")
	if err := v.MergeInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, err
		}
	}

	v.SetDefault("SERVER_PORT", "8080")
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

	v.SetDefault("AWS_REGION", "ap-southeast-1")
	v.SetDefault("AWS_ACCESS_KEY_ID", "minioadmin")
	v.SetDefault("AWS_SECRET_ACCESS_KEY", "minioadmin")
	v.SetDefault("AWS_S3_BUCKET", "nomnom-images")
	v.SetDefault("AWS_S3_ENDPOINT", "localhost:9000")
	v.SetDefault("AWS_S3_FORCE_PATH_STYLE", true)

	v.SetDefault("SENTRY_DSN", "")

	v.SetDefault("CORS_ORIGINS", "http://localhost:3000,http://localhost:8080")

	v.SetDefault("ADMIN_EMAIL", "admin@nomnom.lk")
	v.SetDefault("ADMIN_PASSWORD", "Admin@123")

	v.SetDefault("SMTP_HOST", "")
	v.SetDefault("SMTP_PORT", 587)
	v.SetDefault("SMTP_USERNAME", "")
	v.SetDefault("SMTP_PASSWORD", "")
	v.SetDefault("SMTP_FROM", "NomNom LK <noreply@nomnom.lk>")

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
		AWS: AWSConfig{
			Region:          v.GetString("AWS_REGION"),
			AccessKeyID:     v.GetString("AWS_ACCESS_KEY_ID"),
			SecretAccessKey: v.GetString("AWS_SECRET_ACCESS_KEY"),
			S3Bucket:        v.GetString("AWS_S3_BUCKET"),
			S3Endpoint:      v.GetString("AWS_S3_ENDPOINT"),
			ForcePathStyle:  v.GetBool("AWS_S3_FORCE_PATH_STYLE"),
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
