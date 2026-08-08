#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage: nomnom-logs <service|status|paths> [--since DURATION] [--follow]

Services: backend, admin, caddy, postgres, redis
Examples:
  nomnom-logs status
  nomnom-logs paths
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
compose_project=${NOMNOM_COMPOSE_PROJECT:-nomnom-staging}
log_root=${NOMNOM_LOG_ROOT:-/var/log/nomnom}

if [[ ! "$compose_project" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  printf 'Invalid Compose project name\n' >&2
  exit 2
fi

if [[ "$service" == "paths" ]]; then
  if [[ $# -ne 0 ]]; then
    usage >&2
    exit 2
  fi
  missing=false
  for name in backend admin caddy postgres redis; do
    alias_path="$log_root/${name}.json.log"
    container="${compose_project}-${name}-1"
    expected=$(docker inspect --format '{{.LogPath}}' "$container" 2>/dev/null || true)
    if [[ -n "$expected" ]]; then
      expected=$(realpath -e -- "$expected" 2>/dev/null || true)
    fi
    if [[ -L "$alias_path" && -e "$alias_path" ]]; then
      resolved=$(realpath -e -- "$alias_path")
      if [[ -n "$expected" && "$resolved" == "$expected" && "$resolved" =~ ^/var/lib/docker/containers/([0-9a-f]{64})/([0-9a-f]{64})-json\.log$ && "${BASH_REMATCH[1]}" == "${BASH_REMATCH[2]}" ]]; then
        printf '%s -> %s\n' "$alias_path" "$resolved"
        continue
      fi
      printf '%s -> [stale or invalid target]\n' "$alias_path"
    else
      printf '%s -> [missing or stale]\n' "$alias_path"
    fi
    missing=true
  done
  if [[ "$missing" == true ]]; then
    exit 1
  fi
  exit 0
fi

if [[ "$service" == "status" ]]; then
  if [[ $# -ne 0 ]]; then
    usage >&2
    exit 2
  fi
  exec docker ps \
    --filter "label=com.docker.compose.project=$compose_project" \
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

container="${compose_project}-${service}-1"
if ! docker inspect "$container" >/dev/null 2>&1; then
  printf 'NomNom container is not available: %s\n' "$container" >&2
  exit 1
fi

args=(logs --timestamps --since "$since")
if [[ "$follow" == true ]]; then
  args+=(--follow)
fi

exec docker "${args[@]}" "$container"
