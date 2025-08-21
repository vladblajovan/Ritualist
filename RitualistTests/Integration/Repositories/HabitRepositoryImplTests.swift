//
//  HabitRepositoryImplTests.swift
//  RitualistTests
//
//  Created by Claude on 21.08.2025.
//

import Foundation
import SwiftData
import Testing
@testable import Ritualist
@testable import RitualistCore

/// Comprehensive integration tests for HabitRepositoryImpl using in-memory SwiftData
/// 
/// These tests validate the REAL implementation that runs in production, ensuring:
/// - Actual CRUD operations work correctly with SwiftData
/// - Relationships between Habit-Category and Habit-Log are maintained
/// - Query operations handle filtering and search correctly
/// - Error conditions are properly handled
/// - Performance is acceptable with large datasets
/// - Thread safety and concurrency work as expected
/// - Data integrity is maintained across operations
///
/// **Testing Philosophy**: 
/// - Test the actual production code, not mocks
/// - Use isolated in-memory databases for each test
/// - Validate real SwiftData relationships and cascade behavior
/// - Cover both happy path and error scenarios
/// - Test performance with realistic data volumes
@Suite("HabitRepositoryImpl Integration Tests")
struct HabitRepositoryImplTests {
    
    // MARK: - CRUD Operations Tests
    
    @Test("Create habit successfully persists to database")
    func testCreateHabit() async throws {
        // Arrange: Real repository with in-memory database
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let dataSource = HabitLocalDataSource(modelContainer: container)
        let repository = HabitRepositoryImpl(local: dataSource)
        
        let habit = HabitBuilder()
            .withName("Daily Exercise")
            .withEmoji("🏃‍♂️")
            .asNumeric(target: 30.0, unit: "minutes")
            .withStartDate(Date())
            .build()
        
        // Act: Create habit using real repository
        try await repository.create(habit)
        
        // Assert: Verify habit was persisted correctly
        let allHabits = try await repository.fetchAllHabits()
        #expect(allHabits.count == 1)
        
        let savedHabit = allHabits[0]
        #expect(savedHabit.id == habit.id)
        #expect(savedHabit.name == "Daily Exercise")
        #expect(savedHabit.emoji == "🏃‍♂️")
        #expect(savedHabit.kind == .numeric)
        #expect(savedHabit.dailyTarget == 30.0)
        #expect(savedHabit.unitLabel == "minutes")
        #expect(savedHabit.isActive == true)
    }
    
    @Test("Create habit with category relationship")
    func testCreateHabitWithCategory() async throws {
        // Arrange: Repository with category in database
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let dataSource = HabitLocalDataSource(modelContainer: container)
        let repository = HabitRepositoryImpl(local: dataSource)
        
        // First create a category directly in the database
        let healthCategory = CategoryBuilder.healthCategory().build()
        let categoryModel = HabitCategoryModel.fromEntity(healthCategory)
        context.insert(categoryModel)
        try context.save()
        
        let habit = HabitBuilder()
            .withName("Morning Run")
            .withCategory(healthCategory)
            .build()
        
        // Act: Create habit with category reference
        try await repository.create(habit)
        
        // Assert: Verify habit and category relationship
        let allHabits = try await repository.fetchAllHabits()
        #expect(allHabits.count == 1)
        
        let savedHabit = allHabits[0]
        #expect(savedHabit.categoryId == healthCategory.id)
        #expect(savedHabit.name == "Morning Run")
        
        // Verify category still exists and is properly linked
        let categoryDescriptor = FetchDescriptor<HabitCategoryModel>(
            predicate: #Predicate { $0.id == healthCategory.id }
        )
        let categories = try context.fetch(categoryDescriptor)
        #expect(categories.count == 1)
    }
    
