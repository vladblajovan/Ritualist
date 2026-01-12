//
//  CategoryUseCasesTests.swift
//  RitualistTests
//
//  Tests for category use cases: GetAllCategories, GetCategoryById, GetActiveCategories,
//  GetPredefinedCategories, GetCustomCategories, CreateCustomCategory, UpdateCategory,
//  DeleteCategory, ValidateCategoryName, LoadHabitsData
//

import Testing
import Foundation
@testable import RitualistCore

// MARK: - Test Infrastructure

/// Test double for CategoryRepository with configurable behavior
private final class TestCategoryRepository: CategoryRepository, @unchecked Sendable {
    var categories: [HabitCategory] = []
    var createdCategories: [HabitCategory] = []
    var updatedCategories: [HabitCategory] = []
    var deletedCategoryIds: [String] = []

    init(categories: [HabitCategory] = []) {
        self.categories = categories
    }

    func getAllCategories() async throws -> [HabitCategory] {
        categories
    }

    func getCategory(by id: String) async throws -> HabitCategory? {
        categories.first { $0.id == id }
    }

    func getActiveCategories() async throws -> [HabitCategory] {
        categories.filter { $0.isActive }
    }

    func getPredefinedCategories() async throws -> [HabitCategory] {
        categories.filter { $0.isPredefined }
    }

    func getCustomCategories() async throws -> [HabitCategory] {
        categories.filter { !$0.isPredefined }
    }

    func createCustomCategory(_ category: HabitCategory) async throws {
        createdCategories.append(category)
        categories.append(category)
    }

    func updateCategory(_ category: HabitCategory) async throws {
        updatedCategories.append(category)
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        }
    }

    func deleteCategory(id: String) async throws {
        deletedCategoryIds.append(id)
        categories.removeAll { $0.id == id }
    }

    func categoryExists(id: String) async throws -> Bool {
        categories.contains { $0.id == id }
    }

    func categoryExists(name: String) async throws -> Bool {
        categories.contains { $0.name.lowercased() == name.lowercased() }
    }
}

/// Helper to create test categories
private enum CategoryTestHelper {
    static func predefined(
        id: String = "health",
        name: String = "Health",
        displayName: String = "Health & Fitness",
        emoji: String = "💪",
        order: Int = 0,
        isActive: Bool = true
    ) -> HabitCategory {
        HabitCategory(
            id: id,
            name: name,
            displayName: displayName,
            emoji: emoji,
            order: order,
            isActive: isActive,
            isPredefined: true,
            personalityWeights: nil
        )
    }

    static func custom(
        id: String = "custom-1",
        name: String = "My Category",
        displayName: String = "My Custom Category",
        emoji: String = "⭐️",
        order: Int = 100,
        isActive: Bool = true
    ) -> HabitCategory {
        HabitCategory(
            id: id,
            name: name,
            displayName: displayName,
            emoji: emoji,
            order: order,
            isActive: isActive,
            isPredefined: false,
            personalityWeights: nil
        )
    }
}

// MARK: - GetAllCategories Tests

@Suite("GetAllCategories UseCase", .tags(.categories, .useCase, .businessLogic))
@MainActor
struct GetAllCategoriesUseCaseTests {

    @Test("Returns all categories from repository")
    func returnsAllCategories() async throws {
        // Arrange
        let categories = [
            CategoryTestHelper.predefined(id: "health"),
            CategoryTestHelper.predefined(id: "work", name: "Work"),
            CategoryTestHelper.custom()
        ]
        let repo = TestCategoryRepository(categories: categories)
        let useCase = GetAllCategories(repo: repo)

        // Act
        let result = try await useCase.execute()

        // Assert
        #expect(result.count == 3, "Should return all categories")
    }

