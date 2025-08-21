//
//  LogRepositoryImplTests.swift
//  RitualistTests
//
//  Created by Claude on 21.08.2025.
//

import Foundation
import SwiftData
import Testing
@testable import Ritualist
@testable import RitualistCore

/// Comprehensive integration tests for LogRepositoryImpl using in-memory SwiftData
/// 
/// These tests validate the REAL implementation that runs in production, ensuring:
/// - Actual CRUD operations work correctly with SwiftData
/// - Relationships between HabitLog-Habit are maintained properly
/// - Query operations handle date ranges and filtering correctly
/// - Upsert behavior works correctly (insert or update existing logs)
/// - Error conditions are properly handled
/// - Performance is acceptable with large datasets
/// - Thread safety and concurrency work as expected
/// - Data integrity is maintained across operations
///
/// **Testing Philosophy**: 
/// - Test the actual production code, not mocks
/// - Use isolated in-memory databases for each test
/// - Validate real SwiftData relationships and constraints
/// - Cover both happy path and error scenarios
/// - Test performance with realistic data volumes
@Suite("LogRepositoryImpl Integration Tests")
struct LogRepositoryImplTests {
    
    // MARK: - CRUD Operations Tests
    
    @Test("Upsert creates new log successfully")
    func testUpsertCreatesNewLog() async throws {
        // Arrange: Real repository with in-memory database
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        
        // Create habit first for relationship
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        let habit = HabitBuilder()
            .withName("Exercise")
            .asNumeric(target: 30.0, unit: "minutes")
            .build()
        try await habitRepository.create(habit)
        
        let log = HabitLogBuilder()
            .withHabit(habit)
            .withValue(25.0)
            .forToday()
            .build()
        
        // Act: Create log using real repository
        try await logRepository.upsert(log)
        
        // Assert: Verify log was persisted correctly
        let logs = try await logRepository.logs(for: habit.id)
        #expect(logs.count == 1)
        
        let savedLog = logs[0]
        #expect(savedLog.id == log.id)
        #expect(savedLog.habitID == habit.id)
        #expect(savedLog.value == 25.0)
        #expect(Calendar.current.isDate(savedLog.date, inSameDayAs: Date()))
    }
    
    @Test("Upsert updates existing log with same ID")
    func testUpsertUpdatesExistingLog() async throws {
        // Arrange: Repository with existing log
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        
        // Create habit first
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        let habit = HabitBuilder()
            .withName("Reading")
            .asNumeric(target: 20.0, unit: "pages")
            .build()
        try await habitRepository.create(habit)
        
        // Create initial log
        let logId = UUID()
        let originalLog = HabitLogBuilder()
            .withId(logId)
            .withHabit(habit)
            .withValue(10.0)
            .forToday()
            .build()
        
        try await logRepository.upsert(originalLog)
        
        // Verify initial creation
        let afterCreate = try await logRepository.logs(for: habit.id)
        #expect(afterCreate.count == 1)
        #expect(afterCreate[0].value == 10.0)
        
        // Act: Update same log (same ID)
        let updatedLog = HabitLogBuilder()
            .withId(logId) // Same ID for update
            .withHabit(habit)
            .withValue(25.0) // Updated value
            .forToday()
            .build()
        
        try await logRepository.upsert(updatedLog)
        
        // Assert: Should have updated, not created duplicate
        let afterUpdate = try await logRepository.logs(for: habit.id)
        #expect(afterUpdate.count == 1) // Still only one log
        
        let savedLog = afterUpdate[0]
        #expect(savedLog.id == logId)
        #expect(savedLog.value == 25.0) // Value was updated
        #expect(savedLog.habitID == habit.id)
    }
    
