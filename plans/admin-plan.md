# Admin Dashboard Plan

## P11 — Admin Dashboard Full CRUD
- `GET /admin/stats`, `GET /admin/notifications`
- `PUT /users/:id`, `DELETE /users/:id`
- Restaurant CRUD dialog
- OfferDialog
- User role dropdown
- PaginationBar
- 401 auto-logout interceptor
- Toast notifications (`@radix-ui/react-toast` with custom `ToastProvider` + `notify()`)
- Merged to master

## P14 — Admin UX Polish & Localization
- `GET /admin/stats/timeline` with daily offer & restaurant counts
- Translation fields (`_si`/`_ta`) in restaurant and offer dialogs
- Real chart data with dual bars
- Loading skeletons on dashboard cards
- Merged to master

## P15 — Admin SSE Status Filter
- Admin offers/restaurants pages pass `status=all` to see all statuses (approved, pending, rejected)

## P17 — Admin Dialog Fixes
- Offer dialog field name mismatch fix: `desc_si`/`desc_ta` → `description_si`/`description_ta`
- Restaurant cover image upload
- Translation fields flattened in API responses

## P20 — Admin Notification Page
- Admin notifications page auto-clears result message after 5s

## P21 — UX Foundation (Quick Wins)
- Search & filters on restaurants, offers, users pages (name/email/title search; status/role filter dropdowns)
- Loading skeletons on all table pages (replace "Loading..." text)
- Confirmation dialogs — shadcn `AlertDialog` replacing raw `confirm()` on delete/reject
- Empty state components — replace "No X found" text with illustrations
- Error boundaries — per-page React error boundaries to prevent full dashboard crash
- No backend changes needed

## P22 — CRUD Completion
- User create/edit form — backend already supports `PUT /users/:id`; add create endpoint + modal form (name, email, role, is_active)
- Restaurant owner assignment — owner dropdown in restaurant dialog (fetch `/admin/users?role=restaurant_owner`)
- Restaurant cover image — preview + remove in edit mode
- Offer image reordering — drag-and-drop reorder on `image_urls` array
- Date range filter — on dashboard timeline chart
- Backend: `POST /users` create endpoint; `GET /users?role=restaurant_owner` filter

## P23 — Settings & Activity Log
- Admin settings page — change password form
- Activity/audit log — new page tracking admin actions (who created/edited/deleted what, timestamp)
- Backend: `AuditLog` model + migration; `POST /change-password`; `GET /admin/audit-log` (paginated, filterable)

## P24 — Bulk Actions & Data Export
- Bulk selection — checkbox rows on restaurants, offers, users tables
- Bulk actions — approve / reject / delete selected items
- CSV export — download visible or all filtered rows as CSV for any table
- Restaurant detail page — full-page view with inline offer list (beyond edit dialog)
- Backend: `POST /admin/restaurants/bulk` (action + ids); `POST /admin/offers/bulk`; `POST /admin/users/bulk`

## P25 — Analytics & Reports
- Analytics/reports page — new top-level nav item
  - Top restaurants by offer count / favorites
  - Top offers by favorites / views
  - User growth chart (registrations over time)
  - Offer approval/rejection rate
- Backend: `GET /admin/analytics/top-restaurants`, `GET /admin/analytics/top-offers`, `GET /admin/analytics/user-growth`, `GET /admin/analytics/offer-stats`

## P26 — Notification Enhancements
- Notification templates — create/edit/delete templates with `{{variable}}` placeholders
- Template picker — select template in push notification form, auto-fill body
- Scheduled notifications — pick date/time for future delivery
- Notification analytics — delivery rate, sent/failed/pending counts per notification
- Backend: `NotificationTemplate` model + CRUD endpoints; scheduling via cron/goroutine; analytics aggregation

## P27 — Advanced Features
- Coupon/promo code management — new domain: create, activate, deactivate, validate codes
- Offer category tags — manage categories, assign to offers, filter by category
- Manual offer expiry — force-expire an offer early
- Scheduled offer publish — set `publish_at` for future activation
- Backend: `Coupon` model + CRUD; `Category` model; scheduled publish/expiry worker

## Future
- Form validation: `react-hook-form` + `zod` + `@hookform/resolvers` — packages installed but could be used more
- Theme: Custom `ThemeProvider` (localStorage key `nomnom-theme`), curry-orange brand palette, sidebar CSS vars theme-aware
