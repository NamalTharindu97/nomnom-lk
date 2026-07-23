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

## 4. Configure Runtime Secrets

Connection strings were copied from each Render resource's **Connect** panel
directly into the backend environment. R2, JWT, and bootstrap values were entered
through the Render Dashboard, and Firebase credentials were uploaded through
**Secret Files**. Values and raw connection-info responses are intentionally not
recorded here.

The secret file is mounted on a fresh deploy; a restart alone keeps the old
mounted file. Future automation must use protected GitHub environments and must
not place credentials in command arguments or logs.

## 7. First Deploy & Test

```bash
render deploys create srv-d9frkhgk1i2s73be0j50 --wait

# Health check (after ~1 min)
curl https://nomnom-backend-7iq0.onrender.com/health
# → {"database":{"status":"connected"},"redis":{"status":"connected"},"status":"ok"}

# Admin login test
curl -X POST https://nomnom-backend-7iq0.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  --data-binary @/path/to/private-login-payload.json
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
render deploys create srv-d9frkhgk1i2s73be0j50 --wait
```

## 9. Fix — Existing Admin in Database

The admin was already created by the first deploy (without `email_verified_at`). The bootstrap code only runs when NO admin exists. So we fixed it directly in the DB.

```bash
# Add our IP to the DB allow list
MY_IP=$(curl -s ifconfig.me)
render postgres update dpg-d9frkbjbc2fs73bq2ncg-a \
  --ip-allow-list "cidr=${MY_IP}/32,description=temporary-maintenance" \
  --confirm

# Fix the admin user
render psql nomnom-db --command "UPDATE users SET email_verified_at = NOW() WHERE email = 'admin@nomnom.lk' AND email_verified_at IS NULL;" --output text
# → UPDATE 1

# The temporary operator IP was removed through the PostgreSQL Render Dashboard.
# The allow list was verified empty before the maintenance session ended.
```

## 10. Final Verification

```bash
# Admin login → SUCCESS
curl -X POST https://nomnom-backend-7iq0.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  --data-binary @/path/to/private-login-payload.json
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

Update `CORS_ORIGINS` directly in the backend service's Render Environment page,
then deploy the environment change with:

```bash
render deploys create srv-d9frkhgk1i2s73be0j50 --wait
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
