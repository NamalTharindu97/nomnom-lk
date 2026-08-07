# P52 Recruiter Demo Plan

## Goal

Provide CV reviewers with a one-click, public, read-only view of the NomNom LK
admin dashboard without exposing credentials, personal data, operational data,
or mutation capabilities.

The demo is a portfolio surface. Any data returned to it must be safe to make
public and its restrictions must be enforced by the Go backend. Hidden or
disabled frontend controls are only a usability measure.

## Delivery Model

- Branch: `phase/P52-recruiter-demo`
- Base branch: `staging`
- Baseline SHA: `76e30e4de5b79c3220c59c9e52b80bdfd0e74a39`
- Pull request target: `staging`
- Staging deployment: automatic after merge
- Production promotion: `staging` to `master`, followed by manual approval
- Implementation: phase by phase with sign-off after each phase
- Default state: recruiter demo disabled until hosted verification

## Locked Decisions

| Area | Decision |
|---|---|
| Backend role | `portfolio_viewer` |
| Display name | `Recruiter Demo` |
| Entry | One-click login on the existing login page |
| Shared password | None |
| Data scope | Explicit portfolio-safe allowlist |
| Write protection | Central backend read-only enforcement |
| UI | Dedicated navigation and persistent read-only banner |
| Source code | Public GitHub repository linked from the CV |
| Sensitive pages | Not available to the viewer |

## Phase 0: Baseline And Security Contract

### Existing Behavior To Preserve

The following behavior is mandatory regression coverage throughout P52:

- Admin browser login continues to provide full existing dashboard access.
- Restaurant-owner browser login continues to provide owner-scoped access.
- Consumer users remain unable to establish a dashboard browser session.
- Admin create, update, approve, reject, expire, bulk, upload, notification,
  impersonation, and account-management operations remain unchanged.
- Restaurant owners retain their current scoped restaurant, offer, and banner
  workflows.
- Cookie authentication, CSRF validation, refresh, and logout remain unchanged
  for existing roles.
- Admin-only frontend routes continue to redirect restaurant owners.
- Public mobile API behavior and Flutter authentication remain unchanged.
- Existing audit logging continues to cover authenticated dashboard actions.
- Existing deployment, rollback, and immutable-image behavior remains intact.

### Current Authorization Baseline

| Role | Dashboard login | Data scope | Mutations |
|---|---|---|---|
| `user` | Denied | None | Consumer API only |
| `restaurant_owner` | Allowed | Owned resources | Owned resources |
| `admin` | Allowed | Platform-wide | Full administration |
| `portfolio_viewer` | Not implemented | None | None |

### Target Authorization Contract

| Role | Dashboard login | Data scope | Mutations |
|---|---|---|---|
| `user` | Denied | None | Unchanged |
| `restaurant_owner` | Allowed | Owned resources | Unchanged |
| `admin` | Allowed | Platform-wide | Unchanged |
| `portfolio_viewer` | One-click only | Approved public fields | Always denied |

### Backend Route Matrix

The viewer policy is default-deny. A route is unavailable unless it is listed
as allowed below.

#### Allowed Dashboard Reads

| Method | Route | Viewer response |
|---|---|---|
| GET | `/api/v1/dashboard/stats` | Portfolio-safe aggregate statistics |
| GET | `/api/v1/dashboard/restaurants` | Sanitized platform-wide list |
| GET | `/api/v1/dashboard/restaurants/:id` | Sanitized detail |
| GET | `/api/v1/dashboard/offers` | Sanitized platform-wide list |
| GET | `/api/v1/dashboard/offers/:id` | Sanitized detail |

`/api/v1/dashboard/banners` is not used for the viewer because its existing
owner scoping treats an empty owner ID differently from restaurants and offers.
The viewer uses the approved admin banner read route instead.

#### Allowed Admin Reads

| Method | Route | Viewer response |
|---|---|---|
| GET | `/api/v1/admin/stats` | Safe counts only |
| GET | `/api/v1/admin/stats/timeline` | Aggregate timeline |
| GET | `/api/v1/admin/analytics/top-restaurants` | Aggregate ranking |
| GET | `/api/v1/admin/analytics/top-offers` | Aggregate ranking |
| GET | `/api/v1/admin/analytics/offer-stats` | Aggregate offer metrics |
| GET | `/api/v1/admin/analytics/expiring-offers` | Sanitized offer summary |
| GET | `/api/v1/admin/categories` | Taxonomy list |
| GET | `/api/v1/admin/cuisine-tags` | Taxonomy list |
| GET | `/api/v1/admin/order-platforms` | Public platform configuration |
| GET | `/api/v1/admin/social-platforms` | Public platform configuration |
| GET | `/api/v1/admin/banners` | Sanitized banner list |

