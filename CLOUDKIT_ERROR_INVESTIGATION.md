# CloudKit Error Investigation Report

**Date:** January 2026
**Issue:** CloudKit console alarm triggered for >8 daily SwiftData sync errors

---

## Executive Summary

Investigation of the Ritualist codebase revealed **13 potential error sources** in the SwiftData/CloudKit integration that could cause sync failures. The primary culprits are:

1. Silent JSON encoding failures with `try?` that fall back to empty `Data()`
2. Missing error logging in all data source implementations
3. No pre-save validation for CloudKit-required fields
4. Systemic duplicate record creation (evidenced by 50-iteration deduplication)

---

## Critical Issues

### 1. Silent JSON Encoding Failures

**Severity:** CRITICAL
**Location:** `RitualistCore/Sources/RitualistCore/DataSources/Implementations/ProfileLocalDataSource.swift:38-45`

```swift
// SILENT FAILURE POINT 1
if let modeData = try? JSONEncoder().encode(profile.displayTimezoneMode) {
    existing.displayTimezoneModeData = modeData
}
// If encoding fails, modeData is NOT set, leaving stale data in database

// SILENT FAILURE POINT 2
if let historyData = try? JSONEncoder().encode(profile.timezoneChangeHistory) {
    existing.timezoneChangeHistoryData = historyData
}
// If encoding fails, the history data won't update
```

**Impact:**
- When JSON encoding fails (memory pressure, non-serializable objects), data is silently lost
- CloudKit attempts to sync empty/corrupted Data fields
- Different devices receive inconsistent timezone data
- Generates CloudKit errors when trying to sync invalid data structures

**Similar patterns in:** `RitualistCore/Sources/RitualistCore/Storage/SchemaV11.swift` (Lines 351, 392, 535, 543, 567, 570)

---

### 2. Missing Error Handling in Data Sources

**Severity:** CRITICAL
**Location:** `RitualistCore/Sources/RitualistCore/DataSources/Implementations/HabitLocalDataSource.swift`

Lines 18-20, 33-35, 60-62, 81-83 all have:
```swift
catch {
    // TODO: Add error handler integration when DI allows it
    // For now, just re-throw the error
    throw error
}
```

**Impact:**
- SwiftData errors during `modelContext.fetch()`, `.save()`, and `.insert()` are not logged
- Silent failures in data conversion (`toEntity()`) during `compactMap` operations
- No visibility into which specific database operations fail
- Cannot distinguish between transient and permanent failures
- Upstream callers receive errors without context, making CloudKit sync issues appear sporadic

**Affected Operations:**
| Method | Line Numbers |
|--------|--------------|
| `fetchAll()` | 10-21 |
| `fetch(by id:)` | 25-36 |
| `upsert()` | 40-62 |
| `delete()` | 66-83 |

**Same pattern exists in:**
- `LogLocalDataSource.swift`
- `ProfileLocalDataSource.swift`
- `CategoryLocalDataSource.swift`
- `TipLocalDataSource.swift`

---

### 3. Default Empty Data Fields

**Severity:** CRITICAL
**Location:** `RitualistCore/Sources/RitualistCore/Storage/SchemaV11.swift`

```swift
public var displayTimezoneModeData: Data = Data()  // Line 203
public var timezoneChangeHistoryData: Data = Data()  // Line 207
public var scheduleData: Data = Data()  // Line 55
public var remindersData: Data = Data()  // Line 56
```

**Problem:**
- Empty `Data()` is valid default but loses actual content if JSON encoding fails
- When CloudKit syncs and `try?` encoding fails, the default empty Data is used
- Remote devices receive empty timezone/schedule data instead of user's actual data
- No way to distinguish between "user set empty data" vs "encoding failed"

**Cascade Effect:**
1. User saves profile with timezone info
2. Encoding fails silently
3. Empty `Data()` stored locally
4. Device syncs to CloudKit with empty Data
5. Another device pulls down empty Data
6. User's actual timezone configuration is lost on that device

---

## High Priority Issues

### 4. Optional Relationship Arrays

**Severity:** HIGH
**Location:** `RitualistCore/Sources/RitualistCore/Storage/SchemaV11.swift:68-70, 161-163`

```swift
// HabitModel
@Relationship(deleteRule: .cascade, inverse: \HabitLogModel.habit)
public var logs: [HabitLogModel]?  // Made optional for CloudKit

// HabitCategoryModel
@Relationship(deleteRule: .nullify, inverse: \HabitModel.category)
public var habits: [HabitModel]?  // Made optional for CloudKit
```

**Analysis:**
- Made optional in V10 migration for CloudKit compatibility
- When relationships are `nil` vs empty `[]`, CloudKit sync behaves differently
- Cascade deletes may not trigger properly if inverse relationship is nil
- Orphaned records can accumulate if relationship traversal fails

**Documentation:** See `MigrationPlan.swift:273-290` with explicit note: "CloudKit requires optional"

---

### 5. Deduplication as Symptom of Systemic Issue

**Severity:** HIGH
**Location:** `Ritualist/Application/Coordinators/ICloudSyncCoordinator.swift:123-166`

