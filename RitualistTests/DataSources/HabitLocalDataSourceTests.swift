import Testing
import Foundation
import SwiftData
@testable import RitualistCore

/// Integration tests for HabitLocalDataSource
///
/// **DataSource Purpose:** Provides access to habits with cascade delete support for logs
/// **Why Critical:** Tests verify cascade delete works correctly with optional relationship arrays
/// **Test Strategy:** Use REAL dependencies with TestModelContainer
///
/// **Key Tests:**
/// - Cascade Delete: Verify deleting habit also deletes associated logs (optional relationship)
/// - CRUD Operations: Basic create, read, update, delete operations
/// - ID Validation: Verify pre-save validation catches invalid IDs
@Suite("HabitLocalDataSource Integration Tests")
@MainActor
struct HabitLocalDataSourceTests {

    // MARK: - A. Cascade Delete Tests (High Priority)

    /// **Issue #4 from CLOUDKIT_ERROR_INVESTIGATION.md**
    /// Optional relationship arrays with deleteRule: .cascade may not trigger properly.
    /// This test verifies cascade deletes work correctly.
    @Test("Deleting habit cascades to delete associated logs - optional relationship")
    func deletingHabitCascadesToDeleteLogs() async throws {
        // GIVEN: A habit with multiple logs
        let habit = HabitBuilder.binary(name: "Cascade Test Habit")
        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(2)),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(1)),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)
        ]

        let (container, context, habitModel, _) = try TestModelContainer.withHabitAndLogs(habit, logs: logs)

        // Verify initial state - habit and logs exist
        let initialHabits = try TestModelContainer.fetchAllHabits(from: context)
        let initialLogs = try TestModelContainer.fetchAllLogs(from: context)
        #expect(initialHabits.count == 1, "Should have 1 habit initially")
        #expect(initialLogs.count == 3, "Should have 3 logs initially")

        // WHEN: Delete the habit via data source
        let dataSource = HabitLocalDataSource(modelContainer: container)
        try await dataSource.delete(id: habit.id)

        // THEN: Both habit AND logs should be deleted (cascade)
        let remainingHabits = try TestModelContainer.fetchAllHabits(from: context)
        let remainingLogs = try TestModelContainer.fetchAllLogs(from: context)

        #expect(remainingHabits.isEmpty, "Habit should be deleted")
        #expect(remainingLogs.isEmpty, "Logs should be cascade deleted when habit is deleted")
    }

    @Test("Cascade delete works when logs relationship is nil")
    func cascadeDeleteWorksWithNilLogs() async throws {
        // GIVEN: A habit with no logs (logs relationship will be nil)
        let habit = HabitBuilder.binary(name: "No Logs Habit")
        let (container, context, _) = try TestModelContainer.withHabit(habit)

        // Verify habit exists without logs
        let initialHabits = try TestModelContainer.fetchAllHabits(from: context)
        let initialLogs = try TestModelContainer.fetchAllLogs(from: context)
        #expect(initialHabits.count == 1, "Should have 1 habit")
        #expect(initialLogs.isEmpty, "Should have no logs")

        // WHEN: Delete the habit
        let dataSource = HabitLocalDataSource(modelContainer: container)
        try await dataSource.delete(id: habit.id)

        // THEN: Habit should be deleted without error
        let remainingHabits = try TestModelContainer.fetchAllHabits(from: context)
        #expect(remainingHabits.isEmpty, "Habit should be deleted even with nil logs relationship")
    }

    @Test("Cascade delete removes only logs for deleted habit")
    func cascadeDeleteRemovesOnlyRelatedLogs() async throws {
        // GIVEN: Two habits, each with their own logs
        let habit1 = HabitBuilder.binary(name: "Habit 1")
        let habit2 = HabitBuilder.binary(name: "Habit 2")

        let container = try TestModelContainer.create()
        let context = ModelContext(container)

        // Insert both habits
        let habitModel1 = habit1.toModel()
        let habitModel2 = habit2.toModel()
        context.insert(habitModel1)
        context.insert(habitModel2)

        // Create logs for habit1
        let log1 = HabitLogBuilder.binary(habitId: habit1.id, date: TestDates.today).toModel()
        log1.habit = habitModel1
        context.insert(log1)

        // Create logs for habit2
        let log2 = HabitLogBuilder.binary(habitId: habit2.id, date: TestDates.today).toModel()
        log2.habit = habitModel2
        context.insert(log2)

        try context.save()

        // Verify initial state
        #expect(try TestModelContainer.fetchAllHabits(from: context).count == 2, "Should have 2 habits")
        #expect(try TestModelContainer.fetchAllLogs(from: context).count == 2, "Should have 2 logs")

        // WHEN: Delete only habit1
        let dataSource = HabitLocalDataSource(modelContainer: container)
        try await dataSource.delete(id: habit1.id)

        // THEN: Only habit1's logs should be deleted
        let remainingHabits = try TestModelContainer.fetchAllHabits(from: context)
        let remainingLogs = try TestModelContainer.fetchAllLogs(from: context)

        #expect(remainingHabits.count == 1, "Should have 1 habit remaining")
        #expect(remainingHabits.first?.id == habit2.id, "Remaining habit should be habit2")
        #expect(remainingLogs.count == 1, "Should have 1 log remaining")
        #expect(remainingLogs.first?.habitID == habit2.id, "Remaining log should belong to habit2")
    }

    // MARK: - B. CRUD Operation Tests

    @Test("fetchAll returns all habits sorted by displayOrder")
    func fetchAllReturnsHabitsSortedByDisplayOrder() async throws {
        let habits = [
            HabitBuilder.binary(name: "Third", displayOrder: 2),
            HabitBuilder.binary(name: "First", displayOrder: 0),
            HabitBuilder.binary(name: "Second", displayOrder: 1)
        ]

        let (container, _, _) = try TestModelContainer.withHabits(habits)
        let dataSource = HabitLocalDataSource(modelContainer: container)

        let fetchedHabits = try await dataSource.fetchAll()

        #expect(fetchedHabits.count == 3, "Should return all 3 habits")
        #expect(fetchedHabits[0].name == "First", "First habit should be displayOrder 0")
        #expect(fetchedHabits[1].name == "Second", "Second habit should be displayOrder 1")
        #expect(fetchedHabits[2].name == "Third", "Third habit should be displayOrder 2")
    }

    @Test("fetch(by:) returns correct habit")
    func fetchByIdReturnsCorrectHabit() async throws {
        let targetHabit = HabitBuilder.binary(name: "Target Habit")
        let otherHabit = HabitBuilder.binary(name: "Other Habit")

        let (container, _, _) = try TestModelContainer.withHabits([targetHabit, otherHabit])
        let dataSource = HabitLocalDataSource(modelContainer: container)

        let fetched = try await dataSource.fetch(by: targetHabit.id)

        #expect(fetched != nil, "Should find the habit")
        #expect(fetched?.id == targetHabit.id, "Should return correct habit")
        #expect(fetched?.name == "Target Habit", "Should have correct name")
    }

    @Test("fetch(by:) returns nil for non-existent habit")
    func fetchByIdReturnsNilForMissingHabit() async throws {
        let habit = HabitBuilder.binary(name: "Existing Habit")
        let (container, _, _) = try TestModelContainer.withHabit(habit)
        let dataSource = HabitLocalDataSource(modelContainer: container)

        let fetched = try await dataSource.fetch(by: UUID())  // Non-existent ID

        #expect(fetched == nil, "Should return nil for non-existent habit")
    }

    @Test("upsert creates new habit")
    func upsertCreatesNewHabit() async throws {
        let container = try TestModelContainer.create()
        let dataSource = HabitLocalDataSource(modelContainer: container)

        let newHabit = HabitBuilder.binary(name: "New Habit")
        try await dataSource.upsert(newHabit)

        let habits = try await dataSource.fetchAll()
        #expect(habits.count == 1, "Should have created 1 habit")
        #expect(habits.first?.name == "New Habit", "Should have correct name")
    }

    @Test("upsert updates existing habit")
    func upsertUpdatesExistingHabit() async throws {
        let originalHabit = HabitBuilder.binary(name: "Original Name")
        let (container, _, _) = try TestModelContainer.withHabit(originalHabit)
        let dataSource = HabitLocalDataSource(modelContainer: container)

        // Create updated version with same ID
        let updatedHabit = Habit(
            id: originalHabit.id,
            name: "Updated Name",
            colorHex: originalHabit.colorHex,
            emoji: originalHabit.emoji,
            kind: originalHabit.kind,
            unitLabel: originalHabit.unitLabel,
            dailyTarget: originalHabit.dailyTarget,
            schedule: originalHabit.schedule,
            reminders: originalHabit.reminders,
            startDate: originalHabit.startDate,
            endDate: originalHabit.endDate,
            isActive: originalHabit.isActive,
            displayOrder: originalHabit.displayOrder,
            categoryId: originalHabit.categoryId,
            suggestionId: originalHabit.suggestionId,
            isPinned: originalHabit.isPinned,
            notes: originalHabit.notes,
            lastCompletedDate: originalHabit.lastCompletedDate,
            archivedDate: originalHabit.archivedDate,
            locationConfiguration: originalHabit.locationConfiguration,
            priorityLevel: originalHabit.priorityLevel
        )

        try await dataSource.upsert(updatedHabit)

        let habits = try await dataSource.fetchAll()
        #expect(habits.count == 1, "Should still have 1 habit")
        #expect(habits.first?.name == "Updated Name", "Name should be updated")
    }

    // MARK: - C. ID Validation Tests

    @Test("delete verifies deletion succeeded")
    func deleteVerifiesDeletionSucceeded() async throws {
        let habit = HabitBuilder.binary(name: "To Delete")
        let (container, context, _) = try TestModelContainer.withHabit(habit)
        let dataSource = HabitLocalDataSource(modelContainer: container)

        // Verify habit exists
        #expect(try TestModelContainer.fetchAllHabits(from: context).count == 1)

        // Delete
        try await dataSource.delete(id: habit.id)

        // Verify deleted
        let remaining = try await dataSource.fetchAll()
        #expect(remaining.isEmpty, "Habit should be deleted")
    }
}