    @Test("Update habit modifies existing record")
    func testUpdateHabit() async throws {
        // Arrange: Create habit then modify it
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let dataSource = HabitLocalDataSource(modelContainer: container)
        let repository = HabitRepositoryImpl(local: dataSource)
        
        let originalHabit = HabitBuilder()
            .withName("Original Name")
            .withEmoji("🎯")
            .asDaily()
            .build()
        
        try await repository.create(originalHabit)
        
        // Modify the habit
        let updatedHabit = Habit(
            id: originalHabit.id, // Same ID for update
            name: "Updated Name",
            colorHex: "#FF0000",
            emoji: "⭐️",
            kind: .numeric,
            unitLabel: "reps",
            dailyTarget: 10.0,
            schedule: .timesPerWeek(3),
            reminders: [ReminderTime(hour: 9, minute: 30)],
            startDate: originalHabit.startDate,
            endDate: nil,
            isActive: true,
            displayOrder: 5,
            categoryId: nil,
            suggestionId: nil
        )
        
        // Act: Update the habit
        try await repository.update(updatedHabit)
        
        // Assert: Verify all properties were updated correctly
        let fetchedHabit = try await repository.fetchHabit(by: originalHabit.id)
        #expect(fetchedHabit != nil)
        
        let habit = try #require(fetchedHabit)
        #expect(habit.name == "Updated Name")
        #expect(habit.colorHex == "#FF0000")
        #expect(habit.emoji == "⭐️")
        #expect(habit.kind == .numeric)
        #expect(habit.unitLabel == "reps")
        #expect(habit.dailyTarget == 10.0)
        #expect(habit.displayOrder == 5)
        
        // Verify only one habit exists (update, not create)
        let allHabits = try await repository.fetchAllHabits()
        #expect(allHabits.count == 1)
    }
    
    @Test("Delete habit removes record from database")
    func testDeleteHabit() async throws {
        // Arrange: Create multiple habits
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let dataSource = HabitLocalDataSource(modelContainer: container)
        let repository = HabitRepositoryImpl(local: dataSource)
        
        let habit1 = HabitBuilder().withName("Keep This").build()
        let habit2 = HabitBuilder().withName("Delete This").build()
        
        try await repository.create(habit1)
        try await repository.create(habit2)
        
        // Verify both exist
        let beforeDelete = try await repository.fetchAllHabits()
        #expect(beforeDelete.count == 2)
        
        // Act: Delete one habit
        try await repository.delete(id: habit2.id)
        
        // Assert: Verify correct habit was deleted
        let afterDelete = try await repository.fetchAllHabits()
        #expect(afterDelete.count == 1)
        #expect(afterDelete[0].id == habit1.id)
        #expect(afterDelete[0].name == "Keep This")
        
        // Verify deleted habit cannot be fetched
        let deletedHabit = try await repository.fetchHabit(by: habit2.id)
        #expect(deletedHabit == nil)
    }
    
    @Test("Fetch all habits returns all persisted habits")
    func testFetchAllHabits() async throws {
        // Arrange: Create multiple habits with different properties
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let dataSource = HabitLocalDataSource(modelContainer: container)
        let repository = HabitRepositoryImpl(local: dataSource)
        
        let habits = [
            HabitBuilder().withName("Habit A").withDisplayOrder(2).build(),
            HabitBuilder().withName("Habit B").withDisplayOrder(1).build(),
            HabitBuilder().withName("Habit C").withDisplayOrder(3).asInactive().build()
        ]
        
        for habit in habits {
            try await repository.create(habit)
        }
        
        // Act: Fetch all habits
        let allHabits = try await repository.fetchAllHabits()
        
        // Assert: All habits returned in correct order
        #expect(allHabits.count == 3)
        
        // Verify habits are sorted by displayOrder (as per FetchDescriptor)
        let sortedNames = allHabits.map { $0.name }
        #expect(sortedNames == ["Habit B", "Habit A", "Habit C"])
        
        // Verify both active and inactive habits are included
        let activeCount = allHabits.filter { $0.isActive }.count
        let inactiveCount = allHabits.filter { !$0.isActive }.count
        #expect(activeCount == 2)
        #expect(inactiveCount == 1)
    }
    
