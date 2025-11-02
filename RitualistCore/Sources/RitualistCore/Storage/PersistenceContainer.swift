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
    /// Note: Currently using direct model classes for simplicity.
    /// Migration system (SchemaV1, MigrationPlan) is implemented but not active.
    /// When we need schema migrations, we'll need to refactor datasources to use versioned types.
    public init() throws {
        Self.logger.info("🔍 Initializing PersistenceContainer with actual models")

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

        do {
            Self.logger.info("📋 Creating ModelContainer with actual models")
            Self.logger.debug("   Using models: HabitModel, HabitLogModel, HabitCategoryModel, UserProfileModel, OnboardingStateModel, PersonalityAnalysisModel")

            // CRITICAL FIX: Use actual model classes directly, not versioned schema
            // Versioned schema requires ALL code to use the versioned types (SchemaV1.HabitModelV1)
            // but our datasources use the actual types (HabitModel). This mismatch causes empty app.
            //
            // Future migrations: When we need V2, we'll need to either:
            // 1. Update all datasources to use versioned types, OR
            // 2. Use a different migration approach that preserves actual model types
            container = try ModelContainer(
                for: HabitModel.self,
                    HabitLogModel.self,
                    HabitCategoryModel.self,
                    UserProfileModel.self,
                    OnboardingStateModel.self,
                    PersonalityAnalysisModel.self,
                configurations: configuration
            )
            Self.logger.info("✅ Successfully initialized ModelContainer with actual models")
        } catch {
            Self.logger.error("❌ Failed to initialize ModelContainer: \(error.localizedDescription)")
            Self.logger.error("   Error details: \(String(describing: error))")
            throw PersistenceError.containerInitializationFailed(error)
        }

        // Create single ModelContext instance to prevent threading issues
        // This context is shared across all repositories for data consistency
        context = ModelContext(container)
        Self.logger.debug("✅ ModelContext created successfully")

        // Log database stats
        do {
            let habitCount = try context.fetchCount(FetchDescriptor<HabitModel>())
            let logCount = try context.fetchCount(FetchDescriptor<HabitLogModel>())
            let categoryCount = try context.fetchCount(FetchDescriptor<HabitCategoryModel>())
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
