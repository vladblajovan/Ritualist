//
//  MigrationStatusServiceTests.swift
//  RitualistTests
//
//  Created by Claude on 28.11.2025.
//
//  Unit tests for MigrationStatusService.
//

import Testing
import Foundation
@testable import RitualistCore

#if swift(>=6.1)
@Suite("MigrationStatusService Tests", .tags(.isolated, .fast), .serialized)
#else
@Suite("MigrationStatusService Tests", .serialized)
#endif
struct MigrationStatusServiceTests {

    // MARK: - Initial State Tests

    @Test("Initial state is not migrating")
    @MainActor
    func initialStateNotMigrating() {
        let service = MigrationStatusService.shared
        service.reset()

        #expect(service.isMigrating == false)
        #expect(service.migrationDetails == nil)
    }

    // MARK: - Start Migration Tests

    @Test("startMigration sets isMigrating to true")
    @MainActor
    func startMigrationSetsFlag() {
        let service = MigrationStatusService.shared
        service.reset()

        service.startMigration(from: "1.0", to: "2.0")

        #expect(service.isMigrating == true)
    }

    @Test("startMigration creates migration details")
    @MainActor
    func startMigrationCreatesDetails() {
        let service = MigrationStatusService.shared
        service.reset()

        service.startMigration(from: "1.0", to: "2.0")

        #expect(service.migrationDetails != nil)
        #expect(service.migrationDetails?.fromVersion == "1.0")
        #expect(service.migrationDetails?.toVersion == "2.0")
    }

    @Test("Migration details description is correct")
    @MainActor
    func migrationDetailsDescription() {
        let service = MigrationStatusService.shared
        service.reset()

        service.startMigration(from: "1.0", to: "2.0")

        #expect(service.migrationDetails?.description == "Upgrading from v1.0 to v2.0")
    }

    // MARK: - Fail Migration Tests

    @Test("failMigration clears state immediately")
    @MainActor
    func failMigrationClearsState() {
        let service = MigrationStatusService.shared
        service.reset()

        service.startMigration(from: "1.0", to: "2.0")
        #expect(service.isMigrating == true)

        service.failMigration(error: NSError(domain: "test", code: 1))

        #expect(service.isMigrating == false)
        #expect(service.migrationDetails == nil)
    }

    // MARK: - Reset Tests

    @Test("reset clears all state")
    @MainActor
    func resetClearsAllState() {
        let service = MigrationStatusService.shared

        service.startMigration(from: "1.0", to: "2.0")
        #expect(service.isMigrating == true)
        #expect(service.migrationDetails != nil)

        service.reset()

        #expect(service.isMigrating == false)
        #expect(service.migrationDetails == nil)
    }

    // MARK: - Race Condition Prevention Tests

    @Test("New migration during completion delay cancels old completion")
    @MainActor
    func newMigrationCancelsOldCompletion() async {
        let service = MigrationStatusService.shared
        service.reset()

        // Start first migration
        service.startMigration(from: "1.0", to: "2.0")
        #expect(service.isMigrating == true)

        // Complete first migration (this schedules delayed reset)
        service.completeMigration()

        // Immediately start a second migration
        service.startMigration(from: "2.0", to: "3.0")
        #expect(service.isMigrating == true)
        #expect(service.migrationDetails?.fromVersion == "2.0")
        #expect(service.migrationDetails?.toVersion == "3.0")

        // Wait longer than the completion delay (3.5 seconds)
        // The old completion should NOT reset the new migration
        try? await Task.sleep(nanoseconds: 3_600_000_000) // 3.6 seconds

        // The second migration should still be active
        // (old completion was cancelled due to different migration ID)
        #expect(service.isMigrating == true)
        #expect(service.migrationDetails?.toVersion == "3.0")

        // Clean up
        service.reset()
    }
}

// MARK: - MigrationDetails Tests

#if swift(>=6.1)
@Suite("MigrationDetails Tests", .tags(.isolated, .fast))
#else
@Suite("MigrationDetails Tests")
#endif
struct MigrationDetailsTests {

    @Test("MigrationDetails stores correct values")
    func storesCorrectValues() {
        let startTime = Date()
        let details = MigrationDetails(
            fromVersion: "10.0.0",
            toVersion: "11.0.0",
            startTime: startTime
        )

        #expect(details.fromVersion == "10.0.0")
        #expect(details.toVersion == "11.0.0")
        #expect(details.startTime == startTime)
    }

    @Test("Description format is correct")
    func descriptionFormat() {
        let details = MigrationDetails(
            fromVersion: "10",
            toVersion: "11",
            startTime: Date()
        )

        #expect(details.description == "Upgrading from v10 to v11")
    }
}
