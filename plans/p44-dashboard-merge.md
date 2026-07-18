# P44 — Dashboard + Analytics Merge

## Goal
Merge the analytics page into the dashboard, creating a single comprehensive admin overview with all platform data. Remove the standalone analytics page. Owner dashboard stays simple (unchanged).

## Target Layout (Admin)

```
┌─────────────────────────────────────────────────────────────────┐
│  Stat Cards (6)                                                 │
│  [Restaurants] [Offers] [Users] [Pending] [Approval%] [Devices]│
├──────────────────────────────┬──────────────────────────────────┤
│  Activity Timeline (7/14/30d)│  Top Restaurants by Offers       │
├──────────────────────────────┼──────────────────────────────────┤
│  Top Offers by Favorites     │  Top Offers by Views             │
├──────────────────────────────┼──────────────────────────────────┤
│  User Growth (30d line)      │  Offers by Status (bar)          │
├──────────────────────────────┼──────────────────────────────────┤
│  Recent Activity (last 5)    │  Expiring Soon (next 7d)         │
├──────────────────────────────┼──────────────────────────────────┤
│  Banner Stats                │  Coupon Stats                    │
│  Total | Pending | Clicks    │  Active | Redemptions            │
├──────────────────────────────┴──────────────────────────────────┤
│  Notification Stats (Sent | Pending | Failed)                   │
├─────────────────────────────────────────────────────────────────┤
│  Quick Actions                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Owner dashboard** stays as-is (4 stat cards + quick actions). No changes.

---

## Implementation Plan

### Phase 1: Backend — 2 New Endpoints + Extend Stats

**1a.** `GET /admin/analytics/expiring-offers` — offers ending within N days
- Handler: `AnalyticsExpiringOffers` in `admin_handler.go`
- Repo: `FindExpiringOffers(days int)` in `offer_repo.go`
- Query: `WHERE end_date IS NOT NULL AND end_date > NOW() AND end_date < NOW() + interval AND status = 'approved' ORDER BY end_date ASC LIMIT 10`
- Returns: `[{offer_id, title, restaurant_name, end_date, discount}]`

**1b.** `GET /admin/analytics/device-stats` — device counts by platform
- Handler: `AnalyticsDeviceStats` in `admin_handler.go`
- Repo: `CountByPlatform()` in `device_token_repo.go`
- Returns: `{ios: N, android: N}`

**1c.** Extend `GET /admin/stats` — add banner/coupon/notification aggregates
- New response fields: `active_banners, pending_banners, total_banner_clicks, active_coupons, total_coupon_redemptions, total_notifications_sent, total_notifications_pending, total_notifications_failed`
- New repo methods: `bannerRepo.CountByStatus()`, `couponRepo.CountStats()`, `notificationRepo.CountByStatus()`
- Routes: 2 new routes in analytics group

### Phase 2: Frontend — Merge Analytics Into Dashboard

- 10 API calls via `Promise.all` (parallel)
- 6 stat cards, 6 charts, 3 insight widgets, Quick Actions
- Skeleton loading for all sections

### Phase 3: Remove Analytics Page

- Delete `analytics/page.tsx`
- Remove "Analytics" from sidebar nav (13 → 12 items)
- Remove `/dashboard/analytics` from `adminOnlyPaths`

### Phase 4: Skeletons + Loading States

### Phase 5: Testing — `go build`, `next build`, `tsc`, 51 E2E tests

---

## Files Changed

| File | Change |
|------|--------|
| `backend/internal/handlers/admin_handler.go` | Add 2 handlers, extend Stats() |
| `backend/internal/repository/offer_repo.go` | Add `FindExpiringOffers()` |
| `backend/internal/repository/device_token_repo.go` | Add `CountByPlatform()` |
| `backend/internal/repository/banner_repo.go` | Add `CountByStatus()`, `TotalClicks()` |
| `backend/internal/repository/coupon_repo.go` | Add `CountStats()` |
| `backend/internal/repository/notification_repo.go` | Add `CountByStatus()` |
| `backend/internal/router/router.go` | Add 2 routes |
| `admin/src/app/dashboard/page.tsx` | Full rewrite — merge analytics |
| `admin/src/app/dashboard/analytics/page.tsx` | **Delete** |
| `admin/src/app/dashboard/layout.tsx` | Remove analytics nav + guard |

## Success Criteria

- [ ] `/dashboard` shows all stat cards, charts, widgets
- [ ] `/dashboard/analytics` removed from nav
- [ ] Owner dashboard unchanged
- [ ] `go build ./...` passes
- [ ] `next build` passes
- [ ] `npx tsc --noEmit` passes
- [ ] All 51 E2E tests pass
