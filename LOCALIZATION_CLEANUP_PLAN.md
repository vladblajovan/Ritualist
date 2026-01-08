# Localization Cleanup Plan

**Date:** January 8, 2026
**Branch:** `cleanup/localization-hardcoded-strings`
**Status:** Planning

---

## Executive Summary

Clean up the localization system by:
1. Disabling Xcode's automatic string extraction (stops random xcstrings updates)
2. Migrating all hardcoded strings to use the existing `Strings.*` type-safe keys
3. Moving string values to the `Localizable.xcstrings` catalog

**We keep the current `Strings.swift` approach** - it provides excellent namespace organization and compile-time safety.

---

## Current State

### What We Have
| File | Purpose | Status |
|------|---------|--------|
| `Strings.swift` (597 lines) | Type-safe enum with organized keys | ✅ Keep |
| `Localizable.xcstrings` | String Catalog with translations | ✅ Keep |

### Problems to Fix
1. **Xcode auto-extracts strings** - Any `Text("Hello")` gets added to xcstrings automatically
2. **Hardcoded strings in code** - Many strings bypass the `Strings.*` system
3. **Inconsistent approach** - Some views use `Strings.*`, others use raw strings

---

## Target State

### After Cleanup
```swift
// ❌ Before: Hardcoded string (Xcode extracts this)
Text("Save Changes")

// ✅ After: Type-safe key (Xcode ignores this)
Text(Strings.Button.saveChanges)
```

### Benefits
- No more random xcstrings file changes
- All strings in one organized place
- Compile-time safety for string references
- Easy to find/update any string
- Ready for future localization

---

## Migration Steps

### Phase 1: Disable Xcode Auto-Extraction (5 min)

#### Option A: Build Setting (Recommended)
In Xcode → Project → Build Settings → Search "localization":
```
LOCALIZATION_PREFERS_STRING_CATALOGS = NO
```

