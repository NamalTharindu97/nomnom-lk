# DevOps Plan

## P16 — Dev Environment: Background Processes + Hot Reload
- Backend auto-restart via `air` (Go hot reload, configured in `backend/.air.toml`)
- Admin dashboard runs with `next dev` (HMR built-in)
- Flutter runs on simulator in debug mode
- All three run as background `nohup` processes with logs routed to `*/logs/*.log`
- `.gitignore` updated to exclude log dirs

## Docker Infrastructure
- Postgres 16, Redis 7, MinIO via `docker compose up -d` in `backend/`
- Backend runs natively with `make run` (not in Docker)

## Air Hot Reload
- `air` installed via `go install github.com/air-verse/air@latest`
- Config at `backend/.air.toml` watches `.go`/`.html`/`.tpl`/`.tmpl` changes
- Binary built to `backend/tmp/nomnom-api`

## MinIO Configuration (Local Dev)
- Endpoint format: bare `host:port` only (e.g. `localhost:9000`) — minio-go v7.2.0 `New()` rejects fully qualified endpoints
- No `http://` scheme or path components
- Bucket: `nomnom-images`

## Environment Variables
- `.env` is gitignored
- Viper v1.19.0 does not strip inline `# comments` from `.env` values — parsed as part of the value string
- `R2_ENDPOINT=localhost:9000` (no scheme, no trailing comment)

## iOS Physical Device Testing
- Flutter 3.29.3 debug mode crashes on iOS 26.5+ physical devices (known JIT issue)
- Profile/release mode install issues via `devicectl`
- Workaround: Build release `.app` and install via `ios-deploy` (Homebrew tool)
- `DEVELOPMENT_TEAM = GBBV66G8DH` persisted in `project.pbxproj` for future iOS builds
- iOS push notifications require paid Apple Developer Account ($99/yr) for APNs entitlement
- `Runner.entitlements` with `aps-environment = development` required for APNs token

## Google Sign-In (Android)
- Not yet working — missing SHA-1 fingerprint in Firebase Console
- Steps to fix:
  1. Run `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1`
  2. Add to Firebase Console → Project Settings → General → Android app → Add fingerprint
  3. Verify Google Sign-In enabled in Authentication → Sign-in methods
  4. Rebuild and test on Android emulator

## Scripts & Build
- Build tags: `//go:build seed` and `//go:build migration` on script files to avoid `main()` conflict in `go build ./...`
- `air` config watches `.go`/`.html`/`.tpl`/`.tmpl`

## Deployment (Render.com Free Plan)

### Architecture on Render

```
                         ┌──────────────┐
                         │  Admin UI     │
                         │  Web Service  │
                         │  (Free)       │
                         └──────┬───────┘
                                │ rewrites proxy /api/v1/*
                         ┌──────┴───────┐
                         │  Go API      │
                         │  Web Service │
                         │  (Free)      │
                         └──────┬───────┘
                                │
    ┌───────────────────────────┼───────────────────────┐
    │                           │                       │
┌───┴──────────┐      ┌────────┴───────┐       ┌──────┴──────┐
│ PostgreSQL   │      │    Redis KV    │       │ Cloudflare  │
│ Render Free  │      │   Render Free  │       │   R2 Free   │
│ (1GB, 30day) │      │   (in-memory)  │       │ (10GB, no   │
└──────────────┘      └────────────────┘       │  egress)    │
                                               └─────────────┘
```

### Free Plan Constraints

| Constraint | Impact |
|---|---|
| 750 instance hours/month per workspace | Shared across all services. Realistic usage ~360h/month for personal dev |
| Services sleep after 15min idle | ~1min cold start on first request after idle |
| No persistent disks | Data lost on restart/deploy |
| 1 free PostgreSQL (30-day expiry) | Need to upgrade or migrate after 30 days |
| 1 free Redis KV (in-memory) | Data lost on restart. Fine for sessions/cache |
| No private network for free web services | Backend connects to MinIO/R2 via public URL |
| 5GB outbound bandwidth/month | Sufficient for personal project |

### CI Pipeline (GitHub Actions)

CI runs on every push to master/phase branches:
1. **Backend** — Go unit + integration tests (with Postgres/Redis/MinIO service containers)
2. **Admin** — Build + Playwright E2E tests (with backend service containers)
3. **Flutter** — Analyze + unit/widget tests
4. **Docker** — Build & push `namal97/nomnom-backend` and `namal97/nomnom-admin` to Docker Hub (master only)

Docker images tagged `:latest` + `:{short-sha}`.

### render.yaml Blueprint

The `render.yaml` at repo root defines:

- **nomnom-backend** — Web Service (Free), pulls `namal97/nomnom-backend:latest`
- **nomnom-admin** — Web Service (Free), pulls `namal97/nomnom-admin:latest`
- **nomnom-redis** — Redis KV (Free)
- **nomnom-db** — PostgreSQL (Free)

Cloudflare R2 credentials and ADMIN_PASSWORD set as `sync: false` (prompted during Blueprint setup).

### External Storage: Cloudflare R2

Images stored in Cloudflare R2 (S3 API compatible):

| Feature | R2 Free Tier |
|---|---|
| Storage | 10 GB |
| Class A ops (writes) | 1 million/month |
| Class B ops (reads) | 10 million/month |
| Egress | Free (no charges) |

`minio-go` client connects to R2 — no code changes needed.

### First-time Deploy

```bash
# 1. Push to master → CI builds & pushes Docker images
git push origin master

# 2. Render Dashboard → New → Blueprint → Connect repo
#    Select render.yaml from repo root

# 3. Set sync:false env vars in Render Dashboard:
#    - R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY
#    - R2_ENDPOINT (https://<account>.r2.cloudflarestorage.com)
#    - ADMIN_PASSWORD
#    - Upload firebase-credentials.json as secret file
```
