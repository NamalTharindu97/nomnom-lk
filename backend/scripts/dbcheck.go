//go:build ignore

package main

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/nomnom-lk/backend/internal/config"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		fmt.Fprintf(os.Stderr, "[dbcheck] config.Load error: %v\n", err)
		os.Exit(1)
	}

	fmt.Fprintf(os.Stderr, "[dbcheck] DATABASE_HOST=%s\n", cfg.Database.Host)
	fmt.Fprintf(os.Stderr, "[dbcheck] DATABASE_PORT=%s\n", cfg.Database.Port)
	fmt.Fprintf(os.Stderr, "[dbcheck] DATABASE_USER=%s\n", cfg.Database.User)
	fmt.Fprintf(os.Stderr, "[dbcheck] DATABASE_NAME=%s\n", cfg.Database.Name)
	fmt.Fprintf(os.Stderr, "[dbcheck] DATABASE_SSLMODE=%s\n", cfg.Database.SSLMode)

	pgURL := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s&connect_timeout=5",
		cfg.Database.User, cfg.Database.Password,
		cfg.Database.Host, cfg.Database.Port,
		cfg.Database.Name, cfg.Database.SSLMode)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, pgURL)
	if err != nil {
		fmt.Fprintf(os.Stderr, "[dbcheck] pgxpool.New error: %v\n", err)
		os.Exit(1)
	}
	defer pool.Close()

	err = pool.Ping(ctx)
	if err != nil {
		fmt.Fprintf(os.Stderr, "[dbcheck] Ping error: %v\n", err)
		os.Exit(1)
	}

	fmt.Fprintf(os.Stderr, "[dbcheck] Database connection OK\n")
}
