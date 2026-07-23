# Render Deployment — Full Setup Guide

## Prerequisites

1. **Render account** — Sign up at https://dashboard.render.com/register (use GitHub)
2. **Render CLI** — Install via Homebrew:
   ```bash
   brew update && brew install render
   ```
3. **PostgreSQL client** (for DB fixes):
   ```bash
   brew install postgresql@16
   ```
4. **Credit card** — Required on Render for free-tier PostgreSQL and Redis

## Step 1: Authenticate Render CLI

```bash
render login
# Opens browser → click "Authorize CLI"
```

Set workspace:
```bash
render workspace set
# Pick "My Workspace"
```

Verify:
```bash
render whoami
# → Name: Namal Tharindu
# → Email: NamalA701997@gmail.com
```

## Step 2: Create Resources

### PostgreSQL Database
```bash
render postgres create \
  --name nomnom-db \
  --plan free \
  --version 16 \
  --region singapore \
  --database-name nomnom \
  --database-user nomnom \
  --ip-allow-list "" \
  --confirm --output json
```
Result: `dpg-d9frkbjbc2fs73bq2ncg-a`

### Redis Key Value
```bash
render kv create \
  --name nomnom-redis \
  --plan free \
  --region singapore \
  --confirm --output json
```
Result: `red-d9frkeernols73cji320`

### Backend Web Service
```bash
render services create \
  --name nomnom-backend \
  --type web_service \
  --image docker.io/namal97/nomnom-backend:latest \
  --plan free \
  --region singapore \
  --health-check-path /health \
  --auto-deploy \
  --env-var "SERVER_PORT=10000" \
  --env-var "ENVIRONMENT=production" \
  --env-var "R2_REGION=auto" \
  --env-var "R2_BUCKET=nomnom-images" \
  --env-var "R2_SECURE=true" \
  --env-var "R2_FORCE_PATH_STYLE=false" \
  --env-var "R2_PREFIX=production" \
  --env-var "CORS_ORIGINS=https://nomnom-admin-e41y.onrender.com" \
  --env-var "ADMIN_EMAIL=admin@nomnom.lk" \
  --env-var "FIREBASE_CREDENTIALS_PATH=/etc/secrets/firebase-credentials.json" \
  --env-var "DATABASE_URL=from_service:nomnom-db" \
  --env-var "REDIS_URL=from_service:nomnom-redis" \
  --env-var "JWT_SECRET=generate" \
  --env-var "R2_ACCESS_KEY_ID=placeholder" \
  --env-var "R2_SECRET_ACCESS_KEY=placeholder" \
  --env-var "R2_ENDPOINT=placeholder" \
  --env-var "ADMIN_PASSWORD=placeholder" \
  --confirm --output json
```
Result: `srv-d9frkhgk1i2s73be0j50`
URL: `https://nomnom-backend-7iq0.onrender.com`

## Step 3: Set Runtime Secrets

Do not print `~/.render/cli.yaml`, raw connection-info responses, or secret
values in a terminal transcript. Use the Render Dashboard for manual setup and
protected GitHub environment secrets for automated deployment.

1. Open the PostgreSQL resource's **Connect** panel and copy its internal URL
   directly into the backend service's `DATABASE_URL` environment field.
2. Open the Redis resource's **Connect** panel and copy its internal URL directly
   into `REDIS_URL`.
3. In the backend service's **Environment** page, enter `JWT_SECRET`, the R2
   credentials, and the bootstrap admin password directly. Never reuse a human
   login password for bootstrap configuration.
4. Add `firebase-credentials.json` through Render's **Secret Files** interface
   and keep `FIREBASE_CREDENTIALS_PATH=/etc/secrets/firebase-credentials.json`.
5. Save the configuration and trigger a fresh deploy with `render deploys
   create srv-d9frkhgk1i2s73be0j50 --wait`.

Secret-file updates require a new deploy, not only a service restart.

## Step 4: Verify

```bash
# Health check
curl https://nomnom-backend-7iq0.onrender.com/health

# Admin login
curl -X POST https://nomnom-backend-7iq0.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  --data-binary @/path/to/private-login-payload.json
```

## Step 5: Seed Data (Optional)

The production database starts empty. To seed it with sample data:

1. Add only the operator's current `/32` address through the PostgreSQL Render
   Dashboard allow list.
2. Run the approved seed operation with `render psql` or a local client.
3. Remove the temporary allow-list entry immediately.
4. Verify the allow list is empty before ending the maintenance session.

## Architecture Notes

- Backend runs as a **Docker image** (`namal97/nomnom-backend:latest`) — NOT built from source on Render
- Docker images are built by **GitHub Actions CI** on every push to `master`
- Render pulls the latest `latest` tag on each deploy
- DB and Redis are **private-only** (no public access from Render's internal network)
- Firebase credentials mounted as a secret file at `/etc/secrets/firebase-credentials.json`
- Admin user is **auto-created on first boot** if no admin exists (idempotent bootstrap)

## Step 6: Deploy the Admin Dashboard

The admin dashboard uses the Docker image published by GitHub Actions and
proxies browser API requests to the hosted backend.

The Next.js rewrite destination is compiled during the Docker build. Build the
image with both arguments:

```bash
docker build \
  --build-arg NEXT_PUBLIC_API_URL=/api/v1 \
  --build-arg API_PROXY_TARGET=https://nomnom-backend-7iq0.onrender.com \
  -t namal97/nomnom-admin:latest admin
```

```bash
render services create \
  --name nomnom-admin \
  --type web_service \
  --image docker.io/namal97/nomnom-admin:latest \
  --plan free \
  --region singapore \
  --health-check-path /login \
  --auto-deploy \
  --env-var "NEXT_PUBLIC_API_URL=/api/v1" \
  --env-var "API_PROXY_TARGET=https://nomnom-backend-7iq0.onrender.com" \
  --confirm --output json
```

After creation, record the generated admin URL and update backend
`CORS_ORIGINS` to that exact HTTPS origin. Verify the frontend and proxy:

```bash
curl -I https://nomnom-admin-e41y.onrender.com/login
curl https://nomnom-admin-e41y.onrender.com/api/v1/restaurants
```

Created service: `srv-d9ft1t8okrbs738q9f60`

Live URL: `https://nomnom-admin-e41y.onrender.com`
