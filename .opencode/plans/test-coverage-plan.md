# Test Coverage Expansion Plan

**Goal:** Close critical test gaps across backend (Go), Flutter (Dart), and admin E2E (Playwright) to reach 50%+ file coverage and cover all security-critical, data-integrity, and user-flow scenarios.

**Current State:** Backend ~11%, Flutter ~10%, Admin E2E ~14% page coverage. Zero tests for auth, impersonation, models, providers, services, and 4 admin pages.

**Approach:** Phased by priority (P0→P4), following existing conventions (hand-rolled mocks, testify assertions, Playwright POM pattern).

---

## Phase 1: Backend Unit Tests — Security & Auth (P0)

**Priority:** CRITICAL — must be written first.
**Pattern:** Hand-rolled mocks (in-memory maps), table-driven tests, `testify/assert` + `testify/require`.
**New files:**

### 1.1 `internal/services/auth_service_test.go`

Tests for `AuthService`:

| Test | Scenario |
|------|----------|
| `TestAuthService_Login_Success` | Valid email+password → returns tokens, user |
| `TestAuthService_Login_InvalidPassword` | Wrong password → error |
| `TestAuthService_Login_NonexistentEmail` | Email not found → error |
| `TestAuthService_Login_LockedAccount` | Account locked (LockedUntil > now) → error |
| `TestAuthService_Login_InactiveAccount` | is_active=false → error |
| `TestAuthService_Register_Success` | New email → user created, tokens returned |
| `TestAuthService_Register_DuplicateEmail` | Existing email → error |
| `TestAuthService_RefreshToken_Success` | Valid refresh token → new token pair |
| `TestAuthService_RefreshToken_InvalidToken` | Bad token → error |
| `TestAuthService_RefreshToken_ExpiredToken` | Expired token → error |
| `TestAuthService_FirebaseLogin_NewUser` | Firebase UID not in DB → user created |
| `TestAuthService_FirebaseLogin_ExistingUser` | Firebase UID exists → tokens returned |
| `TestAuthService_SendVerificationCode_Success` | Code stored in Redis with 60s TTL |
| `TestAuthService_VerifyEmail_Success` | Correct code → EmailVerifiedAt set |
| `TestAuthService_VerifyEmail_WrongCode` | Incorrect code → error |
| `TestAuthService_VerifyEmail_ExpiredCode` | Code expired → error |

**Mock requirements:** `mockUserRepo`, `mockRefreshTokenRepo`, `mockEmailService`, mock Redis client (or real Redis from testutil).

### 1.2 `internal/services/impersonation_service_test.go`

Tests for `ImpersonationService`:

| Test | Scenario |
|------|----------|
| `TestImpersonation_Start_Success` | Admin starts impersonation → original token stored in Redis |
| `TestImpersonation_Start_NonAdmin` | Non-admin → error |
| `TestImpersonation_Stop_Success` | Admin stops → original token returned, Redis key deleted |
| `TestImpersonation_Stop_NoActiveSession` | No session → error |
| `TestImpersonation_Status_Active` | During impersonation → returns original token info |
| `TestImpersonation_Status_Inactive` | No session → nil |

**Mock requirements:** `mockUserRepo`, mock Redis client.

### 1.3 `internal/middleware/active_test.go`

Tests for `RequireActive` middleware:

| Test | Scenario |
|------|----------|
| `TestRequireActive_UserIsActive` | is_active=true → 200 OK |
| `TestRequireActive_UserIsInactive` | is_active=false → 403 Forbidden |
| `TestRequireActive_NoUserID` | No user in context → 401 |

**Pattern:** Same as existing `rbac_test.go` — build gin router with middleware, use `httptest.NewRecorder`.

### 1.4 `internal/middleware/owner_scope_test.go`

Tests for `OwnerScoped` + `GetOwnerScopeID`:

| Test | Scenario |
|------|----------|
| `TestOwnerScope_AdminRole` | role=admin → context gets `uuid.Nil` (no scope) |
| `TestOwnerScope_OwnerRole` | role=restaurant_owner → context gets owner_id from user |
| `TestOwnerScope_NoRole` | No role in context → uuid.Nil |

