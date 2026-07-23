#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  printf 'deploy must run as root\n' >&2
  exit 1
fi

nomnom_root=${NOMNOM_ROOT:-/etc/nomnom}
compose_dir="$nomnom_root/compose"
env_file="$nomnom_root/config/compose.env"
secret_root="$nomnom_root/secrets"
previous_root="$nomnom_root/secrets.previous"

if [[ ! -r "$env_file" ]]; then
  printf 'Compose environment file is unavailable\n' >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$env_file"
set +a

require_immutable_image() {
  local variable=$1
  local value=${!variable:-}
  if [[ ! "$value" =~ @sha256:[0-9a-f]{64}$ && ! "$value" =~ :[0-9a-f]{40}$ ]]; then
    printf '%s must use an immutable digest or full Git SHA tag\n' "$variable" >&2
    exit 1
  fi
  if [[ "$value" == *"sha256:0000000000000000000000000000000000000000000000000000000000000000"* || "$value" == *"git-sha-placeholder"* ]]; then
    printf '%s still contains a placeholder image reference\n' "$variable" >&2
    exit 1
  fi
}

for variable in CADDY_IMAGE POSTGRES_IMAGE REDIS_IMAGE BACKEND_IMAGE ADMIN_IMAGE; do
  require_immutable_image "$variable"
done

# Invoked indirectly by the EXIT trap.
# shellcheck disable=SC2317
rollback_secrets() {
  if [[ -d "$previous_root" ]]; then
    failed_root="$nomnom_root/secrets.failed.$(date +%s)"
    mv "$secret_root" "$failed_root"
    mv "$previous_root" "$secret_root"
    docker compose --env-file "$env_file" -f "$compose_dir/compose.yml" up -d
    printf 'Deployment failed; previous secrets restored\n' >&2
  fi
}

deployment_succeeded=false
# Invoked indirectly by the EXIT trap.
# shellcheck disable=SC2317
finish() {
  if [[ "$deployment_succeeded" != true ]]; then
    rollback_secrets
  fi
}
trap finish EXIT

cd "$compose_dir"
docker compose --env-file "$env_file" -f compose.yml config --quiet
docker compose --env-file "$env_file" -f compose.yml pull
docker compose --env-file "$env_file" -f compose.yml up -d

health_url=${HEALTH_URL:?Set HEALTH_URL in the server compose environment}
for _ in $(seq 1 60); do
  if curl --fail --silent --show-error --output /dev/null "$health_url"; then
    rm -rf "$previous_root"
    deployment_succeeded=true
    printf 'Deployment health check passed\n'
    exit 0
  fi
  sleep 5
done

exit 1
