# Contabo VPS Deployment Plan

## Goal

Migrate NomNom LK from Render.com free tier to a self-managed Contabo VPS
with Caddy reverse proxy, Docker Compose orchestration, encrypted backups,
and GitHub Actions CI/CD.

## Pre-Purchase (Phase 0)

### Domain
- Purchase `nomnom.lk` from `.lk` registry or reseller
- Subdomains: `api.nomnom.lk`, `admin.nomnom.lk`

### VPS
- Contabo Cloud VPS S: 4 vCPU, 8 GB RAM, 200 GB SSD (~$5.50/mo)
- Region: Singapore
- OS: Ubuntu 24.04 LTS

### Initial VPS Setup
- SSH key-only (disable password auth)
- Tailscale for admin access (no open SSH port)
- UFW: allow 80/tcp, 443/tcp, 443/udp only
- Unattended security updates enabled

### DNS
- `api.nomnom.lk` → VPS public IP
- `admin.nomnom.lk` → VPS public IP
- Low TTL (300s) for migration flexibility

---

## Phase 1: Infrastructure

### Docker
- Docker Engine from official repo
- `docker compose` plugin
- Daemon: `live-restore: true`, log rotation

### `/etc/nomnom/` Layout
```
/etc/nomnom/
  compose/       → compose.yml
  config/        → Caddyfile, redis.conf
  secrets/       → 0700 dirs, 0400 files per service
  secrets.previous/
```

### Containers
- Pin all images by immutable digest (not `:latest`)
- Caddy 2, PostgreSQL 16-alpine, Redis 7-alpine
- Our backend/admin images tagged with Git SHA from CI

### PostgreSQL
- TLS cert for intra-Docker connections
- Cert + key outside Git, restricted to postgres UID
- DB user + database via init scripts

### Redis
- ACL file from password (no plaintext in config)
- ACL file mounted as Docker secret

### Caddy
- Let's Encrypt for `api.nomnom.lk` + `admin.nomnom.lk`
- TLS 1.3, HTTP → HTTPS redirect
- HSTS, CSP, X-Frame-Options, Referrer-Policy headers

---

## Phase 2: Application

### Backend
- `_FILE` suffixed env vars → Docker secrets
- 8 secrets: DB password, Redis password, JWT secret, Firebase creds, R2 keys, SMTP password, admin bootstrap password
- Health check: `/health`
- Log to stdout only

### Admin
- Proxy target: `http://backend:8080` (internal)
- `NEXT_PUBLIC_API_URL=/api/v1` (same-origin via Caddy)
- Read-only FS except `/tmp` + Next.js cache

### Verify
- `https://api.nomnom.lk/health` → 200
- `https://admin.nomnom.lk/login` → 200
- Firebase login, SSE, FCM push, R2 upload all work

---

## Phase 3: Secret Delivery

### GitHub Actions
- `deploy-vps-secrets.yml` streams secrets via SSH to `install-secrets.sh`
- Production environment protected with manual approval
- PR/fork workflows cannot access production secrets

### install-secrets.sh
- Writes secrets atomically to `/etc/nomnom/secrets/`
- Permissions: 0600 (private), 0400 (read-only)
- Validates non-empty, triggers `docker compose restart`

---

## Phase 4: Data Migration (Render → Contabo)

### Pre-migration
- Count all entities on Render: restaurants, offers, users, favorites, notifications
- Record sample data for verification

### PostgreSQL
- Initial dump: `pg_dump` from Render → restore to Contabo
- Stop Render backend, final data-only dump
- Verify all row counts match

### Redis
- No persistent data migration needed (ephemeral: sessions, rate limits, codes)
- Verify Redis healthy on Contabo

### R2
- No migration (stays on Cloudflare, same bucket)
- Verify images load in app + admin

### Post-migration
- Admin login, dashboard loads, counts match
- Flutter app: browse, search, favorites, notifications all work
- Push notification test
- Keep Render as fallback for 48h

---

## Phase 5: CI/CD Pipeline

### CD Workflows
- `deploy-staging.yml`: Build + Trivy → push SHA-tagged images → SSH → `docker compose up -d` on staging VPS
- `promote-production.yml`: Staging SHA → production env approval → promote to production VPS

### Container Updates
- Staging deploys on every push to `staging` branch
- Production uses immutable SHA tags
- Rollback: `docker compose up -d` with previous SHA

### Render Cutover
- Point DNS to Contabo VPS IP
- Wait for DNS propagation
- Disable Render auto-deploy
- Keep Render as cold standby 1 week
- Delete Render resources after confirmation

---

## Phase 6: Backups & Monitoring

### Encrypted Backups
- `pg_dump` → age encrypt → upload to R2 backup bucket
- Systemd timer: daily at 3 AM
- Retention: 7 daily, 4 weekly, 3 monthly
- Restore via `restore-vps-production.yml` (manual approval)

### Monitoring
- Docker health checks on all services
- Caddy access logs
- Backend structured JSON to stdout
- Optional: Uptime Robot on `/health`

### Alerts
- `restart: unless-stopped` on all containers
- Caddy auto-renew TLS (built-in)
- Log rotation for disk space

---

## Phase 7: Cleanup

- Delete Render PostgreSQL, Redis, backend, admin services
- Remove Render-specific build args from admin Dockerfile
- Update `render.yaml` with migration note
- Document: SSH access, Tailscale, secret locations, restore procedure
- Update Firebase authorized domains for `api.nomnom.lk`, `admin.nomnom.lk`

---

## Prerequisites Checklist

- [ ] `nomnom.lk` domain purchased
- [ ] Contabo VPS purchased (Singapore, Ubuntu 24.04)
- [ ] SSH key pair generated
- [ ] Tailscale account configured
- [ ] GitHub production environment with all secrets
- [ ] R2 backup bucket + separate credentials created
- [ ] Phase 0 provider rotations completed
