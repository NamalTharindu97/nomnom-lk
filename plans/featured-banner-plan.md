# Featured Banners — Plan

## Overview
Replace the Hot Offers carousel with a **Featured Banner Carousel** on the home screen. Banners are image-based promotional cards that link to offers (or restaurants/external URLs). Both **admin** (global) and **restaurant owners** (scoped) can create banners. Owner-created banners require **admin approval** before going live — enabling future monetization (pay for approval).

---

## Backend

### Model — `backend/internal/models/banner.go`

```go
type BannerStatus string

const (
    BannerPending  BannerStatus = "pending"
    BannerApproved BannerStatus = "approved"
    BannerRejected BannerStatus = "rejected"
)

type Banner struct {
    ID          uuid.UUID    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
    Image       string       `gorm:"not null" json:"image"`
    LinkType    string       `gorm:"not null;size:20" json:"link_type"`    // "offer", "restaurant", "external"
    LinkValue   string       `gorm:"not null;size:255" json:"link_value"` // UUID or URL
    Title       string       `gorm:"size:100" json:"title,omitempty"`
    SponsorName string       `gorm:"size:100" json:"sponsor_name,omitempty"`
    SortOrder   int          `gorm:"default:0" json:"sort_order"`
    Status      BannerStatus `gorm:"type:varchar(20);default:pending;index" json:"status"`
    ClickCount  int          `gorm:"default:0" json:"click_count"`
    StartDate   *time.Time   `json:"start_date,omitempty"`
    EndDate     *time.Time   `json:"end_date,omitempty"`
    OwnerID     *uuid.UUID   `gorm:"type:uuid;index" json:"owner_id,omitempty"`
    OfferID     *uuid.UUID   `gorm:"type:uuid" json:"offer_id,omitempty"`
    CreatedAt   time.Time    `json:"created_at"`
    UpdatedAt   time.Time    `json:"updated_at"`
}

func (b *Banner) BeforeCreate(tx *gorm.DB) error {
    if b.ID == uuid.Nil {
        b.ID = uuid.New()
    }
    if b.Status == "" {
        b.Status = BannerPending
    }
    return nil
}
```

- `OwnerID = nil` + `Status = approved` → global banner (admin-created, always live)
- `OwnerID` set → owner-created, requires admin approval
- `OfferID` links to the promoted offer for direct navigation
- `LinkType` / `LinkValue` supports future non-offer link targets

### Migration — `backend/internal/database/postgres.go`
- Add `&models.Banner{}` to `db.AutoMigrate()` list

### Repository — `backend/internal/repository/banner_repo.go`

| Method | Purpose |
|---|---|
| `Create(banner) error` | Insert new banner |
| `FindAll() ([]Banner, error)` | All banners, ordered by `sort_order` (admin) |
| `FindAllByOwner(ownerID) ([]Banner, error)` | Owner's banners only (owner dashboard) |
| `FindAllActive() ([]Banner, error)` | `Status = "approved"`, within date range, ordered by `sort_order` (public) |
| `FindByID(id) (*Banner, error)` | Single banner |
| `Update(banner) error` | Full update |
| `Delete(id) error` | Hard delete |
| `Approve(id) error` | Set `Status = "approved"` |
| `Reject(id) error` | Set `Status = "rejected"` |
| `IncrementClickCount(id) error` | `UPDATE click_count = click_count + 1` |

### Handler — `backend/internal/handlers/banner_handler.go`

#### Admin routes (`/admin/banners`)

| Route | Method | Description |
|---|---|---|
| `/admin/banners` | GET | List ALL banners (global + owner) with status filter |
| `/admin/banners` | POST | Create global banner (`OwnerID = nil`, `Status = "approved"`) |
| `/admin/banners/:id` | PUT | Update any banner |
| `/admin/banners/:id` | DELETE | Delete any banner |
| `/admin/banners/:id/approve` | POST | Approve owner banner → `Status = "approved"` |
| `/admin/banners/:id/reject` | POST | Reject owner banner → `Status = "rejected"` |

#### Owner dashboard routes (`/dashboard/banners`)
Owner-scoped via existing `OwnerScoped` middleware.

