# Role-Based Access Control (RBAC) Plan

## Overview

Implement proper access control levels for the NomNom LK web dashboard (admin panel) with three tiers:

| Role | Web Access | Data Visibility |
|------|-----------|-----------------|
| `user` | **Blocked** — cannot log in to web dashboard | N/A |
| `restaurant_owner` | **Restricted** — sees only their own restaurants, offers, and stats | Scoped to owned resources |
| `admin` | **Full** — sees all data across all owners, users, restaurants, offers | Global |

---

## Current State Analysis

### Backend (Go)
- **Roles defined:** `user`, `restaurant_owner`, `admin` in `models/user.go`
- **JWT claims:** `sub` (user ID), `email`, `role` — role is embedded in every token
- **Middleware:** `Auth()` validates JWT, `RequireRole(roles...)` checks role match
- **Gap:** `restaurant_owner` role has NO middleware-level protection — ownership is checked only at service layer via UUID matching
- **Gap:** Restaurant delete has no ownership check (any authenticated user can delete)
- **Gap:** No `RequireRole("restaurant_owner", "admin")` on any route

### Admin Dashboard (Next.js)
- **Auth check:** Only at login time — rejects `role !== "admin"` with error message
- **No server-side route protection:** No `middleware.ts` / `proxy.ts` file exists
- **No role-based UI:** All 11 nav items visible to any authenticated user
- **Gap:** localStorage tampering could bypass the login gate (backend would still reject API calls)
- **Gap:** `requireAuth()` helper defined but never used

---

## Implementation Plan

### Phase 1: Backend RBAC Hardening

#### 1.1 New Middleware: `RequireDashboardAccess`
Create `backend/internal/middleware/dashboard.go`:
```go
// Allows restaurant_owner and admin; blocks user role
func RequireDashboardAccess() gin.HandlerFunc {
    return func(c *gin.Context) {
        role := GetUserRole(c)
        if role != "restaurant_owner" && role != "admin" {
            c.AbortWithStatusJSON(403, gin.H{"error": "Web dashboard access restricted"})
            return
        }
        c.Next()
    }
}
```

#### 1.2 New Middleware: `OwnerScoped`
Create `backend/internal/middleware/owner_scope.go`:
```go
// For restaurant_owner: injects owner_id filter into context
// For admin: no filter (sees everything)
func OwnerScoped() gin.HandlerFunc {
    return func(c *gin.Context) {
        role := GetUserRole(c)
        userID := GetUserID(c)
        if role == "restaurant_owner" {
            c.Set("owner_scope_id", userID)
        }
        c.Next()
    }
}
```

#### 1.3 Route Restructuring
Restructure `router.go` to add dashboard-specific route groups:

```
/api/v1/                          (public routes — unchanged)
/api/v1/auth/*                    (auth routes — unchanged)
/api/v1/dashboard/*               (NEW — dashboard-only routes)
  GET  /dashboard/restaurants     (owner-scoped: only own restaurants)
  GET  /dashboard/offers          (owner-scoped: only own offers)
  GET  /dashboard/stats           (owner-scoped: only own stats)
  POST /dashboard/restaurants     (create restaurant — owner gets pending)
  POST /dashboard/offers          (create offer — owner gets pending)
  PUT  /dashboard/restaurants/:id (update own restaurant)
  PUT  /dashboard/offers/:id      (update own offer)
  DELETE /dashboard/restaurants/:id (delete own restaurant)
  DELETE /dashboard/offers/:id    (delete own offer)
  GET  /dashboard/notifications   (own notifications)
  POST /dashboard/devices         (register device)
  DELETE /dashboard/devices       (unregister device)
  GET  /dashboard/profile         (own profile)
  POST /dashboard/change-password (change own password)
/api/v1/admin/*                   (admin-only — unchanged)
```

#### 1.4 Repository Layer Changes
Add owner-scoped query methods:

```go
// restaurant_repo.go
func (r *RestaurantRepo) ListByOwner(ownerID string, pagination) ([]Restaurant, int64, error)
func (r *RestaurantRepo) GetByOwnerAndID(ownerID, restaurantID string) (*Restaurant, error)

// offer_repo.go
func (r *OfferRepo) ListByOwner(ownerID string, pagination) ([]Offer, int64, error)
func (r *OfferRepo) GetByOwnerAndID(ownerID, offerID string) (*Offer, error)
```

#### 1.5 Service Layer Changes
- Add `DashboardRestaurantService` and `DashboardOfferService` that always filter by owner
- Fix restaurant delete: add ownership check
- Add owner-scoped stats endpoint (count of own restaurants, offers, views, favorites)

