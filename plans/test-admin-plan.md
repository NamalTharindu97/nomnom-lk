# Admin E2E Test Plan (Playwright)

**Goal:** Raise admin dashboard E2E coverage from 50 tests to ~80 tests, covering all 14 pages and critical workflows.

## Phase 1: Missing Pages

### 1.1 `banners.spec.ts` — Banners page (8 tests)

| # | Test | Steps |
|---|------|-------|
| 1 | Admin creates a banner | Click "New Banner", fill title, image URL, sponsor name, select offer, submit → table shows banner |
| 2 | Admin creates banner without image | Empty image URL → error toast |
| 3 | Owner creates a banner | Login as owner, create → visible in table with pending status |
| 4 | Admin approves a banner | Click Approve → status changes to approved |
| 5 | Admin rejects a banner | Click Reject → status changes to rejected |
| 6 | Admin edits a banner | Click edit, change title/sort order, save → updated in table |
| 7 | Admin deletes a banner | Click delete, confirm → removed from table |
| 8 | Banner form cancel hides form | Click "New Banner", then Cancel → form disappears |

**Page Object:** `tests/pages/banners.page.ts` — `BannersPage` + `BannerDialog`

### 1.2 `owners.spec.ts` — Owners page (6 tests)

| # | Test | Steps |
|---|------|-------|
| 1 | Page loads with owner list | Navigate to Owners → table shows 11 owner rows |
| 2 | Owner stats display correctly | Each row shows restaurant count, offer count |
| 3 | Suspend an owner | Click Suspend → confirm → owner status changes to suspended |
| 4 | Activate a suspended owner | Click Activate → status restored |
| 5 | Impersonate an owner (Switch) | Click "Switch" → ImpersonationBanner appears showing "Viewing as {name}" |
| 6 | Stop impersonation | Click "Back to Admin" → banner gone, sidebar shows admin nav |

## Phase 2: Weak Coverage → Full Coverage

### 2.1 `users.spec.ts` — Users page (extend to 8 tests)

Current: 2 (list only). New total: 8

| # | Test | Steps |
|---|------|-------|
| 1 | *Existing: displays users table* | — |
| 2 | *Existing: shows admin user in list* | — |
| 3 | Create a new user | Click "New User", fill email/name/role/password, submit → table shows new user |
| 4 | Edit a user's role | Change role via Select dropdown → success toast, badge updated |
| 5 | Delete a user | Click delete, confirm → removed from table |
| 6 | Search by email | Type in search → table filters |
| 7 | Filter by role | Select "restaurant_owner" → only owners shown |
| 8 | Filter by status | Select "Inactive" → only deactivated users shown |

### 2.2 `offers-workflow.spec.ts` — Offer approval workflow (5 tests)

| # | Test | Steps |
|---|------|-------|
| 1 | Admin approves a pending offer | As admin on offers page, click Approve → status changes to approved |
| 2 | Admin rejects a pending offer | Click Reject → status changes to rejected |
| 3 | Admin expires an approved offer | Click Expire → status changes to expired |
| 4 | Owner cannot see approve/reject buttons | Login as owner, verify approve/reject/expire buttons not present |
| 5 | Owner sees status badge | Owner can see the status of their offers |

### 2.3 `restaurant-workflow.spec.ts` — Restaurant approval workflow (3 tests)

| # | Test | Steps |
|---|------|-------|
| 1 | Admin approves a pending restaurant | Click Approve → status changes |
| 2 | Admin rejects a pending restaurant | Click Reject → status changes |
| 3 | Owner cannot see approve/reject buttons | Verify absent when logged as owner |

### 2.4 `bulk-operations.spec.ts` — Bulk actions (extend to 6 tests)

Current: 3 (UI only). New total: 6

| # | Test | Steps |
|---|------|-------|
| 1 | *Existing: checkboxes appear* | — |
| 2 | *Existing: bulk bar shows buttons* | — |
| 3 | *Existing: clear deselects all* | — |
| 4 | Bulk approve restaurants | Select multiple restaurants, click Approve → all approved |
| 5 | Bulk delete offers | Select multiple offers, click Delete → all removed |
| 6 | Bulk delete users | Select multiple users, click Delete → all deactivated |

### 2.5 `audit-log.spec.ts` — Audit log (extend to 6 tests)

Current: 2 (load only). New total: 6

| # | Test | Steps |
|---|------|-------|
| 1 | *Existing: page loads with table* | — |
| 2 | *Existing: table has correct headers* | — |
| 3 | Search across audit logs | Type in search → table filters in real-time (debounced) |
| 4 | Filter by action | Select action from dropdown → only matching logs shown |
| 5 | Filter by role | Select admin/owner role → filtered |
| 6 | Pagination works | If > 10 entries, click page 2 → shows next page |

### 2.6 `analytics.spec.ts` — Analytics (extend to 4 tests)

Current: 2 (load only). New total: 4

| # | Test | Steps |
|---|------|-------|
| 1 | *Existing: page loads with stat cards* | — |
| 2 | *Existing: charts render without errors* | — |
| 3 | Top restaurants chart shows data | Chart contains restaurant names |
| 4 | Top offers chart shows data | Chart contains offer titles |

### 2.7 `settings.spec.ts` — Settings (extend to 4 tests)

Current: 2 (render only). New total: 4

| # | Test | Steps |
|---|------|-------|
| 1 | *Existing: change password form renders* | — |
| 2 | *Existing: validation for empty fields* | — |
| 3 | Change password successfully | Fill current + new password + confirm, submit → success toast |
| 4 | Wrong current password fails | Fill wrong current password → error toast |

### 2.8 `notifications.spec.ts` — Notification send (extend to 7 tests)

Current: 5 (form UI only). New total: 7

| # | Test | Steps |
|---|------|-------|
| 1 | *Existing: send notification form* | — |
| 2 | *Existing: notification history table* | — |
| 3 | *Existing: user combobox when target specific* | — |
| 4 | *Existing: hide combobox when target all* | — |
| 5 | *Existing: search and select user* | — |
| 6 | Send push notification to all users | Select "All Users", fill title/body, submit → success toast |
| 7 | Send push notification to specific user | Select "Specific User", pick user, submit → success toast |

## Phase 3: Page Object Cleanup

Create page objects for pages currently using raw selectors:

| Page Object | For |
|-------------|-----|
| `tests/pages/banners.page.ts` | BannersPage + BannerDialog |
| `tests/pages/owners.page.ts` | OwnersPage |
| `tests/pages/settings.page.ts` | SettingsPage |
| `tests/pages/audit-log.page.ts` | AuditLogPage |
| `tests/pages/analytics.page.ts` | AnalyticsPage |
| `tests/pages/categories.page.ts` | CategoriesPage |
| `tests/pages/coupons.page.ts` | CouponsPage |
| `tests/pages/templates.page.ts` | TemplatesPage |

## Total: ~30 new test cases (50 → 80 total)

## Running

```bash
cd admin
npx playwright test
```