#### Sensitive Reads Kept Admin-Only

| Route family | Reason |
|---|---|
| `/api/v1/users` | Names, emails, roles, status, and account metadata |
| `/api/v1/admin/owners` | Owner identities, emails, and account status |
| `/api/v1/admin/notifications` | Recipient and operational messaging data |
| `/api/v1/admin/notification-templates` | Internal messaging configuration |
| `/api/v1/admin/notification-analytics` | Internal notification operations |
| `/api/v1/admin/audit-log` | Authentication and administrative activity |
| `/api/v1/admin/analytics/user-growth` | Not needed for the portfolio demo |
| `/api/v1/admin/analytics/device-stats` | Internal device information |
| `/api/v1/admin/analytics/recent-activity` | Internal administrative activity |
| `/api/v1/admin/coupons` | Promotion codes and redemption configuration |
| `/api/v1/admin/impersonate*` | Account switching capability |
| `/api/v1/users/me` | Viewer account details are not a portfolio feature |

#### Mutations Always Denied

For `portfolio_viewer`, all authenticated `POST`, `PUT`, `PATCH`, and `DELETE`
requests are denied before business handlers run. Browser demo login and logout
are explicit session-lifecycle exceptions.

This includes these route families:

- `/api/v1/users*`
- `/api/v1/restaurants*`
- `/api/v1/offers*`
- `/api/v1/favorites*`
- `/api/v1/notifications*`
- `/api/v1/devices*`
- `/api/v1/banners*`
- `/api/v1/upload*`
- `/api/v1/dashboard*`
- `/api/v1/admin*`

### Public Data Contract

The viewer response must not expose fields in the denied column. Existing admin
and owner response shapes must remain unchanged.

| Resource | Allowed | Denied or sanitized |
|---|---|---|
| Dashboard stats | Counts, views, favorites, clicks, status totals | User identities, device data, recent activity |
| Restaurant | Name, slug, description, cuisine tags, image, status, public links | Owner ID, owner email, personal contact details, internal notes |
| Offer | Title, description, prices, dates, image, restaurant name, categories, status | Creator ID, internal rejection notes, private metadata |
| Banner | Image, sponsor, schedule, status, link type, aggregate clicks | Owner ID, internal notes, private target data |
| Category | Name, slug, display metadata | Internal audit metadata |
| Cuisine tag | Name, slug, display metadata | Internal audit metadata |
| Order platform | Display name, color, logo, public linking configuration | Secrets or private integration data |
| Social platform | Display name, color, logo, public linking configuration | Secrets or private integration data |

Status labels may be shown because they demonstrate the approval workflow.
Rejection reasons and free-form internal notes are private by default.

### Frontend Route Matrix

#### Viewer Navigation

| Label | Route |
|---|---|
| Dashboard | `/dashboard` |
| Restaurants | `/dashboard/restaurants` |
| Offers | `/dashboard/offers` |
| Banners | `/dashboard/banners` |
| Categories | `/dashboard/categories` |
| Cuisine Tags | `/dashboard/cuisine-tags` |
| Order Platforms | `/dashboard/order-platforms` |
| Social Platforms | `/dashboard/social-platforms` |

#### Viewer Routes To Redirect

- `/dashboard/users`
- `/dashboard/owners`
- `/dashboard/notifications`
- `/dashboard/notification-templates`
- `/dashboard/coupons`
- `/dashboard/audit-log`
- `/dashboard/settings`

### Viewer UI Contract

- Show a persistent `Recruiter Demo - Read only` indicator.
- Hide create, edit, delete, upload, bulk, approve, reject, and expire actions.
- Hide row-selection controls and mutation-only dialogs.
- Hide CSV export until its output is separately approved as public.
- Keep search, filters, sorting, pagination, refresh, themes, and responsive UI.
- Use `Explore` or `View` instead of `Manage` in viewer-facing copy.
- Return a friendly read-only message if a stale UI attempts a blocked action.
- Preserve every existing control for admins and restaurant owners.

### Phase 0 Acceptance Criteria

