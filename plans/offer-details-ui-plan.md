# Offer Details Screen — Enhanced UI/UX Plan

## Goal
Redesign the offer details screen with signature brand visuals, two separate order buttons (Uber Eats vs PickMe Uber), premium card-based layout, hero image with gradient overlay, and branded social follow section.

## Architecture
### Single `order_url` → Two separate fields
- `order_url` (existing — primary order link)
- `order_url_alt` (new — secondary/alternate order link)
- Both nullable `*string`, stored in `restaurants` table
- Flutter detects brand from domain (`ubereats.com` → Uber, `pickme.lk` → PickMe) for styling
- If both are non-null, show two side-by-side branded buttons
- If only one is non-null, show single full-width branded button
- If both null, hide the section

## Phases

### Phase 1 — Backend: Add `order_url_alt` field
| File | Change |
|---|---|
| `backend/internal/models/restaurant.go` | Add `OrderURLAlt *string` field with `gorm:"type:text" json:"order_url_alt,omitempty"` |
| `backend/internal/dto/request/restaurant_request.go` | Add `OrderURLAlt *string` with `json:"order_url_alt,omitempty"` to both Create + Update DTOs |
| `backend/internal/services/dashboard_service.go` | Map `OrderURLAlt` in `CreateRestaurant` + `UpdateRestaurant` |
| `backend/internal/services/restaurant_service.go` | Map `OrderURLAlt` in `Create` + `Update` |
| `backend/internal/handlers/restaurant_handler.go` | Add to `restaurantToMap` + `restaurantDetailToMap` |
| `backend/internal/handlers/dashboard_handler.go` | Add to `dashboardRestaurantToMap` + `dashboardRestaurantDetailToMap` |
| `backend/internal/handlers/offer_handler.go` | Add to `offerToMap` nested restaurant object |
| `backend/internal/repository/offer_repo.go` | Add `order_url_alt` to Preload `Select()` in both `FindAll` and `FindAllByOwner` |
| `backend/scripts/seed.go` | Add `OrderURLAlt` to some restaurants: Pizza Hut gets PickMe link, KFC gets Uber Eats link |

### Phase 2 — Flutter Model
| File | Change |
|---|---|
| `lib/models/offer.dart` | Add `orderUrlAlt` field, parse from `restaurant.order_url_alt`, include in `copyWith`/`toJson` |
| `lib/models/restaurant.dart` | Add `orderUrlAlt` field, parse in `fromJson`/`toJson`/`copyWith` |

### Phase 3 — Flutter Utility: Order Link Parser
**New file:** `lib/utils/order_link_parser.dart`
- `OrderLinkType` enum: `uberEats`, `pickMe`, `unknown`
- `parseOrderLink(String url)` → `OrderLinkType` — checks domain for `ubereats.com` or `pickme.lk`
- `uberBrandColor` → `Color(0xFF000000)` (black)
- `pickMeBrandColor` → `Color(0xFF009E60)` (PickMe green)
- `orderLinkIcon(OrderLinkType)` → appropriate `IconData`

### Phase 4 — New Widget: Order Buttons
**New file:** `lib/widgets/order_buttons.dart`
- `OrderButtonsSection` stateful widget with staggered fade-slide animation
- Accepts `String? orderUrl`, `String? orderUrlAlt`
- Logic:
  - If both non-null: `Row` with 2 `Expanded` children, each branded
  - If only one: single full-width branded button
  - If both null: empty `SizedBox.shrink()`
- Each button: `ElevatedButton` with brand color, brand-specific icon, "Order via Uber Eats" / "Order via PickMe" label
- Uses `url_launcher` with `LaunchMode.externalApplication`

### Phase 5 — New Widget: Follow Section
**New file:** `lib/widgets/follow_section.dart`
- `FollowSection` stateless widget with staggered fade-slide
- Accepts `String? instagramUrl`, `String? facebookUrl`, `String? websiteUrl`
- Renders branded icon buttons in a `Wrap`:
  - Instagram: pink gradient circular button (`Color(0xFFE4405F)`)
  - Facebook: blue circular button (`Color(0xFF1877F2)`)
  - Website: curry circular button (`AppColors.curry`)
