# NomNom LK — Project Context

## App Description
Sri Lanka-focused food offers discovery app (Flutter). Surfaces discounted food items from local Sri Lankan restaurants.

## Tech Stack
- **Frontend:** Flutter + Provider + SharedPreferences
- **Backend:** Go + Gin + GORM + PostgreSQL 16 + Redis 7
- **Auth:** Firebase Auth (Google OAuth + email/password) + custom JWT
- **Storage:** S3-compatible (MinIO for dev)
- **Push:** Firebase Cloud Messaging
- **Admin Dashboard:** Next.js 14 + Tailwind + shadcn/ui
- **Deployment:** Railway (Docker)
- **Error Monitoring:** Sentry
- **API Docs:** Swagger/OpenAPI 3.0

## Build Order
```
P1: Foundation      → Go project, GORM models, config, DB/Redis, Docker, Makefile
P2: Auth            → Firebase, JWT, auth endpoints, middleware, rate limiting
P3: Core CRUD       → Restaurants, Offers, Favorites, approval workflow, localization
P4: Search          → PostgreSQL full-text search, filters, sort, nearby
P5: Upload          → S3/MinIO upload endpoint
P6: Notifications   → FCM, device tokens, cron jobs
P7: Admin Dashboard → Next.js app
P8: Flutter Integ.  → Update Flutter app to use real API
P9: Testing         → Handler/service/repo tests, Swagger docs
P10: Deploy         → Railway setup, seed data
```

## Key Decisions
- **Go + Gin** framework
- **GORM** ORM (your choice)
- **Firebase Auth** for Google OAuth + email/password
- **Standard struct-based DI** — repos → services → handlers
- **Rate limiting:** 20 req/min auth, 60 req/min general (Redis sliding window)
- **Image upload:** originals only (no server-side resize)
- **Localization:** JSONB `translations` columns on offers/restaurants
- **Approval workflow:** restaurant_owner submits → admin approves/rejects
- **PostgreSQL full-text search** (tsvector + GIN index)
- **Nearby:** haversine formula in SQL (no PostGIS for MVP)

## Roles
- `user` — browse, favorite, manage profile
- `restaurant_owner` — manage own restaurant + offers (pending approval)
- `admin` — approve/reject, manage users, stats, send notifications

## Flutter Models — Field Mapping

### Offer (current → API)
| Current Field | API Field | Notes |
|---|---|---|
| `id` | `id` | |
| `restaurantName` | `restaurant.name` | Nested object |
| `foodName` | `title` | Renamed |
| `description` | `description` | |
| `originalPrice` | `original_price` | |
| `offerPrice` | `offer_price` | |
| `discountLabel` | `discount_percent` | Computed by DB |
| `imageUrl` (single) | `image_urls` (array) | Was single string, now array |
| `location` | `restaurant.address` | Moved to nested |
| `isFavorite` | `is_favorited` | From /favorites |
| *(missing)* | `end_date` | New required field |
| *(missing)* | `restaurant.id` | For linking |
| *(missing)* | `restaurant.slug` | For URLs |

### AppUser (current → API)
| Current | API | Notes |
|---|---|---|
| `id` | `id` | |
| `name` | `name` | |
| `email` | `email` | |
| `isLoggedIn` | `role != null` | Inferred |
| `isGuest` | `role == null` | Local only |

## Go Project Structure
```
backend/
├── cmd/server/main.go
├── internal/
│   ├── config/config.go
│   ├── database/{postgres,redis}.go
│   ├── models/{user,restaurant,offer,favorite,notification,device_token}.go
│   ├── repository/{user,restaurant,offer,favorite,notification,device}_repo.go
│   ├── services/{auth,user,restaurant,offer,favorite,search,upload,notification,admin}.go
│   ├── handlers/{auth,user,restaurant,offer,favorite,search,upload,notification,admin}.go
│   ├── middleware/{auth,role,ratelimit,localization,cors,logger,recovery,request_id}.go
│   ├── dto/request/{auth,offer,restaurant,search,favorite,notification}_request.go
│   ├── dto/response/{auth,offer,restaurant,pagination,error}.go
│   └── router/router.go
├── pkg/{jwt,hash,locale,pagination,response}/*.go
├── migrations/*.sql
├── scripts/{seed,migrate}.go
├── docs/swagger/
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── go.mod / go.sum
└── Makefile
```

## Current Status
- Build in progress
- Always ask before moving to next phase
