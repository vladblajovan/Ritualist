//
//  DebugService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 18.08.2025.
//

import Foundation

#if DEBUG

/// Service for debug operations like database clearing
/// Only available in debug builds
public protocol DebugServiceProtocol: Sendable {
    /// Clear all data from the database
    func clearDatabase() async throws

    /// Get database statistics
    func getDatabaseStats() async throws -> DebugDatabaseStats
}

#endif
