## Goal
- Go backend + admin dashboard + Flutter app for NomNom LK, a Sri Lankan food offers discovery app.

## Constraints & Preferences
- **Stack:** Go + Gin + GORM + PostgreSQL 16 + Redis 7 + MinIO + Firebase Auth + FCM + JWT + Sentry + Docker/Railway + Next.js 16 + Tailwind v4 + shadcn/ui + Flutter + Dio + firebase_messaging.
- **Build order & sign-off:** Phase-by-phase via feature branches (`phase/N-name`), merge to master after approval, branches preserved on remote.
- **Session context:** AGENTS.md updated and committed at end of every phase; read at session start to restore full context.
- **Architecture:** Standard struct-based DI; roles (user, restaurant_owner, admin); approval workflow; localization via JSONB translations (`Translations` type alias `map[string]map[string]string` stored in JSONB column).
- **Docker for infra only:** Postgres 16, Redis 7, MinIO via `docker compose up -d` in `backend/`. Backend runs natively with `make run`.
- **Firebase graceful fallback:** Both Firebase Auth + FCM client log warning and return nil if credentials file absent — app does not crash.
- **Theme:** Custom `ThemeProvider` (localStorage key `nomnom-theme`), curry-orange brand palette, sidebar CSS vars theme-aware.
- **Toast notifications:** `@radix-ui/react-toast` with custom `ToastProvider` + `notify()` in admin.
- **Pagination:** Shared `PaginationBar` component in admin, infinite scroll in Flutter.
- **Form validation:** `react-hook-form` + `zod` + `@hookform/resolvers` in admin OfferDialog.
- **Build tags:** `//go:build seed` and `//go:build migration` on script files to avoid `main()` conflict in `go build ./...`.
- **Flutter rebuild required:** After every Flutter code change, rebuild and re-run the app with `flutter run` to see changes on the simulator.
- **Air for Go hot reload:** Backend uses `air` for automatic rebuild/restart on `.go` file changes; admin dashboard uses Next.js HMR built into `next dev`; Flutter runs in debug mode.
- **Not yet:** Flutter localization, full offline support.

## Progress
### Done
- **P10: Backend Foundation Fixes** — `/users/me`, Firebase Admin SDK, upload serving, SSE, translation merging. Merged to master.
- **P11: Admin Dashboard Full CRUD** — `GET /admin/stats`, `GET /admin/notifications`, `PUT /users/:id`, `DELETE /users/:id`, restaurant CRUD dialog, OfferDialog, user role dropdown, PaginationBar, 401 auto-logout interceptor, toast notifications. Merged to master.
- **P12: Flutter Full CRUD & Sync** — Favorites fix, infinite scroll pagination, server-side search with debounce, error states + retry, offer detail API, notification provider/list, restaurant model/list, SSE client, 5-tab bottom nav with unread badge. Merged to master.
- **P13: Push Notifications End-to-End** — `FcmMessagingService` with token get/register, permission, token refresh, foreground/background handlers, local notifications via `flutter_local_notifications`, tap nav (foreground/background/terminated → home). Android: minSdk=23 + desugaring. iOS: GoogleService-Info.plist + Runner.entitlements. Merged to master.
- **P14: Admin UX Polish & Localization** — `GET /admin/stats/timeline` with daily offer & restaurant counts; translation fields (`_si`/`_ta`) in restaurant and offer dialogs; real chart data with dual bars; loading skeletons on dashboard cards. Merged to master.
- **E2E Fixes (on master):** Offer create nil `Restaurant` pointer fix (reload after create); `search_vector` TSVECTOR migration; timeline `DATE::text` cast for GORM scan.
- **P15: Real-Time Sync via SSE** — Flutter SSE listener wired up (`_SseListener` widget in `main.dart`); `SSEService` rewritten to parse `event:` lines and emit typed `SSEEvent` objects with auto-reconnect; admin offers/restaurants pages pass `status=all` to see all statuses; backend `status=all` support in `offer_repo.go` and `restaurant_repo.go`; `status` field added to `offerToMap` response.
- **P16: Dev Environment — Background Processes + Hot Reload** — Backend auto-restart via `air` (Go hot reload, configured in `backend/.air.toml`); admin dashboard runs with `next dev` (HMR built-in); Flutter runs on iPhone 17 Pro simulator in debug mode; all three run as background `nohup` processes with logs routed to `*/logs/*.log`; `.gitignore` updated to exclude log dirs.

