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

# Determine source root (works both in Xcode and standalone)
if [ -z "${SOURCE_ROOT}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SOURCE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
fi

# Calculate build number from git commit count
BUILD_NUMBER=$(git -C "${SOURCE_ROOT}" rev-list --count HEAD 2>/dev/null || echo "1")

echo "🔢 Auto Build Number: ${BUILD_NUMBER} (from ${SOURCE_ROOT})"

# When running in Xcode build phase, update the Info.plist
if [ -n "${TARGET_BUILD_DIR}" ] && [ -n "${INFOPLIST_PATH}" ]; then
    PLIST_PATH="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

    # Wait for plist to be copied (may not exist yet early in build)
    if [ -f "${PLIST_PATH}" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER}" "${PLIST_PATH}" 2>/dev/null || true
        echo "✅ Updated ${INFOPLIST_PATH} CFBundleVersion to ${BUILD_NUMBER}"
    else
        echo "⏳ Info.plist not yet available at ${PLIST_PATH}"
    fi
else
    # Running standalone - update project.pbxproj CURRENT_PROJECT_VERSION
    PROJECT_FILE="${SOURCE_ROOT}/Ritualist.xcodeproj/project.pbxproj"

    if [ -f "${PROJECT_FILE}" ]; then
        # Update all occurrences of CURRENT_PROJECT_VERSION
        sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = ${BUILD_NUMBER};/g" "${PROJECT_FILE}"
        echo "✅ Updated project.pbxproj CURRENT_PROJECT_VERSION to ${BUILD_NUMBER}"
    fi
fi
