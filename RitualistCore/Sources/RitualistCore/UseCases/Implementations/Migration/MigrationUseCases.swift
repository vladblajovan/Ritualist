//
//  MigrationUseCases.swift
//  RitualistCore
//
//  Created by Claude on 04.11.2025.
//

import Foundation

/// UseCase implementation for getting migration status
/// Wraps MigrationStatusService to maintain Clean Architecture layer separation
@MainActor
public struct GetMigrationStatusUseCaseImpl: GetMigrationStatusUseCase {
    private let migrationStatusService: MigrationStatusService

    public init(migrationStatusService: MigrationStatusService) {
        self.migrationStatusService = migrationStatusService
    }

    public var isMigrating: Bool {
        migrationStatusService.isMigrating
    }

    public var migrationDetails: MigrationDetails? {
        migrationStatusService.migrationDetails
    }
}
