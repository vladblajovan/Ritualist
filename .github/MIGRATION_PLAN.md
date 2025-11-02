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

## File Structure

```
RitualistCore/Sources/RitualistCore/Storage/
├── PersistenceContainer.swift (updated)
├── SchemaV1.swift (new)
├── MigrationPlan.swift (new)
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

## Current Status (Updated: Nov 2, 2025)

### ⚠️ IMPORTANT: Versioned Schema System NOT ACTIVE

The migration system (SchemaV1, MigrationPlan) is **implemented but not currently in use**.

**Reason:** Architectural incompatibility discovered:
- Versioned schemas require ALL code to use versioned model types (e.g., `SchemaV1.HabitModelV1`)
- Our datasources use actual model types (e.g., `HabitModel`)
- This type mismatch causes empty app (ModelContainer expects different types than datasources query)

**Current Configuration:**
```swift
// PersistenceContainer.swift
container = try ModelContainer(
    for: HabitModel.self,
        HabitLogModel.self,
        HabitCategoryModel.self,
        UserProfileModel.self,
        OnboardingStateModel.self,
        PersonalityAnalysisModel.self,
    configurations: configuration
)
```

**To Activate Migration System in Future:**
We need to choose ONE of these approaches:

1. **Option A: Refactor to Versioned Types (Recommended for production)**
   - Update ALL datasources to use `SchemaV1.HabitModelV1` instead of `HabitModel`
   - Update ALL repositories to work with versioned types
   - More work upfront, but enables safe future migrations

2. **Option B: Different Migration Strategy**
   - Research SwiftData migration approaches that preserve actual model types
   - May involve custom migration logic outside of VersionedSchema system
   - Less invasive but potentially less safe

**For Now:**
- App uses direct models (same as before migration work)
- Migration infrastructure exists but dormant
- No schema evolution capability until we choose and implement Option A or B

## Notes

- Current implementation uses direct models (reverted from versioned schema)
- Migration system infrastructure exists but is not active
- All 6 models must be versioned together when we activate the system
- App group sharing preserved: `group.com.vladblajovan.Ritualist`
- CloudKit compatibility maintained
