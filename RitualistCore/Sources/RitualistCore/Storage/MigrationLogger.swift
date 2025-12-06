//
//  MigrationLogger.swift
//  RitualistCore
//
//  Created by Claude on 11.02.2025.
//
//  Logs migration events for debugging and monitoring.
//  Tracks schema version transitions and migration success/failure.
//

import Foundation

/// Logs and tracks database migration events
///
/// Usage:
/// ```swift
/// let logger = MigrationLogger.shared
///
/// logger.logMigrationStart(from: "1.0.0", to: "2.0.0")
/// // ... perform migration ...
/// logger.logMigrationSuccess(from: "1.0.0", to: "2.0.0", duration: 1.5)
/// ```
public final class MigrationLogger {

    // MARK: - Singleton

    public static let shared = MigrationLogger()

    // MARK: - Properties

    // Local logger: Singleton initialized before DI container
    private let logger = DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "migration")

    /// UserDefaults key for migration history
    private let migrationHistoryKey = UserDefaultsKeys.migrationHistory

    /// Migration history storage
    private let userDefaults = UserDefaults.standard

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Logs the start of a migration
    ///
    /// - Parameters:
    ///   - fromVersion: Source schema version
    ///   - toVersion: Target schema version
    ///   - changeDescription: Description of what changed in this migration
    public func logMigrationStart(
        from fromVersion: String,
        to toVersion: String,
        changeDescription: String? = nil
    ) {
        logger.log("Migration started: \(fromVersion) → \(toVersion)", level: .info, category: .dataIntegrity)

        let event = MigrationEvent(
            fromVersion: fromVersion,
            toVersion: toVersion,
            status: .started,
            startTime: Date(),
            endTime: nil,
            duration: nil,
            error: nil,
            changeDescription: changeDescription
        )

        saveMigrationEvent(event)
    }

    /// Logs successful completion of a migration
    ///
    /// - Parameters:
    ///   - fromVersion: Source schema version
    ///   - toVersion: Target schema version
    ///   - duration: Migration duration in seconds
    ///   - changeDescription: Description of what changed in this migration
    public func logMigrationSuccess(
        from fromVersion: String,
        to toVersion: String,
        duration: TimeInterval,
        changeDescription: String? = nil
    ) {
        logger.log("Migration succeeded: \(fromVersion) → \(toVersion) (took \(String(format: "%.2f", duration))s)", level: .info, category: .dataIntegrity)

        let event = MigrationEvent(
            fromVersion: fromVersion,
            toVersion: toVersion,
            status: .succeeded,
            startTime: Date(timeIntervalSinceNow: -duration),
            endTime: Date(),
            duration: duration,
            error: nil,
            changeDescription: changeDescription
        )

        saveMigrationEvent(event)
    }

    /// Logs failure of a migration
    ///
    /// - Parameters:
    ///   - fromVersion: Source schema version
    ///   - toVersion: Target schema version
    ///   - error: The error that caused the failure
    ///   - duration: Migration duration before failure (in seconds)
    public func logMigrationFailure(
        from fromVersion: String,
        to toVersion: String,
        error: Error,
        duration: TimeInterval
    ) {
        logger.log("Migration failed: \(fromVersion) → \(toVersion) - \(error.localizedDescription)", level: .error, category: .dataIntegrity)

        let event = MigrationEvent(
            fromVersion: fromVersion,
            toVersion: toVersion,
            status: .failed,
            startTime: Date(timeIntervalSinceNow: -duration),
            endTime: Date(),
            duration: duration,
            error: error.localizedDescription
        )

        saveMigrationEvent(event)
    }

    /// Logs database backup creation
    ///
    /// - Parameter success: Whether backup was successful
    public func logBackupCreation(success: Bool) {
        if success {
            logger.log("Database backup created successfully", level: .info, category: .dataIntegrity)
        } else {
            logger.log("Database backup failed", level: .error, category: .dataIntegrity)
        }
    }

    /// Logs database restore from backup
    ///
    /// - Parameter success: Whether restore was successful
    public func logBackupRestore(success: Bool) {
        if success {
            logger.log("Database restored from backup successfully", level: .info, category: .dataIntegrity)
        } else {
            logger.log("Database restore from backup failed", level: .error, category: .dataIntegrity)
        }
    }

    /// Logs current schema version
    ///
    /// - Parameter version: Current schema version
    public func logCurrentSchemaVersion(_ version: String) {
        logger.log("Current schema version: \(version)", level: .info, category: .dataIntegrity)
    }

    /// Gets the migration history
    ///
    /// - Returns: Array of migration events
    public func getMigrationHistory() -> [MigrationEvent] {
        guard let data = userDefaults.data(forKey: migrationHistoryKey),
              let events = try? JSONDecoder().decode([MigrationEvent].self, from: data) else {
            return []
        }
        return events
    }

    /// Clears all migration history
    public func clearHistory() {
        userDefaults.removeObject(forKey: migrationHistoryKey)
        logger.log("Migration history cleared", level: .debug, category: .dataIntegrity)
    }

    /// Backfills change descriptions for existing migration events
    /// This updates legacy migration events that were logged before changeDescription was added
    public func backfillChangeDescriptions() {
        var history = getMigrationHistory()
        var updated = false

        for (index, event) in history.enumerated() {
            // Skip if already has a description
            guard event.changeDescription == nil else { continue }

            let migration = "\(event.fromVersion) → \(event.toVersion)"
            let description = getChangeDescription(for: migration)

            // Create new event with description
            let updatedEvent = MigrationEvent(
                id: event.id,
                fromVersion: event.fromVersion,
                toVersion: event.toVersion,
                status: event.status,
                startTime: event.startTime,
                endTime: event.endTime,
                duration: event.duration,
                error: event.error,
                changeDescription: description
            )

            history[index] = updatedEvent
            updated = true
            logger.log("Backfilled description for migration: \(migration)", level: .info, category: .dataIntegrity)
        }

        // Save updated history if changes were made
        if updated, let data = try? JSONEncoder().encode(history) {
            userDefaults.set(data, forKey: migrationHistoryKey)
            logger.log("Successfully backfilled \(history.count) migration descriptions", level: .info, category: .dataIntegrity)
        }
    }

    /// Gets change description for a migration
    private func getChangeDescription(for migration: String) -> String {
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
            return "Removed subscription fields from database - subscription status is now managed entirely by StoreKit, establishing a single source of truth for premium features."

        default:
            return "Updated database schema."
        }
    }

    /// Gets a formatted summary of migration history
    ///
    /// - Returns: Formatted string with migration history
    public func getHistorySummary() -> String {
        let history = getMigrationHistory()

        guard !history.isEmpty else {
            return "No migration history"
        }

        var summary = "Migration History:\n"
        summary += String(repeating: "=", count: 50) + "\n\n"

        for event in history {
            summary += "Version: \(event.fromVersion) → \(event.toVersion)\n"
            summary += "Status: \(event.status.emoji) \(event.status.rawValue)\n"
            summary += "Date: \(formatDate(event.startTime))\n"

            if let duration = event.duration {
                summary += "Duration: \(String(format: "%.2f", duration))s\n"
            }

            if let error = event.error {
                summary += "Error: \(error)\n"
            }

            summary += "\n"
        }

        return summary
    }

    // MARK: - Private Methods

    /// Saves a migration event to history
    private func saveMigrationEvent(_ event: MigrationEvent) {
        var history = getMigrationHistory()

        // Remove any existing event with the same version transition
        // This prevents duplicate entries for the same migration (e.g., from testing/simulation)
        history.removeAll { existingEvent in
            existingEvent.fromVersion == event.fromVersion &&
            existingEvent.toVersion == event.toVersion
        }

        history.append(event)

        // Keep only the last 50 migration events
        if history.count > 50 {
            history = Array(history.suffix(50))
        }

        if let data = try? JSONEncoder().encode(history) {
            userDefaults.set(data, forKey: migrationHistoryKey)
        }
    }

    /// Formats a date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Migration Event

