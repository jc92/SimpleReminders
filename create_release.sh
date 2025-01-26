#!/bin/bash

# Check if version is provided
if [ -z "$1" ]; then
    echo "Please provide a version number (e.g., 0.1.0-beta)"
    exit 1
fi

VERSION="v$1"

# Update version in Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $1" Sources/SimpleReminders/Info.plist

# Update version in create_dmg.sh
sed -i '' "s/VERSION=.*/VERSION=\"$1\"/" create_dmg.sh

# Commit the version changes
git add Sources/SimpleReminders/Info.plist create_dmg.sh
git commit -m "Bump version to $VERSION"

# Create and push the tag
git tag -a "$VERSION" -m "Release $VERSION"
git push origin main "$VERSION"

echo "Release $VERSION initiated. GitHub Actions will build and publish the release."
echo "You can monitor the progress at: https://github.com/jc92/SimpleReminders/actions"
