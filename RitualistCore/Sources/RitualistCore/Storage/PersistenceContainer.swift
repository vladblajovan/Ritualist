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
    /// Uses versioned schema (SchemaV3) with migration plan to safely handle schema changes.
    /// All datasources use versioned types (HabitModelV3, HabitLogModelV3, etc.)
    public init() throws {
        Self.logger.info("🔍 Initializing PersistenceContainer with versioned schema (V3)")

        // Get the current schema version for migration tracking
        let currentSchemaVersion = RitualistMigrationPlan.currentSchemaVersion
        let currentVersionString = currentSchemaVersion.description

        // Read last known schema version (nil on first launch)
        let lastVersionString = UserDefaults.standard.string(forKey: Self.lastSchemaVersionKey)
        Self.logger.debug("🔍 Last known schema version: \(lastVersionString ?? "none (first launch)")")
        Self.logger.debug("🔍 Current schema version: \(currentVersionString)")

        // Get shared container URL for app group
        let sharedContainerURL = PersistenceContainer.getSharedContainerURL()
        Self.logger.debug("📁 Using shared container URL: \(sharedContainerURL.path)")

        // Configure ModelContainer with shared URL and migration options
        let databaseURL = sharedContainerURL.appendingPathComponent("Ritualist.sqlite")
        Self.logger.debug("🗄️ Database file path: \(databaseURL.path)")

        let configuration = ModelConfiguration(
            url: databaseURL,
            allowsSave: true,
            cloudKitDatabase: .none  // CloudKit setup for future use
        )

        let migrationStartTime = Date()

        do {
            Self.logger.info("📋 Creating Schema from SchemaV3")
            Self.logger.debug("   SchemaV3 models: \(SchemaV3.models.map { String(describing: $0) })")

            let schema = Schema(versionedSchema: SchemaV3.self)
            Self.logger.debug("   Schema version: \(SchemaV3.versionIdentifier)")

            Self.logger.info("🚀 Initializing ModelContainer with schema and migration plan")
            Self.logger.info("   Migration plan will handle V2 → V3 upgrade automatically")

            // Use versioned schema with migration plan
            // This enables safe schema evolution without data loss
            // Migration: V2 data will be automatically upgraded to V3 (adds isPinned property)
            // All datasources now use versioned types (HabitModelV3, etc.)
            container = try ModelContainer(
                for: schema,
                migrationPlan: RitualistMigrationPlan.self,
                configurations: configuration
            )
            Self.logger.info("✅ Successfully initialized ModelContainer with versioned schema (V3)")

            // Calculate migration duration
            let migrationDuration = Date().timeIntervalSince(migrationStartTime)

            // Log migration if version changed
            if let lastVersion = lastVersionString, lastVersion != currentVersionString {
                Self.logger.info("🔄 Schema migration detected: \(lastVersion) → \(currentVersionString)")
                MigrationLogger.shared.logMigrationSuccess(
                    from: lastVersion,
                    to: currentVersionString,
                    duration: migrationDuration
                )
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
            }

            throw PersistenceError.containerInitializationFailed(error)
        }

        // Create single ModelContext instance to prevent threading issues
        // This context is shared across all repositories for data consistency
        context = ModelContext(container)
        Self.logger.debug("✅ ModelContext created successfully")

        // Log database stats using V3 types (post-migration)
        do {
            let habitCount = try context.fetchCount(FetchDescriptor<HabitModelV3>())
            let logCount = try context.fetchCount(FetchDescriptor<HabitLogModelV3>())
            let categoryCount = try context.fetchCount(FetchDescriptor<HabitCategoryModelV3>())
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
