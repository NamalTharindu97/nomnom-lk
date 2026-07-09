# Profile Data Loading Optimization Plan

## Problem
After login or app launch, the Profile screen shows stale data:
- **Favorites count** stays "0 Saved" for 3–25 seconds
- **Restaurants count** stays "0" / "-" for 3–25 seconds
- **Saved deals** in Favorites tab empty until pull-to-refresh

## Root Causes

### Critical
1. **`loadRestaurants()` never runs at startup** — `splash_screen.dart:76` only loads offers + restores session. Profile "All Restaurants" stat card stays 0 until SSE connects or 20s poll timer fires.
2. **`loadFavorites()` never runs after fresh login** — `auth_provider.dart:41-52` navigates to home without syncing favorites. `favoriteOffers.length` stays 0 until pull-to-refresh or SSE triggers.

### High
3. **Hive stores are write-only** — `FavoriteStore`, `OfferStore`, `RestaurantStore` are only read as offline fallback. Every startup requires a network round trip even when cached data exists locally. `FavoriteStore.getFavorites()` is dead code.

### Medium
4. **Cache interceptor TTL is 2 minutes** — too short for infrequently-changing offer/restaurant data. SSE handles real-time invalidation, so 5 min is safe.
5. **App resume fires 4 API calls** — `refreshOffers()` (2 sequential calls: offers + favorites), `loadRestaurants()`, `loadNotifications()` on every resume, even 2-second app switches.
6. **Splash has sequential groups** — `loadFavorites()` waits for `loadOffers()` to complete before starting.

## Fixes

| # | Priority | Fix | Files | Expected Impact |
|---|---|---|---|---|
| 1 | P0 | Add `loadRestaurants()` + `loadFavorites()` to splash bootstrap parallel group | `splash_screen.dart` | Restaurant count + favorites ready in ~2s, not 3–25s |
| 2 | P0 | Call `loadFavorites()` + `loadRestaurants()` after login | `auth_provider.dart`, `login_screen.dart` | Profile data populated immediately after login |
| 3 | P1 | Cache-first pattern: read Hive → display → background API → store | `offer_provider.dart`, `restaurant_provider.dart`, `favorite_store.dart` | Instant display from cache for returning users |
| 4 | P1 | Increase cache TTL to 5 minutes | `cache_interceptor.dart:17` | Fewer redundant re-fetches |
| 5 | P2 | Add 60s debounce to app resume refreshes | `main_shell.dart` | No redundant API calls on quick app switches |
| 6 | P2 | Merge splash parallel groups — fire all loaders simultaneously | `splash_screen.dart` | All data ready ~1 RTT faster |

## Files to Modify

| File | Changes |
|---|---|
| `lib/screens/splash_screen.dart` | Add `loadRestaurants()` to parallel group; call `loadFavorites()` in same group as `loadOffers()` |
| `lib/providers/auth_provider.dart` | Add `postLoginActions()` method; call favorites + restaurants sync after login |
| `lib/screens/login_screen.dart` | Call `postLoginActions()` after successful login before navigating home |
| `lib/providers/offer_provider.dart` | Cache-first: read `OfferStore` → display → API → store; read `FavoriteStore` → apply → API → store |
| `lib/providers/restaurant_provider.dart` | Cache-first: read `RestaurantStore` → display → API → store |
| `lib/services/cache_interceptor.dart` | Change TTL from 2 min to 5 min |
| `lib/screens/main_shell.dart` | Add 60s debounce to resume refresh; skip if `lastResume` < 60s ago |

## Verification
- `flutter analyze` — 0 errors
- `flutter test` — all 19 passing
- Profile: favorites count shows correct value immediately after login
- Profile: restaurants count shows correct value after splash
- Favorites tab: shows saved deals without manual pull-to-refresh
- App resume: quick switch back doesn't fire redundant API calls
