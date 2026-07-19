# Flutter Test Plan (Dart)

**Goal:** Raise Flutter test coverage from effectively 0% to meaningful coverage across models, providers, services, screens, and widgets.

## Phase 1: Model Unit Tests (pure logic, no dependencies)

### 1.1 `test/models/offer_test.dart` (5 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | `fromJson` parses all fields | ID, title, description, prices, dates, status, images, restaurant |
| 2 | `discountLabel` calculates correctly | 30% → "30% off", LKR discount → "LKR 300 off" |
| 3 | `discountLabelLocalized` prefixes locale | si → "30% ක් ඉතුරුයි", ta → "30% தள்ளுபடி" |
| 4 | `saving` computes difference | Original 1000, offer 700 → 300 |
| 5 | `copyWith` updates selected field | copyWith(title: "new") → only title changed |

### 1.2 `test/models/restaurant_test.dart` (3 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | `fromJson` parses all fields | ID, name, slug, address, cuisine, social links, order URLs |
| 2 | `copyWith` works | Partial update preserves other fields |
| 3 | Null social links | instagram_url: null → field is null |

### 1.3 `test/models/app_user_test.dart` (3 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | `fromJson` parses all fields | ID, email, name, role, avatar URL |
| 2 | Role comparison helpers | isAdmin, isOwner helper methods |
| 3 | `copyWith` | Updates avatarUrl while preserving others |

### 1.4 `test/models/paginated_response_test.dart` (2 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | `fromJson` parses data + meta | Items list + pagination fields |
| 2 | Empty data list | data: [] → empty list |

## Phase 2: Utility Tests (pure functions, no dependencies)

### 2.1 `test/utils/currency_formatter_test.dart` (4 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | Formats integer | 1000 → "LKR 1,000" |
| 2 | Handles zero | 0 → "LKR 0" |
| 3 | Handles large numbers | 100000 → "LKR 100,000" |
| 4 | Handles decimal | 999.5 → "LKR 999.5" or rounded |

### 2.2 `test/utils/order_link_parser_test.dart` (6 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | Uber Eats URL detected | uber.com/eats → isUberEats = true, platformName = "Uber Eats" |
| 2 | PickMe URL detected | pickme.lk/food → isPickMe = true, platformName = "PickMe" |
| 3 | Normal URL detected | example.com → isGeneric = true, platformName = "Website" |
| 4 | Null URL | null → null returned |
| 5 | Empty URL | "" → null returned |
| 6 | URL with extra paths | Parse correctly despite deep paths |

## Phase 3: Widget Tests (7 widgets × 2-3 tests each)

### 3.1 `test/widgets/featured_banner_carousel_test.dart` (3 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | Renders with banners | Shows PageView with correct number of items |
| 2 | Sponsor name overlay | Sponsor name displayed on each banner |
| 3 | Auto-advances (timer) | After 5s, page index changes (use `tester.pump(Duration(seconds: 5))`) |

### 3.2 `test/widgets/offer_card_test.dart` (3 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | Renders title, price, discount | Text widgets present |
| 2 | Favorite button toggles | Tap toggles heart icon |
| 3 | Tap calls onTap callback | Callback fires with correct offer |

### 3.3 `test/widgets/hot_offer_card_test.dart` (2 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | Renders image, title, price | Key elements visible |
| 2 | Correct height based on theme | Height calculated from textTheme |

### 3.4 `test/widgets/order_buttons_test.dart` (2 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | Shows branded button for Uber | Uber Eats URL → shows Uber button |
| 2 | Shows branded button for PickMe | PickMe URL → shows PickMe button |

### 3.5 `test/widgets/empty_state_test.dart` (2 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | Shows default message | Empty state with provided text |
| 2 | Shows icon | Icon widget rendered alongside text |

### 3.6 `test/widgets/shimmer_loading_test.dart` (2 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | Renders shimmer boxes | Shimmer widgets render without errors |
| 2 | Custom count | Specified number of shimmer items rendered |

### 3.7 `test/widgets/follow_section_test.dart` (1 test)

| # | Test | Assertions |
|---|------|------------|
| 1 | Renders social links | Instagram, Facebook, Website buttons when URLs provided |

## Phase 4: Screen Widget Tests (6 screens × 2-4 tests each)

