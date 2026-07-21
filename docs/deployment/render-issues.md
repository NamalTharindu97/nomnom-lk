# Render Deployment — Issues & Fixes

## Issue 1: Render CLI `blueprints apply` Doesn't Exist

**Problem:** Render CLI v2.21.0 has `blueprints validate` but no `blueprints apply`.

**Fix:** Create resources individually via CLI:
```bash
render postgres create ...
render kv create ...
render services create ...
```

## Issue 2: Render CLI Can't Set Environment Variables

**Problem:** No `render env set` or `render services env update` command exists.

**Fix:** Use the Render REST API directly:
```bash
curl -X PUT "https://api.render.com/v1/services/{SERVICE_ID}/env-vars/{KEY}" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"value": "NEW_VALUE"}'
```

## Issue 3: `from_service` References Not Resolved

**Problem:** When creating via CLI (not Blueprint), `DATABASE_URL=from_service:nomnom-db` and `REDIS_URL=from_service:nomnom-redis` stay as literal strings — Render doesn't auto-resolve them.

**Fix:** Fetch the actual connection strings from the API and set them manually:
```bash
# Get connection strings
curl -s "https://api.render.com/v1/postgres/{DB_ID}/connection-info" -H "Authorization: Bearer ..."
curl -s "https://api.render.com/v1/redis/{REDIS_ID}/connection-info" -H "Authorization: Bearer ..."

# Set resolved values
curl -X PUT "https://api.render.com/v1/services/{SERVICE_ID}/env-vars/DATABASE_URL" \
  -d '{"value": "postgresql://nomnom:PASSWORD@dpg-xxx/nomnom_xxx"}'
```

## Issue 4: `JWT_SECRET=generate` Not Resolved

**Problem:** Same as above — `generate` stays as a literal string.

**Fix:** Generate locally and set via API:
```bash
JWT_SECRET=$(openssl rand -hex 32)
curl -X PUT "https://api.render.com/v1/services/${SERVICE_ID}/env-vars/JWT_SECRET" \
  -d "{\"value\": \"${JWT_SECRET}\"}"
```

## Issue 5: Admin Bootstrap — "please verify your email first"

**Problem:** The admin user created by `main.go` bootstrap didn't have `EmailVerifiedAt` set. The login handler checks for this field and rejects unverified emails.

**Root cause:** In `backend/cmd/server/main.go`, the admin user struct was:
```go
admin := models.User{
    Email:        adminCfg.Email,
    PasswordHash: hashedPassword,
    Name:         "Admin",
    Role:         models.RoleAdmin,
    IsActive:     true,
    // Missing: EmailVerifiedAt
}
```

**Fix (code):** Added `EmailVerifiedAt` to the bootstrap:
```go
now := time.Now()
admin := models.User{
    Email:          adminCfg.Email,
    PasswordHash:   hashedPassword,
    Name:           "Admin",
    Role:           models.RoleAdmin,
    IsActive:       true,
    EmailVerifiedAt: &now,  // ← ADDED
}
```

**Fix (existing DB):** The admin was already created without the field. The bootstrap only runs when no admin exists, so we had to fix it directly in PostgreSQL:
```bash
# Add IP to allow list
curl -X PATCH "https://api.render.com/v1/postgres/{DB_ID}" \
  -d '{"ipAllowList": [{"cidrBlock": "YOUR_IP/32", "description": "fix"}]}'

# Run SQL fix
render psql nomnom-db --command "UPDATE users SET email_verified_at = NOW() WHERE email = 'admin@nomnom.lk';"

# Remove IP
curl -X PATCH "https://api.render.com/v1/postgres/{DB_ID}" -d '{"ipAllowList": []}'
```

## Issue 6: `render psql` — "psql: executable file not found"

**Problem:** `render psql` requires the `psql` binary on the local machine.

**Fix:** Install PostgreSQL client:
```bash
brew install postgresql@16
```

## Issue 7: `render psql` — "IP address not in allow list"

**Problem:** Render PostgreSQL has an IP allow list that defaults to empty (private only).

**Fix:** Temporarily add your IP:
```bash
# Get your public IP
MY_IP=$(curl -s ifconfig.me)

# Add to allow list (note: Render may IPv4-ize IPv6 addresses)
curl -X PATCH "https://api.render.com/v1/postgres/dpg-xxx" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"ipAllowList\": [{\"cidrBlock\": \"175.157.115.71/32\", \"description\": \"fix\"}]}"

# After psql work, remove it
curl -X PATCH "https://api.render.com/v1/postgres/dpg-xxx" \
  -d '{"ipAllowList": []}'
```

