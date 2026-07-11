# Restaurant Social Links + Direct Ordering

Add social media links (Instagram, Facebook, Website) to restaurant profiles, and "Order Now" buttons on the offer details page that deep-link to the restaurant's Uber Eats/PickMe page.

## Key Decisions

- **Single `order_url` field** instead of separate `uber_url` / `pickme_url` — flexible, restaurant provides whichever link they want
- **Deep linking** (not API-based ordering) — no merchant account/partnership required, works via `url_launcher`
- **Social links shown on both** offer details screen + restaurant detail page

---

## Part 1: Backend (Go)

### Files to modify

| # | File | Change |
|---|------|--------|
| 1 | `backend/internal/models/restaurant.go` | Add 4 nullable `*string` fields with GORM tags |
| 2 | `backend/internal/dto/request/restaurant_request.go` | Add fields to Create + Update request DTOs |
| 3 | `backend/internal/services/dashboard_service.go` | Copy fields from request to model in CreateRestaurant/UpdateRestaurant |
| 4 | `backend/internal/services/restaurant_service.go` | Same copy logic if exists |
| 5 | `backend/internal/handlers/restaurant_handler.go` | Include fields in `restaurantToMap` + `restaurantDetailToMap` |
| 6 | `backend/internal/handlers/dashboard_handler.go` | Include fields in `dashboardRestaurantToMap` + `dashboardRestaurantDetailToMap` |

### Step 1 — Model (`backend/internal/models/restaurant.go`)

Insert after `CoverImage` field (line 34):

```go
InstagramURL *string `gorm:"type:text" json:"instagram_url,omitempty"`
FacebookURL  *string `gorm:"type:text" json:"facebook_url,omitempty"`
WebsiteURL   *string `gorm:"type:text" json:"website_url,omitempty"`
OrderURL     *string `gorm:"type:text" json:"order_url,omitempty"`
```

GORM `AutoMigrate` creates nullable text columns automatically.

### Step 2 — Request DTOs (`backend/internal/dto/request/restaurant_request.go`)

**CreateRestaurantRequest** — add after `OwnerID`:
```go
InstagramURL string `json:"instagram_url,omitempty"`
FacebookURL  string `json:"facebook_url,omitempty"`
WebsiteURL   string `json:"website_url,omitempty"`
OrderURL     string `json:"order_url,omitempty"`
```

**UpdateRestaurantRequest** — add after `OwnerID`:
```go
InstagramURL *string `json:"instagram_url,omitempty"`
FacebookURL  *string `json:"facebook_url,omitempty"`
WebsiteURL   *string `json:"website_url,omitempty"`
OrderURL     *string `json:"order_url,omitempty"`
```

### Step 3 — Dashboard Service (`backend/internal/services/dashboard_service.go`)

In `CreateRestaurant` (after line 146):
```go
if req.InstagramURL != "" { restaurant.InstagramURL = &req.InstagramURL }
if req.FacebookURL != ""  { restaurant.FacebookURL = &req.FacebookURL }
if req.WebsiteURL != ""   { restaurant.WebsiteURL = &req.WebsiteURL }
if req.OrderURL != ""     { restaurant.OrderURL = &req.OrderURL }
```

In `UpdateRestaurant` (after existing pointer-checks):
```go
if req.InstagramURL != nil { restaurant.InstagramURL = req.InstagramURL }
if req.FacebookURL != nil  { restaurant.FacebookURL = req.FacebookURL }
if req.WebsiteURL != nil   { restaurant.WebsiteURL = req.WebsiteURL }
if req.OrderURL != nil     { restaurant.OrderURL = req.OrderURL }
```

### Step 4 — Restaurant Service (`backend/internal/services/restaurant_service.go`)

Apply same pattern as Step 3 if a separate `Create`/`Update` exists.

### Step 5 — Public handler serializers (`backend/internal/handlers/restaurant_handler.go`)

In both `restaurantToMap` and `restaurantDetailToMap`, add:
```go
"instagram_url": r.InstagramURL,
"facebook_url":  r.FacebookURL,
"website_url":   r.WebsiteURL,
"order_url":     r.OrderURL,
```

### Step 6 — Dashboard handler serializers (`backend/internal/handlers/dashboard_handler.go`)

In both `dashboardRestaurantToMap` and `dashboardRestaurantDetailToMap`, add same 4 fields.

---

## Part 2: Admin Dashboard (Next.js)

### Files to modify

| # | File | Change |
|---|------|--------|
| 1 | `admin/src/app/dashboard/restaurants/_restaurant-dialog.tsx` | Add 4 URL inputs to Zod schema + form |
| 2 | `admin/src/app/dashboard/restaurants/[id]/page.tsx` | Show links on detail page |

### Step 1 — Dialog schema + form (`_restaurant-dialog.tsx`)

**Zod schema** — add after line 28:
```ts
instagram_url: z.string().url("Invalid URL").or(z.literal("")).optional(),
facebook_url: z.string().url("Invalid URL").or(z.literal("")).optional(),
website_url: z.string().url("Invalid URL").or(z.literal("")).optional(),
order_url: z.string().url("Invalid URL").or(z.literal("")).optional(),
```

