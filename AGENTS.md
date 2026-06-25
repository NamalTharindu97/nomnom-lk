## Goal
- Build a Go backend + admin dashboard + Flutter app for NomNom LK, a Sri Lanka-focused food offers discovery app.

## Constraints & Preferences
- **Stack:** Go + Gin + GORM + PostgreSQL 16 + Redis 7 + Firebase Auth + JWT + Sentry + Docker/Railway + Next.js 16 + Tailwind v4 + shadcn/ui + Flutter + Dio.
- **Build order & sign-off:** Phase-by-phase via feature branches (`phase/N-name`), merge to master after completion, branches preserved on remote.
- **Session context:** AGENTS.md updated and committed at end of every phase; read at session start to restore full context.
- **Architecture:** Standard struct-based DI; roles (user, restaurant_owner, admin); approval workflow (owner submits → admin approves); localization via JSONB translations; PostgreSQL full-text search; upload originals only; rate limiting (20 auth, 60 general, 10 upload).

## Progress
### Done
- **P1–P6:** See prior phases (Foundation, Auth, Core CRUD, Search, Upload, Notifications).
- **P7: Admin Dashboard** — Next.js 16 + Tailwind v4 + shadcn/ui. Pages: login, dashboard, restaurants (approve/reject), offers, users, push notifications. Auth context with localStorage JWT. Built on `phase/7-admin-dashboard`, merged to master.
- **P8: Flutter Integration** — Replaced mock services with API-backed services. New: `ApiClient` (Dio + JWT interceptor), `ApiAuthService` (Firebase + backend), `ApiOfferService`, `ApiFavoritesService`. Updated `Offer` model with `fromJson` (title, imageUrls, endDate, distanceKm), `AppUser` with `fromJson`. Updated providers, login screen (Firebase Google Sign-In), wired everything in `main.dart`. Firebase init graceful-fallback. `phase/8-flutter-integration` branch, merged to master.
- **Backend running & seeded:** Docker Compose (Postgres 16, Redis 7, MinIO) running. 5 restaurants + 5 offers seeded, all approved. Offers/restaurants/auth endpoints serving real data.
- **GORM text[] → JSONB fix:** pgx driver cannot scan PostgreSQL `text[]` into Go `[]string`. Created `models.JSONStringSlice` type with `Scan`/`Value` methods for JSON serialization. Columns `cuisine_tags` (restaurants) and `image_urls` (offers) altered to `jsonb`. Existing rows converted via `array_to_json()`.
- **P9: Theme & UI Refresh (admin)** — `ThemeProvider` context with light/dark/system toggle (localStorage key `nomnom-theme`), `@variant dark` Tailwind v4 directive, curry-orange brand palette. Redesigned login page (gradient BG, decorative blurs), dashboard overview (stat cards, recharts bar chart, quick actions). Sidebar includes theme toggle segmented button in footer. Sidebar CSS vars split into light/dark so sidebar follows the theme. No new npm packages.
- **P10: Backend Foundation Fixes** — `GET /users/me` endpoint for Flutter session restore; `restaurant.address` included in offer list responses; real Firebase Admin SDK initialization for token verification (graceful fallback if credentials absent); `GET /uploads/:key` route to serve uploaded files from MinIO; `UnregisterDevice` now accepts token param to remove single device; `locale.MergeTranslations` added to restaurant responses; SSE endpoint `GET /api/v1/events` for real-time data change events; SSE events emitted from all mutation handlers (create/update/delete/approve/reject for restaurants, offers, favorites). Branch: `phase/10-backend-foundation`

### Blocked
- (none)

## Key Decisions
- All phase branches (`phase/3-core-crud` through `phase/10-backend-foundation`) created and merged to master, preserved on remote.
- Firebase token verification uses real Firebase Admin SDK when credentials file is present; gracefully falls back to mock if absent (same pattern as FCM client).
- Flutter uses `dio` + `flutter_secure_storage` for API calls; Firebase Auth for Google Sign-In only (email/password goes directly to backend).
- Firebase init is wrapped in try-catch so app works without config files.
- `API_BASE_URL` env var configures backend URL (defaults to `http://localhost:8080/api/v1`).
- Backend entry point is `cmd/server/main.go` (NOT `cmd/api/main.go`).
- `[]string` fields use `models.JSONStringSlice` with JSONB storage instead of PostgreSQL `text[]` to avoid pgx driver incompatibility.
- `ThemeProvider` is a custom React context (not `next-themes`) to keep deps minimal.
- Brand palette: curry orange (`oklch 0.65 0.16 70`) primary, deep charcoal sidebar (`oklch 0.15` light / `oklch 0.08` dark).
- Offer create/edit uses a modal dialog (not separate page) reusing the same form component.
- Admin `GET /users` endpoint added at `backend/internal/handlers/user_handler.go` + `backend/internal/repository/user_repo.go`, requires admin role.

## Next Steps
- **Phase 11: Admin Dashboard Full CRUD** — Restaurant create/edit/delete forms; user management (role editing, soft-delete); pagination on all list pages; 401 intercept + auto-logout; toast error notifications; form validation (zod + react-hook-form); file upload for offer images; real dashboard stats endpoint; notification history list.
- **Phase 12: Flutter Full CRUD & Sync** — Fix favorites sync on startup; infinite scroll/pagination; backend search endpoint integration; restaurant list/detail screens; SSE client for real-time updates; offer detail API call; notification list screen; error states in providers.
- **Phase 13: Push Notifications End-to-End** — Add firebase_messaging to Flutter; device token registration; foreground/background notification handling; unread badge; admin notification sending to real FCM.
- **Phase 14: Admin UX Polish & Localization** — Translation fields in admin forms; translation-aware search; admin stats widgets; performance optimization.

## Relevant Files
- `backend/internal/models/types.go` — `JSONStringSlice` custom type for JSONB array storage.
- `backend/internal/models/restaurant.go` — `CuisineTags JSONStringSlice` with `gorm:"type:jsonb"`.
- `backend/internal/models/offer.go` — `ImageURLs JSONStringSlice` with `gorm:"type:jsonb"`.
- `backend/internal/dto/request/restaurant_request.go` — Uses `models.JSONStringSlice` for cuisine_tags.
- `backend/internal/dto/request/offer_request.go` — Uses `models.JSONStringSlice` for image_urls.
- `backend/internal/dto/request/notification_request.go` — `UnregisterDeviceRequest` with token binding.
- `backend/internal/repository/user_repo.go` — `FindAll(page, perPage)` for admin users list.
- `backend/internal/repository/device_token_repo.go` — `DeleteByToken(userID, token)` for per-device unregister.
- `backend/internal/handlers/user_handler.go` — `Me(c)` returning authenticated user, `List(c)` for admin.
- `backend/internal/handlers/restaurant_handler.go` — `restaurantToMap` and `restaurantDetailToMap` with `locale.MergeTranslations`.
- `backend/internal/handlers/offer_handler.go` — `offerToMap` includes `restaurant.address` in list responses.
- `backend/internal/handlers/favorite_handler.go`, `offer_handler.go`, `restaurant_handler.go` — SSE events emitted on mutation.
- `backend/internal/services/sse_service.go` — `SSEService` hub for broadcasting events to SSE clients.
- `backend/internal/services/firebase_service.go` — `FirebaseService` for real Firebase ID token verification.
- `admin/src/contexts/theme-context.tsx` — ThemeProvider with localStorage + system listener.
- `admin/src/app/dashboard/offers/_offer-dialog.tsx` — Modal form for create/edit offers.
