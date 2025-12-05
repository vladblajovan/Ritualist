# Build Numbers

## Overview

Build numbers are managed via a **monotonically increasing `BUILD_NUMBER` file** and updated automatically by a git pre-commit hook. This ensures build numbers never decrease, even when working on parallel branches.

**Current Build Number:** Check `BUILD_NUMBER` file (currently 216)

## Why Not Git Commit Count?

The previous approach (`git rev-list --count HEAD`) had a critical flaw with parallel branches:

```
Branch A: 200 base + 5 commits = 205
Branch B: 200 base + 3 commits = 203
If B merges first, then A merges → build numbers could DECREASE
```

App Store requires **strictly increasing** build numbers. The `BUILD_NUMBER` file approach solves this.

## How It Works

### Pre-Commit Hook (Primary Method)

On every commit, the pre-commit hook:

1. Reads current value from `BUILD_NUMBER` file
2. Increments by 1
3. Updates `BUILD_NUMBER` file
4. Updates all `CURRENT_PROJECT_VERSION` in `project.pbxproj`
5. Stages both files for inclusion in the commit

```
📦 Build number: 217
```

### Installation

The pre-commit hook should already be installed. To verify:

```bash
ls -la .git/hooks/pre-commit
```

If missing, install it:

```bash
cp Scripts/pre-commit-hook.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## Xcode Build Phase (Optional)

For extra safety, you can also add a build phase in Xcode. This is optional since the pre-commit hook handles it.

### Add Build Phase

1. Open Xcode, select Ritualist project
2. Select Ritualist target
3. Go to Build Phases tab
4. Click (+) → "New Run Script Phase"
5. Rename to "Auto Build Number"
6. Drag to top (before "Compile Sources")
7. Add script:
   ```bash
   ${SOURCE_ROOT}/Scripts/set-build-number.sh
   ```

### Build Log Output

When working:
```
🔢 Auto Build Number: 217 (from /Users/.../Ritualist)
✅ Updated Info.plist CFBundleVersion to 217
```

## Troubleshooting

### Build number doesn't increment

**Check 1:** Is pre-commit hook installed?
```bash
ls -la .git/hooks/pre-commit
cat .git/hooks/pre-commit
```

**Check 2:** Is BUILD_NUMBER file present?
```bash
cat BUILD_NUMBER
```

**Fix:** Reinstall hook or create BUILD_NUMBER:
```bash
cp Scripts/pre-commit-hook.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
echo "216" > BUILD_NUMBER
```

### BUILD_NUMBER file missing

The hook will auto-create it from git commit count:
```bash
# Or manually
echo "$(git rev-list --count HEAD)" > BUILD_NUMBER
git add BUILD_NUMBER
```

### Build number decreases across branches

This shouldn't happen with the new system. But if you see old build numbers:

1. Check you have the latest main: `git fetch origin main`
2. Merge main into your branch: `git merge origin/main`
3. The BUILD_NUMBER file from main will be merged in
4. Next commit will increment from the higher value

### Script not found error

**Error:** `Scripts/set-build-number.sh: No such file or directory`

**Fix:** Verify the script exists:
```bash
ls Scripts/set-build-number.sh
chmod +x Scripts/set-build-number.sh
```

## Manual Update

If you need to force a specific build number:

```bash
# Set specific number
echo "250" > BUILD_NUMBER

# Update project.pbxproj
sed -i '' 's/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = 250;/g' Ritualist.xcodeproj/project.pbxproj

# Stage files
git add BUILD_NUMBER Ritualist.xcodeproj/project.pbxproj
```

## Widget Extension

The widget extension (RitualistWidgetExtension) uses the same `CURRENT_PROJECT_VERSION` from `project.pbxproj`, so it inherits the build number automatically.

## TestFlight/App Store Requirements

- Build number MUST be higher than previous uploads
- The `BUILD_NUMBER` file approach ensures this
- Each commit increments the build number
- No manual intervention needed

## Files Involved

```
BUILD_NUMBER                           # Source of truth (e.g., "216")
.git/hooks/pre-commit                  # Increments on commit
Scripts/pre-commit-hook.sh             # Reference copy of hook
Scripts/set-build-number.sh            # Optional Xcode build phase
Ritualist.xcodeproj/project.pbxproj    # CURRENT_PROJECT_VERSION entries
```

## See Also

- `docs/reference/versioning/versioning-strategy.md` - Complete versioning strategy
- `Scripts/bump-version.sh` - Marketing version bumping
- `CHANGELOG.md` - Version history