### 1.5 `internal/middleware/dashboard_test.go`

Tests for `RequireDashboardAccess`:

| Test | Scenario |
|------|----------|
| `TestRequireDashboardAccess_AdminAllowed` | role=admin → pass |
| `TestRequireDashboardAccess_OwnerAllowed` | role=restaurant_owner → pass |
| `TestRequireDashboardAccess_UserRejected` | role=user → 403 |
| `TestRequireDashboardAccess_NoRole` | No role in context → 401 |

---

## Phase 2: Backend Unit Tests — Services & Repos (P1)

**Priority:** HIGH — data integrity.
**Pattern:** Hand-rolled mocks following existing `mockOfferRepo` pattern.

### 2.1 `internal/services/restaurant_service_test.go`

Tests for `RestaurantService`:

| Test | Scenario |
|------|----------|
| `TestRestaurantService_Create_Success` | Valid input → restaurant created |
| `TestRestaurantService_Update_Success` | Update fields → restaurant updated |
| `TestRestaurantService_Delete_Success` | Delete → restaurant removed |
| `TestRestaurantService_Delete_HasApprovedOffers` | Restaurant has approved offers → error |
| `TestRestaurantService_FindByID_Success` | Existing ID → restaurant returned |
| `TestRestaurantService_FindByID_NotFound` | Non-existent ID → error |
| `TestRestaurantService_Approve_Success` | Approve pending → status=approved |
| `TestRestaurantService_Reject_Success` | Reject pending → status=rejected |

### 2.2 `internal/services/dashboard_service_test.go`

Tests for `DashboardService`:

| Test | Scenario |
|------|----------|
| `TestDashboardService_GetStats_Admin` | Admin → all restaurants, all offers |
| `TestDashboardService_GetStats_Owner` | Owner → scoped to owner_id |
| `TestDashboardService_CreateRestaurant_Success` | Owner creates → restaurant gets owner_id |
| `TestDashboardService_CreateRestaurant_Admin` | Admin creates → no owner_id |
| `TestDashboardService_UpdateRestaurant_Success` | Owner updates own → success |
| `TestDashboardService_UpdateRestaurant_OtherOwner` | Owner updates other's → error |
| `TestDashboardService_DeleteRestaurant_Success` | Admin deletes → success |
| `TestDashboardService_DeleteRestaurant_OwnerOwn` | Owner deletes own (no offers) → success |
| `TestDashboardService_DeleteRestaurant_OwnerOther` | Owner deletes other's → error |

### 2.3 `internal/services/favorite_service_test.go`

Tests for `FavoriteService`:

| Test | Scenario |
|------|----------|
| `TestFavoriteService_Toggle_Add` | Not favorite → adds, returns true |
| `TestFavoriteService_Toggle_Remove` | Already favorite → removes, returns false |
| `TestFavoriteService_GetFavorites` | User has favorites → returns offer list |
| `TestFavoriteService_GetFavorites_Empty` | No favorites → empty list |

### 2.4 `internal/services/audit_service_test.go`

Tests for `AuditService`:

| Test | Scenario |
|------|----------|
| `TestAuditService_LogAction_Success` | Log action → audit record created |
| `TestAuditService_LogAction_WithRole` | Log with userRole → role stored |
| `TestAuditService_LogAction_EmptyDetails` | No details → empty string stored |

### 2.5 `internal/services/search_service_test.go`

Tests for `SearchService`:

| Test | Scenario |
|------|----------|
| `TestSearchService_SearchOffers_ByTitle` | Query matches offer title → returns results |
| `TestSearchService_SearchOffers_NoResults` | Query matches nothing → empty |
| `TestSearchService_SearchRestaurants_ByName` | Query matches restaurant name → returns |
| `TestSearchService_SearchCombined` | Query matches both → both returned |

### 2.6 New mock files

