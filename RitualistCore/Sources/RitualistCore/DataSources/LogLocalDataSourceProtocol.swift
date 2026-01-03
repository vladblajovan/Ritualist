//
//  LogLocalDataSourceProtocol.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import Foundation

/// Protocol for local habit log data source operations
public protocol LogLocalDataSourceProtocol: Sendable {
    /// Retrieve all logs for a specific habit
    func logs(for habitID: UUID) async throws -> [HabitLog]
    
    /// Retrieve all logs for multiple habits in a single query
    func logs(for habitIDs: [UUID]) async throws -> [HabitLog]
    
    /// Insert or update a habit log
    func upsert(_ log: HabitLog) async throws
    
    /// Delete a habit log by ID
    func delete(id: UUID) async throws
}
