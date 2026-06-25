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
- **Not yet:** Flutter localization, full offline support.

## Progress
### Done
- **P10: Backend Foundation Fixes** — `/users/me`, Firebase Admin SDK, upload serving, SSE, translation merging. Merged to master.
- **P11: Admin Dashboard Full CRUD** — Branch `phase/11-admin-full-crud`, merged to master.
  - **Backend:** `GET /admin/stats` (restaurant/offer/user/pending counts), `GET /admin/notifications` (all-users history), `PUT /users/:id` (role/name edit), `DELETE /users/:id` (soft-delete). Count methods on repos. Build tags on scripts. Makefile updated with `-tags`.
  - **Admin Dashboard:** 401 auto-logout interceptor in `api.ts`. Toast via `@radix-ui/react-toast`. Dashboard uses real stats. Restaurant CRUD dialog. User role dropdown + soft-delete. Offer pagination + zod+react-hook-form validation + file upload. Notification history table. `PaginationBar` shared component.
- **P12: Flutter Full CRUD & Sync** — Branch `phase/12-flutter-full-crud`, merged to master.
  - Favorites fix, infinite scroll pagination, server-side search, error states, offer detail API, notification provider/list, restaurant model/list, SSE client, 5-tab bottom nav with unread badge.
- **P13: Push Notifications End-to-End** — Branch `phase/13-push-notifications`, completed and ready to merge to master.
  - Added `firebase_messaging: ^15.2.10` + `flutter_local_notifications` to pubspec.yaml.
  - Created `FcmMessagingService` with token get/register, permission request, token refresh listener, foreground/background message handlers.
  - Local notification display via `flutter_local_notifications` on foreground FCM messages.
  - Notification tap handling: foreground (local notification tap), background (`onMessageOpenedApp`), terminated (`getInitialMessage`) — all navigate to home.
  - `ApiClient.delete()` updated to support optional `data` body.
  - `main.dart` wrapped in `_FcmInitializer` widget that initializes FCM after first frame, reuses `NotificationProvider` to refresh unread badge on notification receipt.
  - `AuthProvider.signOut()` now calls `fcmService?.unregisterToken()` before backend logout.
  - Global `fcmService` variable for logout access.
  - Android: enabled core library desugaring + set `minSdk = 23` for Firebase compatibility.
  - iOS: added `GoogleService-Info.plist` to Xcode project and Resources build phase.
  - iOS: created `Runner.entitlements` with `aps-environment = development` for APNs token.
  - Verified end-to-end: backend FCM client initializes, admin push sends via FCM API, `simctl push` delivers to iOS simulator.

### In Progress
- **Phase 14: Admin UX Polish & Localization** — Backend `GET /admin/stats/timeline` endpoint. Translation fields (`_si`, `_ta`) added to restaurant and offer dialogs. Real chart data from timeline endpoint with offers + restaurants bars. Loading skeletons on dashboard. Animate-pulse placeholders on stats cards.

### Blocked
- (none)

## Key Decisions
- All phase branches merged to master; `phase/13-push-notifications` is current active branch.
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

## Next Steps
- **Phase 14:** Admin UX polish & localization forms.
- **Phase 15:** Final polish & deployment to Railway.

## Critical Context
- All branches P1–P12 merged to master and preserved on remote.
- Backend running on `:8080` with all endpoints. Admin dashboard on `:3000`. Flutter app on iPhone 17 Pro simulator.
- Docker services (postgres 16, redis 7, minio) running with seeded data.
- Backend FCM client already initialized in `NotificationService` — `POST /admin/notifications/push` already sends via FCM in real goroutine.
- `Flutter` `pubspec.yaml` has `firebase_messaging: ^15.2.10` resolved.
- API routes confirmable at startup logs: `GET /admin/stats`, `GET /admin/stats/timeline`, `GET /admin/notifications`, `POST /admin/notifications/push`, `POST /devices`, `DELETE /devices`.
- Translations stored as JSONB column on restaurants/offers. Admin dialog sends `name_si`, `name_ta`, `description_si`, `description_ta` for restaurant and `title_si`, `title_ta`, `desc_si`, `desc_ta` for offer — merged into JSONB by backend `TranslationService`.

