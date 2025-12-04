//
//  CloudKitCleanupService.swift
//  RitualistCore
//
//  One-time cleanup service to remove PersonalityAnalysis records from CloudKit.
//  This is needed after moving PersonalityAnalysisModel to local-only storage.
//
//  REMOVAL NOTICE: This file can be deleted after v2.5.0 (target: March 2025)
//  when all TestFlight users have updated to a version that includes this cleanup.
//  Tech debt tracked in: GitHub Issue #TBD
//
//  Migration Impact & Downgrade Behavior:
//  - PersonalityAnalysis data is now stored locally only (not synced to CloudKit)
//  - If user downgrades to an older version that expects CloudKit sync:
//    - Old version will see empty personality data (local data exists but CloudKit is empty)
//    - User would need to retake personality quiz on older version
//  - If user upgrades again after downgrade:
//    - Local data from this version is preserved (stored in Local.store)
//    - CloudKit cleanup runs again if flag was not set
//  - This is acceptable because personality analysis is easily regenerated
//

import Foundation
import CloudKit

// MARK: - Protocol

public protocol CloudKitCleanupServiceProtocol: Sendable {
    /// Performs one-time cleanup of PersonalityAnalysis records from CloudKit
    /// Returns the number of records deleted, or nil if cleanup was already done
    func cleanupPersonalityAnalysisFromCloudKit() async throws -> Int?
}

// MARK: - Errors

public enum CloudKitCleanupError: LocalizedError {
    case partialFailure(successCount: Int, failureCount: Int)

    public var errorDescription: String? {
        switch self {
        case .partialFailure(let successCount, let failureCount):
            return "CloudKit cleanup partially failed: \(successCount) deleted, \(failureCount) failed"
        }
    }
}

// MARK: - Implementation

public final class CloudKitCleanupService: CloudKitCleanupServiceProtocol, Sendable {

    private let logger: DebugLogger

    /// UserDefaults key to track if cleanup has been performed
    private static let cleanupCompletedKey = "personalityAnalysisCloudKitCleanupCompleted"

    /// CloudKit record type for PersonalityAnalysisModel
    ///
    /// SwiftData automatically prefixes CloudKit record types with "CD_" (Core Data).
    /// This naming convention is internal to SwiftData's CloudKit integration and cannot
    /// be customized. When querying CloudKit records created by SwiftData, you must use
    /// this prefixed format: "CD_" + ModelTypeName.
    ///
    /// Reference: This is observable in CloudKit Dashboard when inspecting synced records.
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
        var totalFailed = 0
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
                let failedCount = try await deleteRecords(database: database, recordIDs: recordIDs)
                let successCount = recordIDs.count - failedCount
                totalDeleted += successCount
                totalFailed += failedCount

                logger.log(
                    "Deleted batch of PersonalityAnalysis records from CloudKit",
                    level: .info,
                    category: .system,
                    metadata: [
                        "batch_success": successCount,
                        "batch_failed": failedCount,
                        "total_deleted": totalDeleted
                    ]
                )
            }

            cursor = nextCursor
        } while cursor != nil

        // Only mark cleanup as completed if ALL deletions succeeded
        if totalFailed > 0 {
            logger.log(
                "PersonalityAnalysis CloudKit cleanup had failures, will retry on next launch",
                level: .warning,
                category: .system,
                metadata: ["total_deleted": totalDeleted, "total_failed": totalFailed]
            )
            throw CloudKitCleanupError.partialFailure(successCount: totalDeleted, failureCount: totalFailed)
        }

        // All deletions succeeded - mark cleanup as completed
        UserDefaults.standard.set(true, forKey: Self.cleanupCompletedKey)

        logger.log(
            "PersonalityAnalysis CloudKit cleanup completed successfully",
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
        let (results, nextCursor): ([(CKRecord.ID, Result<CKRecord, Error>)], CKQueryOperation.Cursor?)

        if let cursor = cursor {
            (results, nextCursor) = try await database.records(continuingMatchFrom: cursor)
        } else {
            (results, nextCursor) = try await database.records(matching: query)
        }

        // Extract records, logging any fetch errors instead of silently discarding
        var records: [CKRecord] = []
        for (recordID, result) in results {
            switch result {
            case .success(let record):
                records.append(record)
            case .failure(let error):
                logger.log(
                    "Failed to fetch record during cleanup",
                    level: .warning,
                    category: .system,
                    metadata: ["recordID": recordID.recordName, "error": error.localizedDescription]
                )
            }
        }

        return (records, nextCursor)
    }

    /// Delete records from CloudKit and return the count of failures
    /// - Returns: Number of records that failed to delete
    private func deleteRecords(database: CKDatabase, recordIDs: [CKRecord.ID]) async throws -> Int {
        let (_, deleteResults) = try await database.modifyRecords(
            saving: [],
            deleting: recordIDs
        )

        // Count and log any deletion errors
        var failureCount = 0
        for (recordID, result) in deleteResults {
            if case .failure(let error) = result {
                failureCount += 1
                logger.log(
                    "Failed to delete PersonalityAnalysis record from CloudKit",
                    level: .warning,
                    category: .system,
                    metadata: ["recordID": recordID.recordName, "error": error.localizedDescription]
                )
            }
        }

        return failureCount
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