    @Test("Returns empty array when no categories exist")
    func returnsEmptyArrayWhenNoCategories() async throws {
        // Arrange
        let repo = TestCategoryRepository(categories: [])
        let useCase = GetAllCategories(repo: repo)

        // Act
        let result = try await useCase.execute()

        // Assert
        #expect(result.isEmpty, "Should return empty array")
    }
}

// MARK: - GetCategoryById Tests

@Suite("GetCategoryById UseCase", .tags(.categories, .useCase, .businessLogic))
@MainActor
struct GetCategoryByIdUseCaseTests {

    @Test("Returns category when found")
    func returnsCategoryWhenFound() async throws {
        // Arrange
        let targetCategory = CategoryTestHelper.predefined(id: "health")
        let categories = [targetCategory, CategoryTestHelper.predefined(id: "work", name: "Work")]
        let repo = TestCategoryRepository(categories: categories)
        let useCase = GetCategoryById(repo: repo)

        // Act
        let result = try await useCase.execute(id: "health")

        // Assert
        #expect(result != nil, "Should find category")
        #expect(result?.id == "health", "Should return correct category")
    }

    @Test("Returns nil when category not found")
    func returnsNilWhenNotFound() async throws {
        // Arrange
        let repo = TestCategoryRepository(categories: [])
        let useCase = GetCategoryById(repo: repo)

        // Act
        let result = try await useCase.execute(id: "nonexistent")

        // Assert
        #expect(result == nil, "Should return nil for nonexistent category")
    }
}

// MARK: - GetActiveCategories Tests

@Suite("GetActiveCategories UseCase", .tags(.categories, .useCase, .businessLogic))
@MainActor
struct GetActiveCategoriesUseCaseTests {

    @Test("Returns only active categories")
    func returnsOnlyActiveCategories() async throws {
        // Arrange
        let categories = [
            CategoryTestHelper.predefined(id: "health", isActive: true),
            CategoryTestHelper.predefined(id: "work", name: "Work", isActive: false),
            CategoryTestHelper.custom(isActive: true)
        ]
        let repo = TestCategoryRepository(categories: categories)
        let useCase = GetActiveCategories(repo: repo)

        // Act
        let result = try await useCase.execute()

        // Assert
        #expect(result.count == 2, "Should return only active categories")
        #expect(result.allSatisfy { $0.isActive }, "All returned categories should be active")
    }

    @Test("Returns empty array when no active categories")
    func returnsEmptyArrayWhenNoActiveCategories() async throws {
        // Arrange
        let categories = [
            CategoryTestHelper.predefined(id: "health", isActive: false)
        ]
        let repo = TestCategoryRepository(categories: categories)
        let useCase = GetActiveCategories(repo: repo)

        // Act
        let result = try await useCase.execute()

        // Assert
        #expect(result.isEmpty, "Should return empty array when no active categories")
    }
}

// MARK: - GetPredefinedCategories Tests

@Suite("GetPredefinedCategories UseCase", .tags(.categories, .useCase, .businessLogic))
@MainActor
struct GetPredefinedCategoriesUseCaseTests {

    @Test("Returns only predefined categories")
    func returnsOnlyPredefinedCategories() async throws {
        // Arrange
        let categories = [
            CategoryTestHelper.predefined(id: "health"),
            CategoryTestHelper.predefined(id: "work", name: "Work"),
            CategoryTestHelper.custom()
        ]
        let repo = TestCategoryRepository(categories: categories)
        let useCase = GetPredefinedCategories(repo: repo)

        // Act
        let result = try await useCase.execute()

        // Assert
        #expect(result.count == 2, "Should return only predefined categories")
        #expect(result.allSatisfy { $0.isPredefined }, "All returned categories should be predefined")
    }

    @Test("Returns empty array when no predefined categories")
    func returnsEmptyArrayWhenNoPredefined() async throws {
        // Arrange
        let categories = [
            CategoryTestHelper.custom()
        ]
        let repo = TestCategoryRepository(categories: categories)
        let useCase = GetPredefinedCategories(repo: repo)

        // Act
        let result = try await useCase.execute()

        // Assert
        #expect(result.isEmpty, "Should return empty array when no predefined categories")
    }
}

