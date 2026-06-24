## Session Context Protocol
- This file must be updated at the end of every completed phase before committing.
- After updating, commit this file with the phase commit message (e.g., `feat: P3 Core CRUD ...`).
- When resuming work, read this file first to restore full context — then delete this section.

## Goal
- Build a Go backend for NomNom LK, a Sri Lanka-focused food offers discovery app (Flutter frontend exists, currently mock-data-only).

## Constraints & Preferences
- **Stack:** Go + Gin + GORM + PostgreSQL 16 + Redis 7 + Firebase Auth + JWT + Sentry + Docker/Railway.
- **Build order & sign-off:** Phase-by-phase; each phase completed, tested, committed, and merged to master via feature branches before next phase starts.
- **Git workflow:** Feature branches per phase (`phase/N-name`), merge to master after completion, branches preserved.
- **Architecture:** Standard struct-based DI; roles (user, restaurant_owner, admin); approval workflow (owner submits → admin approves); localization via JSONB translations; PostgreSQL full-text search; upload originals only; rate limiting (20 auth, 60 general, 10 upload).
- **Documentation:** OpenAPI 3.0 YAML spec, DB schema, Flutter integration guide, README, architecture doc — all saved before build.

## Progress
### Done
- **P1: Foundation** — Go project init, config (viper), GORM models (User, Restaurant, Offer, Favorite, Notification, DeviceToken, RefreshToken), Postgres/Redis connections, AutoMigrate, 8 middleware (Auth, CORS, Logger, Recovery, RequestID, Role, RateLimit, Localization), JWT + bcrypt + pagination + response utils, Docker Compose (Postgres 16 + Redis 7 + MinIO), Dockerfile (multi-stage), Makefile, 12 migration SQL files, seed script, all 5 documentation files saved.
- **P2: Auth** — Auth service (register, login, firebase, refresh, logout), user repo, refresh token repo with rotation, auth handler, routes wired in router, rate limiting on auth routes (20/min). Handlers stubbed for Firebase token verification (mock claims until Firebase SDK connected).
- **P3: Core CRUD** — Repos (restaurant, offer, favorite), services (restaurant, offer, favorite), handlers (restaurant, offer, favorite), DTOs (all request types), locale pkg. Routes: full CRUD + approve/reject for restaurants/offers, add/remove/list for favorites. Built on `phase/3-core-crud`, merged to master.
- **P4: Search** — Search service with PostgreSQL full-text search (tsvector + GIN index on offers), restaurant ILIKE search, cuisine tag filter, nearby haversine filter, sort (newest/oldest/discount/price_low/price_high/nearest), pagination. `GET /api/v1/search` with `q`, `type`, `lat`, `lng`, `radius_km`, `cuisine`, `sort` params. Built on `phase/4-search`, merged to master.
- **P5: Upload** — Upload service using minio-go (S3-compatible, MinIO for dev). Single and multi-file upload with validation (5MB max, image types only). `POST /api/v1/upload` and `POST /api/v1/upload/multiple`. Auto-creates bucket. Returns URL paths. Built on `phase/5-upload`, merged to master.
- **P6: Notifications** — Device token repo + notification repo. Notification service with Firebase Admin SDK FCM integration (graceful fallback if credentials missing). Device register/unregister. List notifications, mark read, unread count. Admin push to all or specific user. Cron service: marks expired offers, notifies users of offers expiring within 24h. Cron runs every 15 min via goroutine in main.go. Routes: `POST/DELETE /devices`, `GET /notifications`, `PUT /notifications/:id/read`, `PUT /notifications/read-all`, `GET /notifications/unread-count`, `POST /admin/notifications/push`. Built on `phase/6-notifications`, merged to master.

### Blocked
- (none)

## Key Decisions
- Feature branches `phase/3-core-crud`, `phase/4-search`, `phase/5-upload`, `phase/6-notifications` all created and merged to master.
- GitHub remote: `https://github.com/NamalTharindu97/nomnom-lk`
- Firebase Admin SDK (`firebase.google.com/go/v4`) installed for FCM push notifications.
- Cron runs inline goroutine in main.go (15-min ticker); can be extracted to standalone scheduler later.
- Firebase token verification still mocked (real Firebase Auth SDK init deferred).
- Upload uses minio-go v7 (works with both MinIO and AWS S3).

## Next Steps
**P7: Admin Dashboard** — Next.js 14 + Tailwind + shadcn/ui frontend for admin operations.
