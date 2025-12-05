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
    private let habitSuggestionsService: HabitSuggestionsService
    private let logger: DebugLogger
    private let userDefaults: UserDefaults

    public init(
        categoryRepository: CategoryRepository,
        categoryDefinitionsService: CategoryDefinitionsServiceProtocol,
        habitRepository: HabitRepository,
        habitSuggestionsService: HabitSuggestionsService,
        logger: DebugLogger,
        userDefaults: UserDefaults = .standard
    ) {
        self.categoryRepository = categoryRepository
        self.categoryDefinitionsService = categoryDefinitionsService
        self.habitRepository = habitRepository
        self.habitSuggestionsService = habitSuggestionsService
        self.logger = logger
        self.userDefaults = userDefaults
    }

    public func execute() async throws {
        // Check if seeding has already been completed
        if userDefaults.bool(forKey: UserDefaultsKeys.categorySeedingCompleted) {
            logger.log(
                "Category seeding already completed, skipping",
                level: .debug,
                category: .system
            )
            return
        }

        // Get all predefined categories from the definitions service
        let predefinedCategories = categoryDefinitionsService.getPredefinedCategories()

        logger.log(
            "Seeding predefined categories",
            level: .info,
            category: .system,
            metadata: ["categoryCount": predefinedCategories.count]
        )

        // Track success and failures for error recovery
        var successCount = 0
        var failedCategories: [(category: HabitCategory, error: Error)] = []

        // Use updateCategory which handles both create and update
        // This ensures predefined categories are always in sync with definitions
        for category in predefinedCategories {
            do {
                let exists = try await categoryRepository.categoryExists(id: category.id)

                if !exists {
                    logger.log(
                        "Creating category",
                        level: .info,
                        category: .system,
                        metadata: ["name": category.displayName, "id": category.id]
                    )
                } else {
                    logger.log(
                        "Updating category",
                        level: .debug,
                        category: .system,
                        metadata: ["name": category.displayName, "id": category.id]
                    )
                }

                try await categoryRepository.updateCategory(category)
                successCount += 1
            } catch {
                logger.log(
                    "Failed to seed category",
                    level: .warning,
                    category: .system,
                    metadata: [
                        "name": category.displayName,
                        "id": category.id,
                        "error": error.localizedDescription
                    ]
                )
                failedCategories.append((category, error))
            }
        }

        logger.log(
            "Category seeding complete",
            level: .info,
            category: .system,
            metadata: [
                "successCount": successCount,
                "failedCount": failedCategories.count
            ]
        )

        // Repair broken category relationships for habits from suggestions
        // This fixes habits that were created before seeding ran
        try await repairBrokenCategoryRelationships()

        // Mark seeding as completed only if all categories were seeded successfully
        if failedCategories.isEmpty {
            userDefaults.set(true, forKey: UserDefaultsKeys.categorySeedingCompleted)
            logger.log(
                "Marked category seeding as completed",
                level: .info,
                category: .system
            )
        } else {
            logger.log(
                "Not marking seeding as completed due to failures",
                level: .warning,
                category: .system,
                metadata: ["failedCount": failedCategories.count]
            )
        }
    }

    private func repairBrokenCategoryRelationships() async throws {
        logger.log(
            "Repairing broken category relationships",
            level: .info,
            category: .system
        )

        // Get suggestions to find which categoryId each suggestionId should have
        let allSuggestions = habitSuggestionsService.getSuggestions()
        let suggestionCategoryMap = Dictionary(uniqueKeysWithValues: allSuggestions.map { ($0.id, $0.categoryId) })

        // Get all habits from repository
        let allHabits = try await habitRepository.fetchAllHabits()

        var repairedCount = 0
        var failedRepairs: [(habitName: String, error: Error)] = []

        for habit in allHabits {
            // Only repair habits from suggestions
            guard let suggestionId = habit.suggestionId else { continue }

            // Check if this habit has a broken category relationship
            // (has suggestionId but no categoryId, meaning relationship is NULL)
            if habit.categoryId == nil {
                // Look up the correct categoryId from the suggestion
                if let correctCategoryId = suggestionCategoryMap[suggestionId] {
                    do {
                        // Create a new habit with the correct categoryId
                        var repairedHabit = habit
                        repairedHabit.categoryId = correctCategoryId

                        logger.log(
                            "Repairing category relationship",
                            level: .debug,
                            category: .system,
                            metadata: ["habit": habit.name, "categoryId": correctCategoryId]
                        )
                        try await habitRepository.update(repairedHabit)
                        repairedCount += 1
                    } catch {
                        logger.log(
                            "Failed to repair category relationship",
                            level: .warning,
                            category: .system,
                            metadata: [
                                "habit": habit.name,
                                "error": error.localizedDescription
                            ]
                        )
                        failedRepairs.append((habit.name, error))
                    }
                }
            }
        }

        logger.log(
            "Category relationship repair complete",
            level: .info,
            category: .system,
            metadata: [
                "repairedCount": repairedCount,
                "failedCount": failedRepairs.count
            ]
        )
    }
}
