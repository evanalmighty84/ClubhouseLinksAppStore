#!/bin/bash
set -e
set -o pipefail

APP_NAME="ClubhouseResident"
SCHEME="ClubhouseResident"
PROJECT="${APP_NAME}.xcodeproj"
ARCHIVE_PATH="./build/${APP_NAME}.xcarchive"
EXPORT_PATH="./build/export"
EXPORT_OPTIONS="./scripts/ExportOptions.plist"

echo "==> Cleaning build folder..."
rm -rf ./build
mkdir -p ./build

echo "==> Building & Archiving..."
xcodebuild \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "${ARCHIVE_PATH}" \
  archive

echo "==> Exporting IPA..."
xcodebuild \
  -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_PATH}" \
  -exportOptionsPlist "${EXPORT_OPTIONS}"

echo ""
echo "✅ IPA ready at: ${EXPORT_PATH}/${APP_NAME}.ipa"