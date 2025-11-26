//
//  DataDeduplicationServiceTests.swift
//  RitualistTests
//
//  Created by Claude on 26.11.2025.
//

import Testing
import Foundation
import SwiftData
@testable import RitualistCore

// MARK: - Profile Deduplication Tests

@Suite("DataDeduplicationService - Profile Deduplication")
struct ProfileDeduplicationTests {

    // MARK: - Zero/One Profile Tests

    @Test("Returns 0 when no profiles exist")
    func noProfilesReturnsZero() async throws {
        let container = try TestModelContainer.create()
        let service = DataDeduplicationService(modelContainer: container)

        let removed = try await service.deduplicateProfiles()

        #expect(removed == 0, "Should return 0 when no profiles exist")
    }

    @Test("Returns 0 when only one profile exists")
    func singleProfileReturnsZero() async throws {
        let container = try TestModelContainer.create()
        let context = ModelContext(container)

        let profile = UserProfileBuilder.standard(name: "Test User")
        context.insert(profile.toModel())
        try context.save()

        let service = DataDeduplicationService(modelContainer: container)
        let removed = try await service.deduplicateProfiles()

        #expect(removed == 0, "Should return 0 when only one profile exists")

        let remaining = try context.fetch(FetchDescriptor<ActiveUserProfileModel>())
        #expect(remaining.count == 1, "Single profile should remain")
    }

    // MARK: - Duplicate Removal Tests

    @Test("Removes duplicate when two profiles exist")
    func removesDuplicateWithTwoProfiles() async throws {
        let container = try TestModelContainer.create()
        let context = ModelContext(container)

        let profile1 = UserProfileBuilder.standard(name: "User 1")
        let profile2 = UserProfileBuilder.standard(name: "User 2")
        context.insert(profile1.toModel())
        context.insert(profile2.toModel())
        try context.save()

        let service = DataDeduplicationService(modelContainer: container)
        let removed = try await service.deduplicateProfiles()

        #expect(removed == 1, "Should remove one duplicate")

        let remaining = try context.fetch(FetchDescriptor<ActiveUserProfileModel>())
        #expect(remaining.count == 1, "Only one profile should remain")
    }

    @Test("Removes all duplicates when three or more profiles exist")
    func removesAllDuplicatesWithMultipleProfiles() async throws {
        let container = try TestModelContainer.create()
        let context = ModelContext(container)

        let profile1 = UserProfileBuilder.standard(name: "User 1")
        let profile2 = UserProfileBuilder.standard(name: "User 2")
        let profile3 = UserProfileBuilder.standard(name: "User 3")
        context.insert(profile1.toModel())
        context.insert(profile2.toModel())
        context.insert(profile3.toModel())
        try context.save()

        let service = DataDeduplicationService(modelContainer: container)
        let removed = try await service.deduplicateProfiles()

        #expect(removed == 2, "Should remove two duplicates")

        let remaining = try context.fetch(FetchDescriptor<ActiveUserProfileModel>())
        #expect(remaining.count == 1, "Only one profile should remain")
    }

    // MARK: - Selection Criteria Tests

    @Test("Keeps profile with name over profile without name")
    func keepsProfileWithName() async throws {
        let container = try TestModelContainer.create()
        let context = ModelContext(container)

        let profileWithName = UserProfileBuilder.standard(name: "Alice")
        let profileWithoutName = UserProfileBuilder.standard(name: "")
        context.insert(profileWithoutName.toModel())
        context.insert(profileWithName.toModel())
        try context.save()

        let service = DataDeduplicationService(modelContainer: container)
        _ = try await service.deduplicateProfiles()

        let remaining = try context.fetch(FetchDescriptor<ActiveUserProfileModel>())
        #expect(remaining.count == 1, "Only one profile should remain")
        #expect(remaining.first?.name == "Alice", "Profile with name should be kept")
    }

    @Test("Keeps profile with avatar over profile without avatar")
    func keepsProfileWithAvatar() async throws {
        let container = try TestModelContainer.create()
        let context = ModelContext(container)

        let avatarData = Data([0x00, 0x01, 0x02])
        var profileWithAvatar = UserProfile(
            id: UUID(),
            name: "User",
            avatarImageData: avatarData,
            appearance: 0
        )
        var profileWithoutAvatar = UserProfile(
            id: UUID(),
            name: "User",
            avatarImageData: nil,
            appearance: 0
        )

        context.insert(profileWithoutAvatar.toModel())
        context.insert(profileWithAvatar.toModel())
        try context.save()

        let service = DataDeduplicationService(modelContainer: container)
        _ = try await service.deduplicateProfiles()

        let remaining = try context.fetch(FetchDescriptor<ActiveUserProfileModel>())
        #expect(remaining.count == 1, "Only one profile should remain")
        #expect(remaining.first?.avatarImageData != nil, "Profile with avatar should be kept")
    }

