# Versioning Strategy

This document describes the versioning strategy for Ritualist app and RitualistCore package.

## Overview

Ritualist follows [Semantic Versioning 2.0.0](https://semver.org/) for both the app and the core package, using a unified versioning approach.

**Current Version:** `0.1.0`

## Versioning Format

```
MAJOR.MINOR.PATCH
```

### Version Components

- **MAJOR** (0.x.x → 1.0.0): Breaking changes, major redesigns, data migrations
- **MINOR** (0.1.x → 0.2.0): New features, functionality additions
- **PATCH** (0.1.0 → 0.1.1): Bug fixes, performance improvements

### Pre-Release Versions (0.x.y)

Version numbers below 1.0.0 indicate **pre-release software** in active development:
- Major version `0` signals the app is not yet production-ready
- Features and APIs may change between minor versions
- First stable release will be `1.0.0`

## Build Numbers

Build numbers are **automatically generated** from git commit count:

```bash
BUILD_NUMBER=$(git rev-list --count HEAD)
```

**Benefits:**
- Always incrementing (required by App Store)
- Unique per commit
- Traceable to exact source code state
- No manual management needed

**Build Script:** `Scripts/set-build-number.sh` (runs automatically during Xcode build)

## Unified Versioning

RitualistCore package version **matches** the app version since they live in the same monorepo:

```
App Version:     0.1.0
Package Version: 0.1.0
```

**Version Files:**
- `/VERSION` - Main app version (single source of truth)
- `/RitualistCore/VERSION` - Package version (kept in sync)
- `/RitualistCore/Package.swift` - Version comment at top

## Version Display

Version information is visible to users in the Settings screen:

**Always Visible:**
- **Version**: `0.1.0` (marketing version)

**Debug/TestFlight Only:**
- **Build**: `(123)` (build number from git commits)

Implementation: `Ritualist/Features/Settings/Presentation/SettingsView.swift`

## Git Tagging Strategy

### Tag Format

```
v<MAJOR>.<MINOR>.<PATCH>
```

Examples:
- `v0.1.0` - Initial pre-release baseline
- `v0.2.0` - Minor feature release
- `v1.0.0` - First stable release

### Creating Tags

```bash
# Create annotated tag
git tag -a v0.2.0 -m "Release 0.2.0: Feature description"

# Push tag to remote
git push origin v0.2.0
```

## Bumping Versions

### Automated Version Bump

Use the provided script to bump versions:

```bash
# Patch release (bug fixes)
./Scripts/bump-version.sh patch    # 0.1.0 → 0.1.1

# Minor release (new features)
./Scripts/bump-version.sh minor    # 0.1.0 → 0.2.0

# Major release (breaking changes)
./Scripts/bump-version.sh major    # 0.1.0 → 1.0.0
```

### What the Script Does

1. Updates `/VERSION` file
2. Updates `/RitualistCore/VERSION` file
3. Updates `Package.swift` version comment
4. Updates Xcode project `MARKETING_VERSION`
5. Creates CHANGELOG.md entry template
6. Creates git commit with version changes

### Manual Steps After Bump

1. Edit `CHANGELOG.md` to add release notes
2. Amend the git commit: `git commit --amend`
3. Create git tag: `git tag -a v0.2.0 -m "Release 0.2.0"`
4. Push changes: `git push && git push --tags`

## Release Process

### Pre-Release Checklist

- [ ] All tests passing
- [ ] CHANGELOG.md updated with release notes
- [ ] Version bumped appropriately (patch/minor/major)
- [ ] Git tag created
- [ ] Build succeeds for all configurations

### TestFlight Release

1. Bump version using `./Scripts/bump-version.sh`
2. Create git tag
3. Archive build in Xcode (Product → Archive)
4. Upload to App Store Connect
5. Submit for TestFlight review

### App Store Release

1. Same as TestFlight
2. Submit for App Store review
3. Release to production

## Version History

All version history is tracked in `CHANGELOG.md` following [Keep a Changelog](https://keepachangelog.com/) format.

## Files Involved

```
Ritualist/
├── VERSION                          # App version (0.1.0)
├── CHANGELOG.md                     # Version history
├── RitualistCore/
│   ├── VERSION                      # Package version (0.1.0)
│   └── Package.swift                # Version comment
├── Ritualist.xcodeproj/
│   └── project.pbxproj             # MARKETING_VERSION + CURRENT_PROJECT_VERSION
├── Scripts/
│   ├── bump-version.sh             # Automated version bumping
│   └── set-build-number.sh         # Automated build number (git commits)
└── docs/
    └── VERSIONING.md               # This file
```

## Future Automation

Potential future enhancements:

- **GitHub Actions**: Automated releases on tag push
- **Changelog Generation**: Auto-generate from conventional commits
- **TestFlight Upload**: Automated upload to App Store Connect
- **Release Notes**: Auto-generate from git history

## Questions?

For questions about versioning, see:
- CHANGELOG.md for version history
- Scripts/bump-version.sh for implementation details
- [Semantic Versioning 2.0.0](https://semver.org/) for specification
