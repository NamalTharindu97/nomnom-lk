# NomNom LK — Architecture Overview

## System Architecture

```
                         ┌──────────────┐
                         │  Admin UI     │
                         │  (Next.js)    │
                         └──────┬───────┘
                                │
┌─────────┐              ┌──────┴───────┐
│ Flutter  │─────────────│   Go API     │
│ App      │  HTTPS/REST │   (Gin)      │
└─────────┘              └──────┬───────┘
                                │
            ┌───────────────────┼───────────────────┐
            │                   │                   │
     ┌──────┴──────┐    ┌──────┴──────┐    ┌───────┴──────┐
      │ PostgreSQL  │    │   Redis     │    │   MinIO /   │
      │  (Primary   │    │  (Cache,    │    │  Cloud R2   │
      │   Data)     │    │   Rate Lim) │    │  (Images)   │
     └─────────────┘    └─────────────┘    └──────────────┘
```

## Design Decisions

### API-First
- RESTful API with JSON request/response
- Versioned via URL prefix (`/api/v1/`)
- Swagger/OpenAPI 3.0 documentation
- All endpoints return consistent JSON envelope

### Authentication
- Firebase Auth for Google Sign-In (reduces OAuth complexity)
- Short-lived JWT access tokens (15 min) for API auth
- Long-lived refresh tokens (30 days) with rotation
- Flutter stores tokens in platform secure storage (Keychain/EncryptedSharedPreferences)

### Role-Based Access Control
Three roles with escalating permissions:
| Role | Permissions |
|---|---|
| `user` | Browse offers, save favorites, manage own profile |
| `restaurant_owner` | User + manage own restaurant + create offers (pending approval) |
| `admin` | Everything: approve/reject, manage users, send notifications, stats |

### Approval Workflow
Restaurant owners submit offers -> status=`pending` -> admin approves/rejects
-> On approval: offer becomes visible to users + push notification sent to owner

### Localization
Multi-language support via JSONB `translations` column:
```json
{"title": {"si": "කුකුල් කොත්තු", "ta": "சிக்கன் கொத்து"}}
```
Client sends `Accept-Language` header -> backend merges translations into response.

### Search
PostgreSQL full-text search using `tsvector` + GIN index:
- Searches across offer titles and descriptions
- Ranked results via `ts_rank()`
- Filters: cuisine, price, discount, location
- Sort: popularity, newest, price, distance
- Nearby via haversine formula

### Notifications
Push notifications via Firebase Cloud Messaging:
- Triggers: offer approved/rejected, restaurant approved, offer expiring soon
- Background cron jobs for expiry checks and cleanup
- Notification history stored in DB, exposed via API

### Caching Strategy
| Cache | Key | TTL | Invalidated |
|---|---|---|---|
| Popular offers | `cache:offers:popular` | 5 min | On new offer creation |
| Restaurant detail | `cache:restaurant:{id}` | 10 min | On restaurant update |
| User session | `session:{user_id}` | 15 min | On logout/token refresh |

## Data Flow Examples

### Browsing Offers (User)
```
1. Flutter sends GET /api/v1/offers?q=kottu&page=1
2. Middleware: parse lang header, check rate limit
3. Handler: extract query params -> call SearchService
4. SearchService: build GORM query with tsvector full-text search
5. Repository: execute SQL with filters, pagination, ranking
6. Response: merge translations based on lang, add is_favorited flag
7. Flutter: parse JSON -> display OfferCards
```

### Creating an Offer (Restaurant Owner)
```
1. Flutter sends POST /api/v1/offers { restaurant_id, title, ... }
2. Middleware: verify JWT, check role=restaurant_owner|admin
3. Handler: parse body, validate -> call OfferService.Create
4. OfferService: set created_by=user_id, status=pending
5. Repository: INSERT into offers table
6. Response: return created offer with status=pending
7. Owner sees: "Pending approval" badge
```

### Approving an Offer (Admin)
```
1. Admin dashboard sends PUT /api/v1/offers/:id/approve
2. Middleware: verify JWT, check role=admin
3. Handler: call OfferService.Approve
4. OfferService: UPDATE status='approved'
5. NotificationService: create notification + send FCM to owner
6. Response: { id, status: "approved" }
7. Owner gets push: "Your offer is now live!"
```

## Monitoring & Observability

### Sentry (Error Tracking)
- Captures all panics and 500 errors
- Includes request_id, user_id, route, params
- Source maps for stack traces

### Logging (zerolog)
- Structured JSON logs
- Every request: method, path, status, duration, request_id
- Errors include full context (request body, user, etc.)

### Health Check
`GET /health` returns:
```json
{
  "status": "ok",
  "version": "1.0.0",
  "uptime": 12345,
  "database": "connected",
  "redis": "connected",
   "storage": "connected"
}
```

## Security

| Concern | Mitigation |
|---|---|
| Auth | JWT with short expiry + refresh rotation |
| Rate limiting | Redis sliding window (20/min auth, 60/min general) |
| SQL injection | GORM parameterized queries + validation |
| XSS | JSON response (no HTML rendering) |
| CORS | Whitelist specific origins |
| File upload | Validate type/size, UUID filenames |
| Secrets | Environment variables via viper |
