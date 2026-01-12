//
//  HabitUseCasesTests.swift
//  RitualistTests
//
//  Tests for Habit Use Cases - business logic for habit management
//
//  Key Testing Focus:
//  - CreateHabit display order assignment
//  - GetAllHabits sorting by display order
//  - ValidateHabitUniqueness duplicate detection
//  - ToggleHabitActiveStatus state management
//  - ReorderHabits display order update
//  - GetHabitsByCategory filtering
//  - OrphanHabitsFromCategory category removal
//

import Testing
import Foundation
@testable import RitualistCore

// MARK: - CreateHabit Tests

@Suite("CreateHabit UseCase", .tags(.habits, .habitCreation, .businessLogic))
struct CreateHabitUseCaseTests {

    @Test("New habit gets display order as max + 1")
    func newHabit_getsDisplayOrderAsMaxPlusOne() async throws {
        // Existing habits with display orders 0, 1, 2
        let existingHabits = [
            HabitBuilder.binary(name: "Habit 1", displayOrder: 0),
            HabitBuilder.binary(name: "Habit 2", displayOrder: 1),
            HabitBuilder.binary(name: "Habit 3", displayOrder: 2)
        ]
        let repo = MockHabitRepository(habits: existingHabits)
        let useCase = CreateHabit(repo: repo)

        let newHabit = HabitBuilder.binary(name: "New Habit")
        let result = try await useCase.execute(newHabit)

        #expect(result.displayOrder == 3)
    }

    @Test("First habit gets display order 0")
    func firstHabit_getsDisplayOrderZero() async throws {
        let repo = MockHabitRepository(habits: [])
        let useCase = CreateHabit(repo: repo)

        let newHabit = HabitBuilder.binary(name: "First Habit")
        let result = try await useCase.execute(newHabit)

        #expect(result.displayOrder == 0)
    }

    @Test("New habit is persisted to repository")
    func newHabit_isPersistedToRepository() async throws {
        let repo = MockHabitRepository(habits: [])
        let useCase = CreateHabit(repo: repo)

        let newHabit = HabitBuilder.binary(name: "Persisted Habit")
        let result = try await useCase.execute(newHabit)

        #expect(repo.habits.count == 1)
        #expect(repo.habits.first?.id == result.id)
    }

    @Test("New habit preserves all properties except display order")
    func newHabit_preservesAllPropertiesExceptDisplayOrder() async throws {
        let repo = MockHabitRepository(habits: [])
        let useCase = CreateHabit(repo: repo)

        let habitId = UUID()
        let newHabit = HabitBuilder.binary(
            id: habitId,
            name: "Test Habit",
            emoji: "🎯",
            categoryId: "health"
        )
        let result = try await useCase.execute(newHabit)

        #expect(result.id == habitId)
        #expect(result.name == "Test Habit")
        #expect(result.emoji == "🎯")
        #expect(result.categoryId == "health")
    }

    @Test("Display order handles non-contiguous existing orders")
    func displayOrder_handlesNonContiguousExistingOrders() async throws {
        // Existing habits with gaps in display order
        let existingHabits = [
            HabitBuilder.binary(name: "Habit 1", displayOrder: 0),
            HabitBuilder.binary(name: "Habit 2", displayOrder: 5),
            HabitBuilder.binary(name: "Habit 3", displayOrder: 10)
        ]
        let repo = MockHabitRepository(habits: existingHabits)
        let useCase = CreateHabit(repo: repo)

        let newHabit = HabitBuilder.binary(name: "New Habit")
        let result = try await useCase.execute(newHabit)

        // Should be max (10) + 1 = 11
        #expect(result.displayOrder == 11)
    }
}

// MARK: - GetAllHabits Tests

@Suite("GetAllHabits UseCase", .tags(.habits, .businessLogic))
struct GetAllHabitsUseCaseTests {

