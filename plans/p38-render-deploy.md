# P38 — Render.com Blueprint Deployment

## Goal
Deploy the NomNom LK stack (backend + admin + PostgreSQL + Redis) to Render's free tier using the existing `render.yaml` Blueprint. After this phase, the app will be publicly accessible for the first time.

---

## Prerequisites
- **P37 must be completed** — `DATABASE_URL` / `REDIS_URL` parsing in config is required for Render's managed services to work
- Docker images must be built and pushed to Docker Hub (CI does this on every master push)
- Cloudflare R2 bucket must exist (for image storage)
- Firebase credentials file must be available

---

## Current State

### What Already Exists

| Asset | Location | Status |
|-------|----------|--------|
| `render.yaml` | Repo root | ✅ Complete — 4 free services declared |
| Dockerfile (backend) | `backend/Dockerfile` | ✅ Render-compatible (PORT fallback, distroless) |
| Dockerfile (admin) | `admin/Dockerfile` | ✅ Render-compatible (proxy rewrites, PORT) |
| docker-compose.deploy.yml | `backend/docker-compose.deploy.yml` | ✅ Full-stack local deploy test |
| CI Docker job | `.github/workflows/test.yml:380` | ✅ Builds + pushes both images on master |
| Health check (backend) | `GET /health` | ✅ Returns 200 with DB + Redis status |
| Health check (admin) | `GET /login` | ✅ Returns 200 |
| Admin proxy config | `admin/next.config.ts` | ✅ Rewrites `/api/v1/*` to backend via `API_PROXY_TARGET` |

### What Still Needs To Be Done

| Step | Status |
|------|--------|
| P37 completed (DATABASE_URL compat) | ❌ Must be done first |
| Push master to trigger Docker build | 🔜 After code changes |
| Connect repo to Render Dashboard | ❌ Manual step |
| Fill in sync:false env vars | ❌ Manual step |
| Upload firebase-credentials.json | ❌ Manual step |
| Verify health checks | ❌ Manual step |
| Update Flutter API endpoint | 🔜 Point to Render URL |

---

## Implementation Plan

### Step 1: Ensure Master Has Latest Code

```bash
git checkout master
git pull origin master
```

Verify CI passes on master — the Docker job will:
1. Build backend image → push as `namal97/nomnom-backend:latest` + `:{short-sha}`
2. Scan with Trivy (HIGH/CRITICAL only, exit-code 1 on failure)
3. Build admin image → push as `namal97/nomnom-admin:latest` + `:{short-sha}`
4. Scan with Trivy

If Trivy fails, fix vulnerabilities and re-push.

### Step 2: Verify Docker Images Locally (Optional but Recommended)

```bash
cd backend
make deploy-up

# Test backend health
curl -s http://localhost:8080/health

# Test admin
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/login

# Verify proxy works (admin calls backend through Next.js rewrite)
curl -s http://localhost:3000/api/v1/offers | head -c 200

make deploy-down
```

### Step 3: Connect Repository to Render Dashboard

1. Go to https://dashboard.render.com
2. Click **New** → **Blueprint**
3. Select the `NamalTharindu97/nomnom-lk` repository
4. Render reads `render.yaml` and displays 4 services:
   - `nomnom-backend` (Web Service, Free)
   - `nomnom-admin` (Web Service, Free)
   - `nomnom-redis` (Redis KV, Free)
   - `nomnom-db` (PostgreSQL, Free)
5. Click **Apply**

### Step 4: Fill In Required Secrets

Render will prompt for env vars marked `sync: false` in `render.yaml`:

| Variable | Value | Source |
|----------|-------|--------|
| `R2_ACCESS_KEY_ID` | `your-r2-access-key` | Cloudflare R2 Dashboard |
| `R2_SECRET_ACCESS_KEY` | `your-r2-secret-key` | Cloudflare R2 Dashboard |
| `R2_ENDPOINT` | `https://<account-id>.r2.cloudflarestorage.com` | Cloudflare R2 Dashboard |
| `ADMIN_PASSWORD` | `Admin@123` (or a new password) | Choose |

