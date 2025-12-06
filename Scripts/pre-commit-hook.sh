#!/bin/bash
# Pre-commit hook for Ritualist
# - Validates strings if Localizable.xcstrings was modified
# - Auto-updates build number using monotonically increasing BUILD_NUMBER file
#
# Installation:
#   cp Scripts/pre-commit-hook.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
#
# This approach ensures build numbers NEVER decrease, even with parallel branches.
# The BUILD_NUMBER file is the single source of truth.
#
# IMPORTANT: This hook automatically modifies and stages files during commit!
# On every commit, the following files are updated and added to your commit:
#   - BUILD_NUMBER (incremented by 1)
#   - Ritualist.xcodeproj/project.pbxproj (CURRENT_PROJECT_VERSION updated)
# This is intentional behavior to ensure every commit has a unique build number.

REPO_ROOT="$(git rev-parse --show-toplevel)"

# ============================================
# 1. String validation (if strings file changed)
# ============================================
if git diff --cached --name-only | grep -q "Localizable.xcstrings"; then
    echo "🔍 Validating strings before commit..."

    # Run the validation script
    if swift Scripts/validate_strings.swift > /tmp/string_validation.log 2>&1; then
        echo "✅ String validation passed!"
        rm -f /tmp/string_validation.log
        rm -f "${REPO_ROOT}/string_validation_report.txt"
    else
        echo "❌ String validation FAILED!"
        echo ""
        cat /tmp/string_validation.log
        echo ""
        echo "Fix the validation errors before committing."
        echo "Run: swift Scripts/validate_strings.swift"
        rm -f /tmp/string_validation.log
        rm -f "${REPO_ROOT}/string_validation_report.txt"
        exit 1
    fi
fi

# ============================================
# 2. Auto-update build number (monotonically increasing)
# ============================================
# Strategy: Use BUILD_NUMBER file as source of truth
# - Always increment from file, never from git commit count
# - This prevents build number decreases across branches
# - BUILD_NUMBER file is committed, ensuring all branches see latest

BUILD_NUMBER_FILE="${REPO_ROOT}/BUILD_NUMBER"
PROJECT_FILE="${REPO_ROOT}/Ritualist.xcodeproj/project.pbxproj"

if [ -f "${BUILD_NUMBER_FILE}" ] && [ -f "${PROJECT_FILE}" ]; then
    # Read current build number from file
    CURRENT_BUILD=$(cat "${BUILD_NUMBER_FILE}" | tr -d '[:space:]')

    # Increment for new commit
    NEW_BUILD_NUMBER=$((CURRENT_BUILD + 1))

    # Update BUILD_NUMBER file
    echo "${NEW_BUILD_NUMBER}" > "${BUILD_NUMBER_FILE}"

    # Update all CURRENT_PROJECT_VERSION entries in Xcode project
    # Use portable sed syntax (works on both macOS and Linux)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = ${NEW_BUILD_NUMBER};/g" "${PROJECT_FILE}"
    else
        sed -i "s/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = ${NEW_BUILD_NUMBER};/g" "${PROJECT_FILE}"
    fi

    # Stage both files so they're included in the commit
    git add "${BUILD_NUMBER_FILE}"
    git add "${PROJECT_FILE}"

    echo "📦 Build number: ${NEW_BUILD_NUMBER}"
else
    if [ ! -f "${BUILD_NUMBER_FILE}" ]; then
        echo "⚠️  BUILD_NUMBER file not found - creating with git commit count"
        COMMIT_COUNT=$(git rev-list --count HEAD 2>/dev/null || echo "0")
        echo "${COMMIT_COUNT}" > "${BUILD_NUMBER_FILE}"
        git add "${BUILD_NUMBER_FILE}"
        echo "📦 Build number: ${COMMIT_COUNT} (initialized from git history)"
    fi
fi

exit 0