/// Represents a single migration event
public struct MigrationEvent: Codable, Identifiable {
    public let id: UUID
    public let fromVersion: String
    public let toVersion: String
    public let status: MigrationStatus
    public let startTime: Date
    public let endTime: Date?
    public let duration: TimeInterval?
    public let error: String?
    public let changeDescription: String?

    public init(
        id: UUID = UUID(),
        fromVersion: String,
        toVersion: String,
        status: MigrationStatus,
        startTime: Date,
        endTime: Date?,
        duration: TimeInterval?,
        error: String?,
        changeDescription: String? = nil
    ) {
        self.id = id
        self.fromVersion = fromVersion
        self.toVersion = toVersion
        self.status = status
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.error = error
        self.changeDescription = changeDescription
    }

    // Custom decoding to handle legacy migration events without id field
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Generate new UUID if id is missing (for legacy migration events)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.fromVersion = try container.decode(String.self, forKey: .fromVersion)
        self.toVersion = try container.decode(String.self, forKey: .toVersion)
        self.status = try container.decode(MigrationStatus.self, forKey: .status)
        self.startTime = try container.decode(Date.self, forKey: .startTime)
        self.endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        self.duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
        self.error = try container.decodeIfPresent(String.self, forKey: .error)
        self.changeDescription = try container.decodeIfPresent(String.self, forKey: .changeDescription)
    }
}

// MARK: - Migration Status

/// Status of a migration operation
public enum MigrationStatus: String, Codable {
    case started = "Started"
    case succeeded = "Succeeded"
    case failed = "Failed"

    public var emoji: String {
        switch self {
        case .started: return "🔄"
        case .succeeded: return "✅"
        case .failed: return "❌"
        }
    }
}

// MARK: - Debug Helpers

extension MigrationLogger {

    /// Prints migration history to console (debug builds only)
    public func printHistory() {
        #if DEBUG
        logger.log(getHistorySummary(), level: .debug, category: .dataIntegrity)
        #endif
    }

    /// Gets detailed statistics about migration history
    ///
    /// - Returns: Dictionary with migration statistics
    public func getStatistics() -> [String: Any] {
        let history = getMigrationHistory()

        let totalMigrations = history.count
        let successfulMigrations = history.filter { $0.status == .succeeded }.count
        let failedMigrations = history.filter { $0.status == .failed }.count

        let averageDuration: TimeInterval = {
            let durations = history.compactMap { $0.duration }
            guard !durations.isEmpty else { return 0 }
            return durations.reduce(0, +) / Double(durations.count)
        }()

        return [
            "totalMigrations": totalMigrations,
            "successfulMigrations": successfulMigrations,
            "failedMigrations": failedMigrations,
            "successRate": totalMigrations > 0 ? Double(successfulMigrations) / Double(totalMigrations) : 0,
            "averageDuration": averageDuration
        ]
    }
}
