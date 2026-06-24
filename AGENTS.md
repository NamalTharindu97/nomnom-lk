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
- **P9: Theme & UI Refresh (admin)** — `ThemeProvider` context with light/dark/system toggle (localStorage key `nomnom-theme`), `@variant dark` Tailwind v4 directive, curry-orange brand palette. Redesigned login page (gradient BG, decorative blurs), dashboard overview (stat cards, recharts bar chart, quick actions). Sidebar includes theme toggle segmented button in footer. No new npm packages.

### Blocked
- (none)

## Key Decisions
- All phase branches (`phase/3-core-crud` through `phase/9-theme-ui-refresh`) created and merged to master, preserved on remote.
- Firebase token verification still mocked on backend (real Firebase Admin SDK init deferred).
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
- **Run Flutter app** on the booted iOS simulator (`flutter run`).
- **Start admin dashboard** (`npm run dev` in `admin/`).
- **End-to-end testing:** Run backend + Flutter app + admin dashboard against the same API.
- **Firebase setup:** Add `GoogleService-Info.plist` (iOS) and `google-services.json` (Android) from Firebase Console, then run `flutterfire configure`.
- **Push notifications:** Connect Flutter device token registration to backend `/devices` endpoint.
- **Pagination & infinite scroll** in Flutter offer lists.
- **Localization** using the backend's JSONB translations.
- **Offer image upload** from admin dashboard (currently accepts URL strings only).
- **Real backend aggregate endpoint** for dashboard chart data (currently uses sample data).

## Relevant Files
- `backend/internal/models/types.go` — `JSONStringSlice` custom type for JSONB array storage.
- `backend/internal/models/restaurant.go` — `CuisineTags JSONStringSlice` with `gorm:"type:jsonb"`.
- `backend/internal/models/offer.go` — `ImageURLs JSONStringSlice` with `gorm:"type:jsonb"`.
- `backend/internal/dto/request/restaurant_request.go` — Uses `models.JSONStringSlice` for cuisine_tags.
- `backend/internal/dto/request/offer_request.go` — Uses `models.JSONStringSlice` for image_urls.
- `backend/internal/repository/user_repo.go` — `FindAll(page, perPage)` for admin users list.
- `backend/internal/handlers/user_handler.go` — `List(c)` returning paginated users.
- `admin/src/contexts/theme-context.tsx` — ThemeProvider with localStorage + system listener.
- `admin/src/app/dashboard/offers/_offer-dialog.tsx` — Modal form for create/edit offers.
