.PHONY: run build test seed migrate swagger lint clean infra infra-down deploy-up deploy-down deploy-logs

# ── Local Development ──────────────────────────────────────────

run:
	@echo "Starting backend with Air (hot reload)..."
	air

build:
	go build -o tmp/nomnom-api ./cmd/server

test:
	go test ./internal/... -v -count=1

test-integration:
	go test -tags=integration ./internal/handlers/... -v -count=1 -timeout 120s

seed:
	go run -tags=seed ./scripts/seed.go

migrate:
	go run -tags=migration ./scripts/migrate.go up

swagger:
	swag init -g ./cmd/server/main.go -o ./docs/swagger

lint:
	golangci-lint run ./...

# ── Docker Infrastructure ──────────────────────────────────────

infra:
	docker compose up -d

infra-down:
	docker compose down

infra-logs:
	docker compose logs -f

infra-clean:
	docker compose down -v
	docker system prune -f

# ── Full-Stack Deploy (pre-built Docker Hub images) ────────────

deploy-pull:
	docker compose -f docker-compose.deploy.yml pull

deploy-up: deploy-pull
	docker compose -f docker-compose.deploy.yml up -d

deploy-down:
	docker compose -f docker-compose.deploy.yml down

deploy-logs:
	docker compose -f docker-compose.deploy.yml logs -f

deploy-rebuild:
	docker compose -f docker-compose.deploy.yml up -d --build

# ── Docker Image Build ─────────────────────────────────────────

docker-backend:
	docker build -t namal97/nomnom-backend:latest -t namal97/nomnom-backend:local ./backend

docker-admin:
	docker build \
		--build-arg NEXT_PUBLIC_API_URL=/api/v1 \
		-t namal97/nomnom-admin:latest \
		-t namal97/nomnom-admin:local \
		./admin

docker-all: docker-backend docker-admin
