# Phase 3: Secure Admin Browser Sessions

**Date:** 2026-07-23
**Branch:** `phase/P54-secure-admin-sessions`
**Status:** Implemented, verified, pending user sign-off

## Summary

Migrated admin dashboard authentication from browser-readable JWTs (localStorage +
client-written cookies) to server-set `HttpOnly` cookie sessions with CSRF
protection. All Flutter/mobile bearer-token endpoints and response contracts are
preserved unchanged. RBAC, owner scoping, impersonation, and audit logging
continue to function identically.

## Backend changes

### New configuration (`backend/internal/config/config.go`)

- Added `BrowserSessionConfig` struct with `CookieSecure bool`.
- `BROWSER_COOKIE_SECURE` defaults to `true` in production, `false` otherwise.
- Production validation rejects `BROWSER_COOKIE_SECURE=false`.
- Secret-file support, production validation, and redacted-error refactoring
  from Phases 1–2 are preserved.

### Dual-mode auth middleware (`backend/internal/middleware/auth.go`)

- Extended `Auth()` to accept both `Authorization: Bearer` headers and a
  BrowserAccessCookie (`nomnom_access`).
- Sets `auth_transport` gin context key as `"bearer"` or `"cookie"`.
- Enforces algorithm restriction (`HS256` only) for all JWT parsing.
- Cookie-authenticated mutating requests automatically fail CSRF inside the
  auth middleware (no separate chain required).
- All existing context keys (`user_id`, `user_email`, `user_name`, `user_role`,
  `impersonated_by`, `impersonated_at`) remain identical.
- Added `IsCookieAuth(c)` helper for handlers that need transport awareness.

### CSRF protection (`backend/internal/middleware/csrf.go`)

- `RequireBrowserCSRF()` middleware validates double-submit `X-CSRF-Token`
  header against `nomnom_csrf` cookie.
- Applies only to mutating methods (POST/PUT/DELETE).
- Safe methods (GET/HEAD/OPTIONS) pass through unconditionally.
- Uses constant-time comparison.
- Included in CORS `Access-Control-Allow-Headers`.

### Browser session handler (`backend/internal/handlers/browser_session.go`)

- `browserSession` manages four cookies:
  - `nomnom_access` — HttpOnly, short-lived (15 min), path `/`
  - `nomnom_refresh` — HttpOnly, long-lived (30 days), path `/api/v1/auth/browser`
  - `nomnom_csrf` — NOT HttpOnly (JS must read it), path `/`, same expiry as
    refresh
- `set()` issues all three cookies together; `setAccess()` replaces only the
  access cookie (for impersonation transitions).
- `clear()` removes all three cookies with identical scope attributes.
- Development uses `HttpOnly`/`SameSite=Lax` without `Secure`; production adds
  `Secure` via config flag.
- CSRF token generated with `crypto/rand` (32 bytes, base64url-encoded).

### New browser endpoints (`backend/internal/handlers/auth_handler.go`)

| Endpoint | Auth | CSRF | Purpose |
|---|---|---|---|
| `POST /auth/browser/login` | None | No | Dashboard login → sets all cookies, returns user JSON only |
| `POST /auth/browser/refresh` | Cookie | Yes | Token rotation → replaces all three cookies |
| `POST /auth/browser/logout` | Cookie | Yes | Server-side revocation + cookie clearing |
| `GET /auth/browser/session` | Cookie | Safe | Bootstrap: returns user + impersonation state from claims |

- `BrowserLogin` uses `LoginDashboard()`, which adds a dashboard-role gate
  (admin or restaurant_owner only). Regular users receive 403 before any
  session is created.
- `BrowserRefresh` calls `RefreshDashboard()`, which preserves impersonation
  by re-issuing the impersonation token when the admin's original identity
  refreshes and Redis confirms an active impersonation session.
- `BrowserLogout` revokes the specific refresh token server-side, clears all
  cookies, and logs the audit event.
- `BrowserSession` reads identity from the existing Gin context and returns
  it — no new database queries.

### Service updates (`backend/internal/services/auth_service.go`)

- Extracted `authenticatePassword()` from `Login()` — shared by both
  bearer and browser login paths.
- `LoginDashboard()` delegates to `authenticatePassword()` + role gate;
  `generateAuthResponse()` is identical to the mobile path.
- `Refresh()` now rejects suspended users (pre-existing gap closed).
- `RefreshDashboard()` calls `Refresh()` then conditionally re-issues
  impersonation tokens by verifying signature, Redis session, and target
  account status.
- `LogoutRefreshToken()` revokes a single token hash for browser logout
  without affecting other browser sessions.

### Impersonation handler (`backend/internal/handlers/impersonation_handler.go`)

- `Start()`: when cookie-authenticated, sets the impersonation access cookie
  directly instead of returning `access_token` in JSON.
- `Stop()`: same pattern — `setAccess()` for cookies, `access_token` field for
  bearer. Cookie-authenticated stops that cannot find a session return a fresh
  admin token (no longer restore an expired backup from Redis).
- `Status()`: unchanged — works with either transport.
- `ImpersonationService.StopImpersonation()` now generates a fresh admin access
  token instead of retrieving a potentially expired stored backup.

### Router (`backend/internal/router/router.go`)

- Browser routes grouped under `authGroup` (shares login brute-force rate
  limiter) except `GET /auth/browser/session`, which is outside the limiter
  to prevent 429s during parallel page hydration.
- Refresh and logout require `RequireBrowserCSRF()` middleware.
- Session requires `Auth` + `RequireDashboardAccess` + `RequireActive`.

### Additional changes

- `RefreshTokenRepo.DeleteByHash()` added for single-token revocation.
- `jwt.ValidateTokenIgnoringExpiry()` added for impersonation continuity
  during refresh (signature verification only; caller validates independently).
