# Security and Android Release Hardening Plan

## Goal

Secure current production credentials and prevent future secret exposure, then
complete the Android release engineering, privacy, account-deletion, testing,
store-content, and signing work required for Google Play.

All work proceeds phase by phase with an explicit baseline, implementation,
verification, and user sign-off. Existing features and prior bug fixes must be
preserved throughout.

This plan complements:

- `plans/android-google-play-go-live-plan.md`
- `plans/production-git-cicd-plan.md`

---

## Approved Decisions

- Complete all no-cost engineering work before purchasing the domain, VPS, or
  Google Play developer account.
- Use GitHub Secrets as the operational secret source for CI/CD and future VPS
  deployments.
- Use protected GitHub `staging` and `production` environments, with manual
  approval before production secrets are released.
- Materialize server secrets only as restricted runtime files outside the Git
  checkout and Docker images.
- Replace browser-readable admin JWT storage with server-set HttpOnly secure
  cookies before launch.
- Rotate exposed credentials before rewriting public Git history.
- Rewrite sensitive public Git history after current files are redacted and
  credentials are invalidated.
- Keep the Android package ID `com.nomnomlk.nomnom_lk`.
- Target Android API 36 before the closed test.
- Use a 30-day recovery period for consumer account deletion.
- Use Sentry's free tier for Flutter crash monitoring with PII filtering.
- Keep administrative and restaurant-owner deletion support-managed.

---

## Mandatory Regression-Preservation Protocol

This protocol applies to every phase.

1. Create a dedicated feature or phase branch according to the active Git
   workflow.
2. Record the affected existing behavior, routes, screens, configuration, and
   prior bug fixes before editing.
3. Run the relevant baseline tests and save the result in the phase notes.
4. Make the smallest additive change that satisfies the phase.
5. Do not remove, replace, disable, rename, or restructure existing features
   unless the plan explicitly requires it and the user approves it.
6. Do not perform unrelated cleanup, dependency upgrades, or refactors.
7. Add regression tests for every behavior that could be affected.
8. Run targeted tests after each logical change.
9. Run the relevant full backend, admin, Flutter, and E2E suites before phase
   completion.
10. Rebuild and re-run the Flutter app after every Flutter code change.
11. Inspect the final diff for accidental deletions, missing localization,
    changed routes, removed validation, and configuration regressions.
12. Stop and ask for direction if a new requirement conflicts with existing
    behavior.
13. Complete one phase and obtain sign-off before starting the next phase.

No phase is complete merely because it builds. Existing behavior must remain
verified.

---

## Current Security Findings

### Confirmed Safe Patterns

- Local backend `.env` and Firebase service-account files are ignored by Git.
- Android keystores and `key.properties` are ignored by Git.
- Flutter access and refresh tokens use secure storage.
- Backend refresh tokens are stored as hashes.
- Firebase Android and iOS client configuration contains public application
  identifiers rather than backend private keys.
- Render supports runtime environment variables and secret files.

### Immediate Risks

- The repository is public.
- A known production admin password appears in tracked documentation and source
  defaults.
- Deployment documentation records that R2 credentials were shared and require
  rotation.
- A production-capable Firebase service-account key exists locally.
- A real SMTP credential exists in the ignored local backend environment file.
- FCM registration tokens are logged by Flutter and partially by the backend.
- Admin tokens are readable by browser JavaScript through local storage and a
  client-written cookie.
- Gitleaks currently excludes broad paths and known password patterns.
- Production backend configuration accepts known development defaults.
- The deployment Compose file exposes infrastructure ports and injects a plain
  `.env` file.
- Android release builds silently fall back to debug signing.

No secret value may be copied into this plan, documentation, issues, pull
requests, terminal transcripts, or commit messages.

---

## How Production Secrets Are Handled

### Environment Files

An `.env` file is plain text. It is protected only by filesystem permissions,
disk security, and restricted administrative access. It is not automatically
encrypted or invisible. Root and Docker administrators can normally read
runtime secrets; production security minimizes and audits that access.

### Container Environment Variables

Container environment variables are not public to the internet, but Docker
administrators can inspect them. High-value secrets should use restricted files
mounted only into the service that needs them.

### GitHub Secrets

