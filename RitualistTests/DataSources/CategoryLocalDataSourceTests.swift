import Testing
import Foundation
import SwiftData
@testable import RitualistCore

/// Integration tests for CategoryLocalDataSource (PR #73)
///
/// **DataSource Purpose:** Provides access to habit categories after seeding refactor
/// **Why Critical:** Refactored from hybrid (in-memory + DB) to pure database approach
/// **Test Strategy:** Use REAL dependencies with TestModelContainer and verify seeding integration
///
/// **Changes Tested:**
/// - getAllCategories() now fetches from DB instead of merging in-memory + DB
/// - getCategory(by:) now queries DB instead of checking in-memory first
/// - getPredefinedCategories() now queries DB with isPredefined filter
/// - getCustomCategories() now queries DB with !isPredefined filter
/// - categoryExists() now queries DB instead of checking in-memory first
///
/// **Test Coverage:**
/// - Post-Seeding Queries: Verify categories are queryable after seeding (6 tests)
/// - Custom Categories: Verify custom category CRUD operations (3 tests)
/// - Category Existence: Verify existence checks work after seeding (2 tests)
@Suite("CategoryLocalDataSource Integration Tests")
@MainActor
struct CategoryLocalDataSourceTests {

    // MARK: - Test Helpers

    /// Seed categories into the database
    func seedCategories(to container: ModelContainer) async throws {
        let userDefaults = MockUserDefaults()

        let categoryDataSource = CategoryLocalDataSource(modelContainer: container)
        let habitDataSource = HabitLocalDataSource(modelContainer: container)

        let categoryRepository = CategoryRepositoryImpl(local: categoryDataSource)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)

        let categoryDefinitionsService = CategoryDefinitionsService()
        let habitSuggestionsService = DefaultHabitSuggestionsService()

        let useCase = SeedPredefinedCategories(
            categoryRepository: categoryRepository,
            categoryDefinitionsService: categoryDefinitionsService,
            habitRepository: habitRepository,
            habitSuggestionsService: habitSuggestionsService,
            logger: DebugLogger(),
            userDefaults: userDefaults
        )