    @Test("Returns habits sorted by display order ascending")
    func returnsHabitsSortedByDisplayOrderAscending() async throws {
        let habits = [
            HabitBuilder.binary(name: "Habit C", displayOrder: 2),
            HabitBuilder.binary(name: "Habit A", displayOrder: 0),
            HabitBuilder.binary(name: "Habit B", displayOrder: 1)
        ]
        let repo = MockHabitRepository(habits: habits)
        let useCase = GetAllHabits(repo: repo)

        let result = try await useCase.execute()

        #expect(result[0].name == "Habit A")
        #expect(result[1].name == "Habit B")
        #expect(result[2].name == "Habit C")
    }

    @Test("Returns empty array when no habits exist")
    func returnsEmptyArrayWhenNoHabitsExist() async throws {
        let repo = MockHabitRepository(habits: [])
        let useCase = GetAllHabits(repo: repo)

        let result = try await useCase.execute()

        #expect(result.isEmpty)
    }

    @Test("Returns single habit when one exists")
    func returnsSingleHabitWhenOneExists() async throws {
        let habit = HabitBuilder.binary(name: "Only Habit")
        let repo = MockHabitRepository(habits: [habit])
        let useCase = GetAllHabits(repo: repo)

        let result = try await useCase.execute()

        #expect(result.count == 1)
        #expect(result.first?.name == "Only Habit")
    }
}

// MARK: - GetActiveHabits Tests

@Suite("GetActiveHabits UseCase", .tags(.habits, .businessLogic))
struct GetActiveHabitsUseCaseTests {

    @Test("Returns only active habits")
    func returnsOnlyActiveHabits() async throws {
        let habits = [
            HabitBuilder.binary(name: "Active 1", isActive: true),
            HabitBuilder.binary(name: "Inactive", isActive: false),
            HabitBuilder.binary(name: "Active 2", isActive: true)
        ]
        let repo = MockHabitRepository(habits: habits)
        let useCase = GetActiveHabits(repo: repo)

        let result = try await useCase.execute()

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.isActive })
    }

    @Test("Returns active habits sorted by display order")
    func returnsActiveHabitsSortedByDisplayOrder() async throws {
        let habits = [
            HabitBuilder.binary(name: "Active C", isActive: true, displayOrder: 2),
            HabitBuilder.binary(name: "Active A", isActive: true, displayOrder: 0),
            HabitBuilder.binary(name: "Inactive", isActive: false, displayOrder: 1),
            HabitBuilder.binary(name: "Active B", isActive: true, displayOrder: 1)
        ]
        let repo = MockHabitRepository(habits: habits)
        let useCase = GetActiveHabits(repo: repo)

        let result = try await useCase.execute()

        #expect(result.count == 3)
        #expect(result[0].name == "Active A")
        #expect(result[1].name == "Active B")
        #expect(result[2].name == "Active C")
    }

    @Test("Returns empty array when no active habits")
    func returnsEmptyArrayWhenNoActiveHabits() async throws {
        let habits = [
            HabitBuilder.binary(name: "Inactive 1", isActive: false),
            HabitBuilder.binary(name: "Inactive 2", isActive: false)
        ]
        let repo = MockHabitRepository(habits: habits)
        let useCase = GetActiveHabits(repo: repo)

        let result = try await useCase.execute()

        #expect(result.isEmpty)
    }
}

// MARK: - ValidateHabitUniqueness Tests

@Suite("ValidateHabitUniqueness UseCase", .tags(.habits, .useCase, .businessLogic))
struct ValidateHabitUniquenessUseCaseTests {

    @Test("Returns true for unique name in same category")
    func returnsTrueForUniqueNameInSameCategory() async throws {
        let habits = [
            HabitBuilder.binary(name: "Existing Habit", categoryId: "health")
        ]
        let repo = MockHabitRepository(habits: habits)
        let useCase = ValidateHabitUniqueness(repo: repo)

        let result = try await useCase.execute(name: "New Habit", categoryId: "health", excludeId: nil)

        #expect(result == true)
    }

    @Test("Returns false for duplicate name in same category")
    func returnsFalseForDuplicateNameInSameCategory() async throws {
        let habits = [
            HabitBuilder.binary(name: "Exercise", categoryId: "health")
        ]
        let repo = MockHabitRepository(habits: habits)
        let useCase = ValidateHabitUniqueness(repo: repo)

        let result = try await useCase.execute(name: "Exercise", categoryId: "health", excludeId: nil)

        #expect(result == false)
    }