## Relevant Files
### Backend (all P10+P11+P14)
- `backend/internal/handlers/admin_handler.go` — `Stats()`, `StatsTimeline()`, `ListNotifications()`
- `backend/internal/handlers/user_handler.go` — `Me()`, `List()`, `Update()`, `Delete()`
- `backend/internal/handlers/notification_handler.go` — `SendPush`, `RegisterDevice`, `UnregisterDevice`
- `backend/internal/services/notification_service.go` — FCM `initFCMClient`, `SendPush()` goroutine
- `backend/internal/services/translation_service.go` — `MergeIntoJSONB()` helper
- `backend/internal/repository/notification_repo.go` — `FindAllAdmin()` for history
- `backend/internal/repository/device_token_repo.go` — `Upsert()`, `DeleteByToken()`
- `backend/internal/repository/offer_repo.go` — CRUD + CountAll + CountByStatus + CountByDate
- `backend/internal/repository/restaurant_repo.go` — CRUD + CountAll + CountByStatus + CountByDate
- `backend/internal/router/router.go` — Admin routes, `/users/:id` PUT/DELETE, `/admin/stats/timeline`
- `backend/internal/models/restaurant.go` — `Translations *json.RawMessage`
- `backend/internal/models/offer.go` — `Translations *json.RawMessage`
- `backend/internal/dto/request/restaurant_request.go` — `NameSi`, `NameTa`, `DescSi`, `DescTa`
- `backend/internal/dto/request/offer_request.go` — `TitleSi`, `TitleTa`, `DescSi`, `DescTa`
- `backend/scripts/seed.go` — `//go:build seed`
- `backend/scripts/migrate.go` — `//go:build migration`
- `backend/Makefile` — targets with `-tags`

### Admin Dashboard (P11+P14)
- `admin/src/lib/api.ts` — 401 auto-logout interceptor
- `admin/src/components/ui/toast.tsx` — ToastProvider + notify()
- `admin/src/components/ui/pagination-bar.tsx` — Reusable pagination
- `admin/src/app/dashboard/page.tsx` — Real stats from `/admin/stats`, chart from `/admin/stats/timeline`, loading skeletons
- `admin/src/app/dashboard/restaurants/_restaurant-dialog.tsx` — Create/edit modal with Sinhala/Tamil translation fields
- `admin/src/app/dashboard/offers/page.tsx` — Offer CRUD table
- `admin/src/app/dashboard/offers/_offer-dialog.tsx` — Zod + react-hook-form + file upload + translation fields
- `admin/src/app/dashboard/users/page.tsx` — Role dropdown + soft-delete
- `admin/src/app/dashboard/notifications/page.tsx` — Send form + history table

### Flutter (P12+P13)
- `lib/services/fcm_messaging_service.dart` — FCM token management, handlers, permission, local notifications, tap navigation
- `lib/services/api_client.dart` — HTTP client with `delete()` data body support
- `lib/main.dart` — `_FcmInitializer` widget, FCM init on first frame
- `lib/services/api_notification_service.dart` — fetch/mark notifications
- `lib/services/sse_service.dart` — SSE stream via `dart:io`
- `lib/services/api_restaurant_service.dart` — Restaurant API
- `lib/providers/notification_provider.dart` — Notification state + unread count
- `lib/providers/auth_provider.dart` — Sign-out calls fcmService?.unregisterToken()
- `lib/providers/restaurant_provider.dart` — Restaurant list state
- `lib/providers/offer_provider.dart` — Paginated loading, search, error state
- `lib/screens/notifications_screen.dart` — Notification list with read/unread
- `lib/screens/restaurants_screen.dart` — Restaurant list with cuisine tags
- `lib/screens/main_shell.dart` — 5-tab bottom nav with unread badge
- `lib/core/app_routes.dart` — All named routes