Create `internal/services/mocks_test.go` with shared mock types:

```go
// Shared mocks for all service tests
type mockUserRepo struct { users map[uuid.UUID]*models.User }
type mockRefreshTokenRepo struct { tokens map[string]*models.RefreshToken }
type mockEmailService struct { sent []emailCall }
type mockFavoriteRepo struct { favorites map[string]*models.Favorite }
type mockNotificationRepo struct { notifications []models.Notification }
type mockDeviceTokenRepo struct { tokens []models.DeviceToken }
```

---

## Phase 3: Backend Integration Tests (P1)

**Priority:** HIGH — full request lifecycle.
**Build tag:** `//go:build integration`
**Pattern:** Extend existing `internal/handlers/integration_test.go`.

### 3.1 `internal/handlers/auth_integration_test.go`

| Test | Scenario |
|------|----------|
| `TestIntegration_Login_Success` | POST /auth/login → 200 + tokens |
| `TestIntegration_Login_InvalidCredentials` | POST /auth/login → 401 |
| `TestIntegration_Register_Success` | POST /auth/register → 200 |
| `TestIntegration_Register_Duplicate` | POST /auth/register → 409 |
| `TestIntegration_RefreshToken_Success` | POST /auth/refresh → 200 |
| `TestIntegration_BrowserLogin_Success` | POST /auth/browser/login → 200 + cookies |
| `TestIntegration_BrowserLogout_Success` | POST /auth/browser/logout → 204 + cookies cleared |

### 3.2 `internal/handlers/notification_integration_test.go`

| Test | Scenario |
|------|----------|
| `TestIntegration_Notification_SendPush_Admin` | Admin sends push → 200 |
| `TestIntegration_Notification_SendPush_NonAdmin` | Non-admin → 403 |
| `TestIntegration_Notification_List` | GET /notifications → 200 + paginated list |
| `TestIntegration_Notification_MarkAsRead` | POST /notifications/:id/read → 204 |
| `TestIntegration_Notification_MarkAllAsRead` | POST /notifications/read-all → 204 |
| `TestIntegration_Notification_UnreadCount` | GET /notifications/unread-count → 200 |

### 3.3 `internal/handlers/dashboard_integration_test.go`

| Test | Scenario |
|------|----------|
| `TestIntegration_Dashboard_Stats_Admin` | GET /dashboard/stats → 200 + all stats |
| `TestIntegration_Dashboard_Stats_Owner` | Owner → scoped stats |
| `TestIntegration_Dashboard_Restaurants_Admin` | GET /dashboard/restaurants → 200 |
| `TestIntegration_Dashboard_Restaurants_Owner` | Owner → only own restaurants |
| `TestIntegration_Dashboard_CreateRestaurant_Owner` | Owner creates → gets owner_id |
| `TestIntegration_Dashboard_UpdateRestaurant_OwnerOwn` | Owner updates own → 200 |
| `TestIntegration_Dashboard_UpdateRestaurant_OtherOwner` | Owner updates other's → 403 |
| `TestIntegration_Dashboard_DeleteRestaurant_Admin` | Admin deletes → 204 |

### 3.4 `internal/handlers/user_integration_test.go`

| Test | Scenario |
|------|----------|
| `TestIntegration_User_List_Admin` | Admin → all users |
| `TestIntegration_User_List_Owner` | Owner → 403 |
| `TestIntegration_User_Create_Admin` | Admin creates user → 200 |
| `TestIntegration_User_Create_Owner` | Owner → 403 |

---

## Phase 4: Flutter Model Tests (P1)

**Priority:** HIGH — data integrity foundation.
**Pattern:** Pure unit tests, no widgets needed.
**Location:** `test/models/`

### 4.1 `test/models/offer_test.dart`

