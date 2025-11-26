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
    ///
    /// Note: V1 removed because it had identical checksum to V2
    /// Starting with V2 as baseline (matches existing database)
    public static var schemas: [any VersionedSchema.Type] {
        [
            SchemaV2.self,  // Baseline schema (existing database)
            SchemaV3.self,  // Added isPinned property to HabitModel
            SchemaV4.self,  // Replaced isPinned with notes property
            SchemaV5.self,  // Added lastCompletedDate property to HabitModel
            SchemaV6.self,  // Added archivedDate property to HabitModel
            SchemaV7.self,  // Added location-aware habit support (locationConfigData, lastGeofenceTriggerDate)
            SchemaV8.self,  // Removed subscription fields from UserProfileModel (subscriptionPlan, subscriptionExpiryDate)
            SchemaV9.self,  // Three-Timezone Model (currentTimezoneIdentifier, homeTimezoneIdentifier, displayTimezoneModeData, timezoneChangeHistoryData)
            SchemaV10.self  // CloudKit compatibility (removed .unique constraints, optional relationship arrays, default values)
        ]
    }

    // MARK: - Current Schema Helper

    /// Returns the current active schema version (the latest one in the migration plan)
    public static var currentSchemaVersion: Schema.Version {
        // The last schema in the array is always the current/active version
        guard let latestSchema = schemas.last else {
            fatalError("Migration plan must have at least one schema")
        }
        return latestSchema.versionIdentifier
    }

    // MARK: - Migration Stages

    /// Defines how to migrate between schema versions
    ///
    /// Current migrations:
    /// - V2 → V3: Added isPinned property to HabitModel (lightweight)
    /// - V3 → V4: Replaced isPinned with notes property in HabitModel (lightweight)
    /// - V4 → V5: Added lastCompletedDate property to HabitModel (lightweight)
    /// - V5 → V6: Added archivedDate property to HabitModel (lightweight)
    /// - V6 → V7: Added location configuration (locationConfigData, lastGeofenceTriggerDate) (lightweight)
    /// - V7 → V8: Removed subscription fields from UserProfileModel (lightweight)
    /// - V8 → V9: Three-Timezone Model implementation (custom/heavyweight)
    /// - V9 → V10: CloudKit compatibility (removed .unique constraints, optional relationships) (lightweight)
    ///
    /// ## Example Future Migration:
    /// ```swift
    /// static var stages: [MigrationStage] {
    ///     [
    ///         // V2 → V3: Add new property with lightweight migration
    ///         migrateV2toV3,
    ///         // V3 → V4: Remove property with lightweight migration
    ///         migrateV3toV4
    ///     ]
    /// }
    /// ```
    public static var stages: [MigrationStage] {
        [
            migrateV2toV3,
            migrateV3toV4,
            migrateV4toV5,
            migrateV5toV6,
            migrateV6toV7,
            migrateV7toV8,
            migrateV8toV9,
            migrateV9toV10
        ]
    }

    // MARK: - Migration Stages Implementation

    /// V2 → V3: Added isPinned property to HabitModel
    ///
    /// This is a LIGHTWEIGHT migration because:
    /// - Both schemas use the same entity names (HabitModel, HabitLogModel, etc.)
    /// - Only adding a new property with a default value (isPinned: Bool = false)
    /// - SwiftData can automatically migrate the data
    /// - No data transformation needed
    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self
    )

    /// V3 → V4: Replaced isPinned with notes property in HabitModel
    ///
    /// This is a LIGHTWEIGHT migration because:
    /// - Both schemas use the same entity names (HabitModel, HabitLogModel, etc.)
    /// - Removing isPinned property (Bool) and adding notes property (String?)
    /// - SwiftData can automatically migrate the data (drops isPinned column, adds notes column)
    /// - No data transformation needed (notes defaults to nil)
    static let migrateV3toV4 = MigrationStage.lightweight(
        fromVersion: SchemaV3.self,
        toVersion: SchemaV4.self
    )

    /// V4 → V5: Added lastCompletedDate property to HabitModel
    ///
    /// This is a LIGHTWEIGHT migration because:
    /// - Both schemas use the same entity names (HabitModel, HabitLogModel, etc.)
    /// - Only adding a new optional property (lastCompletedDate: Date?)
    /// - SwiftData can automatically migrate the data (adds new column)
    /// - No data transformation needed (lastCompletedDate defaults to nil)
    static let migrateV4toV5 = MigrationStage.lightweight(
        fromVersion: SchemaV4.self,
        toVersion: SchemaV5.self
    )

    /// V5 → V6: Added archivedDate property to HabitModel
    ///
    /// This is a LIGHTWEIGHT migration because:
    /// - Both schemas use the same entity names (HabitModel, HabitLogModel, etc.)
    /// - Only adding a new optional property (archivedDate: Date?)
    /// - SwiftData can automatically migrate the data (adds new column)
    /// - No data transformation needed (archivedDate defaults to nil)
    static let migrateV5toV6 = MigrationStage.lightweight(
        fromVersion: SchemaV5.self,
        toVersion: SchemaV6.self
    )

    /// V6 → V7: Added location-aware habit support
    ///
    /// This is a LIGHTWEIGHT migration because:
    /// - Both schemas use the same entity names (HabitModel, HabitLogModel, etc.)
    /// - Only adding two new optional properties:
    ///   - locationConfigData: Data? (JSON-encoded LocationConfiguration)
    ///   - lastGeofenceTriggerDate: Date? (for frequency tracking)
    /// - SwiftData can automatically migrate the data (adds new columns)
    /// - No data transformation needed (both properties default to nil)
    /// - Existing habits without location configuration remain unchanged
    static let migrateV6toV7 = MigrationStage.lightweight(
        fromVersion: SchemaV6.self,
        toVersion: SchemaV7.self
    )

    /// V7 → V8: Removed subscription fields from UserProfileModel
    ///
    /// This is a LIGHTWEIGHT migration because:
    /// - Both schemas use the same entity names (HabitModel, UserProfileModel, etc.)
    /// - Only removing two optional properties from UserProfileModel:
    ///   - subscriptionPlan: String (removed)
    ///   - subscriptionExpiryDate: Date? (removed)
    /// - SwiftData can automatically migrate the data (drops columns)
    /// - No data transformation needed
    /// - Subscription status now queried from SubscriptionService (single source of truth)
    static let migrateV7toV8 = MigrationStage.lightweight(
        fromVersion: SchemaV7.self,
        toVersion: SchemaV8.self
    )

    /// V8 → V9: Three-Timezone Model implementation
    ///
    /// This is a CUSTOM/HEAVYWEIGHT migration because:
    /// - UserProfileModel undergoes significant timezone architecture change
    /// - Removed: homeTimezone (String?), displayTimezoneMode (String)
    /// - Added: currentTimezoneIdentifier (String), homeTimezoneIdentifier (String),
    ///          displayTimezoneModeData (Data), timezoneChangeHistoryData (Data)
    /// - Requires custom data transformation:
    ///   1. Initialize currentTimezoneIdentifier with device timezone
    ///   2. Migrate legacy homeTimezone → homeTimezoneIdentifier (or use device timezone)
    ///   3. Convert legacy displayTimezoneMode string → DisplayTimezoneMode enum → JSON Data
    ///   4. Initialize empty timezoneChangeHistory array → JSON Data
    ///   5. Log timezone change event for analytics
    ///
    /// Migration Logic:
    /// - Existing users: All timezones default to device timezone (safe, predictable)
    /// - Legacy homeTimezone: Preserved if valid, otherwise device timezone
    /// - Legacy displayTimezoneMode: Converted via DisplayTimezoneMode.fromLegacyString()
    /// - First migration event logged to timezoneChangeHistory
    static let migrateV8toV9 = MigrationStage.custom(
        fromVersion: SchemaV8.self,
        toVersion: SchemaV9.self,
        willMigrate: nil,
        didMigrate: { context in
            let migrationStartTime = Date()
            MigrationLogger.shared.logMigrationStart(from: "8.0.0", to: "9.0.0", changeDescription: "Three-Timezone Model Migration")

            // During didMigrate, SwiftData has already transformed the schema structure
            // V8 fields (homeTimezone, displayTimezoneMode) are now V9 structure but with default values
            // We initialize the new V9 fields with safe defaults

            let profiles = try context.fetch(FetchDescriptor<UserProfileModelV9>())
            let deviceTimezone = TimeZone.current.identifier

            for profile in profiles {
                // 1. Initialize currentTimezoneIdentifier (new field in V9)
                profile.currentTimezoneIdentifier = deviceTimezone

                // 2. Initialize homeTimezoneIdentifier
                // After schema transformation, old V8 homeTimezone field is gone
                // Safe default: use device timezone
                profile.homeTimezoneIdentifier = deviceTimezone

                // 3. Initialize displayTimezoneMode (default to .current for safety)
                let displayMode = DisplayTimezoneMode.current
                if let displayModeData = try? JSONEncoder().encode(displayMode) {
                    profile.displayTimezoneModeData = displayModeData
                } else {
                    profile.displayTimezoneModeData = Data()
                }

                // 4. Initialize timezone change history with migration event
                let migrationEvent = TimezoneChange(
                    timestamp: Date(),
                    fromTimezone: "V8_migration",  // Mark as migrated from V8
                    toTimezone: deviceTimezone,
                    trigger: .appInstall
                )
                if let historyData = try? JSONEncoder().encode([migrationEvent]) {
                    profile.timezoneChangeHistoryData = historyData
                } else {
                    profile.timezoneChangeHistoryData = Data()
                }

                // 5. Update the updatedAt timestamp
                profile.updatedAt = Date()
            }

            try context.save()

            let duration = Date().timeIntervalSince(migrationStartTime)
            MigrationLogger.shared.logMigrationSuccess(
                from: "8.0.0",
                to: "9.0.0",
                duration: duration,
                changeDescription: "Migrated \(profiles.count) user profile(s) to Three-Timezone Model"
            )
        }
    )

    /// V9 → V10: CloudKit Compatibility
    ///
    /// This is a LIGHTWEIGHT migration because:
    /// - Removed @Attribute(.unique) from all ID fields (metadata-only change)
    /// - Made relationship arrays optional (HabitModel.logs, HabitCategoryModel.habits)
    /// - Added default values to PersonalityAnalysisModel fields
    /// - No data transformation needed - all changes are schema-level only
    /// - SwiftData automatically handles relationship cardinality changes
    /// - CloudKit can now sync all models without errors
    ///
    /// Changes:
    /// - HabitModel: logs: [HabitLogModel] = [] → logs: [HabitLogModel]?
    /// - HabitCategoryModel: habits: [HabitModel] = [] → habits: [HabitModel]?
    /// - All Models: Removed @Attribute(.unique) from id fields
    /// - PersonalityAnalysisModel: Added default values to all non-optional fields
    ///
    /// Impact:
    /// - ✅ Enables full CloudKit sync for all models
    /// - ✅ No business logic changes (relationships never accessed directly)
    /// - ✅ Cascade delete behavior preserved
    /// - ✅ Zero data loss
    static let migrateV9toV10 = MigrationStage.lightweight(
        fromVersion: SchemaV9.self,
        toVersion: SchemaV10.self
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
