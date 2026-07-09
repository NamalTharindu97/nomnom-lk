# NomNom LK

[![CI](https://github.com/NamalTharindu97/nomnom-lk/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/NamalTharindu97/nomnom-lk/actions/workflows/test.yml)

NomNom LK is a full-stack Sri Lankan food offers discovery platform. Users browse, search, and save deals from restaurants across Sri Lanka. Restaurant owners manage their own offers; admins oversee the platform.

## Tech Stack

| Layer | Stack |
|-------|-------|
| **Frontend** | Flutter + Dio + Provider + firebase_messaging |
| **Admin** | Next.js 16 + Tailwind v4 + shadcn/ui + react-hook-form + Zod |
| **Backend** | Go + Gin + GORM + PostgreSQL 16 + Redis 7 |
| **Auth** | Firebase Auth + JWT |
| **Storage** | MinIO (dev) / Cloudflare R2 (prod) |
| **MCP/SSE** | Real-time offer sync via Server-Sent Events |
| **Infra** | Docker + Render Blueprint |

## Architecture

- `backend/` — Go API server (Gin + GORM), `make run` with Air hot reload
- `admin/` — Next.js dashboard for admins & restaurant owners
- `lib/` — Flutter mobile app (Android + iOS)
- `plans/` — Detailed phase plans for feature work

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for full architecture documentation.

## Quick Start

```bash
# Infrastructure (PostgreSQL 16, Redis 7, MinIO)
cd backend && docker compose up -d

# Backend (hot reload)
cd backend && make run

# Admin dashboard
cd admin && npm run dev

# Flutter app
flutter run
```

Default admin login: `admin@nomnom.lk` / `Admin@123`

## CI/CD

GitHub Actions runs on every push/PR:
- Backend: `go build`, `go test -coverprofile`, `golangci-lint`, `govulncheck`
- Admin: `next build`, `npm run lint`, `tsc --noEmit`, `npm audit`
- E2E: 48 Playwright tests against admin dashboard
- Security: Gitleaks secret scan, Trivy container scan
- Coverage: Codecov upload (Go + Vitest)
