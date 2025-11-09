# Automated Build Number Setup

## Overview

The build number is automatically calculated from git commit count using `Scripts/set-build-number.sh`. To enable automatic updates on every build, add it as an Xcode build phase.

**Current Build Number:** Matches git commit count (currently 148)

## Quick Setup (30 seconds)

### Add Build Phase in Xcode

1. **Open Xcode** and select the Ritualist project

2. **Select the Ritualist target** (not RitualistWidgetExtension)

3. **Go to Build Phases tab**

4. **Click the (+) button** → "New Run Script Phase"

5. **Rename the phase:**
   - Double-click "Run Script" → rename to "Auto Build Number"

6. **Drag it to the top** (before "Compile Sources")
   - This ensures build number updates before compilation

7. **Add the script:**
   ```bash
   # Auto-set build number from git commits
   ${SOURCE_ROOT}/Scripts/set-build-number.sh
   ```

8. **Configure settings:**
   - ✅ Check "Based on dependency analysis" (optional, for speed)
   - Shell: `/bin/sh` (default)

9. **Build the project** (⌘+B)
   - You should see: "🔢 Auto Build Number: XXX" in build log

### Verify It Works

1. **Check current build:**
   ```bash
   # Should show 148 (or current commit count)
   git rev-list --count HEAD
   ```

2. **Make a test commit:**
   ```bash
   git commit --allow-empty -m "test: verify build number increment"
   ```

3. **Build in Xcode** (⌘+B)
   - Build number should now be 149

4. **Check Settings app:**
   - Settings → About → Build: (149)

## How It Works

### Build Number Calculation
```bash
BUILD_NUMBER=$(git rev-list --count HEAD)
```

- **Always incrementing** (required by App Store)
- **Unique per commit**
- **Traceable** to exact source code state

### What the Script Does

1. Calculates commit count from git
2. Updates `CURRENT_PROJECT_VERSION` in project settings
3. Updates `CFBundleVersion` in Info.plist during build

### Build Log Output

When working:
```
🔢 Auto Build Number: 148 (from /Users/.../Ritualist)
✅ Updated Info.plist CFBundleVersion to 148
```

## Troubleshooting

### Build number doesn't change

**Symptom:** Build number stays at 1 or old value

**Fixes:**
1. Verify script is executable:
   ```bash
   chmod +x Scripts/set-build-number.sh
   ```

2. Check script is in build phases (see setup above)

3. Clean build folder: Product → Clean Build Folder (⌘+Shift+K)

4. Rebuild: Product → Build (⌘+B)

### Script not found error

**Error:** `Scripts/set-build-number.sh: No such file or directory`

**Fix:** Script uses `${SOURCE_ROOT}` which should point to project root. Verify:
```bash
ls Scripts/set-build-number.sh
```

### Build number is wrong

**Symptom:** Build number doesn't match commit count

**Debug:**
```bash
# Check commit count
git rev-list --count HEAD

# Run script manually
./Scripts/set-build-number.sh

# Check what was set
grep "CURRENT_PROJECT_VERSION" Ritualist.xcodeproj/project.pbxproj | head -1
```

## Manual Update

If you need to update build number without building:

```bash
# Update to current commit count
./Scripts/set-build-number.sh

# Verify
grep "CURRENT_PROJECT_VERSION" Ritualist.xcodeproj/project.pbxproj | head -1
```

## Widget Extension

The widget extension (RitualistWidgetExtension) inherits the build number from the main app automatically. No additional setup needed.

## TestFlight/App Store

When uploading to TestFlight or App Store:
- Build number MUST be higher than previous uploads
- Git commit count ensures this automatically
- Each commit increments the build number

## Alternative: Manual Build Numbers

If you prefer manual control:

1. **Don't add the build phase**
2. **Update manually before TestFlight uploads:**
   ```bash
   ./Scripts/bump-version.sh patch  # or minor/major
   ```

This is NOT recommended - easy to forget and causes upload failures.

## See Also

- `docs/VERSIONING.md` - Complete versioning strategy
- `Scripts/bump-version.sh` - Version bumping tool
- `CHANGELOG.md` - Version history
