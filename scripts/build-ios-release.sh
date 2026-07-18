#!/bin/bash
set -e

API_URL="${API_BASE_URL:-https://nomnom-lk-api.onrender.com/api/v1}"

echo "=== NomNom LK iOS Release Build ==="
echo "API: $API_URL"

flutter clean
flutter pub get
dart run flutter_native_splash:create

echo "Building IPA..."
flutter build ipa --release \
  --dart-define=API_BASE_URL="$API_URL"

echo ""
echo "=== Build Complete ==="
echo "Archive: build/ios/ipa/"
echo "Open in Xcode: open build/ios/ipa/*.xcarchive"
