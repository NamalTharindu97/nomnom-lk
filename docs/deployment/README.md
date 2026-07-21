# NomNom LK — Deployment Documentation

## What Was Deployed

Backend API deployed to **Render.com** (Singapore region, free tier).

| Resource | Render Type | Plan | Region |
|----------|-------------|------|--------|
| `nomnom-backend` | Web Service (Docker image) | Free | Singapore |
| `nomnom-db` | PostgreSQL 16 | Free | Singapore |
| `nomnom-redis` | Key Value (Redis 8.1) | Free | Singapore |

**Live URL:** `https://nomnom-backend-7iq0.onrender.com`

## Documentation Index

| File | Description |
|------|-------------|
| [render-setup.md](render-setup.md) | Full setup guide — prerequisites, resource creation, env vars |
| [render-commands.md](render-commands.md) | Every command we ran, in order, with outputs |
| [render-issues.md](render-issues.md) | Bugs encountered and how they were fixed |
| [render-credentials.md](render-credentials.md) | Where credentials live (no secrets, just references) |

## Quick Reference

### Health Check
```bash
curl https://nomnom-backend-7iq0.onrender.com/health
# → {"database":{"status":"connected"},"redis":{"status":"connected"},"status":"ok"}
```

### Admin Login
```bash
curl -X POST https://nomnom-backend-7iq0.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@nomnom.lk","password":"Admin@123"}'
```

### Render Dashboard
- Backend service: https://dashboard.render.com/web/srv-d9frkhgk1i2s73be0j50
- PostgreSQL: https://dashboard.render.com/d/dpg-d9frkbjbc2fs73bq2ncg-a
- Redis: https://dashboard.render.com/keyvalue/red-d9frkeernols73cji320
