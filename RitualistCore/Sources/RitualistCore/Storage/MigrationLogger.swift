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
import os.log

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

    /// System logger for migration events
    private let logger = Logger(subsystem: "com.vladblajovan.Ritualist", category: "Migration")

    /// UserDefaults key for migration history
    private let migrationHistoryKey = "com.ritualist.migration.history"

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
    public func logMigrationStart(from fromVersion: String, to toVersion: String) {
        logger.info("🔄 Migration started: \(fromVersion) → \(toVersion)")

        let event = MigrationEvent(
            fromVersion: fromVersion,
            toVersion: toVersion,
            status: .started,
            startTime: Date(),
            endTime: nil,
            duration: nil,
            error: nil
        )

        saveMigrationEvent(event)
    }

    /// Logs successful completion of a migration
    ///
    /// - Parameters:
    ///   - fromVersion: Source schema version
    ///   - toVersion: Target schema version
    ///   - duration: Migration duration in seconds
    public func logMigrationSuccess(from fromVersion: String, to toVersion: String, duration: TimeInterval) {
        logger.info("✅ Migration succeeded: \(fromVersion) → \(toVersion) (took \(String(format: "%.2f", duration))s)")

        let event = MigrationEvent(
            fromVersion: fromVersion,
            toVersion: toVersion,
            status: .succeeded,
            startTime: Date(timeIntervalSinceNow: -duration),
            endTime: Date(),
            duration: duration,
            error: nil
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
        logger.error("❌ Migration failed: \(fromVersion) → \(toVersion) - \(error.localizedDescription)")

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
            logger.info("💾 Database backup created successfully")
        } else {
            logger.error("⚠️  Database backup failed")
        }
    }

    /// Logs database restore from backup
    ///
    /// - Parameter success: Whether restore was successful
    public func logBackupRestore(success: Bool) {
        if success {
            logger.info("♻️  Database restored from backup successfully")
        } else {
            logger.error("⚠️  Database restore from backup failed")
        }
    }

    /// Logs current schema version
    ///
    /// - Parameter version: Current schema version
    public func logCurrentSchemaVersion(_ version: String) {
        logger.info("📊 Current schema version: \(version)")
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
        logger.debug("Migration history cleared")
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
public struct MigrationEvent: Codable {
    public let fromVersion: String
    public let toVersion: String
    public let status: MigrationStatus
    public let startTime: Date
    public let endTime: Date?
    public let duration: TimeInterval?
    public let error: String?

    public init(
        fromVersion: String,
        toVersion: String,
        status: MigrationStatus,
        startTime: Date,
        endTime: Date?,
        duration: TimeInterval?,
        error: String?
    ) {
        self.fromVersion = fromVersion
        self.toVersion = toVersion
        self.status = status
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.error = error
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
        print(getHistorySummary())
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
