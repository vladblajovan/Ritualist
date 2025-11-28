import Foundation
import SwiftData

/// Core persistence container for Ritualist app
/// Manages SwiftData ModelContainer with app group support for widget access
public final class PersistenceContainer {
    public let container: ModelContainer
    public let context: ModelContext

    /// App Group identifier for shared container access
    private static let appGroupIdentifier = "group.com.vladblajovan.Ritualist"

    /// CloudKit container identifier for iCloud sync
    public static let cloudKitContainerIdentifier = "iCloud.com.vladblajovan.Ritualist"

    /// Logger for migration and initialization events (uses shared DebugLogger for consistency)
    private static let logger = DebugLogger(subsystem: "com.vladblajovan.Ritualist", category: "Persistence")

    /// UserDefaults key for last known schema version
    private static let lastSchemaVersionKey = "com.ritualist.lastSchemaVersion"

    /// Initialize persistence container with app group support
    /// Enables data sharing between main app and widget extension
    ///
    /// Uses versioned schema with migration plan to safely handle schema changes.
    /// All datasources use Active* type aliases that point to current schema version.
    public init() throws {
        // Get the current schema version for migration tracking and logging
        let currentSchemaVersion = RitualistMigrationPlan.currentSchemaVersion
        let currentVersionString = currentSchemaVersion.description
        Self.logger.log("🔍 Initializing PersistenceContainer with versioned schema (V\(currentVersionString))", level: .info, category: .system)

        // Read last known schema version (nil on first launch)
        let lastVersionString = UserDefaults.standard.string(forKey: Self.lastSchemaVersionKey)
        Self.logger.log("🔍 Last known schema version: \(lastVersionString ?? "none (first launch)")", level: .debug, category: .system)
        Self.logger.log("🔍 Current schema version: \(currentVersionString)", level: .debug, category: .system)

        // Notify UI if migration is about to start
        let migrationWillOccur = lastVersionString != nil && lastVersionString != currentVersionString
        if migrationWillOccur, let lastVersion = lastVersionString {
            // Set migration state synchronously on main thread
            // This ensures the UI sees the state before migration starts
            // Use sync dispatch to ensure startMigration completes before proceeding
            // This prevents race condition where completeMigration captures stale migration ID
            let startMigrationBlock = {
                MainActor.assumeIsolated {
                    MigrationStatusService.shared.startMigration(
                        from: lastVersion,
                        to: currentVersionString
                    )
                }
            }

            if Thread.isMainThread {
                startMigrationBlock()
            } else {
                DispatchQueue.main.sync(execute: startMigrationBlock)
            }

            // Give UI time to render the migration modal (100ms)
            // Without this, the migration completes before the view appears
            Thread.sleep(forTimeInterval: 0.1)
            Self.logger.log("⏱️ Allowing UI time to show migration modal", level: .debug, category: .system)
        }

        // Use default SwiftData storage location for reliable CloudKit sync
        // NOTE: Custom App Group URLs can cause CloudKit sync issues.
        // If widget support is needed later, we may need a different approach
        // (e.g., separate local store for widget, or NSPersistentCloudKitContainer directly)
        Self.logger.log("📁 Using default SwiftData storage location for CloudKit sync", level: .debug, category: .system)

        let configuration = ModelConfiguration(
            // No custom URL - use default location for best CloudKit compatibility
            allowsSave: true,
            // ✅ CloudKit ENABLED - Syncs to iCloud private database
            cloudKitDatabase: .private(Self.cloudKitContainerIdentifier)
        )

        let migrationStartTime = Date()

        do {
            Self.logger.log("📋 Creating Schema from SchemaV\(currentVersionString)", level: .info, category: .system)
            Self.logger.log("   Models: \(ActiveSchemaVersion.models.map { String(describing: $0) })", level: .debug, category: .system)

            let schema = Schema(versionedSchema: ActiveSchemaVersion.self)
            Self.logger.log("   Schema version: \(currentVersionString)", level: .debug, category: .system)

            Self.logger.log("🚀 Initializing ModelContainer with schema and migration plan", level: .info, category: .system)

            // Use versioned schema with migration plan
            // This enables safe schema evolution without data loss
            // See RitualistMigrationPlan.swift for migration stages
            // All datasources use Active* type aliases pointing to current schema
            container = try ModelContainer(
                for: schema,
                migrationPlan: RitualistMigrationPlan.self,
                configurations: configuration
            )
            Self.logger.log("✅ Successfully initialized ModelContainer with versioned schema (V\(currentVersionString))", level: .info, category: .system)

            // Calculate migration duration
            let migrationDuration = Date().timeIntervalSince(migrationStartTime)

            // Log migration if version changed
            if let lastVersion = lastVersionString, lastVersion != currentVersionString {
                Self.logger.log("🔄 Schema migration detected: \(lastVersion) → \(currentVersionString)", level: .info, category: .system)

                // Get description of what changed in this migration
                let changeDescription = Self.getChangeDescription(from: lastVersion, to: currentVersionString)

                MigrationLogger.shared.logMigrationSuccess(
                    from: lastVersion,
                    to: currentVersionString,
                    duration: migrationDuration,
                    changeDescription: changeDescription
                )

                // Notify UI that migration completed successfully
                Task { @MainActor in
                    MigrationStatusService.shared.completeMigration()
                }
            } else if lastVersionString == nil {
                // First launch - no migration, just set the version
                Self.logger.log("🆕 First launch - setting initial schema version: \(currentVersionString)", level: .info, category: .system)
            } else {
                Self.logger.log("✨ No migration needed - schema version unchanged: \(currentVersionString)", level: .info, category: .system)
            }

            // Update last known schema version
            UserDefaults.standard.set(currentVersionString, forKey: Self.lastSchemaVersionKey)

        } catch {
            let migrationDuration = Date().timeIntervalSince(migrationStartTime)

            Self.logger.log("❌ Failed to initialize ModelContainer: \(error.localizedDescription)", level: .error, category: .system)
            Self.logger.log("   Error details: \(String(describing: error))", level: .error, category: .system)

            // Log migration failure if there was a version change
            if let lastVersion = lastVersionString, lastVersion != currentVersionString {
                MigrationLogger.shared.logMigrationFailure(
                    from: lastVersion,
                    to: currentVersionString,
                    error: error,
                    duration: migrationDuration
                )

                // Notify UI that migration failed
                Task { @MainActor in
                    MigrationStatusService.shared.failMigration(error: error)
                }
            }

            throw PersistenceError.containerInitializationFailed(error)
        }

        // Create single ModelContext instance to prevent threading issues
        // This context is shared across all repositories for data consistency
        context = ModelContext(container)
        Self.logger.log("✅ ModelContext created successfully", level: .debug, category: .system)

        // Log database stats using active schema types (post-migration)
        do {
            let habitCount = try context.fetchCount(FetchDescriptor<ActiveHabitModel>())
            let logCount = try context.fetchCount(FetchDescriptor<ActiveHabitLogModel>())
            let categoryCount = try context.fetchCount(FetchDescriptor<ActiveHabitCategoryModel>())
            Self.logger.log("📊 Database stats - Habits: \(habitCount), Logs: \(logCount), Categories: \(categoryCount)", level: .info, category: .system)
        } catch {
            Self.logger.log("⚠️ Could not fetch database stats: \(error.localizedDescription)", level: .warning, category: .system)
        }
    }
    
