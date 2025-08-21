//
//  HabitLocalDataSourceProtocol.swift
//  RitualistCore
//
//  Created by Claude on 16.08.2025.
//

import Foundation

/// Protocol for local habit data source operations
public protocol HabitLocalDataSourceProtocol {
    /// Fetch all habits from local storage
    func fetchAll() async throws -> [Habit]
    
    /// Fetch a single habit by ID from local storage
    func fetch(by id: UUID) async throws -> Habit?
    
    /// Insert or update a habit in local storage
    func upsert(_ habit: Habit) async throws
    
    /// Delete a habit by ID
    func delete(id: UUID) async throws
    
    /// Clean up orphaned habits and return count of cleaned habits
    func cleanupOrphanedHabits() async throws -> Int
}