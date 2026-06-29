# Fixes Plan

## FCM Fix — Android Push Notifications Working E2E
Three fixes applied:
1. **Android google-services plugin**: Added `id("com.google.gms.google-services")` to `android/settings.gradle.kts` and `android/app/build.gradle.kts`. Without this, `Firebase.initializeApp()` silently failed and FCM tokens were generated under Google's internal project, causing `SENDER_ID_MISMATCH`.
2. **Backend FCM direct HTTP**: Replaced Firebase Admin SDK with direct HTTP to FCM v1 API using `google.CredentialsFromJSON` with `cloud-platform` scope. Added Android channel config (`nomnom_notifications`, `high` priority). Removed `initFCMClient()` and Firebase SDK dependency.
3. **One-time FCM token migration**: `_getToken()` calls `deleteToken()` + `getToken()` on first launch (tracked via `shared_preferences` flag `fcm_token_migrated`) to force a fresh token under the correct Firebase project.
- Verified: FCM v1 API returns HTTP 200. Notifications arrive on Android emulator in foreground, background, and killed states.

## Seed Data + MinIO Images Fix
- Fixed `.env` `AWS_S3_ENDPOINT` inline comment (Viper reads `# comment` as part of value)
- Removed `http://` scheme (minio-go v7.2.0 rejects fully qualified endpoints)
- Re-ran seed: 26 images uploaded, 8 restaurants + 18 offers created
- Images serve HTTP 200 from MinIO via upload proxy

## Build Fixes + Search + Favorite Button Fix
- `const` removed from `BoxDecoration`/`SizedBox` in 5 files (splash, login, register, verify_email, offer_image)
- Shimmer overflow crash fixed (`SingleChildScrollView`)
- Search isolation in providers (`_searchResults` separate from `_offers`)
- Search screen rewritten as combined Restaurants + Offers layout
- Favorite button fix: `ApiClient.post()` null/type guard for empty 201 responses (commit `8e17da1`)

## E2E Fixes (on master)
- Offer create nil `Restaurant` pointer fix (reload after create)
- `search_vector` TSVECTOR migration
- Timeline `DATE::text` cast for GORM scan

## Admin Account Created
- `namal@nomnom.lk` / `Namal@123` registered and promoted to `admin` role via `PUT /users/:id`
- Works for both mobile app and admin dashboard login

## Blocked Items
- **iOS device debug mode** — Flutter 3.29.3 incompatible with iOS 26.5 JIT. No workaround without Flutter upgrade.
- **iOS push notifications** — Requires paid Apple Developer Account ($99/yr) for APNs entitlement.
- **Google Sign-In on Android** — Not yet working. Missing SHA-1 fingerprint in Firebase Console.
