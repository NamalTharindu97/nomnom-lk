# GitHub-to-VPS Secret Delivery

## Status

The delivery path is prepared but intentionally inactive. No VPS exists and no
application secret has been added to GitHub environments.

GitHub environments created on 2026-07-23:

- `staging`: deployment branch policy `staging`
- `production`: deployment branch policy `master`, required reviewer
  `NamalTharindu97`

## Source of Truth

GitHub environment secrets are the operational source for VPS deployments.
Staging and production use identical secret names with different values.
Repository-level CI secrets remain limited to CI services and never substitute
for environment-specific application credentials.

Required environment secrets:

- `VPS_SSH_PRIVATE_KEY`
- `VPS_SSH_KNOWN_HOSTS`
- `DATABASE_PASSWORD`
- `REDIS_PASSWORD`
- `JWT_SECRET`
- `FIREBASE_CREDENTIALS_JSON`
- `R2_ACCESS_KEY`
- `R2_SECRET_KEY`
- `ADMIN_BOOTSTRAP_PASSWORD`
- `SMTP_PASSWORD`
- `POSTGRES_TLS_CERT`
- `POSTGRES_TLS_KEY`
- `BACKUP_R2_ACCESS_KEY`
- `BACKUP_R2_SECRET_KEY`

Production restore additionally requires:

- `AGE_PRIVATE_IDENTITY`

Required environment variables, which are non-secret:

- `VPS_HOST`
- `VPS_PORT`
- `VPS_DEPLOY_USER`
- `AGE_RECIPIENT`

Do not populate these until the VPS host key and deployment account have been
created and independently verified.

## Delivery Flow

`.github/workflows/deploy-vps-secrets.yml`:

1. Requires manual workflow dispatch and selects `staging` or `production`.
2. GitHub applies branch and reviewer protection before releasing secrets.
3. The runner creates a mode-0600 SSH identity and known-hosts file.
4. `scripts/vps/package-secrets.sh` writes secrets only under `$RUNNER_TEMP` with
   `umask 077` and emits a fixed-name tar stream.
5. SSH strict host-key checking is mandatory.
6. The archive is streamed over standard input to a fixed root-owned installer.
7. The server validates every entry, rejects unknown files/links/oversized
   content, creates service-specific copies using the verified container UIDs,
   derives the Redis ACL hash, and atomically replaces the secret directory.
8. The fixed deployment helper validates immutable images and Compose syntax,
   pulls images, starts services, and checks health.
9. Failed health verification restores the immediately previous secret set.

No secret is stored in an artifact, cache, job output, summary, image, Compose
file, command-line argument, or repository file.

## Server Bootstrap

After purchasing the VPS, a root administrator must:

1. Create `/etc/nomnom`, `/etc/nomnom/config`, and `/etc/nomnom/compose` with
   root ownership.
2. Install the reviewed Compose files and configuration.
3. Install scripts as immutable root-owned commands:
   - `/usr/local/sbin/nomnom-install-secrets`
   - `/usr/local/sbin/nomnom-deploy`
   - `/usr/local/sbin/nomnom-backup-postgres`
   - `/usr/local/sbin/nomnom-restore-postgres`
4. Create an unprivileged deployment account with SSH-key access through
   Tailscale or the approved firewall path.
5. Add narrow sudo rules permitting only the four fixed commands above, without
   arbitrary arguments except the validated restore identifier and
   confirmation.
6. Record the SSH host key out of band, then store the complete known-hosts line
   in each GitHub environment.
7. Confirm the deployment account cannot modify root-owned scripts, Compose
   configuration, systemd units, Docker daemon configuration, or sudoers.

Docker group membership is root-equivalent. The deployment account must not be
added to the Docker group; only fixed sudo commands invoke Docker.

## Rotation

1. Create a replacement provider credential.
2. Update only the matching protected GitHub environment secret.
3. Dispatch the secret deployment workflow.
4. Verify application behavior and health.
5. Revoke the previous provider credential.
6. Record the rotation date and result without recording values or fragments.

JWT rotation also requires persisted refresh-token deletion. Database, Redis,
Firebase, SMTP, and R2 rotations require their service-specific verification
steps from `docs/security/phase-0-credential-containment.md`.

## Limitations Before VPS Purchase

Static syntax, archive validation, file loading, and workflow policy can be
tested now. These remain mandatory VPS acceptance tests:

- Service UID and mounted-file permission verification
- PostgreSQL TLS startup and certificate renewal
- Redis ACL startup and persistence
- Firewall and Tailscale isolation
- SSH host-key enrollment
- Atomic secret rollback under real container failure
- Encrypted R2 upload and disposable restore drill
- Confirmation that only ports 80 and 443 are public
