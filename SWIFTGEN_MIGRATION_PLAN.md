# SwiftGen Localization Migration Plan

**Date:** January 8, 2026
**Branch:** `feature/swiftgen-localization-migration`
**Status:** Planning

---

## Executive Summary

Migrate from the current hybrid localization approach (manual `Strings.swift` + Xcode's auto-extraction) to a unified SwiftGen-based solution. This eliminates the dual-maintenance problem and stops Xcode from randomly updating the `.xcstrings` file.

---

## Current State (Problems)

### 1. Dual Maintenance Burden
- **`Strings.swift`** (597 lines): Manually maintained enum with `String(localized:)` calls
- **`Localizable.xcstrings`**: String Catalog with actual translations

Every new string requires edits in **both files**.

### 2. Xcode Auto-Extraction
Xcode automatically extracts string literals from SwiftUI views:
```swift
Text("Save")  // Xcode adds "Save" to xcstrings automatically
```
This causes random, unwanted changes to the `.xcstrings` file.

### 3. Drift Risk
Manual `Strings.swift` can drift from `.xcstrings`:
- Keys added to one but not the other
- Typos in keys cause runtime issues (no compile-time safety)
- Deleted keys leave orphaned entries

---

## Target State (Solution)

### Single Source of Truth
```
Localizable.xcstrings  →  SwiftGen  →  L10n.swift (generated)
     (you edit)            (builds)       (you use)
```

### Benefits
| Aspect | Before | After |
|--------|--------|-------|
| Files to edit for new string | 2 | 1 |
| Compile-time key validation | ❌ | ✅ |
| Random xcstrings updates | Yes | No |
| Namespace organization | Manual | Auto from key names |
| Risk of key typos | Runtime bug | Compile error |

---

## Migration Steps

### Phase 1: Setup (15 min)

#### 1.1 Install SwiftGen
```bash
brew install swiftgen
```

#### 1.2 Create Configuration
Create `swiftgen.yml` in project root:
```yaml
strings:
  inputs:
    - Ritualist/Resources/Localizable.xcstrings
  outputs:
    - templateName: structured-swift5
      output: Ritualist/Resources/Generated/L10n.swift
      params:
        enumName: L10n
        publicAccess: true
```

#### 1.3 Create Output Directory
```bash
mkdir -p Ritualist/Resources/Generated
```

#### 1.4 Add to .gitignore (optional)
```gitignore
# Generated files (optional - some prefer to commit generated code)
# Ritualist/Resources/Generated/
```

### Phase 2: Key Renaming (1-2 hours)

#### 2.1 Naming Convention
Convert flat keys to dot-notation for namespace generation:

| Current Key | New Key | Generated Swift |
|-------------|---------|-----------------|
| `buttonSave` | `button.save` | `L10n.Button.save` |
| `buttonCancel` | `button.cancel` | `L10n.Button.cancel` |
| `navigationOverview` | `navigation.overview` | `L10n.Navigation.overview` |
| `errorFailedToSave` | `error.failedToSave` | `L10n.Error.failedToSave` |
| `formHabitName` | `form.habitName` | `L10n.Form.habitName` |

#### 2.2 Key Categories to Rename
Based on current `Strings.swift` structure:
- `App.*` → `app.*`
- `Navigation.*` → `navigation.*`
- `Button.*` → `button.*`
- `Loading.*` → `loading.*`
- `Status.*` → `status.*`
- `Error.*` → `error.*`
- `EmptyState.*` → `emptyState.*`
- `Form.*` → `form.*`
- `Validation.*` → `validation.*`
- `Settings.*` → `settings.*`
- `Stats.*` → `stats.*`
- `Habit.*` → `habit.*`
- `Schedule.*` → `schedule.*`
- `Streak.*` → `streak.*`
- `Common.*` → `common.*`
- `Accessibility.*` → `accessibility.*`
- `Premium.*` → `premium.*`
- `Onboarding.*` → `onboarding.*`
- `Assistant.*` → `assistant.*`
- `Widget.*` → `widget.*`

#### 2.3 Migration Script
Create a script to automate key renaming in `.xcstrings`:
```bash
# migration-script.sh (to be created)
# Transforms keys from camelCase to dot.notation
```

### Phase 3: Code Updates (2-3 hours)

#### 3.1 Find & Replace Pattern
```swift
// Before
Strings.Button.save
Strings.Navigation.overview
Strings.Error.failedToSave

// After
L10n.Button.save
L10n.Navigation.overview
L10n.Error.failedToSave
```

#### 3.2 Regex for Find/Replace
```regex
Find:    Strings\.([A-Z][a-zA-Z]+)\.([a-zA-Z]+)
Replace: L10n.$1.$2
```

#### 3.3 Files to Update
All Swift files that import/use `Strings.*`:
- Views (*.swift in Features/)
- ViewModels
- Widgets
- Tests (if applicable)

### Phase 4: Build Integration (10 min)

#### 4.1 Add Run Script Build Phase
In Xcode → Ritualist target → Build Phases → Add "Run Script":
```bash
if which swiftgen >/dev/null; then
    swiftgen
else
    echo "warning: SwiftGen not installed, download from https://github.com/SwiftGen/SwiftGen"
fi
```

**Position:** Before "Compile Sources" phase

#### 4.2 Add Generated File to Xcode
- Add `Ritualist/Resources/Generated/L10n.swift` to the Xcode project
- Ensure it's in the Ritualist target

### Phase 5: Cleanup (10 min)

#### 5.1 Delete Old Files
```bash
rm Ritualist/Resources/Strings.swift
```

#### 5.2 Remove from Xcode Project
Remove `Strings.swift` reference from Xcode project navigator.

#### 5.3 Clean Build
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/Ritualist-*
```

### Phase 6: Verification (30 min)

#### 6.1 Build & Test
- [ ] Project builds without errors
- [ ] All string references resolve correctly
- [ ] App runs and displays correct strings
- [ ] No "missing localization" warnings

#### 6.2 Test Localization (if multi-language)
- [ ] Switch device language
- [ ] Verify translations appear correctly

---

## Post-Migration Workflow

### Adding New Strings

**Before (old workflow):**
1. Add key to `Localizable.xcstrings`
2. Add accessor to `Strings.swift`
3. Use in code

**After (new workflow):**
1. Add key to `Localizable.xcstrings` (e.g., `button.newAction`)
2. Build (SwiftGen generates `L10n.Button.newAction`)
3. Use `L10n.Button.newAction` in code

### Preventing Xcode Auto-Extraction

Once migrated, Xcode won't auto-extract because you'll use:
```swift
Text(L10n.Button.save)  // Variable, not literal - Xcode ignores
```

Instead of:
```swift
Text("Save")  // Literal - Xcode extracts
```

---

## Rollback Plan

If issues arise:
1. Revert to previous commit (manual `Strings.swift` preserved in git)
2. Remove SwiftGen build phase
3. Delete `swiftgen.yml`
4. Delete `Generated/` directory

---

## Estimated Timeline

| Phase | Task | Duration |
|-------|------|----------|
| 1 | Setup SwiftGen | 15 min |
| 2 | Rename keys in xcstrings | 1-2 hours |
| 3 | Update code references | 2-3 hours |
| 4 | Build integration | 10 min |
| 5 | Cleanup | 10 min |
| 6 | Verification | 30 min |
| **Total** | | **4-6 hours** |

---

## Risks & Mitigations

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Missed string reference | Medium | Compiler will catch (that's the point!) |
| Widget strings break | Low | Test widget after migration |
| Build time increase | Low | SwiftGen is fast (<1s typically) |
| Team unfamiliarity | Medium | Document new workflow in README |

---

## Checklist

### Pre-Migration
- [ ] Backup current `Strings.swift`
- [ ] Document all current namespaces
- [ ] Install SwiftGen locally

### Migration
- [ ] Create `swiftgen.yml`
- [ ] Rename all keys to dot-notation
- [ ] Run SwiftGen, verify output
- [ ] Update all code references
- [ ] Add build phase
- [ ] Delete old `Strings.swift`

### Post-Migration
- [ ] Full app test
- [ ] Widget test
- [ ] Commit and push
- [ ] Update team documentation

---

## Approval

- [ ] Approved by: _______________
- [ ] Date: _______________
- [ ] Notes: _______________
