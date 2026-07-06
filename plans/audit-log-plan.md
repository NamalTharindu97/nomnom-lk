# Audit Log System — Comprehensive Coverage

## Goal
Full audit trail for ALL state-changing actions by both admins and restaurant owners. Two-tier approach: **middleware auto-log** as universal safety net on every route group + **semantic logs** with entity names on critical handlers for human readability. Cross-field search on the admin page.

---

## Gaps Identified (Post-Initial-Implementation)

### Routes with NO audit coverage at all (30 routes across 10 groups)

| Priority | Group | Missing |
|----------|-------|---------|
| Critical | `restaurantsGroup` | Create, Update, Delete (no middleware, no semantic) |
| Critical | `offersGroup` | Create, Update, Delete |
| Critical | `adminUsers` | Create |
| Critical | `authGroup` | Login, Logout, FirebaseLogin |
| Important | `authGroup` | Register, Refresh, SendVerification, VerifyEmail |
| Important | `uploadGroup` | Upload, UploadMultiple |
| Low | `favoritesGroup` | Add, Remove |
| Low | `notificationsGroup` | MarkAsRead, MarkAllAsRead |
| Low | `devicesGroup` | RegisterDevice, UnregisterDevice |

### Routes with middleware auto-log but NO semantic entity names

| Group | Routes | Auto-logged as | Missing semantic |
|-------|--------|---------------|-----------------|
| `dashboardGroup` | 6 CRUD routes | `POST.restaurants`, etc. | `restaurant.create/update/delete`, `offer.create/update/delete` |
| `adminGroup` | NotificationTemplates CRUD, Coupons CRUD, Categories CRUD | `POST.coupons`, etc. | entity names with human-readable text |

### Search broken
- `FindAllFiltered` searches only `admin_name ILIKE` — can't find by action, entity_type, entity_id, or details

---

## Implementation Plan

### Phase 1: Universal auto-log coverage
Add `AuditTrail` middleware to ALL route groups with mutating routes.

| Group | Change |
|-------|--------|
| `adminUsers` | Add `.Use(AuditTrail)` |
| `restaurantsGroup` auth sub-group | Add `.Use(AuditTrail)` |
| `offersGroup` auth sub-group | Add `.Use(AuditTrail)` |
| `authGroup` mutating routes | Add `.Use(AuditTrail)` after Auth middleware |
| `verificationGroup` | Add `.Use(AuditTrail)` |
| `notificationsGroup` | Add `.Use(AuditTrail)` after Auth |
| `devicesGroup` | Add `.Use(AuditTrail)` after Auth |
| `uploadGroup` | Add `.Use(AuditTrail)` after Auth |
| `impersonationGroup` | Add `.Use(AuditTrail)` after Auth |

### Phase 2: Dashboard handler semantic logs
Inject `AuditService` into `DashboardHandler`, add 6 semantic log calls with entity name:

| Handler Method | Action | Details Example |
|---------------|--------|----------------|
| `CreateRestaurant` | `restaurant.create` | "Created restaurant: Pizza Hut" |
| `UpdateRestaurant` | `restaurant.update` | "Updated restaurant: Pizza Hut" |
| `DeleteRestaurant` | `restaurant.delete` | "Deleted restaurant: Pizza Hut (id: ...)" |
| `CreateOffer` | `offer.create` | "Created offer: 50% Off Burgers" |
| `UpdateOffer` | `offer.update` | "Updated offer: 50% Off Burgers" |
| `DeleteOffer` | `offer.delete` | "Deleted offer: 50% Off Burgers (id: ...)" |

### Phase 3: Fill remaining handler gaps
Add semantic log calls in handlers already wired with `AuditService`:

| Handler | Method | Action |
|---------|--------|--------|
| `RestaurantHandler` | Create | `restaurant.create` |
| `RestaurantHandler` | Update | `restaurant.update` |
| `RestaurantHandler` | Delete | `restaurant.delete` |
| `OfferHandler` | Create | `offer.create` |
| `OfferHandler` | Update | `offer.update` |
| `OfferHandler` | Delete | `offer.delete` |
| `UserHandler` | Create | `user.create` |
| `AuthHandler` | Login | `auth.login` |
| `AuthHandler` | Logout | `auth.logout` |
| `AuthHandler` | Register | `auth.register` |
| `AuthHandler` | FirebaseLogin | `auth.firebase` |

### Phase 4: Cross-field search
Change `FindAllFiltered` to search across ALL fields via OR:
```
admin_name ILIKE ? OR action ILIKE ? OR entity_type ILIKE ? OR entity_id::text ILIKE ? OR details ILIKE ?
```

### Phase 5: Frontend improvements
- Debounced search input (300ms)
- Placeholder: "Search all logs..."
- Show user role alongside name

---

## File Change Summary

| File | Phase |
|------|-------|
| `plans/audit-log-plan.md` | (this file) |
| `backend/internal/router/router.go` | 1 |
| `backend/internal/handlers/dashboard_handler.go` | 2 |
| `backend/internal/handlers/restaurant_handler.go` | 3 |
| `backend/internal/handlers/offer_handler.go` | 3 |
| `backend/internal/handlers/user_handler.go` | 3 |
| `backend/internal/handlers/auth_handler.go` | 3 |
| `backend/internal/repository/audit_log_repo.go` | 4 |
| `admin/src/app/dashboard/audit-log/page.tsx` | 5 |

**8 files changed. No restructured code.**
