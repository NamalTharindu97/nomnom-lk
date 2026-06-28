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

### Done
- **P17: Seed Data with MinIO Images + Data Loading Optimization** — Seed script with MinIO image upload; fix offer dialog field name mismatch (`desc_si`/`desc_ta` → `description_si`/`description_ta`); `CachedNetworkImage` for image caching; Dio interceptor cache with 2-min TTL + SSE-driven cache invalidation; pagination metadata (total/total_pages) + shimmer loading + retry on error + restaurant cover image upload; translation fields flattened in API responses (`FlattenTranslations`); `offerToMap` includes `restaurant_id`, `start_date`, `translations`; `contact_phone` field fix in restaurant dialog. Merged to master.
- **P18: Fix Device Registration** — `_FcmInitializer` reuses shared `ApiClient` from widget tree (via `context.read<ApiClient>()`) instead of creating a duplicate instance without auth; added `registerCurrentToken()` to `FcmMessagingService`; `AuthProvider.restoreSession()` and login methods call `fcmService?.registerCurrentToken()` after auth confirmed. Merged to master.
- **P19: Fix Notification Tap Navigation + Backend Silent Success** — `_navigateToNotifications` parses payload: UUID routes to offer detail; `"notification"`/`"admin"`/null routes to notifications tab (index 3); home route moved to `onGenerateRoute` to accept `RouteSettings.arguments` for initial tab index; `MainShell` accepts `initialTab` param and loads notifications when tab=3 via `addPostFrameCallback`; backend `SendPush` returns error when `len(tokens) == 0` instead of silent nil. Merged to master.
- **P20: Robustness Fixes** — `sendFCMNotifications` deletes stale device tokens on `NotRegistered`/`Unregistered` FCM errors; `POST /admin/notifications/push` rate-limited to 1 per 10s per admin user via in-memory `rateLimiter`; admin notifications page auto-clears result message after 5s; Flutter `markAsRead` checks `isRead` before decrementing unread count to prevent negative. Merged to master.

### Done (Fix)
- **FCM Fix — Android Push Notifications Working E2E** — Three fixes:
  1. **Android google-services plugin**: Added `id("com.google.gms.google-services")` to `android/settings.gradle.kts` and `android/app/build.gradle.kts`. Without this, `Firebase.initializeApp()` silently failed and FCM tokens were generated under Google's internal project, causing `SENDER_ID_MISMATCH`.
  2. **Backend FCM direct HTTP**: Replaced Firebase Admin SDK (`firebase.google.com/go/v4`) with direct HTTP to FCM v1 API using `google.CredentialsFromJSON` with `cloud-platform` scope. Added `android` channel config (`nomnom_notifications`, `high` priority) so background/terminated notifications use the custom channel. Removed `initFCMClient()` and Firebase SDK dependency.
  3. **One-time FCM token migration**: `_getToken()` in `FcmMessagingService` calls `deleteToken()` + `getToken()` on first launch (tracked via `shared_preferences` flag `fcm_token_migrated`) to force a fresh token under the correct Firebase project. Only runs once per installation.
  - Verified: FCM v1 API returns HTTP 200 (`INFO: FCM sent`). Notifications arrive on Android emulator in foreground, background, and killed (non-force-stop) states. `dumpsys notification` confirms notifications posted to `nomnom_notifications` channel with importance=4.

### Done
- **iOS 16 Pro Physical Device Testing** — Connected iPhone 16 Pro (iOS 26.5) for iOS push testing. Findings:
  - Flutter 3.29.3 debug mode crashes on iOS 26.5+ physical devices (known JIT issue).
  - Profile/release mode also had install issues via `devicectl`.
  - Workaround: Built release `.app` and installed via `ios-deploy` (Homebrew tool).
  - White screen on launch → debug mode crash on home screen tap (no JIT support).
  - Reverted iOS changes: restored `aps-environment` entitlement and removed `NSAllowsArbitraryLoads`.
  - `DEVELOPMENT_TEAM = GBBV66G8DH` persisted in `project.pbxproj` for future iOS builds.
