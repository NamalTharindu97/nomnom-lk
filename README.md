# NomNom LK

[![CI](https://github.com/NamalTharindu97/nomnom-lk/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/NamalTharindu97/nomnom-lk/actions/workflows/test.yml)

NomNom LK is a full-stack Sri Lankan food offers discovery platform. Users browse, search, and save deals from restaurants across Sri Lanka. Restaurant owners manage their own offers; admins oversee the platform.

## Tech Stack

| Layer | Stack |
|-------|-------|
| **Frontend** | Flutter + Dio + Provider + firebase_messaging |
| **Admin** | Next.js 16 + Tailwind v4 + shadcn/ui + react-hook-form + Zod |
| **Backend** | Go + Gin + GORM + PostgreSQL 16 + Redis 7 |
| **Auth** | Firebase Auth + JWT |
| **Storage** | MinIO (dev) / Cloudflare R2 (prod) |
| **MCP/SSE** | Real-time offer sync via Server-Sent Events |
| **Infra** | Docker + Render Blueprint |

## Architecture

- `backend/` — Go API server (Gin + GORM), `go run ./cmd/server` with Air hot reload
- `admin/` — Next.js dashboard for admins & restaurant owners
- `lib/` — Flutter mobile app (Android + iOS)
- `plans/` — Detailed phase plans for feature work

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for full architecture documentation.

---

## Prerequisites

- **Go** 1.22+
- **Node.js** 20+
- **Flutter** 3.29+
- **Docker Desktop** (for infra)
- **Firebase project** (optional, for auth/push)

---

## Quick Start

```bash
# 1. Start infrastructure (PostgreSQL 16, Redis 7, MinIO)
cd backend
docker compose up -d
cd ..

# 2. Seed database (first time only)
cd backend
go run ./scripts/seed.go
cd ..

# 3. Start backend (port 8080)
cd backend
make run

# 4. Start admin dashboard (port 3000)
cd admin
npm install
npm run dev

# 5. Run Flutter app on emulator
flutter run
```

**Default login:** `admin@nomnom.lk` / `Admin@123`
**Owner login:** `kfc@nomnom.lk` / `Owner@123`

---

## Backend Commands

```bash
cd backend

# Start infra (Postgres, Redis, MinIO)
docker compose up -d

# Stop infra
docker compose down

# Check infra status
docker compose ps

# Run backend with hot reload (requires Air)
make run

# Run backend without hot reload
go run ./cmd/server

# Build backend
go build ./cmd/server

# Run all tests
go test ./...

# Run unit tests only
go test ./internal/services/...
go test ./internal/middleware/...

# Seed database
go run ./scripts/seed.go

# Run database migrations
go run ./scripts/migrate.go

# Lint backend
golangci-lint run

# Security scan
govulncheck ./...
```

### Database Management

```bash
# Connect to PostgreSQL
psql -h localhost -p 5432 -U nomnom -d nomnom

# Default password: (check docker-compose.yml)

# View tables
\dt

# View offer count
SELECT COUNT(*) FROM offers;

# View restaurant count
SELECT COUNT(*) FROM restaurants;

# View banner stats
SELECT id, title, status, click_count FROM banners WHERE status = 'active';
```

---

## Admin Dashboard Commands

```bash
cd admin

# Install dependencies
npm install

# Start dev server (port 3000, with HMR)
npm run dev

# Build for production
npm run build

# Start production server
npm run start

# Lint
npm run lint

# Type check
npx tsc --noEmit

# Run unit tests
npx vitest run

# Run E2E tests (requires backend running)
npx playwright test

# Run specific E2E test
npx playwright test tests/offers.spec.ts

# Run E2E tests with UI
npx playwright test --ui

# View E2E test report
npx playwright show-report

# Check for security vulnerabilities
npm audit --audit-level=high
```

### E2E Test Accounts

| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@nomnom.lk` | `Admin@123` |
| Owner (KFC) | `kfc@nomnom.lk` | `Owner@123` |
| Owner (Pizza Hut) | `owner@nomnom.lk` | `Owner@123` |
| Owner (Subway) | `subway@nomnom.lk` | `Owner@123` |

---

## Flutter Commands

```bash
# List available devices
flutter devices

# List available emulators
flutter emulators

# Start a specific emulator
flutter emulators --launch Pixel_8_API_35

# Run on emulator
flutter run -d emulator-5554

# Run on connected device
flutter run

# Hot reload (while running)
# Press 'r' in the terminal

# Hot restart (while running)
# Press 'R' in the terminal

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build release AAB (for Play Store)
flutter build appbundle --release

# Build with custom API endpoint
flutter build apk --release \
  --dart-define=API_BASE_URL=https://your-api.onrender.com/api/v1

# Analyze code (find errors/warnings)
flutter analyze lib/

# Run all tests
flutter test

# Run specific test
flutter test test/banner_provider_test.dart

# Regenerate localization files
flutter gen-l10n

# Regenerate app icons
dart run flutter_launcher_icons

# Regenerate splash screen
dart run flutter_native_splash:create

# Clean build cache
flutter clean

# Get dependencies
flutter pub get

# Check for outdated dependencies
flutter pub outdated
```

### Android Emulator Commands

```bash
# Start emulator via command line
~/Library/Android/sdk/emulator/emulator -avd Pixel_8_API_35 &

# List running emulators
~/Library/Android/sdk/emulator/emulator -list-avds

# Install APK on emulator
~/Library/Android/sdk/platform-tools/adb install path/to/app.apk

# Check if app is running
~/Library/Android/sdk/platform-tools/adb shell pidof com.nomnomlk.nomnom_lk

# Take screenshot
~/Library/Android/sdk/platform-tools/adb shell screencap -p /sdcard/screenshot.png
~/Library/Android/sdk/platform-tools/adb pull /sdcard/screenshot.png .

# Clear app data
~/Library/Android/sdk/platform-tools/adb shell pm clear com.nomnomlk.nomnom_lk
```

---

## Release Build Commands

### Android Release

```bash
# Generate release keystore (one-time setup)
keytool -genkey -v \
  -keystore ~/.keystores/upload-keystore.jks \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -alias upload \
  -dname "CN=NomNom LK, OU=Development, O=NomNom, L=Colombo, ST=Western, C=LK"

# Copy and edit key.properties template
cp android/key.properties.example android/key.properties
# Edit android/key.properties with your keystore paths and passwords

# Build release AAB + APK
./scripts/build-android-release.sh

# Or build manually
flutter build appbundle --release
flutter build apk --release

# Build with production API
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://nomnom-lk-api.onrender.com/api/v1
```

### iOS Release (Future)

```bash
# Build iOS release
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://nomnom-lk-api.onrender.com/api/v1

# Open in Xcode for archiving
open ios/Runner.xcworkspace
```

---

## Testing Commands

```bash
# === Backend Tests ===
cd backend
go test ./...                    # All tests
go test ./internal/middleware/    # Middleware tests
go test ./internal/services/      # Service tests
go test -v ./...                  # Verbose output
go test -coverprofile=coverage.txt ./...  # With coverage

# === Admin Unit Tests ===
cd admin
npx vitest run                   # All unit tests
npx vitest run --coverage        # With coverage

# === Admin E2E Tests ===
cd admin
npx playwright test              # All E2E tests (53 tests)
npx playwright test --reporter=list  # List reporter
npx playwright test tests/offers.spec.ts  # Single test file
npx playwright test -g "should create"   # By test name

# === Flutter Tests ===
flutter test                     # All tests (20 tests)
flutter test test/banner_provider_test.dart  # Single test
flutter test --coverage         # With coverage
```

---

## Deployment Commands

### Render.com Deployment

```bash
# 1. Push to GitHub
git push origin master

# 2. Connect repo to Render Dashboard
# - Go to https://dashboard.render.com
# - New > Blueprint
# - Connect GitHub repo
# - Render detects render.yaml

# 3. Set environment variables in Render Dashboard:
#    DATABASE_URL, REDIS_URL, MINIO_*, JWT_SECRET,
#    FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY

# 4. Verify deployment
curl https://your-app.onrender.com/health

# === Deploy Admin Dashboard ===
# Render auto-deploys from render.yaml
# Admin URL: https://your-admin.onrender.com

# === Deploy Backend ===
# Render auto-deploys from render.yaml
# Backend URL: https://your-api.onrender.com
```

---

## API Endpoints

```bash
# Health check
curl http://localhost:8080/health

# Login
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@nomnom.lk","password":"Admin@123"}'

# Get restaurants
curl http://localhost:8080/api/v1/restaurants

# Get offers
curl http://localhost:8080/api/v1/offers

# Get active banners
curl http://localhost:8080/api/v1/banners/active

# Dashboard stats (requires admin/owner JWT)
curl -H "Authorization: Bearer <token>" \
  http://localhost:8080/api/v1/dashboard/stats
```

---

## Git Workflow

```bash
# Create feature branch
git checkout -b phase/P39-feature-name

# Stage and commit
git add -A
git commit -m "P39: Feature description"

# Push branch
git push origin phase/P39-feature-name

# Merge to master (after review)
git checkout master
git merge phase/P39-feature-name --no-ff -m "Merge phase/P39-feature-name"

# Push master
git push origin master

# Keep branch on remote for reference
```

---

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SERVER_PORT` | Backend port | `8080` |
| `PORT` | Cloud port (Render/Heroku) | fallback |
| `DATABASE_URL` | PostgreSQL connection | `postgres://nomnom:nomnom@localhost:5432/nomnom?sslmode=disable` |
| `REDIS_URL` | Redis connection | `redis://localhost:6379` |
| `JWT_SECRET` | JWT signing key | `dev-secret` |
| `API_BASE_URL` | Flutter API endpoint | `http://10.0.2.2:8080/api/v1` |

---

## Default Ports

| Service | Port |
|---------|------|
| Backend API | `8080` |
| Admin Dashboard | `3000` |
| PostgreSQL | `5432` |
| Redis | `6379` |
| MinIO API | `9000` |
| MinIO Console | `9001` |
| Flutter (debug) | varies |

---

## Troubleshooting

```bash
# Backend won't start — check if port is in use
lsof -i :8080

# Kill process on port
kill -9 $(lsof -t -i :8080)

# Database connection refused — restart Docker
cd backend && docker compose restart

# Flutter build fails — clean and rebuild
flutter clean && flutter pub get

# Admin build fails — clear Next.js cache
cd admin && rm -rf .next && npm run build

# E2E tests fail — ensure backend is running
cd backend && go run ./cmd/server &
cd admin && npx playwright test
```

---

## Obsidian Knowledge Base

The project root is an Obsidian vault. Open it in Obsidian to browse and link documentation.

### Setup

```bash
brew install --cask obsidian  # macOS
# Or download from https://obsidian.md
```

1. Open Obsidian
2. Select **Open folder as vault**
3. Open the project root: `/Users/namal/dev/MobileApps/NomNom LK`
4. Start from `docs/Home.md`

### Structure

| Path | Purpose |
|------|---------|
| `docs/Home.md` | Dashboard — start here |
| `docs/Plans Index.md` | All implementation plans |
| `docs/Decisions Index.md` | Architecture decisions |
| `docs/Inbox.md` | Quick capture |
| `docs/templates/` | Reusable templates |
| `docs/decisions/` | Decision records |
| `docs/notes/` | Research and investigations |
| `AGENTS.md` | Current project status |
| `README.md` | Commands and setup |
| `ARCHITECTURE.md` | System design |
| `plans/` | Implementation plans |

### Templates

| Template | Use for |
|----------|---------|
| Project Note | Feature work, research, investigations |
| Decision | Architecture or technical choices |
| Bug Investigation | Complex defect tracking |
| Meeting Note | Meeting notes and action items |

### Workflow

1. Open `docs/Home.md` to navigate the project
2. Capture quick ideas in `docs/Inbox.md`
3. Use templates for structured documentation
4. Move completed items to proper locations
5. Keep `AGENTS.md` updated for official project status

### Notes

- `.obsidian/` is git-ignored (personal settings)
- All notes use standard Markdown links (works in GitHub too)
- Never commit secrets, tokens, or credentials