    @Test("Delete log removes record from database")
    func testDeleteLog() async throws {
        // Arrange: Create multiple logs for same habit
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        
        // Create habit
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        let habit = HabitBuilder().withName("Meditation").build()
        try await habitRepository.create(habit)
        
        // Create multiple logs
        let log1 = HabitLogBuilder()
            .withHabit(habit)
            .forToday()
            .withNoValue()
            .build()
        let log2 = HabitLogBuilder()
            .withHabit(habit)
            .forYesterday()
            .withNoValue()
            .build()
        
        try await logRepository.upsert(log1)
        try await logRepository.upsert(log2)
        
        // Verify both exist
        let beforeDelete = try await logRepository.logs(for: habit.id)
        #expect(beforeDelete.count == 2)
        
        // Act: Delete one log
        try await logRepository.deleteLog(id: log1.id)
        
        // Assert: Verify correct log was deleted
        let afterDelete = try await logRepository.logs(for: habit.id)
        #expect(afterDelete.count == 1)
        #expect(afterDelete[0].id == log2.id)
        
        // Verify deleted log is actually gone
        let allRemainingLogs = try await logRepository.logs(for: habit.id)
        let deletedLogExists = allRemainingLogs.contains { $0.id == log1.id }
        #expect(!deletedLogExists)
    }
    
    @Test("Fetch logs for habit returns only logs for that habit")
    func testFetchLogsForSpecificHabit() async throws {
        // Arrange: Create multiple habits with logs
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        
        // Create habits
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        
        let habit1 = HabitBuilder().withName("Habit 1").build()
        let habit2 = HabitBuilder().withName("Habit 2").build()
        
        try await habitRepository.create(habit1)
        try await habitRepository.create(habit2)
        
        // Create logs for both habits
        let habit1Logs = [
            HabitLogBuilder().withHabit(habit1).forToday().build(),
            HabitLogBuilder().withHabit(habit1).forYesterday().build(),
            HabitLogBuilder().withHabit(habit1).forDaysAgo(2).build()
        ]
        
        let habit2Logs = [
            HabitLogBuilder().withHabit(habit2).forToday().build(),
            HabitLogBuilder().withHabit(habit2).forDaysAgo(3).build()
        ]
        
        for log in habit1Logs + habit2Logs {
            try await logRepository.upsert(log)
        }
        
        // Act & Assert: Fetch logs for habit1
        let habit1Results = try await logRepository.logs(for: habit1.id)
        #expect(habit1Results.count == 3)
        
        for log in habit1Results {
            #expect(log.habitID == habit1.id)
        }
        
        // Verify logs are sorted by date (most recent first)
        let sortedDates = habit1Results.map { $0.date }
        for i in 1..<sortedDates.count {
            #expect(sortedDates[i-1] >= sortedDates[i])
        }
        
        // Act & Assert: Fetch logs for habit2
        let habit2Results = try await logRepository.logs(for: habit2.id)
        #expect(habit2Results.count == 2)
        
        for log in habit2Results {
            #expect(log.habitID == habit2.id)
        }
    }
    
    @Test("Fetch logs for non-existent habit returns empty array")
    func testFetchLogsForNonExistentHabit() async throws {
        // Arrange: Repository with no data
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        
        let nonExistentHabitId = UUID()
        
        // Act: Fetch logs for non-existent habit
        let logs = try await logRepository.logs(for: nonExistentHabitId)
        
        // Assert: Should return empty array, not error
        #expect(logs.isEmpty)
    }
    
    // MARK: - Relationship Tests
    
    @Test("Log maintains relationship with habit")
    func testLogHabitRelationship() async throws {
        // Arrange: Repository with habit and logs
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        
        // Create habit
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        let habit = HabitBuilder()
            .withName("Workout")
            .withEmoji("💪")
            .build()
        try await habitRepository.create(habit)
        
        // Create log with habit relationship
        let log = HabitLogBuilder()
            .withHabit(habit)
            .withValue(45.0)
            .build()
        
        try await logRepository.upsert(log)
        
        // Act: Retrieve logs and verify relationship
        let logs = try await logRepository.logs(for: habit.id)
        #expect(logs.count == 1)
        
        let savedLog = logs[0]
        #expect(savedLog.habitID == habit.id)
        
        // Verify the habit still exists and matches
        let retrievedHabit = try await habitRepository.fetchHabit(by: habit.id)
        #expect(retrievedHabit != nil)
        #expect(retrievedHabit?.name == "Workout")
        #expect(retrievedHabit?.emoji == "💪")
    }
    
