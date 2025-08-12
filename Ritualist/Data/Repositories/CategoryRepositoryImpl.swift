//
//  CategoryRepositoryImpl.swift
//  Ritualist
//
//  Created by Claude on 03.08.2025.
//

import Foundation
import RitualistCore

public final class CategoryRepositoryImpl: CategoryRepository {
    private let localDataSource: CategoryLocalDataSourceProtocol
    
    public init(local: CategoryLocalDataSourceProtocol) {
        self.localDataSource = local
    }
    
    public func getAllCategories() async throws -> [Category] {
        try await localDataSource.getAllCategories()
    }
    
    public func getCategory(by id: String) async throws -> Category? {
        try await localDataSource.getCategory(by: id)
    }
    
    public func getActiveCategories() async throws -> [Category] {
        try await localDataSource.getActiveCategories()
    }
    
    public func getPredefinedCategories() async throws -> [Category] {
        try await localDataSource.getPredefinedCategories()
    }
    
    public func getCustomCategories() async throws -> [Category] {
        try await localDataSource.getCustomCategories()
    }
    
    public func createCustomCategory(_ category: Category) async throws {
        try await localDataSource.createCustomCategory(category)
    }
    
    public func updateCategory(_ category: Category) async throws {
        try await localDataSource.updateCategory(category)
    }
    
    public func deleteCategory(id: String) async throws {
        try await localDataSource.deleteCategory(id: id)
    }
    
    public func categoryExists(id: String) async throws -> Bool {
        try await localDataSource.categoryExists(id: id)
    }
    
    public func categoryExists(name: String) async throws -> Bool {
        try await localDataSource.categoryExists(name: name)
    }
}