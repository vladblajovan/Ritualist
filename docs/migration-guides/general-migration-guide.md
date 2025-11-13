# SwiftData Migration Guide

This guide explains how to safely add new schema versions and perform migrations in Ritualist.

## Table of Contents

1. [When to Create a New Schema Version](#when-to-create-a-new-schema-version)
2. [Step-by-Step Migration Process](#step-by-step-migration-process)
3. [Lightweight vs Heavyweight Migrations](#lightweight-vs-heavyweight-migrations)
4. [Testing Migrations](#testing-migrations)
5. [Common Migration Patterns](#common-migration-patterns)
6. [Troubleshooting](#troubleshooting)

## When to Create a New Schema Version

Create a new schema version when you need to:

- ✅ Add a new property to an existing model
- ✅ Remove a property from a model
- ✅ Change a property's type
- ✅ Add a new model
- ✅ Remove a model
- ✅ Change relationships between models
- ✅ Rename properties (with migration mapping)

**IMPORTANT**: Any schema change requires a new version. Never modify existing schema versions!

## Step-by-Step Migration Process

### 1. Create New Schema Version

Create `SchemaVX.swift` in `RitualistCore/Sources/RitualistCore/Storage/`:

```swift
//
//  SchemaV2.swift
//  RitualistCore
//
//  Created by [Your Name] on [Date].
//

import Foundation
import SwiftData

enum SchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            HabitModelV2.self,
            HabitLogModelV2.self,
            HabitCategoryModelV2.self,
            UserProfileModelV2.self,
            OnboardingStateModelV2.self,
            PersonalityAnalysisModelV2.self
        ]
    }

    // Copy models from V1 and make your changes
    @Model
    final class HabitModelV2 {
        @Attribute(.unique) var id: UUID
        var name: String = ""
        var colorHex: String = "#007AFF"
        var emoji: String?
        var kindRaw: Int = 0
        var unitLabel: String?
        var dailyTarget: Double?
        var scheduleData: Data = Data()
        var remindersData: Data = Data()
        var startDate: Date = Date()
        var endDate: Date?
        var isActive: Bool = true
        var displayOrder: Int = 0
        var suggestionId: String?

        // NEW PROPERTY EXAMPLE:
        var isPinned: Bool = false  // Add new properties with default values

        @Relationship(deleteRule: .cascade, inverse: \HabitLogModelV2.habit)
        var logs: [HabitLogModelV2] = []

        var category: HabitCategoryModelV2?

        init(/* ... include all properties ... */) {
            // Initialize all properties
        }
    }

    // ... copy all other models from V1 ...
}

// Type aliases for easier reference
typealias HabitModelV2 = SchemaV2.HabitModelV2
// ... etc for all models ...
```

### 2. Add Schema to Migration Plan

Update `MigrationPlan.swift`:

```swift
enum RitualistMigrationPlan: SchemaMigrationPlan {

    static var schemas: [any VersionedSchema.Type] {
        [
            SchemaV1.self,
            SchemaV2.self  // ← Add new schema here
        ]
    }

    static var stages: [MigrationStage] {
        [
            migrateV1toV2  // ← Add migration stage
        ]
    }

    // Define migration from V1 to V2
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}
```

### 3. Update Current Models

Update your current models (HabitModel, HabitLogModel, etc.) to match V2:

```swift
// HabitModel.swift
@Model public final class HabitModel: @unchecked Sendable {
    // ... existing properties ...

    public var isPinned: Bool = false  // Add new property

    // ... rest of model ...
}
```

### 4. Create Migration Tests

Create test file in `RitualistCore/Tests/RitualistCoreTests/MigrationTests/`:

```swift
//
//  SchemaV1toV2Tests.swift
//  RitualistCoreTests
//

import Testing
import SwiftData
@testable import RitualistCore

struct SchemaV1toV2Tests {

    @Test("Migration from V1 to V2 adds isPinned property")
    func testMigrationAddsIsPinnedProperty() throws {
        // Test that new property exists and has correct default
        // Implementation depends on your migration testing strategy
    }

    @Test("Migration from V1 to V2 preserves all existing data")
    func testMigrationPreservesData() throws {
        // Verify no data loss during migration
    }
}
```

### 5. Test Locally

1. **Run Tests**: `⌘+U` to run all migration tests
2. **Build App**: `⌘+B` to verify compilation
3. **Test Migration**:
   - Run app with test data
   - Check Debug Menu → Migration Management → Migration History
   - Verify schema version shows V2.0.0
   - Verify all data is intact

### 6. Deployment

1. Increment app version in Xcode (Info.plist)
2. Add migration notes to release notes
3. Submit to TestFlight for beta testing
4. Monitor crash reports and migration logs
5. Release to production after successful beta period

## Lightweight vs Heavyweight Migrations

### Lightweight Migrations (Recommended)

Use for simple schema changes that SwiftData can handle automatically:

```swift
static let migrateV1toV2 = MigrationStage.lightweight(
    fromVersion: SchemaV1.self,
    toVersion: SchemaV2.self
)
```

**Works for:**
- Adding optional properties
- Adding properties with default values
- Removing properties
- Renaming properties (with renaming hint)

### Heavyweight Migrations (Custom Logic)

Use for complex transformations:

```swift
static let migrateV2toV3 = MigrationStage.custom(
    fromVersion: SchemaV2.self,
    toVersion: SchemaV3.self,
    willMigrate: { context in
        // Pre-migration setup
        print("Starting V2 → V3 migration")

        // Create backup
        let backupManager = BackupManager()
        try backupManager.createBackup()

        // Log migration start
        MigrationLogger.shared.logMigrationStart(from: "2.0.0", to: "3.0.0")
    },
    didMigrate: { context in
        // Post-migration data transformations
        let habits = try context.fetch(FetchDescriptor<HabitModelV3>())

        for habit in habits {
            // Example: Migrate colorHex to new color system
            if habit.colorHex == "#FF0000" {
                habit.colorV3 = .systemRed
            }
        }

        try context.save()

        // Log success
        MigrationLogger.shared.logMigrationSuccess(
            from: "2.0.0",
            to: "3.0.0",
            duration: 1.5
        )
    }
)
```

**Use for:**
- Complex data transformations
- Relationship restructuring
- Data validation and cleanup
- Merging/splitting entities

## Testing Migrations

### Manual Testing

1. **Prepare Test Environment**:
   ```bash
   # Debug Menu → Test Data → Test Data Scenarios
   # Populate database with comprehensive test data
   ```

2. **Create Pre-Migration Backup**:
   ```bash
   # Debug Menu → Migration Management → Create Backup Now
   ```

3. **Verify Migration**:
   - Check Migration History shows success
   - Verify all habits/logs/categories are intact
   - Test all app features
   - Check for data inconsistencies

### Automated Testing

```swift
@Test("Full migration from V1 to V2 preserves relationships")
func testV1toV2MigrationPreservesRelationships() throws {
    // 1. Create V1 container with test data
    let v1Container = try createV1TestContainer()
    let v1Context = ModelContext(v1Container)

    // Add test data with relationships
    let category = HabitCategoryModelV1(id: "test", name: "Test", /* ... */)
    let habit = HabitModelV1(id: UUID(), name: "Test Habit", /* ... */)
    habit.category = category
    v1Context.insert(category)
    v1Context.insert(habit)
    try v1Context.save()

    // 2. Perform migration
    let v2Container = try performMigration(from: v1Container)
    let v2Context = ModelContext(v2Container)

    // 3. Verify data integrity
    let habits = try v2Context.fetch(FetchDescriptor<HabitModelV2>())
    #expect(habits.count == 1)
    #expect(habits.first?.category?.name == "Test")
}
```

## Common Migration Patterns

### Pattern 1: Adding Optional Property

**Scenario**: Add `notes` field to HabitModel

```swift
// V2 Model
@Model
final class HabitModelV2 {
    // ... existing properties ...
    var notes: String?  // New optional property
}

// Migration
static let migrateV1toV2 = MigrationStage.lightweight(
    fromVersion: SchemaV1.self,
    toVersion: SchemaV2.self
)
```

### Pattern 2: Adding Property with Default Value

**Scenario**: Add `isPinned` field with default false

```swift
// V2 Model
@Model
final class HabitModelV2 {
    // ... existing properties ...
    var isPinned: Bool = false  // New property with default
}

// Migration
static let migrateV1toV2 = MigrationStage.lightweight(
    fromVersion: SchemaV1.self,
    toVersion: SchemaV2.self
)
```

### Pattern 3: Renaming Property

**Scenario**: Rename `colorHex` to `themeColor`

```swift
// V2 Model
@Model
final class HabitModelV2 {
    var themeColor: String = "#007AFF"  // Renamed from colorHex

    init(/* ... */) {
        // ...
    }
}

// Migration with custom logic
static let migrateV1toV2 = MigrationStage.custom(
    fromVersion: SchemaV1.self,
    toVersion: SchemaV2.self,
    willMigrate: nil,
    didMigrate: { context in
        // Map old colorHex values to new themeColor property
        let habits = try context.fetch(FetchDescriptor<HabitModelV2>())
        for habit in habits {
            // Property automatically migrated by SwiftData
            // but you can perform additional transformations here
        }
    }
)
```

### Pattern 4: Changing Property Type

**Scenario**: Change `appearance` from String to Int

```swift
// V2 Model
@Model
final class UserProfileModelV2 {
    var appearance: Int = 0  // Changed from String
}

// Migration requires custom logic
static let migrateV1toV2 = MigrationStage.custom(
    fromVersion: SchemaV1.self,
    toVersion: SchemaV2.self,
    willMigrate: nil,
    didMigrate: { context in
        let profiles = try context.fetch(FetchDescriptor<UserProfileModelV2>())
        for profile in profiles {
            // Convert string appearance to int
            // This requires storing old value or providing mapping logic
        }
        try context.save()
    }
)
```

### Pattern 5: Adding New Model

**Scenario**: Add HabitStreakModel

```swift
// V2 Schema
static var models: [any PersistentModel.Type] {
    [
        HabitModelV2.self,
        HabitLogModelV2.self,
        HabitCategoryModelV2.self,
        UserProfileModelV2.self,
        OnboardingStateModelV2.self,
        PersonalityAnalysisModelV2.self,
        HabitStreakModelV2.self  // ← New model
    ]
}

@Model
final class HabitStreakModelV2 {
    @Attribute(.unique) var id: UUID
    var habitID: UUID
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastCompletedDate: Date?
}

// Migration
static let migrateV1toV2 = MigrationStage.custom(
    fromVersion: SchemaV1.self,
    toVersion: SchemaV2.self,
    willMigrate: nil,
    didMigrate: { context in
        // Calculate streaks for existing habits
        let habits = try context.fetch(FetchDescriptor<HabitModelV2>())
        for habit in habits {
            let streak = HabitStreakModelV2(id: UUID(), habitID: habit.id)
            // Calculate streak from habit logs
            context.insert(streak)
        }
        try context.save()
    }
)
```

## Troubleshooting

### Migration Fails with "Model Not Found"

**Problem**: SwiftData can't find the model class

**Solution**:
1. Verify model is included in `SchemaVX.models` array
2. Check type aliases are correctly defined
3. Ensure model class name matches reference

### Migration Fails with "Incompatible Types"

**Problem**: Property type changed without custom migration

**Solution**: Use heavyweight migration with custom type conversion logic

### Data Loss After Migration

**Problem**: Data missing after migration completes

**Solution**:
1. Check BackupManager has backup before migration
2. Restore from backup: Debug Menu → Database Backups → Select backup → Restore
3. Review migration logic for data transformation bugs
4. Add logging to migration didMigrate block

### App Crashes on Launch After Migration

**Problem**: Migration completed but app crashes

**Solution**:
1. Check logs: Debug Menu → Migration History
2. Verify all models properly initialized
3. Test with clean database first
4. Restore from pre-migration backup

### Migration Never Completes

**Problem**: Migration hangs indefinitely

**Solution**:
1. Check for deadlocks in custom migration logic
2. Verify heavyweight migration doesn't have infinite loops
3. Add logging to track progress
4. Test migration with smaller dataset first

## Best Practices

### 1. Always Create Backup First

```swift
// In didMigrate block
let backupManager = BackupManager()
try backupManager.createBackup()
```

### 2. Log All Migration Events

```swift
MigrationLogger.shared.logMigrationStart(from: "1.0.0", to: "2.0.0")
// ... perform migration ...
MigrationLogger.shared.logMigrationSuccess(from: "1.0.0", to: "2.0.0", duration: duration)
```

### 3. Test with Production-Like Data

Use Debug Menu → Test Data Scenarios to populate realistic datasets before testing migrations

### 4. Never Skip Versions

Always migrate incrementally: V1 → V2 → V3, never V1 → V3

### 5. Document Breaking Changes

Add migration notes to CHANGELOG.md for every schema version

## References

- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [VersionedSchema Protocol](https://developer.apple.com/documentation/swiftdata/versionedschema)
- [SchemaMigrationPlan Protocol](https://developer.apple.com/documentation/swiftdata/schemamigrationplan)
- [MIGRATION_PLAN.md](.github/MIGRATION_PLAN.md) - Implementation status and progress
