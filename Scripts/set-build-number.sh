#!/bin/bash
#
# set-build-number.sh
#
# Automatically sets the build number (CFBundleVersion) based on git commit count.
# This script should be run as an Xcode build phase before compilation.
#
# Usage: Called automatically by Xcode build phase
#

set -e  # Exit on error

# Calculate build number from git commit count
BUILD_NUMBER=$(git -C "${SOURCE_ROOT}" rev-list --count HEAD 2>/dev/null || echo "1")

echo "Setting build number to: ${BUILD_NUMBER}"

# Update Info.plist for the main app
if [ -f "${INFOPLIST_FILE}" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER}" "${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}" 2>/dev/null || true
fi

# Also set in project settings (CURRENT_PROJECT_VERSION)
# This ensures consistency across all targets
echo "Build number set to ${BUILD_NUMBER} (git commit count)"
