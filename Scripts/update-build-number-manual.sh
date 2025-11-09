#!/bin/bash
#
# update-build-number-manual.sh
#
# Manually update CURRENT_PROJECT_VERSION in project.pbxproj
# Use this when you want to update the build number outside of Xcode builds
#
# Usage: ./Scripts/update-build-number-manual.sh [build_number]
#        If no build number provided, uses git commit count
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_FILE="${SOURCE_ROOT}/Ritualist.xcodeproj/project.pbxproj"

# Get build number (from argument or git commit count)
if [ -n "$1" ]; then
    BUILD_NUMBER="$1"
else
    BUILD_NUMBER=$(git -C "${SOURCE_ROOT}" rev-list --count HEAD 2>/dev/null || echo "1")
fi

echo "Updating build number to: ${BUILD_NUMBER}"

# Update project.pbxproj
if [ -f "${PROJECT_FILE}" ]; then
    sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = ${BUILD_NUMBER};/g" "${PROJECT_FILE}"
    echo "SUCCESS: Updated project.pbxproj CURRENT_PROJECT_VERSION to ${BUILD_NUMBER}"
else
    echo "ERROR: project.pbxproj not found at ${PROJECT_FILE}"
    exit 1
fi

# Verify
CURRENT=$(grep "CURRENT_PROJECT_VERSION" "${PROJECT_FILE}" | head -1 | sed 's/.*= \([0-9]*\);/\1/')
echo "Verified: CURRENT_PROJECT_VERSION = ${CURRENT}"
