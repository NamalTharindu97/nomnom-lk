# P38 — Render.com Phased Deployment

## Goal
Deploy NomNom LK to production in phases: backend first, then admin dashboard, then Flutter app. Enhance CI/CD pipeline for automated deployments.

---

## Deployment Strategy

```
Phase 1: Backend only (tomorrow)
Phase 2: Admin dashboard (week 2)
Phase 3: Flutter app → production (week 3)
Phase 4: CI/CD enhancement (ongoing)
```

---

## Current State (Ready to Deploy)

| Asset | Status | Notes |
|-------|--------|-------|
| `render.yaml` | ✅ | 4 services: backend, admin, postgres, redis |
| Backend Dockerfile | ✅ | PORT fallback, distroless |
| Admin Dockerfile | ✅ | Proxy rewrites, PORT |
| CI Docker job | ✅ | Builds + pushes on master |
| Health check | ✅ | `GET /health` |
| DATABASE_URL parsing | ✅ | `config.go:186` |
| REDIS_URL parsing | ✅ | `config.go:200` |
| PORT fallback | ✅ | `config.go:140` |

---

## Phase 1: Backend on Render (Tomorrow)

### Code Changes Required

#### 1.1 Fix R2 Production Config
**File:** `backend/internal/services/upload_service.go`

Current issue: `Secure: false` hardcoded. R2 requires HTTPS.

```go
// Change from:
client, err := minio.New(cfg.Endpoint, &minio.Options{
    Creds:        credentials.NewStaticV4(cfg.AccessKeyID, cfg.SecretAccessKey, ""),
    Secure:       false,
    Region:       cfg.Region,
    BucketLookup: lookupType,
})

// Change to:
isR2 := !strings.Contains(cfg.Endpoint, "localhost") && !strings.Contains(cfg.Endpoint, "127.0.0.1")
client, err := minio.New(cfg.Endpoint, &minio.Options{
    Creds:        credentials.NewStaticV4(cfg.AccessKeyID, cfg.SecretAccessKey, ""),
    Secure:       isR2,
    Region:       cfg.Region,
    BucketLookup: lookupType,
})
```

Also fix `ForcePathStyle`:
```go
// Change from:
if cfg.ForcePathStyle {
    lookupType = minio.BucketLookupPath
}

// Change to:
// Only use path style for MinIO (localhost), not R2
if cfg.ForcePathStyle && isR2 {
    lookupType = minio.BucketLookupAuto
} else if cfg.ForcePathStyle {
    lookupType = minio.BucketLookupPath
}
```

#### 1.2 Add Auto-Seed on First Boot
**File:** `backend/cmd/server/main.go`

After `database.NewPostgresDB()`, check if database is empty and seed:

```go
db := database.NewPostgresDB(&cfg.Database)

// Auto-seed on first boot (production)
if os.Getenv("ENVIRONMENT") == "production" {
    database.AutoSeed(db, &cfg.Admin)
}
```

**File:** `backend/internal/database/seed.go` (new function)

```go
func AutoSeed(db *gorm.DB, adminCfg *config.AdminConfig) {
    var count int64
    db.Model(&models.User{}).Count(&count)
    if count > 0 {
        log.Println("[DB] Database already seeded, skipping")
        return
    }
    log.Println("[DB] Empty database detected, running seed...")
    // Run seed logic here
}
```

#### 1.3 Update CORS for Render
**File:** `render.yaml`

```yaml
- key: CORS_ORIGINS
  value: "https://nomnom-admin.onrender.com,https://nomnom-backend.onrender.com"
```

### Manual Steps (You Do)

| Step | Where | Time |
|------|-------|------|
| 1. Create Cloudflare R2 bucket `nomnom-images` | https://dash.cloudflare.com → R2 | 5 min |
| 2. Create R2 API token (read/write) | R2 → Manage R2 API Tokens | 2 min |
| 3. Go to Render Dashboard → New → Blueprint | https://dashboard.render.com | 2 min |
| 4. Select repo `NamalTharindu97/nomnom-lk` | Render | 1 min |
| 5. Fill in `sync: false` env vars | Render (R2 keys, admin password) | 3 min |
| 6. Upload `firebase-credentials.json` | Render → Backend → Secret Files | 2 min |
| 7. Wait 3-5 min, verify health | `curl https://nomnom-backend.onrender.com/health` | 1 min |

### Verification

```bash
# Health check
curl https://nomnom-backend.onrender.com/health
# Expected: {"database":{"status":"connected"},"redis":{"status":"connected"},"status":"ok"}

# Login
curl -X POST https://nomnom-backend.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@nomnom.lk","password":"Admin@123"}'
# Expected: JWT token

# Offers
curl https://nomnom-backend.onrender.com/api/v1/offers
# Expected: JSON array of offers

# Restaurants
curl https://nomnom-backend.onrender.com/api/v1/restaurants
# Expected: JSON array of restaurants
```

### Current CI/CD Flow (Already Works)

