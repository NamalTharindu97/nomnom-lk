# NomNom LK — Backend API

Go REST API for the Sri Lanka-focused food offers discovery app.

## Tech Stack

- **Language:** Go 1.22+
- **Framework:** Gin
- **ORM:** GORM
- **Database:** PostgreSQL 16
- **Cache:** Redis 7
- **Auth:** Firebase Auth + JWT
- **Storage:** S3-compatible (MinIO for dev, Cloudflare R2 for production)
- **Push:** Firebase Cloud Messaging
- **Docs:** Swagger/OpenAPI

## Quick Start

### Prerequisites

- Go 1.22+
- Docker & Docker Compose
- Firebase project (for Google Sign-In)

### Setup

```bash
# Clone and enter backend directory
cd backend

# Copy environment config
cp .env.example .env
# Edit .env with your Firebase credentials, JWT secret, etc.

# Start dependencies (Postgres, Redis, MinIO)
docker compose up -d

# Run database migrations
make migrate

# Seed sample data
make seed

# Start the server
make run
```

Server starts at `http://localhost:8080`. Swagger docs at `http://localhost:8080/swagger/index.html`.

### Makefile Commands

```bash
make run        # Start the API server
make build      # Build binary
make test       # Run all tests
make lint       # Run golangci-lint
make migrate    # Run database migrations
make seed       # Seed sample data
make swagger    # Regenerate Swagger docs
make docker     # Build Docker image
```

## Project Structure

```
backend/
├── cmd/server/          Entry point
├── internal/
│   ├── config/          Environment config
│   ├── database/        DB connections
│   ├── models/          GORM models
│   ├── repository/      Database access
│   ├── services/        Business logic
│   ├── handlers/        HTTP handlers
│   ├── middleware/       Auth, CORS, rate limit, etc.
│   ├── dto/             Request/response types
│   └── router/          Route definitions
├── pkg/                 Shared utilities
├── migrations/          SQL migration files
├── scripts/             Seed and migration scripts
├── docs/swagger/        API documentation
├── Dockerfile
└── docker-compose.yml
```

## API Overview

| Group       | Base Path              | Auth Required |
|-------------|------------------------|---------------|
| Auth        | `/api/v1/auth/*`       | Mixed         |
| Users       | `/api/v1/users/*`      | Yes           |
| Restaurants | `/api/v1/restaurants/*`| Mixed         |
| Offers      | `/api/v1/offers/*`     | Mixed         |
| Favorites   | `/api/v1/favorites/*`  | Yes           |
| Search      | `/api/v1/search`       | No            |
| Upload      | `/api/v1/upload`       | Yes           |
| Notifications| `/api/v1/notifications/*`| Yes         |
| Devices     | `/api/v1/devices/*`    | Yes           |
| Admin       | `/api/v1/admin/*`      | Admin only    |

Full documentation: `http://localhost:8080/swagger/index.html`

## Authentication

1. **Email/Password:** `POST /api/v1/auth/register` or `/auth/login`
2. **Google Sign-In:** Flutter signs in via Firebase SDK, sends ID token to `POST /api/v1/auth/firebase`
3. Backend returns `{ access_token, refresh_token, user }`
4. Include `Authorization: Bearer <access_token>` in subsequent requests
5. Auto-refresh: `POST /api/v1/auth/refresh` with refresh_token

## Deployment (Render.com)

This project deploys to Render.com using prebuilt Docker images from Docker Hub.
CI automatically builds & pushes images on master push.

### Services on Render

| Service | Type | Plan |
|---------|------|------|
| `nomnom-backend` | Web Service (prebuilt image) | Free |
| `nomnom-admin` | Web Service (prebuilt image) | Free |
| `nomnom-db` | Managed PostgreSQL | Free (30-day expiry) |
| `nomnom-redis` | Managed Redis KV | Free (in-memory only) |

### External Storage (Cloudflare R2)

Image uploads use Cloudflare R2 (S3-compatible, 10GB free tier).
Set these env vars on the backend service:

- `R2_ENDPOINT` — your R2 bucket endpoint URL
- `R2_ACCESS_KEY_ID` — R2 API token ID
- `R2_SECRET_ACCESS_KEY` — R2 API token secret
- `R2_REGION=auto`
- `R2_BUCKET=nomnom-images`

### First-time Deploy

```bash
# 1. Push to master (CI builds & pushes Docker images)
git push origin master

# 2. Connect repo in Render Dashboard → New → Blueprint
#    Select render.yaml from the repo

# 3. Set sync:false env vars in Render Dashboard:
#    - R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY
#    - R2_ENDPOINT, ADMIN_PASSWORD
#    - JWT_SECRET (optional — auto-generated)
#    - FIREBASE_CREDENTIALS_PATH secret file
```

### Local Deploy Test

```bash
# Pull and run prebuilt Docker images
make deploy-up

# Tail logs
make deploy-logs

# Stop
make deploy-down
```

## Testing

```bash
make test                    # Unit + integration tests
go test ./... -v             # Verbose test output
go test ./... -coverprofile=coverage.out
go tool cover -html=coverage.out  # HTML coverage report
```