**Default values** — add four empty strings to `defaultValues`.

**Edit reset** — populate from `restaurant.instagram_url || ""` etc.

**Form section** — insert between cover image and translations:
```
Social & Order Links (h4)
├── Instagram URL (text input)
├── Facebook URL (text input)
├── Website URL (text input)
└── Order URL (text input, hint: "Uber Eats / PickMe link")
```

### Step 2 — Detail page (`restaurants/[id]/page.tsx`)

**Type interface** — add 4 nullable `string | null` fields.

**New card** — after the Details card, render a third "Social & Order Links" card with:
- Clickable Instagram link (external, `target="_blank"`)
- Clickable Facebook link
- Clickable Website link
- Clickable Order URL
- Empty state: "No links configured"

---

## Part 3: Flutter (Mobile App)

### Files to modify

| # | File | Change |
|---|------|--------|
| 1 | `lib/models/restaurant.dart` | Add 4 nullable fields + fromJson/toJson/copyWith |
| 2 | `lib/models/offer.dart` | Parse from nested `restaurant` JSON |
| 3 | `lib/screens/offer_details_screen.dart` | Add "Order Now" + "Follow" section |
| 4 | `lib/l10n/app_en.arb` | Add 5 localization keys |
| 5 | `lib/l10n/app_si.arb` | Add Sinhala translations |
| 6 | `lib/l10n/app_ta.arb` | Add Tamil translations |

### Step 1 — Restaurant model (`lib/models/restaurant.dart`)

Constructor + fields:
```dart
final String? instagramUrl;
final String? facebookUrl;
final String? websiteUrl;
final String? orderUrl;
```

`fromJson` — parse from keys `instagram_url`, `facebook_url`, `website_url`, `order_url`.

`toJson` — output same keys.

`copyWith` — add parameters and null-coalescing.

### Step 2 — Offer model (`lib/models/offer.dart`)

Constructor + fields (same 4 nullable `String?`).

`fromJson` — extract from nested `restaurant` object:
```dart
final r = json['restaurant'] as Map<String, dynamic>?;
instagramUrl: r?['instagram_url'] as String?,
facebookUrl: r?['facebook_url'] as String?,
websiteUrl: r?['website_url'] as String?,
orderUrl: r?['order_url'] as String?,
```

`toJson` — include in the nested `restaurant` map.

`copyWith` — add parameters.

### Step 3 — Offer details screen (`lib/screens/offer_details_screen.dart`)

After the FavoriteButton (index 7 at line 267), add:

**Order Now section** (only if `offer.orderUrl != null`):
- Section title: "Order Now" (localized)
- Full-width ElevatedButton with cart icon
- Calls `launchUrl(Uri.parse(offer.orderUrl!))` via `url_launcher`
- Styled in curry-orange (`AppColors.curry`)

**Follow section** (only if any social link exists):
- Section title: "Follow" (localized)
- Row of icon buttons:
  - Instagram (`Icons.camera_alt_rounded`) — visible if `offer.instagramUrl != null`
  - Facebook (`Icons.facebook_rounded`) — visible if `offer.facebookUrl != null`
  - Website (`Icons.language_rounded`) — visible if `offer.websiteUrl != null`
- Each calls `launchUrl()` with respective URL

Wrap both in `_StaggeredFadeSlide` with incremented indices (8, 9).
Add `import 'package:url_launcher/url_launcher.dart';` at top.

### Step 4 — ARB locale keys

**`app_en.arb`:**
```json
"offerOrderNow": "Order Now",
"offerOrderVia": "Order via Store",
"offerFollow": "Follow",
"offerVisitInstagram": "Instagram",
"offerVisitFacebook": "Facebook",
"offerVisitWebsite": "Website"
```

**`app_si.arb`:**
```json
"offerOrderNow": "දැන් ඇණවුම් කරන්න",
"offerOrderVia": "වෙළඳසැල හරහා ඇණවුම් කරන්න",
"offerFollow": "අනුගමනය කරන්න",
"offerVisitInstagram": "Instagram",
"offerVisitFacebook": "Facebook",
"offerVisitWebsite": "වෙබ් අඩවිය"
```

**`app_ta.arb`:**
```json
"offerOrderNow": "இப்போது ஆர்டர் செய்ய",
"offerOrderVia": "கடை மூலம் ஆர்டர் செய்ய",
"offerFollow": "பின்தொடர",
"offerVisitInstagram": "Instagram",
"offerVisitFacebook": "Facebook",
"offerVisitWebsite": "இணையதளம்"
```

---

## Implementation Order

```
1. Backend model + DTOs        → go build ./... ✓
2. Backend service + handlers   → go build ./... ✓
3. Admin dialog + detail page   → npx next build ✓
4. Flutter model + offer model  → flutter analyze ✓
5. Flutter offer details screen → flutter analyze ✓
6. ARB locale files             → flutter gen-l10n ✓
```

No existing behavior changes — all new fields are optional. Backend tests and Playwright E2E tests should pass without modification.