- **Admin Account Created** — `namal@nomnom.lk` / `Namal@123` registered and promoted to `admin` role via `PUT /users/:id`. Works for both mobile app and admin dashboard login.

### Done
- **Build Fixes + Search + Favorite Button Fix** — `const` removed from `BoxDecoration`/`SizedBox` in 5 files (splash, login, register, verify_email, offer_image). Backend offer search via `search_vector @@ to_tsquery` with `:*` prefix matching. Backend restaurant search via `name ILIKE`. Shimmer overflow crash fixed (`SingleChildScrollView`). Search isolation in providers (`_searchResults` separate from `_offers`). Search screen rewritten as combined Restaurants + Offers layout. Favorite button root cause: `ApiClient.post()` threw `TypeError` on empty 201 response body from `POST /favorites` → rollback in `toggleFavorite()` reverted optimistic update. Fixed with null/type guard in `post()` matching `put()`. Hot restart applied, verified working. Commit `8e17da1`.

### Blocked
- **iOS device debug mode** — Flutter 3.29.3 incompatible with iOS 26.5 JIT. No workaround without Flutter upgrade.
- **iOS push notifications** — Requires paid Apple Developer Account ($99/yr) for APNs entitlement.
- **Google Sign-In on Android** — Not yet working. Missing SHA-1 fingerprint in Firebase Console (see Next Steps).

## Key Decisions
- All phase branches merged to master; master is current active branch.
- **SSE for real-time sync:** Chose Server-Sent Events over WebSocket for simpler server→client streaming with Gin's `c.Stream()`.
- **SSE header flush:** Gin's `c.Stream()` blocks on `select` inside the callback, so HTTP response headers never flush to the client. Fix: call `c.Writer.WriteHeader(http.StatusOK)` + `c.Writer.Flush()` before `c.Stream()`.
- **SSE parser no-space colons:** Gin's SSE encoder writes `event:eventName` and `data:{json}` (no space after colon). Flutter parser must check `startsWith('event:')` and use `.trim()`, not `startsWith('event: ')`.
- **SSE forceRefresh for restaurants:** `RestaurantProvider.loadRestaurants()` guard `if (!forceRefresh && _restaurants.isNotEmpty) return;` silently skips reload on SSE events when called without `forceRefresh: true`.
- **Firebase graceful fallback:** Both Auth token verification and FCM client follow same pattern — init from credentials file, skip if missing, log a warning.
- **Toast notifications in admin:** `@radix-ui/react-toast` with custom `ToastProvider` avoids extra dependencies.
- **Form validation in admin:** `react-hook-form` + `zod` + `@hookform/resolvers` — packages already installed but unused.
- **Pagination:** Shared `PaginationBar` in admin; `NotificationListener<ScrollNotification>` infinite scroll in Flutter. Backend returns `page`, `per_page`, `total`, `total_pages` — consumed by Flutter via `PaginatedResponse<T>` model.
- **Shimmer loading:** `shimmer: ^3.0.0` package used for animated skeleton screens in Flutter (offers list, restaurants list, search results). Replaces old static gray boxes with `CircularProgressIndicator`.
- **Retry on error:** `EmptyState` widget has optional `onRetry` callback and `retryLabel`. Error states on home, restaurants, and search screens show a retry button. Restaurants screen also has pull-to-refresh.
- **Restaurant cover image upload:** Admin restaurant dialog now has image file input and upload via `/upload/multiple` endpoint. Sends `cover_image` in API body.
- **Build tags on script files:** `//go:build seed` / `//go:build migration` prevents `go build ./...` conflict from two `main()` functions in `scripts/` directory.
- **FCM service init:** `_FcmInitializer` stateful widget at app root runs `addPostFrameCallback` to avoid blocking UI; uses shared `ApiClient` from widget tree (via `context.read<ApiClient>()`). `NotificationProvider` captured before async gap to avoid `use_build_context_synchronously` lint.
- **Rate limiter:** In-memory per-user `rateLimiter` with `sync.Mutex` for `POST /admin/notifications/push` — 10s cooldown per admin user (identified by UUID from JWT).
- **Stale token cleanup:** FCM `Send()` error message checked via `strings.Contains()` for `"NotRegistered"`/`"UNREGISTERED"`/`"Unregistered"`; matching tokens deleted from DB via `DeleteByTokenValue`.
- **firebase_messaging version:** Pinned to `^15.2.10` for compatibility with existing `firebase_core ^3.6.0`.
- **Android minSdk:** Set to 23 for Firebase Auth compatibility (firebase-auth 23.x requires 23). Core library desugaring enabled for `flutter_local_notifications`.
- **Notification tap nav:** All three tap scenarios (foreground local notification, background `onMessageOpenedApp`, terminated `getInitialMessage`) route to home screen via an `onNavigate` callback.
- **iOS entitlements:** `Runner.entitlements` with `aps-environment = development` required for APNs token. Added to Xcode project via pbxproj edits (CODE_SIGN_ENTITLEMENTS build setting + file reference).
- **SSE listener in Flutter:** `_SseListener` widget in `main.dart` creates `SSEService`, connects on init, listens for `offer.*` and `restaurant.*` events, and calls `OfferProvider.refreshOffers()` / `RestaurantProvider.loadRestaurants()` automatically — no user action needed.
- **Admin page status filter:** Both offers and restaurants pages pass `status=all` to the backend to display all statuses (approved, pending, rejected) so admins can manage them.
- **Air for Go hot reload:** `air` installed via `go install github.com/air-verse/air@latest`; config at `backend/.air.toml` watches `.go`/`.html`/`.tpl`/`.tmpl` changes and rebuilds; binary built to `backend/tmp/nomnom-api`.
- **Background process management:** All three services (backend, admin, Flutter) run as `nohup` background processes; logs go to `*/logs/*.log`.