    @Test("Returns true for same name in different category")
    func returnsTrueForSameNameInDifferentCategory() async throws {
        let habits = [
            HabitBuilder.binary(name: "Morning Routine", categoryId: "health")
        ]
        let repo = MockHabitRepository(habits: habits)
        let useCase = ValidateHabitUniqueness(repo: repo)

        // Same name but different category
        let result = try await useCase.execute(name: "Morning Routine", categoryId: "productivity", excludeId: nil)

        #expect(result == true)
    }

    @Test("Case insensitive comparison detects duplicates")
    func caseInsensitiveComparisonDetectsDuplicates() async throws {
        let habits = [
            HabitBuilder.binary(name: "Exercise", categoryId: "health")
        ]
        let repo = MockHabitRepository(habits: habits)
        let useCase = ValidateHabitUniqueness(repo: repo)

        let result = try await useCase.execute(name: "EXERCISE", categoryId: "health", excludeId: nil)

        #expect(result == false)
    }

    @Test("Trims whitespace before comparison")
    func trimsWhitespaceBeforeComparison() async throws {
        let habits = [
            HabitBuilder.binary(name: "Exercise", categoryId: "health")
        ]
        let repo = MockHabitRepository(habits: habits)
        let useCase = ValidateHabitUniqueness(repo: repo)

        let result = try await useCase.execute(name: "  Exercise  ", categoryId: "health", excludeId: nil)

        #expect(result == false)
    }

    @Test("Excludes specified habit ID from uniqueness check")
    func excludesSpecifiedHabitIdFromUniquenessCheck() async throws {
        let habitId = UUID()
        let habits = [
            HabitBuilder.binary(id: habitId, name: "Exercise", categoryId: "health")
        ]
        let repo = MockHabitRepository(habits: habits)
        let useCase = ValidateHabitUniqueness(repo: repo)

        // When editing the same habit, should return true (unique)
        let result = try await useCase.execute(name: "Exercise", categoryId: "health", excludeId: habitId)

        #expect(result == true)
    }

    @Test("Returns true for nil categories when existing has category")
    func returnsTrueForNilCategoriesWhenExistingHasCategory() async throws {
        let habits = [
            HabitBuilder.binary(name: "Exercise", categoryId: "health")
        ]
        let repo = MockHabitRepository(habits: habits)
        let useCase = ValidateHabitUniqueness(repo: repo)

        // Same name but new habit has no category
        let result = try await useCase.execute(name: "Exercise", categoryId: nil, excludeId: nil)

        #expect(result == true)
    }
}

// MARK: - ReorderHabits Tests

@Suite("ReorderHabits UseCase", .tags(.habits, .businessLogic))
struct ReorderHabitsUseCaseTests {

    @Test("Updates display order for all habits")
    func updatesDisplayOrderForAllHabits() async throws {
        let habit1 = HabitBuilder.binary(name: "Habit 1", displayOrder: 2)
        let habit2 = HabitBuilder.binary(name: "Habit 2", displayOrder: 0)
        let habit3 = HabitBuilder.binary(name: "Habit 3", displayOrder: 1)
        let repo = MockHabitRepository(habits: [habit1, habit2, habit3])
        let useCase = ReorderHabits(repo: repo)

        // Reorder: habit2 first, then habit3, then habit1
        try await useCase.execute([habit2, habit3, habit1])

        // Check that display orders were updated
        let updatedHabit1 = repo.habits.first { $0.id == habit1.id }
        let updatedHabit2 = repo.habits.first { $0.id == habit2.id }
        let updatedHabit3 = repo.habits.first { $0.id == habit3.id }

        #expect(updatedHabit2?.displayOrder == 0)
        #expect(updatedHabit3?.displayOrder == 1)
        #expect(updatedHabit1?.displayOrder == 2)
    }

