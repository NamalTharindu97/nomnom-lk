# Android Google Play Go-Live Plan

## Goal

Release NomNom LK on Google Play for users in Sri Lanka through a controlled,
policy-compliant process. Complete all engineering and content work that does
not require payment first, then purchase the domain, VPS, and Play developer
account when the app is ready to enter Play testing.

This plan supersedes the Android readiness sections of
`plans/p43-release-plan.md`. The older plan contains stale API, deployment, and
asset information.

---

## Approved Decisions

- Release Android first; defer iOS.
- Keep the permanent package ID `com.nomnomlk.nomnom_lk`.
- Launch in Sri Lanka initially.
- Target users aged 13 and older; the app is not directed at children.
- Use a personal Google Play developer account.
- Use Sentry's free tier for mobile crash monitoring.
- Give consumer account deletion requests a 30-day recovery period.
- Keep administrative and restaurant-owner account deletion as a
  support-managed process.
- Use at least 14 to 16 invited testers so that 12 can remain continuously
  opted in for Google's required 14-day closed test.
- Use `https://api.nomnom.lk/api/v1` for the final production mobile build.
- Promote a tested Android App Bundle rather than rebuilding for production.

---

## Current State

### Ready

- The Flutter app works against the hosted Render production API.
- Firebase initialization, Google authentication, FCM registration, SSE, and
  featured banners have been verified on an Android emulator.
- The package ID is `com.nomnomlk.nomnom_lk`.
- The current version is `1.0.0+1`.
- The minimum Android SDK is 23.
- The app icon source is a 1024 x 1024 image.
- App assets are declared in `pubspec.yaml`.
- Release shrinking and ProGuard rules are configured.
- The merged Android manifest contains the notification permission and no
  sensitive location, contacts, SMS, or broad-storage permissions.
- The user can provide at least 12 closed-test participants.

### Blocking Release

- The current generated Android build targets API 35, not API 36.
- Flutter 3.29.3 and the Android toolchain need to be upgraded and tested.
- A production upload keystore and `android/key.properties` do not exist.
- The release build silently falls back to debug signing when credentials are
  absent.
- `scripts/build-android-release.sh` contains an obsolete Render API URL.
- There is no user-facing account-deletion workflow.
- Privacy, terms, support, and account-deletion pages are not published.
- User-specific local caches are not cleared completely during logout.
- Firebase Auth and Google Sign-In are not explicitly signed out on logout.
- Mobile Sentry monitoring is not configured.
- Store listing text, screenshots, feature graphic, Data Safety answers, and
  reviewer instructions are incomplete.
- CI does not build and verify a production-signed API 36 AAB.
- The Google Play personal developer account does not exist yet.
- `nomnom.lk` and the Contabo VPS have not been purchased.

---

## Work That Can Be Completed Without Buying Anything

Complete these phases before purchasing the Play account, domain, or VPS.

### Free Workstream A: Android Toolchain

1. Upgrade to a current stable Flutter release that officially supports
   Android API 36.
2. Upgrade the Android Gradle Plugin, Gradle, Kotlin, and dependencies required
   by that Flutter release.
3. Set or verify `compileSdk` and `targetSdk` 36.
4. Commit the Gradle wrapper files required for reproducible builds.
5. Build and test on Android 16/API 36.
6. Test the minimum supported Android version and representative Android 13 and
   Android 15 devices or emulators.
7. Verify edge-to-edge rendering, system back behavior, notification prompts,
   image selection, text scaling, dark mode, and rotation.

### Free Workstream B: Release Build Safety

1. Remove the debug-signing fallback from release builds.
2. Make release builds fail clearly when signing properties are missing.
3. Replace the stale release script endpoint with a required explicit
   `API_BASE_URL`.
4. Reject missing, local, HTTP, and obsolete API URLs in production builds.
5. Record the source commit, API endpoint, Flutter version, version name, and
   version code with every release artifact.
6. Add CI checks for package ID, target SDK, permissions, endpoint, and signing
   configuration.
7. Produce an unsigned or locally test-signed API 36 AAB in CI until the real
   upload key is created.

