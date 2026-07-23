# Phase 0 Credential Containment Record

## Purpose

Track credential rotation and verification without recording secret values.
Rotate one credential class at a time, verify the replacement, and only then
revoke the previous credential.

## Baseline

- Date started: 2026-07-23
- Branch: `phase/P51-credential-containment`
- Baseline commit: `ff77f51`
- Backend health endpoint: HTTP 200
- Admin login page: HTTP 200
- Render CLI authentication: available
- GitHub CLI authentication: available
- GitHub `production` environment: not created yet
- Firebase or Google Cloud CLI authentication: unavailable
- Cloudflare Wrangler authentication: unavailable
- Android app: intentionally stopped

## Local Secret-File Permissions

The following ignored local files existed with mode `0644` and were changed to
owner-only mode `0600` without changing their contents:

- `backend/.env`
- `backend/config/firebase-credentials.json`
- `admin/.env.local`

`android/key.properties` is absent, as expected before release signing setup.

## Rotation Checklist

No values, password hints, key IDs, token fragments, or private URLs belong in
this record.

| Credential | Replacement installed | Replacement verified | Previous revoked | Notes |
|---|---:|---:|---:|---|
| Production admin password | Yes | Yes | Yes | Replacement login verified; disclosed previous credential returns HTTP 401; Render bootstrap value also replaced |
| Admin refresh tokens | Yes | Yes | Yes | 22 persisted admin refresh tokens deleted |
| Admin impersonation sessions | Yes | Yes | Yes | No active impersonation keys existed; JWT rotation invalidated prior tokens |
| Restaurant-owner passwords | Contained | Yes | Yes | All 11 owner accounts suspended pending unique passwords; published credential returns HTTP 403 |
| Firebase service-account key | Deferred | No | No | User will perform provider dashboard action later; old key remains active |
| SMTP application password | No | No | No | Provider dashboard action required |
| R2 application credentials | No | No | No | Provider dashboard action required |
| JWT signing secret | Yes | Yes | Yes | Render deploy and fresh admin login succeeded; all remaining refresh tokens deleted |
| Render API credential | Review pending | Review pending | Review pending | Rotate if shared or recorded |
| PostgreSQL credentials | Review pending | Review pending | Review pending | Rotate if exposed outside provider controls |
| Redis credentials | Review pending | Review pending | Review pending | Rotate if exposed outside provider controls |
| Docker Hub credential | Review pending | Review pending | Review pending | GitHub secret exists |
| SonarCloud credential | Review pending | Review pending | Review pending | GitHub secret exists |
| Codecov credential | Review pending | Review pending | Review pending | GitHub secret exists |

The PostgreSQL allow list was opened only to the current operator IP while the
targeted refresh-token deletion ran. It was cleared immediately afterward and
verified to contain zero entries. Backend and admin health remained HTTP 200.

The JWT signing secret was generated in memory, sent directly to Render without
printing it, and followed by a successful backend deployment. Three refresh
tokens created after the targeted admin cleanup were then deleted globally. The
Redis allow list was opened only for a targeted impersonation-key cleanup; no
matching keys existed. PostgreSQL and Redis allow lists were both restored to
zero entries and production health remained HTTP 200.

After explicit approval, all 11 restaurant-owner accounts were suspended because
their shared password is documented publicly. Restaurant, offer, and owner data
was preserved. The published credential now receives HTTP 403, the PostgreSQL
allow list was restored to zero entries, and backend health remained HTTP 200.
Each owner must receive a unique password before that individual account is
reactivated.

## Required Rotation Order

1. Change the actual production admin password.
2. Verify login with the replacement password.
3. Confirm the publicly disclosed previous password no longer authenticates.
4. Delete admin refresh tokens and impersonation sessions.
5. Create, install, verify, and then revoke the Firebase service-account key.
6. Create, install, verify, and then revoke the SMTP application password.
7. Create, install, verify, and then revoke the R2 application credentials.
8. Replace the JWT signing secret.
9. Delete all existing refresh tokens because refresh lookup currently relies on
   the stored token hash and does not independently reject tokens signed by the
   previous JWT key.
10. Verify user, owner, and admin authentication after JWT rotation.
11. Review provider and CI credentials and rotate any credential that was
    shared, copied into logs, or used outside its intended boundary.

## Manual Provider Actions

### Admin Password

1. Open the hosted admin dashboard.
2. Sign in with the current admin account.
3. Open Dashboard Settings.
4. Generate a unique password in the macOS Passwords app or another trusted
   password manager. A human login password must remain recoverable and should
   not be stored only in GitHub Secrets.
5. Change the password.
6. Log out and sign in again with the replacement password.
7. Do not paste the replacement password into chat, source files, shell history,
   documentation, or a GitHub issue.

### Firebase Service Account

1. Open Google Cloud IAM and Admin for the production Firebase project.
2. Confirm the backend service account has only the roles required for Firebase
   token verification and FCM delivery.
3. Create one replacement JSON key.
4. Replace the Render secret file.
5. Deploy and verify Firebase login and FCM.
6. Replace the ignored local file and set mode `0600`.
7. Delete the previous key from Google Cloud.

### SMTP

1. Create a replacement application password at the mail provider.
2. Update the Render SMTP secret without placing it in a command argument.
3. Deploy and send a verification email.
4. Update the ignored local environment file if local email testing is needed.
5. Revoke the previous application password.

### Cloudflare R2

1. Create a least-privilege replacement token scoped to the production bucket.
2. Update Render access-key and secret-key values.
3. Deploy and verify existing image reads, a new upload, and deletion of the test
   object.
4. Update ignored local credentials only if production R2 access is required
   locally.
5. Revoke the previous R2 token.

### JWT

1. Generate a cryptographically random replacement signing secret locally
   without printing it.
2. Store it directly in the Render environment.
3. Deploy the backend.
4. Delete every persisted refresh token.
5. Delete active impersonation sessions from Redis.
6. Verify that old access and refresh tokens fail.
7. Verify fresh user, owner, and admin login and refresh behavior.

## Phase Completion Gate

Phase 0 is complete only when:

- Every credential marked for rotation has a verified replacement.
- Every previous credential is revoked.
- Existing backend, admin, Firebase, FCM, email, R2, SSE, and authentication
  behavior passes regression checks.
- No secret value was added to Git, logs, documentation, or chat.
- The final diff contains only sanitized records and explicitly approved Phase 0
  changes.

## Paused State

Phase 0 was paused by user choice on 2026-07-23 before the provider-managed
Firebase, SMTP, R2, Render API, PostgreSQL, and Redis rotations. Do not begin
Phase 1 until those rotations are resumed, verified, recorded above, and Phase 0
receives explicit sign-off.
