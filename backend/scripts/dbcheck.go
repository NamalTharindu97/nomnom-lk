//go:build ignore

package main

import (
	"fmt"
	"net"
	"os"
	"time"

	"github.com/nomnom-lk/backend/internal/config"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		fmt.Fprintf(os.Stderr, "config.Load error: %v\n", err)
		os.Exit(1)
	}

	addr := cfg.Database.Host + ":" + cfg.Database.Port
	fmt.Fprintf(os.Stderr, "Attempting TCP connection to %s...\n", addr)

	conn, err := net.DialTimeout("tcp", addr, 5*time.Second)
	if err != nil {
		fmt.Fprintf(os.Stderr, "TCP dial error: %v\n", err)
		os.Exit(1)
	}
	conn.Close()
	fmt.Fprintf(os.Stderr, "TCP connection OK\n")

	dsn := cfg.Database.DSN()
	fmt.Fprintf(os.Stderr, "DSN would be: host=%s port=%s user=%s dbname=%s sslmode=%s\n",
		cfg.Database.Host, cfg.Database.Port, cfg.Database.User, cfg.Database.Name, cfg.Database.SSLMode)
	_ = dsn

	fmt.Println("Config loaded successfully, database seems reachable")
}
