## Goal
- Build a Go backend + admin dashboard + Flutter app for NomNom LK, a Sri Lanka-focused food offers discovery app.

## Constraints & Preferences
- **Stack:** Go + Gin + GORM + PostgreSQL 16 + Redis 7 + MinIO + Firebase Auth + JWT + Sentry + Docker/Railway + Next.js 16 + Tailwind v4 + shadcn/ui + Flutter + Dio.
- **Build order & sign-off:** Phase-by-phase via feature branches (`phase/N-name`), merge to master after completion, branches preserved on remote.
- **Session context:** AGENTS.md updated and committed at end of every phase; read at session start to restore full context.
- **Architecture:** Standard struct-based DI; roles (user, restaurant_owner, admin); approval workflow (owner submits → admin approves); localization via JSONB translations; PostgreSQL full-text search; upload originals only; rate limiting (20 auth, 60 general, 10 upload).

## Progress
### Done
- **P1–P6:** See prior phases (Foundation, Auth, Core CRUD, Search, Upload, Notifications).
- **P7: Admin Dashboard** — Initial build. Merged to master.
- **P8: Flutter Integration** — API-backed services, Firebase Google Sign-In. Merged to master.
- **P9: Theme & UI Refresh (admin)** — ThemeProvider, curry-orange palette, login redesign. Merged to master.
- **P10: Backend Foundation Fixes** — `/users/me`, Firebase Admin SDK, upload serving, SSE, translation merging. Merged to master.
- **P11: Admin Dashboard Full CRUD** — Branch `phase/11-admin-full-crud`, committed. Changes:
  - **Backend:** `GET /admin/stats` endpoint (restaurant/offer/user counts, pending counts), `GET /admin/notifications` (all-notifications list with user names), `PUT /users/:id` (role/name editing), `DELETE /users/:id` (soft-delete). New `admin_handler.go` with `Stats` and `ListNotifications`. Count methods added to restaurant/offer/user repos. Build tags (`//go:build seed` / `//go:build migration`) on scripts to allow `go build ./...`. Makefile updated with `-tags`.
  - **Admin Dashboard:** 401 auto-logout in `api.ts` (interceptor clears localStorage + redirects). New `ToastProvider` using `@radix-ui/react-toast` with `notify()` function for success/error messages. Dashboard uses real `/admin/stats` endpoint with 4 stat cards (Restaurants, Offers, Users, Pending Reviews). Restaurant CRUD: new `_restaurant-dialog.tsx` modal (name/slug/address/phone/cuisine/description), edit/delete buttons with pagination (`PaginationBar` component). User management: role editing dropdown, soft-delete button, pagination. Offers: pagination, zod+react-hook-form validation on OfferDialog, file upload support via `/upload/multiple`. Notifications: new history table with pagination from `/admin/notifications`. Scripts fixed with build tags to avoid redeclared `main()` errors.
- **P12: Flutter Full CRUD & Sync** — Branch `phase/12-flutter-full-crud`, not yet merged. Changes:
  - **Favorites fix:** `loadFavorites()` now called in splash screen after `loadOffers()` completes (only for logged-in users). Favorite state persists across app restarts.
  - **Pagination:** `OfferProvider` tracks `_currentPage`, `_hasMore`, supports `loadMoreOffers()`. `HomeScreen` uses `NotificationListener<ScrollNotification>` for infinite scroll, shows loading indicator at bottom.
  - **Server-side search:** `SearchScreen` now calls `provider.searchOffers()` with 400ms debounce instead of client-side filtering. Shows loading spinner during search, error state on failure.
  - **Error states:** `OfferProvider` exposes `_error` string. Home/Search screens show retry UI with error message instead of silently failing.
  - **Offer detail API:** `OfferDetailsScreen` fetches full detail from `GET /offers/:id` using `ApiOfferService` if not in local cache. Shows loading spinner during fetch.
  - **Notification system:** New `NotificationProvider`, `ApiNotificationService`, `AppNotification` model, `NotificationsScreen` with read/unread badge on tab bar. `loadUnreadCount()` called on splash. Mark-all-read and per-notification read support.
  - **Restaurant model + list:** `Restaurant` model (`lib/models/restaurant.dart`), `ApiRestaurantService`, `RestaurantProvider`, `RestaurantsScreen` with list. Link from Profile screen ("Browse Restaurants") navigates to `RestaurantsScreen`.
  - **SSE service:** `SSEService` (`lib/services/sse_service.dart`) connects to `GET /events` for real-time updates using `dart:io` `HttpClient`. Configurable base URL + token auth.

