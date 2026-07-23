# Seed Data Realism Plan

## Problem
- All 11 restaurants assigned to single `owner@nomnom.lk` — RBAC scoping not demonstrated
- All 23 offers have `created_by` = admin UUID — owner can list offers but cannot get/update/delete individual ones
- No realistic owner-to-brand mapping

## Solution: 11 Owners, One Per Brand

### Owner Distribution

| # | Email | Name | Restaurant | Offers |
|---|---|---|---|---|
| 1 | `owner@nomnom.lk` | Pizza Hut Owner | Pizza Hut | 5 |
| 2 | `kfc@nomnom.lk` | KFC Owner | KFC | 3 |
| 3 | `breadtalk@nomnom.lk` | Bread Talk Owner | Bread Talk | 1 |
| 4 | `keells@nomnom.lk` | Keells Owner | Keells | 3 |
| 5 | `fab@nomnom.lk` | Fab Owner | Fab | 3 |
| 6 | `popeyes@nomnom.lk` | Popeyes Owner | Popeyes | 1 |
| 7 | `solobowl@nomnom.lk` | Solo Bowl Owner | Solo Bowl | 1 |
| 8 | `spar@nomnom.lk` | Spar Owner | Spar | 1 |
| 9 | `streetburger@nomnom.lk` | Street Burger Owner | Street Burger | 3 |
| 10 | `subway@nomnom.lk` | Subway Owner | Subway | 1 |
| 11 | `tacbell@nomnom.lk` | Taco Bell Owner | Taco Bell | 1 |

All development owners use the seed-only password defined in
`backend/scripts/seed.go`. It must never be reused for hosted accounts.
All have `is_active: true`, `email_verified_at: now`.

### Changes (only `backend/scripts/seed.go`)

1. **Replace `createRestaurantOwner()`** → `createOwners()` that creates all 11 owners, returns `map[string]uuid.UUID` keyed by brand slug (e.g. `"pizza-hut"` → owner UUID).
2. **Update restaurant `OwnerID`** — each restaurant uses the correct owner from the map instead of the single `ownerID`.
3. **Fix offer `CreatedBy`** — each offer's `CreatedBy` set to the restaurant's owner UUID instead of admin UUID.
4. **No other files change** — `owner@nomnom.lk` preserved for E2E tests; testutil uses hardcoded IDs.

### Files Changed
| File | Change |
|------|--------|
| `backend/scripts/seed.go` | Replace `createRestaurantOwner()` with `createOwners()` returning map; update restaurant + offer assignments |

### Expected Result After Re-seeding
- **Admin**: sees all 11 restaurants, 23 offers, 11 owners on Owners page
- **`owner@nomnom.lk`** (Pizza Hut): sees 1 restaurant + 5 offers, can CRUD them
- **`kfc@nomnom.lk`**: sees 1 restaurant + 3 offers, can CRUD them
- Each owner sees ONLY their own data — RBAC scoping properly demonstrated
- No `created_by` mismatch — owners can fully manage their offers
