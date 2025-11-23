//
//  SeedPredefinedCategoriesUseCase.swift
//  RitualistCore
//
//  Created by Claude on 23.11.2025.
//

import Foundation

/// Seeds predefined categories into the database if they don't already exist
/// This ensures that category relationships work properly for habits from suggestions
public protocol SeedPredefinedCategoriesUseCase {
    func execute() async throws
}

public final class SeedPredefinedCategories: SeedPredefinedCategoriesUseCase {
    private let categoryRepository: CategoryRepository
    private let categoryDefinitionsService: CategoryDefinitionsServiceProtocol
    private let habitRepository: HabitRepository

    public init(
        categoryRepository: CategoryRepository,
        categoryDefinitionsService: CategoryDefinitionsServiceProtocol,
        habitRepository: HabitRepository
    ) {
        self.categoryRepository = categoryRepository
        self.categoryDefinitionsService = categoryDefinitionsService
        self.habitRepository = habitRepository
    }

    public func execute() async throws {
        // Get all predefined categories from the definitions service
        let predefinedCategories = categoryDefinitionsService.getPredefinedCategories()

        print("🌱 Seeding predefined categories - Total to seed: \(predefinedCategories.count)")

        // Use updateCategory which handles both create and update
        // This ensures predefined categories are always in sync with definitions
        // (e.g., if user deactivates a category, it will be reactivated on next app launch)
        for category in predefinedCategories {
            let exists = try await categoryRepository.categoryExists(id: category.id)

            if !exists {
                print("🌱 Creating category: \(category.displayName) (id: \(category.id))")
            } else {
                print("🔄 Updating category: \(category.displayName) (id: \(category.id))")
            }

            try await categoryRepository.updateCategory(category)
        }

        print("🌱 Category seeding complete")

        // Repair broken category relationships for habits from suggestions
        // This fixes habits that were created before seeding ran
        try await repairBrokenCategoryRelationships()
    }

    private func repairBrokenCategoryRelationships() async throws {
        print("🔧 Repairing broken category relationships...")

        // Get suggestions to find which categoryId each suggestionId should have
        let habitSuggestionsService = DefaultHabitSuggestionsService()
        let allSuggestions = habitSuggestionsService.getSuggestions()
        let suggestionCategoryMap = Dictionary(uniqueKeysWithValues: allSuggestions.map { ($0.id, $0.categoryId) })

        // Get all habits from repository
        let allHabits = try await habitRepository.fetchAllHabits()

        var repairedCount = 0

        for habit in allHabits {
            // Only repair habits from suggestions
            guard let suggestionId = habit.suggestionId else { continue }

            // Check if this habit has a broken category relationship
            // (has suggestionId but no categoryId, meaning relationship is NULL)
            if habit.categoryId == nil {
                // Look up the correct categoryId from the suggestion
                if let correctCategoryId = suggestionCategoryMap[suggestionId] {
                    // Create a new habit with the correct categoryId
                    var repairedHabit = habit
                    repairedHabit.categoryId = correctCategoryId

                    print("🔧 Repairing: \(habit.name) → \(correctCategoryId)")
                    try await habitRepository.update(repairedHabit)
                    repairedCount += 1
                }
            }
        }

        print("🔧 Repaired \(repairedCount) broken category relationships")
    }
}
