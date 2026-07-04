## Goal
- Go backend + admin dashboard + Flutter app for NomNom LK, a Sri Lankan food offers discovery app.
- Detail plans in `plans/`: `backend-plan.md`, `flutter-plan.md`, `admin-plan.md`, `devops-plan.md`, `fixes-plan.md`.

## Constraints & Preferences
- **Stack:** Go + Gin + GORM + PostgreSQL 16 + Redis 7 + MinIO + Firebase Auth + FCM + JWT + Sentry + Docker/Railway + Next.js 16 + Tailwind v4 + shadcn/ui + Flutter + Dio + firebase_messaging.
- **Build order & sign-off:** Phase-by-phase via feature branches (`phase/N-name`), merge to master after approval, branches preserved on remote.
- **Architecture:** Standard struct-based DI; roles (user, restaurant_owner, admin); approval workflow; localization via JSONB translations (`Translations` type alias `map[string]map[string]string` stored in JSONB column).
- **Docker for infra only:** Postgres 16, Redis 7, MinIO via `docker compose up -d` in `backend/`. Backend runs natively with `make run`.
- **Firebase graceful fallback:** Both Firebase Auth + FCM client log warning and return nil if credentials file absent.
- **Theme:** Custom `ThemeProvider` (localStorage key `nomnom-theme`), curry-orange brand palette, sidebar CSS vars theme-aware.
- **Toast notifications:** `@radix-ui/react-toast` with custom `ToastProvider` + `notify()` in admin.
- **Pagination:** Shared `PaginationBar` component in admin, infinite scroll in Flutter.
- **Form validation:** `react-hook-form` + `zod` + `@hookform/resolvers` in admin OfferDialog.
- **Build tags:** `//go:build seed` and `//go:build migration` on script files to avoid `main()` conflict in `go build ./...`.
- **Flutter rebuild required:** After every Flutter code change, rebuild and re-run the app.
- **Air for Go hot reload:** Backend uses `air`; admin uses next dev HMR; Flutter runs in debug mode.
- **Not yet:** Flutter localization, full offline support.

## Key Decisions
- **Git workflow:** Feature branches (`phase/N-name`) only — commit, push branch, create PR. Never push directly to `origin/master`.
- **App icon generation:** Use exact Material Design SVG path from Google Fonts CDN (`fonts.gstatic.com/s/i/materialiconsround/...`), render with cairosvg at 1024×1024, then run `flutter_launcher_icons`.
- **Login typography hierarchy (research-based):** Brand name (`headlineMedium` 28px w900) → tagline (`titleMedium` 16px w600 muted) → divider/footer (`titleSmall` 14px w500 muted). Based on DoorDash (28pt → 13pt) and Uber Eats (30pt → 13pt) cascading hierarchy.
- **SSE for real-time sync:** Chose Server-Sent Events over WebSocket for simpler server→client streaming.
- **SSE header flush:** Call `c.Writer.WriteHeader(http.StatusOK)` + `c.Writer.Flush()` before `c.Stream()`.
- **SSE parser no-space colons:** Gin writes `event:eventName` (no space). Flutter parser uses `startsWith('event:')` + `.trim()`.
- **SSE forceRefresh for restaurants:** `RestaurantProvider.loadRestaurants()` guard skips reload without `forceRefresh: true`.
- **Firebase graceful fallback:** Both Auth and FCM init from credentials file, skip if missing, log warning.
- **Rate limiter:** In-memory per-user `rateLimiter` with `sync.Mutex` for `POST /admin/notifications/push` — 10s cooldown.
- **Stale token cleanup:** `strings.Contains()` for `"NotRegistered"`/`"UNREGISTERED"`/`"Unregistered"`; delete via `DeleteByTokenValue`.
- **firebase_messaging:** Pinned to `^15.2.10` for compatibility with `firebase_core ^3.6.0`.
- **Android minSdk:** 23 for Firebase Auth compat. Core library desugaring enabled.
- **Notification tap nav:** All three tap scenarios route to home via `onNavigate` callback.
- **`.env` inline comments:** Viper v1.19.0 parses `# comment` as part of value.
- **MinIO endpoint format:** minio-go v7.2.0 rejects `http://` scheme or path components — use bare `host:port`.