### Free Workstream C: Account Deletion

1. Add deletion state and timestamps to consumer users:
   `deletion_requested_at` and `deletion_scheduled_at`.
2. Add an authenticated endpoint that requests account deletion after explicit
   confirmation and recent authentication.
3. Mark the account pending deletion for 30 days.
4. Immediately revoke refresh tokens and remove FCM device registrations.
5. Prevent normal application access while deletion is pending.
6. Add a secure cancellation flow during the 30-day recovery period.
7. Add a scheduled job that finalizes expired requests.
8. Delete favorites, notifications, refresh tokens, device tokens, profile
   data, avatar objects, and the Firebase identity during finalization.
9. Anonymize any audit information that must survive deletion.
10. Document that isolated backups expire according to the normal retention
    schedule and are not used to recreate deleted accounts except during a
    disaster recovery event.
11. Clear secure tokens and user-specific local caches when deletion is
    requested.
12. Add backend, Flutter, and integration tests for request, cancellation, and
    finalization.

Temporary deactivation alone does not satisfy Google Play's deletion policy.
The request must result in permanent deletion when the recovery period ends.

### Free Workstream D: Authentication and Privacy Fixes

1. Explicitly sign out from Firebase Auth and Google Sign-In during logout.
2. Clear favorites, notifications, offers, and other user-specific local caches
   during logout, account switching, and deletion.
3. Ensure cached data from one account cannot appear for another account.
4. Stop logging complete FCM registration tokens.
5. Validate the background FCM callback in a minified release and add
   `@pragma('vm:entry-point')` where required.
6. Add a dedicated monochrome Android notification icon.
7. Move notification permission prompting to a contextual opt-in point.
8. Add denied-permission recovery that opens Android notification settings.
9. Add in-app links for Privacy, Terms, Support, and Delete Account using the
   final domain paths, even if temporary local pages are used during testing.

### Free Workstream E: Policy and Web Content

Draft the content locally before a domain is purchased:

- Privacy policy
- Terms of service
- Support/contact page
- Account-deletion request page
- Thirty-day deletion and cancellation explanation
- Backup-retention explanation
- Third-party service-provider list

The final public URLs will be:

- `https://nomnom.lk/privacy`
- `https://nomnom.lk/terms`
- `https://nomnom.lk/support`
- `https://nomnom.lk/delete-account`

The privacy policy must accurately cover:

- Name, email, optional phone number, and avatar
- Favorites and notification history
- Device and FCM identifiers
- Authentication and refresh tokens
- Local application caches
- Firebase Authentication, Google Sign-In, and FCM
- Cloudflare R2, PostgreSQL, Redis, infrastructure hosting, and Sentry
- Data retention, backups, account deletion, and support contact
- Encryption in transit and applicable storage protections

### Free Workstream F: Sentry Mobile Monitoring

1. Add Sentry to the Flutter app.
2. Load the DSN through compile-time configuration rather than source control.
3. Set release name, environment, distribution/version code, and source commit.
4. Scrub authorization headers, tokens, email addresses, and unnecessary PII.
5. Do not enable screenshots or view-hierarchy collection without a separate
   privacy review.
6. Capture handled startup, authentication, networking, FCM, and background
   errors without duplicating expected user-facing failures.
7. Verify symbol and source-map handling for release diagnostics.
8. Reflect diagnostic collection accurately in the privacy policy and Play
   Data Safety form.

### Free Workstream G: Store Listing Package

Prepare locally:

- App title: NomNom LK
- Short description
- Full description
- First-release notes
- 512 x 512 Play icon
- 1024 x 500 feature graphic
- At least four portrait phone screenshots
- Screenshot captions
- Reviewer instructions
- Dedicated consumer reviewer account plan
- Data Safety worksheet
- Content-rating worksheet
- Target-audience declaration: ages 13 and older
- Initial country list: Sri Lanka
- Support-response templates

Determine before submission whether paid restaurant placements or sponsored
banners require the Play listing to declare advertising or commercial content.

### Free Workstream H: Testing and CI