```
You push to master
    ↓
GitHub Actions: test.yml runs (all tests)
    ↓ (pass)
Docker job: builds + pushes nomnom-backend:latest
    ↓
Render: watches Docker Hub → auto-deploys
    ↓
Backend live at https://nomnom-backend.onrender.com
```

**No CI changes needed for Phase 1.**

---

## Phase 2: Admin Dashboard (Week 2)

### What Changes

1. Admin dashboard connects to Render backend via `API_PROXY_TARGET`
2. CORS_ORIGINS includes admin URL
3. Admin auto-deploys after backend is stable

### Manual Steps

1. Verify backend is stable for 1 week
2. In Render Dashboard, enable `nomnom-admin` service
3. Set `API_PROXY_TARGET` to backend service URL
4. Verify admin login works

### Verification

```bash
# Admin login page
curl -o /dev/null -w "%{http_code}" https://nomnom-admin.onrender.com/login
# Expected: 200

# Admin proxy (Next.js rewrites to backend)
curl https://nomnom-admin.onrender.com/api/v1/offers | head -c 200
# Expected: JSON array of offers
```

---

## Phase 3: Flutter App → Production (Week 3)

### What Changes

1. Flutter app points to `https://nomnom-backend.onrender.com/api/v1`
2. Build release AAB with `--dart-define=API_BASE_URL`
3. Generate release keystore
4. Submit to Play Store

### Manual Steps

1. Get SHA-1 fingerprint → add to Firebase Console
2. Generate release keystore (`keytool` command)
3. Create `android/key.properties`
4. Build release AAB
5. Sign up for Play Store ($25)
6. Upload AAB → submit for review

### Build Command

```bash
# Build Flutter pointing to Render backend
flutter build apk --release \
  --dart-define=API_BASE_URL=https://nomnom-backend.onrender.com/api/v1

flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://nomnom-backend.onrender.com/api/v1
```

---

## Phase 4: CI/CD Enhancement (Ongoing)

### 4a. Separate Deploy Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Render

on:
  workflow_run:
    workflows: ["Test"]
    types: [completed]
    branches: [master]

jobs:
  deploy:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Render deploy
        run: |
          curl -X POST "${{ secrets.RENDER_DEPLOY_HOOK }}"
          
      - name: Wait for deploy + health check
        run: |
          sleep 120
          curl -f https://nomnom-backend.onrender.com/health
```

**Benefits:**
- Deploy only happens when tests pass
- Automatic rollback if health check fails
- Clear deployment status in GitHub

### 4b. Render Deploy Hook Setup

1. Go to Render Dashboard → Backend service → Settings
2. Copy "Deploy Hook" URL
3. Add to GitHub repo secrets as `RENDER_DEPLOY_HOOK`

### 4c. Branch Previews (Later)

Render supports branch-based previews:
- Push to `phase/*` branch → Render creates preview environment
- Test changes before merging to master
- Automatic cleanup when branch is deleted

---

## Render Free Plan Constraints

| Constraint | Impact | Mitigation |
|-----------|--------|------------|
| 750 instance hours/month | ~360h for personal dev | Services sleep after 15min idle |
| Cold start ~1min | First request slow | Acceptable for personal project |
| PostgreSQL 30-day expiry | Need to upgrade | Migrate to paid tier ($7/mo) |
| Redis data lost on restart | Sessions expire | Fine for our use case |
| 5GB outbound bandwidth | ~500k API responses | Sufficient |

---

## Rollback Plan

**To take down:**
1. Render Dashboard → Settings → Delete Blueprint
2. All services deleted together

**To update:**
1. Push to master → CI builds new Docker images
2. Render auto-deploys (watches Docker Hub)
3. Zero-downtime deployment

---

## Success Criteria

### Phase 1 (Tomorrow)
- [ ] `https://nomnom-backend.onrender.com/health` returns 200
- [ ] `POST /api/v1/auth/login` returns JWT token
- [ ] `GET /api/v1/offers` returns offers
- [ ] `GET /api/v1/restaurants` returns restaurants
- [ ] Image uploads work via R2

### Phase 2 (Week 2)
- [ ] `https://nomnom-admin.onrender.com/login` returns 200
- [ ] Admin can manage restaurants/offers via hosted backend
- [ ] CORS works for admin dashboard

### Phase 3 (Week 3)
- [ ] Flutter app loads data from Render backend
- [ ] Release AAB builds successfully
- [ ] App submitted to Play Store

### Phase 4 (Ongoing)
- [ ] Deploy workflow triggers on master push
- [ ] Health check verifies deployment
- [ ] Branch previews work for testing

---

## File Changes Summary

| Phase | File | Change |
|-------|------|--------|
| 1 | `backend/internal/services/upload_service.go` | Fix R2 Secure + PathStyle |
| 1 | `backend/cmd/server/main.go` | Add auto-seed on first boot |
| 1 | `backend/internal/database/postgres.go` | Add AutoSeed function |
| 1 | `render.yaml` | Update CORS_ORIGINS |
| 2 | (none) | Just enable admin service |
| 3 | `lib/core/api_config.dart` | Point to Render URL |
| 4 | `.github/workflows/deploy.yml` | New deploy workflow |

**Total: 5 files changed across all phases**
