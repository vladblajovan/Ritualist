# SwiftData Schema Migration Guide

This guide explains how to create a new schema version and migration for the Ritualist app using SwiftData.

## Overview

The app uses **SwiftData's VersionedSchema and SchemaMigrationPlan** for database migrations. Each schema version is defined in a separate file (e.g., `SchemaV8.swift`) and migrations are lightweight (automatic) whenever possible.

**Current Schema Version**: V11

## When to Create a New Schema

Create a new schema version when you need to:
- Add new properties to existing models
- Remove properties from models
- Change property types
- Add new models
- Modify relationships

## Step-by-Step Process

### 1. Design Your Schema Changes

**Example from V7 → V8:**
- **Goal**: Add habit priority support
- **Change**: Add `priorityLevel: Int?` to `HabitModel` (1=Low, 2=Medium, 3=High)
- **Type**: Lightweight migration (adding optional property)

### 2. Create the New Schema File

**Location**: `RitualistCore/Sources/RitualistCore/Storage/SchemaVX.swift`

**Template** (replace X with new version number):

```swift
//
//  SchemaVX.swift
//  RitualistCore
//
//  Created by [Your Name] on [Date].
//
//  Schema Version X: [Brief description of changes]
//

import Foundation
import SwiftData

/// Schema VX: [Detailed description]
///
/// Changes from V(X-1):
/// - [List each change with model and property names]
/// - Migration: Lightweight/Heavyweight
public enum SchemaVX: VersionedSchema {
    public static var versionIdentifier: Schema.Version = Schema.Version(X, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [
            HabitModel.self,
            HabitLogModel.self,
            HabitCategoryModel.self,
            UserProfileModel.self,
            OnboardingStateModel.self,
            PersonalityAnalysisModel.self
        ]
    }

    // MARK: - Models

    @Model
    public final class HabitModel {
        // Copy ALL properties from previous schema
        // Add your new property here
        public var newProperty: Type?  // NEW in VX: Description

        // Include all relationships
        @Relationship(deleteRule: .cascade, inverse: \HabitLogModel.habit)
        public var logs: [HabitLogModel] = []

        public var category: SchemaVX.HabitCategoryModel?

        // Full initializer with ALL properties
        public init(...) {
            // Initialize everything
        }
    }

    // Copy all other models (HabitLogModel, HabitCategoryModel, etc.)
    // from the previous schema WITHOUT changes
}

// MARK: - Type Aliases

public typealias HabitModelVX = SchemaVX.HabitModel
// ... (add all model aliases)

// MARK: - Domain Entity Conversions

extension SchemaVX.HabitModel {
    public func toEntity() throws -> Habit {
        // Convert to domain entity
        // Make sure to include your new property
    }

    public static func fromEntity(_ habit: Habit, context: ModelContext? = nil) throws -> HabitModelVX {
        // Convert from domain entity
        // Make sure to include your new property
    }
}

// ... (add conversions for all models)
```

### 3. Update the Domain Entity

**Location**: `RitualistCore/Sources/RitualistCore/Entities/Shared/[Model].swift`

Add the new property to the domain entity:

```swift
public struct Habit: Identifiable, Codable, Hashable {
    // ... existing properties
    public var newProperty: Type?  // Added in SchemaVX

    public init(..., newProperty: Type? = nil) {
        // ... initialize all properties
        self.newProperty = newProperty
    }
}
```

### 4. Update the Migration Plan

**Location**: `RitualistCore/Sources/RitualistCore/Storage/MigrationPlan.swift`

**A. Add schema to the schemas array:**

```swift
public static var schemas: [any VersionedSchema.Type] {
    [
        SchemaV2.self,
        // ...
        SchemaV(X-1).self,
        SchemaVX.self  // NEW: Your new schema
    ]
}
```

**B. Add migration stage:**