    @Test("Preserves habit properties other than display order")
    func preservesHabitPropertiesOtherThanDisplayOrder() async throws {
        let habitId = UUID()
        let habit = HabitBuilder.binary(
            id: habitId,
            name: "Test Habit",
            emoji: "🎯",
            categoryId: "health",
            displayOrder: 5
        )
        let repo = MockHabitRepository(habits: [habit])
        let useCase = ReorderHabits(repo: repo)

        try await useCase.execute([habit])

        let updatedHabit = repo.habits.first { $0.id == habitId }
        #expect(updatedHabit?.name == "Test Habit")
        #expect(updatedHabit?.emoji == "🎯")
        #expect(updatedHabit?.categoryId == "health")
        #expect(updatedHabit?.displayOrder == 0)
    }
}

// MARK: - GetHabitsByCategory Tests

@Suite("GetHabitsByCategory UseCase", .tags(.habits, .categories, .businessLogic))
struct GetHabitsByCategoryUseCaseTests {

    @Test("Returns habits for specified category")
    func returnsHabitsForSpecifiedCategory() async throws {
        let habits = [
            HabitBuilder.binary(name: "Health Habit 1", categoryId: "health"),
            HabitBuilder.binary(name: "Productivity Habit", categoryId: "productivity"),
            HabitBuilder.binary(name: "Health Habit 2", categoryId: "health")
        ]
        let repo = MockHabitRepository(habits: habits)
        let useCase = GetHabitsByCategory(repo: repo)

        let result = try await useCase.execute(categoryId: "health")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.categoryId == "health" })
    }

    @Test("Returns empty array when no habits in category")
    func returnsEmptyArrayWhenNoHabitsInCategory() async throws {
        let habits = [
            HabitBuilder.binary(name: "Health Habit", categoryId: "health")
        ]
        let repo = MockHabitRepository(habits: habits)
        let useCase = GetHabitsByCategory(repo: repo)

        let result = try await useCase.execute(categoryId: "nonexistent")

        #expect(result.isEmpty)
    }
}

// MARK: - OrphanHabitsFromCategory Tests

@Suite("OrphanHabitsFromCategory UseCase", .tags(.habits, .categories, .businessLogic))
struct OrphanHabitsFromCategoryUseCaseTests {

    @Test("Sets categoryId to nil for habits in deleted category")
    func setsCategoryIdToNilForHabitsInDeletedCategory() async throws {
        let habit1 = HabitBuilder.binary(name: "Health Habit 1", categoryId: "health")
        let habit2 = HabitBuilder.binary(name: "Health Habit 2", categoryId: "health")
        let habit3 = HabitBuilder.binary(name: "Productivity Habit", categoryId: "productivity")
        let repo = MockHabitRepository(habits: [habit1, habit2, habit3])
        let useCase = OrphanHabitsFromCategory(repo: repo)

        try await useCase.execute(categoryId: "health")

        let orphaned1 = repo.habits.first { $0.id == habit1.id }
        let orphaned2 = repo.habits.first { $0.id == habit2.id }
        let unchanged = repo.habits.first { $0.id == habit3.id }

        #expect(orphaned1?.categoryId == nil)
        #expect(orphaned2?.categoryId == nil)
        #expect(unchanged?.categoryId == "productivity")
    }

    @Test("Does nothing when no habits in category")
    func doesNothingWhenNoHabitsInCategory() async throws {
        let habit = HabitBuilder.binary(name: "Productivity Habit", categoryId: "productivity")
        let repo = MockHabitRepository(habits: [habit])
        let useCase = OrphanHabitsFromCategory(repo: repo)

        try await useCase.execute(categoryId: "nonexistent")

        #expect(repo.habits.first?.categoryId == "productivity")
    }

    @Test("Preserves other habit properties when orphaning")
    func preservesOtherHabitPropertiesWhenOrphaning() async throws {
        let habitId = UUID()
        let habit = HabitBuilder.binary(
            id: habitId,
            name: "Test Habit",
            emoji: "🎯",
            categoryId: "health"
        )
        let repo = MockHabitRepository(habits: [habit])
        let useCase = OrphanHabitsFromCategory(repo: repo)

        try await useCase.execute(categoryId: "health")

        let orphaned = repo.habits.first { $0.id == habitId }
        #expect(orphaned?.name == "Test Habit")
        #expect(orphaned?.emoji == "🎯")
        #expect(orphaned?.categoryId == nil)
    }
}

// MARK: - ToggleHabitActiveStatus Tests