// MARK: - GetCustomCategories Tests

@Suite("GetCustomCategories UseCase", .tags(.categories, .useCase, .businessLogic))
@MainActor
struct GetCustomCategoriesUseCaseTests {

    @Test("Returns only custom categories")
    func returnsOnlyCustomCategories() async throws {
        // Arrange
        let categories = [
            CategoryTestHelper.predefined(id: "health"),
            CategoryTestHelper.custom(id: "custom-1"),
            CategoryTestHelper.custom(id: "custom-2", name: "Another Custom")
        ]
        let repo = TestCategoryRepository(categories: categories)
        let useCase = GetCustomCategories(repo: repo)

        // Act
        let result = try await useCase.execute()

        // Assert
        #expect(result.count == 2, "Should return only custom categories")
        #expect(result.allSatisfy { !$0.isPredefined }, "All returned categories should be custom")
    }

    @Test("Returns empty array when no custom categories")
    func returnsEmptyArrayWhenNoCustom() async throws {
        // Arrange
        let categories = [
            CategoryTestHelper.predefined(id: "health")
        ]
        let repo = TestCategoryRepository(categories: categories)
        let useCase = GetCustomCategories(repo: repo)

        // Act
        let result = try await useCase.execute()

        // Assert
        #expect(result.isEmpty, "Should return empty array when no custom categories")
    }
}

// MARK: - CreateCustomCategory Tests

@Suite("CreateCustomCategory UseCase", .tags(.categories, .useCase, .businessLogic))
@MainActor
struct CreateCustomCategoryUseCaseTests {

    @Test("Successfully creates custom category")
    func successfullyCreatesCustomCategory() async throws {
        // Arrange
        let repo = TestCategoryRepository(categories: [])
        let useCase = CreateCustomCategory(repo: repo)
        let newCategory = CategoryTestHelper.custom()

        // Act
        try await useCase.execute(newCategory)

        // Assert
        #expect(repo.createdCategories.count == 1, "Category should be created")
        #expect(repo.createdCategories.first?.id == newCategory.id, "Correct category should be created")
    }

    @Test("Throws error when category with same name exists")
    func throwsErrorWhenNameExists() async throws {
        // Arrange
        let existingCategory = CategoryTestHelper.custom(id: "existing", name: "My Category")
        let repo = TestCategoryRepository(categories: [existingCategory])
        let useCase = CreateCustomCategory(repo: repo)
        let newCategory = CategoryTestHelper.custom(id: "new", name: "My Category")

        // Act & Assert
        do {
            try await useCase.execute(newCategory)
            Issue.record("Should throw categoryAlreadyExists error")
        } catch let error as CategoryError {
            #expect(error == .categoryAlreadyExists, "Should throw categoryAlreadyExists")
        }
    }

    @Test("Throws error when category with same ID exists")
    func throwsErrorWhenIdExists() async throws {
        // Arrange
        let existingCategory = CategoryTestHelper.custom(id: "same-id", name: "Existing Name")
        let repo = TestCategoryRepository(categories: [existingCategory])
        let useCase = CreateCustomCategory(repo: repo)
        let newCategory = CategoryTestHelper.custom(id: "same-id", name: "Different Name")

        // Act & Assert
        do {
            try await useCase.execute(newCategory)
            Issue.record("Should throw categoryAlreadyExists error")
        } catch let error as CategoryError {
            #expect(error == .categoryAlreadyExists, "Should throw categoryAlreadyExists")
        }
    }
}

// MARK: - UpdateCategory Tests

@Suite("UpdateCategory UseCase", .tags(.categories, .useCase, .businessLogic))
@MainActor
struct UpdateCategoryUseCaseTests {