| Test | Scenario |
|------|----------|
| `fromJson parses complete offer` | All fields including nested restaurant |
| `fromJson handles nullable fields` | cuisine_tags, category_ids, image_urls can be null |
| `fromJson parses social_links` | JSON array of social link objects |
| `fromJson parses order_platforms` | JSON array of order platform objects |
| `toJson roundtrip` | fromJson(toJson(json)) == original |
| `discountPercent calculates correctly` | (1000-600)/1000 = 40% |
| `discountPercent handles zero original` | originalPrice=0 → 0 (no div/zero) |
| `discountPercent handles equal prices` | same price → 0% |
| `saving calculates correctly` | 1000-600 = 400 |
| `discountLabel for percentage` | "40% off" |
| `discountLabel for fixed amount` | "Rs. 400 off" |
| `discountLabelLocalized si` | Sinhala prefix "40% වට්ටමක්" |
| `discountLabelLocalized ta` | Tamil prefix "40% தள்ளுபடி" |
| `localizedTitle returns en` | English title when locale='en' |
| `localizedTitle falls back to en` | Unknown locale → English |
| `primaryImage returns first` | Multiple images → first |
| `primaryImage empty list` | No images → null |

### 4.2 `test/models/restaurant_test.dart`

| Test | Scenario |
|------|----------|
| `fromJson parses complete restaurant` | All fields |
| `fromJson handles nullable fields` | description, cuisine_tags nullable |
| `toJson roundtrip` | Consistent serialization |
| `copyWith updates name` | Only name changed, rest preserved |

### 4.3 `test/models/app_user_test.dart`

| Test | Scenario |
|------|----------|
| `fromJson parses user` | All fields including role, is_active |
| `fromJson guest factory` | AppUser.guest() → role='user', isGuest=true |
| `copyWith updates name` | Only name changed |
| `copyWith preserves other fields` | email, role unchanged |

### 4.4 `test/models/notification_model_test.dart`

| Test | Scenario |
|------|----------|
| `fromJson parses notification` | All fields including image_url |
| `fromJson handles null image_url` | image_url absent → null |
| `toJson roundtrip` | Consistent |
| `copyWith updates isRead` | Only isRead changed |

### 4.5 `test/models/paginated_response_test.dart`

| Test | Scenario |
|------|----------|
| `fromJson parses response` | offers, total, page, per_page |
| `hasMore when more pages` | page=1, totalPages=3 → true |
| `hasMore when last page` | page=3, totalPages=3 → false |

### 4.6 `test/models/social_link_test.dart`

| Test | Scenario |
|------|----------|
| `fromJson parses link` | platform, url fields |
| `toJson roundtrip` | Consistent |
| `listFromJson with null` | null → empty list |
| `listFromJson with list` | Parses each element |

### 4.7 `test/models/banner_test.dart`

| Test | Scenario |
|------|----------|
| `fromJson parses banner` | All fields |
| `fromJson handles nullable fields` | link_value, cta_text nullable |

---

## Phase 5: Flutter Provider Tests (P1)

**Priority:** HIGH — state management logic.
**Pattern:** Direct construction with mock services, no widgets needed.
**Location:** `test/providers/`

### 5.1 `test/providers/offer_provider_test.dart`

| Test | Scenario |
|------|----------|
| `loadOffers populates list` | Calls service, list populated |
| `loadOffers sets isLoading` | true during load, false after |
| `loadOffers error sets error` | Service throws → error set |
| `loadMoreOffers appends` | Already loaded, loadMore → more items |
| `loadMoreOffers no more` | hasMore=false → no load |
| `refreshOffers forces reload` | forceRefresh=true bypasses cache |
| `toggleFavorite adds` | Not favorite → adds, list updates |
| `toggleFavorite removes` | Favorite → removes |
| `toggleFavorite rollback on error` | API fails → optimistic add rolled back |
| `filterByCuisine filters` | Set cuisine → only matching offers |
| `clearCuisineFilter` | Clear → all offers shown |
| `filterByCategory filters` | Set category → only matching |
| `hotOffers returns top 5` | Sorted by discount, limited to 5 |
| `favoriteOffers filters` | Only favorited offers |
| `offerById finds` | Known ID → correct offer |

### 5.2 `test/providers/auth_provider_test.dart`