#### 1.6 Fix Existing Gaps
- Add ownership check to restaurant delete
- Add `RequireRole("restaurant_owner", "admin")` to dashboard routes
- Ensure all admin routes use `RequireRole("admin")`

---

### Phase 2: Admin Dashboard Frontend RBAC

#### 2.1 Server-Side Route Protection (proxy.ts)
Create `admin/src/proxy.ts` (Next.js 16 uses `proxy.ts` instead of `middleware.ts`):

```typescript
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function proxy(request: NextRequest) {
  const token = request.cookies.get('token')?.value
  const userStr = request.cookies.get('user')?.value
  
  if (!token) {
    return NextResponse.redirect(new URL('/login', request.url))
  }
  
  const user = userStr ? JSON.parse(userStr) : null
  
  if (!user || (user.role !== 'admin' && user.role !== 'restaurant_owner')) {
    return NextResponse.redirect(new URL('/login?error=forbidden', request.url))
  }
  
  return NextResponse.next()
}

export const config = {
  matcher: ['/dashboard/:path*'],
}
```

**Note:** This requires moving token/user storage from `localStorage` to cookies for proxy access.

#### 2.2 Auth Context Enhancement
Update `use-auth.tsx`:

```typescript
interface AuthContext {
  user: User | null
  token: string | null
  login: (email: string, password: string) => Promise<void>
  logout: () => void
  isLoading: boolean
  isAdmin: boolean
  isOwner: boolean
  canAccess: (feature: string) => boolean
}
```

#### 2.3 Role-Based Navigation
Update `dashboard/layout.tsx` sidebar:

```typescript
const adminNavItems = [
  { label: 'Dashboard', href: '/dashboard', icon: LayoutDashboard },
  { label: 'Restaurants', href: '/dashboard/restaurants', icon: Store },
  { label: 'Offers', href: '/dashboard/offers', icon: Tag },
  { label: 'Users', href: '/dashboard/users', icon: Users },
  { label: 'Notifications', href: '/dashboard/notifications', icon: Bell },
  { label: 'Templates', href: '/dashboard/templates', icon: FileText },
  { label: 'Coupons', href: '/dashboard/coupons', icon: Ticket },
  { label: 'Categories', href: '/dashboard/categories', icon: FolderTree },
  { label: 'Analytics', href: '/dashboard/analytics', icon: BarChart3 },
  { label: 'Audit Log', href: '/dashboard/audit-log', icon: ScrollText },
  { label: 'Settings', href: '/dashboard/settings', icon: Settings },
]

const ownerNavItems = [
  { label: 'Dashboard', href: '/dashboard', icon: LayoutDashboard },
  { label: 'My Restaurants', href: '/dashboard/restaurants', icon: Store },
  { label: 'My Offers', href: '/dashboard/offers', icon: Tag },
  { label: 'Notifications', href: '/dashboard/notifications', icon: Bell },
  { label: 'Settings', href: '/dashboard/settings', icon: Settings },
]

const navItems = user?.role === 'admin' ? adminNavItems : ownerNavItems
```

#### 2.4 Role-Based Page Guards
Create `admin/src/components/role-guard.tsx`:

```typescript
export function RoleGuard({ allowedRoles, children, fallback }: {
  allowedRoles: string[]
  children: React.ReactNode
  fallback?: React.ReactNode
}) {
  const { user } = useAuth()
  if (!user || !allowedRoles.includes(user.role)) {
    return fallback || <AccessDenied />
  }
  return <>{children}</>
}
```

Wrap admin-only pages:
```typescript
export default function UsersPage() {
  return (
    <RoleGuard allowedRoles={['admin']}>
      <UsersContent />
    </RoleGuard>
  )
}
```

#### 2.5 Owner-Scoped Dashboard
Create owner-specific dashboard view:

```typescript
export default function DashboardPage() {
  const { user } = useAuth()
  
  if (user?.role === 'admin') {
    return <AdminDashboard />
  }
  
  return <OwnerDashboard />
}
```

#### 2.6 API Client Updates
Update `admin/src/lib/api.ts`:

```typescript
function getBasePath() {
  const user = JSON.parse(localStorage.getItem('user') || '{}')
  if (user.role === 'admin') {
    return '/api/v1'
  }
  return '/api/v1/dashboard'
}
```

---

### Phase 3: Admin Owner Management

#### 3.1 Owner Access Control Page
Create `admin/src/app/dashboard/owners/page.tsx`:
- List all restaurant owners
- Toggle owner access (activate/deactivate)
- View owner's restaurants and offers
- Assign/remove owner role from users

