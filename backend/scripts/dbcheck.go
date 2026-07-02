//go:build ignore

package main

import (
	"fmt"
	"net"
	"os"
	"time"

	"github.com/nomnom-lk/backend/internal/config"
	"github.com/nomnom-lk/backend/internal/database"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		fmt.Fprintf(os.Stderr, "config.Load error: %v\n", err)
		os.Exit(1)
	}

	fmt.Fprintf(os.Stderr, "[dbcheck] DATABASE_HOST=%s\n", cfg.Database.Host)
	fmt.Fprintf(os.Stderr, "[dbcheck] DATABASE_PORT=%s\n", cfg.Database.Port)
	fmt.Fprintf(os.Stderr, "[dbcheck] DATABASE_USER=%s\n", cfg.Database.User)
	fmt.Fprintf(os.Stderr, "[dbcheck] DATABASE_NAME=%s\n", cfg.Database.Name)

	addr := cfg.Database.Host + ":" + cfg.Database.Port
	fmt.Fprintf(os.Stderr, "[dbcheck] TCP dial to %s...\n", addr)

	conn, err := net.DialTimeout("tcp", addr, 5*time.Second)
	if err != nil {
		fmt.Fprintf(os.Stderr, "[dbcheck] TCP dial error: %v\n", err)
		os.Exit(1)
	}
	conn.Close()
	fmt.Fprintf(os.Stderr, "[dbcheck] TCP connection OK\n")

	dsn := cfg.Database.DSN()
	fmt.Fprintf(os.Stderr, "[dbcheck] DSN: %s\n", dsn)

	fmt.Fprintf(os.Stderr, "[dbcheck] Attempting GORM connection...\n")
	db := database.NewPostgresDB(&cfg.Database)
	fmt.Fprintf(os.Stderr, "[dbcheck] GORM connection OK\n")

	sqlDB, err := db.DB()
	if err != nil {
		fmt.Fprintf(os.Stderr, "[dbcheck] sql.DB error: %v\n", err)
		os.Exit(1)
	}

	err = sqlDB.Ping()
	if err != nil {
		fmt.Fprintf(os.Stderr, "[dbcheck] Ping error: %v\n", err)
		os.Exit(1)
	}
	fmt.Fprintf(os.Stderr, "[dbcheck] Ping OK\n")
}