- The existing role behavior is recorded.
- The viewer route policy is default-deny.
- Safe GET routes are explicitly listed.
- Sensitive GET routes are explicitly excluded.
- All mutation methods are covered by server-side denial.
- Public and private response fields are classified.
- Existing admin, owner, consumer, Flutter, and deployment behavior is listed as
  mandatory regression coverage.
- No application behavior, database record, environment variable, or server
  configuration changes in Phase 0.

## Phase 1: Backend Security Foundation

### Work

- Add the `portfolio_viewer` role constant.
- Validate role writes and keep viewer provisioning out of generic user CRUD.
- Add centralized viewer read-only enforcement to authenticated requests.
- Return a stable `PORTFOLIO_DEMO_READ_ONLY` error for blocked requests.
- Block viewer profile, password, deletion, upload, device, favorite, and
  Firebase-linking operations.
- Add demo configuration that defaults on only in staging and remains disabled
  by default in every other environment.
- Add unit tests before allowing dashboard access.

### Gate

A direct viewer JWT cannot execute any authenticated mutation. Admin and owner
mutation tests continue to pass.

## Phase 2: Backend Read Allowlist And Sanitization

### Work

- Permit the viewer through dashboard authentication.
- Make platform-wide viewer read scope explicit.
- Split safe admin GET routes from sensitive and mutating routes.
- Add viewer-safe response mappings without changing existing role responses.
- Ensure allowed GET handlers do not perform viewer-triggered writes.
- Add allowlist, sensitive-route, scoping, and response-shape tests.

### Gate

Approved reads return `200`; sensitive reads and every mutation return `403`.

## Phase 3: One-Click Demo Session

### Configuration

```text
DEMO_VIEWER_ENABLED=false
DEMO_VIEWER_EMAIL=recruiter-demo@nomnomlk.com
DEMO_VIEWER_NAME=Recruiter Demo
DEMO_VIEWER_SESSION_TTL=30m
```

`DEMO_VIEWER_ENABLED` explicitly overrides the environment default. Staging
defaults to enabled so immutable image-only deployments cannot omit the demo;
development, test, and production default to disabled.

### Work

- Add an idempotent, configuration-controlled viewer bootstrap.
- Provision no usable shared password.
- Add rate-limited `POST /api/v1/auth/browser/demo`.
- Issue a short-lived secure browser session.
- Keep browser logout functional.
- Audit demo session creation without recording tokens.
- Return `404` while the feature is disabled.

### Gate

One-click login works only for the configured active viewer account, and the
feature can be disabled without a deployment.

## Phase 4: Frontend Role, Navigation, And Dashboard

### Work

- Add `isViewer` and `isReadOnly` to the auth context.
- Replace implicit admin-versus-owner branching with explicit role handling.
- Add dedicated viewer navigation and direct-route redirects.
- Add the persistent read-only banner.
- Render a portfolio-safe dashboard without sensitive widgets.
- Preserve admin and owner navigation and dashboards.

### Gate

The viewer sees only approved navigation on desktop and mobile. Existing role
navigation remains unchanged.

## Phase 5: Read-Only Resource Screens

### Work

- Adapt restaurants, restaurant detail, offers, banners, categories, cuisine
  tags, order platforms, and social platforms for viewer mode.
- Hide all mutation and upload controls for the viewer.
- Keep discovery controls such as filtering and pagination.
- Keep normal admin and owner workflows unchanged.

### Gate

No mutation control is rendered for the viewer, and direct API attempts remain
blocked by the backend.

## Phase 6: Recruiter Login Experience

### Work

- Add an `Explore read-only demo` panel to the login page.
- Explain that no credentials are required and no data can be changed.
- Add accessible loading, error, keyboard, theme, and responsive states.
- Preserve normal admin and owner email/password login.

### Gate

A first-time visitor can enter the demo from an incognito browser without CV
instructions beyond the live URL.

## Phase 7: Automated Tests And Security Review

### Backend Coverage

- Demo enabled and disabled behavior
- Viewer session creation, expiry, rate limit, and logout
- Allowed GET route matrix
- Sensitive GET denial matrix
- POST, PUT, PATCH, and DELETE denial matrix
- Upload, impersonation, profile, password, and Firebase-linking denial
- Suspended viewer denial
- Viewer response sanitization
- Existing admin and owner regression behavior

### Admin Coverage

- One-click demo login
- Viewer navigation and read-only banner
- Approved page access and sensitive route redirects
- Mutation controls absent
- Direct API mutations denied
- Logout and repeat login
- Responsive login and dashboard
- Existing admin and owner RBAC behavior

