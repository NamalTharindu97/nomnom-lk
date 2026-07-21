# Render Deployment — Commands We Ran

Chronological record of every command executed during the deployment session.

## 1. Render CLI Setup

```bash
# Install Render CLI
brew update && brew install render

# Install PostgreSQL client (for DB access)
brew install postgresql@16

# Authenticate (opens browser)
render login

# Set workspace (interactive — pick "My Workspace")
render workspace set
# → tea-d9freo6rnols73cj90u0

# Verify auth
render whoami
# → Name: Namal Tharindu
# → Email: NamalA701997@gmail.com
```

## 2. Validate Blueprint

```bash
render blueprints validate
```
Output:
```json
{
  "plan": {
    "databases": ["nomnom-db"],
    "keyValue": ["nomnom-redis"],
    "services": ["nomnom-backend"],
    "totalActions": 3
  },
  "valid": true
}
```

## 3. Create Resources

### PostgreSQL
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
Created: `dpg-d9frkbjbc2fs73bq2ncg-a`

### Redis
```bash
render kv create \
  --name nomnom-redis \
  --plan free \
  --region singapore \
  --confirm --output json
```
Created: `red-d9frkeernols73cji320`

### Backend Service
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
  --env-var "CORS_ORIGINS=https://nomnom-admin.onrender.com" \
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
Created: `srv-d9frkhgk1i2s73be0j50`
URL: `https://nomnom-backend-7iq0.onrender.com`

## 4. Fetch Connection Strings

```bash
RENDER_API_KEY="rnd_..."  # from ~/.render/cli.yaml

# PostgreSQL
curl -s "https://api.render.com/v1/postgres/dpg-d9frkbjbc2fs73bq2ncg-a/connection-info" \
  -H "Authorization: Bearer ${RENDER_API_KEY}"
# → internalConnectionString: postgresql://nomnom:PASSWORD@dpg-d9frkbjbc2fs73bq2ncg-a/nomnom_bd9o

# Redis
curl -s "https://api.render.com/v1/redis/red-d9frkeernols73cji320/connection-info" \
  -H "Authorization: Bearer ${RENDER_API_KEY}"
# → internalConnectionString: redis://red-d9frkeernols73cji320:6379
# → externalConnectionString: rediss://red-d9frkeernols73cji320:PASSWORD@...:6379
```

## 5. Set Secrets via API

```bash
RENDER_API_KEY="rnd_..."
SERVICE_ID="srv-d9frkhgk1i2s73be0j50"

# Individual env var updates
curl -s -X PUT "https://api.render.com/v1/services/${SERVICE_ID}/env-vars/R2_ACCESS_KEY_ID" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"value": "YOUR_R2_ACCESS_KEY"}'

curl -s -X PUT "https://api.render.com/v1/services/${SERVICE_ID}/env-vars/R2_SECRET_ACCESS_KEY" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"value": "YOUR_R2_SECRET_KEY"}'

curl -s -X PUT "https://api.render.com/v1/services/${SERVICE_ID}/env-vars/R2_ENDPOINT" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"value": "YOUR_R2_ENDPOINT.r2.cloudflarestorage.com"}'

curl -s -X PUT "https://api.render.com/v1/services/${SERVICE_ID}/env-vars/ADMIN_PASSWORD" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"value": "YOUR_ADMIN_PASSWORD"}'

# DATABASE_URL and REDIS_URL
curl -s -X PUT "https://api.render.com/v1/services/${SERVICE_ID}/env-vars/DATABASE_URL" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"value": "postgresql://nomnom:PASSWORD@dpg-xxx/nomnom_xxx"}'

curl -s -X PUT "https://api.render.com/v1/services/${SERVICE_ID}/env-vars/REDIS_URL" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"value": "rediss://red-xxx:PASSWORD@red-xxx:6379"}'

# JWT_SECRET
JWT_SECRET=$(openssl rand -hex 32)
curl -s -X PUT "https://api.render.com/v1/services/${SERVICE_ID}/env-vars/JWT_SECRET" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"value\": \"${JWT_SECRET}\"}"
```

## 6. Upload Firebase Credentials

```bash
jq -Rs '{content: .}' backend/config/firebase-credentials.json > /tmp/firebase-secret.json

curl -s -X PUT "https://api.render.com/v1/services/${SERVICE_ID}/secret-files/firebase-credentials.json" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  --data-binary @/tmp/firebase-secret.json
```

The secret file is mounted on a fresh deploy; a restart alone keeps the old
mounted file.

