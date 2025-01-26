#!/bin/bash

# Set variables
APP_NAME="SimpleReminders"
VERSION="0.1.2-beta"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

# Build for production
swift build -c release -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.15"

# Create app bundle structure
rm -rf "${APP_NAME}.app"
mkdir -p "${APP_NAME}.app/Contents/MacOS"
mkdir -p "${APP_NAME}.app/Contents/Resources"

# Copy executable
cp .build/release/SimpleReminders "${APP_NAME}.app/Contents/MacOS/"

# Copy Info.plist
cp Sources/SimpleReminders/Info.plist "${APP_NAME}.app/Contents/"

# Sign the app with hardened runtime and entitlements
codesign --force --options runtime --sign "Developer ID Application" \
  --entitlements "SimpleReminders.entitlements" \
  "${APP_NAME}.app"

# Create DMG
./create_dmg.sh

# Sign the DMG
codesign --force --sign "Developer ID Application" "${DMG_NAME}"

echo "App and DMG have been signed. Now you can notarize them with:"
echo "xcrun notarytool submit ${DMG_NAME} --keychain-profile \"AC_PASSWORD\" --wait"