### Commands

```bash
cd backend
make build
make lint
make test
make test-integration
```

```bash
cd admin
npm run lint
npx tsc --noEmit
npm run test:unit
npm run build
npm run test:e2e
```

The full GitHub CI pipeline, including the unchanged Flutter job, must pass.

### Gate

All authorization tests and existing regression suites pass. The final diff is
reviewed for accidental deletions or weakened role checks.

## Phase 8: Staging Deployment

### Work

- Open the P52 pull request against `staging`.
- Merge only after required CI checks pass.
- Deploy immutable backend and admin SHA images.
- Configure the viewer environment with demo mode initially disabled.
- Enable demo mode after both services are deployed.
- Test HTTPS, cookies, rate limits, redirects, allowed reads, and blocked writes.
- Review backend, admin, Caddy, and audit logs.
- Test in incognito desktop and mobile browsers.

### Rollback

- Set `DEMO_VIEWER_ENABLED=false` to stop new demo sessions.
- Roll back to the previous immutable backend and admin images if necessary.

### Gate

The hosted route matrix passes and no sensitive data appears in viewer responses
or browser developer tools.

## Phase 9: Production Promotion

### Work

- Open the release pull request from `staging` to `master`.
- Promote the exact staging-tested image digests after manual approval.
- Configure and enable the production viewer.
- Run live health, login, read-only, sensitive-route, and logout smoke tests.
- Record deployed SHAs and rollback images.

### Gate

`https://admin.nomnomlk.com/login` provides the verified one-click demo and all
production checks pass.

## Phase 10: CV And GitHub Presentation

### GitHub README

- Add a prominent live-demo link and one-click instruction.
- Add dashboard and mobile screenshots or a short GIF.
- Add an architecture diagram, stack, RBAC model, CI badges, and deployment
  overview.
- Add a short engineering decisions and challenges section.
- Add a 60-90 second walkthrough video as a fallback.

### CV Entry

```text
NomNom LK - Food Offers Discovery Platform
Live demo: https://admin.nomnomlk.com/login
Source: https://github.com/NamalTharindu97/nomnom-lk

- Built a full-stack food-offer platform with Flutter, Go/Gin, Next.js,
  PostgreSQL, Redis, Firebase, and Docker.
- Developed role-based admin and restaurant-owner workflows, real-time SSE
  updates, push notifications, and multilingual content.
- Deployed behind Cloudflare and Caddy with HTTPS, immutable releases, CI/CD,
  security scanning, and automated testing.
- Provides a one-click, server-enforced read-only recruiter demo.
```

### Final Checks

- Display complete URLs in the exported PDF, not only linked labels.
- Test links after PDF export.
- Add a QR code only to the visual CV version.
- Do not distribute a debug APK.
- Add the Play Store link after publication.

## Estimated Effort

| Phase | Estimate |
|---|---:|
| Phase 0 | 0.5 day |
| Phases 1-3 | 2-3 days |
| Phases 4-6 | 2-3 days |
| Phase 7 | 1 day |
| Phases 8-9 | 0.5-1 day |
| Phase 10 | 0.5 day |
| Total | 6-8 working days |

## Sign-Off Record

| Phase | Status | Evidence |
|---|---|---|
| Phase 0 | Approved | Baseline, route matrix, and data contract in this document |
| Phase 1 | Verified | Role, disabled config, central write guard, protected account/auth paths, and backend tests |
| Phase 2 | Verified | Explicit safe-read routes, platform scope, viewer-only response maps, and route/sanitization/regression tests |
| Phase 3 | Verified | Idempotent bootstrap, short-lived access-only browser session, strict IP rate limit, audit event, and lifecycle tests |
| Phase 4 | Verified | Explicit viewer auth state, default-deny routes, dedicated navigation/banner, and safe dashboard |
| Phase 5 | Verified | Approved resource pages use safe GET routes and omit viewer mutation, upload, selection, bulk, and CSV controls |
| Phase 6 | Verified | Accessible responsive one-click recruiter panel with isolated loading/error state and no automatic login |
| Phase 7 | Complete | Backend suites, 18 Vitest tests, 73 Playwright tests, Next.js build, and 344 Flutter tests pass |
| Phase 8 | Not started | - |
| Phase 9 | Not started | - |
| Phase 10 | Complete | Public README includes the live demo, one-click instructions, security model, and CV-ready project wording |
