#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=/etc/nomnom-recruiter
COMPOSE_DIR=$ROOT/compose
COMPOSE_FILE=$COMPOSE_DIR/compose.recruiter.yml
ENV_FILE=$COMPOSE_DIR/compose.recruiter.env
DOMAIN=demo.nomnomlk.com
BACKEND_IMAGE=${1:-}
ADMIN_IMAGE=${2:-}

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  printf 'deploy-recruiter must run as root\n' >&2
  exit 1
fi

for image in "$BACKEND_IMAGE" "$ADMIN_IMAGE"; do
  if [[ ! "$image" =~ :[0-9a-f]{40}$ ]]; then
    printf 'Recruiter images must use full 40-character Git SHA tags: %s\n' "$image" >&2
    exit 1
  fi
done

old_backend=$(docker inspect --format '{{.Config.Image}}' nomnom-recruiter-recruiter-backend-1 2>/dev/null || \
  docker inspect --format '{{.Config.Image}}' nomnom-recruiter-backend-1 2>/dev/null || true)
old_admin=$(docker inspect --format '{{.Config.Image}}' nomnom-recruiter-recruiter-admin-1 2>/dev/null || \
  docker inspect --format '{{.Config.Image}}' nomnom-recruiter-admin-1 2>/dev/null || true)
succeeded=false

rollback() {
  local status=$?
  set +e
  if [[ "$succeeded" != true && -n "$old_backend" && -n "$old_admin" ]]; then
    BACKEND_IMAGE="$old_backend" ADMIN_IMAGE="$old_admin" \
      docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d --no-deps recruiter-backend recruiter-admin
  fi
  return "$status"
}
trap rollback EXIT

cd "$COMPOSE_DIR"
BACKEND_IMAGE="$BACKEND_IMAGE" ADMIN_IMAGE="$ADMIN_IMAGE" \
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" config --quiet
BACKEND_IMAGE="$BACKEND_IMAGE" ADMIN_IMAGE="$ADMIN_IMAGE" \
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" pull recruiter-backend recruiter-admin
BACKEND_IMAGE="$BACKEND_IMAGE" ADMIN_IMAGE="$ADMIN_IMAGE" \
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d --no-deps --remove-orphans recruiter-backend recruiter-admin

for _ in $(seq 1 60); do
  if curl --fail --silent --show-error --output /dev/null "https://$DOMAIN/login" && \
    curl --fail --silent --show-error --output /dev/null --request POST "https://$DOMAIN/api/v1/auth/browser/demo"; then
    succeeded=true
    break
  fi
  sleep 5
done
if [[ "$succeeded" != true ]]; then
  printf 'Recruiter public health verification failed\n' >&2
  exit 1
fi

update_image() {
  local key=$1 value=$2 temporary
  temporary=$(mktemp "$COMPOSE_DIR/.compose.recruiter.env.XXXXXX")
  grep -v "^${key}=" "$ENV_FILE" > "$temporary"
  printf '%s=%s\n' "$key" "$value" >> "$temporary"
  chmod 600 "$temporary"
  mv "$temporary" "$ENV_FILE"
}
update_image BACKEND_IMAGE "$BACKEND_IMAGE"
update_image ADMIN_IMAGE "$ADMIN_IMAGE"
logger --tag nomnom-deploy-recruiter -- "deployment_succeeded backend_image=$BACKEND_IMAGE admin_image=$ADMIN_IMAGE" || true
printf '[deploy-recruiter] Deployment completed successfully\n'