@Suite("ToggleHabitActiveStatus UseCase", .tags(.habits, .businessLogic))
struct ToggleHabitActiveStatusUseCaseTests {

    @Test("Toggles active habit to inactive")
    func togglesActiveHabitToInactive() async throws {
        let habitId = UUID()
        let habit = HabitBuilder.binary(id: habitId, name: "Active Habit", isActive: true)
        let repo = MockHabitRepository(habits: [habit])
        let useCase = ToggleHabitActiveStatus(repo: repo)

        let result = try await useCase.execute(id: habitId)

        #expect(result.isActive == false)
    }

    @Test("Toggles inactive habit to active")
    func togglesInactiveHabitToActive() async throws {
        let habitId = UUID()
        let habit = HabitBuilder.binary(id: habitId, name: "Inactive Habit", isActive: false)
        let repo = MockHabitRepository(habits: [habit])
        let useCase = ToggleHabitActiveStatus(repo: repo)

        let result = try await useCase.execute(id: habitId)

        #expect(result.isActive == true)
    }

    @Test("Throws error when habit not found")
    func throwsErrorWhenHabitNotFound() async throws {
        let repo = MockHabitRepository(habits: [])
        let useCase = ToggleHabitActiveStatus(repo: repo)

        await #expect(throws: HabitError.self) {
            try await useCase.execute(id: UUID())
        }
    }

    @Test("Preserves other habit properties when toggling")
    func preservesOtherHabitPropertiesWhenToggling() async throws {
        let habitId = UUID()
        let habit = HabitBuilder.binary(
            id: habitId,
            name: "Test Habit",
            emoji: "🎯",
            categoryId: "health",
            isActive: true
        )
        let repo = MockHabitRepository(habits: [habit])
        let useCase = ToggleHabitActiveStatus(repo: repo)

        let result = try await useCase.execute(id: habitId)

        #expect(result.name == "Test Habit")
        #expect(result.emoji == "🎯")
        #expect(result.categoryId == "health")
        #expect(result.isActive == false)
    }

    @Test("Updates habit in repository")
    func updatesHabitInRepository() async throws {
        let habitId = UUID()
        let habit = HabitBuilder.binary(id: habitId, name: "Test Habit", isActive: true)
        let repo = MockHabitRepository(habits: [habit])
        let useCase = ToggleHabitActiveStatus(repo: repo)

        _ = try await useCase.execute(id: habitId)

        let updatedHabit = repo.habits.first { $0.id == habitId }
        #expect(updatedHabit?.isActive == false)
    }
}

// MARK: - GetHabitCount Tests

@Suite("GetHabitCount UseCase", .tags(.habits, .businessLogic))
struct GetHabitCountUseCaseTests {

    @Test("Returns correct count of habits")
    func returnsCorrectCountOfHabits() async {
        let habits = [
            HabitBuilder.binary(name: "Habit 1"),
            HabitBuilder.binary(name: "Habit 2"),
            HabitBuilder.binary(name: "Habit 3")
        ]
        let repo = MockHabitRepository(habits: habits)
        let logger = DebugLogger(subsystem: "test", category: "usecase")
        let useCase = GetHabitCount(repo: repo, logger: logger)

        let result = await useCase.execute()

        #expect(result == 3)
    }

    @Test("Returns zero when no habits exist")
    func returnsZeroWhenNoHabitsExist() async {
        let repo = MockHabitRepository(habits: [])
        let logger = DebugLogger(subsystem: "test", category: "usecase")
        let useCase = GetHabitCount(repo: repo, logger: logger)

        let result = await useCase.execute()

        #expect(result == 0)
    }

    @Test("Counts both active and inactive habits")
    func countsBothActiveAndInactiveHabits() async {
        let habits = [
            HabitBuilder.binary(name: "Active", isActive: true),
            HabitBuilder.binary(name: "Inactive", isActive: false)
        ]
        let repo = MockHabitRepository(habits: habits)
        let logger = DebugLogger(subsystem: "test", category: "usecase")
        let useCase = GetHabitCount(repo: repo, logger: logger)

        let result = await useCase.execute()

        #expect(result == 2)
    }
}
