# Phase 5: Flutter and Android API 36

**Date:** 2026-07-23
**Branch:** `phase/P54-secure-admin-sessions`
**Status:** Implemented, verified, pending user sign-off

## Summary

Upgraded Flutter from 3.29.3 to 3.44.7 (latest stable, Dart 3.12.2), restored
native API 36 targeting, added multi-ABI support for older 32-bit devices and
emulators, and replaced disabled text scaling with a bounded accessible scaler.

## Changes

### Flutter upgrade (3.29.3 → 3.44.7)

- Dart 3.7.2 → 3.12.2
- Native `compileSdkVersion` / `targetSdkVersion` now returns 36 (no manual override needed)
- Reverted manual `compileSdk = 36` / `targetSdk = 36` overrides — `flutter.compileSdkVersion` and `flutter.targetSdkVersion` now natively provide API 36

### Android toolchain (`android/app/build.gradle.kts`, `android/settings.gradle.kts`, `android/gradle/wrapper/gradle-wrapper.properties`)

| Setting | Before | After | Reason |
|---|---|---|---|
| Flutter | 3.29.3 | 3.44.7 | Latest stable |
| AGP | 8.7.0 | 8.11.1 | Flutter 3.44 requires ≥8.11.1 |
| Kotlin | 1.8.22 | 2.2.20 | AGP 8.11 + Flutter 3.44 require ≥2.2.20 |
| Gradle | 8.10.2 | 8.13.0 | AGP 8.11.1 minimum |
| JDK target | 11 | 17 | AGP 8.11 + Kotlin 2.2 require JDK 17 |
| NDK | 27.0.12077973 | 28.2.13676358 | Required by integration_test plugin |
| desugar | 2.1.4 | 2.1.5 | Latest compatible version |
| Google Services | 4.4.2 | 4.4.3 | AGP 8.11 compatibility |
| minSdk | 23 | 23 (effective: 24) | Declared 23; Firebase libs merge to 24 |

### Multi-ABI support (`android/app/build.gradle.kts`)

```kotlin
ndk {
    abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
}
```

APK/AAB now contains native code for:
- `arm64-v8a` — all modern Android phones (Pixel 3+, Samsung, etc.)
- `armeabi-v7a` — older 32-bit devices
- `x86_64` — emulators and ChromeOS

### Accessible text scaling (`lib/main.dart`)

```dart
final textScaler = MediaQuery.textScalerOf(context)
    .clamp(minScaleFactor: 0.75, maxScaleFactor: 1.5);
```

Replaced `TextScaler.noScaling` with `MediaQuery.textScalerOf` + `TextScaler.clamp` (Flutter 3.24+ API).

### Flutter 3.44 API compatibility

- `CupertinoPageTransitionsBuilder` removed → removed iOS entry from `pageTransitionsTheme` (Flutter uses default transitions)
- `Switch.activeColor` deprecated → replaced with `activeThumbColor` in `notification_prefs_screen.dart` and `profile_screen.dart`
- `intl` pinned to `^0.20.0` (up from `^0.19.0`) to resolve `flutter_localizations` SDK pin
- `stagger_item_test.dart`: fixed `find.byType(FadeTransition)` → `.first` (Flutter 3.44 adds more internal FadeTransitions)

### Gradle wrapper committed (`android/.gitignore`)

- Removed `gradle-wrapper.jar` from `.gitignore` for deterministic builds.

## What was NOT changed

- All Dart/pub dependency versions (except `intl` constraint bump required by SDK)
- Firebase Auth, FCM, Google Sign-In integration code
- Backend, admin dashboard, all E2E tests
- `minSdk = 23` (declared; effective 24 due to Firebase lib manifests)
- Release signing config, ProGuard, resource shrinking
- `flutter_launcher_icons`, `flutter_native_splash` configs

## Verification

| Check | Result |
|---|---|
| Release AAB | 63.0MB, clean build |
| Release APK | 63.5MB, clean build |
| `targetSdkVersion` in manifest | 36 |
| `compileSdkVersion` in manifest | 36 |
| `sdkVersion` (minSdk) in manifest | 24 (effective from Firebase) |
| `native-code` ABIs | arm64-v8a, armeabi-v7a, x86_64 |
| `package` | `com.nomnomlk.nomnom_lk` |
| `flutter analyze` | 37 pre-existing info findings (unchanged) |
| `flutter test` | 20/20 passing |
| Backend tests (race) | All passing |
| Admin unit tests | 11/11 passing |

## Device coverage

| Device | API level | Supported |
|---|---|---|
| Pixel 3 | 28+ | arm64-v8a |
| Modern phones (2020+) | 29+ | arm64-v8a |
| Older 32-bit phones | 24+ | armeabi-v7a |
| Android emulators | 24+ | x86_64, arm64-v8a |
| ChromeOS | 24+ | x86_64 |