GitHub Secrets are encrypted at rest, but workflows that receive them can use
or leak them. Therefore:

- Pull-request jobs never receive production secrets.
- Production uses a protected GitHub environment with manual approval.
- Third-party actions are pinned and minimized.
- Shell tracing is disabled around secret handling.
- Secret values are never placed in command-line arguments or logs.
- Deployment sends values through standard input or temporary protected files.
- Temporary files are removed after use.

### Mobile Applications

Anything compiled into an APK or AAB is extractable. Only public configuration
may be embedded:

- API base URL
- Firebase client identifiers and restricted client API key
- Android package ID
- Public Sentry DSN

Database passwords, JWT secrets, service-account keys, SMTP passwords, R2
secrets, Sentry auth tokens, Play credentials, and keystore passwords must never
be compiled into the app.

### Irreplaceable Recovery Material

GitHub does not reveal a stored secret after it is saved. The Android upload
keystore and backup decryption key therefore require separately verified,
encrypted recovery copies even though GitHub Secrets is the operational source.

---

## Phase 0: Credential Containment

**Goal:** Invalidate known or potentially exposed production credentials before
additional development.

### Tasks

1. Change the actual production admin password hash through a controlled account
   flow; changing only the bootstrap environment variable is insufficient.
2. Revoke admin refresh tokens, impersonation sessions, and active sessions.
3. Create a replacement least-privilege Firebase service-account key.
4. Deploy and verify the replacement Firebase key before deleting the old key.
5. Replace the SMTP application password and verify email delivery.
6. Replace R2 application credentials with least-privilege credentials.
7. Verify R2 upload, read, and delete operations before revoking old keys.
8. Rotate the JWT signing secret and require all users to authenticate again.
9. Review and rotate Render API credentials if they were shared or recorded.
10. Rotate database and Redis credentials if connection values appeared in
    shared output or logs.
11. Review Docker Hub, SonarCloud, Codecov, and GitHub credentials for exposure.
12. Record only credential names, rotation dates, owners, and verification
    status; never record values.

### Verification

- Old credentials no longer authenticate.
- Admin login works only with the replacement password.
- Firebase Auth verification and FCM delivery work.
- Verification emails are delivered.
- R2 images load and uploads/deletes succeed.
- Existing JWT sessions are invalidated.
- Backend, admin, and Flutter production smoke checks pass.

### Sign-Off Gate

Do not start Phase 1 until replacement credentials are verified and previous
credentials are revoked.

---

## Phase 1: Prevent New Secret Exposure

**Goal:** Remove current disclosure paths and make recurrence detectable.

### Repository and Configuration

1. Replace committed passwords with non-working placeholders.
2. Redact credential values and unsafe command examples from deployment docs.
3. Remove production-like defaults from `.env.example` and backend production
   configuration.
4. Add production startup validation for database, Redis, JWT, R2, SMTP,
   Firebase, and bootstrap configuration.
5. Make production refuse known development defaults and missing mandatory
   secrets.
6. Explicitly exclude Firebase service-account paths and all environment files
   from Docker build contexts.
7. Verify secret files, keystores, and signing properties are not tracked.

### Scanning and Logging

1. Replace broad Gitleaks exclusions with narrow rule-specific exceptions.
2. Scan current files, all branches, all tags, and Git history.
3. Remove full and partial FCM-token logging.
4. Redact authorization headers, cookies, refresh tokens, reset tokens,
   verification tokens, and sensitive query parameters.
5. Prevent FCM error bodies from leaking credentials or notification content.
6. Add tests for production configuration rejection and logging redaction.

### Verification

- Strict Gitleaks scan passes.
- Production cannot start with defaults or missing secrets.
- Docker image inspection finds no `.env`, Firebase private key, keystore, or
  signing properties.
- Application logs contain no authentication, FCM, verification, or reset
  tokens.
- Existing local development fallback behavior remains intact.

---

## Phase 2: GitHub-to-Server Secret Delivery

**Goal:** Define a production-grade no-cost secret path from protected GitHub
environments to restricted VPS runtime files.

### GitHub Environments

