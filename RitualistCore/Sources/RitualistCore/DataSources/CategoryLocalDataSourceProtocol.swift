//
//  CategoryLocalDataSourceProtocol.swift
//  RitualistCore
//
//  Created by Claude on 16.08.2025.
//

import Foundation

/// Protocol for local category data source operations
public protocol CategoryLocalDataSourceProtocol: Sendable {
    /// Retrieve all categories from local storage
    func getAllCategories() async throws -> [HabitCategory]
    
    /// Get a specific category by ID
    func getCategory(by id: String) async throws -> HabitCategory?
    
    /// Get all active categories
    func getActiveCategories() async throws -> [HabitCategory]
    
    /// Get predefined system categories
    func getPredefinedCategories() async throws -> [HabitCategory]
    
    /// Get user-created custom categories
    func getCustomCategories() async throws -> [HabitCategory]
    
    /// Create a new custom category
    func createCustomCategory(_ category: HabitCategory) async throws
    
    /// Update an existing category
    func updateCategory(_ category: HabitCategory) async throws
    
    /// Delete a category by ID
    func deleteCategory(id: String) async throws
    
    /// Check if category exists by ID
    func categoryExists(id: String) async throws -> Bool
    
    /// Check if category exists by name
    func categoryExists(name: String) async throws -> Bool
}