```swift
private func performInitialDeduplication() async {
    // Runs 50 times on first sync (maxInitialDedupAttempts = 50)
    // Indicates that duplicate records are being created
}
```

**The Real Problem:**
- Duplicates being created suggests CloudKit sync is creating multiple copies of records
- This happens when:
  - SwiftData's unique constraint was removed (V9→V10) but CloudKit still sees duplicates
  - Network retry logic causes duplicate inserts
  - Multiple devices sync the same logical record with different UUIDs
- The deduplication runs 50 times in initial sync, indicating systemic duplicate creation

---

### 6. Race Condition in Model Save

**Severity:** HIGH
**Location:** `RitualistCore/Sources/RitualistCore/DataSources/Implementations/LogLocalDataSource.swift:33-51`

```swift
if let existing = try modelContext.fetch(descriptor).first {
    // Update fields
    existing.habitID = log.habitID
    existing.date = log.date
    // ... NO explicit save() here - relying on auto-save
} else {
    let habitLogModel = ActiveHabitLogModel.fromEntity(log, context: modelContext)
    modelContext.insert(habitLogModel)
}

try modelContext.save()  // Single save at end
```

**Potential Issue:**
- If an exception occurs after the `if-else` but before `save()`, the update is lost
- If `fromEntity()` fails for existing records, they remain in inconsistent state
- No transactional guarantee - partial updates could sync to CloudKit

---

### 7. Empty String Default IDs

**Severity:** HIGH
**Location:** `RitualistCore/Sources/RitualistCore/Storage/SchemaV11.swift`

```swift
public var id: String = ""  // Added default value for CloudKit
public var name: String = ""
public var colorHex: String = "#007AFF"
```

**Concern:**
- Empty string defaults are valid in SwiftData but problematic for CloudKit sync
- CloudKit requires non-empty identifying fields for proper record matching
- When these defaults are synced, CloudKit records become incomplete
- No validation before saving to modelContext

---

## Medium Priority Issues

### 8. Schema V12 Removed Due to Checksum Issue

**Severity:** MEDIUM
**Location:** `RitualistCore/Sources/RitualistCore/Storage/ActiveSchema.swift:26-29`

```swift
/// NOTE: Reverted from V12 to V11 because V12 had identical checksum (no schema changes)
/// SwiftData crashes when two schemas have the same checksum in migration plan
public typealias ActiveSchemaVersion = SchemaV11
```

**Impact:**
- Indicates fragile schema versioning
- If a schema change is made that doesn't affect checksum, SwiftData crashes
- Error: `NSLightweightMigrationStage initWithVersionChecksums: error`
- Migrations are brittle and prone to hidden failures

---

### 9. #Index Macro Breaks CloudKit Sync

**Severity:** MEDIUM (documented workaround in place)
**Location:** `RitualistCore/Sources/RitualistCore/Storage/MigrationPlan.swift:327-331`

```swift
// CRITICAL LEARNING: #Index macro breaks CloudKit sync!
// - SwiftData's #Index causes CloudKit sync to fail SILENTLY
// - No errors thrown, data simply doesn't sync
// - CloudKit has its own indexing in CloudKit Console
// - DO NOT use #Index until Apple fixes this
```

**Status:** Documented and avoided, but important to remember for future development.

---

### 10. Main Thread Blocking in Init

**Severity:** MEDIUM
**Location:** `RitualistCore/Sources/RitualistCore/Storage/PersistenceContainer.swift:54-81`

```swift
let migrationWillOccur = lastVersionString != nil && lastVersionString != currentVersionString
if migrationWillOccur, let lastVersion = lastVersionString {
    if Thread.isMainThread {
        MainActor.assumeIsolated {
            MigrationStatusService.shared.startMigration(...)
        }
    } else {
        DispatchQueue.main.sync {
            MainActor.assumeIsolated {
                MigrationStatusService.shared.startMigration(...)
            }
        }
    }
}

Thread.sleep(forTimeInterval: 0.1)  // Blocks for 100ms during init()
```

**Issues:**
- Using `Thread.sleep()` in init() is a blocking operation
- If main thread is blocked, other operations may timeout
- Multiple `MainActor.assumeIsolated` calls could race
- CloudKit remote change notifications may miss the migration window

---

### 11. Silent Failures in Category Seeding

**Severity:** MEDIUM
**Location:** `RitualistCore/Sources/RitualistCore/DataSources/Implementations/CategoryLocalDataSource.swift:59-85`

```swift
public func createCustomCategory(_ category: HabitCategory) async throws {
    let categoryModel = ActiveHabitCategoryModel.fromEntity(category)
    modelContext.insert(categoryModel)
    try modelContext.save()
}
```

**Issue:**
- If `fromEntity()` creates a model with empty `id` (default value), CloudKit sync will fail or create duplicates
- No validation that category has valid ID before inserting

---

### 12. Profile Save Doesn't Validate Timezone Data

**Severity:** MEDIUM
**Location:** `RitualistCore/Sources/RitualistCore/DataSources/Implementations/ProfileLocalDataSource.swift:27-58`

