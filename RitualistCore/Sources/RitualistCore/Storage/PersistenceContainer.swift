import Foundation
import SwiftData
import os.log

/// Core persistence container for Ritualist app
/// Manages SwiftData ModelContainer with app group support for widget access
public final class PersistenceContainer {
    public let container: ModelContainer
    public let context: ModelContext

    /// App Group identifier for shared container access
    private static let appGroupIdentifier = "group.com.vladblajovan.Ritualist"

    /// Logger for migration and initialization events
    private static let logger = Logger(subsystem: "com.vladblajovan.Ritualist", category: "Persistence")

    /// UserDefaults key for last known schema version
    private static let lastSchemaVersionKey = "com.ritualist.lastSchemaVersion"

    /// Initialize persistence container with app group support
    /// Enables data sharing between main app and widget extension
    ///
    /// Uses versioned schema (SchemaV7) with migration plan to safely handle schema changes.
    /// All datasources use Active* type aliases that point to current schema version.
    public init() throws {
        Self.logger.info("🔍 Initializing PersistenceContainer with versioned schema (V7)")

        // Get the current schema version for migration tracking
        let currentSchemaVersion = RitualistMigrationPlan.currentSchemaVersion
        let currentVersionString = currentSchemaVersion.description

        // Read last known schema version (nil on first launch)
        let lastVersionString = UserDefaults.standard.string(forKey: Self.lastSchemaVersionKey)
        Self.logger.debug("🔍 Last known schema version: \(lastVersionString ?? "none (first launch)")")
        Self.logger.debug("🔍 Current schema version: \(currentVersionString)")

        // Notify UI if migration is about to start
        let migrationWillOccur = lastVersionString != nil && lastVersionString != currentVersionString
        if migrationWillOccur, let lastVersion = lastVersionString {
            // Set migration state synchronously on main thread
            // This ensures the UI sees the state before migration starts
            DispatchQueue.main.async {
                Task { @MainActor in
                    MigrationStatusService.shared.startMigration(
                        from: lastVersion,
                        to: currentVersionString
                    )
                }
            }

            // Give UI time to render the migration modal (100ms)
            // Without this, the migration completes before the view appears
            Thread.sleep(forTimeInterval: 0.1)
            Self.logger.debug("⏱️ Allowing UI time to show migration modal")
        }

        // Get shared container URL for app group
        let sharedContainerURL = PersistenceContainer.getSharedContainerURL()
        Self.logger.debug("📁 Using shared container URL: \(sharedContainerURL.path)")

        // Configure ModelContainer with shared URL and migration options
        let databaseURL = sharedContainerURL.appendingPathComponent("Ritualist.sqlite")
        Self.logger.debug("🗄️ Database file path: \(databaseURL.path)")

        let configuration = ModelConfiguration(
            url: databaseURL,
            allowsSave: true,
            cloudKitDatabase: .private(  // CloudKit private database for UserProfile sync
                "iCloud.com.vladblajovan.Ritualist"
            )
        )

        let migrationStartTime = Date()

        do {
            Self.logger.info("📋 Creating Schema from SchemaV7")
            Self.logger.debug("   SchemaV7 models: \(SchemaV7.models.map { String(describing: $0) })")

            let schema = Schema(versionedSchema: SchemaV7.self)
            Self.logger.debug("   Schema version: \(SchemaV7.versionIdentifier)")

            Self.logger.info("🚀 Initializing ModelContainer with schema and migration plan")
            Self.logger.info("   Migration plan will handle V2 → V3 → V4 → V5 → V6 → V7 upgrades automatically")

            // Use versioned schema with migration plan
            // This enables safe schema evolution without data loss
            // Migrations: V2 → V3 (adds isPinned) → V4 (replaces with notes) → V5 (adds lastCompletedDate) → V6 (adds archivedDate) → V7 (adds location support)
            // All datasources use Active* type aliases pointing to current schema
            container = try ModelContainer(
                for: schema,
                migrationPlan: RitualistMigrationPlan.self,
                configurations: configuration
            )
            Self.logger.info("✅ Successfully initialized ModelContainer with versioned schema (V7)")

            // Calculate migration duration
            let migrationDuration = Date().timeIntervalSince(migrationStartTime)

            // Log migration if version changed
            if let lastVersion = lastVersionString, lastVersion != currentVersionString {
                Self.logger.info("🔄 Schema migration detected: \(lastVersion) → \(currentVersionString)")

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
                Self.logger.info("🆕 First launch - setting initial schema version: \(currentVersionString)")
            } else {
                Self.logger.info("✨ No migration needed - schema version unchanged: \(currentVersionString)")
            }

            // Update last known schema version
            UserDefaults.standard.set(currentVersionString, forKey: Self.lastSchemaVersionKey)

        } catch {
            let migrationDuration = Date().timeIntervalSince(migrationStartTime)

            Self.logger.error("❌ Failed to initialize ModelContainer: \(error.localizedDescription)")
            Self.logger.error("   Error details: \(String(describing: error))")

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
        Self.logger.debug("✅ ModelContext created successfully")

        // Log database stats using active schema types (post-migration)
        do {
            let habitCount = try context.fetchCount(FetchDescriptor<ActiveHabitModel>())
            let logCount = try context.fetchCount(FetchDescriptor<ActiveHabitLogModel>())
            let categoryCount = try context.fetchCount(FetchDescriptor<ActiveHabitCategoryModel>())
            Self.logger.info("📊 Database stats - Habits: \(habitCount), Logs: \(logCount), Categories: \(categoryCount)")
        } catch {
            Self.logger.warning("⚠️ Could not fetch database stats: \(error.localizedDescription)")
        }
    }
    
    /// Get the shared container URL for app group
    /// Returns the shared directory where both app and widget can access data
    private static func getSharedContainerURL() -> URL {
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