        try await useCase.execute()
    }

    // MARK: - A. Post-Seeding Query Tests

    @Test("getAllCategories returns all 6 predefined categories after seeding")
    func getAllCategoriesReturnsAllPredefinedAfterSeeding() async throws {
        let container = try TestModelContainer.create()

        // Seed categories
        try await seedCategories(to: container)

        // Query via data source
        let dataSource = CategoryLocalDataSource(modelContainer: container)
        let categories = try await dataSource.getAllCategories()

        // Verify all 6 predefined categories are present
        #expect(categories.count == 6, "Should return all 6 predefined categories")

        let categoryIds = Set(categories.map { $0.id })
        let expectedIds: Set<String> = ["health", "wellness", "productivity", "social", "learning", "creativity"]
        #expect(categoryIds == expectedIds, "Should contain all expected category IDs")
    }

    @Test("getPredefinedCategories returns only predefined categories")
    func getPredefinedCategoriesReturnsOnlyPredefined() async throws {
        let container = try TestModelContainer.create()

        // Seed categories
        try await seedCategories(to: container)

        // Add a custom category
        let dataSource = CategoryLocalDataSource(modelContainer: container)
        let customCategory = CategoryBuilder.category(
            id: "custom-test",
            name: "custom-test",
            displayName: "Custom Test",
            emoji: "🧪",
            order: 100,
            isPredefined: false
        )
        try await dataSource.createCustomCategory(customCategory)

        // Query predefined categories
        let predefined = try await dataSource.getPredefinedCategories()

        // Verify only predefined categories returned
        #expect(predefined.count == 6, "Should return 6 predefined categories")
        #expect(predefined.allSatisfy { $0.isPredefined }, "All categories should be predefined")
        #expect(!predefined.contains { $0.id == "custom-test" }, "Should not include custom category")
    }

    @Test("getCustomCategories returns only custom categories")
    func getCustomCategoriesReturnsOnlyCustom() async throws {
        let container = try TestModelContainer.create()

        // Seed categories
        try await seedCategories(to: container)

        // Initially no custom categories
        let dataSource = CategoryLocalDataSource(modelContainer: container)
        let initialCustom = try await dataSource.getCustomCategories()
        #expect(initialCustom.count == 0, "Should have no custom categories initially")

        // Add custom category
        let customCategory = CategoryBuilder.category(
            id: "custom-test",
            name: "custom-test",
            displayName: "Custom Test",
            emoji: "🧪",
            order: 100,
            isPredefined: false
        )
        try await dataSource.createCustomCategory(customCategory)

        // Query custom categories
        let custom = try await dataSource.getCustomCategories()

        // Verify only custom category returned
        #expect(custom.count == 1, "Should return 1 custom category")
        #expect(custom.allSatisfy { !$0.isPredefined }, "All categories should be custom")
        #expect(custom.first?.id == "custom-test", "Should return the custom category")
    }

    @Test("getCategory(by:) returns correct category after seeding")
    func getCategoryByIdReturnsCorrectCategory() async throws {
        let container = try TestModelContainer.create()

        // Seed categories
        try await seedCategories(to: container)

        // Query specific category
        let dataSource = CategoryLocalDataSource(modelContainer: container)
        let healthCategory = try await dataSource.getCategory(by: "health")

        // Verify category returned
        #expect(healthCategory != nil, "Should find health category")
        #expect(healthCategory?.id == "health", "Should return health category")
        #expect(healthCategory?.isPredefined == true, "Health should be predefined")
    }

    @Test("getActiveCategories returns all active categories")
    func getActiveCategoriesReturnsAllActive() async throws {
        let container = try TestModelContainer.create()

        // Seed categories
        try await seedCategories(to: container)

        // Query active categories
        let dataSource = CategoryLocalDataSource(modelContainer: container)
        let active = try await dataSource.getActiveCategories()

        // Verify all 6 predefined categories are active
        #expect(active.count == 6, "Should return 6 active categories")
        #expect(active.allSatisfy { $0.isActive }, "All categories should be active")
    }

    @Test("Categories are sorted by order after seeding")
    func categoriesAreSortedByOrder() async throws {
        let container = try TestModelContainer.create()

        // Seed categories
        try await seedCategories(to: container)

        // Query categories
        let dataSource = CategoryLocalDataSource(modelContainer: container)
        let categories = try await dataSource.getAllCategories()

        // Verify sorted by order
        let orders = categories.map { $0.order }
        #expect(orders == orders.sorted(), "Categories should be sorted by order")
    }

    // MARK: - B. Custom Category CRUD Tests

    @Test("createCustomCategory adds new custom category to database")
    func createCustomCategoryAddsToDatabase() async throws {
        let container = try TestModelContainer.create()

        // Seed categories first
        try await seedCategories(to: container)

        // Create custom category
        let dataSource = CategoryLocalDataSource(modelContainer: container)
        let customCategory = CategoryBuilder.category(
            id: "workout",
            name: "workout",
            displayName: "Workout",
            emoji: "💪",
            order: 100,
            isPredefined: false
        )
        try await dataSource.createCustomCategory(customCategory)

        // Verify it's in the database
        let allCategories = try await dataSource.getAllCategories()
        #expect(allCategories.count == 7, "Should have 6 predefined + 1 custom")

        let workout = try await dataSource.getCategory(by: "workout")
        #expect(workout != nil, "Should find workout category")
        #expect(workout?.isPredefined == false, "Should be custom category")
    }

    @Test("updateCategory modifies existing category")
    func updateCategoryModifiesExisting() async throws {
        let container = try TestModelContainer.create()

        // Seed categories
        try await seedCategories(to: container)

        // Get health category
        let dataSource = CategoryLocalDataSource(modelContainer: container)
        let healthCategory = try await dataSource.getCategory(by: "health")!

        // Create updated category with modified display name
        let updatedCategory = HabitCategory(
            id: healthCategory.id,
            name: healthCategory.name,
            displayName: "Health & Fitness",
            emoji: healthCategory.emoji,
            order: healthCategory.order,
            isActive: healthCategory.isActive,
            isPredefined: healthCategory.isPredefined,
            personalityWeights: healthCategory.personalityWeights
        )
        try await dataSource.updateCategory(updatedCategory)

        // Verify update
        let updated = try await dataSource.getCategory(by: "health")
        #expect(updated?.displayName == "Health & Fitness", "Display name should be updated")
    }

    @Test("deleteCategory removes category from database")
    func deleteCategoryRemovesFromDatabase() async throws {
        let container = try TestModelContainer.create()

        // Seed categories
        try await seedCategories(to: container)

        // Create and delete custom category
        let dataSource = CategoryLocalDataSource(modelContainer: container)
        let customCategory = CategoryBuilder.category(
            id: "temp",
            name: "temp",
            displayName: "Temporary",
            emoji: "⏱️",
            order: 200,
            isPredefined: false
        )
        try await dataSource.createCustomCategory(customCategory)

        // Verify it exists
        let beforeDelete = try await dataSource.getCategory(by: "temp")
        #expect(beforeDelete != nil, "Category should exist before delete")

        // Delete it
        try await dataSource.deleteCategory(id: "temp")

        // Verify it's gone
        let afterDelete = try await dataSource.getCategory(by: "temp")
        #expect(afterDelete == nil, "Category should be deleted")
    }

    // MARK: - C. Category Existence Tests

    @Test("categoryExists(id:) returns true for seeded categories")
    func categoryExistsIdReturnsTrueForSeeded() async throws {
        let container = try TestModelContainer.create()

        // Seed categories
        try await seedCategories(to: container)

        // Check existence
        let dataSource = CategoryLocalDataSource(modelContainer: container)
        let healthExists = try await dataSource.categoryExists(id: "health")
        let wellnessExists = try await dataSource.categoryExists(id: "wellness")
        let fakeExists = try await dataSource.categoryExists(id: "fake-category")

        #expect(healthExists == true, "Health category should exist")
        #expect(wellnessExists == true, "Wellness category should exist")
        #expect(fakeExists == false, "Fake category should not exist")
    }

    @Test("categoryExists(name:) returns true for seeded categories")
    func categoryExistsNameReturnsTrueForSeeded() async throws {
        let container = try TestModelContainer.create()

        // Seed categories
        try await seedCategories(to: container)

        // Check existence by name
        let dataSource = CategoryLocalDataSource(modelContainer: container)
        let healthExists = try await dataSource.categoryExists(name: "health")
        let wellnessExists = try await dataSource.categoryExists(name: "wellness")
        let fakeExists = try await dataSource.categoryExists(name: "fake")

        #expect(healthExists == true, "Health category should exist by name")
        #expect(wellnessExists == true, "Wellness category should exist by name")
        #expect(fakeExists == false, "Fake category should not exist by name")
    }
}
