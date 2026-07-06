# Owner Scoping Fix Plan

## Problem
Restaurant owners can see ALL restaurants and offers instead of only their own. The Pizza Hut owner (`owner@nomnom.lk`) sees all 11 restaurants and 23 offers.

## Root Cause
Frontend dashboard pages call **public endpoints** instead of **owner-scoped endpoints**:
- Restaurants page calls `/restaurants` (public) instead of `/dashboard/restaurants` (scoped)
- Offers page calls `/offers` (public) instead of `/dashboard/offers` (scoped)

## Backend Status ✅
The backend is correctly configured:
- `/api/v1/dashboard/*` routes use `OwnerScoped` middleware
- `GetOwnerScopeID()` returns user ID for owners, `uuid.Nil` for admins
- `FindAllByOwner()` filters by `owner_id` when not `uuid.Nil`
- Seed data has 11 owners, each with their own restaurant and offers

## Required Changes

### 1. Frontend API Endpoint Updates

#### Files to Update:
1. `admin/src/app/dashboard/restaurants/page.tsx`
   - Line 70: `/restaurants` → `/dashboard/restaurants`
   - Line 87: `/restaurants/${id}/${action}` → `/dashboard/restaurants/${id}/${action}` (approve/reject)
   - Line 96: `/restaurants/${deleteTarget.id}` → `/dashboard/restaurants/${deleteTarget.id}`
   - Line 106: `/admin/restaurants/bulk` → `/dashboard/restaurants/bulk` (if bulk actions needed)

2. `admin/src/app/dashboard/offers/page.tsx`
   - Line 74: `/offers` → `/dashboard/offers`
   - Line 90: `/offers/${id}/${action}` → `/dashboard/offers/${id}/${action}` (approve/reject)
   - Line 98: `/offers/${id}/expire` → `/dashboard/offers/${id}/expire`
   - Line 108: `/offers/${deleteTarget.id}` → `/dashboard/offers/${deleteTarget.id}`
   - Line 118: `/admin/offers/bulk` → `/dashboard/offers/bulk` (if bulk actions needed)

3. `admin/src/app/dashboard/restaurants/[id]/page.tsx` (restaurant detail page)
   - Update all `/restaurants/${id}` calls to `/dashboard/restaurants/${id}`
   - Update offer creation to use `/dashboard/offers`

4. `admin/src/app/dashboard/offers/_offer-dialog.tsx`
   - Update restaurant dropdown to fetch from `/dashboard/restaurants` (scoped)
   - Update offer creation/edit to use `/dashboard/offers`

5. `admin/src/app/dashboard/page.tsx` (main dashboard)
   - Update stats call to `/dashboard/stats`
   - Update recent data calls to scoped endpoints

### 2. Backend Endpoint Additions (if needed)

#### Missing Endpoints:
- `POST /dashboard/restaurants/:id/approve` - Owner approve restaurant
- `POST /dashboard/restaurants/:id/reject` - Owner reject restaurant (maybe not needed for owners)
- `POST /dashboard/offers/:id/approve` - Owner approve offer
- `POST /dashboard/offers/:id/reject` - Owner reject offer (maybe not needed)
- `POST /dashboard/offers/:id/expire` - Owner force expire offer
- `POST /dashboard/restaurants/bulk` - Bulk actions for owners
- `POST /dashboard/offers/bulk` - Bulk actions for owners

**Decision**: Should owners be able to approve/reject their own restaurants/offers?
- Option A: Owners can only create (status = pending), admin approves
- Option B: Owners can approve their own (auto-approve or manual)
- Option C: Mixed - some auto-approve, some require admin

**Recommendation**: Option A (current behavior) - owners create, admin approves. Remove approve/reject buttons from owner view.

### 3. Frontend UI Adjustments

#### Role-Based UI:
1. **Hide admin-only actions for owners**:
   - Approve/Reject buttons (if Option A above)
   - Bulk approve/reject actions
   - Status filter (owners only see their own data anyway)

2. **Show owner-specific UI**:
   - "My Restaurants" instead of "All Restaurants"
   - "My Offers" instead of "All Offers"
   - Status badges showing approval state

3. **Restaurant creation**:
   - Auto-assign `owner_id` from current user (backend already does this)
   - Show pending status until admin approves

### 4. Data Verification

#### Current Seed Data Status ✅:
- 11 owners created (one per restaurant)
- Each restaurant has correct `owner_id`
- Each offer has `created_by` = restaurant's owner
- Admin sees all: 11 restaurants, 23 offers
- KFC owner sees: 1 restaurant, 3 offers (verified via API)

#### Verification Steps:
1. Login as `owner@nomnom.lk` (Pizza Hut owner)
2. Navigate to `/dashboard/restaurants` → should see only Pizza Hut
3. Navigate to `/dashboard/offers` → should see only Pizza Hut's 5 offers
4. Create new restaurant → should be assigned to current owner
5. Create new offer → should be linked to owner's restaurant

### 5. Testing Plan

#### Manual Testing:
1. **Admin login** (`namal@nomnom.lk`):
   - See all 11 restaurants, 23 offers, 11 owners
   - Can approve/reject any restaurant/offer
   - Can perform bulk actions

2. **Owner login** (`owner@nomnom.lk` - Pizza Hut):
   - See only 1 restaurant (Pizza Hut), 5 offers
   - Can create new restaurant (status = pending)
   - Can create new offer for Pizza Hut (status = pending)
   - Cannot see other restaurants/offers
   - Cannot approve/reject (buttons hidden)

3. **Different owner login** (`kfc@nomnom.lk`):
   - See only 1 restaurant (KFC), 3 offers
   - Cannot access Pizza Hut's data

#### Automated Testing:
- Update E2E tests to verify owner scoping
- Add tests for:
  - Owner sees only their restaurants
  - Owner sees only their offers
  - Owner cannot access other owner's data
  - Admin sees all data

## Implementation Order

### Phase 1: Frontend Endpoint Updates (Critical)
1. Update `restaurants/page.tsx` to use `/dashboard/restaurants`
2. Update `offers/page.tsx` to use `/dashboard/offers`
3. Update `restaurants/[id]/page.tsx` to use `/dashboard/restaurants/:id`
4. Update `_offer-dialog.tsx` to use scoped endpoints
5. Update main `dashboard/page.tsx` to use `/dashboard/stats`

**Test**: Login as owner, verify only own data visible

### Phase 2: UI Adjustments (UX)
1. Add role checks to hide admin-only buttons
2. Update page titles ("My Restaurants" vs "All Restaurants")
3. Show approval status prominently for owners

**Test**: Verify owners don't see approve/reject buttons

### Phase 3: Backend Endpoint Additions (if needed)
1. Add missing dashboard endpoints based on Phase 1 gaps
2. Add bulk action endpoints for owners (if needed)

**Test**: Verify all CRUD operations work for owners

### Phase 4: Testing & Verification
1. Manual testing with multiple owner accounts
2. Update E2E tests
3. Verify data isolation between owners

## Success Criteria
- ✅ Owner sees only their own restaurants
- ✅ Owner sees only their own offers
- ✅ Owner can create new restaurants (auto-assigned to them)
- ✅ Owner can create offers for their restaurants only
- ✅ Admin sees all data (no change)
- ✅ Data isolation verified across multiple owner accounts
- ✅ All E2E tests passing

## Notes
- Backend scoping logic is already correct and tested
- Seed data is already correct (11 owners, proper assignments)
- Main issue is frontend calling wrong endpoints
- Consider adding API response field `owner_scoped: true` to help frontend detect scoping
