.PHONY: run build test lint migrate seed swagger docker clean

APP_NAME = nomnom-api

run:
	@echo "Starting server..."
	go run ./cmd/server/main.go

build:
	@echo "Building binary..."
	go build -ldflags="-s -w" -o bin/$(APP_NAME) ./cmd/server/main.go

test:
	@echo "Running tests..."
	go test ./... -v -count=1 -race 2>&1 | grep -v 'no test files'

test-coverage:
	@echo "Running tests with coverage..."
	go test ./... -count=1 -race -coverprofile=coverage.out 2>&1 | grep -v 'no test files'
	go tool cover -html=coverage.out -o coverage.html

test-integration:
	@echo "Running integration tests..."
	@echo "Ensure Docker services are running: docker compose up -d postgres redis minio"
	go test -tags=integration ./internal/handlers/... -v -count=1

test-all: test test-integration

lint:
	@echo "Running linter..."
	golangci-lint run ./...

migrate-up:
	@echo "Running migrations up..."
	go run -tags=migration ./scripts/migrate.go up

migrate-down:
	@echo "Running migrations down..."
	go run -tags=migration ./scripts/migrate.go down

seed:
	@echo "Seeding database..."
	go run -tags=seed ./scripts/seed.go

swagger:
	@echo "Generating Swagger docs..."
	swag init -g cmd/server/main.go -o docs/swagger

docker:
	@echo "Building Docker image..."
	docker build -t $(APP_NAME) .

docker-run:
	@echo "Starting Docker Compose..."
	docker compose up -d --build

docker-stop:
	@echo "Stopping Docker Compose..."
	docker compose down

docker-logs:
	docker compose logs -f

clean:
	@echo "Cleaning..."
	rm -rf bin/ coverage.out coverage.html

tidy:
	@echo "Tidying modules..."
	go mod tidy
	go mod verify

all: tidy build test
