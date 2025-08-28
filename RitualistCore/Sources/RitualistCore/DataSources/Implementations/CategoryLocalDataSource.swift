import Foundation
import SwiftData

/// @ModelActor implementation of CategoryLocalDataSource  
/// Runs database operations on background actor thread for optimal performance
@ModelActor
public actor CategoryLocalDataSource: CategoryLocalDataSourceProtocol {
    
    private lazy var predefinedCategories: [HabitCategory] = {
        [
            HabitCategory(
                id: "health",
                name: "health", 
                displayName: "Health",
                emoji: "💪",
                order: 0,
                isActive: true,
                isPredefined: true,
                personalityWeights: [
                    "conscientiousness": 0.6,
                    "neuroticism": -0.3,
                    "agreeableness": 0.2
                ]
            ),
            HabitCategory(
                id: "wellness",
                name: "wellness",
                displayName: "Wellness", 
                emoji: "🧘",
                order: 1,
                isActive: true,
                isPredefined: true,
                personalityWeights: [
                    "conscientiousness": 0.4,
                    "neuroticism": -0.5,
                    "openness": 0.3,
                    "agreeableness": 0.2
                ]
            ),
            HabitCategory(
                id: "productivity",
                name: "productivity",
                displayName: "Productivity",
                emoji: "⚡",
                order: 2, 
                isActive: true,
                isPredefined: true,
                personalityWeights: [
                    "conscientiousness": 0.8,
                    "neuroticism": -0.2,
                    "openness": 0.1
                ]
            ),
            HabitCategory(
                id: "social",
                name: "social",
                displayName: "Social",
                emoji: "👥",
                order: 3,
                isActive: true, 
                isPredefined: true,
                personalityWeights: [
                    "extraversion": 0.7,
                    "agreeableness": 0.6,
                    "conscientiousness": 0.3
                ]
            ),
            HabitCategory(
                id: "learning",
                name: "learning",
                displayName: "Learning",
                emoji: "📚", 
                order: 4,
                isActive: true,
                isPredefined: true,
                personalityWeights: [
                    "openness": 0.8,
                    "conscientiousness": 0.5,
                    "extraversion": 0.2
                ]
            ),
            HabitCategory(
                id: "creativity",
                name: "creativity",
                displayName: "Creativity",
                emoji: "🎨",
                order: 5,
                isActive: true,
                isPredefined: true,
                personalityWeights: [
                    "openness": 0.9,
                    "extraversion": 0.3,
                    "conscientiousness": 0.1
                ]
            )
        ]
    }()
    
    private func getStoredCategories() async throws -> [HabitCategory] {
        let descriptor = FetchDescriptor<HabitCategoryModel>()
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
        let categoryModel = HabitCategoryModel.fromEntity(category)
        modelContext.insert(categoryModel)
        try modelContext.save()
    }
    
    public func updateCategory(_ category: HabitCategory) async throws {
        let descriptor = FetchDescriptor<HabitCategoryModel>(
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
            let categoryModel = HabitCategoryModel.fromEntity(category)
            modelContext.insert(categoryModel)
            try modelContext.save()
        }
    }
    
    public func deleteCategory(id: String) async throws {
        let descriptor = FetchDescriptor<HabitCategoryModel>(
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
