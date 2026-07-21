# P43 — Mobile App Release Plan

## Goal
Release NomNom LK as a live application on Google Play Store (Android) and Apple App Store (iOS). This plan covers all remaining blockers, build configuration, store submission, and post-launch tasks.

---

## Current Readiness Summary

| Area | Status | Details |
|------|--------|---------|
| App features | ✅ Complete | 14 screens, 13 services, 7 providers, 3 languages |
| UI/UX audit | ✅ Complete | 44 issues fixed |
| Backend | ✅ Running | Go + Gin, all endpoints functional |
| Admin dashboard | ✅ Running | Next.js, 48 E2E tests passing |
| CI pipeline | ✅ Green | All 4 jobs passing |
| Android release signing | ❌ Not configured | Uses debug keys |
| Assets in pubspec | ❌ Not declared | `app_icon.png` won't bundle |
| iOS push notifications | ❌ Blocked | Requires paid Apple Developer account |
| iOS JIT issue | ❌ Blocked | Flutter 3.29.3 incompatible with iOS 26.5+ |
| Google Sign-In | ❌ Broken | Missing SHA-1 fingerprint |
| Release keystore | ❌ Missing | No `.jks` or `key.properties` |
| App Store placeholder | ❌ `YOUR_APP_STORE_ID` | iOS store links broken |
| Production API endpoint | ❌ Hardcoded to localhost | Needs Render URL |
| Render deployment | ⚠️ Blueprint exists | Not deployed yet |

---

## Phase 1 — Android Release Signing (Critical)

**Goal:** Enable release APK/AAB builds signed with a production keystore.

### Step 1.1: Generate Release Keystore

```bash
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -alias upload \
  -dname "CN=NomNom LK, OU=Development, O=NomNom, L=Colombo, ST=Western, C=LK"
```

Store securely outside repo (e.g., `~/.keystores/upload-keystore.jks`).