## Next Steps
### Performance Optimization Plan — Completed
**Goal**: Faster data loading + smoother scrolling on home screen. ✅ All 3 phases implemented.

#### Phase 1 — Quick Wins (Flutter) ✅
- ✅ Removed 350ms forced delay in `refreshOffers()` (saves 350ms on every pull-to-refresh)
- ✅ SSE `clearCache()` → targeted `invalidateCache('/offers')` / `invalidateCache('/restaurants')` — no more collateral cache wipe
- ✅ SSE 1-second debounce timer — coalesces rapid events into single refresh
- **Verification**: Hot restart, verified offers load faster, SSE refreshes don't clear other caches

#### Phase 2 — Rendering Performance (Flutter) ✅
- ✅ `Consumer<OfferProvider>` → targeted `Selector` widgets: header reads only `total`, body reads only its state; error change no longer rebuilds list and vice versa
- ✅ `Map<String, int>` index for O(1) `offerById()` — built on data load, updated on toggle; FavoriteButton lookups O(n) → O(1)
- ✅ Cached `List.unmodifiable` — only re-wrap when internal list reference changes
- **Verification**: Hot restart, verified scrolling smoother (fewer widget rebuilds)

#### Phase 3 — Backend Indexes ✅
- ✅ Composite index `idx_offers_status_created ON offers(status, created_at DESC)` — covers main listing query
- ✅ Partial index `idx_offers_end_date ON offers(end_date) WHERE status = 'approved'` — covers expiry queries
- ✅ Preload restricted to `id, name, slug, address` — 4 fields instead of ~15, reduces DB→Go data transfer
- **Verification**: `EXPLAIN ANALYZE` confirms query plan uses indexes for larger datasets. API response verified restaurant fields limited to 4.

