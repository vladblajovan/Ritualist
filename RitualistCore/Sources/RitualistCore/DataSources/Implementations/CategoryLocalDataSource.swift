import Foundation
import SwiftData

/// @ModelActor implementation of CategoryLocalDataSource
/// Runs database operations on background actor thread for optimal performance
@ModelActor
public actor CategoryLocalDataSource: CategoryLocalDataSourceProtocol {

    private let categoryDefinitionsService: CategoryDefinitionsServiceProtocol = CategoryDefinitionsService()

    private var predefinedCategories: [HabitCategory] {
        categoryDefinitionsService.getPredefinedCategories()
    }
    
    private func getStoredCategories() async throws -> [HabitCategory] {
        let descriptor = FetchDescriptor<ActiveHabitCategoryModel>()
        let categories = try modelContext.fetch(descriptor)
        return categories.map { $0.toEntity() }
    }
    
    public func getAllCategories() async throws -> [HabitCategory] {
        let storedCategories = try await getStoredCategories()
        let allCategories = predefinedCategories + storedCategories
        return allCategories.sorted { $0.order < $1.order }
    }
    
    public func getCategory(by id: String) async throws -> HabitCategory? {
        return try await getAllCategories().first { $0.id == id }
    }
    
    public func getActiveCategories() async throws -> [HabitCategory] {
        return try await getAllCategories().filter { $0.isActive }
    }
    
    public func getPredefinedCategories() async throws -> [HabitCategory] {
        return predefinedCategories.filter { $0.isActive }
    }
    
    public func getCustomCategories() async throws -> [HabitCategory] {
        return try await getStoredCategories().filter { $0.isActive }
    }
    
    public func createCustomCategory(_ category: HabitCategory) async throws {
        let categoryModel = ActiveHabitCategoryModel.fromEntity(category)
        modelContext.insert(categoryModel)
        try modelContext.save()
    }
    
    public func updateCategory(_ category: HabitCategory) async throws {
        let descriptor = FetchDescriptor<ActiveHabitCategoryModel>(
            predicate: #Predicate { $0.id == category.id }
        )
        
        if let existingCategory = try modelContext.fetch(descriptor).first {
            // Update existing category
            existingCategory.name = category.name
            existingCategory.displayName = category.displayName
            existingCategory.emoji = category.emoji
            existingCategory.order = category.order
            existingCategory.isActive = category.isActive
            existingCategory.isPredefined = category.isPredefined
            try modelContext.save()
        } else {
            // Create new category if it doesn't exist
            let categoryModel = ActiveHabitCategoryModel.fromEntity(category)
            modelContext.insert(categoryModel)
            try modelContext.save()
        }
    }
    
    public func deleteCategory(id: String) async throws {
        let descriptor = FetchDescriptor<ActiveHabitCategoryModel>(
            predicate: #Predicate { $0.id == id }
        )
        
        let categories = try modelContext.fetch(descriptor)
        for category in categories {
            modelContext.delete(category)
        }
        try modelContext.save()
    }
    
    public func categoryExists(id: String) async throws -> Bool {
        return try await getCategory(by: id) != nil
    }
    
    public func categoryExists(name: String) async throws -> Bool {
        let categories = try await getAllCategories()
        return categories.contains { $0.name.lowercased() == name.lowercased() }
    }
}
