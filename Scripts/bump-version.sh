#!/bin/bash
#
# bump-version.sh
#
# Bump version number for Ritualist app and RitualistCore package.
# Uses semantic versioning: MAJOR.MINOR.PATCH
#
# Usage: ./Scripts/bump-version.sh [major|minor|patch]
# Example: ./Scripts/bump-version.sh minor  # 0.1.0 -> 0.2.0
#

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERSION_FILE="${REPO_ROOT}/VERSION"
CHANGELOG="${REPO_ROOT}/CHANGELOG.md"

# Check for required argument
if [ $# -eq 0 ]; then
    echo "Error: Version bump type required"
    echo "Usage: $0 [major|minor|patch]"
    echo ""
    echo "Examples:"
    echo "  $0 patch   # 0.1.0 -> 0.1.1 (bug fixes)"
    echo "  $0 minor   # 0.1.0 -> 0.2.0 (new features)"
    echo "  $0 major   # 0.1.0 -> 1.0.0 (breaking changes)"
    exit 1
fi

BUMP_TYPE=$1

# Validate bump type
if [[ ! "$BUMP_TYPE" =~ ^(major|minor|patch)$ ]]; then
    echo "Error: Invalid bump type '$BUMP_TYPE'. Must be major, minor, or patch."
    exit 1
fi

# Read current version
if [ ! -f "$VERSION_FILE" ]; then
    echo "Error: VERSION file not found at $VERSION_FILE"
    exit 1
fi

CURRENT_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
echo "Current version: $CURRENT_VERSION"

# Parse version components
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Bump version based on type
case $BUMP_TYPE in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
echo "New version: $NEW_VERSION"

# Confirm with user
read -p "Bump version from $CURRENT_VERSION to $NEW_VERSION? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Version bump cancelled"
    exit 0
fi

# Update VERSION file
echo "$NEW_VERSION" > "$VERSION_FILE"
echo "✓ Updated VERSION file"

# Update RitualistCore VERSION file
CORE_VERSION_FILE="${REPO_ROOT}/RitualistCore/VERSION"
echo "$NEW_VERSION" > "$CORE_VERSION_FILE"
echo "✓ Updated RitualistCore/VERSION file"

# Update Package.swift comment
PACKAGE_SWIFT="${REPO_ROOT}/RitualistCore/Package.swift"
if [ -f "$PACKAGE_SWIFT" ]; then
    # Update or add version comment at top of file
    if grep -q "// Version:" "$PACKAGE_SWIFT"; then
        sed -i '' "s|// Version: .*|// Version: $NEW_VERSION|" "$PACKAGE_SWIFT"
    else
        # Add version comment after the initial comment block
        sed -i '' "1a\\
// Version: $NEW_VERSION\\
" "$PACKAGE_SWIFT"
    fi
    echo "✓ Updated Package.swift version comment"
fi

# Update Xcode project MARKETING_VERSION
PROJECT_FILE="${REPO_ROOT}/Ritualist.xcodeproj/project.pbxproj"
if [ -f "$PROJECT_FILE" ]; then
    sed -i '' "s/MARKETING_VERSION = .*/MARKETING_VERSION = $NEW_VERSION;/" "$PROJECT_FILE"
    echo "✓ Updated Xcode project MARKETING_VERSION"
fi

# Prepare CHANGELOG entry
TODAY=$(date +%Y-%m-%d)
CHANGELOG_ENTRY="## [$NEW_VERSION] - $TODAY

### Added
-

### Changed
-

### Fixed
-

"

# Update CHANGELOG.md
if [ -f "$CHANGELOG" ]; then
    # Insert new version after [Unreleased] section
    awk -v entry="$CHANGELOG_ENTRY" '
        /^## \[Unreleased\]/ { print; print ""; print entry; next }
        { print }
    ' "$CHANGELOG" > "${CHANGELOG}.tmp" && mv "${CHANGELOG}.tmp" "$CHANGELOG"
    echo "✓ Added entry to CHANGELOG.md"
    echo ""
    echo "⚠️  Please edit CHANGELOG.md to add release notes"
fi

# Create git commit
echo ""
echo "Creating git commit..."
git add "$VERSION_FILE" "$CORE_VERSION_FILE" "$PACKAGE_SWIFT" "$PROJECT_FILE" "$CHANGELOG"
git commit -m "chore: bump version to $NEW_VERSION

- Updated VERSION files
- Updated Package.swift version comment
- Updated Xcode project MARKETING_VERSION
- Added CHANGELOG entry for $NEW_VERSION
"

echo "✓ Git commit created"
echo ""
echo "Next steps:"
echo "1. Edit CHANGELOG.md to add release notes"
echo "2. Amend the commit: git commit --amend"
echo "3. Create tag: git tag -a v$NEW_VERSION -m \"Release $NEW_VERSION\""
echo "4. Push: git push && git push --tags"