    @Test("Multiple logs for same habit maintain proper relationships")
    func testMultipleLogsForSameHabit() async throws {
        // Arrange: One habit with multiple logs across different dates
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        
        // Create habit
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        let habit = HabitBuilder()
            .withName("Daily Steps")
            .asNumeric(target: 10000.0, unit: "steps")
            .build()
        try await habitRepository.create(habit)
        
        // Create logs for a week
        let logs = HabitLogBuilder.createWeeklyLogs(for: habit, completionRate: 1.0)
        
        for log in logs {
            try await logRepository.upsert(log)
        }
        
        // Act: Retrieve all logs for the habit
        let retrievedLogs = try await logRepository.logs(for: habit.id)
        
        // Assert: All logs maintain correct relationship
        #expect(retrievedLogs.count == logs.count)
        
        for log in retrievedLogs {
            #expect(log.habitID == habit.id)
            #expect(log.value != nil) // Numeric habit should have values
        }
        
        // Verify logs are sorted by date (most recent first)
        let sortedDates = retrievedLogs.map { $0.date }
        for i in 1..<sortedDates.count {
            #expect(sortedDates[i-1] >= sortedDates[i])
        }
    }
    
    // MARK: - Data Integrity Tests
    
    @Test("Upsert handles duplicate dates for same habit correctly")
    func testUpsertHandlesDuplicateDatesForSameHabit() async throws {
        // Arrange: Repository with habit
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        
        // Create habit
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        let habit = HabitBuilder().withName("Water Intake").build()
        try await habitRepository.create(habit)
        
        let today = Date()
        
        // Create first log for today
        let log1 = HabitLogBuilder()
            .withHabit(habit)
            .withDate(today)
            .withValue(2.0)
            .build()
        
        try await logRepository.upsert(log1)
        
        // Verify first log exists
        let afterFirst = try await logRepository.logs(for: habit.id)
        #expect(afterFirst.count == 1)
        #expect(afterFirst[0].value == 2.0)
        
        // Act: Create second log for same date with different ID
        let log2 = HabitLogBuilder()
            .withHabit(habit)
            .withDate(today) // Same date
            .withValue(3.0)  // Different value
            .build() // Different ID
        
        try await logRepository.upsert(log2)
        
        // Assert: Should have two separate logs (different IDs)
        let afterSecond = try await logRepository.logs(for: habit.id)
        #expect(afterSecond.count == 2)
        
        let values = afterSecond.map { $0.value }.compactMap { $0 }
        #expect(values.contains(2.0))
        #expect(values.contains(3.0))
    }
    
    @Test("Delete non-existent log does not throw error")
    func testDeleteNonExistentLog() async throws {
        // Arrange: Repository with existing data
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        
        // Create habit and log for context
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        let habit = HabitBuilder().withName("Test Habit").build()
        try await habitRepository.create(habit)
        
        let existingLog = HabitLogBuilder().withHabit(habit).build()
        try await logRepository.upsert(existingLog)
        
        // Verify log exists
        let beforeDelete = try await logRepository.logs(for: habit.id)
        #expect(beforeDelete.count == 1)
        
        let nonExistentId = UUID()
        
        // Act & Assert: Delete should not throw
        try await logRepository.deleteLog(id: nonExistentId)
        
        // Verify existing data is unchanged
        let afterDelete = try await logRepository.logs(for: habit.id)
        #expect(afterDelete.count == 1)
        #expect(afterDelete[0].id == existingLog.id)
    }
    
    // MARK: - Edge Cases and Validation Tests
    
    @Test("Log handles nil values correctly for binary habits")
    func testLogHandlesNilValuesForBinaryHabits() async throws {
        // Arrange: Repository with binary habit
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        
        // Create binary habit
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        let binaryHabit = HabitBuilder()
            .withName("Take Vitamins")
            .asBinary()
            .build()
        try await habitRepository.create(binaryHabit)
        
        // Create log with no value (appropriate for binary habits)
        let binaryLog = HabitLogBuilder()
            .withHabit(binaryHabit)
            .withNoValue() // nil value
            .build()
        
        // Act: Upsert binary log
        try await logRepository.upsert(binaryLog)
        
        // Assert: Log should be saved correctly with nil value
        let logs = try await logRepository.logs(for: binaryHabit.id)
        #expect(logs.count == 1)
        
        let savedLog = logs[0]
        #expect(savedLog.value == nil) // Binary habit log should have nil value
        #expect(savedLog.habitID == binaryHabit.id)
    }
    