### 4.1 `test/screens/login_screen_test.dart` (4 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | Renders email + password fields | TextFormFields present |
| 2 | Shows validation on empty submit | Error messages appear |
| 3 | Invalid email shows error | "Enter a valid email" shown |
| 4 | Sign In button calls auth provider | AuthProvider.login called (mock) |

### 4.2 `test/screens/favorites_screen_test.dart` (4 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | Shows login gate when unauthenticated | "Sign in to view favorites" message |
| 2 | Shows empty state with no favorites | EmptyState widget |
| 3 | Shows favorite items when logged in | List of favorited offers |
| 4 | Pull-to-refresh works | RefreshIndicator fires reload |

### 4.3 `test/screens/offer_details_screen_test.dart` (4 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | Renders all sections | Hero image, title, price, countdown |
| 2 | Shows order buttons | Branded delivery buttons |
| 3 | Shows social follow section | Social links rendered |
| 4 | Share button present | Share icon in AppBar |

### 4.4 `test/screens/edit_profile_screen_test.dart` (3 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | Form loads with user data | Name + email fields pre-filled |
| 2 | Save updates profile | Calls provider method |
| 3 | Avatar upload bottom sheet | Camera/Gallery options shown on tap |

### 4.5 `test/screens/notifications_screen_test.dart` (2 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | Shows notification list | Notifications rendered from provider |
| 2 | Shows empty state | EmptyState when no notifications |

### 4.6 `test/screens/restaurants_screen_test.dart` (2 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | Shows restaurant list | Grid of restaurant cards |
| 2 | Tapping restaurant navigates | Navigation callback called |

## Phase 5: Provider Tests (3 providers × 3-4 tests each)

Require mocked services. Use existing `test/helpers/mocks.dart` infrastructure.

### 5.1 `test/providers/auth_provider_test.dart` (4 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | Login_Success | Calls AuthService.login, sets user + token |
| 2 | Login_Failure | Error state set, user null |
| 3 | Logout | Clears user + token |
| 4 | CheckAuth | Restores user from stored token |

### 5.2 `test/providers/offer_provider_test.dart` (3 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | loadOffers_Success | Populates offers list |
| 2 | loadOffers_Failure | Error state, offers empty |
| 3 | toggleFavorite | Adds/removes from favorites, calls API |

### 5.3 `test/providers/restaurant_provider_test.dart` (3 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | loadRestaurants_Success | Populates restaurants list |
| 2 | loadRestaurants_ForceRefresh | Skips guard when forceRefresh true |
| 3 | loadRestaurants_Empty | Empty list handled gracefully |

## Phase 6: Service Tests (3 critical services × 2-4 tests each)

### 6.1 `test/services/api_client_test.dart` (4 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | Adds auth header | Token injected from store |
| 2 | Cache interceptor caches GET | Same URL returns cached response |
| 3 | Cache interceptor skips POST | POST not cached |
| 4 | 401 clears auth | Auth store cleared on 401 |

### 6.2 `test/services/sse_service_test.dart` (3 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | Connects to SSE endpoint | EventSource created with correct URL |
| 2 | Parses offer events | "event:offer\n" → broadcast to listeners |
| 3 | Handles reconnection | On error, reconnects after delay |

### 6.3 `test/services/connectivity_service_test.dart` (2 tests)

| # | Test | Assertions |
|---|------|------------|
| 1 | Reports online | connectivityResult.wifi → isOnline = true |
| 2 | Reports offline | connectivityResult.none → isOnline = false |

## Phase 7: Home Screen Extension (3 additional tests for uncovered areas)

Add to existing `test/screens/home_screen_test.dart` (currently 7 tests, covers Hot Offers only)

| # | Test | Assertions |
|---|------|------------|
| 8 | Banner carousel renders | FeaturedBannerCarousel with banners from provider |
| 9 | Restaurant list section | List of restaurant cards below carousel |
| 10 | Loading state shows shimmer | ShimmerLoading during data fetch |

## Summary

| Phase | Area | New Tests |
|-------|------|-----------|
| 1 | Models | 13 |
| 2 | Utils | 10 |
| 3 | Widgets | 15 |
| 4 | Screens | 19 |
| 5 | Providers | 10 |
| 6 | Services | 9 |
| 7 | HomeScreen ext | 3 |
| **Total** | | **~79 test cases** |

## Running

```bash
flutter test
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```
