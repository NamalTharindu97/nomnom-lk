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

## Step 3: Set Real Secrets via Render API

The CLI doesn't support env var updates. Use the API directly.

### Get API Key

The Render CLI stores its token in `~/.render/cli.yaml`. Extract the API key:
```bash
cat ~/.render/cli.yaml
# Look for: api.key: rnd_...
```

### Get Connection Strings

```bash
RENDER_API_KEY="rnd_..."
SERVICE_ID="srv-d9frkhgk1i2s73be0j50"

# PostgreSQL
curl -s "https://api.render.com/v1/postgres/dpg-d9frkbjbc2fs73bq2ncg-a/connection-info" \
  -H "Authorization: Bearer ${RENDER_API_KEY}"

# Redis
curl -s "https://api.render.com/v1/redis/red-d9frkeernols73cji320/connection-info" \
  -H "Authorization: Bearer ${RENDER_API_KEY}"
```

### Update Environment Variables

```bash
# R2 Access Key
curl -s -X PUT "https://api.render.com/v1/services/${SERVICE_ID}/env-vars/R2_ACCESS_KEY_ID" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"value": "YOUR_R2_ACCESS_KEY"}'

# R2 Secret Key
curl -s -X PUT "https://api.render.com/v1/services/${SERVICE_ID}/env-vars/R2_SECRET_ACCESS_KEY" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"value": "YOUR_R2_SECRET_KEY"}'

# R2 Endpoint
curl -s -X PUT "https://api.render.com/v1/services/${SERVICE_ID}/env-vars/R2_ENDPOINT" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"value": "YOUR_R2_ENDPOINT.r2.cloudflarestorage.com"}'

# Admin Password
curl -s -X PUT "https://api.render.com/v1/services/${SERVICE_ID}/env-vars/ADMIN_PASSWORD" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"value": "YOUR_ADMIN_PASSWORD"}'

# DATABASE_URL (internal connection string from step above)
curl -s -X PUT "https://api.render.com/v1/services/${SERVICE_ID}/env-vars/DATABASE_URL" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"value": "postgresql://nomnom:PASSWORD@dpg-xxx/nomnom_xxx"}'

# REDIS_URL (internal connection string from step above)
curl -s -X PUT "https://api.render.com/v1/services/${SERVICE_ID}/env-vars/REDIS_URL" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"value": "rediss://red-xxx:PASSWORD@red-xxx:6379"}'

# JWT_SECRET (generate a random one)
JWT_SECRET=$(openssl rand -hex 32)
curl -s -X PUT "https://api.render.com/v1/services/${SERVICE_ID}/env-vars/JWT_SECRET" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"value\": \"${JWT_SECRET}\"}"
```

### Upload Firebase Credentials

```bash
jq -Rs '{content: .}' backend/config/firebase-credentials.json > /tmp/firebase-secret.json

curl -s -X PUT "https://api.render.com/v1/services/${SERVICE_ID}/secret-files/firebase-credentials.json" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  --data-binary @/tmp/firebase-secret.json
```

Secret-file updates require a new deploy, not only a service restart.

### Trigger Redeploy

```bash
curl -s -X POST "https://api.render.com/v1/services/${SERVICE_ID}/deploys" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{}'
```

## Step 4: Verify

```bash
# Health check
curl https://nomnom-backend-7iq0.onrender.com/health

# Admin login
curl -X POST https://nomnom-backend-7iq0.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@nomnom.lk","password":"Admin@123"}'
```

## Step 5: Seed Data (Optional)

The production database starts empty. To seed it with sample data:

```bash
# Add your IP to DB allow list temporarily
curl -s -X PATCH "https://api.render.com/v1/postgres/dpg-d9frkbjbc2fs73bq2ncg-a" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"ipAllowList\": [{\"cidrBlock\": \"$(curl -s ifconfig.me)/32\", \"description\": \"seed\"}]}"

# Seed via render psql (or local psql with external connection string)
render psql nomnom-db --command "..." --output text

# Remove IP from allow list after
curl -s -X PATCH "https://api.render.com/v1/postgres/dpg-d9frkbjbc2fs73bq2ncg-a" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"ipAllowList": []}'
```

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
