#!/bin/bash
# =============================================================
# upload.sh — Upload IPA to App Store Connect via altool
# Requires: APP_APPLE_ID and APP_PASSWORD set as env vars
#   export APP_APPLE_ID="you@email.com"
#   export APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"  (App-Specific Password)
# =============================================================

set -e

APP_NAME="ClubhouseResident"
IPA_PATH="./build/export/${APP_NAME}.ipa"

if [ -z "$APP_APPLE_ID" ] || [ -z "$APP_PASSWORD" ]; then
  echo "❌ Error: Set APP_APPLE_ID and APP_PASSWORD environment variables first."
  echo "   Generate an App-Specific Password at: https://appleid.apple.com"
  exit 1
fi

echo "==> Validating IPA..."
xcrun altool --validate-app \
  -f "${IPA_PATH}" \
  -t ios \
  -u "${APP_APPLE_ID}" \
  -p "${APP_PASSWORD}" \
  --output-format xml

echo "==> Uploading to App Store Connect..."
xcrun altool --upload-app \
  -f "${IPA_PATH}" \
  -t ios \
  -u "${APP_APPLE_ID}" \
  -p "${APP_PASSWORD}" \
  --output-format xml

echo ""
echo "✅ Upload complete! Check App Store Connect for processing status."
echo "   https://appstoreconnect.apple.com"