## Critical Context
- All branches P1–P20 merged to master and preserved on remote.
- Backend on `:8080`, admin on `:3000`, Flutter on Android emulator (API 35).
- Docker services (postgres 16, redis 7, minio) running with seeded data (8 restaurants, 18 offers).
- Backend FCM via direct HTTP to FCM v1 API using `cloud-platform` OAuth2 scope. No Firebase Admin SDK.
- **Android google-services plugin** required for Firebase to work on Android.
- Admin user: `namal@nomnom.lk` / `Namal@123` (role = admin).

## Relevant Files
### Backend
- `backend/internal/handlers/` — admin, user, notification, offer, restaurant, upload handlers
- `backend/internal/services/` — FCM via direct HTTP (`notification_service.go`), translations (`translation_service.go`), SSE (`sse_service.go`)
- `backend/internal/repository/` — offer, restaurant, notification, device_token repos
- `backend/internal/database/postgres.go` — `runIndexMigrations()` for composite + partial indexes
- `backend/internal/router/router.go` — all routes
- `backend/internal/models/` — `Translations *json.RawMessage`
- `backend/internal/dto/request/` — request DTOs
- `backend/scripts/` — seed.go, migrate.go (build-tagged)
- `backend/.air.toml` — Air hot reload config

### Admin Dashboard
- `admin/src/lib/api.ts` — 401 auto-logout interceptor, upload
- `admin/src/components/ui/` — toast, pagination-bar
- `admin/src/app/dashboard/` — page.tsx, restaurants/, offers/, users/, notifications/
- `admin/src/app/dashboard/offers/_offer-dialog.tsx` — Zod + react-hook-form
- `admin/src/app/dashboard/restaurants/_restaurant-dialog.tsx` — cover image upload + translation fields
- `admin/tests/` — Playwright E2E tests (restaurant CRUD)

### Flutter
- `lib/services/` — api_client (cache interceptor), api_offer_service, api_restaurant_service, api_notification_service, sse_service, fcm_messaging_service
- `lib/providers/` — offer, restaurant, notification, auth providers
- `lib/screens/` — home, search, favorites, restaurants, notifications
- `lib/widgets/` — shimmer_loading, empty_state
- `lib/models/` — paginated_response, restaurant, offer
- `lib/main.dart` — `_FcmInitializer` + `_SseListener` widgets
- `lib/core/` — api_config, app_routes

## Recent Work
- **2026-07-04:** P21-P28 completed and merged to master.
  - P21 (UX Foundation): AlertDialog, Skeleton, TableSkeleton, EmptyState, ErrorBoundary; search/filter bars; backend user email+role filters.
  - P22 (CRUD Completion): User creation dialog; restaurant owner dropdown; cover image preview; image drag-and-drop reordering; date range selector.
  - P23 (Settings & Audit Log): AuditLog model/repo/handler; ChangePassword endpoint; settings page; audit log page.
  - P24 (Bulk Actions & Export): Checkbox selection; bulk approve/reject/delete; CSV export; restaurant detail page.
  - P25 (Analytics): Analytics page with top restaurants/offers charts, user growth, offer stats.
  - P26 (Notification Enhancements): Templates CRUD; template picker; scheduled notifications; notification analytics.
  - P27 (Advanced Features): Coupons CRUD (activate/deactivate); categories CRUD; force-expire offers; publish_at field.
  - P28 (Admin Optimization): CSS vars (--success, --info, --chart-1..5); theme-aware overlays & toasts; shared csvExport & BulkActionBar components; raw textarea → Textarea; login theme toggle; 11 Vitest unit tests; 14 new Playwright E2E tests; CI pipeline green (all 43 E2E passing).
  - `gh` CLI authenticated for CI log access.
  - All branches P21–P28 preserved on remote.