| Test | Scenario |
|------|----------|
| `restoreSession with tokens` | Tokens exist → user restored |
| `restoreSession no tokens` | No tokens → guest state |
| `signInWithEmail success` | Valid credentials → user set, tokens stored |
| `signInWithEmail failure` | Bad credentials → error set |
| `register success` | New user → user set |
| `signOut clears all` | Firebase + Google + stores + tokens cleared |
| `signOut concurrent guard` | Second signOut call → no-op |
| `continueAsGuest` | Sets guest user |

### 5.3 `test/providers/restaurant_provider_test.dart`

| Test | Scenario |
|------|----------|
| `loadRestaurants populates list` | Service returns → list populated |
| `loadRestaurants error` | Service throws → error set |
| `refreshRestaurants forces` | forceRefresh=true |
| `searchRestaurants filters` | Query → matching results |

### 5.4 `test/providers/notification_provider_test.dart`

| Test | Scenario |
|------|----------|
| `loadNotifications populates` | Service returns → list populated |
| `loadUnreadCount updates` | Count updated |
| `markAsRead updates state` | Notification marked, unread decremented |
| `markAllAsRead` | All marked read |

### 5.5 `test/providers/theme_provider_test.dart`

| Test | Scenario |
|------|----------|
| `toggle switches theme` | Light → Dark |
| `isDark reflects state` | After toggle → true |

### 5.6 `test/providers/locale_provider_test.dart`

| Test | Scenario |
|------|----------|
| `setLocale updates` | Change to 'si' → locale updated |
| `displayName returns correct` | 'si' → 'සිංහල' |
| `supportedLocales has 3` | en, si, ta |

---

## Phase 6: Flutter Service Tests (P2)

**Priority:** MEDIUM — API layer.
**Pattern:** Mock Dio HTTP client or hand-rolled fakes.
**Location:** `test/services/`

### 6.1 `test/services/api_client_test.dart`

| Test | Scenario |
|------|----------|
| `invalidateCache removes entry` | Cached request → invalidated |
| `clearCache removes all` | Multiple cached → all gone |
| `clearTokens removes storage` | Tokens cleared from secure storage |

### 6.2 `test/services/cache_interceptor_test.dart`

| Test | Scenario |
|------|----------|
| `cache hit returns cached` | Same request → cached response |
| `cache miss fetches fresh` | New request → fetched from network |
| `cache expiry refetches` | TTL expired → refetched |
| `invalidateCache specific` | Invalidate one → others preserved |

### 6.3 `test/services/auth_interceptor_test.dart`

| Test | Scenario |
|------|----------|
| `refreshes token on 401` | 401 → refresh → retry original request |
| `serializes concurrent refreshes` | Multiple 401s → single refresh call |
| `fails after max retries` | Refresh fails → error propagated |
| `uses isolated refresh client` | Refresh uses separate Dio |

### 6.4 `test/services/connectivity_service_test.dart`

| Test | Scenario |
|------|----------|
| `initial state online` | connectivityPlus returns true |
| `stream emits changes` | Connectivity changes → stream updates |

---

## Phase 7: Flutter Widget Tests (P2)

**Priority:** MEDIUM — UI correctness.
**Pattern:** `pumpWidget` with `MaterialApp` + `MultiProvider` + localization delegates.
**Location:** `test/widgets/`

### 7.1 `test/widgets/offer_card_test.dart`

| Test | Scenario |
|------|----------|
| `renders title` | Title text visible |
| `renders price` | "Rs. 600" visible |
| `renders discount badge` | "40% off" visible |
| `renders restaurant name` | Restaurant name visible |
| `renders favorite button` | Heart icon present |
| `maxLines truncates long title` | Long title → ellipsis |

### 7.2 `test/widgets/price_panel_test.dart`

| Test | Scenario |
|------|----------|
| `renders deal price` | Offer price visible |
| `renders original price strikethrough` | Original price with strikethrough |
| `renders save amount` | "Save Rs. 400" visible |
| `expiry within 7 days` | "Ends in 3 days" |
| `expiry today` | "Ends today" |