| Route | Method | Description |
|---|---|---|
| `/dashboard/banners` | GET | List owner's banners |
| `/dashboard/banners` | POST | Create banner (must select one of owner's offers). `LinkType = "offer"`, `LinkValue = offerID`, `OfferID = offerID`, `OwnerID` set from scope. `Status = "pending"` |
| `/dashboard/banners/:id` | PUT | Update own banner (only if status is pending/rejected) |
| `/dashboard/banners/:id` | DELETE | Delete own banner |

**Offer ownership check on create:** Verify `offer_id` belongs to a restaurant owned by `owner_id`:
```go
// In handler:
offer, err := offerRepo.FindByID(offerID)
if err != nil || offer.Restaurant.OwnerID == nil || *offer.Restaurant.OwnerID != ownerID {
    response.ValidationError(c, ...)
    return
}
```

#### Public routes

| Route | Method | Description |
|---|---|---|
| `GET /banners/active` | GET | Returns all approved banners (global + owner), ordered by sort_order |
| `POST /banners/:id/click` | POST | Increment click count (fire-and-forget from Flutter) |

#### Offer deletion cascade
When an offer is deleted, auto-deactivate linked banners:
- In `OfferHandler.Delete()` or `DashboardHandler.DeleteOffer()`:
  ```go
  bannerRepo.DeactivateByOfferID(offerID) // sets Status = "rejected"
  ```

### Audit logging
All admin banner operations (create, approve, reject, update, delete) logged by `AuditTrail` middleware on `adminGroup`. Owner dashboard operations logged by `AuditTrail` middleware on `dashboardGroup`.

---

## Admin Dashboard — `admin/src/app/dashboard/banners/page.tsx`

### Nav items
- **Admin sidebar:** Add `"Banners"` to `adminNavItems`
- **Owner sidebar:** Add `"My Banners"` to `ownerNavItems`

### Admin view
- **Table columns:** Image thumbnail, Title, Sponsor Name, Owner (email if owned, empty if global), Linked Offer, Status badge (pending/approved/rejected), Sort Order, Clicks, Actions
- **Rows:** All banners, newest first
- **Admin actions per row:** 
  - Pending → [Approve] [Reject]
  - Approved → [Deactivate] (sets status to rejected)
  - Rejected → [Approve]
  - Edit, Delete always visible
- **Filters:** Status dropdown (All / Pending / Approved / Rejected), Owner email search
- **Create dialog:** Upload image, title, sponsor name, link type dropdown (offer/restaurant/external), link value, sort order, start/end dates. Create = global, no approval needed, immediately active.

### Owner view
- **Table columns:** Image thumbnail, Title, Linked Offer, Status badge, Sort Order, Clicks, Actions
- **Rows:** Only owner's banners
- **Owner actions:** Edit (only if pending/rejected), Delete
- **Create dialog:** Dropdown of owner's offers → select one → upload image → title → save. Status = pending, shows "Awaiting approval" message after save.
- **Status info text:** Pending → "Awaiting admin approval", Approved → "Live on app", Rejected → "Not approved. You can edit and resubmit."
- **No approve/reject buttons** (owner cannot self-approve)

---

## Flutter App

### Model — `lib/models/banner.dart`
```dart
class FeaturedBanner {
  final String id;
  final String image;
  final String linkType;
  final String linkValue;
  final String? title;
  final String? sponsorName;

  FeaturedBanner({...});

  factory FeaturedBanner.fromJson(Map<String, dynamic> json) => ...;
}
```

### Service — `lib/services/api_banner_service.dart`
```dart
class ApiBannerService {
  final ApiClient client;

  Future<List<FeaturedBanner>> fetchActiveBanners() async {
    final res = await client.get('/banners/active');
    final data = res['data'] as List;
    return data.map((j) => FeaturedBanner.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> trackClick(String bannerId) async {
    await client.post('/banners/$bannerId/click');
  }
}
```

### Provider — `lib/providers/banner_provider.dart`
```dart
class BannerProvider extends ChangeNotifier {
  List<FeaturedBanner> _banners = [];
  bool _isLoading = false;
  String? _error;

  Future<void> loadBanners({bool forceRefresh = false}) async {
    if (_banners.isNotEmpty && !forceRefresh) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _banners = await _bannerService.fetchActiveBanners();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}
```

### Widget — `lib/widgets/featured_banner_carousel.dart`

```dart
class FeaturedBannerCarousel extends StatefulWidget { ... }
```

- **Auto-scroll:** `Timer.periodic(4 seconds)`, `PageController`, pause on user drag
- **Layout:** `SizedBox(height: 200)` with `PageView` + dot indicators below
- **Card:** Full-width 16:9 image with rounded corners. Title overlay at bottom (semi-transparent gradient). Sponsor name small label ("Sponsored by Pizza Hut")
- **Tap handler:**
  1. Call `trackClick(banner.id)` (fire-and-forget, no await)
  2. Navigate based on `linkType`:
     - `"offer"` → `Navigator.pushNamed(AppRoutes.offerDetails, arguments: linkValue)`
     - `"restaurant"` → `Navigator.pushNamed(AppRoutes.restaurantDetails, arguments: linkValue)`
     - `"external"` → `await launchUrl(Uri.parse(linkValue))`
- **States:** Shimmer placeholder while loading, hidden (`SizedBox.shrink`) if banners empty

### Home screen — `lib/screens/home_screen.dart`
- Replace `_TrendingCarousel()` with `FeaturedBannerCarousel()` in the sliver list
- The `_TrendingCarousel` class and `hotOffers` can be removed or kept for later
- New sliver order:
  ```
  _HomeHeader → FeaturedBannerCarousel → _CuisineFilterChips → _HomeBody
  ```

### Provider registration — `lib/main.dart`
- Add `BannerProvider` to `MultiProvider` list
- Load banners on app startup alongside offers:
  ```dart
  final bannerProvider = BannerProvider(apiBannerService);
  bannerProvider.loadBanners();
  ```

---

## Implementation Order

| Phase | Files | Description |
|---|---|---|
| 1 | `banner.go`, `postgres.go`, `banner_repo.go` | Model + migration + repo |
| 2 | `banner_handler.go`, `router.go` | Backend routes (admin + owner + public) |
| 3 | `layout.tsx`, `banners/page.tsx` | Admin dashboard page + sidebar |
| 4 | `banner.dart`, `api_banner_service.dart`, `banner_provider.dart` | Flutter data layer |
| 5 | `featured_banner_carousel.dart`, `home_screen.dart`, `main.dart` | Flutter UI + integration |
| 6 | `featured-banner-plan.md` | This plan file |

---

## Notes
- Image upload: reuse existing `POST /api/v1/upload?folder=banners` endpoint. Banner images should be 1024×256 crop (wider aspect ratio than offers) via `cropSizeForFolder("banners")` in upload service.
- No translations needed (banners are image-based, title is optional English text)
- Future monetization: Add `payment_status` + `paid_until` fields, enable owner payment flow before approval
