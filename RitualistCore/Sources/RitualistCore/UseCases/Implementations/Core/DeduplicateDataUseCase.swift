//
//  DeduplicateDataUseCase.swift
//  RitualistCore
//
//  Created by Claude on 26.11.2025.
//
//  Use case for deduplicating data after CloudKit sync or import.
//
//  This should be called:
//  1. On app launch (after NSPersistentStoreRemoteChange processing)
//  2. After receiving NSPersistentStoreRemoteChange notifications
//  3. After data import completes
//

import Foundation

// MARK: - Protocol

/// Deduplicate data to clean up duplicate records from CloudKit sync
public protocol DeduplicateDataUseCase: Sendable {
    /// Execute deduplication and return result summary
    func execute() async throws -> DeduplicationResult
}

// MARK: - Implementation

public final class DefaultDeduplicateDataUseCase: DeduplicateDataUseCase {
    private let deduplicationService: DataDeduplicationServiceProtocol
    private let logger: DebugLogger

    public init(
        deduplicationService: DataDeduplicationServiceProtocol,
        logger: DebugLogger
    ) {
        self.deduplicationService = deduplicationService
        self.logger = logger
    }

    public func execute() async throws -> DeduplicationResult {
        logger.log(
            "🔄 Running data deduplication",
            level: .info,
            category: .dataIntegrity
        )

        let result = try await deduplicationService.deduplicateAll()

        if result.hadDuplicates {
            logger.log(
                "✅ Deduplication removed duplicates",
                level: .info,
                category: .dataIntegrity,
                metadata: [
                    "habits": result.habitsRemoved,
                    "categories": result.categoriesRemoved,
                    "logs": result.habitLogsRemoved,
                    "profiles": result.profilesRemoved,
                    "total": result.totalRemoved
                ]
            )
        }

        return result
    }
}