### Step 5: Upload Firebase Credentials as Secret File

1. In the Render Dashboard, navigate to the `nomnom-backend` service
2. Go to **Environment** → **Secret Files**
3. Click **Add Secret File**
4. Filename: `firebase-credentials.json`
5. Path: `/etc/secrets/firebase-credentials.json`
6. Content: Paste the contents of your Firebase service account JSON
7. Save

### Step 6: Verify Deployment

Render takes 3-5 minutes to provision services. After deployment:

**Backend health check:**
```bash
curl https://nomnom-backend.onrender.com/health
# Expected: {"database":{"status":"connected"},"redis":{"status":"connected"},"status":"ok",...}
```

**Admin login page:**
```bash
curl -s -o /dev/null -w "%{http_code}" https://nomnom-admin.onrender.com/login
# Expected: 200
```

**Admin proxy (verifies Next.js rewrites work):**
```bash
curl -s https://nomnom-admin.onrender.com/api/v1/offers | head -c 200
# Expected: JSON array of offers (proxied to backend via ish
```

**Full login flow:**
```bash
curl -s -X POST https://nomnom-admin.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@nomnom.lk","password":"<ADMIN_PASSWORD>"}'
# Expected: JWT token response
```

### Step 7: Update Flutter API Endpoint

After verifying the backend is live, update the Flutter app to point to the Render URL.

**File:** `lib/core/api_config.dart`

```dart
// Before (local dev)
static const String baseUrl = 'http://10.0.2.2:8080/api/v1';

// After (Render production)
static const String baseUrl = 'https://nomnom-backend.onrender.com/api/v1';
```

Also update any MinIO image URLs to use Cloudflare R2 public URLs. The backend serves images via the upload proxy (`/api/v1/uploads/*`), which will proxy to R2 without code changes. The existing URL format stays the same.

---

## Render Free Plan Constraints

| Constraint | Impact | Mitigation |
|-----------|--------|------------|
| 750 instance hours/month | ~360h realistic for personal dev Split across 2 web services (~720h combined) | Both services sleep after 15min idle. A single dev session uses ~8h/day = 240h/month |
| Services sleep after 15min idle | ~1min cold start | First request of the day is slow. Acceptable for personal project |
| No persistent disks | Data lost on restart | PostgreSQL data persists in managed DB. Redis data is lost (fine — sessions expire) |
| 1 free PostgreSQL (30-day expiry) | Need to upgrade or migrate after 30 days | Migrate to paid tier ($7/mo) or another provider when needed |
| 1 free Redis KV (in-memory) | Data lost on restart | Fine — only used for sessions, rate limiting, verification codes |
| No private network for free services | Backend→Redis and Backend→DB traffic goes over public internet | Render enables TLS by default. Connection strings auto-include SSL |
| 5GB outbound bandwidth/month | ~500k API responses/month | Sufficient for personal project |

---

## Rollback Plan

**To take down the deployment:**
1. Render Dashboard → Settings → Delete Blueprint
2. All 4 services are deleted together
3. Local development continues unchanged

**To update after deploy:**
1. Push to master → CI builds & pushes new Docker images
2. Render auto-deploys (watches Docker Hub for new `:latest` tags)
3. Zero-downtime deployment is built into Render's Web Service

---

## File Change Summary

| File | Change Type | Description |
|------|-------------|-------------|
| `lib/core/api_config.dart` | Modify | Point from localhost to Render URL |

**Total: 1 file changed (for Flutter URL)**

---

## Success Criteria

- [ ] `https://nomnom-backend.onrender.com/health` returns 200 with DB + Redis connected
- [ ] `https://nomnom-admin.onrender.com/login` returns 200 and renders login page
- [ ] `POST /api/v1/auth/login` returns JWT token
- [ ] `GET /api/v1/offers` returns 20 offers via admin proxy
- [ ] `GET /api/v1/restaurants` returns 11 restaurants
- [ ] Flutter app launches and loads data from Render backend