1. Create `staging` and `production` environments.
2. Require manual approval for `production`.
3. Separate staging and production credentials completely.
4. Keep CI-only credentials at repository level only when appropriate.
5. Prevent fork and pull-request workflows from receiving protected secrets.
6. Use the built-in `GITHUB_TOKEN` with minimum permissions where possible.

### Runtime Layout

Use this target layout outside the repository checkout:

```text
/etc/nomnom/
  compose/
  config/
  secrets/
```

Requirements:

- Secret directory mode `0700`.
- Secret files mode `0400` or `0600`.
- Ownership restricted to the service that consumes each file.
- Only Caddy publishes ports 80 and 443.
- PostgreSQL and Redis remain on private Docker networks.
- Administrative access uses SSH keys and Tailscale.
- Containers run as non-root where practical.

### File-Based Configuration

Add support where required for:

- `DATABASE_PASSWORD_FILE`
- `REDIS_PASSWORD_FILE`
- `JWT_SECRET_FILE`
- `R2_ACCESS_KEY_FILE`
- `R2_SECRET_KEY_FILE`
- `SMTP_PASSWORD_FILE`
- `FIREBASE_CREDENTIALS_PATH`

Use PostgreSQL's supported secret-file mechanism. Configure Redis through a
restricted mounted configuration or ACL file rather than exposing a password
in Compose arguments.

### Deployment Workflow

1. Unlock production secrets only after environment approval.
2. Connect using a restricted deployment account.
3. Transmit secrets through standard input, not command-line arguments.
4. Write files atomically with restrictive permissions.
5. Mount only required files into each service.
6. Never print secret values or enable shell tracing.
7. Remove temporary runner files.
8. Run health and smoke checks before replacing the old deployment.

### Encrypted Backups

- The VPS stores only an age encryption public key.
- PostgreSQL backups are encrypted before R2 upload.
- The private recovery key remains in the protected GitHub production
  environment and an encrypted recovery copy.
- Restore requires a manually approved workflow.
- Application and backup R2 credentials are separate.

### Verification

- A fresh deployment succeeds without a repository `.env`.
- Docker images contain no runtime secrets.
- Database and Redis are unreachable publicly.
- Services cannot read unrelated secret files.
- Backup encryption and a test restore succeed.

---

## Phase 3: Secure Admin Browser Sessions

**Goal:** Remove admin tokens from browser-readable storage while preserving
mobile bearer-token authentication and all existing RBAC/impersonation behavior.

### Tasks

1. Continue bearer-token support for Flutter clients.
2. Add dashboard authentication using server-set cookies.
3. Mark cookies `HttpOnly`, `Secure`, and `SameSite=Lax` or stricter.
4. Use a short access-cookie lifetime and restrict refresh-cookie scope.
5. Route dashboard API requests through the same-origin Next.js proxy.
6. Add CSRF protection to mutating cookie-authenticated requests.
7. Remove admin access and refresh tokens from local storage.
8. Remove client-written authorization cookies.
9. Clear cookies server-side on logout, expiry, suspension, and revocation.
10. Preserve role guards, owner scoping, route protection, token refresh,
    impersonation, and Back to Admin behavior.

### Verification

- Browser JavaScript cannot read access or refresh tokens.
- CSRF attempts fail.
- Admin and owner logins, refresh, logout, RBAC, and impersonation work.
- All existing admin unit and Playwright E2E tests pass.
- Flutter authentication remains unchanged.

---

## Phase 4: Rewrite Sensitive Public Git History

**Goal:** Remove rotated credential literals from reachable public history.

### Tasks

1. Rotate credentials and clean current files first.
2. Freeze merges and pushes temporarily.
3. Inventory sensitive paths and literals across all branches and tags.
4. Create a protected repository backup.
5. Rewrite history with `git filter-repo`.
6. Remove passwords, secret files, and sensitive command examples.
7. Force-push rewritten branches and tags during a coordinated window.
8. Reapply branch protections and GitHub environment rules.
9. Require collaborators to remove old clones and clone again.
10. Recreate or rebase pull requests based on old history.
11. Run strict Gitleaks scans across every rewritten ref.
12. Request GitHub cached-view removal where necessary.

History rewriting does not make a disclosed credential safe. Rotation remains
the primary control.

### Verification

