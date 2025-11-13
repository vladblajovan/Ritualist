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
        // Check predefined categories first (in-memory, fast)
        if let predefined = predefinedCategories.first(where: { $0.id == id }) {
            return predefined
        }

        // Then check database with targeted query
        let descriptor = FetchDescriptor<ActiveHabitCategoryModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first?.toEntity()
    }
    
    public func getActiveCategories() async throws -> [HabitCategory] {
        // Get active predefined categories (in-memory filter)
        let activePredefined = predefinedCategories.filter { $0.isActive }

        // Get active custom categories (database filter)
        let descriptor = FetchDescriptor<ActiveHabitCategoryModel>(
            predicate: #Predicate { $0.isActive == true }
        )
        let activeStored = try modelContext.fetch(descriptor).map { $0.toEntity() }

        // Combine and sort
        return (activePredefined + activeStored).sorted { $0.order < $1.order }
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
        // Check predefined categories first (in-memory, fast)
        if predefinedCategories.contains(where: { $0.id == id }) {
            return true
        }

        // Then check database with targeted existence query
        let descriptor = FetchDescriptor<ActiveHabitCategoryModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try !modelContext.fetch(descriptor).isEmpty
    }

    public func categoryExists(name: String) async throws -> Bool {
        let lowercasedName = name.lowercased()

        // Check predefined categories first (in-memory)
        if predefinedCategories.contains(where: { $0.name.lowercased() == lowercasedName }) {
            return true
        }

        // Then check database with targeted query
        // Note: SwiftData doesn't support case-insensitive predicates directly,
        // so we fetch and compare in memory (still better than fetching all categories)
        let descriptor = FetchDescriptor<ActiveHabitCategoryModel>()
        let storedCategories = try modelContext.fetch(descriptor)
        return storedCategories.contains { $0.name.lowercased() == lowercasedName }
    }
}