- Each with `InkWell` + `Container` (56x56) + label below

### Phase 6 — New Widget: Info Card
**New file:** `lib/widgets/info_card.dart`
- `InfoCard` stateless widget
- Replaces `_InfoRow` — Card container with 12px radius, subtle elevation, left 4px curry accent bar
- Content: icon (brand-colored) + title (muted small) + value (bold primary)
- Animated via `_StaggeredFadeSlide`

### Phase 7 — New Widget: Price Panel (enhanced)
**New file:** `lib/widgets/price_panel.dart`
- `PricePanel` stateless widget
- Card container with 12px radius, left 4px curry accent bar
- Deal price in large bold curry text
- Original price with strikethrough
- "Save X" pill badge in `AppColors.lime` at top-right corner
- Countdown section: if `endDate` ≤ 7 days away, show "Ends in X days" or "Ends today" in a muted pill

### Phase 8 — Offer Details Screen Rewrite
**File:** `lib/screens/offer_details_screen.dart`
- **Hero image:** full-width below AppBar, replaces existing mid-body image
  - Aspect ratio 16:9
  - Gradient overlay (black 0.4 → transparent, bottom to top)
  - Discount pill positioned at top-right corner on the image
  - Restaurant name + offer title overlaid on gradient at bottom-left
- **AppBar:** transparent (`elevation: 0`, `backgroundColor: Colors.transparent`), white back arrow, title visible only when scrolled (scroll-to-collapse — optional stretch goal)
- **Scrollable body** (below hero):
  1. Price panel (Phase 6)
  2. Description text
  3. Info cards: Restaurant → Location → Discount (Phase 5)
  4. Follow section (Phase 4)
  5. Order buttons (Phase 3)
  6. Favorite button
- All sections wrapped in staggered fade-slide animations (kept from current pattern)

### Phase 9 — Admin Dashboard
| File | Change |
|---|---|
| `admin/src/app/dashboard/restaurants/_restaurant-dialog.tsx` | Add "Alternate Order URL" Input with label "Uber Eats / PickMe" next to existing Order URL field |
| `admin/src/app/dashboard/restaurants/[id]/page.tsx` | Render `order_url_alt` in Social & Order Links card |

### Phase 10 — Localization
| Key | en | si | ta |
|---|---|---|---|
| `offerOrderUberEats` | "Order via Uber Eats" | "Uber Eats හරහා ඇණවුම් කරන්න" | "Uber Eats மூலம் ஆர்டர் செய்யுங்கள்" |
| `offerOrderPickMe` | "Order via PickMe" | "PickMe හරහා ඇණවුම් කරන්න" | "PickMe மூலம் ஆர் டர் செய்யுங்கள்" |
| `offerEndsIn` | "Ends in {days} days" | "තව දින {days} කින් අවසන් වේ" | "{days} நாட்களில் முடிவடைகிறது" |
| `offerEndsToday` | "Ends today" | "අද අවසන් වේ" | "இன்று முடிவடைகிறது" |

### Phase 11 — Tests
| File | Test |
|---|---|
| `backend/internal/services/offer_service_test.go` | `TestOfferService_Create_WithAlternateOrderUrl` — verify `order_url_alt` round-trip |
| `backend/internal/handlers/integration_test.go` | `TestIntegration_OfferDetail_HasAlternateOrderUrl` — verify `order_url_alt` in API response |
| `admin/tests/pages/restaurants.page.ts` | Add `orderAltInput` locator + `fillOrderAlt()` method |
| `admin/tests/restaurant-crud.spec.ts` | Extend social links test to fill + verify alternate order URL |

## Migration
- GORM `AutoMigrate` handles adding the new column — no manual migration needed
- Existing seed data needs re-run to get `order_url_alt` values

## Total Files Changed
~27 files (9 backend, 6 Flutter, 2 admin, 4 test, ~3 ARB, 1 plan, 2 new widgets)
