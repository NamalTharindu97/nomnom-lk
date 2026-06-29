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

## P25 — App Icon & Branding
- Generated 1024×1024 app icon matching in-app brand logo (curry-orange `#FFB23F` background, white rounded container, fork & knife icon)
- Added `flutter_launcher_icons` (v0.14.4) to `pubspec.yaml`, configured with adaptive icon support
- Generated all platform icon sizes for Android (5 mipmap densities) and iOS (15 AppIcon sizes + App Store 1024×1024)
- Adaptive icon XML created for Android 8+ with curry-orange background + foreground inset at 16%
- Updated `AndroidManifest.xml` `android:label` from `nomnom_lk` → `NomNom LK`

## P26 — Splash Screen Sequential Reveal
- Refactored `SplashScreen` from single fade+scale (850ms) to staggered sequential reveal (1200ms):
  - 0–35%: Icon container scales in with easeOutBack bounce + fade
  - 25–60%: "NomNom LK" text slides up from below + fades in
  - 50–85%: Tagline "Discover Sri Lanka's Best Food Deals" fades in
  - 70–100%: `CircularProgressIndicator` fades in
- Added exit fade: `_controller.reverse()` (200ms) before `pushReplacementNamed`
- Removed dependency on `AppLogo` widget (splash now self-contained)
- Increased minimum display from 1100ms → 1500ms to accommodate longer animation

## P27 — Text Copy Refinement
| File | Old | New |
|------|-----|-----|
| `home_screen.dart` | `'Today near you'` | `'Best deals near you'` |
| `home_screen.dart` | `'Street food favorites, lunch packs...across Sri Lanka.'` | `'Discover the best food deals from your favorite local spots.'` |
| `home_screen.dart` | `'No offers yet'` / `'Fresh deals will appear here soon.'` | `'No deals yet'` / `'Check back for new offers from your favorite eateries.'` |
| `search_screen.dart` | `'Find your next meal'` / `'Search for food or restaurant names.'` | `'What are you craving?'` / `'Search for dishes, restaurants, or cuisines.'` |
| `search_screen.dart` | `'No matching deals'` / `'Try another food or restaurant name.'` | `'No deals found'` / `'Try another dish or restaurant name.'` |
| `favorites_screen.dart` | `'Tap the heart on any offer to keep it here.'` | `'Tap the heart on any deal to save it here.'` |
| `main_shell.dart` | `'Alerts'` (tab label) | `'Notifications'` (matches screen title) |
| `app_user.dart` | `'Guest foodie'` | `'Guest'` |

## P28 — App Icon Branding Match
- Rendered exact `restaurant_menu_rounded` Material icon path (from Google Fonts CDN) via cairosvg at 1024×1024
- Curry-orange `#FFB23F` background + white icon — matches in-app `AppLogo` widget
- Regenerated all Android (5 mipmap densities + adaptive icon) and iOS (21 sizes) launcher icons
- Updated `AndroidManifest.xml` `android:label` from `nomnom_lk` → `NomNom LK`

## P29 — Login Screen Typography Hierarchy
- Researched DoorDash, Uber Eats, Grubhub login typography (28–30pt brand → 13–15pt body → 11–13pt meta)
- Applied cascade: NomNom LK `headlineMedium` (28px) → tagline `titleMedium` (16px) → divider/footer `titleSmall` (14px)
- Tagline color: `context.colors.textSecondary` (muted) instead of `textPrimary`
- Divider/footer bumped from `bodySmall` (12px) to `titleSmall` (14px) for consistent visual flow

## P30 — Notification Expiry Based on Offer Dates
- Added `offer_id` (`*uuid.UUID`) column to `Notification` model via GORM AutoMigrate
- Backend DTO: `SendPushRequest` accepts optional `offer_id`, wired into `SendPushInput.OfferID`
- `NotificationHandler.List` and `AdminHandler.ListNotifications` return `offer_id` in response
- `CronService.MarkExpiredOffers`: after marking expired offers, deletes all notifications linked to those offer IDs via `NotificationRepo.DeleteByOfferIDs`
- `CronService.NotifyExpiringSoon`: passes `OfferID` into `SendPushInput` so expiring-soon notifications carry the offer reference
- Flutter `AppNotification` model: added nullable `offerId` field, deserialized from `offer_id`
- `NotificationsScreen`: on tap, if notification has `offerId`, navigates to `OfferDetailsScreen` via `pushNamed(AppRoutes.offerDetails, arguments: n.offerId)`