    @Test("Successfully updates category")
    func successfullyUpdatesCategory() async throws {
        // Arrange
        let originalCategory = CategoryTestHelper.custom(id: "custom-1", name: "Original Name")
        let repo = TestCategoryRepository(categories: [originalCategory])
        let useCase = UpdateCategory(repo: repo)
        let updatedCategory = CategoryTestHelper.custom(id: "custom-1", name: "Updated Name")

        // Act
        try await useCase.execute(updatedCategory)

        // Assert
        #expect(repo.updatedCategories.count == 1, "Category should be updated")
        #expect(repo.updatedCategories.first?.name == "Updated Name", "Name should be updated")
    }
}

// MARK: - DeleteCategory Tests

@Suite("DeleteCategory UseCase", .tags(.categories, .useCase, .businessLogic))
@MainActor
struct DeleteCategoryUseCaseTests {

    @Test("Successfully deletes category")
    func successfullyDeletesCategory() async throws {
        // Arrange
        let category = CategoryTestHelper.custom(id: "to-delete")
        let repo = TestCategoryRepository(categories: [category])
        let useCase = DeleteCategory(repo: repo)

        // Act
        try await useCase.execute(id: "to-delete")

        // Assert
        #expect(repo.deletedCategoryIds.contains("to-delete"), "Category should be deleted")
        #expect(repo.categories.isEmpty, "Category should be removed from repository")
    }

    @Test("Delete does not throw for nonexistent category")
    func deleteDoesNotThrowForNonexistent() async throws {
        // Arrange
        let repo = TestCategoryRepository(categories: [])
        let useCase = DeleteCategory(repo: repo)

        // Act & Assert - should not throw
        try await useCase.execute(id: "nonexistent")
    }
}

// MARK: - ValidateCategoryName Tests

@Suite("ValidateCategoryName UseCase", .tags(.categories, .useCase, .businessLogic))
@MainActor
struct ValidateCategoryNameUseCaseTests {

    @Test("Returns true for unique name")
    func returnsTrueForUniqueName() async throws {
        // Arrange
        let repo = TestCategoryRepository(categories: [
            CategoryTestHelper.custom(name: "Existing Category")
        ])
        let useCase = ValidateCategoryName(repo: repo)

        // Act
        let isValid = try await useCase.execute(name: "New Category")

        // Assert
        #expect(isValid == true, "Should return true for unique name")
    }

    @Test("Returns false for duplicate name")
    func returnsFalseForDuplicateName() async throws {
        // Arrange
        let repo = TestCategoryRepository(categories: [
            CategoryTestHelper.custom(name: "Existing Category")
        ])
        let useCase = ValidateCategoryName(repo: repo)

        // Act
        let isValid = try await useCase.execute(name: "Existing Category")

        // Assert
        #expect(isValid == false, "Should return false for duplicate name")
    }

    @Test("Performs case-insensitive comparison")
    func performsCaseInsensitiveComparison() async throws {
        // Arrange
        let repo = TestCategoryRepository(categories: [
            CategoryTestHelper.custom(name: "My Category")
        ])
        let useCase = ValidateCategoryName(repo: repo)

        // Act
        let isValid = try await useCase.execute(name: "MY CATEGORY")

        // Assert
        #expect(isValid == false, "Should detect duplicate regardless of case")
    }

    @Test("Returns false for empty name")
    func returnsFalseForEmptyName() async throws {
        // Arrange
        let repo = TestCategoryRepository(categories: [])
        let useCase = ValidateCategoryName(repo: repo)

        // Act
        let isValid = try await useCase.execute(name: "")

        // Assert
        #expect(isValid == false, "Should return false for empty name")
    }

    @Test("Returns false for whitespace-only name")
    func returnsFalseForWhitespaceOnlyName() async throws {
        // Arrange
        let repo = TestCategoryRepository(categories: [])
        let useCase = ValidateCategoryName(repo: repo)

        // Act
        let isValid = try await useCase.execute(name: "   ")

        // Assert
        #expect(isValid == false, "Should return false for whitespace-only name")
    }

