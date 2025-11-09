#!/bin/bash
#
# set-build-number.sh
#
# Automatically sets the build number (CFBundleVersion) based on git commit count.
# This script updates the Info.plist in the built product during Xcode build.
#
# Usage: Called automatically by Xcode build phase
#

# Determine source root (works both in Xcode and standalone)
if [ -z "${SOURCE_ROOT}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SOURCE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
fi

# Calculate build number from git commit count
BUILD_NUMBER=$(git -C "${SOURCE_ROOT}" rev-list --count HEAD 2>/dev/null || echo "1")

echo "Auto Build Number: ${BUILD_NUMBER}"

# Only update Info.plist if running in Xcode build (has TARGET_BUILD_DIR)
if [ -n "${TARGET_BUILD_DIR}" ] && [ -n "${INFOPLIST_PATH}" ]; then
    # Info.plist location in built product
    PLIST_PATH="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

    # Update CFBundleVersion in the built Info.plist
    # This runs AFTER Info.plist is processed, so we update the final output
    if [ -f "${PLIST_PATH}" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER}" "${PLIST_PATH}" 2>/dev/null || true
        echo "SUCCESS: Build number set to ${BUILD_NUMBER}"
    fi
else
    echo "INFO: Not running in Xcode build, skipping"
fi