### 7.3 `test/widgets/empty_state_test.dart`

| Test | Scenario |
|------|----------|
| `renders icon title message` | All three visible |
| `retry button visible` | When onRetry provided |
| `no retry button` | When onRetry null |

### 7.4 `test/widgets/follow_section_test.dart`

| Test | Scenario |
|------|----------|
| `renders social pills` | Instagram, Facebook buttons |
| `empty links returns SizedBox` | No links → empty |

### 7.5 `test/widgets/order_buttons_test.dart`

| Test | Scenario |
|------|----------|
| `renders platform buttons` | Uber Eats, PickMe buttons |
| `empty platforms returns empty` | No platforms → nothing |

### 7.6 `test/widgets/info_card_test.dart`

| Test | Scenario |
|------|----------|
| `renders icon title value` | All three visible |

### 7.7 `test/widgets/app_logo_test.dart`

| Test | Scenario |
|------|----------|
| `compact mode no text` | compact=true → no "NomNom" text |
| `full mode shows brand` | compact=false → "NomNom" text |

---

## Phase 8: Flutter Screen Tests (P2)

**Priority:** MEDIUM — user flow validation.
**Pattern:** Pre-load provider state, `pumpWidget` with `MaterialApp` + providers.
**Location:** `test/screens/`

### 8.1 `test/screens/login_screen_test.dart`

| Test | Scenario |
|------|----------|
| `renders email field` | Email input visible |
| `renders password field` | Password input visible |
| `renders sign in button` | Button visible |
| `renders Google sign in` | Google button visible |
| `empty email shows error` | Submit empty → validation error |
| `invalid email shows error` | "not-an-email" → validation error |
| `short password shows error` | "123" → validation error |

### 8.2 `test/screens/register_screen_test.dart`

| Test | Scenario |
|------|----------|
| `renders all form fields` | Name, email, password, confirm visible |
| `renders register button` | Button visible |
| `password mismatch shows error` | Different passwords → error |
| `short password shows error` | "12" → error |

### 8.3 `test/screens/offer_details_screen_test.dart`

| Test | Scenario |
|------|----------|
| `shows loading initially` | CircularProgressIndicator |
| `renders offer title` | Title text visible (pre-loaded state) |
| `renders price panel` | Price, original, save visible |
| `renders order buttons` | Order section visible |

### 8.4 `test/screens/restaurants_screen_test.dart`

| Test | Scenario |
|------|----------|
| `shows restaurant list` | Restaurant cards visible |
| `empty state shows message` | No restaurants → EmptyState |
| `pull to refresh` | RefreshIndicator present |

### 8.5 `test/screens/favorites_screen_test.dart`

| Test | Scenario |
|------|----------|
| `guest shows login gate` | Not logged in → login prompt |
| `empty favorites shows message` | No favorites → EmptyState |

### 8.6 `test/screens/notifications_screen_test.dart`

| Test | Scenario |
|------|----------|
| `shows notification list` | Notification tiles visible |
| `empty state shows message` | No notifications → EmptyState |
| `unread dot visible` | Unread notification → curry dot |

---

## Phase 9: Admin E2E — Missing Pages (P2)

**Priority:** MEDIUM — recently added pages.
**Pattern:** Serial CRUD tests with E2E-prefixed names, POM where complex.
**Location:** `admin/tests/`

### 9.1 `admin/tests/cuisine-tags.spec.ts`

| Test | Scenario |
|------|----------|
| `create a cuisine tag` | Fill name → Create → tag visible |
| `edit a cuisine tag` | Click edit → update name → Update → new name |
| `delete a cuisine tag` | Click delete → confirm → tag gone |
| `shows validation for empty name` | Empty submit → error |

### 9.2 `admin/tests/order-platforms.spec.ts`

| Test | Scenario |
|------|----------|
| `create an order platform` | Fill name, slug, display_name → Create |
| `edit an order platform` | Update display_name → success |
| `delete an order platform` | Delete → gone |