- Sensitive literals are absent from reachable refs.
- Branch protections and workflows still function.
- A fresh clone passes Gitleaks and all builds.
- Team members no longer use old clones.

---

## Phase 5: Flutter and Android API 36

**Goal:** Produce a deterministic Android API 36 build without regressing the
existing Flutter application.

### Tasks

1. Select and pin an exact stable Flutter version supporting API 36.
2. Upgrade Dart, Android Gradle Plugin, Gradle, Kotlin, JDK, and plugins only as
   required by that Flutter release.
3. Use JDK 17 or the exact JDK required by the selected Flutter toolchain.
4. Set or assert `compileSdk` and `targetSdk` 36.
5. Commit the complete Gradle wrapper.
6. Preserve Firebase, signing, notification, desugaring, and ProGuard settings.
7. Replace disabled text scaling with a bounded accessible scaler.
8. Validate API 23, API 33, API 35, and API 36.
9. Test edge-to-edge layout, back navigation, rotation, dark mode, image
   selection, text scaling, Google Sign-In, FCM, SSE, and R2 images.

### Verification

- Generated bundle manifest reports target API 36.
- `flutter analyze` passes with warnings fatal.
- Flutter unit, widget, and integration tests pass.
- Minified release starts on API 36 and installs on API 23.
- Existing screens, navigation, languages, auth, banners, notifications,
  favorites, search, and profile behavior remain present.

---

## Phase 6: Release Signing and API Safety

**Goal:** Make it impossible to produce a debug-signed or localhost production
AAB.

### Tasks

1. Remove all release fallback to debug signing.
2. Require `storeFile`, `storePassword`, `keyAlias`, and `keyPassword` for
   release tasks.
3. Require the keystore file to exist and be readable.
4. Keep debug builds working without release credentials.
5. Make `API_BASE_URL` mandatory for release builds.
6. Reject HTTP, localhost, loopback, emulator, and obsolete Render URLs.
7. Retain local fallback behavior for debug/profile builds only.
8. Add `APP_ENV`, `BUILD_SHA`, and `SENTRY_ENVIRONMENT` build values.
9. Generate metadata containing source SHA, endpoint, target SDK, version,
   signer fingerprint, and artifact checksum.
10. Update active release documentation and mark stale instructions historical.

### Verification

- Missing or partial signing credentials fail before compilation.
- Invalid production API URLs fail before compilation.
- The final signer differs from the Android debug certificate.
- Artifact metadata matches the AAB.
- Existing debug development flow remains functional.

---

## Phase 7: Logout and Cross-Account Isolation

**Goal:** Guarantee that sessions and private cached data cannot survive logout
or cross between users.

### Tasks

1. Mark the session terminating before starting logout operations.
2. Prevent an active token refresh from writing credentials after logout.
3. Unregister FCM while a valid access token remains available.
4. Call backend logout.
5. Sign out Firebase Auth.
6. Sign out Google Sign-In.
7. Clear access and refresh credentials.
8. Clear authenticated HTTP caches.
9. Clear or namespace favorites, notifications, and other private local data.
10. Reset affected provider state.
11. Preserve device-wide theme and locale preferences.
12. Reacquire and register FCM after the next authenticated login.

### Verification

- User A data never appears for User B.
- Offline startup after logout contains no previous private data.
- Firebase current user is null after logout.
- Concurrent refresh cannot restore credentials.
- FCM registers correctly after another login.
- Existing login, refresh, and guest-visible content still work.

---

## Phase 8: Notification Permission and Background FCM

**Goal:** Make notification consent contextual and background delivery reliable
in minified release builds.

### Tasks

1. Move the background callback to a top-level entry point.
2. Add `@pragma('vm:entry-point')`.
3. Initialize Firebase in the background isolate where required.
4. Remove token and notification-content logging.
5. Add a dedicated monochrome notification icon.
6. Explicitly declare and verify `POST_NOTIFICATIONS`.
7. Remove automatic startup permission prompting.
8. Add contextual notification opt-in UI.
9. Support not-determined, granted, denied, and permanently denied states.
10. Add an Open Settings recovery action.
11. Connect preference switches to actual delivery behavior or clearly identify
    them as local-only.

### Verification