#### Phase 4 — Future / Nice-to-Have
- Cache interceptor LRU eviction (prevent unbounded memory)
- MinIO presigned URLs for image serving
- Redis caching of offer list (30s TTL)

### Other
1. **Fix Google Sign-In on Android** — Add debug SHA-1 fingerprint to Firebase Console:
   - Run `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1`
   - Add to Firebase Console → Project Settings → General → Android app → Add fingerprint
   - Verify Google Sign-In enabled in Authentication → Sign-in methods
   - Rebuild and test "Continue with Google" on Android emulator

## Critical Context
- All branches P1–P17 merged to master and preserved on remote.
- Backend running on `:8080` with all endpoints. Admin dashboard on `:3000`. Flutter app on Pixel 8 Pro Android emulator.
- Docker services (postgres 16, redis 7, minio) running with seeded data.
- Backend FCM via direct HTTP to `https://fcm.googleapis.com/v1/projects/nomnom-cfe32/messages:send` using `cloud-platform` OAuth2 scope. No Firebase Admin SDK dependency.
- `Flutter` `pubspec.yaml` has `firebase_messaging: ^15.2.10` resolved.
- **Android google-services plugin** required for Firebase to work on Android (processes `google-services.json` at build time). Without it, FCM tokens are generated under wrong project → `SENDER_ID_MISMATCH`.
- API routes confirmable at startup logs: `GET /admin/stats`, `GET /admin/stats/timeline`, `GET /admin/notifications`, `POST /admin/notifications/push`, `POST /devices`, `DELETE /devices`.
- Translations stored as JSONB column on restaurants/offers. Admin dialog sends `name_si`, `name_ta`, `description_si`, `description_ta` for restaurant and `title_si`, `title_ta`, `desc_si`, `desc_ta` for offer — merged into JSONB by backend `TranslationService`.
- **Offer dialog field name mismatch:** The admin offer dialog sends `desc_si`/`desc_ta` but the backend DTO expects `description_si`/`description_ta`. The dialog needs updating to match backend field names. — ✅ **Fixed in P17**
- **Real-time SSE sync working:** Backend emits `offer.*` and `restaurant.*` events on all CRUD operations. Flutter `_SseListener` widget connects, parses events, and refreshes providers automatically with cache invalidation. Admin offers/restaurants pages pass `?status=all` to see pending/rejected items for moderation. ✅ **Working end-to-end (header flush + parser fix)**

## Relevant Files
### Backend (all P10+P11+P14+P15+P17)
- `backend/internal/handlers/admin_handler.go` — `Stats()`, `StatsTimeline()`, `ListNotifications()`
- `backend/internal/handlers/user_handler.go` — `Me()`, `List()`, `Update()`, `Delete()`
- `backend/internal/handlers/notification_handler.go` — `SendPush`, `RegisterDevice`, `UnregisterDevice`
- `backend/internal/handlers/offer_handler.go` — `offerToMap` now includes `status`, `restaurant_id`, `start_date`, `translations` fields; SSE emits on CRUD
- `backend/internal/handlers/restaurant_handler.go` — `contact_phone`, `description`, `translations` in response; SSE emits on CRUD
- `backend/internal/handlers/upload_handler.go` — cover image upload support
- `backend/internal/services/notification_service.go` — FCM via direct HTTP (`sendFCMDirect`) with `google.CredentialsFromJSON` + `cloud-platform` scope; Android channel config (`nomnom_notifications`, `high` priority); stale token deletion on `UNREGISTERED`
- `backend/internal/services/translation_service.go` — `MergeIntoJSONB()` helper
- `backend/internal/services/sse_service.go` — `HandleSSE()`, `Broadcast()`, `Emit()`; header flush fix (`c.Writer.WriteHeader` + `c.Writer.Flush()` before `c.Stream()`)
- `backend/internal/services/offer_service.go` — `UpdateTranslationFields`
- `backend/internal/repository/notification_repo.go` — `FindAllAdmin()` for history
- `backend/internal/repository/device_token_repo.go` — `Upsert()`, `DeleteByToken()`
- `backend/internal/repository/offer_repo.go` — `FindAll` supports `status=all` (no filter), search via `search_vector @@ tsquery` with `:*` prefix, Preload scoped to `id,name,slug,address`
- `backend/internal/database/postgres.go` — `runIndexMigrations()` creates composite + partial indexes on startup
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