### 9.3 `admin/tests/social-platforms.spec.ts`

| Test | Scenario |
|------|----------|
| `create a social platform` | Fill name, slug → Create |
| `edit a social platform` | Update → success |
| `delete a social platform` | Delete → gone |

### 9.4 `admin/tests/owners.spec.ts`

| Test | Scenario |
|------|----------|
| `owners page loads with table` | Heading + table visible |
| `shows owner stats cards` | Stats visible |
| `suspend an owner` | Click Suspend → confirm → Inactive |
| `activate an owner` | Click Activate → confirm → Active |
| `switch to owner (impersonation)` | Click Switch → banner shows "Viewing as" |
| `stop impersonation` | Click "Back to Admin" → banner gone |

---

## Phase 10: Admin E2E — Gap Filling (P3)

**Priority:** LOW — completeness.
**Location:** Extend existing spec files + new POMs.

### 10.1 Fix `restaurant-crud.spec.ts` — delete test

The existing `should delete a restaurant` test creates but never clicks delete. Fix:
- After creating, click delete → confirm dialog → assert row removed
- Use existing POM methods `clickDelete()` + `confirmDeleteDialog()`

### 10.2 Fix `users.spec.ts` — create/edit/delete

Add tests:
| Test | Scenario |
|------|----------|
| `create a user` | Open dialog → fill email/name/password/role → Create → user visible |
| `edit a user role` | Click role dropdown → change → updated |
| `delete a user` | Click delete → confirm → user gone |
| `shows validation errors` | Empty submit → errors |
| `status filter works` | Toggle Active/Inactive → filtered list |

### 10.3 Extend `notifications.spec.ts` — send + validation

Add tests:
| Test | Scenario |
|------|----------|
| `sends push notification` | Fill title+body → Send → success toast |
| `validates empty title` | Empty title → validation error |
| `validates empty body` | Empty body → validation error |
| `template selection populates form` | Select template → title+body filled |

### 10.4 Extend `banners.spec.ts` — admin CRUD

Add tests:
| Test | Scenario |
|------|----------|
| `admin creates banner with offer link` | Fill all fields → Create → visible |
| `admin edits banner` | Edit title → Update → success |
| `admin deletes banner` | Delete → confirm → gone |
| `admin rejects banner` | Reject → status=rejected |

### 10.5 Extend `audit-log.spec.ts` — filters

Add tests:
| Test | Scenario |
|------|----------|
| `action filter works` | Select "auth.login" → only login actions |
| `entity filter works` | Select "restaurant" → only restaurant actions |
| `search filters results` | Type query → filtered table |
| `clear filters resets` | Click Clear → all results shown |

### 10.6 Extend `settings.spec.ts` — password change

Add tests:
| Test | Scenario |
|------|----------|
| `successfully changes password` | Fill all fields → Update → success toast |
| `wrong current password` | Wrong password → error |
| `password mismatch` | Different new/confirm → error |

### 10.7 Extend `dashboard.spec.ts` — error/loading

Add tests:
| Test | Scenario |
|------|----------|
| `activity chart preset switching` | Click 7d/14d/30d → chart updates |
| `owner dashboard scoped view` | Owner login → scoped stats |

### 10.8 Add `LoginPage` POM usage

The POM exists but is never used. Add a login flow test:
| Test | Scenario |
|------|----------|
| `login with valid credentials` | Fill email+password → Sign in → redirect to dashboard |
| `login with invalid credentials` | Wrong password → error message |

---

## Phase 11: New Admin POMs (P3)

**Priority:** LOW — infrastructure.
**Location:** `admin/tests/pages/`

### 11.1 New POM files to create

| File | Purpose |
|------|---------|
| `cuisine-tags.page.ts` | goto, fillName, fillSlug, submit, expectRow |
| `order-platforms.page.ts` | goto, fillName, fillSlug, fillDisplayName, submit |
| `social-platforms.page.ts` | goto, fillName, fillSlug, submit |
| `owners.page.ts` | goto, getSuspendButton, getActivateButton, getSwitchButton, statsCards |
| `audit-log.page.ts` | goto, actionFilter, entityFilter, roleFilter, searchInput, clearFilters |

