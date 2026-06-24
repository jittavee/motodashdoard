#!/bin/bash

set -e

FIREBASE_APP_ID="1:867109877:android:7b228147d2d86979726ebc"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //')
echo "==> Version: $VERSION"

echo "==> What's new in this build? (กด Enter เพื่อจบ, พิมพ์ . แล้วกด Enter เพื่อสิ้นสุด)"
RELEASE_NOTES=""
while IFS= read -r line; do
  [[ "$line" == "." ]] && break
  RELEASE_NOTES+="$line"$'\n'
done
RELEASE_NOTES="$(echo "$RELEASE_NOTES" | sed 's/[[:space:]]*$//')"

if [[ -z "$RELEASE_NOTES" ]]; then
  RELEASE_NOTES="Build $(date '+%Y-%m-%d %H:%M')"
fi

echo "==> Flutter build APK..."
flutter build apk --release

echo "==> Uploading to Firebase App Distribution..."
firebase appdistribution:distribute "$APK_PATH" \
  --app "$FIREBASE_APP_ID" \
  --release-notes "$RELEASE_NOTES" \
  --groups "tester"

echo "==> Done! Build uploaded successfully."