### In Progress
- **P17: Seed Data with MinIO Images + Data Loading Optimization** — Phase split into sub-steps:
  1. ✅ Seed script with MinIO image upload (Unsplash food photos → MinIO → DB records)
  2. ✅ Fix offer dialog field name mismatch (`desc_si`/`desc_ta` → `description_si`/`description_ta`)
  3. ✅ Image caching (Flutter `Image.network` → `CachedNetworkImage`)
  4. ✅ Data caching (Dio interceptor with 2-min TTL + SSE cache invalidation)
  5. ⬜ Pagination metadata + shimmer + retry + restaurant upload

### Blocked
- (none)

## Key Decisions
- All phase branches merged to master; master is current active branch.
- **SSE for real-time sync:** Chose Server-Sent Events over WebSocket for simpler server→client streaming with Gin's `c.Stream()`.
- **Firebase graceful fallback:** Both Auth token verification and FCM client follow same pattern — init from credentials file, skip if missing, log a warning.
- **Toast notifications in admin:** `@radix-ui/react-toast` with custom `ToastProvider` avoids extra dependencies.
- **Form validation in admin:** `react-hook-form` + `zod` + `@hookform/resolvers` — packages already installed but unused.
- **Pagination:** Shared `PaginationBar` in admin; `NotificationListener<ScrollNotification>` infinite scroll in Flutter.
- **Build tags on script files:** `//go:build seed` / `//go:build migration` prevents `go build ./...` conflict from two `main()` functions in `scripts/` directory.
- **FCM service init:** `_FcmInitializer` stateful widget at app root runs `addPostFrameCallback` to avoid blocking UI; creates its own `ApiClient` instance. `NotificationProvider` captured before async gap to avoid `use_build_context_synchronously` lint.
- **firebase_messaging version:** Pinned to `^15.2.10` for compatibility with existing `firebase_core ^3.6.0`.
- **Android minSdk:** Set to 23 for Firebase Auth compatibility (firebase-auth 23.x requires 23). Core library desugaring enabled for `flutter_local_notifications`.
- **Notification tap nav:** All three tap scenarios (foreground local notification, background `onMessageOpenedApp`, terminated `getInitialMessage`) route to home screen via an `onNavigate` callback.
- **iOS entitlements:** `Runner.entitlements` with `aps-environment = development` required for APNs token. Added to Xcode project via pbxproj edits (CODE_SIGN_ENTITLEMENTS build setting + file reference).
- **SSE listener in Flutter:** `_SseListener` widget in `main.dart` creates `SSEService`, connects on init, listens for `offer.*` and `restaurant.*` events, and calls `OfferProvider.refreshOffers()` / `RestaurantProvider.loadRestaurants()` automatically — no user action needed.
- **Admin page status filter:** Both offers and restaurants pages pass `status=all` to the backend to display all statuses (approved, pending, rejected) so admins can manage them.
- **Air for Go hot reload:** `air` installed via `go install github.com/air-verse/air@latest`; config at `backend/.air.toml` watches `.go`/`.html`/`.tpl`/`.tmpl` changes and rebuilds; binary built to `backend/tmp/nomnom-api`.
- **Background process management:** All three services (backend, admin, Flutter) run as `nohup` background processes; logs go to `*/logs/*.log`.

## Next Steps
- (none — all 16 phases complete, P17 in progress on master)

## Critical Context
- All branches P1–P16 merged to master and preserved on remote.
- Backend running on `:8080` with all endpoints. Admin dashboard on `:3000`. Flutter app on iPhone 17 Pro simulator.
- Docker services (postgres 16, redis 7, minio) running with seeded data.
- Backend FCM client already initialized in `NotificationService` — `POST /admin/notifications/push` already sends via FCM in real goroutine.
- `Flutter` `pubspec.yaml` has `firebase_messaging: ^15.2.10` resolved.
- API routes confirmable at startup logs: `GET /admin/stats`, `GET /admin/stats/timeline`, `GET /admin/notifications`, `POST /admin/notifications/push`, `POST /devices`, `DELETE /devices`.
- Translations stored as JSONB column on restaurants/offers. Admin dialog sends `name_si`, `name_ta`, `description_si`, `description_ta` for restaurant and `title_si`, `title_ta`, `desc_si`, `desc_ta` for offer — merged into JSONB by backend `TranslationService`.
- **Offer dialog field name mismatch:** The admin offer dialog sends `desc_si`/`desc_ta` but the backend DTO expects `description_si`/`description_ta`. The dialog needs updating to match backend field names.
- **Real-time SSE sync working:** Backend emits `offer.*` and `restaurant.*` events on all CRUD operations. Flutter `_SseListener` widget connects, parses events, and refreshes providers automatically. Admin offers/restaurants pages pass `?status=all` to see pending/rejected items for moderation.