### Blocked
- (none)

## Key Decisions
- All phase branches (`phase/3-core-crud` through `phase/11-admin-full-crud`) created and saved, `phase/10-backend-foundation` and prior merged to master.
- Firebase token verification uses real Firebase Admin SDK when credentials file is present; gracefully falls back to mock if absent (same pattern as FCM client).
- Flutter uses `dio` + `flutter_secure_storage` for API calls; Firebase Auth for Google Sign-In only (email/password goes directly to backend).
- Firebase init is wrapped in try-catch so app works without config files.
- `API_BASE_URL` env var configures backend URL (defaults to `http://localhost:8080/api/v1`).
- Backend entry point is `cmd/server/main.go` (NOT `cmd/api/main.go`).
- `[]string` fields use `models.JSONStringSlice` with JSONB storage instead of PostgreSQL `text[]` to avoid pgx driver incompatibility.
- `ThemeProvider` is a custom React context (not `next-themes`) to keep deps minimal.
- Brand palette: curry orange (`oklch 0.65 0.16 70`) primary, deep charcoal sidebar (`oklch 0.15` light / `oklch 0.08` dark).
- Toast notifications use `@radix-ui/react-toast` with a custom `ToastProvider` and `notify()` window event.
- Pagination uses shared `PaginationBar` component with intelligent page display (first/last + surrounding pages).
- Form validation uses `react-hook-form` + `zod` + `@hookform/resolvers` (all already installed, finally wired up).
- Build tags (`seed`, `migration`) on script files to avoid `go build ./...` conflicts.

## Next Steps
- **Phase 13: Push Notifications End-to-End** — Add firebase_messaging to Flutter; device token registration; foreground/background notification handling; unread badge; admin notification sending to real FCM.
- **Phase 14: Admin UX Polish & Localization** — Translation fields in admin forms; translation-aware search; admin stats widgets; performance optimization.

## Relevant Files
### Backend
- `backend/internal/handlers/admin_handler.go` — `Stats()` and `ListNotifications()` endpoints for admin.
- `backend/internal/handlers/user_handler.go` — `Me()`, `List()`, `Update()`, `Delete()` for admin user management.
- `backend/internal/repository/notification_repo.go` — `FindAllAdmin(offset, limit)` for all-notifications.
- `backend/internal/repository/restaurant_repo.go` — `CountAll`, `CountByStatus` methods.
- `backend/internal/repository/offer_repo.go` — `CountAll`, `CountByStatus` methods.
- `backend/internal/repository/user_repo.go` — `CountAll`, `SoftDelete`, `Update` methods.
- `backend/internal/router/router.go` — Admin routes: `/admin/stats`, `/admin/notifications`. User admin routes: `PUT /users/:id`, `DELETE /users/:id`.
- `backend/Makefile` — `seed` and `migrate-up/down` targets updated with `-tags`.
- `backend/scripts/seed.go` — Added `//go:build seed`.
- `backend/scripts/migrate.go` — Added `//go:build migration`.

### Admin
- `admin/src/lib/api.ts` — 401 auto-logout interceptor.
- `admin/src/components/ui/toast.tsx` — `ToastProvider` and `notify()` using `@radix-ui/react-toast`.
- `admin/src/components/ui/pagination-bar.tsx` — Reusable pagination UI component.
- `admin/src/app/dashboard/page.tsx` — Real stats from `/admin/stats`, 4 stat cards.
- `admin/src/app/dashboard/restaurants/_restaurant-dialog.tsx` — Create/edit modal with form fields.
- `admin/src/app/dashboard/restaurants/page.tsx` — Edit/delete, pagination.
- `admin/src/app/dashboard/offers/_offer-dialog.tsx` — Zod + react-hook-form validation, file upload.
- `admin/src/app/dashboard/offers/page.tsx` — Pagination.
- `admin/src/app/dashboard/users/page.tsx` — Role editing dropdown, soft-delete, pagination.
- `admin/src/app/dashboard/notifications/page.tsx` — Send form + history table with pagination.
