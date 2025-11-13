//
//  HabitMaintenanceServiceTests.swift
//  RitualistTests
//
//  Created by Phase 2 Consolidation on 13.11.2025.
//

import Foundation
import Testing
import SwiftData
@testable import RitualistCore

@Suite("HabitMaintenanceService Tests")
struct HabitMaintenanceServiceTests {

    // MARK: - Test Infrastructure

    /// Create an in-memory ModelContainer for testing
    /// This provides isolated, fast tests without persistent storage
    func createTestContainer() throws -> ModelContainer {
        let schema = Schema([
            ActiveHabitModel.self,
            ActiveHabitCategoryModel.self,
            ActiveHabitLogModel.self
        ])

        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    // MARK: - SwiftData Relationship Behavior Tests

    @Test("SwiftData automatically nulls category when category is deleted")
    func swiftDataNullsCategoryOnDelete() async throws {
        let container = try createTestContainer()
        let service = HabitMaintenanceService(modelContainer: container)

        let context = ModelContext(container)

        // Create a category
        let category = ActiveHabitCategoryModel(
            id: "test-category",
            name: "test",
            displayName: "Test",
            emoji: "🧪",
            order: 0,
            isActive: true,
            isPredefined: false
        )
        context.insert(category)

        // Create habit that references the category
        let habit = ActiveHabitModel(
            id: UUID(),
            name: "Test Habit",
            colorHex: "#2DA9E3",
            emoji: "🎯",
            kindRaw: 0,
            unitLabel: nil,
            dailyTarget: nil,
            scheduleData: try JSONEncoder().encode(HabitSchedule.daily),
            remindersData: try JSONEncoder().encode([] as [ReminderTime]),
            startDate: Date(),
            endDate: nil,
            isActive: true,
            displayOrder: 0,
            suggestionId: nil,
            locationConfigData: nil,
            lastGeofenceTriggerDate: nil
        )
        habit.category = category
        context.insert(habit)
        try context.save()

        // Verify habit has category
        #expect(habit.category != nil, "Habit should have category before deletion")

        // Delete the category
        context.delete(category)
        try context.save()

        // Verify SwiftData automatically nulled the relationship
        #expect(habit.category == nil, "SwiftData should automatically null the category reference")

        // Verify cleanup finds no orphans (since SwiftData handled it)
        let deletedCount = try await service.cleanupOrphanedHabits()
        #expect(deletedCount == 0, "No orphans should exist because SwiftData nulled the relationship")

        // Verify habit still exists (not deleted)
        let descriptor = FetchDescriptor<ActiveHabitModel>()
        let remainingHabits = try context.fetch(descriptor)
        #expect(remainingHabits.count == 1, "Habit should still exist with nil category")
    }

    @Test("Multiple habits with same category all get nulled when category deleted")
    func swiftDataNullsMultipleHabitsOnCategoryDelete() async throws {
        let container = try createTestContainer()
        let service = HabitMaintenanceService(modelContainer: container)

        let context = ModelContext(container)

        // Create a category
        let category = ActiveHabitCategoryModel(
            id: "test-category",
            name: "test",
            displayName: "Test",
            emoji: "🧪",
            order: 0,
            isActive: true,
            isPredefined: false
        )
        context.insert(category)

        // Create 3 habits that reference the category
        var habits: [ActiveHabitModel] = []
        for i in 0..<3 {
            let habit = ActiveHabitModel(
                id: UUID(),
                name: "Test Habit \(i + 1)",
                colorHex: "#2DA9E3",
                emoji: "🎯",
                kindRaw: 0,
                unitLabel: nil,
                dailyTarget: nil,
                scheduleData: try JSONEncoder().encode(HabitSchedule.daily),
                remindersData: try JSONEncoder().encode([] as [ReminderTime]),
                startDate: Date(),
                endDate: nil,
                isActive: true,
                displayOrder: i,
                suggestionId: nil,
                locationConfigData: nil,
                lastGeofenceTriggerDate: nil
            )
            habit.category = category
            context.insert(habit)
            habits.append(habit)
        }
        try context.save()

        // Verify all habits have category
        for habit in habits {
            #expect(habit.category != nil, "All habits should have category before deletion")
        }

        // Delete the category
        context.delete(category)
        try context.save()

        // Verify SwiftData automatically nulled all relationships
        for habit in habits {
            #expect(habit.category == nil, "SwiftData should null all category references")
        }

        // Verify cleanup finds no orphans
        let deletedCount = try await service.cleanupOrphanedHabits()
        #expect(deletedCount == 0, "No orphans exist due to SwiftData's automatic relationship management")

        // Verify all habits still exist
        let descriptor = FetchDescriptor<ActiveHabitModel>()
        let remainingHabits = try context.fetch(descriptor)
        #expect(remainingHabits.count == 3, "All habits should still exist with nil categories")
    }

    @Test("Habits with different categories are unaffected when one category deleted")
    func swiftDataOnlyNullsAffectedHabits() async throws {
        let container = try createTestContainer()
        let service = HabitMaintenanceService(modelContainer: container)

        let context = ModelContext(container)

        // Create two categories
        let category1 = ActiveHabitCategoryModel(
            id: "category-1",
            name: "category1",
            displayName: "Category 1",
            emoji: "✅",
            order: 0,
            isActive: true,
            isPredefined: false
        )
        let category2 = ActiveHabitCategoryModel(
            id: "category-2",
            name: "category2",
            displayName: "Category 2",
            emoji: "💀",
            order: 1,
            isActive: true,
            isPredefined: false
        )
        context.insert(category1)
        context.insert(category2)

        // Create habit with category1
        let habit1 = ActiveHabitModel(
            id: UUID(),
            name: "Habit 1",
            colorHex: "#2DA9E3",
            emoji: "🎯",
            kindRaw: 0,
            unitLabel: nil,
            dailyTarget: nil,
            scheduleData: try JSONEncoder().encode(HabitSchedule.daily),
            remindersData: try JSONEncoder().encode([] as [ReminderTime]),
            startDate: Date(),
            endDate: nil,
            isActive: true,
            displayOrder: 0,
            suggestionId: nil,
            locationConfigData: nil,
            lastGeofenceTriggerDate: nil
        )
        habit1.category = category1
        context.insert(habit1)

        // Create habit with category2
        let habit2 = ActiveHabitModel(
            id: UUID(),
            name: "Habit 2",
            colorHex: "#2DA9E3",
            emoji: "💀",
            kindRaw: 0,
            unitLabel: nil,
            dailyTarget: nil,
            scheduleData: try JSONEncoder().encode(HabitSchedule.daily),
            remindersData: try JSONEncoder().encode([] as [ReminderTime]),
            startDate: Date(),
            endDate: nil,
            isActive: true,
            displayOrder: 1,
            suggestionId: nil,
            locationConfigData: nil,
            lastGeofenceTriggerDate: nil
        )
        habit2.category = category2
        context.insert(habit2)

        try context.save()

        // Delete only category2
        context.delete(category2)
        try context.save()

        // Verify only habit2's category was nulled
        #expect(habit1.category != nil, "Habit 1 should still have its category")
        #expect(habit1.category?.id == "category-1", "Habit 1's category should be unchanged")
        #expect(habit2.category == nil, "Habit 2's category should be nulled")

        // Verify cleanup finds no orphans
        let deletedCount = try await service.cleanupOrphanedHabits()
        #expect(deletedCount == 0, "No orphans due to SwiftData's selective relationship management")

        // Verify both habits still exist
        let descriptor = FetchDescriptor<ActiveHabitModel>()
        let remainingHabits = try context.fetch(descriptor)
        #expect(remainingHabits.count == 2, "Both habits should still exist")
    }

    // MARK: - Basic Functionality Tests

    @Test("Cleanup returns 0 when no habits exist")
    func cleanupReturnsZeroWithNoHabits() async throws {
        let container = try createTestContainer()
        let service = HabitMaintenanceService(modelContainer: container)

        // Create a valid category but no habits
        let context = ModelContext(container)
        let category = ActiveHabitCategoryModel(
            id: "test-category",
            name: "test",
            displayName: "Test",
            emoji: "🧪",
            order: 0,
            isActive: true,
            isPredefined: false
        )
        context.insert(category)
        try context.save()

        let deletedCount = try await service.cleanupOrphanedHabits()
        #expect(deletedCount == 0, "No habits to delete when database has no habits")
    }

    @Test("Cleanup returns 0 when habits have valid categories")
    func cleanupReturnsZeroWithValidCategories() async throws {
        let container = try createTestContainer()
        let service = HabitMaintenanceService(modelContainer: container)

        // Create a valid category
        let context = ModelContext(container)
        let category = ActiveHabitCategoryModel(
            id: "test-category",
            name: "test",
            displayName: "Test",
            emoji: "🧪",
            order: 0,
            isActive: true,
            isPredefined: false
        )
        context.insert(category)

        // Create habit that references the valid category
        let habit = ActiveHabitModel(
            id: UUID(),
            name: "Valid Habit",
            colorHex: "#2DA9E3",
            emoji: "🎯",
            kindRaw: 0,
            unitLabel: nil,
            dailyTarget: nil,
            scheduleData: try JSONEncoder().encode(HabitSchedule.daily),
            remindersData: try JSONEncoder().encode([] as [ReminderTime]),
            startDate: Date(),
            endDate: nil,
            isActive: true,
            displayOrder: 0,
            suggestionId: nil,
            locationConfigData: nil,
            lastGeofenceTriggerDate: nil
        )
        habit.category = category
        context.insert(habit)

        try context.save()

        let deletedCount = try await service.cleanupOrphanedHabits()
        #expect(deletedCount == 0, "No habits should be deleted when all have valid categories")
    }

    @Test("Cleanup returns 0 when habits have nil category")
    func cleanupReturnsZeroWithNilCategory() async throws {
        let container = try createTestContainer()
        let service = HabitMaintenanceService(modelContainer: container)

        // Create habit with nil category (which is valid)
        let context = ModelContext(container)
        let habit = ActiveHabitModel(
            id: UUID(),
            name: "Uncategorized Habit",
            colorHex: "#2DA9E3",
            emoji: "🎯",
            kindRaw: 0,
            unitLabel: nil,
            dailyTarget: nil,
            scheduleData: try JSONEncoder().encode(HabitSchedule.daily),
            remindersData: try JSONEncoder().encode([] as [ReminderTime]),
            startDate: Date(),
            endDate: nil,
            isActive: true,
            displayOrder: 0,
            suggestionId: nil,
            locationConfigData: nil,
            lastGeofenceTriggerDate: nil
        )
        // Explicitly leave category as nil
        context.insert(habit)
        try context.save()

        let deletedCount = try await service.cleanupOrphanedHabits()
        #expect(deletedCount == 0, "Habits with nil category should not be deleted")
    }

    @Test("Multiple cleanup calls are idempotent")
    func multipleCleanupCallsAreIdempotent() async throws {
        let container = try createTestContainer()
        let service = HabitMaintenanceService(modelContainer: container)

        let context = ModelContext(container)

        // Create habit with nil category
        let habit = ActiveHabitModel(
            id: UUID(),
            name: "Test Habit",
            colorHex: "#2DA9E3",
            emoji: "🎯",
            kindRaw: 0,
            unitLabel: nil,
            dailyTarget: nil,
            scheduleData: try JSONEncoder().encode(HabitSchedule.daily),
            remindersData: try JSONEncoder().encode([] as [ReminderTime]),
            startDate: Date(),
            endDate: nil,
            isActive: true,
            displayOrder: 0,
            suggestionId: nil,
            locationConfigData: nil,
            lastGeofenceTriggerDate: nil
        )
        context.insert(habit)
        try context.save()

        // Multiple cleanups should all return 0
        let firstCount = try await service.cleanupOrphanedHabits()
        #expect(firstCount == 0)

        let secondCount = try await service.cleanupOrphanedHabits()
        #expect(secondCount == 0, "Second cleanup should find nothing")

        let thirdCount = try await service.cleanupOrphanedHabits()
        #expect(thirdCount == 0, "Third cleanup should find nothing")
    }

    // MARK: - Edge Case Tests

    @Test("Cleanup handles empty database gracefully")
    func cleanupHandlesEmptyDatabase() async throws {
        let container = try createTestContainer()
        let service = HabitMaintenanceService(modelContainer: container)

        let deletedCount = try await service.cleanupOrphanedHabits()
        #expect(deletedCount == 0, "Cleanup on empty database should return 0")
    }

    @Test("Cleanup handles database with only categories gracefully")
    func cleanupHandlesOnlyCategories() async throws {
        let container = try createTestContainer()
        let service = HabitMaintenanceService(modelContainer: container)

        // Create some categories but no habits
        let context = ModelContext(container)
        for i in 0..<3 {
            let category = ActiveHabitCategoryModel(
                id: "category-\(i)",
                name: "category\(i)",
                displayName: "Category \(i)",
                emoji: "🧪",
                order: i,
                isActive: true,
                isPredefined: false
            )
            context.insert(category)
        }
        try context.save()

        let deletedCount = try await service.cleanupOrphanedHabits()
        #expect(deletedCount == 0, "No habits to delete when database has only categories")
    }
}
