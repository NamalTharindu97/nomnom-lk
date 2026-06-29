# Flutter Plan

## P12 — Flutter Full CRUD & Sync
- Favorites fix
- Infinite scroll pagination
- Server-side search with debounce
- Error states + retry
- Offer detail API
- Notification provider/list
- Restaurant model/list
- SSE client
- 5-tab bottom nav with unread badge
- Merged to master

## P13 — Push Notifications End-to-End
- `FcmMessagingService` with token get/register, permission, token refresh
- Foreground/background handlers
- Local notifications via `flutter_local_notifications`
- Tap navigation (foreground/background/terminated → home)
- Android: minSdk=23 + desugaring
- iOS: GoogleService-Info.plist + Runner.entitlements
- Merged to master

## P15 — Real-Time Sync via SSE (Flutter)
- Flutter SSE listener wired up (`_SseListener` widget in `main.dart`)
- `SSEService` rewritten to parse `event:` lines and emit typed `SSEEvent` objects with auto-reconnect
- SSE parser checks `startsWith('event:')` and uses `.trim()` (no space after colon)
- `_SseListener` widget creates `SSEService`, connects on init, listens for `offer.*` and `restaurant.*` events
- Calls `OfferProvider.refreshOffers()` / `RestaurantProvider.loadRestaurants()` automatically

## P17 — Data Loading Optimization (Flutter)
- `CachedNetworkImage` for image caching
- Dio interceptor cache with 2-min TTL + SSE-driven cache invalidation
- Shimmer loading + retry on error
- `PaginatedResponse<T>` model consuming backend pagination metadata
- `FlattenTranslations` for translation fields in API responses

## P18 — Fix Device Registration
- `_FcmInitializer` reuses shared `ApiClient` from widget tree (via `context.read<ApiClient>()`)
- Added `registerCurrentToken()` to `FcmMessagingService`
- `AuthProvider.restoreSession()` and login methods call `fcmService?.registerCurrentToken()` after auth confirmed

## P19 — Fix Notification Tap Navigation
- `_navigateToNotifications` parses payload: UUID routes to offer detail; `"notification"`/`"admin"`/null routes to notifications tab (index 3)
- Home route moved to `onGenerateRoute` to accept `RouteSettings.arguments` for initial tab index
- `MainShell` accepts `initialTab` param and loads notifications when tab=3 via `addPostFrameCallback`

## P20 — Robustness Fixes (Flutter)
- `markAsRead` checks `isRead` before decrementing unread count to prevent negative

## Performance Phase 1 — Quick Wins
- Removed 350ms forced delay in `refreshOffers()` (saves 350ms on every pull-to-refresh)
- SSE `clearCache()` → targeted `invalidateCache('/offers')` / `invalidateCache('/restaurants')` — no more collateral cache wipe
- SSE 1-second debounce timer — coalesces rapid events into single refresh

## Performance Phase 2 — Rendering Performance
- `Consumer<OfferProvider>` → targeted `Selector` widgets: header reads only `total`, body reads only its state
- `Map<String, int>` index for O(1) `offerById()` — built on data load, updated on toggle
- Cached `List.unmodifiable` — only re-wrap when internal list reference changes

## P24 — Carousel Refactor
- Renamed "Trending deals" → "**Hot Offers**" header in home screen
- Sort by discount — `_TrendingCarousel` sorts `filteredOffers` by `discountPercent` descending, takes top 5
- Card redesign — replace `Expanded` + `Height(180)` with `AspectRatio(16:9)` image (matching `OfferCard` pattern), show original+offer price, add location row, add `FavoriteButton` overlay
- Extract `_DiscountBadge` from `offer_card.dart` to shared `lib/widgets/discount_badge.dart`

## Build Fixes
- `const` removed from `BoxDecoration`/`SizedBox` in 5 files (splash, login, register, verify_email, offer_image)
- Shimmer overflow crash fixed (`SingleChildScrollView`)
- Search isolation in providers (`_searchResults` separate from `_offers`)
- Search screen rewritten as combined Restaurants + Offers layout
- Favorite button fix: `ApiClient.post()` null/type guard for empty 201 responses