```swift
public static var stages: [MigrationStage] {
    [
        // ... existing migrations
        migrateV(X-1)toVX  // NEW: Your new migration
    ]
}

// MARK: - Migration Stages Implementation

/// V(X-1) → VX: [Description]
///
/// This is a LIGHTWEIGHT migration because:
/// - Both schemas use the same entity names
/// - Only adding [describe changes]
/// - SwiftData can automatically migrate the data
/// - No data transformation needed
static let migrateV(X-1)toVX = MigrationStage.lightweight(
    fromVersion: SchemaV(X-1).self,
    toVersion: SchemaVX.self
)
```

**C. Update documentation comments:**

```swift
/// Current migrations:
/// - V2 → V3: ...
/// - ...
/// - V(X-1) → VX: [Your migration description] (lightweight)
```

### 5. Build and Test

```bash
# Build the project
xcodebuild -project Ritualist.xcodeproj \
  -scheme Ritualist-AllFeatures \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build

# Expected output: ** BUILD SUCCEEDED **
```

### 6. Test Migration on Device

**Important**: Always test with real user data!

1. **Setup test device with existing data** (V7 database)
2. **Run app with V8 schema** - migration should happen automatically
3. **Check console logs** for migration messages:
   ```
   ✅ [LocationMonitoring] Started monitoring region: ...
   🔐 [LocationMonitoring] Authorization changed to: ...
   ```
4. **Verify migration modal** shows during migration
5. **Verify data integrity** - all existing data should be preserved
6. **Verify new property** - defaults to nil for existing records

## Example: V7 → V8 Migration (Priority Level)

This example demonstrates the complete process for adding the `priorityLevel` field.

### Files Changed

1. **SchemaV8.swift** (NEW)
   - Added `priorityLevel: Int?` to `HabitModel`
   - Updated `init()` to include new parameter
   - Updated `toEntity()` and `fromEntity()` conversions

2. **Habit.swift** (MODIFIED)
   ```swift
   public var priorityLevel: Int?  // Added in SchemaV8 (1=Low, 2=Medium, 3=High)
   ```

3. **MigrationPlan.swift** (MODIFIED)
   - Added `SchemaV8.self` to schemas array
   - Added `migrateV7toV8` to stages array
   - Defined lightweight migration

### Migration Flow

```
User opens app with V7 database
    ↓
SwiftData detects V8 schema
    ↓
Checks migration plan: V7 → V8
    ↓
Runs lightweight migration:
  - Adds priorityLevel column to HabitModel table
  - Sets NULL (nil) for all existing records
    ↓
Migration complete ✅
    ↓
App continues normally with V8 schema
```

## Lightweight vs Heavyweight Migrations

### Lightweight (Automatic)

Use for:
- ✅ Adding optional properties
- ✅ Adding properties with default values
- ✅ Removing properties
- ✅ Simple type changes

Example:
```swift
static let migrateVXtoVY = MigrationStage.lightweight(
    fromVersion: SchemaVX.self,
    toVersion: SchemaVY.self
)
```

### Heavyweight (Custom)

Use for:
- ⚠️  Data transformations
- ⚠️  Relationship restructuring
- ⚠️  Complex type conversions
- ⚠️  Data validation/cleanup

Example:
```swift
static let migrateVXtoVY = MigrationStage.custom(
    fromVersion: SchemaVX.self,
    toVersion: SchemaVY.self,
    willMigrate: { context in
        print("Starting migration VX → VY")
    },
    didMigrate: { context in
        // Transform data after schema change
        let habits = try context.fetch(FetchDescriptor<HabitModelVY>())
        for habit in habits {
            // Perform custom transformations
        }
        try context.save()
    }
)
```

## Common Pitfalls to Avoid

### ❌ DON'T: Reference old schema versions in new code

```swift
// BAD - Don't use SchemaV1-V6 in new features
let habit = SchemaV3.HabitModel(...)
```

### ❌ DON'T: Skip versions in migration chain

```swift
// BAD - Can't skip versions
static var schemas: [any VersionedSchema.Type] {
    [SchemaV2.self, SchemaV8.self]  // Missing V3-V7!
}
```

### ❌ DON'T: Modify existing schema files

Once a schema version is released, **never modify it**. Always create a new version.

### ❌ DON'T: Forget to update domain entity

```swift
// BAD - Schema has new property but Habit entity doesn't
// This will cause conversion errors!
```