```swift
if let existing = try modelContext.fetch(descriptor).first {
    // ... timezone encoding with try? that fails silently
    existing.gender = profile.gender  // New in V11
    existing.ageGroup = profile.ageGroup  // New in V11
    existing.updatedAt = profile.updatedAt
} else {
    let userProfileModel = ActiveUserProfileModel.fromEntity(profile)
    modelContext.insert(userProfileModel)
}
```

**Issue:**
- Demographics fields (gender, ageGroup) are new in V11
- If they're not properly initialized in migrated records, they'll be nil
- CloudKit may reject records with inconsistent optional field handling
- No logging of what actually gets saved

---

### 13. Migration Plan Complexity

**Severity:** MEDIUM
**Location:** `RitualistCore/Sources/RitualistCore/Storage/MigrationPlan.swift`

- 11 schemas tracked (V1-V12, with V1 and V12 removed)
- Custom migration for V8→V9 but lightweight for others
- **Risk:** Each schema version is a potential failure point
- If legacy device is on V5 and tries to sync with CloudKit records from V11, sync may fail

---

## Summary Table

| # | Issue | Severity | File | Impact |
|---|-------|----------|------|--------|
| 1 | Silent JSON encoding failures | CRITICAL | ProfileLocalDataSource.swift:38-45 | Empty Data synced to CloudKit |
| 2 | No error logging in data sources | CRITICAL | All *LocalDataSource.swift files | No visibility into failures |
| 3 | Default empty Data() fields | CRITICAL | SchemaV11.swift | Cross-device data loss |
| 4 | Optional relationship arrays | HIGH | SchemaV11.swift:68-70 | Cascade deletes may fail |
| 5 | Systemic duplicate creation | HIGH | ICloudSyncCoordinator.swift | 50x deduplication needed |
| 6 | Race condition in saves | HIGH | LogLocalDataSource.swift:33-51 | Partial updates sync |
| 7 | Empty string default IDs | HIGH | SchemaV11.swift | Invalid CloudKit records |
| 8 | Schema checksum fragility | MEDIUM | ActiveSchema.swift | Migration crashes |
| 9 | #Index breaks CloudKit | MEDIUM | MigrationPlan.swift:327 | Silent sync failures |
| 10 | Main thread blocking | MEDIUM | PersistenceContainer.swift | Notification timeouts |
| 11 | No category validation | MEDIUM | CategoryLocalDataSource.swift | Duplicate categories |
| 12 | No profile validation | MEDIUM | ProfileLocalDataSource.swift | Incomplete records |
| 13 | Migration complexity | MEDIUM | MigrationPlan.swift | Cross-version sync issues |

---

## Recommended Fixes (Priority Order)

### Immediate (Fix CloudKit Errors)

1. **Add try-catch logging** around all JSON encode/decode operations
   - Replace `try?` with `do-catch` that logs the error before falling back
   - This provides visibility into what's actually failing

2. **Add comprehensive logging** to all data source operations
   - Inject `DebugLogger` into data sources
   - Log every save, fetch, and delete with context

3. **Validate timezone/schedule data** before setting empty defaults
   - If encoding fails, log the error and keep existing data
   - Don't overwrite valid data with empty Data()

### Short-term (Prevent Data Loss)

4. **Add pre-save validation** for required fields
   - Validate `id` is not empty before insert
   - Validate relationships are properly set

5. **Make relationship optional handling explicit**
   - Add null checks before cascade operations
   - Log when relationships are unexpectedly nil

6. **Replace Thread.sleep()** with async alternatives in PersistenceContainer init

### Long-term (Architecture)

7. **Add CloudKit field validation layer** before any sync operations
8. **Monitor schema checksum stability** during development
9. **Consider adding a DataSourceErrorHandler** protocol for centralized error handling
10. **Add telemetry** to track which specific operations fail most often

---

## How to Debug Further

### Check CloudKit Console
1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
2. Select your container
3. Check "Logs" → "Server-to-Server" for specific error messages
4. Look for "Record Zone Not Found", "Conflict", or "Server Rejected" errors

### Add Temporary Logging
```swift
// In ProfileLocalDataSource.save()
do {
    let modeData = try JSONEncoder().encode(profile.displayTimezoneMode)
    existing.displayTimezoneModeData = modeData
} catch {
    logger.log("Failed to encode displayTimezoneMode: \(error)", level: .error, category: .dataIntegrity)
    // Keep existing data instead of setting empty
}
```

### Monitor Deduplication
```swift
// In ICloudSyncCoordinator
logger.log("Deduplication attempt \(attempt) of \(maxAttempts)", level: .info, category: .dataIntegrity, metadata: [
    "duplicates_found": duplicateCount,
    "records_merged": mergedCount
])
```

---

## References

- [SwiftData and CloudKit Best Practices](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices)
- [CloudKit Error Codes](https://developer.apple.com/documentation/cloudkit/ckerror/code)
- Internal: `MigrationPlan.swift` contains extensive documentation on schema evolution decisions