### Step 1.2: Create `android/key.properties`

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path-to>/upload-keystore.jks
```

### Step 1.3: Update `android/app/build.gradle.kts`

Read `key.properties` in the `android` block and configure release signing:

```kotlin
android {
    // ... existing config ...

    signingConfigs {
        create("release") {
            val keyProperties = java.util.Properties()
            val keyFile = rootProject.file("key.properties")
            if (keyFile.exists()) {
                keyProperties.load(keyFile.inputStream())
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### Step 1.4: Add ProGuard Rules

Create `android/app/proguard-rules.pro`:

```
-keep class com.nomnomlk.nomnom_lk.** { *; }
-dontwarn com.google.firebase.**
-dontwarn io.flutter.embedding.**
```

### Step 1.5: Add `android/key.properties` to `.gitignore`

```gitignore
key.properties
*.keystore
*.jks
```

### Verification

```bash
flutter build apk --release
flutter build appbundle --release
```

APK path: `build/app/outputs/flutter-apk/app-release.apk`
AAB path: `build/app/outputs/bundle/release/app-release.aab`

---

## Phase 2 — Fix Asset Declaration in pubspec.yaml

**Goal:** Ensure app icon, sample images, and localization files are bundled.

### Step 2.1: Add `assets:` section to `pubspec.yaml`

```yaml
flutter:
  generate: true
  uses-material-design: true
  assets:
    - assets/app_icon.png
    - assets/samples/
```

### Verification

```bash
flutter build apk --release
# Verify icon appears in the built APK
```

---

## Phase 3 — Production API Endpoint

**Goal:** Point Flutter app to the deployed backend on Render.

### Step 3.1: Update `lib/core/api_config.dart`

The current default is `http://10.0.2.2:8080/api/v1` (Android emulator). For production, use compile-time env var:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://nomnom-lk-api.onrender.com/api/v1
```

### Step 3.2: Create Build Script

Create `scripts/build-android-release.sh`:

```bash
#!/bin/bash
set -e

API_URL="${API_BASE_URL:-https://nomnom-lk-api.onrender.com/api/v1}"

echo "Building Android release with API: $API_URL"

flutter build appbundle --release \
  --dart-define=API_BASE_URL="$API_URL"

flutter build apk --release \
  --dart-define=API_BASE_URL="$API_URL"

echo "Build complete."
echo "AAB: build/app/outputs/bundle/release/app-release.aab"
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
```

### Step 3.3: Create `scripts/build-ios-release.sh`

```bash
#!/bin/bash
set -e

API_URL="${API_BASE_URL:-https://nomnom-lk-api.onrender.com/api/v1}"

echo "Building iOS release with API: $API_URL"

flutter build ipa --release \
  --dart-define=API_BASE_URL="$API_URL"

echo "Build complete. Archive at: build/ios/ipa/"
```

---

## Phase 4 — Fix Placeholder Values

**Goal:** Replace all placeholder constants with real values.

### Step 4.1: `lib/core/app_store.dart`

Replace `_iosId = 'YOUR_APP_STORE_ID'` with `''` (empty string) for initial release. After App Store submission, update with real ID.

### Step 4.2: `android/app/build.gradle.kts`

Remove the TODO comment on line 26:
```kotlin
applicationId = "com.nomnomlk.nomnom_lk"
```

### Step 4.3: `ios/Runner/Info.plist`

Fix display name casing:
```xml
<key>CFBundleName</key>
<string>NomNom LK</string>
```

---

## Phase 5 — Google Sign-In Fix (Android)

**Goal:** Enable Google Sign-In on Android.

### Step 5.1: Get SHA-1 Fingerprint

```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android -keypass android | grep SHA1
```

### Step 5.2: Add to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/) → Project Settings
2. Select Android app (`com.nomnomlk.nomnom_lk`)
3. Add SHA-1 fingerprint
4. Download updated `google-services.json`
5. Replace `android/app/google-services.json`

### Step 5.3: Verify Firebase Authentication

1. Firebase Console → Authentication → Sign-in method
2. Ensure "Google" is enabled
3. Add support email if not set

### Verification

```bash
flutter run --release
# Test Google Sign-In on physical Android device or emulator with Google Play Services
```

---

## Phase 6 — Native Splash Screen

**Goal:** Eliminate white flash on cold start.

### Step 6.1: Add `flutter_native_splash` Dependency

Add to `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_native_splash: ^2.4.3

flutter_native_splash:
  color: "#FFB23F"
  image: assets/app_icon.png
  android_12:
    color: "#FFB23F"
    image: assets/app_icon.png
  ios: true
```

### Step 6.2: Generate Splash Screen

```bash
dart run flutter_native_splash:create
```

### Verification

```bash
flutter run --release
# Cold start should show curry-orange splash, no white flash
```

---

## Phase 7 — Deploy Backend to Render (Prerequisite)

**Goal:** Get the backend running in production so the Flutter app has an API.

### Step 7.1: Follow P38 Render Deployment Plan

Refer to `plans/p38-render-deploy.md` for full steps:
1. Ensure `DATABASE_URL`/`REDIS_URL` parsing works (P37)
2. Connect repo to Render Dashboard
3. Fill in sync:false env vars
4. Upload firebase-credentials.json
5. Verify health checks

### Step 7.2: Verify Backend Health

```bash
curl https://nomnom-lk-api.onrender.com/health
# Should return: {"status":"ok","database":"connected","redis":"connected"}
```

### Step 7.3: Verify API from Flutter

```bash
flutter run --dart-define=API_BASE_URL=https://nomnom-lk-api.onrender.com/api/v1
# Test login, browse offers, favorites
```

---

## Phase 8 — Android Play Store Submission

**Goal:** Publish to Google Play Store.

### Step 8.1: Prerequisites

- [ ] Google Play Developer account ($25 one-time)
- [ ] Release AAB built (Phase 1)
- [ ] App icon (1024×1024) ready
- [ ] Feature graphic (1024×500) created
- [ ] Screenshots (phone + tablet) taken
- [ ] Privacy policy page hosted (nomnom.lk/privacy)

### Step 8.2: Store Listing

| Field | Value |
|-------|-------|
| App name | NomNom LK |
| Short description | Discover the best food offers in Sri Lanka |
| Full description | Find exclusive deals from top restaurants across Sri Lanka. Browse offers, save favorites, and get notified about new deals in your area. |
| Category | Food & Drink |
| Content rating | Everyone |
| Contact email | support@nomnom.lk |
| Privacy policy | https://nomnom.lk/privacy |

### Step 8.3: Upload & Submit

1. Go to [Google Play Console](https://play.google.com/console)
2. Create new app → Choose default language → App name: "NomNom LK"
3. Complete store listing (description, screenshots, feature graphic)
4. Upload `app-release.aab` to Internal Testing track
5. Complete content rating questionnaire
6. Set pricing (Free) and distribution
7. Promote to Production track
8. Submit for review

### Step 8.4: Review Timeline

- Initial review: 1–7 days (first submission)
- Subsequent updates: hours to 2 days

---

## Phase 9 — iOS App Store Submission (Future)

**Goal:** Publish to Apple App Store. **Blocked** until Flutter upgrade + Apple Developer account.

### Prerequisites

- [ ] Upgrade Flutter to fix JIT/iOS 26.5+ incompatibility
- [ ] Apple Developer account ($99/year)
- [ ] Xcode with latest iOS SDK
- [ ] Physical iOS device for testing

### Step 9.1: Xcode Configuration

1. Open `ios/Runner.xcworkspace` in Xcode
2. Set Development Team in Signing & Capabilities
3. Configure Bundle Identifier: `com.nomnomlk.nomnom-lk`
4. Enable Push Notifications capability
5. Add APNs entitlement for push notifications

### Step 9.2: Build & Archive

```bash
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://nomnom-lk-api.onrender.com/api/v1
```

Open in Xcode → Product → Archive → Upload to App Store Connect.

### Step 9.3: App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Create new app → NomNom LK
3. Complete store listing, screenshots, privacy policy
4. Submit for App Review

### Review Timeline

- Initial review: 1–3 days
- Rejection common on first submission — be prepared for feedback

---

## Phase 10 — Post-Launch Monitoring

**Goal:** Ensure app stability after release.

### Step 10.1: Sentry Integration

Backend already has Sentry. Add Flutter Sentry:

```yaml
dependencies:
  sentry_flutter: ^8.0.0
```

```dart
// main.dart
await SentryFlutter.init(
  (options) {
    options.dsn = 'YOUR_SENTRY_DSN';
  },
  appRunner: () => runApp(NomNomBootstrap(...)),
);
```

### Step 10.2: Analytics

Consider adding Firebase Analytics or PostHog for user behavior tracking.

### Step 10.3: Crash Reporting

Verify Firebase Crashlytics is enabled in Firebase Console → Crashlytics.

### Step 10.4: Monitoring Checklist

- [ ] Backend health check every 5 min (Render auto-restart)
- [ ] Sentry alerts for Flutter crashes
- [ ] Play Console crash reports
- [ ] API response time monitoring
- [ ] Database connection pool monitoring

---

## Phase 11 — Version Management

### Semantic Versioning

| Version | Meaning |
|---------|---------|
| `1.0.0+1` | Initial Play Store release |
| `1.0.1+2` | Bug fix |
| `1.1.0+3` | New feature |
| `2.0.0+4` | Breaking change |

### Update Version in

1. `pubspec.yaml` → `version: 1.0.0+1` (versionName + versionCode)
2. `android/app/build.gradle.kts` → reads from pubspec
3. `ios/Runner/Info.plist` → `CFBundleShortVersionString` + `CFBundleVersion`

### Release Process

```bash
# Bump version
# Edit pubspec.yaml: version: 1.0.1+2
# Commit, push, CI builds artifacts

# Android
flutter build appbundle --release --dart-define=API_BASE_URL=https://nomnom-lk-api.onrender.com/api/v1

# iOS (when ready)
flutter build ipa --release --dart-define=API_BASE_URL=https://nomnom-lk-api.onrender.com/api/v1
```

---

## Execution Order & Dependencies

```
NEW ORDER (Backend First):
Phase 7 (Render Deploy)     ──► Phase 1 (Android Signing)
                                   │
Phase 2 (Assets)            ──┤
Phase 4 (Placeholders)      ──┼──► Phase 8 (Play Store Submit)
Phase 5 (Google Sign-In)    ──┤
Phase 6 (Splash Screen)     ──┘
                               │
Phase 3 (API Endpoint)      ──┘
                               │
Phase 9 (iOS)               ──┘ (Future — needs Flutter upgrade)
Phase 10 (Monitoring)       ──┘ (Post-launch)
Phase 11 (Versioning)       ──┘ (Ongoing)
```

**Critical path:** Phase 7 → Phase 1 → Phase 2 → Phase 3 → Phase 8

**Estimated timeline:**
- **Backend on Render:** 1 day (follow P38)
- **Android Play Store:** 2–3 days (signing + build + submit)
- **iOS App Store:** 1–2 weeks (Flutter upgrade + Apple account + review)

**Why backend first?**
- Get API live for testing immediately
- Flutter app can point to production API early
- Admin dashboard can connect to hosted backend
- Validates infrastructure before app store submission

---

## Files to Modify

| File | Changes |
|------|---------|
| `android/app/build.gradle.kts` | Add release signing config, ProGuard, remove TODO |
| `android/key.properties` | **NEW** — Keystore credentials (gitignored) |
| `android/app/proguard-rules.pro` | **NEW** — ProGuard rules |
| `pubspec.yaml` | Add `assets:` section, `flutter_native_splash` |
| `lib/core/app_store.dart` | Replace `YOUR_APP_STORE_ID` with empty string |
| `lib/core/api_config.dart` | No changes needed (compile-time `--dart-define` works) |
| `ios/Runner/Info.plist` | Fix display name casing |
| `scripts/build-android-release.sh` | **NEW** — Release build script |
| `scripts/build-ios-release.sh` | **NEW** — iOS release build script |

---

## Success Criteria

| Criterion | Target |
|-----------|--------|
| Android AAB builds without errors | ✅ |
| APK installs on physical device | ✅ |
| Google Sign-In works | ✅ |
| App icon renders correctly | ✅ |
| Splash screen shows on cold start | ✅ |
| API connects to Render backend | ✅ |
| Play Store listing approved | ✅ |
| App visible in Play Store search | ✅ |
| Push notifications received | ✅ |
| No crashes in first 24 hours | ✅ |
