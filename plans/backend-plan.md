# Backend Plan

## P10 — Backend Foundation Fixes
- `/users/me` endpoint
- Firebase Admin SDK integration
- Upload serving
- SSE (Server-Sent Events)
- Translation merging
- Merged to master

## P15 — Real-Time Sync via SSE
- Backend `status=all` support in `offer_repo.go` and `restaurant_repo.go`
- `status` field added to `offerToMap` response
- SSE header flush fix: `c.Writer.WriteHeader(http.StatusOK)` + `c.Writer.Flush()` before `c.Stream()`
- Gin SSE encoder writes `event:eventName` and `data:{json}` (no space after colon)
- Backend emits `offer.*` and `restaurant.*` events on all CRUD operations

## P17 — Seed Data with MinIO Images
- Seed script with MinIO image upload (26 images, UUIDs matching DB records)
- 8 restaurants + 18 offers created
- Translation fields flattened in API responses (`FlattenTranslations`)
- `offerToMap` includes `restaurant_id`, `start_date`, `translations`
- `contact_phone` field fix in restaurant dialog
- Pagination metadata (total/total_pages)

## P20 — Robustness Fixes (Backend)
- `sendFCMNotifications` deletes stale device tokens on `NotRegistered`/`Unregistered` FCM errors
- `POST /admin/notifications/push` rate-limited to 1 per 10s per admin user via in-memory `rateLimiter`
- Backend `SendPush` returns error when `len(tokens) == 0` instead of silent nil

## Performance Phase 3 — Backend Indexes
- Composite index `idx_offers_status_created ON offers(status, created_at DESC)` — covers main listing query
- Partial index `idx_offers_end_date ON offers(end_date) WHERE status = 'approved'` — covers expiry queries
- Preload restricted to `id, name, slug, address` — 4 fields instead of ~15, reduces DB→Go data transfer
- Indexes created via `runIndexMigrations()` in `postgres.go`

## Search
- Backend offer search via `search_vector @@ to_tsquery` with `:*` prefix matching
- Backend restaurant search via `name ILIKE`

## FCM Backend
- Backend FCM via direct HTTP to `https://fcm.googleapis.com/v1/projects/nomnom-cfe32/messages:send` using `cloud-platform` OAuth2 scope
- No Firebase Admin SDK dependency
- Android channel config (`nomnom_notifications`, `high` priority)
- Stale token deletion on `UNREGISTERED`

## Future
- Cache interceptor LRU eviction (prevent unbounded memory)
- MinIO presigned URLs for image serving
- Redis caching of offer list (30s TTL)