    // MARK: - Data Merging Tests

    @Test("Merges name from duplicate when keeper has no name")
    func mergesNameFromDuplicate() async throws {
        let container = try TestModelContainer.create()
        let context = ModelContext(container)

        let newerDate = Date()
        let olderDate = Date().addingTimeInterval(-3600)

        let keeperProfile = UserProfile(
            id: UUID(),
            name: "",
            avatarImageData: nil,
            appearance: 0,
            createdAt: newerDate,
            updatedAt: newerDate
        )
        let duplicateWithName = UserProfile(
            id: UUID(),
            name: "Alice",
            avatarImageData: nil,
            appearance: 0,
            createdAt: olderDate,
            updatedAt: olderDate
        )

        context.insert(keeperProfile.toModel())
        context.insert(duplicateWithName.toModel())
        try context.save()

        let service = DataDeduplicationService(modelContainer: container)
        _ = try await service.deduplicateProfiles()

        let remaining = try context.fetch(FetchDescriptor<ActiveUserProfileModel>())
        #expect(remaining.count == 1, "Only one profile should remain")
        #expect(remaining.first?.name == "Alice", "Name should be merged from duplicate")
    }

    @Test("Merges avatar from duplicate when keeper has no avatar")
    func mergesAvatarFromDuplicate() async throws {
        let container = try TestModelContainer.create()
        let context = ModelContext(container)

        let avatarData = Data([0x00, 0x01, 0x02])

        let keeperWithName = UserProfile(
            id: UUID(),
            name: "Alice",
            avatarImageData: nil,
            appearance: 0
        )
        let duplicateWithAvatar = UserProfile(
            id: UUID(),
            name: "",
            avatarImageData: avatarData,
            appearance: 0
        )

        context.insert(keeperWithName.toModel())
        context.insert(duplicateWithAvatar.toModel())
        try context.save()

        let service = DataDeduplicationService(modelContainer: container)
        _ = try await service.deduplicateProfiles()

        let remaining = try context.fetch(FetchDescriptor<ActiveUserProfileModel>())
        #expect(remaining.count == 1, "Only one profile should remain")
        #expect(remaining.first?.name == "Alice", "Keeper's name should be preserved")
        #expect(remaining.first?.avatarImageData == avatarData, "Avatar should be merged from duplicate")
    }
}

// MARK: - Habit Deduplication Tests

@Suite("DataDeduplicationService - Habit Deduplication")
struct HabitDeduplicationTests {

    @Test("Returns 0 when no habits exist")
    func noHabitsReturnsZero() async throws {
        let container = try TestModelContainer.create()
        let service = DataDeduplicationService(modelContainer: container)

        let removed = try await service.deduplicateHabits()

        #expect(removed == 0, "Should return 0 when no habits exist")
    }

    @Test("Returns 0 when no duplicate habit names exist")
    func noDuplicatesReturnsZero() async throws {
        let container = try TestModelContainer.create()
        let context = ModelContext(container)

        let habit1 = HabitBuilder.binary(name: "Exercise")
        let habit2 = HabitBuilder.binary(name: "Meditation")
        context.insert(habit1.toModel())
        context.insert(habit2.toModel())
        try context.save()

        let service = DataDeduplicationService(modelContainer: container)
        let removed = try await service.deduplicateHabits()

        #expect(removed == 0, "Should return 0 when no duplicates")

        let remaining = try TestModelContainer.fetchAllHabits(from: context)
        #expect(remaining.count == 2, "Both habits should remain")
    }

