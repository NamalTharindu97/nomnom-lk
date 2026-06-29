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

## Future
- Form validation: `react-hook-form` + `zod` + `@hookform/resolvers` — packages installed but could be used more
- Theme: Custom `ThemeProvider` (localStorage key `nomnom-theme`), curry-orange brand palette, sidebar CSS vars theme-aware