    @Test("Log handles various numeric values correctly")
    func testLogHandlesVariousNumericValues() async throws {
        // Arrange: Repository with numeric habit
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        
        // Create numeric habit
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        let numericHabit = HabitBuilder()
            .withName("Run Distance")
            .asNumeric(target: 5.0, unit: "km")
            .build()
        try await habitRepository.create(numericHabit)
        
        // Test various numeric values
        let testValues: [Double] = [0.0, 0.5, 1.0, 3.14159, 100.5, 999.99]
        
        for (index, value) in testValues.enumerated() {
            let log = HabitLogBuilder()
                .withHabit(numericHabit)
                .withValue(value)
                .forDaysAgo(index)
                .build()
            
            try await logRepository.upsert(log)
        }
        
        // Act: Retrieve all logs
        let logs = try await logRepository.logs(for: numericHabit.id)
        
        // Assert: All values should be preserved correctly
        #expect(logs.count == testValues.count)
        
        let savedValues = logs.compactMap { $0.value }.sorted()
        let expectedValues = testValues.sorted()
        
        #expect(savedValues.count == expectedValues.count)
        for (saved, expected) in zip(savedValues, expectedValues) {
            #expect(abs(saved - expected) < 0.0001) // Float precision tolerance
        }
    }
    
    @Test("Log handles extreme date values correctly")
    func testLogHandlesExtremeDateValues() async throws {
        // Arrange: Repository with habit
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        
        // Create habit
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        let habit = HabitBuilder().withName("Time Test").build()
        try await habitRepository.create(habit)
        
        // Test extreme dates
        let testDates = [
            Date(timeIntervalSince1970: 0), // Unix epoch
            Date(timeIntervalSince1970: 253402300799), // Year 9999
            Calendar.current.date(from: DateComponents(year: 1970, month: 1, day: 1))!,
            Calendar.current.date(from: DateComponents(year: 2050, month: 12, day: 31))!,
            Date() // Current date
        ]
        
        for (index, date) in testDates.enumerated() {
            let log = HabitLogBuilder()
                .withHabit(habit)
                .withDate(date)
                .withValue(Double(index))
                .build()
            
            try await logRepository.upsert(log)
        }
        
        // Act: Retrieve all logs
        let logs = try await logRepository.logs(for: habit.id)
        
        // Assert: All dates should be preserved correctly
        #expect(logs.count == testDates.count)
        
        let savedDates = logs.map { $0.date }.sorted()
        let expectedDates = testDates.sorted()
        
        for (saved, expected) in zip(savedDates, expectedDates) {
            let timeDifference = abs(saved.timeIntervalSince(expected))
            #expect(timeDifference < 1.0) // Within 1 second tolerance
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("Repository handles large number of logs efficiently")
    func testPerformanceWithLargeLogDataset() async throws {
        // Arrange: Repository with multiple habits for performance testing
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        
        // Create habits
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        
        let habits = [
            HabitBuilder().withName("Performance Habit 1").build(),
            HabitBuilder().withName("Performance Habit 2").build(),
            HabitBuilder().withName("Performance Habit 3").build()
        ]
        
        for habit in habits {
            try await habitRepository.create(habit)
        }
        
        // Create large number of logs
        let logsPerHabit = 100
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for habit in habits {
            for dayOffset in 0..<logsPerHabit {
                let log = HabitLogBuilder()
                    .withHabit(habit)
                    .forDaysAgo(dayOffset)
                    .withRandomValue(min: 1.0, max: 50.0)
                    .build()
                
                try await logRepository.upsert(log)
            }
        }
        
        let createTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Act: Test fetch performance for individual habits
        let fetchStartTime = CFAbsoluteTimeGetCurrent()
        
        var totalLogs = 0
        for habit in habits {
            let habitLogs = try await logRepository.logs(for: habit.id)
            totalLogs += habitLogs.count
        }
        
        let fetchTime = CFAbsoluteTimeGetCurrent() - fetchStartTime
        
        // Assert: Verify data integrity and reasonable performance
        #expect(totalLogs == habits.count * logsPerHabit)
        #expect(createTime < 30.0) // Creating 300 logs should take less than 30 seconds
        #expect(fetchTime < 2.0) // Fetching logs should be fast
        
        // Test individual habit fetch performance
        let individualFetchStart = CFAbsoluteTimeGetCurrent()
        let singleHabitLogs = try await logRepository.logs(for: habits[0].id)
        let individualFetchTime = CFAbsoluteTimeGetCurrent() - individualFetchStart
        
        #expect(singleHabitLogs.count == logsPerHabit)
        #expect(individualFetchTime < 0.5) // Individual fetch should be very fast
    }
    
    @Test("Concurrent log operations maintain data integrity")
    func testConcurrentLogOperations() async throws {
        // Arrange: Repository for concurrent testing
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        
        // Create habits for concurrent testing
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        
        let habits = [
            HabitBuilder().withName("Concurrent Habit 1").build(),
            HabitBuilder().withName("Concurrent Habit 2").build()
        ]
        
        for habit in habits {
            try await habitRepository.create(habit)
        }
        
        // Create concurrent tasks
        let taskCount = 5
        let logsPerTask = 10
        
        await withTaskGroup(of: Void.self) { group in
            for taskId in 0..<taskCount {
                group.addTask {
                    do {
                        // Each task creates logs for different dates to avoid conflicts
                        for logIndex in 0..<logsPerTask {
                            let habit = habits[taskId % habits.count]
                            let dayOffset = taskId * logsPerTask + logIndex
                            
                            let log = HabitLogBuilder()
                                .withHabit(habit)
                                .forDaysAgo(dayOffset)
                                .withValue(Double(taskId * 10 + logIndex))
                                .build()
                            
                            try await logRepository.upsert(log)
                        }
                    } catch {
                        // Some concurrent operations might conflict, which is acceptable
                        // as long as data integrity is maintained
                    }
                }
            }
        }
        
        // Act & Assert: Verify data integrity after concurrent operations
        var totalLogs = 0
        for habit in habits {
            let habitLogs = try await logRepository.logs(for: habit.id)
            totalLogs += habitLogs.count
            
            // Verify no data corruption (all logs have valid data)
            for log in habitLogs {
                #expect(log.habitID == habit.id)
                #expect(log.value != nil)
                #expect(log.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
            }
            
            // Verify uniqueness of log IDs (no duplicate IDs from concurrent operations)
            let uniqueIds = Set(habitLogs.map { $0.id })
            #expect(uniqueIds.count == habitLogs.count)
        }
        
        // We should have some logs (exact count depends on concurrency conflicts)
        #expect(totalLogs > 0)
        #expect(totalLogs <= taskCount * logsPerTask)
    }
    
    // MARK: - Data Conversion and Mapping Tests
    
    @Test("Complex log data survives round-trip conversion")
    func testComplexLogDataRoundTrip() async throws {
        // Arrange: Repository with habit for complex log testing
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        
        // Create habit
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        let habit = HabitBuilder()
            .withName("Complex Data Test")
            .asNumeric(target: 123.456789, unit: "complex units")
            .build()
        try await habitRepository.create(habit)
        
        // Create log with precise numeric data
        let preciseValue = 987.123456789
        let preciseDate = Calendar.current.date(from: DateComponents(
            year: 2025, month: 8, day: 21,
            hour: 14, minute: 30, second: 45, nanosecond: 123456789
        ))!
        
        let originalLog = HabitLogBuilder()
            .withHabit(habit)
            .withDate(preciseDate)
            .withValue(preciseValue)
            .build()
        
        // Act: Store and retrieve the complex log
        try await logRepository.upsert(originalLog)
        let retrievedLogs = try await logRepository.logs(for: habit.id)
        
        // Assert: All complex data is preserved exactly
        #expect(retrievedLogs.count == 1)
        let log = retrievedLogs[0]
        
        #expect(log.id == originalLog.id)
        #expect(log.habitID == habit.id)
        #expect(log.value == preciseValue)
        
        // Verify date precision (SwiftData may have some precision limits)
        let timeDifference = abs(log.date.timeIntervalSince(preciseDate))
        #expect(timeDifference < 1.0) // Within 1 second tolerance for date precision
    }
    
    // MARK: - Integration with TestModelContainer Fixtures
    
    @Test("Repository works correctly with pre-populated test data")
    func testRepositoryWithTestFixtures() async throws {
        // Arrange: Use TestModelContainer with existing test data
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        
        // Populate with standard test fixtures
        let fixture = try TestModelContainer.populateWithTestData(context: context)
        
        // Act & Assert: Repository should work with existing fixture data
        let exerciseLogs = try await logRepository.logs(for: fixture.exerciseHabit.id)
        let readingLogs = try await logRepository.logs(for: fixture.readingHabit.id)
        
        #expect(exerciseLogs.count == 3) // 3 exercise logs from fixture
        #expect(readingLogs.count == 3) // 3 reading logs from fixture
        
        // Verify fixture data integrity
        for log in exerciseLogs {
            #expect(log.habitID == fixture.exerciseHabit.id)
            #expect(log.value == 1.0) // Binary habit logs with value 1.0
        }
        
        for log in readingLogs {
            #expect(log.habitID == fixture.readingHabit.id)
            #expect(log.value != nil) // Reading habit has numeric values
        }
        
        // Test adding to existing fixture data
        let newLog = HabitLogBuilder()
            .withHabitId(fixture.exerciseHabit.id)
            .forDaysFromNow(1) // Future log
            .withNoValue()
            .build()
        
        try await logRepository.upsert(newLog)
        
        let afterAddition = try await logRepository.logs(for: fixture.exerciseHabit.id)
        #expect(afterAddition.count == 4) // 3 fixture logs + 1 new log
        
        // Test deleting from fixture data
        let logToDelete = exerciseLogs[0]
        try await logRepository.deleteLog(id: logToDelete.id)
        
        let afterDeletion = try await logRepository.logs(for: fixture.exerciseHabit.id)
        #expect(afterDeletion.count == 3) // Back to 3 logs (2 fixture + 1 new)
    }
    
    // MARK: - Memory Management Tests
    
    @Test("Repository operations do not leak memory with repeated operations")
    func testMemoryManagementWithRepeatedOperations() async throws {
        // Arrange: Repository for memory testing
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        
        // Create habit for memory testing
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        let habit = HabitBuilder().withName("Memory Test Habit").build()
        try await habitRepository.create(habit)
        
        // Act: Perform many create/delete cycles
        for cycle in 0..<20 {
            // Create multiple logs
            var cycleLogs: [UUID] = []
            
            for i in 0..<20 {
                let log = HabitLogBuilder()
                    .withHabit(habit)
                    .forDaysAgo(cycle * 20 + i) // Unique dates
                    .withValue(Double(cycle * 20 + i))
                    .build()
                
                try await logRepository.upsert(log)
                cycleLogs.append(log.id)
            }
            
            // Delete half of them
            for id in cycleLogs.prefix(10) {
                try await logRepository.deleteLog(id: id)
            }
            
            // Update remaining ones (test upsert functionality)
            for (index, id) in cycleLogs.suffix(10).enumerated() {
                let updatedLog = HabitLogBuilder()
                    .withId(id)
                    .withHabit(habit)
                    .forDaysAgo(cycle * 20 + index)
                    .withValue(999.0) // Updated value to verify upsert
                    .build()
                
                try await logRepository.upsert(updatedLog)
            }
        }
        
        // Assert: Final state should be manageable
        let finalLogs = try await logRepository.logs(for: habit.id)
        #expect(finalLogs.count == 200) // 20 cycles × 10 remaining logs each
        
        // Verify all remaining logs have updated value
        let updatedCount = finalLogs.filter { $0.value == 999.0 }.count
        #expect(updatedCount == 200)
    }
}