    @Test("Removes duplicate habits with same name")
    func removesDuplicatesWithSameName() async throws {
        let container = try TestModelContainer.create()
        let context = ModelContext(container)

        // Create two habits with the same name (simulating CloudKit duplicate)
        let habit1 = HabitBuilder.binary(name: "Exercise")
        let habit2 = HabitBuilder.binary(name: "Exercise")  // Same name, different ID
        context.insert(habit1.toModel())
        context.insert(habit2.toModel())
        try context.save()

        let service = DataDeduplicationService(modelContainer: container)
        let removed = try await service.deduplicateHabits()

        #expect(removed == 1, "Should remove one duplicate")

        let remaining = try TestModelContainer.fetchAllHabits(from: context)
        #expect(remaining.count == 1, "Only one habit should remain")
        #expect(remaining.first?.name == "Exercise", "Remaining habit should have correct name")
    }

    @Test("Keeps habit with more logs when deduplicating")
    func keepsHabitWithMoreLogs() async throws {
        let container = try TestModelContainer.create()
        let context = ModelContext(container)

        // Create two habits with same name
        let habit1 = HabitBuilder.binary(name: "Exercise")
        let habit2 = HabitBuilder.binary(name: "Exercise")

        let habit1Model = habit1.toModel()
        let habit2Model = habit2.toModel()

        context.insert(habit1Model)
        context.insert(habit2Model)

        // Add more logs to habit2
        let log1 = HabitLogBuilder.binary(habitId: habit2.id, date: TestDates.today)
        let log2 = HabitLogBuilder.binary(habitId: habit2.id, date: TestDates.yesterday)
        let logModel1 = log1.toModel()
        let logModel2 = log2.toModel()
        logModel1.habit = habit2Model
        logModel2.habit = habit2Model

        context.insert(logModel1)
        context.insert(logModel2)
        try context.save()

        let service = DataDeduplicationService(modelContainer: container)
        _ = try await service.deduplicateHabits()

        let remaining = try TestModelContainer.fetchAllHabits(from: context)
        #expect(remaining.count == 1, "Only one habit should remain")

        // The habit with more logs should be kept
        let logs = try TestModelContainer.fetchAllLogs(from: context)
        #expect(logs.count == 2, "Logs should be preserved")
    }

    @Test("Moves logs to keeper habit when deduplicating")
    func movesLogsToKeeperHabit() async throws {
        let container = try TestModelContainer.create()
        let context = ModelContext(container)

        // Create two habits with same name
        let habit1 = HabitBuilder.binary(name: "Exercise")
        let habit2 = HabitBuilder.binary(name: "Exercise")

        let habit1Model = habit1.toModel()
        let habit2Model = habit2.toModel()

        context.insert(habit1Model)
        context.insert(habit2Model)

        // Add logs to both habits
        let log1 = HabitLogBuilder.binary(habitId: habit1.id, date: TestDates.today)
        let log2 = HabitLogBuilder.binary(habitId: habit2.id, date: TestDates.yesterday)
        let logModel1 = log1.toModel()
        let logModel2 = log2.toModel()
        logModel1.habit = habit1Model
        logModel2.habit = habit2Model

        context.insert(logModel1)
        context.insert(logModel2)
        try context.save()

        let service = DataDeduplicationService(modelContainer: container)
        _ = try await service.deduplicateHabits()

        let remainingHabits = try TestModelContainer.fetchAllHabits(from: context)
        #expect(remainingHabits.count == 1, "Only one habit should remain")

        // All logs should now belong to the keeper habit
        let logs = try TestModelContainer.fetchAllLogs(from: context)
        #expect(logs.count == 2, "Both logs should be preserved")
        #expect(logs.allSatisfy { $0.habit == remainingHabits.first }, "All logs should belong to keeper")
    }
}

// MARK: - Category Deduplication Tests

@Suite("DataDeduplicationService - Category Deduplication")
struct CategoryDeduplicationTests {

    @Test("Returns 0 when no categories exist")
    func noCategoriesReturnsZero() async throws {
        let container = try TestModelContainer.create()
        let service = DataDeduplicationService(modelContainer: container)

        let removed = try await service.deduplicateCategories()

        #expect(removed == 0, "Should return 0 when no categories exist")
    }

    @Test("Returns 0 when no duplicate category IDs exist")
    func noDuplicatesReturnsZero() async throws {
        let container = try TestModelContainer.create()
        let context = ModelContext(container)

        let cat1 = CategoryBuilder.category(id: "health", displayName: "Health")
        let cat2 = CategoryBuilder.category(id: "fitness", displayName: "Fitness")
        context.insert(cat1.toModel())
        context.insert(cat2.toModel())
        try context.save()

        let service = DataDeduplicationService(modelContainer: container)
        let removed = try await service.deduplicateCategories()

        #expect(removed == 0, "Should return 0 when no duplicates")

        let remaining = try TestModelContainer.fetchAllCategories(from: context)
        #expect(remaining.count == 2, "Both categories should remain")
    }