    @Test("Trims whitespace before validation")
    func trimsWhitespaceBeforeValidation() async throws {
        // Arrange
        let repo = TestCategoryRepository(categories: [
            CategoryTestHelper.custom(name: "Existing")
        ])
        let useCase = ValidateCategoryName(repo: repo)

        // Act - name with surrounding whitespace that matches existing after trim
        let isValid = try await useCase.execute(name: "  Existing  ")

        // Assert
        #expect(isValid == false, "Should detect duplicate after trimming whitespace")
    }
}

// MARK: - LoadHabitsData Tests

@Suite("LoadHabitsData UseCase", .tags(.categories, .habits, .useCase, .businessLogic))
@MainActor
struct LoadHabitsDataUseCaseTests {

    @Test("Returns habits and categories together")
    func returnsHabitsAndCategoriesTogether() async throws {
        // Arrange
        let habits = [
            HabitBuilder.binary(name: "Habit 1", displayOrder: 0),
            HabitBuilder.binary(name: "Habit 2", displayOrder: 1)
        ]
        let categories = [
            CategoryTestHelper.predefined(id: "health"),
            CategoryTestHelper.custom()
        ]
        let habitRepo = MockHabitRepository(habits: habits)
        let categoryRepo = TestCategoryRepository(categories: categories)
        let useCase = LoadHabitsData(habitRepo: habitRepo, categoryRepo: categoryRepo)

        // Act
        let result = try await useCase.execute()

        // Assert
        #expect(result.habits.count == 2, "Should return all habits")
        #expect(result.categories.count == 2, "Should return active categories")
    }

    @Test("Returns habits sorted by display order")
    func returnsHabitsSortedByDisplayOrder() async throws {
        // Arrange - habits in wrong order
        let habits = [
            HabitBuilder.binary(name: "Last", displayOrder: 2),
            HabitBuilder.binary(name: "First", displayOrder: 0),
            HabitBuilder.binary(name: "Middle", displayOrder: 1)
        ]
        let habitRepo = MockHabitRepository(habits: habits)
        let categoryRepo = TestCategoryRepository(categories: [])
        let useCase = LoadHabitsData(habitRepo: habitRepo, categoryRepo: categoryRepo)

        // Act
        let result = try await useCase.execute()

        // Assert
        #expect(result.habits[0].name == "First", "First habit should have displayOrder 0")
        #expect(result.habits[1].name == "Middle", "Second habit should have displayOrder 1")
        #expect(result.habits[2].name == "Last", "Third habit should have displayOrder 2")
    }

    @Test("Returns only active categories")
    func returnsOnlyActiveCategories() async throws {
        // Arrange
        let categories = [
            CategoryTestHelper.predefined(id: "active", isActive: true),
            CategoryTestHelper.predefined(id: "inactive", name: "Inactive", isActive: false)
        ]
        let habitRepo = MockHabitRepository(habits: [])
        let categoryRepo = TestCategoryRepository(categories: categories)
        let useCase = LoadHabitsData(habitRepo: habitRepo, categoryRepo: categoryRepo)

        // Act
        let result = try await useCase.execute()

        // Assert
        #expect(result.categories.count == 1, "Should return only active categories")
        #expect(result.categories.first?.id == "active", "Should include only active category")
    }

    @Test("Returns empty data when no habits or categories")
    func returnsEmptyDataWhenNothing() async throws {
        // Arrange
        let habitRepo = MockHabitRepository(habits: [])
        let categoryRepo = TestCategoryRepository(categories: [])
        let useCase = LoadHabitsData(habitRepo: habitRepo, categoryRepo: categoryRepo)

        // Act
        let result = try await useCase.execute()

        // Assert
        #expect(result.habits.isEmpty, "Should return empty habits array")
        #expect(result.categories.isEmpty, "Should return empty categories array")
    }
}
