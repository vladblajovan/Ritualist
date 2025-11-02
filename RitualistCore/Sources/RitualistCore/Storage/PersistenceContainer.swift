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

    /// Initialize persistence container with app group support
    /// Enables data sharing between main app and widget extension
    ///
    /// Uses versioned schema with migration plan to safely handle schema changes.
    /// Migrations are automatic based on RitualistMigrationPlan configuration.
    public init() throws {
        Self.logger.info("Initializing PersistenceContainer with versioned schema")

        // Get shared container URL for app group
        let sharedContainerURL = PersistenceContainer.getSharedContainerURL()
        Self.logger.debug("Using shared container URL: \(sharedContainerURL.path)")

        // Configure ModelContainer with shared URL and migration options
        let configuration = ModelConfiguration(
            url: sharedContainerURL.appendingPathComponent("Ritualist.sqlite"),
            allowsSave: true,
            cloudKitDatabase: .none  // CloudKit setup for future use
        )

        do {
            // Use versioned schema with migration plan
            // This enables safe schema evolution without data loss
            // Pass the schema (from migration plan) and the migration plan itself
            container = try ModelContainer(
                for: Schema(versionedSchema: SchemaV1.self),
                migrationPlan: RitualistMigrationPlan.self,
                configurations: configuration
            )
            Self.logger.info("Successfully initialized ModelContainer with migration plan")
        } catch {
            Self.logger.error("Failed to initialize ModelContainer: \(error.localizedDescription)")
            throw PersistenceError.containerInitializationFailed(error)
        }

        // Create single ModelContext instance to prevent threading issues
        // This context is shared across all repositories for data consistency
        context = ModelContext(container)
        Self.logger.debug("ModelContext created successfully")
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
