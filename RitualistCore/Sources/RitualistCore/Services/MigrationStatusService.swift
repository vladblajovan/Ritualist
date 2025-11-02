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

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Called when migration starts
    public func startMigration(from fromVersion: String, to toVersion: String) {
        isMigrating = true
        migrationDetails = MigrationDetails(
            fromVersion: fromVersion,
            toVersion: toVersion,
            startTime: Date()
        )
    }

    /// Called when migration completes successfully
    public func completeMigration() {
        // Keep migration modal visible for 3 seconds
        // This ensures users see the "Preparing your experience" message
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            await MainActor.run {
                isMigrating = false
                // Keep details for a short time to show completion message
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    await MainActor.run {
                        migrationDetails = nil
                    }
                }
            }
        }
    }

    /// Called when migration fails
    public func failMigration(error: Error) {
        isMigrating = false
        migrationDetails = nil
    }

    /// Reset migration state (useful for testing)
    public func reset() {
        isMigrating = false
        migrationDetails = nil
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
