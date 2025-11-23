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
        // After seeding, all categories (predefined + custom) are in the database
        // Just fetch from database to avoid duplicates
        return try await getStoredCategories().sorted { $0.order < $1.order }
    }
    
    public func getCategory(by id: String) async throws -> HabitCategory? {
        // After seeding, all categories are in the database - fetch from there
        let descriptor = FetchDescriptor<ActiveHabitCategoryModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first?.toEntity()
    }
    
    public func getActiveCategories() async throws -> [HabitCategory] {
        // After seeding, all categories are in the database - fetch active ones from there
        let descriptor = FetchDescriptor<ActiveHabitCategoryModel>(
            predicate: #Predicate { $0.isActive == true }
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }.sorted { $0.order < $1.order }
    }
    
    public func getPredefinedCategories() async throws -> [HabitCategory] {
        // After seeding, predefined categories are in the database
        let descriptor = FetchDescriptor<ActiveHabitCategoryModel>(
            predicate: #Predicate { $0.isPredefined == true && $0.isActive == true }
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    public func getCustomCategories() async throws -> [HabitCategory] {
        // Custom categories are those created by user (not predefined)
        let descriptor = FetchDescriptor<ActiveHabitCategoryModel>(
            predicate: #Predicate { $0.isPredefined == false && $0.isActive == true }
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
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
        // Only check database - predefined categories need to be persisted too
        let descriptor = FetchDescriptor<ActiveHabitCategoryModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try !modelContext.fetch(descriptor).isEmpty
    }

    public func categoryExists(name: String) async throws -> Bool {
        let lowercasedName = name.lowercased()

        // After seeding, all categories are in the database - check there
        // Note: SwiftData doesn't support case-insensitive predicates directly,
        // so we fetch just the names and compare in memory
        var descriptor = FetchDescriptor<ActiveHabitCategoryModel>()
        descriptor.propertiesToFetch = [\.name] // Only fetch name field, not full models
        let storedCategories = try modelContext.fetch(descriptor)
        return storedCategories.contains { $0.name.lowercased() == lowercasedName }
    }
}
