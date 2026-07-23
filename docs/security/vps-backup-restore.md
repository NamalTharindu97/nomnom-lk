# VPS PostgreSQL Backup and Restore

## Security Boundary

The VPS stores only the age recipient public key. It can create encrypted
backups but cannot decrypt them. The age private identity belongs in the
protected GitHub `production` environment and in separately encrypted offline
recovery copies.

Application R2 credentials and backup R2 credentials must be different. Backup
credentials should be limited to the backup prefix and must not grant access to
application images.

## Backup Flow

`scripts/vps/backup-postgres.sh`:

1. Streams a custom-format `pg_dump` directly into age encryption.
2. Never writes an unencrypted database dump.
3. Verifies the age header before accepting the artifact.
4. Generates a SHA-256 checksum.
5. Uploads the encrypted object and checksum using a temporary mode-0600 rclone
   configuration.
6. Deletes all temporary local material on exit.

Schedule the script with a root-owned systemd timer after the VPS is purchased.
Do not add retention deletion until a real upload, checksum verification, and
restore drill have succeeded.

Planned retention after verification:

- 7 daily backups
- 4 weekly backups
- 3 monthly backups

## Restore Flow

`.github/workflows/restore-vps-production.yml` is manually dispatched and uses
the protected `production` environment. It requires a backup object name and the
typed confirmation `VERIFY-RESTORE`.

The workflow streams the private age identity through SSH standard input to
`scripts/vps/restore-postgres.sh`. The script:

1. Downloads the encrypted backup and checksum.
2. Verifies integrity before decryption.
3. Streams decrypted data directly into `pg_restore`.
4. Restores only into a disposable verification database.
5. Confirms application tables exist.
6. Drops the verification database and deletes the temporary private identity.

This workflow never replaces the production database. A production replacement
requires a separate maintenance plan, fresh pre-restore backup, explicit user
approval, downtime communication, and post-restore application verification.

## VPS Acceptance Gate

Before enabling scheduled backups:

- Install pinned versions of `age`, `rclone`, Docker, and PostgreSQL client
  tooling.
- Confirm the root-owned scripts and sudo rules cannot be modified by the deploy
  user.
- Verify R2 permissions using dedicated backup credentials.
- Perform one encrypted upload and disposable restore drill.
- Verify no plaintext dump, private age identity, or R2 secret appears in logs,
  process arguments, temporary files after completion, or shell history.
