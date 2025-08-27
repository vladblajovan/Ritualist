//
//  DebugService.swift
//  RitualistCore
//
//  Created by Claude on 18.08.2025.
//

import Foundation

/// Service for debug operations like database clearing
/// Only available in debug builds
public protocol DebugServiceProtocol {
    /// Clear all data from the database
    func clearDatabase() async throws
    
    /// Get database statistics
    func getDatabaseStats() async throws -> DebugDatabaseStats
}