## 7. First Deploy & Test

```bash
# Trigger deploy
curl -s -X POST "https://api.render.com/v1/services/${SERVICE_ID}/deploys" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{}'

# Health check (after ~1 min)
curl https://nomnom-backend-7iq0.onrender.com/health
# → {"database":{"status":"connected"},"redis":{"status":"connected"},"status":"ok"}

# Admin login test
curl -X POST https://nomnom-backend-7iq0.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@nomnom.lk","password":"Admin@123"}'
# → FAILED: "please verify your email first"
```

## 8. Fix — Admin Bootstrap (EmailVerifiedAt)

### Code change
In `backend/cmd/server/main.go`, added `EmailVerifiedAt: &now` to admin bootstrap user struct.

### Push & rebuild
```bash
git checkout -b phase/P47-admin-bootstrap-fix
git add backend/cmd/server/main.go
git commit -m "Fix admin bootstrap: set EmailVerifiedAt on first boot"
git push origin phase/P47-admin-bootstrap-fix

gh pr create --title "Fix: admin bootstrap EmailVerifiedAt" --body "..."
gh pr merge 31 --merge
```

### Wait for Docker rebuild
```bash
# Monitor Docker Hub for new image
for i in $(seq 1 20); do
  LAST_UPDATED=$(curl -s "https://hub.docker.com/v2/repositories/namal97/nomnom-backend/tags/latest" | python3 -c "import sys,json; print(json.load(sys.stdin)['last_updated'])")
  echo "[$i] Docker latest: ${LAST_UPDATED}"
  if [[ "$LAST_UPDATED" > "2026-07-21T18:40" ]]; then
    echo "Docker image updated!"
    break
  fi
  sleep 15
done
```

### Redeploy
```bash
curl -s -X POST "https://api.render.com/v1/services/${SERVICE_ID}/deploys" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{}'
```

## 9. Fix — Existing Admin in Database

The admin was already created by the first deploy (without `email_verified_at`). The bootstrap code only runs when NO admin exists. So we fixed it directly in the DB.

```bash
# Add our IP to DB allow list
MY_IP=$(curl -s ifconfig.me)
curl -s -X PATCH "https://api.render.com/v1/postgres/dpg-d9frkbjbc2fs73bq2ncg-a" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"ipAllowList\": [{\"cidrBlock\": \"175.157.115.71/32\", \"description\": \"local dev\"}]}"

# Fix the admin user
render psql nomnom-db --command "UPDATE users SET email_verified_at = NOW() WHERE email = 'admin@nomnom.lk' AND email_verified_at IS NULL;" --output text
# → UPDATE 1

# Remove our IP
curl -s -X PATCH "https://api.render.com/v1/postgres/dpg-d9frkbjbc2fs73bq2ncg-a" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"ipAllowList": []}'
```

## 10. Final Verification

```bash
# Admin login → SUCCESS
curl -X POST https://nomnom-backend-7iq0.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@nomnom.lk","password":"Admin@123"}'
# → {"access_token":"eyJ...","user":{"role":"admin","name":"Admin"}}
```

## 11. Deploy Admin Dashboard

```bash
# Next.js compiles rewrites at build time, so include the backend target.
docker build \
  --build-arg NEXT_PUBLIC_API_URL=/api/v1 \
  --build-arg API_PROXY_TARGET=https://nomnom-backend-7iq0.onrender.com \
  -t namal97/nomnom-admin:latest admin

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

Created: `srv-d9ft1t8okrbs738q9f60`

URL: `https://nomnom-admin-e41y.onrender.com`

Update backend CORS and deploy the environment change:

```bash
curl -X PUT \
  "https://api.render.com/v1/services/srv-d9frkhgk1i2s73be0j50/env-vars/CORS_ORIGINS" \
  -H "Authorization: Bearer ${RENDER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"value":"https://nomnom-admin-e41y.onrender.com"}'

render deploys create srv-d9frkhgk1i2s73be0j50 --confirm
```

Verify the hosted frontend and same-origin proxy:

```bash
curl -I https://nomnom-admin-e41y.onrender.com/login
curl https://nomnom-admin-e41y.onrender.com/api/v1/restaurants
```

## Useful Render CLI Commands

```bash
# List services
render services --output json

# View logs
render logs nomnom-backend

# Open psql session
render psql nomnom-db

# Run SQL command
render psql nomnom-db --command "SELECT * FROM users;" --output text

# Restart service
render restart nomnom-backend

# List deploys
render deploys nomnom-backend
```
