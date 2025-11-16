# SwiftData Schema Migration Guide

**Last Updated:** 2025-11-15
**Current Schema:** V9
**Author:** Based on V8→V9 Migration Experience

---

## Table of Contents

1. [Overview](#overview)
2. [Pre-Migration Planning](#pre-migration-planning)
3. [Implementation Checklist](#implementation-checklist)
4. [Safety Verification](#safety-verification)
5. [Testing Procedures](#testing-procedures)
6. [Common Pitfalls](#common-pitfalls)
7. [Rollback Strategy](#rollback-strategy)
8. [Post-Migration Verification](#post-migration-verification)

---

## Overview

This document provides a comprehensive checklist for creating new SwiftData schema versions and migrations. Follow this guide **exactly** to minimize risk of data loss.

### Migration Types

**Lightweight Migration (Automatic):**
- Adding optional properties
- Adding properties with default values
- Removing properties
- Simple type changes

**Heavyweight Migration (Custom):**
- Renaming properties
- Changing property types (complex)
- Data transformations
- Structural changes (like V8→V9 timezone model)

**Rule of Thumb:** If you're changing how data is stored or its meaning, use heavyweight migration.

---

## Pre-Migration Planning

### 1. Define Migration Requirements

**Questions to Answer:**
- [ ] What data structure is changing?
- [ ] Is this a breaking change or additive?
- [ ] Will existing data need transformation?
- [ ] Are there user settings that must be preserved?
- [ ] What are the safe default values for new fields?

**Document:**
```markdown
## Migration V8 → V9: Three-Timezone Model

**What Changed:**
- Added: currentTimezoneIdentifier (String)
- Added: homeTimezoneIdentifier (String)
- Changed: displayTimezoneMode (String → DisplayTimezoneMode enum → Data)
- Added: timezoneChangeHistory ([TimezoneChange] → Data)

**Data Preservation:**
- MUST preserve V8 homeTimezone → V9 homeTimezoneIdentifier
- MUST preserve V8 displayTimezoneMode → V9 displayTimezoneModeData (with conversion)

**Safe Defaults:**
- currentTimezoneIdentifier: TimeZone.current.identifier
- homeTimezoneIdentifier: V8 value OR device timezone
- displayTimezoneModeData: Converted V8 value OR .current enum
- timezoneChangeHistoryData: Empty array OR migration event
```

### 2. Create Domain Model First

**Order of Operations:**
1. ✅ Create/Update domain entity (`UserProfile.swift`)
2. ✅ Create new schema version (`SchemaVX.swift`)
3. ✅ Update migration plan (`MigrationPlan.swift`)
4. ✅ Update all old schemas' conversion methods
5. ✅ Update ActiveSchema type aliases

**Why This Order?**
- Domain entity is the "source of truth"
- Schema models are persistence layers
- Old schemas must convert to current domain entity
- Compiler will catch mismatches

### 3. Identify All Affected Code

**Search for:**
```bash
# Find all schema references
grep -r "UserProfileModel" --include="*.swift"

# Find all domain entity usages
grep -r "UserProfile(" --include="*.swift"

# Find property access patterns
grep -r "\.homeTimezone" --include="*.swift"
```

**Create List:**
- [ ] Domain entity file
- [ ] All schema version files (V1-VX)
- [ ] Migration plan
- [ ] ActiveSchema.swift
- [ ] Data sources (local, cloud)
- [ ] Use cases
- [ ] View models
- [ ] UI views
- [ ] Tests

---

## Implementation Checklist

### Phase 1: Domain Model Updates

- [ ] **Update or create domain entity** (e.g., `UserProfile.swift`)
  - [ ] Add new properties with appropriate types
  - [ ] Update initializer with default values
  - [ ] Add computed properties if needed
  - [ ] Ensure `Codable` conformance for JSON fields
  - [ ] Document each field with comments

**Example:**
```swift
public struct UserProfile: Identifiable, Codable, Hashable {
    public var currentTimezoneIdentifier: String = TimeZone.current.identifier
    public var homeTimezoneIdentifier: String = TimeZone.current.identifier
    public var displayTimezoneMode: DisplayTimezoneMode = .current  // Enum, not String!
    public var timezoneChangeHistory: [TimezoneChange] = []
}
```

- [ ] **Create supporting types** (e.g., `DisplayTimezoneMode.swift`)
  - [ ] Make it `Codable` for JSON encoding
  - [ ] Add `toLegacyString()` / `fromLegacyString()` for backward compatibility
  - [ ] Include comprehensive documentation
  - [ ] Add safety defaults

### Phase 2: Schema Creation

- [ ] **Create new schema file** (`SchemaVX.swift`)
  - [ ] Copy from previous version (e.g., `SchemaV8.swift`)
  - [ ] Update version identifier: `Schema.Version(X, 0, 0)`
  - [ ] Update all class names: `SchemaVX`
  - [ ] Apply structural changes ONLY to affected models
  - [ ] Keep unchanged models identical to previous version

**Critical: UserProfileModel Changes**
```swift
@Model
public final class UserProfileModel {
    // Basic fields (unchanged)
    @Attribute(.unique) public var id: String
    public var name: String = ""

    // NEW FIELDS - Add with safe defaults
    public var currentTimezoneIdentifier: String = TimeZone.current.identifier
    public var homeTimezoneIdentifier: String = TimeZone.current.identifier

    // Encode complex types as Data
    public var displayTimezoneModeData: Data = Data()  // NOT String!
    public var timezoneChangeHistoryData: Data = Data()

    // Always include timestamps
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()
}
```

- [ ] **Implement conversion methods** (`extension SchemaVX.UserProfileModel`)

  **toEntity() - Database → Domain:**
  ```swift
  public func toEntity() -> UserProfile {
      // Decode JSON fields
      let displayMode: DisplayTimezoneMode
      if !displayTimezoneModeData.isEmpty {
          displayMode = (try? JSONDecoder().decode(DisplayTimezoneMode.self,
                                                    from: displayTimezoneModeData)) ?? .current
      } else {
          displayMode = .current  // Safe default
      }

      // Return domain entity with current structure
      return UserProfile(
          currentTimezoneIdentifier: currentTimezoneIdentifier,
          homeTimezoneIdentifier: homeTimezoneIdentifier,
          displayTimezoneMode: displayMode,  // Enum, not Data!
          timezoneChangeHistory: decodeHistory()
      )
  }
  ```

  **fromEntity() - Domain → Database:**
  ```swift
  public static func fromEntity(_ profile: UserProfile) -> UserProfileModelVX {
      // Encode complex types to JSON
      let displayModeData = (try? JSONEncoder().encode(profile.displayTimezoneMode)) ?? Data()
      let historyData = (try? JSONEncoder().encode(profile.timezoneChangeHistory)) ?? Data()

      return SchemaVX.UserProfileModel(
          currentTimezoneIdentifier: profile.currentTimezoneIdentifier,
          homeTimezoneIdentifier: profile.homeTimezoneIdentifier,
          displayTimezoneModeData: displayModeData,
          timezoneChangeHistoryData: historyData
      )
  }
  ```

### Phase 3: Migration Plan Updates

- [ ] **Register new schema** in `MigrationPlan.swift`
  ```swift
  public static var schemas: [any VersionedSchema.Type] {
      [
          SchemaV2.self,
          // ... existing versions ...
          SchemaV(X-1).self,
          SchemaVX.self  // ADD NEW VERSION
      ]
  }
  ```

- [ ] **Create migration stage**

  **For Lightweight Migration:**
  ```swift
  static let migrateV(X-1)toVX = MigrationStage.lightweight(
      fromVersion: SchemaV(X-1).self,
      toVersion: SchemaVX.self
  )
  ```

  **For Heavyweight Migration (DATA TRANSFORMATION):**
  ```swift
  static let migrateV(X-1)toVX = MigrationStage.custom(
      fromVersion: SchemaV(X-1).self,
      toVersion: SchemaVX.self,
      willMigrate: { context in
          print("🔄 [Migration] Starting V(X-1) → VX: [Description]")
      },
      didMigrate: { context in
          // 🚨 CRITICAL: Read old data BEFORE it's gone!
          let oldProfiles = try context.fetch(FetchDescriptor<UserProfileModelV(X-1)>())

          // Create mapping to preserve data
          var oldData: [String: OldDataStructure] = [:]
          for oldProfile in oldProfiles {
              oldData[oldProfile.id] = extractDataToPreserve(oldProfile)
          }

          // Fetch new profiles and populate
          let newProfiles = try context.fetch(FetchDescriptor<UserProfileModelVX>())

          for newProfile in newProfiles {
              // PRESERVE old data
              if let preserved = oldData[newProfile.id] {
                  newProfile.someField = preserved.value
                  print("🔄 Preserved: \(preserved.value)")
              } else {
                  // Safe defaults
                  newProfile.someField = safeDefault
              }

              newProfile.updatedAt = Date()
          }

          try context.save()
          print("✅ [Migration] V(X-1) → VX: Migrated \(newProfiles.count) records")
      }
  )
  ```

- [ ] **Add to stages array**
  ```swift
  public static var stages: [MigrationStage] {
      [
          // ... existing stages ...
          migrateV(X-1)toVX  // ADD NEW STAGE
      ]
  }
  ```

### Phase 4: Backward Compatibility

**🚨 CRITICAL: Update ALL old schema conversion methods**

For EACH schema version (V1, V2, V3, ... V(X-1)):

- [ ] **Update SchemaV1 conversion methods**
  ```swift
  // In SchemaV1.swift
  extension SchemaV1.UserProfileModel {
      public func toEntity() -> UserProfile {
          // Convert V1 fields → CURRENT (VX) UserProfile structure
          let currentTz = TimeZone.current.identifier
          let homeTz = homeTimezone ?? TimeZone.current.identifier
          let displayMode = DisplayTimezoneMode.fromLegacyString(displayTimezoneMode ?? "current")

          return UserProfile(
              currentTimezoneIdentifier: currentTz,      // NEW in VX
              homeTimezoneIdentifier: homeTz,            // NEW in VX
              displayTimezoneMode: displayMode,          // NEW in VX (enum)
              timezoneChangeHistory: []                  // NEW in VX
          )
      }

      public static func fromEntity(_ profile: UserProfile) -> UserProfileModelV1 {
          // Convert CURRENT (VX) UserProfile → V1 format
          let homeTimezoneV1 = profile.homeTimezoneIdentifier
          let displayModeV1 = profile.displayTimezoneMode.toLegacyString()

          return SchemaV1.UserProfileModel(
              homeTimezone: homeTimezoneV1,
              displayTimezoneMode: displayModeV1
          )
      }
  }
  ```

- [ ] **Repeat for SchemaV2, V3, V4, ... V(X-1)**

**Why Update All Old Schemas?**
- Users might be upgrading from ANY version
- Migration chain runs: V1→V2→V3→...→VX
- Each step calls `toEntity()` which must create CURRENT UserProfile
- If old schemas use old UserProfile structure, compilation fails

### Phase 5: ActiveSchema Updates

- [ ] **Update type aliases** in `ActiveSchema.swift`
  ```swift
  // Update ALL type aliases to new version
  public typealias ActiveUserProfileModel = UserProfileModelVX  // Changed
  public typealias ActiveHabitModel = HabitModelVX              // Changed
  public typealias ActiveHabitLogModel = HabitLogModelVX        // Changed
  // ... etc
  ```

**Verification:**
```bash
# Ensure no hardcoded schema versions remain
grep -r "UserProfileModelV[0-9]" --include="*.swift" | grep -v "Schema"
# Should only show schema definition files, not usage in app logic
```

### Phase 6: Data Sources & Use Cases

- [ ] **Update local data source** (`ProfileLocalDataSource.swift`)
  ```swift
  // Use ActiveSchema, not hardcoded version
  let existing = try modelContext.fetch(
      FetchDescriptor<ActiveUserProfileModel>()  // ✅ Good
      // NOT: FetchDescriptor<UserProfileModelV8>()  // ❌ Bad
  ).first

  // Update all fields
  existing.currentTimezoneIdentifier = profile.currentTimezoneIdentifier
  existing.homeTimezoneIdentifier = profile.homeTimezoneIdentifier

  // Encode complex types
  if let modeData = try? JSONEncoder().encode(profile.displayTimezoneMode) {
      existing.displayTimezoneModeData = modeData
  }
  ```

- [ ] **Update cloud mapper** (`UserProfileCloudMapper.swift`)
  - [ ] Increment CloudKit schema version (`"v2"`, `"v3"`, etc.)
  - [ ] Add new field keys to `FieldKey` enum
  - [ ] Update `toCKRecord()` with new fields
  - [ ] Update `fromCKRecord()` with version detection
  - [ ] Add migration path for old CloudKit records

- [ ] **Update use cases**
  - [ ] Check all `UserProfile()` constructor calls
  - [ ] Use default initializer or specify new fields
  - [ ] Remove old field references

### Phase 7: UI Updates

- [ ] **Update ViewModels**
  - [ ] Check property access patterns
  - [ ] Update bindings
  - [ ] Fix any hardcoded field names

- [ ] **Update Views**
  - [ ] Search for old property names
  - [ ] Update display logic
  - [ ] Add conversion for string-based UI (`.toLegacyString()`)

**Example Fixes:**
```swift
// OLD (won't compile):
Text(vm.profile.displayTimezoneMode)  // Error: DisplayTimezoneMode is not String

// NEW:
Text(vm.profile.displayTimezoneMode.toLegacyString())  // ✅

// BETTER (future): Update UI to use enum directly
picker: vm.profile.displayTimezoneMode  // DisplayTimezoneMode enum
onChange: { vm.profile.displayTimezoneMode = $0 }  // No conversion needed
```

---

## Safety Verification

### Build-Time Checks

- [ ] **Clean build succeeds**
  ```bash
  xcodebuild clean build -scheme YourScheme
  ```

- [ ] **No compiler warnings related to migration**
  ```bash
  # Check for common issues
  grep -i "deprecated" build.log
  grep -i "ambiguous" build.log
  ```

- [ ] **All tests compile**
  ```bash
  xcodebuild test -scheme YourScheme -destination 'platform=iOS Simulator,...'
  ```

### Code Review Checklist

- [ ] **Schema VX Definition**
  - [ ] Version identifier is correct: `Schema.Version(X, 0, 0)`
  - [ ] All models listed in `models` array
  - [ ] UserProfileModel has all required fields
  - [ ] Fields have safe default values
  - [ ] No breaking changes to unchanged models

- [ ] **Conversion Methods**
  - [ ] `toEntity()` creates current UserProfile structure
  - [ ] `fromEntity()` handles all UserProfile fields
  - [ ] JSON encoding has fallbacks (`?? Data()`)
  - [ ] JSON decoding has fallbacks (`?? defaultValue`)

- [ ] **Migration Logic**
  - [ ] Custom migration reads old data FIRST
  - [ ] Old data is preserved in new structure
  - [ ] Safe defaults for missing values
  - [ ] Logging statements for debugging
  - [ ] `context.save()` is called
  - [ ] Error handling doesn't swallow critical errors

- [ ] **ActiveSchema Updates**
  - [ ] All type aliases point to VX
  - [ ] No hardcoded version numbers in app logic
  - [ ] Grep verification passes

- [ ] **Old Schema Updates**
  - [ ] V1 `toEntity()` / `fromEntity()` updated
  - [ ] V2 `toEntity()` / `fromEntity()` updated
  - [ ] V3 `toEntity()` / `fromEntity()` updated
  - [ ] ... (all versions through V(X-1))

### Data Integrity Checks

- [ ] **Map old fields to new fields**
  ```
  V(X-1) Field         →  VX Field                 Fallback
  ───────────────────────────────────────────────────────────
  homeTimezone         →  homeTimezoneIdentifier   TimeZone.current.identifier
  displayTimezoneMode  →  displayTimezoneModeData  .current enum → JSON
  (none)               →  currentTimezoneIdentifier TimeZone.current.identifier
  (none)               →  timezoneChangeHistory    [] empty array
  ```

- [ ] **All user settings preserved**
  - [ ] User-modified fields copied, not reset
  - [ ] Only system fields use new defaults
  - [ ] Optional fields handle nil safely

- [ ] **Test migration with sample data**
  ```swift
  // In DebugMenuView or test:
  // 1. Create V(X-1) profile with specific values
  // 2. Trigger migration to VX
  // 3. Verify all values preserved correctly
  ```

---

## Testing Procedures

### Pre-Migration Testing

1. **Create test database with V(X-1) data**
   ```swift
   // In Debug menu or test setup:
   let testProfile = UserProfileModelV(X-1)(
       homeTimezone: "America/New_York",
       displayTimezoneMode: "home"
   )
   // Save to database
   ```

2. **Document current state**
   ```
   V(X-1) Database State:
   - homeTimezone: "America/New_York"
   - displayTimezoneMode: "home"
   - Expected after migration:
     - currentTimezoneIdentifier: (device)
     - homeTimezoneIdentifier: "America/New_York" (preserved!)
     - displayTimezoneModeData: <.home enum>
   ```

### Migration Testing

1. **Launch app with new code**
   - [ ] Watch console for migration logs
   - [ ] Verify "Starting V(X-1) → VX" appears
   - [ ] Verify "Successfully migrated N records" appears
   - [ ] No error messages

2. **Check migration logs**
   ```
   Expected Output:
   🔄 [Migration] Starting V(X-1) → VX: Three-Timezone Model
   🔄 [Migration] V(X-1) → VX: Preserving timezone settings...
   🔄 [Migration] Preserved home timezone: America/New_York
   🔄 [Migration] Preserved display mode: home → DisplayTimezoneMode.home
   ✅ [Migration] V(X-1) → VX: Successfully migrated 1 user profile(s)
   ```

3. **Verify data in Debug Menu**
   - [ ] Navigate to Settings → Debug Menu → Timezone Diagnostics
   - [ ] Check "Display Settings" section
   - [ ] Verify preserved values appear correctly

4. **Verify database state**
   ```swift
   // In Debug menu:
   let profile = try await loadProfile()
   print("Current TZ: \(profile.currentTimezoneIdentifier)")
   print("Home TZ: \(profile.homeTimezoneIdentifier)")  // Should be preserved!
   print("Display Mode: \(profile.displayTimezoneMode)")
   print("History: \(profile.timezoneChangeHistory)")
   ```

### Rollback Testing

1. **Backup database before migration**
   - [ ] Use Debug Menu → Database Backups → Create Backup
   - [ ] Note backup filename and timestamp

2. **If migration fails:**
   - [ ] Use Debug Menu → Database Backups → Restore
   - [ ] Restart app
   - [ ] Verify V(X-1) data intact
   - [ ] Debug migration issue
   - [ ] Fix and retry

3. **Test rollback procedure**
   ```bash
   # Before shipping:
   1. Create V(X-1) database with test data
   2. Backup
   3. Run migration to VX
   4. Restore from backup
   5. Verify V(X-1) data intact
   ```

---

## Common Pitfalls

### ❌ PITFALL 1: Not Preserving Old Data

**What Happened (V8→V9):**
```swift
// ❌ BAD - Overwrites user settings!
profile.homeTimezoneIdentifier = TimeZone.current.identifier  // Always resets!
```

**Fix:**
```swift
// ✅ GOOD - Preserves user settings
if let oldValue = v8Data[profile.id]?.homeTimezone {
    profile.homeTimezoneIdentifier = oldValue  // Preserve!
} else {
    profile.homeTimezoneIdentifier = TimeZone.current.identifier  // Default
}
```

**Lesson:** Always read old schema data BEFORE modifying new schema records.

### ❌ PITFALL 2: Not Updating Old Schemas

**Symptom:**
```
Error: Extra argument 'homeTimezone' in call
Error: Cannot convert value of type 'String' to expected argument type 'DisplayTimezoneMode'
```

**Cause:** Old schemas (V1-V7) still trying to create old UserProfile structure.

**Fix:** Update ALL old schema `toEntity()` / `fromEntity()` methods to work with current UserProfile.

### ❌ PITFALL 3: Hardcoding Schema Versions

**What Happened:**
```swift
// ❌ BAD - Hardcoded version
let profile = try context.fetch(FetchDescriptor<UserProfileModelV8>())
```

**Fix:**
```swift
// ✅ GOOD - Use ActiveSchema
let profile = try context.fetch(FetchDescriptor<ActiveUserProfileModel>())
```

**Prevention:** Always grep for hardcoded versions before shipping.

### ❌ PITFALL 4: Forgetting CloudKit Schema

**Symptom:** Local migration works, but CloudKit sync fails or corrupts data.

**Fix:**
- Update `UserProfileCloudMapper.swift`
- Increment CloudKit schema version
- Add version-aware field parsing
- Test sync after migration

### ❌ PITFALL 5: SwiftUI View Compilation Errors

**Symptom:**
```
Error: The compiler is unable to type-check this expression in reasonable time
```

**Cause:** Complex SwiftUI view with many fields changed simultaneously.

**Fix:** Break up complex views into smaller components, add type annotations.

### ❌ PITFALL 6: Missing Default Values

**Symptom:** App crashes on migration with "Unexpectedly found nil".

**Cause:** New required fields without safe defaults.

**Fix:** Always provide default values in schema model:
```swift
public var newField: String = "safe default"  // ✅ Not String?
```

### ❌ PITFALL 7: Lightweight vs Heavyweight Confusion

**Symptom:** Migration appears to work but data is corrupted or missing.

**Cause:** Used lightweight migration when heavyweight was needed.

**Rule:** If you're transforming data or changing semantics, use heavyweight (custom) migration.

---

## Rollback Strategy

### Before Migration

1. **Automatic Backup**
   ```swift
   // BackupManager creates backup before migration automatically
   // Located in: Documents/Backups/Ritualist_backup_<timestamp>.sqlite
   ```

2. **Manual Backup**
   ```
   Settings → Debug Menu → Database Backups → Create Backup
   ```

3. **Document current state**
   ```
   Schema Version: V(X-1)
   User Profile:
     - homeTimezone: <value>
     - displayTimezoneMode: <value>
   Habits: <count>
   Logs: <count>
   ```

### If Migration Fails

1. **Check console logs**
   ```
   Filter for: [Migration]
   Look for: error, failed, exception
   ```

2. **Restore from backup**
   ```
   Settings → Debug Menu → Database Backups → [Select backup] → Restore
   ```

3. **Restart app**
   - App will launch with V(X-1) database
   - All data intact

4. **Fix migration code**
   - Debug the issue
   - Update migration logic
   - Test with restored backup
   - Retry migration

### Backup Retention

**Keep backups for:**
- Last 3 schema versions
- At least 30 days
- Until new version ships to App Store

**Cleanup:**
```bash
# Manual cleanup via Debug Menu
Settings → Debug Menu → Database Backups → Swipe to Delete
```

---

## Post-Migration Verification

### Immediate Checks

- [ ] **App launches successfully**
- [ ] **No crash on startup**
- [ ] **Migration logs show success**
- [ ] **User profile loads correctly**
- [ ] **Habits display normally**
- [ ] **Logs are accessible**

### Data Verification

- [ ] **User settings preserved**
  ```swift
  // Check Debug Menu → Timezone Diagnostics
  Display Mode: <should match old value>
  Home Timezone: <should match old value>
  ```

- [ ] **All habits present**
  ```swift
  // Check Debug Menu → Database Statistics
  Habits: <same count as before>
  Logs: <same count as before>
  ```

- [ ] **Functionality intact**
  - [ ] Can create new habits
  - [ ] Can log completions
  - [ ] Streaks calculate correctly
  - [ ] Settings update properly

### Performance Checks

- [ ] **No unusual memory usage**
  ```swift
  // Check Debug Menu → Performance Statistics
  Memory Usage: <should be normal range>
  ```

- [ ] **No performance degradation**
  - [ ] App feels responsive
  - [ ] Scrolling is smooth
  - [ ] Database queries are fast

### Long-Term Monitoring

**First Week After Release:**
- Monitor crash reports for migration-related issues
- Check analytics for unusual data patterns
- Watch for user reports of missing data
- Verify CloudKit sync working correctly

**First Month:**
- Ensure all users successfully migrated
- Check backup storage isn't growing unbounded
- Verify old schema versions can still upgrade

---

## Master Checklist Summary

Use this abbreviated checklist for quick verification:

### Planning
- [ ] Migration requirements documented
- [ ] Data preservation strategy defined
- [ ] Safe defaults identified
- [ ] Affected code locations listed

### Implementation
- [ ] Domain model updated
- [ ] Schema VX created
- [ ] Migration plan updated
- [ ] All old schemas updated (V1 through V(X-1))
- [ ] ActiveSchema type aliases updated
- [ ] Data sources updated
- [ ] Cloud mapper updated
- [ ] Use cases updated
- [ ] UI updated

### Safety
- [ ] Build succeeds
- [ ] All tests pass
- [ ] Old data preservation verified
- [ ] Default values are safe
- [ ] Error handling robust
- [ ] No hardcoded schema versions

### Testing
- [ ] Migration tested with real data
- [ ] Logs confirm success
- [ ] Data verified in Debug Menu
- [ ] Rollback tested
- [ ] CloudKit sync tested (if applicable)

### Deployment
- [ ] Backup created before migration
- [ ] Console monitored during first launch
- [ ] User data verified intact
- [ ] Performance normal
- [ ] No crash reports

---

## Version History

| Version | Date | Change | Notes |
|---------|------|--------|-------|
| V9 | 2025-11-15 | Three-Timezone Model | Added currentTz, homeTz, displayMode (enum), history |
| V8 | 2025-11-XX | Removed subscription fields | Moved to SubscriptionService |
| V7 | 2025-11-XX | Location-aware habits | Added geofencing support |
| ... | ... | ... | ... |

---

## Additional Resources

**SwiftData Documentation:**
- [Migrating schema versions](https://developer.apple.com/documentation/swiftdata/migrating-your-swiftdata-schema)
- [Migration plans](https://developer.apple.com/documentation/swiftdata/schemamigrationplan)

**Internal Files:**
- `/docs/reference/versioning/schema-migrations.md` - Schema version history
- `/docs/migration-guides/` - Individual migration guides
- `MigrationPlan.swift` - Current migration code
- `BackupManager.swift` - Backup/restore implementation

**Debugging:**
- Settings → Debug Menu → Migration History
- Settings → Debug Menu → Database Backups
- Settings → Debug Menu → Timezone Diagnostics

---

## Emergency Contacts

**If migration fails catastrophically:**

1. **Stop rollout immediately**
2. **Collect crash logs and user reports**
3. **Prepare hotfix with rollback instructions**
4. **Document issue for future prevention**

**Data Recovery:**
- Backups stored in: `Documents/Backups/`
- Retention: 30 days minimum
- Recovery procedure: Debug Menu → Database Backups → Restore

---

**Remember:** Data loss is unacceptable. When in doubt, test more thoroughly.
