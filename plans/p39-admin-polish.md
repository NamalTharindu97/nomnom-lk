# P39 — Admin UX Polish

## Goal
Complete three remaining admin dashboard gaps: (1) user edit form, (2) scheduled offer publishing via `publish_at`, and (3) consistent form validation using `react-hook-form` + `zod` across all forms.

---

## Gap 1 — User Edit Form

### Current State
`_user-dialog.tsx` only implements create mode. The users table (`users/page.tsx`) has no "Edit" button. The only way to modify a user is inline role change or delete.

**Backend support:** `PUT /users/:id` already exists (P11). No backend changes needed.

### Implementation

#### `admin/src/app/dashboard/users/_user-dialog.tsx`

**Accept optional `user` prop for edit mode:**
```typescript
interface UserDialogProps {
  open: boolean
  onClose: () => void
  user?: User | null  // null/undefined = create mode, User = edit mode
}
```

**Pre-fill form fields when editing:**
```typescript
useEffect(() => {
  if (user) {
    setName(user.name)
    setEmail(user.email)
    setRole(user.role)
    setPassword('') // Password field starts empty in edit mode
  }
}, [user])
```

**Submit logic:**
```typescript
const handleSubmit = async () => {
  if (user) {
    // Edit mode — PUT
    await api.put(`/users/${user.id}`, {
      name, email, role,
      ...(password && { password }) // Only send password if changed
    })
  } else {
    // Create mode — POST
    await api.post('/users', { name, email, password, role })
  }
  onClose()
  onSuccess()
}
```

**Password field hint in edit mode:**
```tsx
{user && (
  <p className="text-sm text-muted-foreground">
    Leave blank to keep current password
  </p>
)}
```

#### `admin/src/app/dashboard/users/page.tsx`

**Add "Edit" button to each user row:**
```tsx
// In the table columns definition, after the role column:
<DropdownMenuItem onClick={() => { setEditingUser(user); setDialogOpen(true) }}>
  <Pencil className="mr-2 h-4 w-4" />
  Edit
</DropdownMenuItem>
```

**State for edit:**
```typescript
const [editingUser, setEditingUser] = useState<User | null>(null)
```

**Wire the dialog:**
```tsx
<UserDialog
  open={dialogOpen}
  onClose={() => { setDialogOpen(false); setEditingUser(null) }}
  user={editingUser}
/>
```

### Files Changed
| File | Change |
|------|--------|
| `admin/src/app/dashboard/users/_user-dialog.tsx` | Add `user` prop, edit mode logic, conditional password |
| `admin/src/app/dashboard/users/page.tsx` | Add Edit button, `editingUser` state |

---

## Gap 2 — `publish_at` Field for Offers

### Current State
Offers go live immediately when approved. There is no mechanism to schedule offers to go live at a future date.

### Backend Changes

#### `backend/internal/models/offer.go`

Add `PublishAt` field:
```go
type Offer struct {
    // ... existing fields ...
    PublishAt *time.Time `gorm:"index" json:"publish_at,omitempty"`
}
```

GORM AutoMigrate in `postgres.go` will add the column. No migration script needed.

#### `backend/internal/services/cron_service.go`

Add scheduled publish processing:
```go
func (s *CronService) ProcessScheduledPublishes() {
    ctx := context.Background()
    now := time.Now()
    
    // Find offers that are due for publishing
    var offers []models.Offer
    s.db.Model(&models.Offer{}).
        Where("status = ? AND publish_at IS NOT NULL AND publish_at <= ?",
            models.OfferStatusPending, now).
        Find(&offers)
    
    for _, offer := range offers {
        s.db.Model(&offer).Update("status", models.OfferStatusApproved)
        
        // Audit log
        s.auditSvc.LogAction(ctx, "system", "system", "admin",
            "offer.publish", "offer", offer.ID.String(),
            fmt.Sprintf("Scheduled offer auto-published: %s", offer.Title))
    }
    
    if len(offers) > 0 {
        slog.Info("Scheduled publishes processed", "count", len(offers))
    }
}
```