    /// Get the shared container URL for app group
    /// Returns the shared directory where both app and widget can access data
    /// Used by BackupManager for backup storage location
    public static func getSharedContainerURL() -> URL {
        guard let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            fatalError("Failed to get shared container URL for app group: \(appGroupIdentifier)")
        }
        return sharedContainerURL
    }

    /// Get description of what changed in a migration
    /// Maps schema version transitions to human-readable descriptions
    private static func getChangeDescription(from fromVersion: String, to toVersion: String) -> String {
        let migration = "\(fromVersion) → \(toVersion)"

        switch migration {
        case "2.0.0 → 3.0.0":
            return "Added habit pinning feature - habits can now be pinned to the top of lists for quick access."

        case "3.0.0 → 4.0.0":
            return "Replaced pinning with notes system - habits now support rich text notes instead of simple pinning."

        case "4.0.0 → 5.0.0":
            return "Added last completion tracking - the app now remembers when each habit was last completed for better insights."

        case "5.0.0 → 6.0.0":
            return "Added habit archiving - habits can now be archived instead of deleted, preserving your history while decluttering active habits."

        case "6.0.0 → 7.0.0":
            return "Added location-aware habits - habits can now send notifications when you enter or exit specific locations with configurable geofencing."

        case "7.0.0 → 8.0.0":
            return "Removed subscription fields from database - subscription status now queried from StoreKit service for improved security and accuracy."

        case "8.0.0 → 9.0.0":
            return "Upgraded timezone handling with three-timezone model - the app now tracks your current timezone, home timezone, and display preferences for accurate habit tracking across time zones."

        default:
            // For unknown migrations, provide a generic description
            return "Updated database schema from version \(fromVersion) to \(toVersion)."
        }
    }
}

// MARK: - Persistence Errors

/// Errors that can occur during persistence operations
public enum PersistenceError: LocalizedError {
    case containerInitializationFailed(Error)
    case migrationFailed(Error)
    case backupFailed(Error)
    case restoreFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .containerInitializationFailed(let error):
            return "Failed to initialize persistence container: \(error.localizedDescription)"
        case .migrationFailed(let error):
            return "Database migration failed: \(error.localizedDescription)"
        case .backupFailed(let error):
            return "Failed to create database backup: \(error.localizedDescription)"
        case .restoreFailed(let error):
            return "Failed to restore database from backup: \(error.localizedDescription)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .containerInitializationFailed:
            return "Please try restarting the app. If the problem persists, you may need to reinstall."
        case .migrationFailed:
            return "The app will attempt to restore from backup. If this fails, please contact support."
        case .backupFailed:
            return "Ensure sufficient storage space is available."
        case .restoreFailed:
            return "Database backup may be corrupted. Please contact support."
        }
    }
}