### Admin Dashboard (P11+P14+P15+P17)
- `admin/src/lib/api.ts` — 401 auto-logout interceptor, `upload()` method for FormData
- `admin/src/components/ui/toast.tsx` — ToastProvider + notify()
- `admin/src/components/ui/pagination-bar.tsx` — Reusable pagination
- `admin/src/app/dashboard/page.tsx` — Real stats from `/admin/stats`, chart from `/admin/stats/timeline`, loading skeletons
- `admin/src/app/dashboard/restaurants/page.tsx` — CRUD table, passes `status=all`
- `admin/src/app/dashboard/restaurants/_restaurant-dialog.tsx` — Create/edit modal with cover image upload + Sinhala/Tamil translation fields
- `admin/src/app/dashboard/offers/page.tsx` — CRUD table, passes `status=all`
- `admin/src/app/dashboard/offers/_offer-dialog.tsx` — Zod + react-hook-form + file upload + translation fields
- `admin/src/app/dashboard/users/page.tsx` — Role dropdown + soft-delete
- `admin/src/app/dashboard/notifications/page.tsx` — Send form + history table

### Flutter (P12+P13+P15+P17)
- `lib/models/paginated_response.dart` — Generic paginated response model consuming backend `pagination` metadata
- `lib/models/restaurant.dart` — Restaurant model with `coverImage` field
- `lib/services/fcm_messaging_service.dart` — FCM token management, handlers, permission, local notifications, tap navigation, one-time `deleteToken()` migration with `shared_preferences`
- `lib/services/api_client.dart` — HTTP client with `delete()` data body support; `post()` has null/type guard for empty 201 responses; `CacheInterceptor` with 2-min TTL and targeted invalidation
- `lib/services/sse_service.dart` — SSE stream via `dart:io`, parses `event:` / `data:` lines, emits `SSEEvent` objects, auto-reconnect
- `lib/services/api_restaurant_service.dart` — Restaurant API, returns `PaginatedResponse<Restaurant>`
- `lib/services/api_offer_service.dart` — Offer API, returns `PaginatedResponse<Offer>`
- `lib/services/api_notification_service.dart` — fetch/mark notifications
- `lib/main.dart` — `_FcmInitializer` widget (FCM init) + `_SseListener` widget (SSE real-time sync)
- `lib/providers/notification_provider.dart` — Notification state + unread count
- `lib/providers/auth_provider.dart` — Sign-out calls fcmService?.unregisterToken()
- `lib/providers/restaurant_provider.dart` — Paginated restaurant list with `hasMore`, `total`, infinite scroll
- `lib/providers/offer_provider.dart` — Paginated loading from backend metadata, search, error state with retry
- `lib/screens/notifications_screen.dart` — Notification list with read/unread
- `lib/screens/restaurants_screen.dart` — Restaurant list with shimmer, pull-to-refresh, infinite scroll, retry button
- `lib/screens/home_screen.dart` — Offers with shimmer animation, retry button on error
- `lib/screens/search_screen.dart` — Search with shimmer loading and retry button
- `lib/screens/favorites_screen.dart` — Favorites with loading state check
- `lib/widgets/shimmer_loading.dart` — Shimmer skeleton widgets for offers and restaurant cards
- `lib/widgets/empty_state.dart` — Optional `onRetry` callback + retry button
- `lib/core/api_config.dart` — Base URL configuration
- `lib/core/app_routes.dart` — All named routes