Add to `RunAll()`:
```go
func (s *CronService) RunAll() {
    ticker := time.NewTicker(15 * time.Minute)
    go func() {
        for range ticker.C {
            s.MarkExpiredOffers()
            s.NotifyExpiringSoon()
            s.ProcessScheduledNotifications()
            s.ProcessScheduledPublishes()  // <-- NEW
            s.PruneAuditLogs()
        }
    }()
}
```

#### `backend/internal/handlers/offer_handler.go` (Create/Update)

When creating or updating an offer, if `publish_at` is set to a future date AND the status would normally be `approved`, instead set status to `pending` (the cron job will publish it at the scheduled time).

For admin/owner creates:
```go
if req.PublishAt != nil && req.PublishAt.After(time.Now()) {
    offer.Status = models.OfferStatusPending
} else if userRole == "admin" {
    offer.Status = models.OfferStatusApproved
} else {
    offer.Status = models.OfferStatusPending
}
```

### Frontend Changes

#### `admin/src/app/dashboard/offers/_offer-dialog.tsx`

**Add datetime-local input:**
```tsx
<div className="space-y-2">
  <Label htmlFor="publish_at">Schedule Publish</Label>
  <Input
    id="publish_at"
    type="datetime-local"
    value={publishAt ? formatDateTimeLocal(publishAt) : ''}
    onChange={(e) => setPublishAt(e.target.value ? new Date(e.target.value) : null)}
  />
  <p className="text-sm text-muted-foreground">
    Leave empty to publish immediately upon approval
  </p>
</div>
```

**Helper function:**
```typescript
function formatDateTimeLocal(date: Date): string {
  const pad = (n: number) => n.toString().padStart(2, '0')
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`
}
```

**Validation:**
```typescript
if (publishAt && publishAt < new Date()) {
  setError('Publish date must be in the future')
  return
}
```

**In the offer list, show "Scheduled" badge:**
```tsx
{offer.publish_at && new Date(offer.publish_at) > new Date() && (
  <Badge variant="outline" className="text-amber-600 border-amber-600">
    Scheduled
  </Badge>
)}
```

### Files Changed
| File | Change |
|------|--------|
| `backend/internal/models/offer.go` | Add `PublishAt *time.Time` field |
| `backend/internal/services/cron_service.go` | Add `ProcessScheduledPublishes()`, add to `RunAll()` |
| `backend/internal/handlers/offer_handler.go` | Set status to pending when future `publish_at` |
| `admin/src/app/dashboard/offers/_offer-dialog.tsx` | Add datetime-local input |
| `admin/src/app/dashboard/offers/page.tsx` | Add "Scheduled" badge |

---

## Gap 3 — Form Validation with react-hook-form + zod

### Current State
Only `_offer-dialog.tsx` uses `react-hook-form` + `zod` with `zodResolver`. Other forms use manual `useState` + inline if/else validation:

| Form | Current Approach |
|------|-----------------|
| OfferDialog | ✅ `react-hook-form` + `zod` |
| UserDialog | ❌ Manual `useState` |
| RestaurantDialog | ❌ Manual `useState` |
| Settings (change password) | ❌ Manual `useState` |
| Notifications (push form) | ❌ Manual `useState` |
| Coupons form | ❌ Manual `useState` |

### Implementation Pattern (same for all forms)

Each form follows the existing OfferDialog pattern:

```typescript
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const schema = z.object({
  name: z.string().min(1, 'Name is required'),
  email: z.string().email('Invalid email'),
  // ... per-form fields
})

type FormData = z.infer<typeof schema>

