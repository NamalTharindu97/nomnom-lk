# P37 — Pre-Deployment: DATABASE_URL/REDIS_URL Compatibility + CI Badge

## Goal
Remove two hard blockers preventing Render deployment: (1) backend config cannot parse the single `DATABASE_URL` / `REDIS_URL` connection strings that Render's managed services provide, and (2) add a CI status badge to the repo README.

---

## Current State

### Database Configuration
`backend/internal/config/config.go` reads individual env vars:

```go
DatabaseHost     string // DATABASE_HOST
DatabasePort     string // DATABASE_PORT
DatabaseUser     string // DATABASE_USER
DatabasePassword string // DATABASE_PASSWORD
DatabaseName     string // DATABASE_NAME
DatabaseSSLMode  string // DATABASE_SSLMODE
```

Render's `render.yaml` injects a single `DATABASE_URL` connection string:
```
postgres://nomumnom_user:randompassword@dpg-xxxxx.oregon-postgres.render.com:5432/nomnom_db?sslmode=require
```

If `DATABASE_URL` is present but unparsed, `DatabaseHost` stays empty and the backend fails to connect with a "host is not specified" error.

Same problem exists for `REDIS_URL`:
```
rediss://red-xxxxx.oregon-redis.render.com:6379
```

### CI Badge
The repo README has no CI status badge, making it harder to see build status at a glance.

---

## Phase 1 — DATABASE_URL Parser in Config

### File Changes

#### `backend/internal/config/config.go`

**Step 1: Add new fields to Config struct**

Add after existing Database fields:
```go
// DatabaseURL is an alternative to individual DATABASE_* fields.
// Render provides a single postgres:// connection string.
DatabaseURL string

// RedisURL is an alternative to individual REDIS_* fields.
// Render provides a single redis:// connection string.
RedisURL string
```

**Step 2: Bind env vars in `Load()`**

Add alongside existing Viper bindings:
```go
viper.BindEnv("DATABASE_URL")
viper.BindEnv("REDIS_URL")
```

**Step 3: Add `parseDatabaseURL()` method**

```go
import "net/url"

// parseDatabaseURL parses a DATABASE_URL connection string into individual fields.
// Called during Load() when DATABASE_URL is set.
// Format: postgres://user:pass@host:port/dbname?sslmode=require
func (c *Config) parseDatabaseURL() error {
    if c.DatabaseURL == "" {
        return nil
    }

    u, err := url.Parse(c.DatabaseURL)
    if err != nil {
        return fmt.Errorf("failed to parse DATABASE_URL %q: %w", c.DatabaseURL, err)
    }

    password, _ := u.User.Password()

    c.DatabaseHost = u.Hostname()
    c.DatabasePort = u.Port()
    c.DatabaseUser = u.User.Username()
    c.DatabasePassword = password
    c.DatabaseName = strings.TrimPrefix(u.Path, "/")

    if q := u.Query(); q.Has("sslmode") {
        c.DatabaseSSLMode = q.Get("sslmode")
    }

    return nil
}
```

**Step 4: Add `parseRedisURL()` method**

```go
// parseRedisURL parses a REDIS_URL connection string into individual fields.
// Format: redis://:password@host:port  or  rediss://:password@host:port
func (c *Config) parseRedisURL() error {
    if c.RedisURL == "" {
        return nil
    }

    u, err := url.Parse(c.RedisURL)
    if err != nil {
        return fmt.Errorf("failed to parse REDIS_URL %q: %w", c.RedisURL, err)
    }

    password, _ := u.User.Password()

    c.RedisHost = u.Hostname()
    c.RedisPort = u.Port()
    c.RedisPassword = password

    return nil
}
```

**Step 5: Call parsers at end of `Load()`**

```go
func Load() (*Config, error) {
    // ... existing Viper setup and binding ...

    var cfg Config
    // ... existing unmarshal ...

    if err := cfg.parseDatabaseURL(); err != nil {
        return nil, err
    }
    if err := cfg.parseRedisURL(); err != nil {
        return nil, err
    }

    return &cfg, nil
}
```

### Edge Cases Handled

| Edge case | How handled |
|-----------|-------------|
| Password with special chars (`@`, `:`, `#`) | `url.Parse` percent-decodes, `User.Password()` returns decoded value |
| IPv6 host | `Hostname()` handles `[::1]` bracket notation |
| No password | `User.Password()` returns empty string, `password` stays empty |
| No port in URL | `Port()` returns empty string — existing code defaults to `5432` or `6379` |
| `postgres://` vs `postgresql://` | Both accepted by `url.Parse` (scheme is not validated here) |
| `redis://` vs `rediss://` (TLS) | `rediss://` is parsed same as `redis://` — TLS is handled at connection level, not URL level |
| `sslmode` not in query | `q.Has("sslmode")` returns false, field keeps its default |
| `DATABASE_URL` not set | `parseDatabaseURL()` returns nil immediately |

### No New Dependencies
Uses only `net/url` from the Go standard library.

---

## Phase 2 — CI Badge in README

### File Changes

#### `README.md`

Add at the top, after the project title:

```markdown
![CI](https://github.com/NamalTharindu97/nomnom-lk/actions/workflows/test.yml/badge.svg)
```

If the README already has a header section, place it inline with the title or on its own line after the first heading.

---

## Verification

### Local Test with Connection Strings

```bash
# From backend directory
DATABASE_URL="postgres://nomnom:nomnom123@localhost:5432/nomnom?sslmode=disable" \
REDIS_URL="redis://:password@localhost:6379" \
go run ./cmd/server/main.go

# In another terminal, verify health
curl -s http://localhost:8080/health
# Expected: {"database":{"status":"connected"},"redis":{"status":"connected"},"status":"ok",...}
```

### Test with Individual Fields (Regression)

```bash
# Should still work as before
go run ./cmd/server/main.go
curl -s http://localhost:8080/health
# Same expected output
```

---

## File Change Summary

| File | Change Type | Lines Changed |
|------|-------------|---------------|
| `backend/internal/config/config.go` | Modify | ~+50 |
| `README.md` | Modify | ~+1 |

**Total: 2 files, ~+51 lines**

## Implementation Order

1. Add `DatabaseURL` + `RedisURL` fields to Config struct
2. Add Viper binding in `Load()`
3. Implement `parseDatabaseURL()` method
4. Implement `parseRedisURL()` method
5. Call both at end of `Load()`
6. Add CI badge to README
7. Verify with both connection-string and individual-field modes

## Rollback Plan
- Revert the `config.go` changes — the existing individual field code path is untouched, so removing the new code restores original behavior
- Revert the README change
