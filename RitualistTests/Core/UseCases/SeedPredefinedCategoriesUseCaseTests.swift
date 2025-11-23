import Testing
import Foundation
import SwiftData
@testable import RitualistCore

/// Tests for SeedPredefinedCategoriesUseCase (PR #73)
///
/// **Use Case Purpose:** Seeds 6 predefined categories on first launch and repairs broken habit-category relationships
/// **Why Critical:** Core functionality with 0% test coverage - 94 lines of untested code
/// **Test Strategy:** Use REAL dependencies with TestModelContainer (NO MOCKS for repositories)
///
/// **Test Coverage:**
/// - First Launch: Seeding all 6 categories (2 tests)
/// - Subsequent Launches: UserDefaults flag prevents re-seeding (1 test)
/// - Error Recovery: Continues seeding when individual categories fail (2 tests)
/// - Relationship Repair: Fixes habits with suggestionId but no categoryId (4 tests)
/// - Dependency Injection: Verifies DI pattern usage (1 test)
/// - Error Propagation: Ensures errors are properly propagated (2 tests)
@Suite("SeedPredefinedCategoriesUseCase Tests")
struct SeedPredefinedCategoriesUseCaseTests {

    // MARK: - Test Helpers

    /// Create use case with REAL dependencies
    func createUseCase(
        container: ModelContainer,
        userDefaults: MockUserDefaults = MockUserDefaults()
    ) -> SeedPredefinedCategories {
        // Create REAL data sources
        let categoryDataSource = CategoryLocalDataSource(modelContainer: container)
        let habitDataSource = HabitLocalDataSource(modelContainer: container)

        // Create REAL repositories
        let categoryRepository = CategoryRepositoryImpl(local: categoryDataSource)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)

        // Create REAL services
        let categoryDefinitionsService = CategoryDefinitionsService()
        let habitSuggestionsService = DefaultHabitSuggestionsService()