- CORS `Access-Control-Allow-Headers` includes `X-CSRF-Token`.
- `.env.example` documents `BROWSER_COOKIE_SECURE`.
- VPS compose.yml sets `BROWSER_COOKIE_SECURE: "true"`.

## Admin dashboard changes

### API client (`admin/src/lib/api.ts`)

- Removed bearer/auth header injection — credentials are now transmitted via
  `credentials: "include"` on every request.
- Reads `nomnom_csrf` cookie and sends `X-CSRF-Token` header on mutating
  requests.
- Serializes 401 refresh with a deduplication promise.
- 401 on non-browser-auth paths triggers refresh attempt, then logout redirect.
- No longer reads or writes localStorage or client-set cookies.
- API base defaults to `/api/v1` (same-origin proxy) instead of
  `http://localhost:8080/api/v1`.

### Auth provider (`admin/src/hooks/use-auth.tsx`)

- User state hydrates from `GET /api/v1/auth/browser/session` instead of
  localStorage/decodeToken.
- Impersonation state comes from the server's `impersonated_by` claim.
- `login()` calls `POST /auth/browser/login` and sets only React state.
- `logout()` calls `POST /auth/browser/logout` to revoke server-side, then
  clears React state and redirects.
- `impersonate()`/`stopImpersonating()` no longer manipulate localStorage or
  client cookies — the backend sets `nomnom_access` via `Set-Cookie`.
- Removed `token` from context (no consumers used it directly).

### Proxy (`admin/src/proxy.ts`)

- Now reads only `nomnom_access` (HttpOnly server-set cookie) for presence
  check.
- Removed path-based RBAC and client-controlled `user` cookie parsing.
- Backend authorization and client-side layout remain authoritative for role
  enforcement; the proxy provides only a coarse session gate.

## Test updates

### E2E auth setup (`admin/tests/auth.setup.ts`)

- Authenticates via `POST /auth/browser/login` (which sets cookies).
- Removed all manual localStorage/document.cookie writes.

### RBAC tests (`admin/tests/rbac.spec.ts`)

- `loginAs()` helper uses browser login endpoint.
- Regular-user test now asserts that `POST /auth/browser/login` returns 403
  before any session is created (stronger boundary than client-side redirect).

### Banners test (`admin/tests/banners.spec.ts`)

- Uses browser login for page auth + bearer login for direct API checks
  (preserves existing admin/owner role-switch pattern).

### New browser session E2E suite (`admin/tests/browser-session.spec.ts`)

- **Tokens not in JSON/storage:** verifies login response excludes
  `access_token`/`refresh_token`, cookies are HttpOnly, localStorage is empty.
- **CSRF required for mutations:** unauthenticated logout without CSRF header
  returns 403 with `CSRF_VALIDATION_FAILED`.
- **Logout clears all cookies:** login → logout with valid CSRF → all three
  cookies removed.

### Backend unit tests

- `backend/internal/middleware/auth_test.go`: 7 table-driven cases covering
  bearer, cookie, CSRF validation, transport marking, and precedence.
- `backend/internal/middleware/csrf_test.go`: 3 cases for matching, missing,
  and mismatched CSRF tokens.
- `backend/internal/handlers/browser_session_test.go`: cookie attributes,
  HttpOnly/non-HttpOnly classification, path scoping, and clear-scope
  correctness.
- `backend/internal/config/config_test.go`: development `CookieSecure=false`, 
  production rejection, and combined production acceptance.

## Verification results

| Suite | Result |
|---|---|
| Backend build + race tests | All passing |
| Backend integration tests | All passing |
| Admin TypeScript + build | Passing (no new lint errors) |
| Admin unit tests | 11/11 passing |
| Playwright E2E (56 tests) | 56/56 passing |
| Flutter analyze | 37 pre-existing info findings (unchanged) |
| Flutter tests | 20/20 passing |
| VPS compose config | Validates successfully |
| Gitleaks (214 commits) | No findings |

## What was NOT changed

- All existing mobile bearer-token endpoints (`/auth/login`, `/auth/refresh`,
  `/auth/logout`, `/auth/firebase`, `/auth/verify-email`) retain identical
  request/response contracts.
- Flutter `AuthInterceptor`, `ApiAuthService`, `ApiClient`, FCM, and SSE
  services are untouched.
- Dashboard RBAC (RequireDashboardAccess, RequireActive, OwnerScoped,
  RequireRole) middleware chain is unchanged.
- Audit logging (middleware + semantic calls) is unchanged.
- All dashboard CRUD endpoints and response contracts are unchanged.
- Cookie expiry leverages the existing JWT lifetimes (15m access, 30d refresh).

## Migration notes

1. **Production `BROWSER_COOKIE_SECURE` must be `true`.** The config validation
   gate enforces this in production mode. Local development uses `false` for
   HTTP access.
2. **CORS origins must include the admin domain.** The existing
   `CORS_ORIGINS` setting already covers this for the VPS deployment.
3. **Same-origin proxy required.** The admin dashboard must proxy `/api/v1/*`
   to the backend (existing `next.config.ts` rewrite). Direct cross-origin
   cookie auth will not work without explicit domain/credentials configuration.
4. **CSRF cookie is JavaScript-readable** by design (double-submit pattern).
   This is the only browser-readable token and is not sensitive on its own.
5. **Refresh cookie has restricted path** (`/api/v1/auth/browser`) so it is
   only sent with refresh requests, not every API call.
6. **Existing mobile refresh does NOT reject suspended users** — this was a
   pre-existing gap that Phase 3 closed in the shared `Refresh()` method as an
   additive security improvement.
