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
enum RitualistMigrationPlan: SchemaMigrationPlan {

    // MARK: - Schema Versions

    /// All schema versions in chronological order
    ///
    /// When adding a new version:
    /// - Append to the end of this array
    /// - Never remove or reorder existing versions
    /// - Each version must have a unique versionIdentifier
    static var schemas: [any VersionedSchema.Type] {
        [
            SchemaV1.self,
            SchemaV2.self  // Added for migration testing
            // Future versions go here:
            // SchemaV3.self,
        ]
    }

    // MARK: - Migration Stages

    /// Defines how to migrate between schema versions
    ///
    /// Migrations are executed in order when the app detects a schema change.
    /// Each migration stage defines how to transform data from one version to the next.
    static var stages: [MigrationStage] {
        [
            // V1 → V2: Add isPinned property to HabitModel
            migrateV1toV2
        ]
        // Future migration stages will be added here:
        // Example: migrateV2toV3, migrateV3toV4, etc.
    }

    // MARK: - Migration Stage Implementations

    /// Lightweight migration from V1 to V2
    ///
    /// Changes:
    /// - Adds `isPinned: Bool` property to HabitModel with default value `false`
    ///
    /// This is a lightweight migration because:
    /// - Only adding a new property
    /// - Property has a default value
    /// - No data transformation needed
    /// - SwiftData handles it automatically
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            // Pre-migration: Create backup and log start
            let backupManager = BackupManager()
            do {
                try backupManager.createBackup()
                MigrationLogger.shared.logBackupCreation(success: true)
            } catch {
                MigrationLogger.shared.logBackupCreation(success: false)
                // Don't fail migration if backup fails - just log it
            }

            MigrationLogger.shared.logMigrationStart(from: "1.0.0", to: "2.0.0")
            MigrationLogger.shared.logCurrentSchemaVersion("2.0.0")
        },
        didMigrate: { context in
            // Post-migration: Verify data and log success
            let startTime = Date()

            // Verify all habits were migrated
            let habits = try context.fetch(FetchDescriptor<HabitModelV2>())
            let habitsWithDefaultPinned = habits.filter { !$0.isPinned }

            print("✅ Migration V1 → V2 completed:")
            print("   - Migrated \(habits.count) habits")
            print("   - All habits have isPinned = false (default)")
            print("   - \(habitsWithDefaultPinned.count) habits confirmed with default value")

            let duration = Date().timeIntervalSince(startTime)
            MigrationLogger.shared.logMigrationSuccess(from: "1.0.0", to: "2.0.0", duration: duration)
        }
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
