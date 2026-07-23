# Future VPS Runtime

This directory is an additive production template. It does not replace
`backend/docker-compose.yml`, `backend/docker-compose.deploy.yml`, or the current
Render deployment.

## Security Model

- Only Caddy publishes host ports.
- Backend, admin, PostgreSQL, and Redis use internal Docker networks.
- Runtime secrets live under `/etc/nomnom/secrets`, outside Git and images.
- Each service receives only its declared secret files.
- PostgreSQL uses TLS inside the data network.
- Redis uses an ACL file derived from the password without storing the plaintext
  password in its configuration.
- Application images must use immutable Git SHA tags; infrastructure images must
  use reviewed digests.
- Containers drop Linux capabilities and use read-only filesystems where their
  runtime permits it.

## Server Layout

```text
/etc/nomnom/
  compose/
  config/
  secrets/
  secrets.previous/
```

The committed `compose.env.example` contains only non-secret placeholders.
Production values come from the protected GitHub environment and are installed
by `scripts/vps/install-secrets.sh`.

## Pre-Purchase Limitations

The Compose model can be validated statically now. Before deployment, confirm
the exact service UIDs, PostgreSQL TLS key permissions, image digests, firewall,
Tailscale access, backup tooling, and rollback behavior on the purchased VPS.

Do not use the zero digests or placeholder application tags from
`compose.env.example` for deployment.
