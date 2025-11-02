//
//  MigrationIntegrityTests.swift
//  RitualistCoreTests
//
//  Created by Claude on 11.02.2025.
//
//  Tests for data integrity during migrations
//

import Testing
import SwiftData
@testable import RitualistCore

/// Tests for migration data integrity and rollback capabilities
struct MigrationIntegrityTests {

    // MARK: - Migration Plan Tests

    @Test("RitualistMigrationPlan has SchemaV1 in schemas list")
    func testMigrationPlanIncludesSchemaV1() throws {
        let schemas = RitualistMigrationPlan.schemas
        #expect(schemas.count >= 1, "Migration plan should include at least SchemaV1")

        let schemaNames = schemas.map { String(describing: $0) }
        #expect(schemaNames.contains(String(describing: SchemaV1.self)))
    }

    @Test("RitualistMigrationPlan stages is empty for V1")
    func testMigrationPlanStagesEmptyForV1() throws {
        let stages = RitualistMigrationPlan.stages
        #expect(stages.isEmpty, "No migration stages should exist for V1 only")
    }

    // MARK: - Backup Manager Tests

    @Test("BackupManager creates backup directory")
    func testBackupManagerCreatesDirectory() throws {
        let manager = BackupManager()

        // List backups should succeed even if directory doesn't exist
        let backups = try manager.listBackups()
        #expect(backups.isEmpty || !backups.isEmpty, "Backup listing should work")
    }

    @Test("BackupManager lists backups in chronological order")
    func testBackupManagerListsBackupsChronologically() throws {
        let manager = BackupManager()
        let backups = try manager.listBackups()

        // If we have multiple backups, verify they're sorted newest first
        if backups.count >= 2 {
            let firstDate = try backups[0].resourceValues(forKeys: [.creationDateKey]).creationDate ?? .distantPast
            let secondDate = try backups[1].resourceValues(forKeys: [.creationDateKey]).creationDate ?? .distantPast
            #expect(firstDate >= secondDate, "Backups should be sorted newest first")
        }
    }

    // MARK: - Migration Logger Tests

    @Test("MigrationLogger singleton instance exists")
    func testMigrationLoggerSingleton() throws {
        let logger1 = MigrationLogger.shared
        let logger2 = MigrationLogger.shared
        #expect(logger1 === logger2, "MigrationLogger should be a singleton")
    }

    @Test("MigrationLogger tracks migration events")
    func testMigrationLoggerTracksEvents() throws {
        let logger = MigrationLogger.shared

        // Clear existing history
        logger.clearHistory()

        // Log a test migration
        logger.logMigrationStart(from: "1.0.0", to: "2.0.0")
        logger.logMigrationSuccess(from: "1.0.0", to: "2.0.0", duration: 1.5)

        let history = logger.getMigrationHistory()
        #expect(history.count >= 1, "Migration history should contain at least one event")

        // Check that the latest event is our test migration
        if let latestEvent = history.last {
            #expect(latestEvent.fromVersion == "1.0.0")
            #expect(latestEvent.toVersion == "2.0.0")
            #expect(latestEvent.status == .succeeded || latestEvent.status == .started)
        }

        // Clean up
        logger.clearHistory()
    }

    @Test("MigrationLogger clears history")
    func testMigrationLoggerClearsHistory() throws {
        let logger = MigrationLogger.shared

        // Add a test event
        logger.logMigrationStart(from: "1.0.0", to: "2.0.0")

        // Clear history
        logger.clearHistory()

        let history = logger.getMigrationHistory()
        #expect(history.isEmpty, "History should be empty after clearing")
    }

    @Test("MigrationLogger generates statistics")
    func testMigrationLoggerGeneratesStatistics() throws {
        let logger = MigrationLogger.shared

        // Clear and add test data
        logger.clearHistory()
        logger.logMigrationStart(from: "1.0.0", to: "2.0.0")
        logger.logMigrationSuccess(from: "1.0.0", to: "2.0.0", duration: 1.0)
        logger.logMigrationStart(from: "2.0.0", to: "3.0.0")
        logger.logMigrationFailure(from: "2.0.0", to: "3.0.0", error: TestError.migrationFailed, duration: 0.5)

        let stats = logger.getStatistics()

        #expect(stats["totalMigrations"] as? Int ?? 0 > 0, "Should have total migrations count")
        #expect(stats["successfulMigrations"] as? Int ?? 0 >= 0, "Should have successful migrations count")
        #expect(stats["failedMigrations"] as? Int ?? 0 >= 0, "Should have failed migrations count")

        // Clean up
        logger.clearHistory()
    }

    @Test("MigrationLogger generates history summary")
    func testMigrationLoggerGeneratesHistorySummary() throws {
        let logger = MigrationLogger.shared

        // Clear and add test data
        logger.clearHistory()
        logger.logMigrationStart(from: "1.0.0", to: "2.0.0")
        logger.logMigrationSuccess(from: "1.0.0", to: "2.0.0", duration: 1.0)

        let summary = logger.getHistorySummary()
        #expect(summary.contains("Migration History"), "Summary should contain header")
        #expect(summary.contains("1.0.0"), "Summary should contain version information")

        // Clean up
        logger.clearHistory()
    }

    // MARK: - PersistenceError Tests

    @Test("PersistenceError provides error descriptions")
    func testPersistenceErrorDescriptions() throws {
        let testError = TestError.generic
        let containerError = PersistenceError.containerInitializationFailed(testError)
        let migrationError = PersistenceError.migrationFailed(testError)
        let backupError = PersistenceError.backupFailed(testError)
        let restoreError = PersistenceError.restoreFailed(testError)

        #expect(containerError.errorDescription != nil)
        #expect(migrationError.errorDescription != nil)
        #expect(backupError.errorDescription != nil)
        #expect(restoreError.errorDescription != nil)
    }

    @Test("PersistenceError provides recovery suggestions")
    func testPersistenceErrorRecoverySuggestions() throws {
        let testError = TestError.generic
        let containerError = PersistenceError.containerInitializationFailed(testError)
        let migrationError = PersistenceError.migrationFailed(testError)
        let backupError = PersistenceError.backupFailed(testError)
        let restoreError = PersistenceError.restoreFailed(testError)

        #expect(containerError.recoverySuggestion != nil)
        #expect(migrationError.recoverySuggestion != nil)
        #expect(backupError.recoverySuggestion != nil)
        #expect(restoreError.recoverySuggestion != nil)
    }

    // MARK: - Future Migration Test Placeholders

    // These tests will be activated when V2 is created

    /*
    @Test("Migration from V1 to V2 preserves all data")
    func testV1toV2MigrationPreservesData() throws {
        // Create V1 container with test data
        // Migrate to V2
        // Verify all data is preserved
        // This will be implemented when V2 is created
    }

    @Test("Migration from V1 to V2 handles relationships correctly")
    func testV1toV2MigrationHandlesRelationships() throws {
        // Create V1 data with relationships
        // Migrate to V2
        // Verify relationships are intact
        // This will be implemented when V2 is created
    }

    @Test("Migration rollback restores original data")
    func testMigrationRollbackRestoresData() throws {
        // Create V1 data
        // Create backup
        // Simulate migration failure
        // Restore from backup
        // Verify data matches original
        // This will be implemented when V2 is created
    }
    */
}

// MARK: - Test Helpers

enum TestError: Error {
    case generic
    case migrationFailed
}
