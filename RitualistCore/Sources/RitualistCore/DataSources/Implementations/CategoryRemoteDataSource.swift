//
//  CategoryRemoteDataSource.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import Foundation
import SwiftData

public final class CategoryRemoteDataSource: CategoryLocalDataSourceProtocol {
    public init() {}
    
    // TODO: Implement backend integration when available
    // For now, this is a NoOp implementation - replace with real backend calls
    
    public func getAllCategories() async throws -> [HabitCategory] {
        // TODO: Fetch from backend API
        // For now, return empty array until backend is available
        return []
    }
    
    public func getCategory(by id: String) async throws -> HabitCategory? {
        // TODO: Fetch specific category from backend API
        return nil
    }
    
    public func getActiveCategories() async throws -> [HabitCategory] {
        // TODO: Fetch active categories from backend API
        return []
    }
    
    public func getPredefinedCategories() async throws -> [HabitCategory] {
        // TODO: Fetch predefined categories from backend API
        return []
    }
    
    public func getCustomCategories() async throws -> [HabitCategory] {
        // TODO: Fetch custom categories from backend API
        return []
    }
    
    public func createCustomCategory(_ category: HabitCategory) async throws {
        // TODO: Create custom category via backend API
        // For now, this is a NoOp until backend is available
    }
    
    public func updateCategory(_ category: HabitCategory) async throws {
        // TODO: Update category via backend API
        // For now, this is a NoOp until backend is available
    }
    
    public func deleteCategory(id: String) async throws {
        // TODO: Delete category via backend API
        // For now, this is a NoOp until backend is available
    }
    
    public func categoryExists(id: String) async throws -> Bool {
        // TODO: Check if category exists via backend API
        // For now, return false until backend is available
        return false
    }
    
    public func categoryExists(name: String) async throws -> Bool {
        // TODO: Check if category name exists via backend API
        // For now, return false until backend is available
        return false
    }
}
