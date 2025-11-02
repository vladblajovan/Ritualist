//
//  MigrationPlan.swift
//  RitualistCore
//
//  Created by Claude on 11.02.2025.
//
//  Defines the migration plan for all schema versions.
//  This enables safe, automated migrations between schema versions.
//

import Foundation
import SwiftData

/// Main migration plan for Ritualist's SwiftData schema
///
/// This plan defines:
/// - All schema versions (V1, V2, V3, etc.)
/// - Migration stages between versions
/// - Whether migrations are lightweight (automatic) or heavyweight (custom)
///
/// ## Adding a New Schema Version:
/// 1. Create SchemaVX.swift with the new schema
/// 2. Add it to `schemas` array
/// 3. Add migration stage from V(X-1) to VX
/// 4. Test migration with real data before release
public enum RitualistMigrationPlan: SchemaMigrationPlan {

    // MARK: - Schema Versions

    /// All schema versions in chronological order
    ///
    /// When adding a new version:
    /// - Append to the end of this array
    /// - Never remove or reorder existing versions
    /// - Each version must have a unique versionIdentifier
    public static var schemas: [any VersionedSchema.Type] {
        [
            SchemaV1.self,
            SchemaV2.self  // Added isPinned property to HabitModel
            // Future versions go here:
            // SchemaV3.self,
        ]
    }

    // MARK: - Migration Stages

    /// Defines how to migrate between schema versions
    ///
    /// Current migrations:
    /// - V1 → V2: Added isPinned property to HabitModel (lightweight)
    ///
    /// ## Example Future Migration:
    /// ```swift
    /// static var stages: [MigrationStage] {
    ///     [
    ///         // V1 → V2: Add new property with lightweight migration
    ///         migrateV1toV2
    ///     ]
    /// }
    /// ```
    public static var stages: [MigrationStage] {
        [
            migrateV1toV2
        ]
    }

    // MARK: - Migration Stages Implementation

    /// V1 → V2: Added isPinned property to HabitModel
    ///
    /// This is a LIGHTWEIGHT migration because:
    /// - Both schemas use the same entity names (HabitModel, HabitLogModel, etc.)
    /// - Only adding a new property with a default value (isPinned: Bool = false)
    /// - SwiftData can automatically migrate the data
    /// - No data transformation needed
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )

    // MARK: - Future Migration Stages (Examples)

    /*
     Example lightweight migration (automatic property additions/removals):

     static let migrateV1toV2 = MigrationStage.lightweight(
         fromVersion: SchemaV1.self,
         toVersion: SchemaV2.self
     )
     */

    /*
     Example heavyweight migration (custom data transformations):

     static let migrateV2toV3 = MigrationStage.custom(
         fromVersion: SchemaV2.self,
         toVersion: SchemaV3.self,
         willMigrate: { context in
             // Optional: Pre-migration setup
             print("Starting migration V2 → V3")
         },
         didMigrate: { context in
             // Optional: Post-migration cleanup
             print("Completed migration V2 → V3")

             // Example: Transform data after schema change
             let habits = try context.fetch(FetchDescriptor<HabitModelV3>())
             for habit in habits {
                 // Perform custom data transformations
             }
             try context.save()
         }
     )
     */
}

// MARK: - Migration Guidelines

/*
 ## When to Use Lightweight vs Heavyweight Migrations

 ### Lightweight Migrations (Automatic)
 Use for simple schema changes:
 - Adding new optional properties
 - Adding new properties with default values
 - Removing properties
 - Renaming properties (with renaming hint)
 - Changing property types (some cases)

 Example:
 ```swift
 // V1: Old schema
 var name: String

 // V2: Added optional property
 var name: String
 var nickname: String?  // ✅ Lightweight migration
 ```

 ### Heavyweight Migrations (Custom)
 Use for complex schema changes:
 - Data transformations
 - Relationship restructuring
 - Splitting/merging entities
 - Complex type conversions
 - Data validation/cleanup

 Example:
 ```swift
 // V1: Single timezone property
 var timezone: String

 // V2: Split into home and display timezones
 var homeTimezone: String?
 var displayTimezoneMode: String
 // ⚠️  Heavyweight migration needed to split data
 ```

 ## Migration Best Practices

 1. **Always test migrations** with production-like data
 2. **Create backups** before migration (BackupManager handles this)
 3. **Log migration progress** (MigrationLogger handles this)
 4. **Version numbering**: Use semantic versioning (major.minor.patch)
 5. **Never skip versions**: Always migrate V1→V2→V3, never V1→V3
 6. **Test rollback**: Ensure backup/restore works correctly

 ## Migration Checklist

 Before deploying a migration:
 - [ ] New schema version created (SchemaVX.swift)
 - [ ] Migration stage added to RitualistMigrationPlan
 - [ ] Migration tested with sample data
 - [ ] Migration tested with large dataset (1000+ records)
 - [ ] Backup/restore tested
 - [ ] Migration logging verified
 - [ ] App version incremented
 - [ ] Release notes updated with migration details
 */