1. Add automated coverage for registration and email verification.
2. Add account-deletion request and cancellation tests.
3. Add logout and cross-account cache-isolation tests.
4. Preserve the token-refresh concurrency regression test.
5. Test notification permission denial and settings recovery.
6. Test FCM foreground, background, terminated, and notification-tap flows.
7. Test avatar upload and image-picker recovery after process death.
8. Add a production API smoke-test mode using an injected endpoint.
9. Run Flutter analysis without ignoring warnings.
10. Build an API 36 release artifact in CI.
11. Retain the AAB, ProGuard mapping, native symbols, checksums, and build
    metadata.

---

## Deferred Paid and External Steps

These steps can wait until the free engineering work is near completion.

### Google Play Developer Account

1. Create a truthful personal developer account.
2. Pay the one-time USD 25 registration fee.
3. Complete identity and Android-device verification.
4. Create the Play application using `com.nomnomlk.nomnom_lk`.
5. Enable Play App Signing.

### Domain and Email

1. Confirm availability and purchase `nomnom.lk` through the official LK Domain
   Registry Economy package.
2. Configure Cloudflare Free DNS.
3. Configure `support@nomnom.lk` using a suitable mailbox or email-routing
   provider.
4. Publish the prepared privacy, terms, support, and deletion pages.

### Contabo VPS

1. Purchase Contabo Cloud VPS 4 in Singapore with Ubuntu 24.04.
2. Confirm the final Singapore-region surcharge before payment.
3. Configure Tailscale-only administrative access.
4. Deploy Caddy, PostgreSQL 16, Redis 7, backend, admin, Netdata, and backup
   jobs.
5. Configure `api.nomnom.lk` and `admin.nomnom.lk`.
6. Configure encrypted PostgreSQL backups to Cloudflare R2.
7. Migrate production data from Render and verify counts and behavior.
8. Keep Render available until the Contabo deployment and closed-test app are
   stable.
9. Rotate production credentials after migration.

### Upload Keystore

Creating a keystore is free, but it should be done when a secure backup location
and Play application are ready:

1. Generate a dedicated upload keystore.
2. Store credentials outside Git.
3. Keep two secure backups in separate locations.
4. Add upload-certificate SHA-1 and SHA-256 fingerprints to Firebase.
5. Upload the first AAB to Play Internal Testing.
6. Add the Play App Signing SHA-1 and SHA-256 fingerprints to Firebase.
7. Download and commit the resulting non-secret `google-services.json` update.
8. Verify Google Sign-In in an app installed from Google Play.

---

## Execution Phases

### Phase 1: Free Engineering Readiness

Complete API 36, release-build hardening, deletion, logout/cache isolation,
notification UX, Sentry, policy drafts, store assets, and CI improvements.

**Exit criteria:**

- API 36 release build succeeds.
- All Flutter and backend tests pass.
- Release builds cannot use debug signing accidentally.
- Account deletion and cancellation pass automated tests.
- Policy and store content are ready to publish.
- No purchase is required to reach this gate.

### Phase 2: Infrastructure and Public Pages

Purchase the domain and VPS, deploy the final production environment, publish
the policy pages, migrate Render data, and rotate credentials.

**Exit criteria:**

- `api.nomnom.lk` and `admin.nomnom.lk` are healthy.
- Privacy, terms, support, and deletion pages are publicly reachable.
- Production data and R2 images are verified.
- Backups and restoration are tested.

### Phase 3: Play and Signing Setup

Create and verify the Play developer account, create the app, configure Play App
Signing, generate the upload key, update Firebase fingerprints, and upload the
first internal build.

**Exit criteria:**

- A production-signed API 36 AAB is installed through Play Internal Testing.
- Google Sign-In works with the Play signing certificate.
- Production API, FCM, SSE, images, and account deletion work in the
  Play-installed build.

### Phase 4: Internal Quality Gate

Test the Play-installed build before starting the closed-test clock.

Required scenarios:

- Email registration and verification
- Google Sign-In
- Logout and account switching
- Account deletion request and cancellation
- FCM foreground, background, terminated, denied, and tap behavior
- Favorites, search, banners, SSE, and offline caches
- Avatar camera/gallery upload
- Cold backend behavior and token refresh
- Android 16, representative older Android versions, dark mode, and text scaling
- Play pre-launch report findings

**Exit criteria:**

- No known launch-blocking crash, ANR, authentication, privacy, or data-loss
  defect remains.

### Phase 5: Mandatory Closed Test

1. Invite 14 to 16 reliable testers.
2. Keep at least 12 opted in continuously for 14 complete days.
3. Keep a dated tester roster and feedback log.
4. Give testers documented scenarios rather than asking only for general use.
5. Upload fixes with incremented version codes when necessary.
6. Monitor Sentry, Play Vitals, API errors, FCM failures, and VPS resources.
7. Keep at least 12 testers enrolled until production access is approved.

**Exit criteria:**

- Google recognizes the continuous testing requirement as complete.
- Tester feedback and resulting changes are documented.
- The release candidate is stable and policy declarations are complete.

### Phase 6: Production Access and Rollout

1. Apply for production access immediately after the closed-test requirement.
2. Submit accurate testing, feedback, and remediation information.
3. Complete Data Safety, App Content, content rating, target audience, app
   access, support, and deletion declarations.
4. Promote the exact closed-tested AAB whenever possible.
5. Start with a 10 percent staged rollout.
6. Increase to 25, 50, and 100 percent only when Play Vitals, Sentry,
   authentication, FCM, and API health remain acceptable.
7. Keep an incremented-version hotfix AAB path ready.

---

## Versioning and Artifact Rules

- Keep `1.0.0` as the initial public version unless product changes require a
  new version name.
- Increment the Android version code for every newly uploaded artifact.
- Promote the same artifact between tracks instead of rebuilding it.
- Never use mutable `latest` artifacts for a release decision.
- Retain the AAB, checksums, mapping file, symbols, source SHA, API endpoint,
  Flutter version, and build logs for every candidate.
- Never commit keystores, passwords, API secrets, Sentry auth tokens, or Play
  service-account credentials.

---

## Data Safety Preparation

Audit the actual production behavior before completing Play's form. Expected
data categories include:

- Name and email address
- Optional phone number
- Optional profile photo
- User ID and Firebase UID
- Favorites and notification interactions
- Device or app identifiers used for FCM
- Authentication and refresh credentials
- Crash reports, diagnostics, and limited app context sent to Sentry

Do not declare location, contacts, SMS, broad storage access, or advertising ID
unless the final release actually collects or uses them. Sponsored content must
be assessed separately from ad-SDK collection.

---

## Rollback and Incident Preparation

- A Play release cannot be rolled back to a lower version code; prepare a new
  higher-version hotfix instead.
- Use staged rollout halt controls for mobile incidents.
- Keep the previous backend image and database backup available.
- Maintain compatibility between the released mobile API contract and at least
  one prior mobile version.
- Do not shut down Render until Contabo, backups, and the Play test build are
  verified.
- Document support escalation for login, deletion, notifications, and payment
  or restaurant-content complaints.

---

## Critical Path

```text
Free engineering readiness
        |
        v
Domain and VPS deployment
        |
        v
Play account and production signing
        |
        v
Play Internal Testing
        |
        v
12 testers for 14 continuous days
        |
        v
Production-access review
        |
        v
Staged Google Play rollout
```

The paid purchases can be deferred until Phase 1 is complete. Once purchases
begin, allow approximately five to seven weeks for setup, internal validation,
the mandatory closed test, production-access review, and staged rollout.

---

## Immediate Next Work

Start with the tasks that have no monetary dependency:

1. Upgrade Flutter and Android to API 36.
2. Harden release signing and API endpoint validation.
3. Implement the 30-day account-deletion lifecycle.
4. Fix logout and cross-account cache isolation.
5. Draft privacy, terms, support, and deletion content.
6. Add Sentry mobile monitoring with PII scrubbing.
7. Prepare store listing text and visual assets.
8. Expand mobile tests and add API 36 release builds to CI.
