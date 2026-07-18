#!/bin/bash
set -e

API_URL="${API_BASE_URL:-https://nomnom-lk-api.onrender.com/api/v1}"

echo "=== NomNom LK Android Release Build ==="
echo "API: $API_URL"

flutter clean
flutter pub get
dart run flutter_native_splash:create

echo "Building App Bundle (Play Store)..."
flutter build appbundle --release \
  --dart-define=API_BASE_URL="$API_URL"

echo "Building APK (direct install)..."
flutter build apk --release \
  --dart-define=API_BASE_URL="$API_URL"

echo ""
echo "=== Build Complete ==="
echo "AAB: build/app/outputs/bundle/release/app-release.aab"
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
