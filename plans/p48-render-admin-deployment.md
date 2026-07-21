# P48 - Render Admin Dashboard Deployment

## Goal

Deploy the NomNom LK Next.js admin dashboard to Render in Singapore using the
default Render URL. A custom domain will be configured later.

## Architecture

```text
Browser
  -> https://nomnom-admin-*.onrender.com
  -> Next.js rewrite /api/v1/*
  -> https://nomnom-backend-7iq0.onrender.com/api/v1/*
  -> PostgreSQL, Redis, and Cloudflare R2
```

The browser uses the admin origin for API requests. Next.js proxies those
requests to the hosted backend, avoiding mixed-content and browser CORS issues.

## Deployment Method

- Render resource: image-backed web service
- Image: `docker.io/namal97/nomnom-admin:latest`
- Region: Singapore
- Plan: Free
- Health check: `/login`
- Client API base baked into image: `/api/v1`
- Proxy target baked into the Next.js rewrite manifest:
  `https://nomnom-backend-7iq0.onrender.com`

GitHub Actions publishes both `latest` and commit-SHA image tags after changes
are merged to `master` and the backend/admin jobs pass.

## Phase 1 - Repository Preparation

- Work on `phase/P48-render-admin`.
- Add `nomnom-admin` to `render.yaml` without recreating existing resources.
- Include the banner empty-table hydration fix.
- Keep local `.env.local` files and credentials out of Git.
- Update deployment documentation with the service, URL, commands, and rollback.
- Correct the Render Firebase secret-file payload field to `content`.

## Phase 2 - Validation

Run:

```bash
cd admin
npm install
npm run lint
npx tsc --noEmit
npm run test:unit
npm run build
```

Run a non-destructive browser smoke test against the hosted backend and verify:

- Admin login succeeds.
- Every dashboard route loads.
- No browser request targets `localhost:8080`.
- No console, hydration, or failed-request errors occur.
- R2-backed restaurant, offer, and banner images load.
- Admin and owner route guards remain effective.

## Phase 3 - Image Publication

- Commit and push the P48 branch.
- Open a pull request and wait for green CI.
- Merge only after approval.
- Confirm Docker Hub receives `nomnom-admin:latest` and the SHA tag.

The initial Render service may use the current `latest` image. After the P48 PR
is merged, redeploy to pick up the hydration fix and documentation-aligned image.

## Phase 4 - Render Service

Create `nomnom-admin` as a free Singapore web service with:

```env
NEXT_PUBLIC_API_URL=/api/v1
API_PROXY_TARGET=https://nomnom-backend-7iq0.onrender.com
```

Render supplies `PORT`; the existing Docker command reads it at runtime.

Next.js evaluates `rewrites()` during `next build`. The Docker build must pass
both `NEXT_PUBLIC_API_URL=/api/v1` and the production `API_PROXY_TARGET`; setting
only the runtime variable does not replace the compiled rewrite destination.

After Render assigns the service URL:

- Record the service ID and live URL.
- Update backend `CORS_ORIGINS` to the exact admin origin.
- Deploy the backend environment change.
- Update `render.yaml` and deployment documentation with the actual URL.

## Phase 5 - Hosted Verification

Verify:

- `/login` returns HTTP 200.
- `/api/v1/restaurants` returns HTTP 200 through the admin proxy.
- Admin login works from the hosted origin.
- Dashboard statistics and all navigation routes load.
- Banners and R2 images render.
- Hard refresh works on protected dashboard routes.
- Logout clears local storage and cookies.
- Owner login remains correctly scoped.
- Backend and mobile application remain healthy.

## Phase 6 - CI/CD Follow-up

After the initial deployment is stable:

- Add a Render deploy hook or API deployment job after Docker image publication.
- Run a hosted `/login` health check after deployment.
- Avoid enabling two mechanisms that trigger duplicate deployments.
- Prefer the SHA-tagged image for deterministic rollback.

## Rollback

- Change the Render image to the previous known-good SHA tag.
- Trigger a new deploy.
- Verify `/login` and `/api/v1/restaurants`.
- The backend, database, Redis, R2 data, and mobile app are unaffected by an
  admin frontend rollback.

## Acceptance Criteria

- The admin dashboard is available at a default Render HTTPS URL.
- Login, proxying, route guards, images, and banners work.
- Browser smoke tests report no application errors.
- The deployment and rollback procedures are documented.
- No credentials are committed to the repository.

## Operational Notes

- Render free web services can sleep after inactivity, so the first request can
  be slower.
- The current free PostgreSQL resource reports an expiry date of 2026-08-20 and
  must be upgraded or replaced before permanent production use.
- A custom admin domain is intentionally deferred.

## Deployment Result

- Service: `nomnom-admin`
- Service ID: `srv-d9ft1t8okrbs738q9f60`
- URL: `https://nomnom-admin-e41y.onrender.com`
- Verified image source commit: `6c084ce`
- Hosted `/login`, API proxy, banners, images, hard refresh, and owner route guard
  verified successfully.
- Browser sweep: 12 dashboard routes, 3 banners, 6 rendered images, 0
  application failures.