## Issue 8: CI Failures After P47 Merge

### 8a. Backend Lint — staticcheck QF1003

**Problem:** `user_repo.go:156` used an if/else chain that staticcheck suggested converting to a tagged switch.

**Fix:**
```go
// Before
if statusFilter == "inactive" {
    query = query.Where("is_active = ?", false)
} else if statusFilter == "all" {
    // no filter
} else {
    query = query.Where("is_active = ?", true)
}

// After
switch statusFilter {
case "inactive":
    query = query.Where("is_active = ?", false)
case "all":
    // no filter
default:
    query = query.Where("is_active = ?", true)
}
```

### 8b. Admin npm audit — high severity

**Problem:** `brace-expansion` DoS and `js-yaml` quadratic CPU vulnerabilities.

**Fix:**
```bash
cd admin && npm audit fix
```
Fixed 2 high-severity vulns. 2 moderate postcss vulns remain (require breaking `next` upgrade, below `--audit-level=high` threshold).

## Issue 9: Database Name Mismatch

**Problem:** Requested `nomnom` as database name, Render auto-generated `nomnom_bd9o` instead (appends random suffix).

**Impact:** None — the `DATABASE_URL` connection string contains the correct name. The backend uses `DATABASE_URL` directly, not the name.

## Issue 10: Firebase Secret File Mounted Empty

**Problem:** The secret-file API returned HTTP 200, but Firebase initialization
failed with `unexpected end of JSON input` because the payload used `contents`
instead of the API's `content` field.

**Fix:** Upload the JSON through the correct field and trigger a full deploy. A
service restart alone reuses the old mounted secret.

```bash
jq -Rs '{content: .}' backend/config/firebase-credentials.json > /tmp/firebase-secret.json

curl -X PUT \
  "https://api.render.com/v1/services/${SERVICE_ID}/secret-files/firebase-credentials.json" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  --data-binary @/tmp/firebase-secret.json

render deploys create "${SERVICE_ID}" --confirm
```

## Issue 11: Admin Proxy Used `localhost:8080` on Render

**Problem:** The admin service had the correct runtime `API_PROXY_TARGET`, but
`/api/v1/*` returned HTTP 500. Next.js evaluates `rewrites()` during
`next build`, so the Docker image had already compiled the default
`http://localhost:8080` destination.

**Fix:** Add `API_PROXY_TARGET` as a Docker build argument and pass the hosted
backend URL from GitHub Actions:

```dockerfile
ARG NEXT_PUBLIC_API_URL=/api/v1
ARG API_PROXY_TARGET=http://localhost:8080
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
ENV API_PROXY_TARGET=$API_PROXY_TARGET
RUN npm run build
```

```yaml
build-args: |
  NEXT_PUBLIC_API_URL=/api/v1
  API_PROXY_TARGET=https://nomnom-backend-7iq0.onrender.com
```

After rebuilding and redeploying the image, `/api/v1/restaurants` and admin
login both returned HTTP 200 through the hosted frontend.

## Environment Variable Reference

| Variable | Source | Notes |
|----------|--------|-------|
| `DATABASE_URL` | Render API (connection-info) | Internal URL for same-region services |
| `REDIS_URL` | Render API (connection-info) | Internal URL for same-region services |
| `JWT_SECRET` | `openssl rand -hex 32` | Random 64-char hex string |
| `R2_ACCESS_KEY_ID` | Cloudflare R2 | **Rotate after sharing in chat** |
| `R2_SECRET_ACCESS_KEY` | Cloudflare R2 | **Rotate after sharing in chat** |
| `R2_ENDPOINT` | Cloudflare R2 | `9e4b33ed2e3cfb1fbbb837ada2399a6d.r2.cloudflarestorage.com` |
| `ADMIN_PASSWORD` | User chosen | Currently `Admin@123` — change for production |
| `FIREBASE_CREDENTIALS_PATH` | Fixed path | `/etc/secrets/firebase-credentials.json` |
| `SERVER_PORT` | Fixed | `10000` (Render convention) |
| `ENVIRONMENT` | Fixed | `production` |
| `R2_REGION` | Fixed | `auto` |
| `R2_BUCKET` | Fixed | `nomnom-images` |
| `R2_SECURE` | Fixed | `true` |
| `R2_FORCE_PATH_STYLE` | Fixed | `false` |
| `R2_PREFIX` | Fixed | `production` |
| `CORS_ORIGINS` | Fixed | `https://nomnom-admin-e41y.onrender.com` |
| `ADMIN_EMAIL` | Fixed | `admin@nomnom.lk` |
