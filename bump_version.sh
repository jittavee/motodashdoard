#!/bin/bash

set -e

PUBSPEC="pubspec.yaml"

CURRENT_VERSION=$(grep '^version:' "$PUBSPEC" | sed 's/version: //')
CURRENT_NAME=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
CURRENT_BUILD=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

echo "==> Version ปัจจุบัน: $CURRENT_VERSION"
read -rp "==> ใส่ version ใหม่ (กด Enter เพื่อใช้ $CURRENT_NAME) : " NEW_NAME
NEW_NAME="${NEW_NAME:-$CURRENT_NAME}"
NEW_BUILD=$((CURRENT_BUILD + 1))
NEW_VERSION="${NEW_NAME}+${NEW_BUILD}"

sed -i '' "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC"

echo "==> Version อัปเดตเป็น: $NEW_VERSION"
