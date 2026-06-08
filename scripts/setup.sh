#!/bin/bash
set -e

echo "==> Checking Xcode..."
xcode-select --print-path
xcodebuild -version

echo "==> Checking XcodeGen..."
if ! command -v xcodegen >/dev/null 2>&1; then
    echo "ERROR: XcodeGen is not installed."
    exit 1
fi

echo "==> Generating Xcode project..."
xcodegen generate

echo "✅ Setup complete."
echo "Run: open ClubhouseResident.xcodeproj"