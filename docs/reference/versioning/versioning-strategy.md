# Versioning Strategy

This document describes the versioning strategy for Ritualist app and RitualistCore package.

## Overview

Ritualist follows [Semantic Versioning 2.0.0](https://semver.org/) for both the app and the core package, using a unified versioning approach.

**Current Version:** `0.4.0`

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

Build numbers are **automatically managed** via a monotonically increasing `BUILD_NUMBER` file:

```bash
# BUILD_NUMBER file contains a single integer
# Incremented by pre-commit hook on each commit
216
```

### Why Not Git Commit Count?

The previous approach (`git rev-list --count HEAD`) had a critical flaw:

| Scenario | Problem |
|----------|---------|
| Branch A: 200 base + 5 commits = 205 | |
| Branch B: 200 base + 3 commits = 203 | |
| B merges first, then A merges | Build numbers can **decrease** |

App Store requires **strictly increasing** build numbers. The `BUILD_NUMBER` file solves this:
- Single source of truth committed to repo
- Pre-commit hook increments and commits
- Merging branches naturally resolves via git merge

### How It Works

1. **Pre-commit hook** reads `BUILD_NUMBER` file
2. Increments by 1
3. Updates `project.pbxproj` `CURRENT_PROJECT_VERSION`
4. Stages both files for the commit
5. Build number is part of the commit itself

### Industry Best Practices Comparison

| Company/Tool | Strategy | Our Approach |
|--------------|----------|--------------|
| Spotify/Netflix | CI-generated counter | Similar - monotonic file |
| Fastlane | Query App Store + increment | More complex, needs auth |
| GitHub Actions | `run_number` | Doesn't work locally |

Our approach balances simplicity (local commits work) with correctness (never decreases).

## Unified Versioning

RitualistCore package version **matches** the app version since they live in the same monorepo:

```
App Version:     0.4.0
Package Version: 0.4.0
```

**Version Files:**
- `/VERSION` - Main app version (single source of truth)
- `/RitualistCore/VERSION` - Package version (kept in sync)
- `/RitualistCore/Package.swift` - Version comment at top
- `/BUILD_NUMBER` - Build number (auto-incremented)

## Version Display

Version information is visible to users in the Settings screen:

**Always Visible:**
- **Version**: `0.4.0` (marketing version)

**Debug/TestFlight Only:**
- **Build**: `(219)` (build number)

Implementation: `Ritualist/Features/Settings/Presentation/SettingsView.swift`

## Git Tagging Strategy

### Automatic Tagging

Tags are **automatically created** by GitHub Actions when VERSION file changes on main:

1. Push version bump to main
2. `.github/workflows/auto-tag-version.yml` triggers
3. Creates annotated tag `v0.4.0` with CHANGELOG notes
4. Tag appears in GitHub releases

### Tag Format

```
v<MAJOR>.<MINOR>.<PATCH>
```

Examples:
- `v0.1.0` - Initial pre-release baseline
- `v0.2.0` - Minor feature release
- `v0.4.0` - Current version (iCloud sync feature gating)
- `v1.0.0` - First stable release (future)

### Manual Tagging (if needed)

```bash
# Create annotated tag
git tag -a v0.4.0 -m "Release 0.4.0: Feature description"

# Push tag to remote
git push origin v0.4.0
```

## Bumping Versions

### Automated Version Bump

Use the provided script to bump versions:

```bash
# Patch release (bug fixes)
./Scripts/bump-version.sh patch    # 0.4.0 → 0.4.1

# Minor release (new features)
./Scripts/bump-version.sh minor    # 0.4.0 → 0.5.0

# Major release (breaking changes)
./Scripts/bump-version.sh major    # 0.4.0 → 1.0.0
```

### What the Script Does

1. Updates `/VERSION` file
2. Updates `/RitualistCore/VERSION` file
3. Updates `Package.swift` version comment
4. Updates Xcode project `MARKETING_VERSION`
5. Creates CHANGELOG.md entry template
6. Creates git commit with version changes

### After Running the Script

1. Edit `CHANGELOG.md` to add release notes
2. Amend the commit if needed: `git commit --amend`
3. Push to main: `git push`
4. **Tag is created automatically** by GitHub Actions

## Release Process

### Pre-Release Checklist

- [ ] All tests passing
- [ ] CHANGELOG.md updated with release notes
- [ ] Version bumped appropriately (patch/minor/major)
- [ ] Build succeeds for all configurations
- [ ] Push to main (tag auto-created)

### TestFlight Release

1. Bump version using `./Scripts/bump-version.sh`
2. Push to main (auto-tags)
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
├── VERSION                          # App version (0.4.0)
├── BUILD_NUMBER                     # Build number (auto-incremented)
├── CHANGELOG.md                     # Version history
├── RitualistCore/
│   ├── VERSION                      # Package version (0.4.0)
│   └── Package.swift                # Version comment
├── Ritualist.xcodeproj/
│   └── project.pbxproj             # MARKETING_VERSION + CURRENT_PROJECT_VERSION
├── Scripts/
│   ├── bump-version.sh             # Automated version bumping
│   └── pre-commit-hook.sh          # Build number auto-increment
├── .git/hooks/
│   └── pre-commit                  # Active hook (copies pre-commit-hook.sh)
├── .github/workflows/
│   └── auto-tag-version.yml        # Auto-creates tags on main
└── docs/
    └── reference/versioning/
        └── versioning-strategy.md  # This file
```

## Troubleshooting

### Build Number Not Incrementing

Check if pre-commit hook is installed:
```bash
ls -la .git/hooks/pre-commit
# Should exist and be executable
```

Reinstall if needed:
```bash
cp Scripts/pre-commit-hook.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### BUILD_NUMBER File Missing

The hook will auto-create it from git commit count:
```bash
# Or manually create
echo "216" > BUILD_NUMBER
git add BUILD_NUMBER
```

### Tag Not Created on Push

Check GitHub Actions workflow status. Common issues:
- Workflow permissions not set (needs `contents: write`)
- VERSION file not actually changed (same content)
- Tag already exists

## Questions?

For questions about versioning, see:
- CHANGELOG.md for version history
- Scripts/bump-version.sh for implementation details
- [Semantic Versioning 2.0.0](https://semver.org/) for specification