- First startup does not prompt unexpectedly.
- Denial leaves the application usable.
- Foreground, background, terminated, and tapped notifications work.
- Background handling survives minification and tree shaking.
- No FCM token or notification body appears in logs or Sentry.

---

## Phase 9: Thirty-Day Account Deletion

**Goal:** Meet Google Play's in-app and external account-deletion requirements
with a real 30-day recovery lifecycle.

### Backend

1. Add `deletion_requested_at` and `deletion_scheduled_at` to consumer users.
2. Keep deletion state separate from normal suspension.
3. Add authenticated request and cancellation endpoints.
4. Add a rate-limited external email challenge for the public web flow.
5. Require recent authentication.
6. Permit automatic self-deletion only for consumer users.
7. Immediately remove refresh tokens and FCM registrations.
8. Reject pending users from refresh and normal authenticated routes.
9. Prevent registration and Firebase login from recreating pending accounts.
10. Add a bounded, idempotent scheduled finalizer.
11. Delete favorites, notifications, devices, refresh tokens, Redis keys,
    avatar objects, and Firebase identity.
12. Anonymize retained audit records.
13. Retry partial Firebase and R2 failures safely.
14. Send request, cancellation, and completion emails.

### Flutter

1. Add a destructive Delete Account section.
2. Explain the scheduled date and immediate effects.
3. Require typed confirmation and recent authentication.
4. Clear the local session after a successful request.
5. Add secure cancellation and pending-deletion screens.
6. Link the external deletion page.
7. Localize all text in English, Sinhala, and Tamil.

### Verification

- Existing access and refresh tokens cannot bypass pending status.
- Duplicate requests are idempotent.
- Cancellation works only before finalization.
- Finalization safely handles retries and repeated runs.
- In-app and external requests both work.
- Owner and admin requests are redirected to support.
- Existing suspension, registration, login, verification, and admin user
  management behavior remains correct.

---

## Phase 10: Flutter Sentry and Public Legal Pages

**Goal:** Add privacy-safe mobile diagnostics and locally complete public policy
surfaces before purchasing a domain.

### Flutter Sentry

1. Add Flutter Sentry using the free tier.
2. Load the public DSN through compile-time configuration.
3. Set environment, source revision, version, and distribution.
4. Disable default PII, screenshots, and view hierarchy.
5. Scrub authorization headers, cookies, tokens, email, phone, request bodies,
   notification content, and URL query values.
6. Keep the Sentry organization auth token only in protected GitHub Secrets.
7. Preserve source maps and symbols for release diagnostics.

### Public Pages

Implement public routes in the existing Next.js application:

- `/privacy`
- `/terms`
- `/support`
- `/delete-account`

Keep versioned source content under `docs/legal/`. The deletion page must submit
a secure real request and must not reveal whether an email is registered.

### Verification

- Public pages render locally without authentication.
- Pages are responsive and accessible.
- In-app links open every page.
- Test Sentry events resolve to the expected release.
- Events contain no credentials or prohibited PII.
- Privacy and retention wording matches actual behavior.

---

## Phase 11: Play Store Package

**Goal:** Prepare all store content without purchasing a Play account.

### Deliverables

- App title
- Short description
- Full description
- Initial release notes
- 512 x 512 Play icon
- 1024 x 500 feature graphic
- At least four portrait phone screenshots
- Screenshot captions
- Reviewer instructions
- Dedicated consumer reviewer-account plan
- Data Safety worksheet
- Content-rating worksheet
- Target-audience declaration for ages 13 and older
- Initial Sri Lanka distribution decision
- Support-response templates
- Asset source and licensing record
- Sponsored-content and advertising declaration decision

### Verification

- Assets meet dimensions and format requirements.
- Screenshots contain no debug UI, credentials, personal data, or emulator
  controls.
- Store claims match implemented behavior.
- Restaurant logos and promotional images have documented usage rights.
- Reviewer instructions do not use admin credentials.

---

## Phase 12: Mobile Tests and API 36 AAB CI

**Goal:** Build and verify Android release candidates reproducibly without
exposing production signing material to untrusted jobs.

### Pull Request Job