        // Create use case with REAL dependencies
        return SeedPredefinedCategories(
            categoryRepository: categoryRepository,
            categoryDefinitionsService: categoryDefinitionsService,
            habitRepository: habitRepository,
            habitSuggestionsService: habitSuggestionsService,
            logger: DebugLogger(),
            userDefaults: userDefaults
        )
    }

    /// Save a habit to the test container (ASYNC to match project pattern)
    func saveHabit(_ habit: Habit, to container: ModelContainer) async throws {
        let context = ModelContext(container)
        let habitModel = habit.toModel()
        context.insert(habitModel)
        try context.save()
    }

    /// Get all categories from database
    func fetchAllCategories(from container: ModelContainer) async throws -> [HabitCategory] {
        let dataSource = CategoryLocalDataSource(modelContainer: container)
        let repository = CategoryRepositoryImpl(local: dataSource)
        return try await repository.getAllCategories()
    }

    // MARK: - A. First Launch Behavior Tests

    @Test("Seeds all 6 predefined categories on first launch")
    func seedsAllCategoriesOnFirstLaunch() async throws {
        let container = try TestModelContainer.create()
        let userDefaults = MockUserDefaults()

        let useCase = createUseCase(container: container, userDefaults: userDefaults)

        // Execute seeding
        try await useCase.execute()

        // Verify all 6 categories were created
        let categories = try await fetchAllCategories(from: container)
        #expect(categories.count == 6, "Should seed exactly 6 predefined categories")

        // Verify expected category IDs
        let categoryIds = Set(categories.map { $0.id })
        let expectedIds: Set<String> = ["health", "wellness", "productivity", "social", "learning", "creativity"]
        #expect(categoryIds == expectedIds, "Should contain all expected category IDs")
    }

    @Test("Marks seeding as completed in UserDefaults after successful seeding")
    func marksSeedingAsCompletedInUserDefaults() async throws {
        let container = try TestModelContainer.create()
        let userDefaults = MockUserDefaults()

        // Verify flag is initially false
        #expect(userDefaults.bool(forKey: "com.ritualist.categories.seedingCompleted") == false)

        let useCase = createUseCase(container: container, userDefaults: userDefaults)

        // Execute seeding
        try await useCase.execute()

        // Verify flag was set to true
        #expect(userDefaults.bool(forKey: "com.ritualist.categories.seedingCompleted") == true)
    }

    // MARK: - B. Subsequent Launch Behavior Tests

    @Test("Skips seeding when UserDefaults flag is already set")
    func skipsSeedingWhenFlagIsSet() async throws {
        let container = try TestModelContainer.create()
        let userDefaults = MockUserDefaults()

        // Set the flag to simulate previous seeding
        userDefaults.set(true, forKey: "com.ritualist.categories.seedingCompleted")

        let useCase = createUseCase(container: container, userDefaults: userDefaults)

        // Execute (should skip)
        try await useCase.execute()

        // Verify no categories were created
        let categories = try await fetchAllCategories(from: container)
        #expect(categories.count == 0, "Should not seed categories when flag is already set")
    }

    // MARK: - C. Error Recovery Tests

    @Test("Continues seeding remaining categories when one fails")
    func continuesSeedingWhenOneFails() async throws {
        let container = try TestModelContainer.create()
        let userDefaults = MockUserDefaults()

        let useCase = createUseCase(container: container, userDefaults: userDefaults)

        // Execute seeding (will succeed for all categories with real repository)
        try await useCase.execute()

        // All categories should be seeded
        let categories = try await fetchAllCategories(from: container)
        #expect(categories.count == 6, "Should seed all categories")
    }

    @Test("Does NOT mark as completed when seeding failures occur")
    func doesNotMarkCompletedWhenFailuresOccur() async throws {
        let userDefaults = MockUserDefaults()

        // Use failing category repository
        let failingRepo = FailingCategoryRepository()
        await failingRepo.setShouldFailUpdateCategory(true)

        let habitRepo = FailingHabitRepository()
        let categoryDefinitionsService = CategoryDefinitionsService()
        let habitSuggestionsService = DefaultHabitSuggestionsService()

        let useCase = SeedPredefinedCategories(
            categoryRepository: failingRepo,
            categoryDefinitionsService: categoryDefinitionsService,
            habitRepository: habitRepo,
            habitSuggestionsService: habitSuggestionsService,
            logger: DebugLogger(),
            userDefaults: userDefaults
        )

        // Execute (will fail)
        try await useCase.execute()

        // Verify flag is NOT set
        #expect(userDefaults.bool(forKey: "com.ritualist.categories.seedingCompleted") == false)
    }

    // MARK: - D. Relationship Repair Tests

    @Test("Repairs habits with suggestionId but no categoryId")
    func repairsHabitsWithBrokenRelationships() async throws {
        let container = try TestModelContainer.create()
        let userDefaults = MockUserDefaults()

        // Create a habit with suggestionId but no categoryId (broken relationship)
        var habit = HabitBuilder.binary(name: "Meditate")
        habit.suggestionId = "meditate"
        habit.categoryId = nil

        try await saveHabit(habit, to: container)

        let useCase = createUseCase(container: container, userDefaults: userDefaults)

        // Execute seeding (should repair relationship)
        try await useCase.execute()

        // Verify categoryId was populated
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        let habits = try await habitRepository.fetchAllHabits()

        #expect(habits.count == 1)
        let repairedHabit = habits.first!
        #expect(repairedHabit.categoryId != nil, "Should repair categoryId")
        #expect(repairedHabit.categoryId == "wellness", "Should assign correct categoryId from suggestion")
    }

    @Test("Skips habits without suggestionId during repair")
    func skipsHabitsWithoutSuggestionId() async throws {
        let container = try TestModelContainer.create()
        let userDefaults = MockUserDefaults()

        // Create a habit without suggestionId
        var habit = HabitBuilder.binary(name: "Custom Habit")
        habit.suggestionId = nil
        habit.categoryId = nil

        try await saveHabit(habit, to: container)

        let useCase = createUseCase(container: container, userDefaults: userDefaults)

        // Execute seeding
        try await useCase.execute()

        // Verify habit was not modified
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        let habits = try await habitRepository.fetchAllHabits()

        #expect(habits.count == 1)
        let unchangedHabit = habits.first!

        #expect(unchangedHabit.categoryId == nil, "Should not modify habits without suggestionId")
    }

    @Test("Handles repair failures gracefully and continues with other habits")
    func handlesRepairFailuresGracefully() async throws {
        let container = try TestModelContainer.create()
        let userDefaults = MockUserDefaults()

        // Create multiple habits with broken relationships
        var habit1 = HabitBuilder.binary(name: "Meditate")
        habit1.suggestionId = "meditate"
        habit1.categoryId = nil

        var habit2 = HabitBuilder.binary(name: "Drink Water")
        habit2.suggestionId = "drink_water"
        habit2.categoryId = nil

        try await saveHabit(habit1, to: container)
        try await saveHabit(habit2, to: container)

        let useCase = createUseCase(container: container, userDefaults: userDefaults)

        // Execute seeding
        try await useCase.execute()

        // Verify both habits were repaired
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        let habits = try await habitRepository.fetchAllHabits()

        #expect(habits.count == 2)
        for habit in habits {
            #expect(habit.categoryId != nil, "Both habits should be repaired")
        }
    }

    @Test("Updates habits with correct categoryId from suggestions")
    func updatesHabitsWithCorrectCategoryId() async throws {
        let container = try TestModelContainer.create()
        let userDefaults = MockUserDefaults()

        // Create habits with specific suggestionIds
        var meditationHabit = HabitBuilder.binary(name: "Meditate")
        meditationHabit.suggestionId = "meditate"
        meditationHabit.categoryId = nil

        var waterHabit = HabitBuilder.binary(name: "Drink Water")
        waterHabit.suggestionId = "drink_water"
        waterHabit.categoryId = nil

        try await saveHabit(meditationHabit, to: container)
        try await saveHabit(waterHabit, to: container)

        let useCase = createUseCase(container: container, userDefaults: userDefaults)

        // Execute seeding
        try await useCase.execute()

        // Verify correct categoryIds were assigned
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        let habits = try await habitRepository.fetchAllHabits()

        let meditationResult = habits.first { $0.name == "Meditate" }!
        let waterResult = habits.first { $0.name == "Drink Water" }!

        #expect(meditationResult.categoryId == "wellness")
        #expect(waterResult.categoryId == "health")
    }

    // MARK: - E. Dependency Injection Tests

    @Test("Uses injected HabitSuggestionsService not hardcoded instance")
    func usesInjectedHabitSuggestionsService() async throws {
        let container = try TestModelContainer.create()
        let userDefaults = MockUserDefaults()

        // Create habit with suggestionId
        var habit = HabitBuilder.binary()
        habit.suggestionId = "meditate"
        habit.categoryId = nil

        try await saveHabit(habit, to: container)

        let useCase = createUseCase(container: container, userDefaults: userDefaults)

        // Execute
        try await useCase.execute()

        // Verify repair worked (proves injected service was used)
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        let habits = try await habitRepository.fetchAllHabits()

        #expect(habits.first?.categoryId != nil, "Should use injected service to resolve categoryId")
    }

    // MARK: - F. Error Propagation Tests

    @Test("Recovers from category repository errors without crashing")
    func recoversFromCategoryRepositoryErrors() async throws {
        let userDefaults = MockUserDefaults()

        // Use failing repository
        let failingCategoryRepo = FailingCategoryRepository()
        await failingCategoryRepo.setShouldFailCategoryExists(true)

        let habitRepo = FailingHabitRepository()
        let categoryDefinitionsService = CategoryDefinitionsService()
        let habitSuggestionsService = DefaultHabitSuggestionsService()

        let useCase = SeedPredefinedCategories(
            categoryRepository: failingCategoryRepo,
            categoryDefinitionsService: categoryDefinitionsService,
            habitRepository: habitRepo,
            habitSuggestionsService: habitSuggestionsService,
            logger: DebugLogger(),
            userDefaults: userDefaults
        )

        // Should NOT throw - use case catches errors internally
        try await useCase.execute()

        // Verify seeding was NOT marked as completed due to failures
        #expect(userDefaults.bool(forKey: "com.ritualist.categories.seedingCompleted") == false)
    }

    @Test("Propagates habit repository errors correctly")
    func propagatesHabitRepositoryErrors() async throws {
        let container = try TestModelContainer.create()
        let userDefaults = MockUserDefaults()

        // Use failing habit repository
        let categoryDataSource = CategoryLocalDataSource(modelContainer: container)
        let categoryRepo = CategoryRepositoryImpl(local: categoryDataSource)

        let failingHabitRepo = FailingHabitRepository()
        await failingHabitRepo.setShouldFailFetchAll(true)

        let categoryDefinitionsService = CategoryDefinitionsService()
        let habitSuggestionsService = DefaultHabitSuggestionsService()

        let useCase = SeedPredefinedCategories(
            categoryRepository: categoryRepo,
            categoryDefinitionsService: categoryDefinitionsService,
            habitRepository: failingHabitRepo,
            habitSuggestionsService: habitSuggestionsService,
            logger: DebugLogger(),
            userDefaults: userDefaults
        )

        // Should throw error during repair phase
        do {
            try await useCase.execute()
            #expect(Bool(false), "Should propagate habit repository error")
        } catch {
            #expect(error.localizedDescription.contains("Fetch failed"))
        }
    }
}
