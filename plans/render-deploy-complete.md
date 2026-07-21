# NomNom LK — Complete Render Deployment Plan

## Strategy

Release NomNom LK incrementally:

```text
Backend preparation
        ↓
Render infrastructure
        ↓
First backend deployment
        ↓
Automated backend CI/CD
        ↓
Flutter production testing
        ↓
Google Play internal testing
        ↓
Production release
        ↓
Admin deployment and iOS release
```

The backend should be stable before producing the final mobile build.

---

## Phase 0: Decisions and Accounts

Before implementation, confirm access to:

- GitHub repository and Actions secrets
- Docker Hub account
- Render account
- Cloudflare account with R2 enabled
- Firebase Console and service-account JSON
- Google Play Developer account, or plans to create one
- Sentry account, optional for initial deployment

Also verify Render's currently available PostgreSQL and Redis plans because free-tier availability and expiration policies can change.

---

## Phase 1: Prepare the Git Workflow

1. Push and merge the current `phase/P46-penpot-removal` branch through a PR.
2. Create a new branch such as `phase/P47-render-backend`.
3. Make all deployment changes on that branch.
4. Run the complete validation suite.
5. Push the branch and create a PR.
6. Merge only after approval and green CI.
7. Never push deployment code directly to `master`.

---

## Phase 2: Production-Harden the Backend

### 2.1 Cloudflare R2 Configuration

The current upload client has `Secure: false`, which works for local MinIO but not Cloudflare R2.

Add explicit configuration:

```env
R2_ENDPOINT=<account-id>.r2.cloudflarestorage.com
R2_SECURE=true
R2_FORCE_PATH_STYLE=false
R2_REGION=auto
R2_BUCKET=nomnom-images
R2_PREFIX=production
```

Local development remains:

```env
R2_ENDPOINT=localhost:9000
R2_SECURE=false
R2_FORCE_PATH_STYLE=true
R2_PREFIX=dev
```

Implementation requirements:

- Do not include `https://` in `R2_ENDPOINT`.
- Do not infer security from the hostname when an explicit setting is possible.
- Use virtual-hosted lookup for R2.
- Preserve path-style lookup for local MinIO.
- Use separate `dev` and `production` object prefixes.
- Validate malformed endpoints during startup.

### 2.2 Production Configuration Validation

When `ENVIRONMENT=production`, startup should reject:

- `JWT_SECRET=change-me`
- Missing R2 credentials
- Missing R2 endpoint
- Missing production admin password
- Default `Admin@123` password
- Invalid database configuration

Firebase, SMTP, and Sentry may remain optional initially, but the backend should log clear warnings when unavailable.

### 2.3 Database Startup

The backend already runs GORM `AutoMigrate()` during startup.

For the initial release:

- Continue using `AutoMigrate()` and existing idempotent SQL migrations.
- Add bounded database connection retries for Render startup ordering.
- Keep migrations backward-compatible.
- Reduce the production connection pool from the current maximum of 100 to a value suitable for the selected Render database plan.
- Log migration completion clearly.

Later, move production schema changes to versioned migrations rather than relying exclusively on `AutoMigrate()`.

### 2.4 Production Data Initialization

Do not automatically run the current sample seed script on every production startup. It cleans existing seeded data and could destroy production changes.

Recommended approach:

- Add an idempotent admin bootstrap.
- Create the configured admin only when no matching admin exists.
- Require a strong `ADMIN_PASSWORD` in production.
- Never update an existing admin password automatically.
- Create restaurants and offers manually through the admin dashboard later.

If demo data is required, implement a separate, explicit, one-time seed command protected by an environment flag. Never run it during normal server startup.

### 2.5 CORS

For backend-only deployment:

```env
CORS_ORIGINS=https://nomnom-admin.onrender.com
```

The Flutter mobile application does not rely on browser CORS.

During local development, keep localhost origins in `.env`. Do not use `*` in production when authenticated browser requests are supported.

### 2.6 Health and Readiness

`GET /health` should confirm:

- Server is running
- PostgreSQL is reachable
- Redis is reachable

It should not expose credentials or sensitive connection details.

Firebase and R2 can be checked through separate operational tests because external-service outages should not necessarily make the entire API health check fail.

---

## Phase 3: Create Production Infrastructure

### 3.1 Cloudflare R2

You will:

1. Open Cloudflare Dashboard.
2. Enable R2.
3. Create bucket `nomnom-images`.
4. Create an API token limited to that bucket.
5. Grant object read/write permissions.
6. Save the access key and secret in a password manager.
7. Record the bare endpoint hostname.
8. Never paste credentials into chat or commit them.

### 3.2 Backend-First Render Blueprint

The first Blueprint should provision only:

| Resource | Purpose |
|---|---|
| `nomnom-backend` | Go API |
| `nomnom-db` | PostgreSQL |
| `nomnom-redis` | Sessions, rate limits, verification codes |

Do not deploy `nomnom-admin` in the first phase. Add it after the backend has passed production testing.

### 3.3 Render Environment Variables

Render-managed variables:

| Variable | Source |
|---|---|
| `DATABASE_URL` | Render PostgreSQL |
| `REDIS_URL` | Render Redis/KV |
| `PORT` or `SERVER_PORT` | Render/service configuration |

Required secrets:

| Variable | Purpose |
|---|---|
| `JWT_SECRET` | JWT signing |
| `ADMIN_PASSWORD` | Initial admin |
| `R2_ACCESS_KEY_ID` | R2 authentication |
| `R2_SECRET_ACCESS_KEY` | R2 authentication |
| `R2_ENDPOINT` | R2 endpoint |

Required non-secret configuration:

| Variable | Recommended value |
|---|---|
| `ENVIRONMENT` | `production` |
| `R2_REGION` | `auto` |
| `R2_BUCKET` | `nomnom-images` |
| `R2_SECURE` | `true` |
| `R2_FORCE_PATH_STYLE` | `false` |
| `R2_PREFIX` | `production` |
| `ADMIN_EMAIL` | Production admin email |
| `FIREBASE_CREDENTIALS_PATH` | `/etc/secrets/firebase-credentials.json` |

Optional configuration:

- `SENTRY_DSN`
- SMTP variables
- Firebase credentials during the first infrastructure test

### 3.4 Firebase Secret File

In Render:

1. Open the backend service.
2. Open Environment or Secret Files.
3. Add `firebase-credentials.json`.
4. Mount it at `/etc/secrets/firebase-credentials.json`.
5. Set `FIREBASE_CREDENTIALS_PATH` accordingly.

Do not commit this file.

---

## Phase 4: Local Pre-Deployment Verification

Run:

```bash
docker compose up -d
```

Then verify:

```bash
go build ./...
go test ./internal/... -count=1
go test -tags=integration ./internal/handlers/... -count=1 -timeout 120s
```

Build the production image:

```bash
docker build -t nomnom-backend:release ./backend
```

Run it against test infrastructure and verify:

- Startup migrations complete
- Admin bootstrap is idempotent
- `/health` returns 200
- Login works
- Public offers and restaurants work
- Upload works through MinIO
- Missing Firebase credentials produce a warning rather than a crash
- Restarting the container does not duplicate or delete data

---

## Phase 5: First Render Deployment

1. Push the feature branch.
2. Confirm CI passes.
3. Merge the approved PR to `master`.
4. Confirm Docker Hub receives the backend image.
5. Create or apply the Render Blueprint.
6. Configure all secrets.
7. Start the deployment.
8. Monitor Render logs.
9. Wait for migration and bootstrap completion.
10. Record the actual backend URL.

Example:

```text
https://nomnom-backend.onrender.com
```

---

## Phase 6: Production Verification

### 6.1 Infrastructure Tests

Verify:

```bash
curl -f https://nomnom-backend.onrender.com/health
```

Expected result:

- HTTP 200
- PostgreSQL connected
- Redis connected

### 6.2 API Smoke Tests

Test:

- Admin login
- Token refresh
- Restaurants list
- Offers list
- Active banners
- Categories
- Upload endpoint
- Uploaded image retrieval
- SSE connection
- Authentication rejection for invalid tokens
- Owner-scoped access
- Rate limiting

Do not place production passwords directly in shell history. Use temporary environment variables or secure API tooling.

### 6.3 Persistence Tests

1. Create a temporary record.
2. Restart the backend.
3. Confirm the record remains.
4. Confirm no duplicate admin was created.
5. Confirm Redis-backed sessions behave as expected after Redis restart.

### 6.4 R2 Tests

1. Upload a test restaurant image.
2. Confirm it exists in R2.
3. Retrieve it through `/api/v1/uploads/*`.
4. Confirm correct content type.
5. Delete the test image.
6. Confirm local MinIO behavior still works afterward.

### 6.5 Firebase Tests

Test:

- Backend starts without credentials
- Backend initializes with credentials
- FCM token registration
- Test push notification
- Stale token cleanup
- Notification tap behavior in Flutter

---

## Phase 7: Backend CI/CD Enhancement

### Stage 1: Minimal Automated Deployment

Keep the current test workflow initially.

Add a production deployment workflow that:

1. Runs only after successful CI on `master`.
2. Triggers the Render deploy hook.
3. Polls `/health` until deployment completes.
4. Runs basic smoke tests.
5. Fails visibly when health checks fail.
6. Uses GitHub's `production` environment.

