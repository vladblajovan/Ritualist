# SwiftData Migration Strategy Implementation Plan

## Current State Analysis

### ✅ What We Have
- 6 SwiftData models (Habit, HabitLog, Category, UserProfile, OnboardingState, PersonalityAnalysis)
- Proper @Relationship setup with cascade/nullify rules
- App group sharing for widgets: `group.com.vladblajovan.Ritualist`
- CloudKit-ready default values

### ❌ Critical Gap: NO MIGRATION STRATEGY
- Comment in PersistenceContainer.swift: "Use direct models without versioning"
- **ANY SCHEMA CHANGE = USERS LOSE ALL DATA**
- No VersionedSchema implementation
- No SchemaMigrationPlan
- No backup/rollback capability

## Implementation Progress

### Phase 1: Create Versioned Schema System (2-3 hours)

- [x] **1.1 Create SchemaV1.swift** ✅
  - File: `RitualistCore/Sources/RitualistCore/Storage/SchemaV1.swift`
  - Snapshot current models as V1
  - Implement VersionedSchema protocol
  - Include all 6 models: HabitModel, HabitLogModel, HabitCategoryModel, UserProfileModel, OnboardingStateModel, PersonalityAnalysisModel

- [x] **1.2 Create MigrationPlan.swift** ✅
  - File: `RitualistCore/Sources/RitualistCore/Storage/MigrationPlan.swift`
  - Implement SchemaMigrationPlan protocol
  - Define migration stages (V1 -> V2 when needed)
  - Add lightweight migration support for simple property changes

- [x] **1.3 Update PersistenceContainer.swift** ✅
  - Switch from direct models to versioned schema
  - Add migration options configuration
  - Add migration logging and error handling
  - Maintain app group sharing and CloudKit compatibility

### Phase 2: Migration Safety Features (1-2 hours)

- [x] **2.1 Create BackupManager.swift** ✅
  - File: `RitualistCore/Sources/RitualistCore/Storage/BackupManager.swift`
  - Automatic SQLite backup before migrations
  - Rollback capability on migration failure
  - Backup retention policy (keep 3 most recent)

- [x] **2.2 Create MigrationLogger.swift** ✅
  - File: `RitualistCore/Sources/RitualistCore/Storage/MigrationLogger.swift`
  - Log migration start/success/failure
  - Track schema version transitions
  - User notification of migration progress
  - Debug logging for troubleshooting

### Phase 3: Future-Proofing (1 hour)

- [x] **3.1 Create Migration Tests** ✅
  - File: `RitualistCore/Tests/RitualistCoreTests/MigrationTests/SchemaV1Tests.swift`
  - File: `RitualistCore/Tests/RitualistCoreTests/MigrationTests/MigrationIntegrityTests.swift`
  - Unit tests for schema V1 validation
  - Test data generation for migration scenarios
  - Verification of data integrity post-migration

- [x] **3.2 Add Debug Menu for Testing Migrations** ✅
  - Add schema version display in Settings
  - Add migration history viewer (debug builds only)
  - Add database backup/restore UI (debug builds only)

- [x] **3.3 Create Migration Documentation** ✅
  - File: `.github/MIGRATION_GUIDE.md`
  - Guide for adding new schema versions
  - Checklist for schema changes
  - Common migration patterns and examples

### Phase 4: Real-World Migration Testing (1-2 hours)

- [x] **4.1 Create SchemaV2.swift** ✅
  - File: `RitualistCore/Sources/RitualistCore/Storage/SchemaV2.swift`
  - Added `isPinned: Bool = false` property to HabitModelV2
  - All other models unchanged (V2 suffix, same structure)
  - Test lightweight migration with property addition

- [x] **4.2 Implement V1→V2 Migration** ✅
  - Updated `MigrationPlan.swift` with V1→V2 migration stage
  - Added `migrateV1toV2` custom migration with:
    - `willMigrate`: Creates backup, logs migration start
    - `didMigrate`: Verifies data, logs success, prints migration details
  - Migration validates all habits migrated with isPinned default value

- [x] **4.3 Update PersistenceContainer to V2** ✅
  - Changed from `SchemaV1.self` to `SchemaV2.self`
  - Updated logging to indicate V2 schema
  - Ready for end-to-end migration testing

- [x] **4.4 Update Debug UI** ✅
  - Updated DebugMenuView to show "V2.0.0" (blue indicator)
  - Updated description to "SwiftData versioned schema with V1→V2 migration"
  - Build succeeded - ready for migration testing

## File Structure

```
RitualistCore/Sources/RitualistCore/Storage/
├── PersistenceContainer.swift (updated - now uses SchemaV2)
├── SchemaV1.swift (new - baseline snapshot)
├── SchemaV2.swift (new - V2 with isPinned property)
├── MigrationPlan.swift (new - includes V1→V2 migration)
├── MigrationLogger.swift (new)
└── BackupManager.swift (new)

RitualistTests/
└── MigrationTests/ (new)
    ├── SchemaV1Tests.swift
    └── MigrationIntegrityTests.swift

.github/
└── MIGRATION_GUIDE.md (new)
```

## Benefits

- ✅ **Safe schema evolution** - Add/remove properties without data loss
- ✅ **Automatic migrations** - Lightweight migrations handle simple changes
- ✅ **Manual migration support** - Complex changes via heavyweight migration
- ✅ **Backup/rollback** - Users protected from migration failures
- ✅ **Testing** - Migration paths validated before release
- ✅ **CloudKit ready** - Schema versioning compatible with future CloudKit sync

## Risk Mitigation

- Backup before every migration
- Test migrations on copy of production data
- Phased rollout with version checks
- Ability to rollback to previous version

## Current Models Snapshot

### HabitModel
- id, name, colorHex, emoji, kindRaw
- scheduleType, scheduleDaysOfWeek, reminderTime
- @Relationship logs (cascade delete)
- @Relationship category (nullify)

### HabitLogModel
- id, habitID, date, value, timezone
- @Relationship habit

### HabitCategoryModel
- id, name, colorHex, emoji, isSystem, sortOrder
- @Relationship habits (cascade delete)

### UserProfileModel
- id, weekStartDay, preferredTimeZone, darkModeEnabled
- notificationsEnabled, hasSeenOnboarding, subscriptionStatus

### OnboardingStateModel
- id, hasCompletedOnboarding, currentStep, lastUpdated

### PersonalityAnalysisModel
- id, userId, analysisDate
- openness, conscientiousness, extraversion, agreeableness, neuroticism
- confidence, habitCount, completionRate

## Notes

- Current implementation uses direct models: **HIGH RISK** for production app
- Migration system is **CRITICAL** before any schema changes
- All 6 models must be versioned together in SchemaV1
- App group sharing must be preserved: `group.com.vladblajovan.Ritualist`
- CloudKit compatibility must be maintained
