# Contabo VPS Deployment Plan (Staging-First)

## Goal

Deploy NomNom LK to a Contabo VPS as a staging environment first (no domain
required), then later add the domain and go production.

## Why Staging-First

- No domain purchase needed upfront — use VPS IP directly
- Test everything on real infrastructure before production
- Fix issues in staging while Render keeps running
- Add domain and TLS later as a single cutover step

---

## Phase A: Purchase & Configure VPS

### A.1 — Buy VPS
- Contabo Cloud VPS S: 4 vCPU, 8 GB RAM, 200 GB SSD (~$5.50/mo)
- Region: Singapore
- OS: Ubuntu 24.04 LTS
- No domain needed — use public IP

### A.2 — Initial Setup
- SSH key-only (disable password auth)
- UFW: allow 22/tcp, 8080/tcp, 3000/tcp
- Unattended security updates
- Install Docker Engine + `docker compose` plugin

### A.3 — Server Layout
```
/etc/nomnom/
  compose/       → compose.yml
  config/        → redis.conf
  secrets/       → 0700 dirs, 0400 files
  secrets.previous/
```

---

## Phase B: Simplified Compose (Staging — No Caddy)

Since we don't have a domain, remove Caddy and expose backend/admin ports directly.
Simpler compose for staging:

```
Services:
  backend   → port 8080 exposed
  admin     → port 3000 exposed  
  postgres  → internal only
  redis     → internal only
```

### B.1 — Access URLs
- Backend: `http://<VPS-IP>:8080/health`
- Admin: `http://<VPS-IP>:3000/login`

### B.2 — Deploy
- Copy compose + config files to VPS
- Run `install-secrets.sh` to set up secrets
- `docker compose up -d`
- Verify both services are healthy

### B.3 — Staging Differences from Production
| Aspect | Staging (No Domain) | Production (With Domain) |
|--------|--------------------|--------------------------|
| Access | `http://<IP>:8080`, `http://<IP>:3000` | `https://api.nomnom.lk`, `https://admin.nomnom.lk` |
| Proxy | None (direct ports) | Caddy (TLS + reverse proxy) |
| TLS | None | Let's Encrypt via Caddy |
| Ports | 22, 8080, 3000 | 80, 443 only |
| Networks | Single internal | edge, app, data, egress |
| Security | Basic (UFW + SSH key) | Full (read-only FS, cap drop) |

---

## Phase C: CI/CD Pipeline

### C.1 — GitHub Actions
- `deploy-vps-secrets.yml`: Streams production secrets to VPS via SSH
- `deploy-staging.yml`: Build Docker images, push to Docker Hub, SSH → VPS → `docker compose up -d`
- `promote-production.yml`: Staging SHA → production env approval → deploy to production VPS

### C.2 — Workflow
```
Push to staging → CI builds images → pushes to Docker Hub → SSH to VPS → pulls images → docker compose up -d
```

### C.3 — Rollback
```
docker compose up -d --no-build --pull always BACKEND_IMAGE=<previous-sha> ADMIN_IMAGE=<previous-sha>
```

---

## Phase D: Production Cutover (Add Domain Later)

### D.1 — Purchase Domain
- Buy `nomnom.lk` from `.lk` registry
- Subdomains: `api.nomnom.lk`, `admin.nomnom.lk`

### D.2 — Enable Caddy
- Add Caddy to compose (from `deploy/vps/compose.yml`)
- Caddy auto-requests Let's Encrypt certificates
- Close ports 8080, 3000 — route through Caddy
- TLS 1.3, HSTS, security headers

### D.3 — DNS Cutover
- Point domain DNS to VPS IP
- Update Firebase authorized domains
- Update Flutter app API URL
- Disable Render, keep as cold standby 1 week

### D.4 — Backups & Monitoring
- PostgreSQL daily backups to R2 (age encrypted)
- Uptime Robot on `api.nomnom.lk/health`
- Systemd timer for backup + log rotation

---

## Phase E: Cleanup
- Delete Render services
- Document: SSH access, secrets, restore procedure

---

## Prerequisites Checklist

### For Staging (Buy Now)
- [ ] Contabo VPS S purchased (Singapore, Ubuntu 24.04)
- [ ] SSH key pair generated
- [ ] GitHub production environment with all secrets

### For Production (Buy Later)
- [ ] `nomnom.lk` domain purchased
- [ ] Phase 0 provider rotations completed
- [ ] R2 backup bucket + separate credentials

---

## Current Pre-Built Assets

| Asset | Purpose | Status |
|-------|---------|--------|
| `deploy/vps/compose.yml` | Full prod compose with Caddy | ✅ Ready |
| `deploy/vps/Caddyfile` | Reverse proxy config | ✅ Ready (for prod) |
| `deploy/vps/config/redis.conf` | Redis ACL config | ✅ Ready |
| `scripts/vps/install-secrets.sh` | Secret delivery | ✅ Ready |
| `scripts/vps/deploy.sh` | Docker compose up | ✅ Ready |
| `scripts/vps/backup-postgres.sh` | Encrypted backups | ✅ Ready |
| `scripts/vps/restore-postgres.sh` | Backup restore | ✅ Ready |
| `scripts/vps/package-secrets.sh` | Secret packaging | ✅ Ready |
| `.github/workflows/deploy-vps-secrets.yml` | CI secret delivery | ✅ Ready |
| `.github/workflows/restore-vps-production.yml` | CI restore workflow | ✅ Ready |

## What Needs Creation

| Asset | Purpose |
|-------|---------|
| `deploy/vps/compose.staging.yml` | Simplified compose without Caddy for staging |
| `scripts/vps/deploy-staging.sh` | Deploy script for staging |
