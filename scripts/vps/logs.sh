#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage: nomnom-logs <service|status> [--since DURATION] [--follow]

Services: backend, admin, caddy, postgres, redis
Examples:
  nomnom-logs status
  nomnom-logs backend --since 30m
  nomnom-logs backend --since 2h --follow
EOF
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 2
fi

service=$1
shift

if [[ "$service" == "status" ]]; then
  if [[ $# -ne 0 ]]; then
    usage >&2
    exit 2
  fi
  exec docker ps \
    --filter label=com.docker.compose.project=nomnom-staging \
    --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
fi

case "$service" in
  backend|admin|caddy|postgres|redis) ;;
  *)
    printf 'Unknown NomNom service: %s\n' "$service" >&2
    usage >&2
    exit 2
    ;;
esac

since=30m
follow=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --since)
      if [[ $# -lt 2 || ! "$2" =~ ^[1-9][0-9]*(s|m|h|d)$ ]]; then
        printf -- '--since requires a positive duration such as 30m, 2h, or 1d\n' >&2
        exit 2
      fi
      since=$2
      shift 2
      ;;
    --follow)
      follow=true
      shift
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

container="nomnom-staging-${service}-1"
if ! docker inspect "$container" >/dev/null 2>&1; then
  printf 'NomNom container is not available: %s\n' "$container" >&2
  exit 1
fi

args=(logs --timestamps --since "$since")
if [[ "$follow" == true ]]; then
  args+=(--follow)
fi

exec docker "${args[@]}" "$container"
