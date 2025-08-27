//
//  OverviewViewModelSimpleTests.swift
//  RitualistTests
//
//  Created by Claude on 27.08.2025.
//

import Testing
import Foundation
import SwiftData
@testable import Ritualist
@testable import RitualistCore

/// Simple, clean tests for OverviewViewModel using real implementations
/// This demonstrates the CORRECT testing approach:
/// - Use real UseCase implementations with TestModelContainer
/// - Set up test data in the database instead of mocks
/// - Test actual business logic flow
@Suite("OverviewViewModel Clean Tests")
@MainActor
final class OverviewViewModelSimpleTests {
    
    // MARK: - Test Infrastructure
    
    private var testContainer: ModelContainer!
    private var testContext: ModelContext!
    
    init() async throws {
        // Set up test infrastructure with real database
        let (container, context) = try TestModelContainer.createContainerAndContext()
        testContainer = container
        testContext = context
    }
    
    deinit {
        // Clean up is handled by TestModelContainer
    }
    
    // MARK: - Helper Methods
    
    private func createViewModel() -> OverviewViewModel {
        // Use real ViewModel with real UseCase implementations
        return OverviewViewModel()
    }
    
    private func setupTestHabitsWithLogs() async throws -> [HabitModel] {
        // Create test habits using builders
        let dailyHabit = HabitModelBuilder()
            .with(name: "Daily Exercise")
            .with(schedule: .daily)
            .with(isActive: true)
            .build()
        
        let weeklyHabit = HabitModelBuilder()
            .with(name: "Weekly Review")
            .with(schedule: .timesPerWeek(3))
            .with(isActive: true)
            .build()
        
        // Insert into test database
        testContext.insert(dailyHabit)
        testContext.insert(weeklyHabit)
        
        // Create logs for recent dates
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let todayLog = LogModelBuilder()
            .with(habitID: dailyHabit.id)
            .with(date: today)
            .with(value: 1.0)
            .build()
            
        let yesterdayLog = LogModelBuilder()
            .with(habitID: dailyHabit.id)
            .with(date: yesterday)
            .with(value: 1.0)
            .build()
        
        testContext.insert(todayLog)
        testContext.insert(yesterdayLog)
        
        try testContext.save()
        return [dailyHabit, weeklyHabit]
    }
    
    // MARK: - Tests
    
    @Test("ViewModel initializes correctly")
    func testViewModelInitialization() async throws {
        let vm = createViewModel()
        
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
        #expect(vm.todaysSummary == nil) // Not loaded yet
        #expect(vm.overviewData == nil) // Not loaded yet
    }
    
    @Test("loadData() loads real data from database")
    func testLoadDataWithRealData() async throws {
        // Arrange: Set up real test data in database
        let testHabits = try await setupTestHabitsWithLogs()
        let vm = createViewModel()
        
        // Act: Load data using real UseCase implementations
        await vm.loadData()
        
        // Assert: Verify real data was loaded
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
        #expect(vm.overviewData != nil)
        
        // Verify actual data from database
        if let overviewData = vm.overviewData {
            #expect(overviewData.habits.count >= testHabits.count)
            
            // Check that our test habits are present
            let habitNames = overviewData.habits.map { $0.name }
            #expect(habitNames.contains("Daily Exercise"))
            #expect(habitNames.contains("Weekly Review"))
        }
    }
    
    @Test("loadData() handles empty database correctly")
    func testLoadDataWithEmptyDatabase() async throws {
        let vm = createViewModel()
        
        // Act: Load data from empty database
        await vm.loadData()
        
        // Assert: Should complete without error
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
        #expect(vm.overviewData != nil)
        #expect(vm.overviewData?.habits.isEmpty == true)
    }
    
    @Test("completeHabit() creates real log in database")
    func testCompleteHabitCreatesRealLog() async throws {
        // Arrange: Set up test habit
        let testHabits = try await setupTestHabitsWithLogs()
        let vm = createViewModel()
        await vm.loadData()
        
        guard let habit = testHabits.first else {
            throw TestError.dataSetupFailed
        }
        
        // Act: Complete habit using real UseCase
        try await vm.completeHabit(habit.toDomain(), date: Date())
        
        // Assert: Verify log was created in database
        let descriptor = FetchDescriptor<LogModel>(
            predicate: #Predicate<LogModel> { log in
                log.habitID == habit.id
            }
        )
        let logs = try testContext.fetch(descriptor)
        #expect(logs.count > 2) // We had 2 initial logs, now should have more
    }
}

// MARK: - Test Errors

enum TestError: Error {
    case dataSetupFailed
}

// MARK: - Domain Conversion Extensions

extension HabitModel {
    func toDomain() -> Habit {
        return Habit(
            id: self.id,
            name: self.name,
            emoji: self.emoji,
            dailyTarget: self.dailyTarget,
            kind: HabitKind(rawValue: self.kind) ?? .binary,
            schedule: HabitSchedule.daily, // Simplified for testing
            categoryId: self.categoryId,
            position: Int(self.position),
            reminderTimes: [],
            isActive: self.isActive,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
    }
}