1. Pin exact Flutter and JDK versions.
2. Run formatting checks.
3. Run strict Flutter analysis.
4. Run Flutter and backend tests.
5. Generate an ephemeral CI keystore.
6. Build a minified API 36 AAB.
7. Verify package ID, min SDK, target SDK, permissions, endpoint, and signer.
8. Retain short-lived AAB, mapping, symbols, metadata, and checksums.

### Protected Candidate Job

1. Require protected production-environment approval.
2. Reconstruct the real upload keystore from GitHub Secrets.
3. Require the approved production API endpoint.
4. Verify the expected signing fingerprint.
5. Build once and preserve the exact artifact.
6. Run non-destructive production smoke checks.
7. Retain immutable AAB, mapping, symbols, metadata, and checksums.

### Required Regression Tests

- Refresh/logout race
- Firebase and Google logout
- Cross-account cache isolation
- Notification permission states
- Background FCM and tap navigation
- Deletion request, cancellation, and finalization
- API URL validation
- Missing-signing negative tests
- API 36 bundle and merged-permission inspection
- Existing home, search, favorites, restaurants, offers, banners, auth, profile,
  localization, and notification behavior

### Verification

- Pull requests cannot access production signing or deployment secrets.
- AAB reports API 36 and approved permissions.
- Release fails without signing and endpoint configuration.
- Mapping, symbols, metadata, and checksums are retained.
- All relevant existing backend, admin, Flutter, and E2E tests pass.

---

## Phase 13: Upload Keystore and Recovery

**Goal:** Create the permanent upload identity and prove it is recoverable.

Creating the keystore is free.

### Tasks

1. Generate a unique upload key with a strong unique password.
2. Keep the working keystore outside Git.
3. Store an encrypted copy in the protected GitHub production environment.
4. Keep two encrypted recovery copies in separate failure domains.
5. Keep at least one recovery copy separate from its password.
6. Record alias, generation date, expiry, SHA-1, and SHA-256 without recording
   passwords or key material.
7. Restore a backup to a temporary location and sign a test AAB.
8. Verify the signature and remove the temporary restored copy.
9. Confirm no keystore or signing property exists in any Git ref.
10. Add the upload certificate fingerprints to Firebase when ready.
11. Add the separate Play App Signing fingerprints after Play setup.
12. Document Google's upload-key reset process.

### Verification

- Two independent encrypted recovery copies exist.
- Restore, sign, and verify drill succeeds.
- Fingerprints match the protected CI expectation.
- Git and Gitleaks contain no private signing material.

---

## Deferred Paid and External Work

These steps wait until Phases 0 through 13 are ready:

- Purchase the Google Play personal developer account.
- Complete Play identity and device verification.
- Purchase `nomnom.lk`.
- Purchase the Contabo VPS.
- Configure final DNS and public support email.
- Migrate Render to the VPS.
- Upload the internal-test AAB.
- Register Play App Signing fingerprints in Firebase.
- Run the required closed test.
- Apply for production access and perform a staged rollout.

A domain and VPS are business/infrastructure choices, not prerequisites for
completing the engineering phases. Existing or free hosting can be used for
temporary policy-page verification.

---

## Phase Order and Dependencies

```text
Phase 0  Credential containment
   |
Phase 1  Prevent new exposure
   |
Phase 2  GitHub-to-server secret delivery design
   |
Phase 3  Secure admin browser sessions
   |
Phase 4  Rewrite sensitive Git history
   |
Phase 5  Flutter and Android API 36
   |
Phase 6  Release signing and API safety
   |
Phase 7  Logout and cache isolation
   |
Phase 8  Notification and background FCM
   |
Phase 9  Thirty-day account deletion
   |
Phase 10 Sentry and public legal pages
   |
Phase 11 Play Store package
   |
Phase 12 Tests and API 36 AAB CI
   |
Phase 13 Upload keystore and recovery
```

Phases 7 and 8 may be implemented together after Phase 6 because both touch
authentication and FCM lifecycle behavior. All other phases require separate
sign-off unless the user explicitly approves parallel execution.

---

## Immediate Next Action

Begin Phase 0 only after creating its feature branch and recording baseline
production health. Rotate one credential class at a time, deploy the replacement,
verify dependent features, and only then revoke the previous credential.
