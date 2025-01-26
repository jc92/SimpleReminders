#!/bin/bash

# Set variables
APP_NAME="SimpleReminders"
VERSION="0.1.9-beta"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

# Build for production
swift build -c release

# Create app bundle structure
mkdir -p "${APP_NAME}.app/Contents/MacOS"
mkdir -p "${APP_NAME}.app/Contents/Resources"

# Copy executable
cp .build/release/SimpleReminders "${APP_NAME}.app/Contents/MacOS/"

# Copy Info.plist
cp Sources/SimpleReminders/Info.plist "${APP_NAME}.app/Contents/"

# Copy entitlements
cp SimpleReminders.entitlements "${APP_NAME}.app/Contents/"

# Sign the app with entitlements
codesign --force --deep --sign - --entitlements SimpleReminders.entitlements "${APP_NAME}.app"

# Create DMG
# Create a temporary directory for mounting
TEMP_DIR=$(mktemp -d)

# Create a new DMG
hdiutil create -size 50m -fs HFS+ -volname "${APP_NAME}" -o "${APP_NAME}-temp"

# Mount the DMG
hdiutil attach "${APP_NAME}-temp.dmg" -mountpoint "${TEMP_DIR}"

# Copy the app bundle to the DMG
cp -r "${APP_NAME}.app" "${TEMP_DIR}"

# Create a symbolic link to /Applications
ln -s /Applications "${TEMP_DIR}"

# Unmount the DMG
hdiutil detach "${TEMP_DIR}"

# Convert the DMG to compressed format
hdiutil convert "${APP_NAME}-temp.dmg" -format UDZO -o "${DMG_NAME}"

# Clean up
rm "${APP_NAME}-temp.dmg"
rm -rf "${TEMP_DIR}"
rm -rf "${APP_NAME}.app"

echo "DMG created successfully: ${DMG_NAME}"