## Relevant Files
### Backend (all P10+P11+P14+P15)
- `backend/internal/handlers/admin_handler.go` — `Stats()`, `StatsTimeline()`, `ListNotifications()`
- `backend/internal/handlers/user_handler.go` — `Me()`, `List()`, `Update()`, `Delete()`
- `backend/internal/handlers/notification_handler.go` — `SendPush`, `RegisterDevice`, `UnregisterDevice`
- `backend/internal/handlers/offer_handler.go` — `offerToMap` now includes `status` field; SSE emits on CRUD
- `backend/internal/handlers/restaurant_handler.go` — SSE emits on CRUD
- `backend/internal/services/notification_service.go` — FCM `initFCMClient`, `SendPush()` goroutine
- `backend/internal/services/translation_service.go` — `MergeIntoJSONB()` helper
- `backend/internal/services/sse_service.go` — `HandleSSE()`, `Broadcast()`, `Emit()`
- `backend/internal/repository/notification_repo.go` — `FindAllAdmin()` for history
- `backend/internal/repository/device_token_repo.go` — `Upsert()`, `DeleteByToken()`
- `backend/internal/repository/offer_repo.go` — `FindAll` supports `status=all` (no filter)
- `backend/internal/repository/restaurant_repo.go` — `FindAll` supports `status=all` (no filter)
- `backend/internal/router/router.go` — Admin routes, `/users/:id` PUT/DELETE, `/admin/stats/timeline`, `/events`
- `backend/internal/models/restaurant.go` — `Translations *json.RawMessage`
- `backend/internal/models/offer.go` — `Translations *json.RawMessage`
- `backend/internal/dto/request/restaurant_request.go` — `NameSi`, `NameTa`, `DescSi`, `DescTa`
- `backend/internal/dto/request/offer_request.go` — `TitleSi`, `TitleTa`, `DescSi`, `DescTa`
- `backend/.air.toml` — Air hot reload config (watches `.go`/`.html`/`.tpl`/`.tmpl`)
- `backend/scripts/seed.go` — `//go:build seed`
- `backend/scripts/migrate.go` — `//go:build migration`
- `backend/Makefile` — targets with `-tags`

### Admin Dashboard (P11+P14+P15)
- `admin/src/lib/api.ts` — 401 auto-logout interceptor
- `admin/src/components/ui/toast.tsx` — ToastProvider + notify()
- `admin/src/components/ui/pagination-bar.tsx` — Reusable pagination
- `admin/src/app/dashboard/page.tsx` — Real stats from `/admin/stats`, chart from `/admin/stats/timeline`, loading skeletons
- `admin/src/app/dashboard/restaurants/page.tsx` — CRUD table, passes `status=all`
- `admin/src/app/dashboard/restaurants/_restaurant-dialog.tsx` — Create/edit modal with Sinhala/Tamil translation fields
- `admin/src/app/dashboard/offers/page.tsx` — CRUD table, passes `status=all`
- `admin/src/app/dashboard/offers/_offer-dialog.tsx` — Zod + react-hook-form + file upload + translation fields
- `admin/src/app/dashboard/users/page.tsx` — Role dropdown + soft-delete
- `admin/src/app/dashboard/notifications/page.tsx` — Send form + history table

### Flutter (P12+P13+P15)
- `lib/services/fcm_messaging_service.dart` — FCM token management, handlers, permission, local notifications, tap navigation
- `lib/services/api_client.dart` — HTTP client with `delete()` data body support
- `lib/services/sse_service.dart` — SSE stream via `dart:io`, parses `event:` / `data:` lines, emits `SSEEvent` objects, auto-reconnect
- `lib/services/api_restaurant_service.dart` — Restaurant API
- `lib/services/api_notification_service.dart` — fetch/mark notifications
- `lib/main.dart` — `_FcmInitializer` widget (FCM init) + `_SseListener` widget (SSE real-time sync)
- `lib/providers/notification_provider.dart` — Notification state + unread count
- `lib/providers/auth_provider.dart` — Sign-out calls fcmService?.unregisterToken()
- `lib/providers/restaurant_provider.dart` — Restaurant list state
- `lib/providers/offer_provider.dart` — Paginated loading, search, error state
- `lib/screens/notifications_screen.dart` — Notification list with read/unread
- `lib/screens/restaurants_screen.dart` — Restaurant list with cuisine tags
- `lib/screens/main_shell.dart` — 5-tab bottom nav with unread badge
- `lib/core/api_config.dart` — Base URL configuration
- `lib/core/app_routes.dart` — All named routes