const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
  resolver: zodResolver(schema),
})
```

#### Form-specific Zod Schemas

**User dialog:**
```typescript
const userSchema = z.object({
  name: z.string().min(1, 'Name is required').max(100),
  email: z.string().email('Invalid email address'),
  role: z.enum(['user', 'restaurant_owner', 'admin']),
  password: z.string().min(6, 'Password must be at least 6 characters').optional(),
})
```

**Restaurant dialog:**
```typescript
const restaurantSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  slug: z.string().min(1, 'Slug is required').regex(/^[a-z0-9-]+$/, 'Slug must be lowercase, alphanumeric, with dashes'),
  description_si: z.string().optional(),
  description_ta: z.string().optional(),
  address: z.string().min(1, 'Address is required'),
  contact_phone: z.string().optional(),
  latitude: z.number().min(-90).max(90).optional(),
  longitude: z.number().min(-180).max(180).optional(),
  owner_id: z.string().uuid().optional().nullable(),
  cover_image: z.string().optional(),
})
```

**Settings (change password):**
```typescript
const passwordSchema = z.object({
  current_password: z.string().min(1, 'Current password is required'),
  new_password: z.string().min(6, 'Password must be at least 6 characters'),
  confirm_password: z.string(),
}).refine((data) => data.new_password === data.confirm_password, {
  message: 'Passwords do not match',
  path: ['confirm_password'],
})
```

**Notification push form:**
```typescript
const notificationSchema = z.object({
  title: z.string().min(1, 'Title is required').max(200),
  body: z.string().min(1, 'Body is required').max(1000),
  target: z.enum(['all', 'users', 'owners', 'specific']),
  user_id: z.string().uuid().optional(),
  offer_id: z.string().uuid().optional(),
  schedule_at: z.string().optional(),
})
```

**Coupon form:**
```typescript
const couponSchema = z.object({
  code: z.string().min(1, 'Code is required').max(50).transform(s => s.toUpperCase()),
  discount_type: z.enum(['percentage', 'fixed']),
  discount_value: z.number().positive('Must be positive'),
  min_order_amount: z.number().min(0).optional(),
  max_uses: z.number().int().positive().optional(),
  starts_at: z.string().optional(),
  expires_at: z.string().optional(),
}).refine(/* percentage <= 100 rule */)
```

### Per-Form Refactoring Steps

Each form is independent. Recommended order:

1. **UserDialog** — simplest form (4 fields), lowest risk
2. **Settings (change password)** — 3 fields, adds cross-field validation (confirm match)
3. **Coupon form** — 6+ fields, adds type coercion (`z.number()`, `z.transform()`)
4. **RestaurantDialog** — 9+ fields, adds optional/nested types
5. **Notification push form** — 6 fields, adds conditional fields (target-dependent)

### Files Changed
| File | Change |
|------|--------|
| `admin/src/app/dashboard/users/_user-dialog.tsx` | Replace manual state with `useForm` + `zod` |
| `admin/src/app/dashboard/settings/page.tsx` | Same |
| `admin/src/app/dashboard/coupons/page.tsx` | Same |
| `admin/src/app/dashboard/restaurants/_restaurant-dialog.tsx` | Same |
| `admin/src/app/dashboard/notifications/page.tsx` | Same |

**No dependencies change** — packages already installed (`react-hook-form`, `zod`, `@hookform/resolvers`).

---

## Summary

| Gap | Effort | Files | Backend? |
|-----|--------|-------|----------|
| User edit form | ~1 hr | 2 | No |
| `publish_at` field | ~2 hr | 5 | Yes |
| Form validation | ~2 hr | 5 | No |
| **Total** | **~5 hr** | **12** | |

### Implementation Order
1. User edit form (simplest, no backend)
2. `publish_at` backend (model + cron + handler)
3. `publish_at` frontend (dialog + badge)
4. Form validation — UserDialog first, then rest incrementally

### Verification
- [ ] Create a user, then edit the user's name → saves correctly
- [ ] Create an offer with a future `publish_at` → offer appears as "Scheduled" (pending status)
- [ ] Wait for publish time → offer auto-approves (or fast-forward test)
- [ ] Each form shows real-time field validation errors
- [ ] Forms reject invalid data, submit valid data correctly