#### 3.2 Backend Endpoints
```
GET    /api/v1/admin/owners              (list all owners with stats)
PUT    /api/v1/admin/users/:id/role      (change user role)
POST   /api/v1/admin/users/:id/suspend   (suspend owner access)
POST   /api/v1/admin/users/:id/activate  (reactivate owner access)
```

#### 3.3 User Model Enhancement
Add `is_active` field to User model:
```go
type User struct {
    IsActive     bool       `json:"is_active" gorm:"default:true"`
    SuspendedAt  *time.Time `json:"suspended_at,omitempty"`
}
```

Update auth middleware to check `is_active`:
```go
if !user.IsActive {
    c.AbortWithStatusJSON(403, gin.H{"error": "Account suspended"})
    return
}
```

---

### Phase 4: Testing & Security

#### 4.1 Backend Tests
- Unit tests for `RequireDashboardAccess` middleware
- Unit tests for `OwnerScoped` middleware
- Integration tests for dashboard endpoints (owner sees only own data)
- Integration tests for admin endpoints (admin sees all data)
- Test that `user` role gets 403 on dashboard routes

#### 4.2 Frontend Tests
- E2E test: `user` role cannot log in to dashboard
- E2E test: `restaurant_owner` sees only own restaurants/offers
- E2E test: `admin` sees all restaurants/offers
- E2E test: owner nav items differ from admin nav items
- E2E test: owner cannot access /dashboard/users, /dashboard/analytics, etc.

#### 4.3 Security Review
- Verify JWT token validation on every request
- Verify ownership checks cannot be bypassed
- Verify cookie-based auth is secure (httpOnly, secure, sameSite)
- Verify no sensitive data leaks between owners

---

## File Changes Summary

### Backend (New/Modified)
| File | Action | Description |
|------|--------|-------------|
| `internal/middleware/dashboard.go` | NEW | Dashboard access middleware |
| `internal/middleware/owner_scope.go` | NEW | Owner-scoped data middleware |
| `internal/handlers/dashboard_handler.go` | NEW | Dashboard-specific handlers |
| `internal/services/dashboard_service.go` | NEW | Owner-scoped business logic |
| `internal/repository/restaurant_repo.go` | MODIFY | Add `ListByOwner`, `GetByOwnerAndID` |
| `internal/repository/offer_repo.go` | MODIFY | Add `ListByOwner`, `GetByOwnerAndID` |
| `internal/router/router.go` | MODIFY | Add `/dashboard/*` route group |
| `internal/models/user.go` | MODIFY | Add `is_active`, `suspended_at` fields |
| `internal/middleware/auth.go` | MODIFY | Check `is_active` on auth |
| `internal/services/restaurant_service.go` | MODIFY | Fix delete ownership check |

### Admin Dashboard (New/Modified)
| File | Action | Description |
|------|--------|-------------|
| `src/proxy.ts` | NEW | Server-side route protection |
| `src/components/role-guard.tsx` | NEW | Role-based page guard |
| `src/components/access-denied.tsx` | NEW | Access denied page |
| `src/app/dashboard/owners/page.tsx` | NEW | Owner management page |
| `src/app/dashboard/page.tsx` | MODIFY | Role-based dashboard view |
| `src/app/dashboard/layout.tsx` | MODIFY | Role-based navigation |
| `src/hooks/use-auth.tsx` | MODIFY | Add `isAdmin`, `isOwner`, cookie storage |
| `src/lib/api.ts` | MODIFY | Role-based API base path |
| `src/app/login/page.tsx` | MODIFY | Allow owner login, show role-specific error |

---

## Implementation Order

1. **Phase 1** (Backend) — 3-4 days
   - Middleware + route restructuring
   - Repository + service layer changes
   - Fix existing gaps

2. **Phase 2** (Frontend) — 3-4 days
   - proxy.ts + cookie auth
   - Role-based nav + page guards
   - Owner-scoped dashboard

3. **Phase 3** (Owner Management) — 2 days
   - Owner list page
   - Suspend/activate endpoints

4. **Phase 4** (Testing) — 2 days
   - Backend + frontend tests
   - Security review

**Total: ~10-12 days**

---

## Key Design Decisions

1. **Separate `/dashboard/*` routes** instead of filtering existing routes — cleaner separation of concerns, easier to audit
2. **Cookie-based auth** instead of localStorage — enables server-side route protection via proxy.ts
3. **Owner-scoped middleware** instead of per-handler checks — DRY, consistent behavior
4. **Role-based nav items** instead of hiding with CSS — prevents rendering unauthorized UI
5. **`is_active` flag** instead of deleting users — preserves audit trail, allows reactivation
