#!/bin/bash
set -e

# Deploy staging application to VPS
# Usage: ./deploy-staging.sh [--restart]

COMPOSE_FILE="compose.staging.yml"
ENV_FILE="compose.staging.env"
COMPOSE_DIR="/etc/nomnom/compose"
ACTION="${1:-up}"

cd "$COMPOSE_DIR"

case "$ACTION" in
  up)
    echo "[deploy-staging] Pulling images..."
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" pull

    echo "[deploy-staging] Starting services..."
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

    echo "[deploy-staging] Waiting for backend..."
    for i in $(seq 1 10); do
      if curl -sf http://localhost:8080/health > /dev/null 2>&1; then
        echo "[deploy-staging] Backend healthy"
        break
      fi
      sleep 3
    done

    echo "[deploy-staging] Waiting for admin..."
    for i in $(seq 1 10); do
      if curl -sf -o /dev/null http://localhost:3000/login 2>&1; then
        echo "[deploy-staging] Admin healthy"
        break
      fi
      sleep 3
    done

    echo "[deploy-staging] Deploy complete"
    ;;

  down)
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down
    ;;

  restart)
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" restart
    ;;

  logs)
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs -f
    ;;

  status)
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps
    ;;

  *)
    echo "Usage: $0 {up|down|restart|logs|status}"
    exit 1
    ;;
esac