### ✅ DO: Copy all properties from previous schema

When creating a new schema, copy **all** properties from the previous version, even if they're unchanged.

### ✅ DO: Test with production-like data

Test migrations with realistic datasets (1000+ records) to catch performance issues.

### ✅ DO: Update all type aliases

```swift
public typealias HabitModelV8 = SchemaV8.HabitModel
public typealias HabitLogModelV8 = SchemaV8.HabitLogModel
// ... add all models
```

### ✅ DO: Update both toEntity() and fromEntity()

Always update both conversion methods when adding properties.

## Verification Checklist

Before committing a new schema:

### Schema File
- [ ] New schema file created (`SchemaVX.swift`)
- [ ] Schema version incremented (`Schema.Version(X, 0, 0)`)
- [ ] All models copied from previous schema
- [ ] New properties added with proper types
- [ ] Initializers updated with new parameters
- [ ] Type aliases added for all models (e.g., `HabitModelVX`)
- [ ] `toEntity()` method updated for changed models
- [ ] `fromEntity()` method updated for changed models

### Domain Entity
- [ ] Domain entity updated (`Habit.swift`, `UserProfile.swift`, etc.)
- [ ] Entity initializer updated with new parameters

### Migration Plan
- [ ] Schema added to `MigrationPlan.schemas` array
- [ ] Migration stage added to `MigrationPlan.stages` array
- [ ] Migration stage implementation added (lightweight or custom)
- [ ] Documentation comments updated in MigrationPlan

### Active Schema (SINGLE SOURCE OF TRUTH)
- [ ] `ActiveSchema.swift`: Update `ActiveSchemaVersion = SchemaVX`
- [ ] (PersistenceContainer and all type aliases update automatically!)

### DataSource Updates (if adding new fields)
- [ ] DataSource `save()` methods updated to persist new fields
- [ ] Example: `ProfileLocalDataSource.save()` for new UserProfile fields

### Use Case Updates (if fields are set from user input)
- [ ] Use case protocol updated with new parameters
- [ ] Use case implementation updated to save new fields
- [ ] Example: `CompleteOnboardingUseCase` for onboarding-collected fields

### ViewModel Updates (if fields come from UI)
- [ ] ViewModel updated to pass new fields to use cases
- [ ] Example: `OnboardingViewModel.finishOnboarding()` passes gender/ageGroup

### Testing
- [ ] Build succeeds ✅
- [ ] Fresh install works (no migration)
- [ ] Migration from previous version works
- [ ] New fields are saved and loaded correctly
- [ ] Data integrity verified

## Rollback Strategy

If migration fails in production:

1. **Immediate**: Release previous app version
2. **Restore**: Users' iCloud backups restore V(X-1) database
3. **Fix**: Debug migration issue
4. **Test**: Extensive testing with production data
5. **Re-release**: New version with fixed migration

## Migration Performance

### Expected Performance

- **Small datasets** (<100 records): <1 second
- **Medium datasets** (100-1000 records): 1-3 seconds
- **Large datasets** (1000+ records): 3-10 seconds

### Monitoring

The `MigrationStatusService` tracks migration progress:

```swift
// During migration
migrationStatusService.isMigrating  // true
migrationStatusService.migrationDetails  // Migration details

// UI shows MigrationLoadingView modal automatically
```

## Additional Resources

- **Apple Documentation**: [SwiftData Migrations](https://developer.apple.com/documentation/swiftdata/migrating-your-swiftdata-models)
- **Code Examples**: See `SchemaV7.swift` and `SchemaV8.swift` for real implementations
- **Migration Plan**: See `MigrationPlan.swift` for all migration stages

## Questions?

If you encounter issues:

1. Check console logs for SwiftData errors
2. Verify all checklist items above
3. Test with clean database first
4. Then test with existing V(X-1) database
5. Check that type aliases match schema version

---

**Last Updated**: November 28, 2025
**Current Schema Version**: V11
**Total Migrations**: 9 (V2→V3, V3→V4, V4→V5, V5→V6, V6→V7, V7→V8, V8→V9, V9→V10, V10→V11)