    @Test("Removes duplicate categories with same ID")
    func removesDuplicatesWithSameId() async throws {
        let container = try TestModelContainer.create()
        let context = ModelContext(container)

        // Create two categories with the same ID (simulating CloudKit duplicate)
        let cat1 = CategoryBuilder.category(id: "health", displayName: "Health")
        let cat2 = CategoryBuilder.category(id: "health", displayName: "Health 2")  // Same ID
        context.insert(cat1.toModel())
        context.insert(cat2.toModel())
        try context.save()

        let service = DataDeduplicationService(modelContainer: container)
        let removed = try await service.deduplicateCategories()

        #expect(removed == 1, "Should remove one duplicate")

        let remaining = try TestModelContainer.fetchAllCategories(from: context)
        #expect(remaining.count == 1, "Only one category should remain")
        #expect(remaining.first?.id == "health", "Remaining category should have correct ID")
    }
}

// MARK: - Habit Log Deduplication Tests

@Suite("DataDeduplicationService - HabitLog Deduplication")
struct HabitLogDeduplicationTests {

    @Test("Returns 0 when no logs exist")
    func noLogsReturnsZero() async throws {
        let container = try TestModelContainer.create()
        let service = DataDeduplicationService(modelContainer: container)

        let removed = try await service.deduplicateHabitLogs()

        #expect(removed == 0, "Should return 0 when no logs exist")
    }

    @Test("Returns 0 when no duplicate logs exist")
    func noDuplicatesReturnsZero() async throws {
        let container = try TestModelContainer.create()
        let context = ModelContext(container)

        let habit = HabitBuilder.binary(name: "Exercise")
        let habitModel = habit.toModel()
        context.insert(habitModel)

        let log1 = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)
        let log2 = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.yesterday)
        let logModel1 = log1.toModel()
        let logModel2 = log2.toModel()
        logModel1.habit = habitModel
        logModel2.habit = habitModel
        context.insert(logModel1)
        context.insert(logModel2)
        try context.save()

        let service = DataDeduplicationService(modelContainer: container)
        let removed = try await service.deduplicateHabitLogs()

        #expect(removed == 0, "Should return 0 when no duplicates")

        let remaining = try TestModelContainer.fetchAllLogs(from: context)
        #expect(remaining.count == 2, "Both logs should remain")
    }

    @Test("Removes duplicate logs with same UUID")
    func removesDuplicatesWithSameUUID() async throws {
        let container = try TestModelContainer.create()
        let context = ModelContext(container)

        let habit = HabitBuilder.binary(name: "Exercise")
        let habitModel = habit.toModel()
        context.insert(habitModel)

        // Create two logs with the same UUID (simulating CloudKit duplicate)
        let logId = UUID()
        let log1 = HabitLog(id: logId, habitID: habit.id, date: TestDates.today, value: 1.0, timezone: "UTC")
        let log2 = HabitLog(id: logId, habitID: habit.id, date: TestDates.today, value: 1.0, timezone: "UTC")
        let logModel1 = log1.toModel()
        let logModel2 = log2.toModel()
        logModel1.habit = habitModel
        logModel2.habit = habitModel
        context.insert(logModel1)
        context.insert(logModel2)
        try context.save()

        let service = DataDeduplicationService(modelContainer: container)
        let removed = try await service.deduplicateHabitLogs()

        #expect(removed == 1, "Should remove one duplicate")

        let remaining = try TestModelContainer.fetchAllLogs(from: context)
        #expect(remaining.count == 1, "Only one log should remain")
    }

    @Test("Removes duplicate logs for same habit and date")
    func removesDuplicatesForSameHabitAndDate() async throws {
        let container = try TestModelContainer.create()
        let context = ModelContext(container)

        let habit = HabitBuilder.binary(name: "Exercise")
        let habitModel = habit.toModel()
        context.insert(habitModel)

        // Create two logs for the same habit on the same day (different UUIDs)
        let log1 = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)
        let log2 = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)
        let logModel1 = log1.toModel()
        let logModel2 = log2.toModel()
        logModel1.habit = habitModel
        logModel2.habit = habitModel
        context.insert(logModel1)
        context.insert(logModel2)
        try context.save()

        let service = DataDeduplicationService(modelContainer: container)
        let removed = try await service.deduplicateHabitLogs()

        #expect(removed == 1, "Should remove one duplicate")

        let remaining = try TestModelContainer.fetchAllLogs(from: context)
        #expect(remaining.count == 1, "Only one log should remain for the day")
    }

    @Test("Keeps log with highest value when deduplicating numeric logs")
    func keepsLogWithHighestValue() async throws {
        let container = try TestModelContainer.create()
        let context = ModelContext(container)

        let habit = HabitBuilder.numeric(name: "Water", target: 8.0, unit: "glasses")
        let habitModel = habit.toModel()
        context.insert(habitModel)

        // Create two logs for the same day with different values
        let log1 = HabitLogBuilder.numeric(habitId: habit.id, value: 5.0, date: TestDates.today)
        let log2 = HabitLogBuilder.numeric(habitId: habit.id, value: 8.0, date: TestDates.today)
        let logModel1 = log1.toModel()
        let logModel2 = log2.toModel()
        logModel1.habit = habitModel
        logModel2.habit = habitModel
        context.insert(logModel1)
        context.insert(logModel2)
        try context.save()

        let service = DataDeduplicationService(modelContainer: container)
        _ = try await service.deduplicateHabitLogs()

        let remaining = try TestModelContainer.fetchAllLogs(from: context)
        #expect(remaining.count == 1, "Only one log should remain")
        #expect(remaining.first?.value == 8.0, "Log with highest value should be kept")
    }
}

