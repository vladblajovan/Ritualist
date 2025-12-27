//
//  DebugService.swift
//  RitualistCore
//
//  Created by Claude on 18.08.2025.
//

import Foundation

#if DEBUG

/// Service for debug operations like database clearing
/// Only available in debug builds
@MainActor
public protocol DebugServiceProtocol {
    /// Clear all data from the database
    func clearDatabase() async throws

    /// Get database statistics
    func getDatabaseStats() throws -> DebugDatabaseStats
}

#endif