---

## Phase 12: Backend Repository Tests (P4)

**Priority:** LOW — foundation, but integration tests already cover repo layer.
**Build tag:** `//go:build integration`
**Pattern:** Real PostgreSQL via testutil, seed + query + assert.

### 12.1 `internal/repository/restaurant_repo_test.go`

| Test | Scenario |
|------|----------|
| `Create success` | Insert → returned with ID |
| `FindByID success` | Existing ID → restaurant |
| `FindByID not found` | Non-existent → error |
| `FindAll pagination` | Limit/offset → correct subset |
| `FindAllByOwner admin` | uuid.Nil → all restaurants |
| `FindAllByOwner scoped` | Specific owner → only their restaurants |
| `Update success` | Update fields → persisted |
| `Delete success` | Delete → not found on re-query |
| `FindPending` | Status=pending → returned |

### 12.2 `internal/repository/offer_repo_test.go`

| Test | Scenario |
|------|----------|
| `Create success` | Insert → returned with ID |
| `FindByID success` | Existing ID → offer |
| `FindAllByOwner admin` | uuid.Nil → all offers |
| `FindAllByOwner scoped` | Owner → only their offers |
| `Update success` | Fields updated |
| `Delete success` | Removed |
| `FindPending` | Status=pending → returned |

### 12.3 `internal/repository/user_repo_test.go`

| Test | Scenario |
|------|----------|
| `Create success` | Insert → returned |
| `FindByID success` | Existing → user |
| `FindByEmail success` | Email lookup → user |
| `FindAll status filter` | "inactive" → only inactive |
| `FindAll all` | "all" → no filter |
| `Update success` | Fields updated |
| `Delete success` | Removed |

---

## Execution Order & Effort Estimates

| Phase | Description | Files Created | Effort | Dependency |
|-------|-------------|--------------|--------|------------|
| **1** | Backend security (auth, impersonation, middleware) | 5 | 3h | — |
| **2** | Backend services (restaurant, dashboard, favorite, audit, search) | 6 | 4h | Phase 1 mocks |
| **3** | Backend integration tests | 4 | 3h | Docker services running |
| **4** | Flutter models | 7 | 2h | — |
| **5** | Flutter providers | 6 | 4h | Phase 4 models |
| **6** | Flutter services | 4 | 3h | — |
| **7** | Flutter widgets | 7 | 2h | — |
| **8** | Flutter screens | 6 | 3h | Phase 5 providers |
| **9** | Admin E2E missing pages | 4 | 3h | — |
| **10** | Admin E2E gap filling | 8 | 4h | — |
| **11** | Admin POMs | 5 | 1h | — |
| **12** | Backend repo tests | 3 | 2h | Docker services running |
| **Total** | | **65 files** | **~34h** | |

---

## Verification Commands

After each phase:

```bash
# Backend unit tests
cd backend && go test ./internal/... -v -count=1 -race

# Backend integration tests (requires Docker)
cd backend && docker compose up -d && sleep 10 && \
  go test -tags=integration ./internal/handlers/... -v -count=1 -timeout 120s

# Flutter unit/widget tests
flutter test --coverage

# Admin E2E tests (requires backend + admin running)
cd admin && npx playwright test

# Coverage reports
cd backend && go tool cover -func=coverage.out
cd admin && npx vitest run --coverage
```

---

## Target Metrics After Completion

| Layer | Current | Target |
|-------|---------|--------|
| Backend file coverage | 11% (5/47) | 55% (26/47) |
| Flutter file coverage | 10% (7/69) | 50% (35/69) |
| Admin E2E page coverage | 14% (2/14 pages full) | 64% (9/14 pages full) |
| Backend test count | ~35 | ~150 |
| Flutter test count | ~20 | ~120 |
| Admin E2E test count | ~56 | ~95 |