Required GitHub secret:

```text
RENDER_BACKEND_DEPLOY_HOOK
```

### Stage 2: Decouple Backend Releases

The current Docker job builds both backend and admin and depends on both jobs. Later separate it so backend deployment does not wait for unrelated admin packaging.

Target pipeline:

```text
Backend change or master merge
        ↓
Go lint and security checks
        ↓
Backend unit tests
        ↓
Backend integration tests
        ↓
Build immutable SHA image
        ↓
Scan image before pushing
        ↓
Push SHA and latest tags
        ↓
Trigger Render deployment
        ↓
Health and smoke tests
```

### Stage 3: Improve Image Safety

The current pipeline pushes an image before Trivy completes. Change the order:

1. Build local image.
2. Scan local image.
3. Push only if the scan passes.
4. Tag each image with the full or short commit SHA.
5. Retain `latest` only as a convenience tag.
6. Record the deployed SHA.

### Stage 4: Deployment Controls

Add:

- `concurrency` to prevent overlapping production deployments
- Manual approval initially through GitHub Environments
- Path filters for `backend/**`, `render.yaml`, and backend workflow files
- Deployment timeout
- Deployment summary with URL and commit
- Optional Sentry release annotation

### Stage 5: Rollback

Do not treat another deploy-hook call as a rollback. A proper rollback must redeploy a known previous image tag.

Initial rollback procedure:

1. Identify the last healthy SHA image.
2. Point Render to that image tag.
3. Redeploy.
4. Verify `/health`.
5. Confirm database compatibility.
6. Open an incident note in `docs/notes/`.

Automated rollback can be added later through the Render API after the basic deployment is stable.

---

## Phase 8: Production Soak Period

Allow the backend to run for at least 24 to 48 hours before building the final mobile release.

Monitor:

- Cold-start duration
- Database connection failures
- Redis failures
- HTTP 5xx responses
- R2 upload failures
- FCM failures
- Memory usage
- CPU usage
- Database storage
- Render restarts
- Sentry events, if configured

Test after the service has slept to understand the free-plan cold-start experience.

---

## Phase 9: Connect Flutter to Production

Use the existing compile-time API configuration:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://nomnom-backend.onrender.com/api/v1
```

Test on an Android emulator and physical device:

- Registration
- Email/password login
- Google Sign-In
- Logout and token refresh
- Restaurants
- Offers
- Search
- Favorites
- Profile update
- Avatar upload
- Banners
- SSE refresh
- Notifications
- Offline cache
- App resume
- Cold backend startup
- Slow or unavailable network
- Order-platform links

Do not replace the local default API URL. Use `--dart-define` for production builds.

---

## Phase 10: Firebase and Android Signing

### Firebase

Add these SHA fingerprints to Firebase:

- Debug keystore SHA-1 and SHA-256
- Release upload keystore SHA-1 and SHA-256
- Google Play App Signing SHA-1 and SHA-256 after Play Console setup

Then download the updated `google-services.json` and test Google Sign-In.

### Release Keystore

You will generate and securely store the upload keystore.

Required safeguards:

- Store outside the repository
- Keep passwords in a password manager
- Back up the keystore securely
- Never send the keystore or passwords through chat
- Keep `android/key.properties` gitignored

---

## Phase 11: Google Play Release Readiness

Before submission, complete:

| Requirement | Status needed |
|---|---|
| Signed AAB | Required |
| Production API tested | Required |
| App icon | Required |
| Feature graphic | Required |
| Phone screenshots | Required |
| Tablet screenshots if supported | Recommended/possibly required |
| Privacy policy URL | Required |
| Data Safety form | Required |
| Content rating | Required |
| Target audience | Required |
| Contact email | Required |
| Store description | Required |
| Account deletion flow | Required if users can create accounts |
| Notification permission handling | Required |
| Current target API requirement | Must be verified at submission |
| Closed testing requirement | Must be verified for your developer-account type |

The account-deletion requirement needs an explicit audit. If users can register but cannot delete their accounts from the app and through a public web route, that must be addressed before release.

---

## Phase 12: Build and Internal Testing

Build with:

```bash
API_BASE_URL=https://nomnom-backend.onrender.com/api/v1 \
  ./scripts/build-android-release.sh
