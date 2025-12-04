//
//  CloudKitCleanupService.swift
//  RitualistCore
//
//  One-time cleanup service to remove PersonalityAnalysis records from CloudKit.
//  This is needed after moving PersonalityAnalysisModel to local-only storage.
//
//  REMOVAL NOTICE: This file can be deleted after all TestFlight users have
//  updated to a version that includes this cleanup (approximately 2-3 releases).
//

import Foundation
import CloudKit

// MARK: - Protocol

public protocol CloudKitCleanupServiceProtocol: Sendable {
    /// Performs one-time cleanup of PersonalityAnalysis records from CloudKit
    /// Returns the number of records deleted, or nil if cleanup was already done
    func cleanupPersonalityAnalysisFromCloudKit() async throws -> Int?
}

// MARK: - Implementation

public final class CloudKitCleanupService: CloudKitCleanupServiceProtocol, Sendable {

    private let logger: DebugLogger

    /// UserDefaults key to track if cleanup has been performed
    private static let cleanupCompletedKey = "personalityAnalysisCloudKitCleanupCompleted"

    /// CloudKit record type for PersonalityAnalysisModel (SwiftData prefixes with CD_)
    private static let recordType = "CD_PersonalityAnalysisModel"

    public init(logger: DebugLogger) {
        self.logger = logger
    }

    public func cleanupPersonalityAnalysisFromCloudKit() async throws -> Int? {
        // Check if cleanup was already performed
        if UserDefaults.standard.bool(forKey: Self.cleanupCompletedKey) {
            logger.log(
                "PersonalityAnalysis CloudKit cleanup already completed, skipping",
                level: .debug,
                category: .system
            )
            return nil
        }

        logger.log(
            "Starting one-time PersonalityAnalysis CloudKit cleanup",
            level: .info,
            category: .system
        )

        let container = CKContainer(identifier: iCloudConstants.containerIdentifier)
        let database = container.privateCloudDatabase

        // Query all PersonalityAnalysis records
        let query = CKQuery(
            recordType: Self.recordType,
            predicate: NSPredicate(value: true)  // Match all records
        )

        var totalDeleted = 0
        var cursor: CKQueryOperation.Cursor?

        // Fetch and delete in batches (CloudKit has limits)
        repeat {
            let (records, nextCursor) = try await fetchBatch(
                database: database,
                query: query,
                cursor: cursor
            )

            if !records.isEmpty {
                let recordIDs = records.map { $0.recordID }
                try await deleteRecords(database: database, recordIDs: recordIDs)
                totalDeleted += recordIDs.count

                logger.log(
                    "Deleted batch of PersonalityAnalysis records from CloudKit",
                    level: .info,
                    category: .system,
                    metadata: ["batch_count": recordIDs.count, "total_deleted": totalDeleted]
                )
            }

            cursor = nextCursor
        } while cursor != nil

        // Mark cleanup as completed
        UserDefaults.standard.set(true, forKey: Self.cleanupCompletedKey)

        logger.log(
            "PersonalityAnalysis CloudKit cleanup completed",
            level: .info,
            category: .system,
            metadata: ["total_deleted": totalDeleted]
        )

        return totalDeleted
    }

    // MARK: - Private Helpers

    private func fetchBatch(
        database: CKDatabase,
        query: CKQuery,
        cursor: CKQueryOperation.Cursor?
    ) async throws -> ([CKRecord], CKQueryOperation.Cursor?) {
        if let cursor = cursor {
            let (results, nextCursor) = try await database.records(continuingMatchFrom: cursor)
            let records = results.compactMap { try? $0.1.get() }
            return (records, nextCursor)
        } else {
            let (results, nextCursor) = try await database.records(matching: query)
            let records = results.compactMap { try? $0.1.get() }
            return (records, nextCursor)
        }
    }

    private func deleteRecords(database: CKDatabase, recordIDs: [CKRecord.ID]) async throws {
        let (_, deleteResults) = try await database.modifyRecords(
            saving: [],
            deleting: recordIDs
        )

        // Check for any deletion errors
        for (recordID, result) in deleteResults {
            if case .failure(let error) = result {
                logger.log(
                    "Failed to delete PersonalityAnalysis record from CloudKit",
                    level: .warning,
                    category: .system,
                    metadata: ["recordID": recordID.recordName, "error": error.localizedDescription]
                )
            }
        }
    }
}

// MARK: - Disabled Implementation

/// No-op implementation for when CloudKit is disabled
public final class DisabledCloudKitCleanupService: CloudKitCleanupServiceProtocol, Sendable {
    public init() {}

    public func cleanupPersonalityAnalysisFromCloudKit() async throws -> Int? {
        return nil
    }
}