// MARK: - DeduplicateAll Tests

@Suite("DataDeduplicationService - DeduplicateAll")
struct DeduplicateAllTests {

    @Test("deduplicateAll returns correct totals for all model types")
    func deduplicateAllReturnsCorrectTotals() async throws {
        let container = try TestModelContainer.create()
        let context = ModelContext(container)

        // Create duplicate profiles
        let profile1 = UserProfileBuilder.standard(name: "User 1")
        let profile2 = UserProfileBuilder.standard(name: "User 2")
        context.insert(profile1.toModel())
        context.insert(profile2.toModel())

        // Create duplicate categories
        let cat1 = CategoryBuilder.category(id: "health", displayName: "Health")
        let cat2 = CategoryBuilder.category(id: "health", displayName: "Health 2")
        context.insert(cat1.toModel())
        context.insert(cat2.toModel())

        // Create duplicate habits
        let habit1 = HabitBuilder.binary(name: "Exercise")
        let habit2 = HabitBuilder.binary(name: "Exercise")
        context.insert(habit1.toModel())
        context.insert(habit2.toModel())

        try context.save()

        let service = DataDeduplicationService(modelContainer: container)
        let result = try await service.deduplicateAll()

        #expect(result.profilesRemoved == 1, "Should remove 1 profile duplicate")
        #expect(result.categoriesRemoved == 1, "Should remove 1 category duplicate")
        #expect(result.habitsRemoved == 1, "Should remove 1 habit duplicate")
        #expect(result.totalRemoved == 3, "Total should be 3")
        #expect(result.hadDuplicates == true, "Should indicate duplicates were found")
    }

    @Test("deduplicateAll returns zeros when no duplicates exist")
    func deduplicateAllReturnsZerosWhenNoDuplicates() async throws {
        let container = try TestModelContainer.create()
        let context = ModelContext(container)

        // Create unique records
        let profile = UserProfileBuilder.standard(name: "User")
        context.insert(profile.toModel())

        let category = CategoryBuilder.category(id: "health", displayName: "Health")
        context.insert(category.toModel())

        let habit = HabitBuilder.binary(name: "Exercise")
        context.insert(habit.toModel())

        try context.save()

        let service = DataDeduplicationService(modelContainer: container)
        let result = try await service.deduplicateAll()

        #expect(result.profilesRemoved == 0, "Should remove 0 profiles")
        #expect(result.categoriesRemoved == 0, "Should remove 0 categories")
        #expect(result.habitsRemoved == 0, "Should remove 0 habits")
        #expect(result.habitLogsRemoved == 0, "Should remove 0 logs")
        #expect(result.totalRemoved == 0, "Total should be 0")
        #expect(result.hadDuplicates == false, "Should indicate no duplicates")
        #expect(result.hadDataToCheck == true, "Should indicate data was checked")
    }
}