```

Verify:

- AAB is release-signed
- APK installs on a physical device
- Internet permission exists
- Production endpoint is embedded
- Debug symbols are retained where needed
- App starts without white screen
- Google Sign-In works
- Push notifications work
- Images load from R2
- No localhost addresses remain

Upload the AAB to Google Play Internal Testing first.

---

## Phase 13: Play Console Testing

1. Enable Play App Signing.
2. Upload the AAB to Internal Testing.
3. Add testers.
4. Install through Google Play.
5. Add Play signing fingerprints to Firebase.
6. Repeat Google Sign-In tests.
7. Review the pre-launch report.
8. Fix crashes, ANRs, accessibility issues, and policy warnings.
9. Complete required closed testing if applicable.
10. Promote to production only after internal testing passes.

---

## Phase 14: Production Launch

Use a staged rollout if available:

```text
10% → monitor → 25% → monitor → 50% → monitor → 100%
```

Monitor:

- Crash-free users
- ANR rate
- Login failures
- API error rate
- R2 errors
- FCM errors
- Backend latency
- Database saturation
- User reviews

Prepare a rapid rollback or mobile hotfix process before moving to 100%.

---

## Phase 15: Admin Dashboard

Deploy the admin dashboard only after the backend is stable.

Steps:

1. Add `nomnom-admin` back to `render.yaml`.
2. Set `API_PROXY_TARGET` to the backend.
3. Add the admin origin to backend CORS.
4. Deploy the admin image.
5. Test login, RBAC, owner scoping, uploads, banners, and notifications.
6. Run production-safe E2E smoke tests.
7. Do not run destructive CRUD tests against production data.

---

## Phase 16: iOS Release

Handle iOS separately after Android:

- Upgrade Flutter to a version compatible with the installed iOS/Xcode environment.
- Create the Apple Developer account.
- Configure bundle signing.
- Add APNs capability.
- Upload APNs credentials to Firebase.
- Configure the App Store ID.
- Build and test through TestFlight.
- Complete App Privacy information.
- Submit to App Review.

---

## Recommended Order for Today

If we begin today, the practical order is:

1. Verify Render's current database and Redis plans.
2. Merge or finish the current P46 branch through the normal PR workflow.
3. Create `phase/P47-render-backend`.
4. Fix explicit R2 secure/path-style configuration.
5. Add production configuration validation.
6. Add safe, idempotent admin bootstrap.
7. Add database startup retries and appropriate pool limits.
8. Convert `render.yaml` to backend-first deployment.
9. Run backend tests and Docker verification.
10. Create R2 resources.
11. Configure Render secrets.
12. Deploy.
13. Run production smoke tests.
14. Add the first deploy-hook workflow.
15. Start the 24 to 48-hour soak period.
16. Connect Flutter to the hosted API after backend validation.

---

## Completion Gates

### Backend Ready

- `/health` consistently returns 200
- Database survives restarts
- Admin bootstrap is idempotent
- R2 uploads work
- Authentication works
- SSE works
- No default secrets remain
- CI deploys only tested images
- Previous image SHA is available for rollback

### Mobile Ready

- Production API tested on physical Android device
- Google Sign-In works with release and Play signing certificates
- Push notifications work
- Account deletion requirement is satisfied
- Signed AAB passes Play pre-launch testing
- Privacy policy and Data Safety answers are complete
- No critical Sentry, crash, or ANR findings remain

---

## Production Data Policy

Bootstrap only the admin account automatically. Add real restaurant and offer data through the admin dashboard. Do not auto-seed sample data in production.

---

## Files to Change

| File | Phase | Change |
|------|-------|--------|
| `backend/internal/config/config.go` | 2 | Add `R2_SECURE`, `R2_FORCE_PATH_STYLE` as explicit bool settings |
| `backend/internal/services/upload_service.go` | 2 | Use explicit secure/path-style config instead of hardcoded values |
| `backend/cmd/server/main.go` | 2 | Add production config validation and admin bootstrap |
| `backend/internal/database/postgres.go` | 2 | Add connection retries and production-safe pool limits |
| `render.yaml` | 3 | Backend-only Blueprint with explicit R2 configuration |
| `.github/workflows/deploy.yml` | 7 | New Render deployment workflow |
| `.github/workflows/test.yml` | 7 | Later decouple backend and admin Docker jobs |

---

## Rollback Plan

1. Identify the last healthy Docker image SHA.
2. Point Render to that image.
3. Redeploy.
4. Verify `/health`.
5. Confirm database compatibility.
6. Document the incident in `docs/notes/`.

---

## Success Criteria

| Criterion | Gate |
|-----------|------|
| `/health` returns 200 | Backend ready |
| Admin login works | Backend ready |
| Restaurants and offers load | Backend ready |
| R2 uploads work | Backend ready |
| SSE works | Backend ready |
| No default production secrets | Backend ready |
| Flutter loads data from Render | Mobile ready |
| Google Sign-In works | Mobile ready |
| Push notifications work | Mobile ready |
| Signed AAB passes Play testing | Play Store ready |
| Privacy policy and account deletion handled | Play Store ready |
| Admin dashboard works | Phase 15 ready |
| iOS build passes TestFlight | iOS ready |