#### Option B: Use Explicit Keys Only
Once all strings use `Strings.*`, Xcode has nothing to extract (variables aren't extracted).

### Phase 2: Audit Hardcoded Strings (30 min)

#### Find All Hardcoded Strings
Search for patterns that indicate hardcoded localizable strings:

```bash
# Text views with string literals
grep -rn 'Text("' --include="*.swift" Ritualist/

# Button labels
grep -rn 'Button("' --include="*.swift" Ritualist/

# Labels
grep -rn 'Label("' --include="*.swift" Ritualist/

# NavigationTitle
grep -rn 'navigationTitle("' --include="*.swift" Ritualist/

# Alert/confirmation dialogs
grep -rn 'alert.*"' --include="*.swift" Ritualist/

# Section headers
grep -rn 'Section("' --include="*.swift" Ritualist/
```

#### Categorize Findings
- **User-facing strings** → Must migrate to `Strings.*`
- **Debug-only strings** → Can stay hardcoded (won't ship)
- **System strings** → SF Symbols, identifiers, etc. (ignore)

### Phase 3: Add Missing Keys to Strings.swift (1-2 hours)

#### For Each Hardcoded String:

1. **Determine the namespace** based on context:
   - Button text → `Strings.Button.*`
   - Form labels → `Strings.Form.*`
   - Error messages → `Strings.Error.*`
   - Settings text → `Strings.Settings.*`
   - etc.

2. **Add the key to Strings.swift**:
   ```swift
   public enum Button {
       // Existing keys...
       public static let saveChanges = String(localized: "buttonSaveChanges")
   }
   ```

3. **Add the value to Localizable.xcstrings**:
   - Open in Xcode
   - Add key: `buttonSaveChanges`
   - Add value: `Save Changes`

### Phase 4: Update Code References (2-3 hours)

#### Replace Hardcoded Strings
```swift
// Before
Text("Save Changes")
Button("Cancel") { ... }
.navigationTitle("Settings")

// After
Text(Strings.Button.saveChanges)
Button(Strings.Button.cancel) { ... }
.navigationTitle(Strings.Navigation.settings)
```

#### Bulk Find & Replace Strategy
For common patterns, use regex find/replace:
```
Find:    Text\("([^"]+)"\)
Replace: Text(Strings.TODO.$1)  // Then fix manually
```

### Phase 5: Clean Up xcstrings (30 min)

#### Remove Auto-Extracted Entries
After migration, the xcstrings file will have:
- ✅ Keys that match `Strings.swift` (keep)
- ❌ Auto-extracted raw strings like `"Save"`, `"Cancel"` (remove)

Review and remove orphaned entries that no longer have code references.

### Phase 6: Verification (30 min)

#### Checklist
- [ ] Build succeeds with no warnings
- [ ] No `Text("...")`  with hardcoded user-facing strings
- [ ] All `Strings.*` keys have values in xcstrings
- [ ] App displays correct strings throughout
- [ ] xcstrings file is clean (no orphaned entries)

---

## String Categories Reference

Based on current `Strings.swift` structure:

| Namespace | Use For |
|-----------|---------|
| `Strings.App` | App name, version info |
| `Strings.Navigation` | Tab titles, nav bar titles |
| `Strings.Button` | All button labels |
| `Strings.Loading` | Loading states |
| `Strings.Status` | Status messages |
| `Strings.Error` | Error messages |
| `Strings.EmptyState` | Empty state messages |
| `Strings.Form` | Form labels, placeholders |
| `Strings.Validation` | Validation errors |
| `Strings.Settings` | Settings screen text |
| `Strings.Stats` | Statistics screen text |
| `Strings.Habit` | Habit-related text |
| `Strings.Schedule` | Schedule-related text |
| `Strings.Streak` | Streak-related text |
| `Strings.Common` | Shared/common text |
| `Strings.Accessibility` | VoiceOver labels |
| `Strings.Premium` | Premium/paywall text |
| `Strings.Onboarding` | Onboarding flow text |
| `Strings.Assistant` | Habits assistant text |
| `Strings.Widget` | Widget text |

---

## Files to Review

### High Priority (User-facing views)
- `Ritualist/Features/Overview/Presentation/*.swift`
- `Ritualist/Features/Habits/Presentation/*.swift`
- `Ritualist/Features/Settings/Presentation/*.swift`
- `Ritualist/Features/Stats/Presentation/*.swift`
- `Ritualist/Features/Onboarding/Presentation/*.swift`

### Medium Priority
- `Ritualist/Features/Shared/Presentation/*.swift`
- `RitualistWidget/**/*.swift`

### Low Priority (Can defer)
- Debug views
- Preview code
- Test files

---

## Estimated Timeline

| Phase | Task | Duration |
|-------|------|----------|
| 1 | Disable auto-extraction | 5 min |
| 2 | Audit hardcoded strings | 30 min |
| 3 | Add keys to Strings.swift | 1-2 hours |
| 4 | Update code references | 2-3 hours |
| 5 | Clean up xcstrings | 30 min |
| 6 | Verification | 30 min |
| **Total** | | **5-7 hours** |

---

## Exclusions (Strings That Stay Hardcoded)

These are intentionally NOT localized:
- SF Symbol names (`"gear"`, `"plus"`, etc.)
- Accessibility identifiers
- Debug/logging messages
- URL schemes and deep links
- UserDefaults keys
- Notification names
- Bundle identifiers

---

## Checklist

### Pre-Migration
- [ ] Review current `Strings.swift` structure
- [ ] Run audit to find hardcoded strings
- [ ] Estimate scope of changes

### Migration
- [ ] Disable Xcode auto-extraction
- [ ] Add all missing keys to `Strings.swift`
- [ ] Add all values to `Localizable.xcstrings`
- [ ] Update all code references
- [ ] Remove orphaned xcstrings entries

### Post-Migration
- [ ] Full app test
- [ ] Widget test
- [ ] Verify no hardcoded user-facing strings remain
- [ ] Commit and push

---

## Approval

- [ ] Approved by: _______________
- [ ] Date: _______________
- [ ] Notes: _______________