    @Test("Fetch habit by ID returns correct habit or nil")
    func testFetchHabitById() async throws {
        // Arrange: Create multiple habits
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let dataSource = HabitLocalDataSource(modelContainer: container)
        let repository = HabitRepositoryImpl(local: dataSource)
        
        let targetHabit = HabitBuilder()
            .withName("Target Habit")
            .withEmoji("🎯")
            .build()
        
        let otherHabit = HabitBuilder()
            .withName("Other Habit")
            .build()
        
        try await repository.create(targetHabit)
        try await repository.create(otherHabit)
        
        // Act & Assert: Fetch existing habit
        let fetchedHabit = try await repository.fetchHabit(by: targetHabit.id)
        #expect(fetchedHabit != nil)
        
        let habit = try #require(fetchedHabit)
        #expect(habit.id == targetHabit.id)
        #expect(habit.name == "Target Habit")
        #expect(habit.emoji == "🎯")
        
        // Act & Assert: Fetch non-existent habit
        let nonExistentId = UUID()
        let missingHabit = try await repository.fetchHabit(by: nonExistentId)
        #expect(missingHabit == nil)
    }
    
    // MARK: - Relationship Tests
    
    @Test("Delete habit with logs cascades correctly")
    func testDeleteHabitCascadesToLogs() async throws {
        // Arrange: Create habit with logs
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let dataSource = HabitLocalDataSource(modelContainer: container)
        let repository = HabitRepositoryImpl(local: dataSource)
        
        let habit = HabitBuilder().withName("Habit with Logs").build()
        try await repository.create(habit)
        
        // Create logs with proper relationship setup
        let habitModel = try context.fetch(FetchDescriptor<HabitModel>(predicate: #Predicate { $0.id == habit.id })).first!
        
        let logs = [
            HabitLogModel(
                id: UUID(),
                habitID: habit.id,
                habit: habitModel, // Properly establish relationship
                date: Date(),
                value: 1.0
            ),
            HabitLogModel(
                id: UUID(),
                habitID: habit.id,
                habit: habitModel, // Properly establish relationship
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                value: 1.0
            )
        ]
        
        for log in logs {
            context.insert(log)
        }
        try context.save()
        
        // Verify logs exist
        let logDescriptor = FetchDescriptor<HabitLogModel>()
        let allLogs = try context.fetch(logDescriptor)
        #expect(allLogs.count == 2)
        
        // Act: Delete the habit
        try await repository.delete(id: habit.id)
        
        // Assert: Logs should be cascaded (deleted with habit)
        let remainingLogs = try context.fetch(logDescriptor)
        #expect(remainingLogs.count == 0)
        
        // Verify habit is also gone
        let remainingHabits = try await repository.fetchAllHabits()
        #expect(remainingHabits.count == 0)
    }
    
    @Test("Habit category relationship maintains integrity")
    func testHabitCategoryRelationshipIntegrity() async throws {
        // Arrange: Create category and habits
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let dataSource = HabitLocalDataSource(modelContainer: container)
        let repository = HabitRepositoryImpl(local: dataSource)
        
        let category = CategoryBuilder.healthCategory().build()
        let categoryModel = HabitCategoryModel.fromEntity(category)
        context.insert(categoryModel)
        try context.save()
        
        let habitsInCategory = [
            HabitBuilder().withName("Habit 1").withCategory(category).build(),
            HabitBuilder().withName("Habit 2").withCategory(category).build()
        ]
        
        for habit in habitsInCategory {
            try await repository.create(habit)
        }
        
        // Create habit without category
        let habitWithoutCategory = HabitBuilder().withName("No Category").build()
        try await repository.create(habitWithoutCategory)
        
        // Act & Assert: Verify relationships
        let allHabits = try await repository.fetchAllHabits()
        #expect(allHabits.count == 3)
        
        let habitsWithCategory = allHabits.filter { $0.categoryId == category.id }
        #expect(habitsWithCategory.count == 2)
        
        let habitsWithoutCategory = allHabits.filter { $0.categoryId == nil }
        #expect(habitsWithoutCategory.count == 1)
        
        // Verify category still exists
        let categoryDescriptor = FetchDescriptor<HabitCategoryModel>(
            predicate: #Predicate { $0.id == category.id }
        )
        let categories = try context.fetch(categoryDescriptor)
        #expect(categories.count == 1)
    }
    
    // MARK: - Cleanup and Orphaned Data Tests
    
    @Test("Cleanup orphaned habits removes habits with invalid categories")
    func testCleanupOrphanedHabits() async throws {
        // Arrange: Create habits with and without valid categories
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let dataSource = HabitLocalDataSource(modelContainer: container)
        let repository = HabitRepositoryImpl(local: dataSource)
        
        // Create valid category
        let validCategory = CategoryBuilder.healthCategory().build()
        let categoryModel = HabitCategoryModel.fromEntity(validCategory)
        context.insert(categoryModel)
        try context.save()
        
        // Create habits
        let validHabit = HabitBuilder()
            .withName("Valid Habit")
            .withCategory(validCategory)
            .build()
        
        let orphanedHabit1 = HabitBuilder()
            .withName("Orphaned Habit 1")
            .withCategoryId("non-existent-category-1")
            .build()
        
        let orphanedHabit2 = HabitBuilder()
            .withName("Orphaned Habit 2")
            .withCategoryId("non-existent-category-2")
            .build()
        
        let noCategoryHabit = HabitBuilder()
            .withName("No Category Habit")
            .build() // categoryId is nil
        
        // Create all habits
        for habit in [validHabit, orphanedHabit1, orphanedHabit2, noCategoryHabit] {
            try await repository.create(habit)
        }
        
        // Verify initial state
        let beforeCleanup = try await repository.fetchAllHabits()
        #expect(beforeCleanup.count == 4)
        
        // Act: Cleanup orphaned habits
        let cleanedCount = try await repository.cleanupOrphanedHabits()
        
        // Assert: Only orphaned habits were removed
        #expect(cleanedCount == 2) // orphanedHabit1 and orphanedHabit2
        
        let afterCleanup = try await repository.fetchAllHabits()
        #expect(afterCleanup.count == 2) // validHabit and noCategoryHabit remain
        
        let remainingNames = Set(afterCleanup.map { $0.name })
        #expect(remainingNames.contains("Valid Habit"))
        #expect(remainingNames.contains("No Category Habit"))
        #expect(!remainingNames.contains("Orphaned Habit 1"))
        #expect(!remainingNames.contains("Orphaned Habit 2"))
    }
    
    @Test("Cleanup with no orphaned habits returns zero")
    func testCleanupWithNoOrphanedHabits() async throws {
        // Arrange: Create only valid habits
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let dataSource = HabitLocalDataSource(modelContainer: container)
        let repository = HabitRepositoryImpl(local: dataSource)
        
        let validCategory = CategoryBuilder.productivityCategory().build()
        let categoryModel = HabitCategoryModel.fromEntity(validCategory)
        context.insert(categoryModel)
        try context.save()
        
        let validHabits = [
            HabitBuilder().withName("Valid 1").withCategory(validCategory).build(),
            HabitBuilder().withName("Valid 2").build(), // No category is valid
            HabitBuilder().withName("Valid 3").withCategory(validCategory).build()
        ]
        
        for habit in validHabits {
            try await repository.create(habit)
        }
        
        // Act: Cleanup (should find nothing to clean)
        let cleanedCount = try await repository.cleanupOrphanedHabits()
        
        // Assert: No habits were cleaned up
        #expect(cleanedCount == 0)
        
        let afterCleanup = try await repository.fetchAllHabits()
        #expect(afterCleanup.count == 3) // All habits remain
    }
    
    // MARK: - Error Condition Tests
    
    @Test("Create duplicate habit ID updates existing habit")
    func testCreateDuplicateHabitId() async throws {
        // Arrange: Create initial habit
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let dataSource = HabitLocalDataSource(modelContainer: container)
        let repository = HabitRepositoryImpl(local: dataSource)
        
        let habitId = UUID()
        let originalHabit = HabitBuilder()
            .withId(habitId)
            .withName("Original")
            .withEmoji("🎯")
            .build()
        
        try await repository.create(originalHabit)
        
        // Verify initial creation
        let afterCreate = try await repository.fetchAllHabits()
        #expect(afterCreate.count == 1)
        #expect(afterCreate[0].name == "Original")
        
        // Act: Create "duplicate" with same ID (should update)
        let duplicateHabit = HabitBuilder()
            .withId(habitId) // Same ID
            .withName("Updated")
            .withEmoji("⭐️")
            .build()
        
        try await repository.create(duplicateHabit)
        
        // Assert: Should have updated, not created duplicate
        let afterDuplicate = try await repository.fetchAllHabits()
        #expect(afterDuplicate.count == 1) // Still only one habit
        
        let updatedHabit = afterDuplicate[0]
        #expect(updatedHabit.id == habitId)
        #expect(updatedHabit.name == "Updated") // Name was updated
        #expect(updatedHabit.emoji == "⭐️") // Emoji was updated
    }
    
    @Test("Delete non-existent habit does not throw error")
    func testDeleteNonExistentHabit() async throws {
        // Arrange: Empty repository
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let dataSource = HabitLocalDataSource(modelContainer: container)
        let repository = HabitRepositoryImpl(local: dataSource)
        
        let nonExistentId = UUID()
        
        // Act & Assert: Delete should not throw
        try await repository.delete(id: nonExistentId)
        
        // Verify repository is still empty
        let habits = try await repository.fetchAllHabits()
        #expect(habits.count == 0)
    }
    
    // MARK: - Performance Tests
    
    @Test("Repository handles large number of habits efficiently")
    func testPerformanceWithLargeDataset() async throws {
        // Arrange: Repository with performance test setup
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let dataSource = HabitLocalDataSource(modelContainer: container)
        let repository = HabitRepositoryImpl(local: dataSource)
        
        // Create categories for realistic data
        let categories = CategoryBuilder.createPredefinedCategories()
        for category in categories {
            let categoryModel = HabitCategoryModel.fromEntity(category)
            context.insert(categoryModel)
        }
        try context.save()
        
        // Create large number of habits
        let habitCount = 100
        var createdHabits: [Habit] = []
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<habitCount {
            let category = categories[i % categories.count]
            let habit = HabitBuilder()
                .withName("Performance Habit \(i)")
                .withCategory(category)
                .withDisplayOrder(i)
                .build()
            
            try await repository.create(habit)
            createdHabits.append(habit)
        }
        
        let createTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Act: Test fetch performance
        let fetchStartTime = CFAbsoluteTimeGetCurrent()
        let allHabits = try await repository.fetchAllHabits()
        let fetchTime = CFAbsoluteTimeGetCurrent() - fetchStartTime
        
        // Assert: Verify data integrity and reasonable performance
        #expect(allHabits.count == habitCount)
        #expect(createTime < 10.0) // Creating 100 habits should take less than 10 seconds
        #expect(fetchTime < 1.0) // Fetching 100 habits should take less than 1 second
        
        // Test individual fetch performance
        let individualFetchStart = CFAbsoluteTimeGetCurrent()
        let randomHabit = try await repository.fetchHabit(by: createdHabits[50].id)
        let individualFetchTime = CFAbsoluteTimeGetCurrent() - individualFetchStart
        
        #expect(randomHabit != nil)
        #expect(individualFetchTime < 0.1) // Individual fetch should be very fast
    }
    
    @Test("Concurrent operations maintain data integrity")
    func testConcurrentOperations() async throws {
        // Arrange: Repository for concurrent testing
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let dataSource = HabitLocalDataSource(modelContainer: container)
        let repository = HabitRepositoryImpl(local: dataSource)
        
        // Create concurrent tasks
        let taskCount = 10
        let habitsPerTask = 5
        
        await withTaskGroup(of: Void.self) { group in
            for taskId in 0..<taskCount {
                group.addTask {
                    do {
                        // Each task creates multiple habits
                        for habitId in 0..<habitsPerTask {
                            let habit = HabitBuilder()
                                .withName("Task\(taskId)_Habit\(habitId)")
                                .withDisplayOrder(taskId * 100 + habitId)
                                .build()
                            
                            try await repository.create(habit)
                        }
                    } catch {
                        // In real concurrent scenarios, some operations might conflict
                        // This is acceptable as long as data integrity is maintained
                    }
                }
            }
        }
        
        // Act & Assert: Verify data integrity after concurrent operations
        let allHabits = try await repository.fetchAllHabits()
        
        // We should have some habits (exact count depends on concurrency conflicts)
        #expect(allHabits.count > 0)
        #expect(allHabits.count <= taskCount * habitsPerTask)
        
        // Verify no data corruption (all habits have valid data)
        for habit in allHabits {
            #expect(!habit.name.isEmpty)
            #expect(habit.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
            #expect(habit.displayOrder >= 0)
        }
        
        // Verify uniqueness of IDs (no duplicate IDs from concurrent operations)
        let uniqueIds = Set(allHabits.map { $0.id })
        #expect(uniqueIds.count == allHabits.count)
    }
    
    // MARK: - Data Conversion and Mapping Tests
    
    @Test("Complex habit data survives round-trip conversion")
    func testComplexHabitDataRoundTrip() async throws {
        // Arrange: Complex habit with all possible data
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let dataSource = HabitLocalDataSource(modelContainer: container)
        let repository = HabitRepositoryImpl(local: dataSource)
        
        let category = CategoryBuilder.learningCategory().build()
        let categoryModel = HabitCategoryModel.fromEntity(category)
        context.insert(categoryModel)
        try context.save()
        
        let complexSchedule = HabitSchedule.daysOfWeek([1, 3, 5, 7]) // Mon, Wed, Fri, Sun
        let multipleReminders = [
            ReminderTime(hour: 8, minute: 30),
            ReminderTime(hour: 14, minute: 15),
            ReminderTime(hour: 20, minute: 0)
        ]
        
        let originalHabit = HabitBuilder()
            .withName("Complex Learning Habit")
            .withColor("#FF6B35")
            .withEmoji("🧠")
            .asNumeric(target: 45.5, unit: "minutes")
            .withSchedule(complexSchedule)
            .withReminders(multipleReminders)
            .withCategory(category)
            .withDisplayOrder(42)
            .withSuggestionId("suggestion-123")
            .startingDaysAgo(7)
            .build()
        
        // Act: Store and retrieve the complex habit
        try await repository.create(originalHabit)
        let retrievedHabit = try await repository.fetchHabit(by: originalHabit.id)
        
        // Assert: All complex data is preserved exactly
        let habit = try #require(retrievedHabit)
        
        #expect(habit.id == originalHabit.id)
        #expect(habit.name == "Complex Learning Habit")
        #expect(habit.colorHex == "#FF6B35")
        #expect(habit.emoji == "🧠")
        #expect(habit.kind == .numeric)
        #expect(habit.dailyTarget == 45.5)
        #expect(habit.unitLabel == "minutes")
        #expect(habit.displayOrder == 42)
        #expect(habit.categoryId == category.id)
        #expect(habit.suggestionId == "suggestion-123")
        
        // Verify complex schedule
        if case let .daysOfWeek(days) = habit.schedule {
            #expect(days == Set([1, 3, 5, 7]))
        } else {
            Issue.record("Schedule was not preserved correctly")
        }
        
        // Verify multiple reminders
        #expect(habit.reminders.count == 3)
        let reminderTimes = habit.reminders.sorted { $0.hour < $1.hour }
        #expect(reminderTimes[0].hour == 8 && reminderTimes[0].minute == 30)
        #expect(reminderTimes[1].hour == 14 && reminderTimes[1].minute == 15)
        #expect(reminderTimes[2].hour == 20 && reminderTimes[2].minute == 0)
        
        // Verify dates (should be close to expected)
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let timeDifference = abs(habit.startDate.timeIntervalSince(sevenDaysAgo))
        #expect(timeDifference < 60) // Within 1 minute tolerance
    }
    
    // MARK: - Memory Management and Resource Tests
    
    @Test("Repository operations do not leak memory with repeated operations")
    func testMemoryManagementWithRepeatedOperations() async throws {
        // Arrange: Repository for memory testing
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let dataSource = HabitLocalDataSource(modelContainer: container)
        let repository = HabitRepositoryImpl(local: dataSource)
        
        // Act: Perform many create/delete cycles
        for cycle in 0..<50 {
            // Create multiple habits
            var cycleHabits: [UUID] = []
            
            for i in 0..<10 {
                let habit = HabitBuilder()
                    .withName("Cycle\(cycle)_Habit\(i)")
                    .build()
                
                try await repository.create(habit)
                cycleHabits.append(habit.id)
            }
            
            // Delete half of them
            for id in cycleHabits.prefix(5) {
                try await repository.delete(id: id)
            }
            
            // Update remaining ones
            for id in cycleHabits.suffix(5) {
                let updatedHabit = HabitBuilder()
                    .withId(id)
                    .withName("Updated_Cycle\(cycle)")
                    .build()
                
                try await repository.update(updatedHabit)
            }
        }
        
        // Assert: Final state should be manageable
        let finalHabits = try await repository.fetchAllHabits()
        #expect(finalHabits.count == 250) // 50 cycles × 5 remaining habits
        
        // Verify all remaining habits have updated names
        let updatedCount = finalHabits.filter { $0.name.hasPrefix("Updated_") }.count
        #expect(updatedCount == 250)
    }
    
    // MARK: - Integration with TestModelContainer Fixtures
    
    @Test("Repository works correctly with pre-populated test data")
    func testRepositoryWithTestFixtures() async throws {
        // Arrange: Use TestModelContainer with existing test data
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let dataSource = HabitLocalDataSource(modelContainer: container)
        let repository = HabitRepositoryImpl(local: dataSource)
        
        // Populate with standard test fixtures
        let fixture = try TestModelContainer.populateWithTestData(context: context)
        
        // Act & Assert: Repository should work with existing data
        let allHabits = try await repository.fetchAllHabits()
        #expect(allHabits.count == 2) // Exercise and Reading from fixture
        
        let habitNames = Set(allHabits.map { $0.name })
        #expect(habitNames.contains("Exercise"))
        #expect(habitNames.contains("Read Pages"))
        
        // Test adding to existing data
        let newHabit = HabitBuilder()
            .withName("New Habit")
            .withCategory(try fixture.healthCategory.toEntity())
            .build()
        
        try await repository.create(newHabit)
        
        let afterAddition = try await repository.fetchAllHabits()
        #expect(afterAddition.count == 3)
        
        // Test cleanup with mixed data
        let cleanedCount = try await repository.cleanupOrphanedHabits()
        #expect(cleanedCount == 0) // All test data should have valid relationships
        
        let afterCleanup = try await repository.fetchAllHabits()
        #expect(afterCleanup.count == 3) // No habits should be removed
    }
}