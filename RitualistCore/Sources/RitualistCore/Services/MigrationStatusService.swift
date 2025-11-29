//
//  MigrationStatusService.swift
//  RitualistCore
//
//  Created by Claude on 03.11.2025.
//
//  Tracks migration status for UI feedback during schema migrations.
//

import Foundation
import Observation

/// Service that tracks migration status for UI feedback
///
/// This service allows the UI layer to show loading states during migrations.
/// PersistenceContainer updates this service before/after migrations.
@MainActor @Observable
public final class MigrationStatusService {

    // MARK: - Singleton

    /// Shared instance for app-wide migration status tracking
    public static let shared = MigrationStatusService()

    // MARK: - Published State

    /// Whether a migration is currently in progress
    public private(set) var isMigrating: Bool = false

    /// Current migration details (from version → to version)
    public private(set) var migrationDetails: MigrationDetails?

    /// Error from the last failed migration (if any)
    public private(set) var migrationError: Error?

    /// Tracks the current migration instance to prevent race conditions
    private var currentMigrationId: UUID?

    /// Logger for migration events
    private let logger = DebugLogger(subsystem: "com.vladblajovan.Ritualist", category: "migration")

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Called when migration starts
    public func startMigration(from fromVersion: String, to toVersion: String) {
        logger.log(
            "Migration starting",
            level: .info,
            category: .dataIntegrity,
            metadata: ["fromVersion": fromVersion, "toVersion": toVersion]
        )
        let migrationId = UUID()
        currentMigrationId = migrationId
        isMigrating = true
        migrationError = nil  // Clear any previous error
        migrationDetails = MigrationDetails(
            fromVersion: fromVersion,
            toVersion: toVersion,
            startTime: Date()
        )
    }

    /// Called when migration completes successfully
    public func completeMigration() {
        logger.log(
            "Migration completed successfully",
            level: .info,
            category: .dataIntegrity,
            metadata: [
                "fromVersion": migrationDetails?.fromVersion ?? "unknown",
                "toVersion": migrationDetails?.toVersion ?? "unknown"
            ]
        )
        // Capture the migration ID at the time of completion
        let completedMigrationId = currentMigrationId

        // Keep migration modal visible for 3 seconds
        // This ensures users see the "Preparing your experience" message
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            await MainActor.run {
                // Only update state if this is still the same migration
                // (prevents race condition if a new migration started)
                guard currentMigrationId == completedMigrationId else { return }

                isMigrating = false
                // Keep details for a short time to show completion message
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    await MainActor.run {
                        // Check again before clearing details
                        guard currentMigrationId == completedMigrationId else { return }
                        migrationDetails = nil
                    }
                }
            }
        }
    }

    /// Called when migration fails
    public func failMigration(error: Error) {
        logger.log(
            "Migration failed",
            level: .error,
            category: .dataIntegrity,
            metadata: [
                "error": error.localizedDescription,
                "fromVersion": migrationDetails?.fromVersion ?? "unknown",
                "toVersion": migrationDetails?.toVersion ?? "unknown"
            ]
        )
        migrationError = error
        isMigrating = false
        migrationDetails = nil
    }

    /// Reset migration state (useful for testing)
    public func reset() {
        currentMigrationId = nil
        isMigrating = false
        migrationDetails = nil
        migrationError = nil
    }
}

// MARK: - Migration Details

/// Details about the current/recent migration
public struct MigrationDetails {
    public let fromVersion: String
    public let toVersion: String
    public let startTime: Date

    public init(fromVersion: String, toVersion: String, startTime: Date) {
        self.fromVersion = fromVersion
        self.toVersion = toVersion
        self.startTime = startTime
    }

    /// Human-readable migration description
    public var description: String {
        "Upgrading from v\(fromVersion) to v\(toVersion)"
    }
}
