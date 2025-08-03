//
//  StreakEngineTests.swift
//  Ritualist
//
//  Created by Claude on 03.08.2025.
//

import Testing
import Foundation
@testable import Ritualist

@Suite("StreakEngine Tests")
struct StreakEngineTests {
    
    private let calendar = Calendar(identifier: .gregorian)
    
    // MARK: - Test Data Helpers
    
    private func createTestDate(year: Int = 2025, month: Int = 1, day: Int) -> Date {
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
    
    private func createBinaryHabit() -> Habit {
        return Habit(
            id: UUID(),
            name: "Test Binary Habit",
            colorHex: "#FF0000",
            kind: .binary,
            schedule: .daily,
            isActive: true
        )
    }
    
    private func createNumericHabit(target: Double = 8.0) -> Habit {
        return Habit(
            id: UUID(),
            name: "Test Numeric Habit",
            colorHex: "#00FF00", 
            kind: .numeric,
            dailyTarget: target,
            schedule: .daily,
            isActive: true
        )
    }
    
    private func createHabitLog(date: Date, value: Double = 1.0) -> HabitLog {
        return HabitLog(
            id: UUID(),
            habitID: UUID(),
            date: date,
            value: value
        )
    }
    
    // MARK: - Current Streak Tests - Binary Habits
    
    @Test("Current streak returns zero when no logs exist")
    func currentStreak_whenNoDays_thenReturnsZero() {
        // Arrange
        let habit = createBinaryHabit()
        let logs: [HabitLog] = []
        let today = createTestDate(day: 10)
        let mockDateProvider = MockDateProvider()
        mockDateProvider.startOfDayReturnValue = today
        let streakEngine = DefaultStreakEngine(dateProvider: mockDateProvider)
        
        // Act
        let result = streakEngine.currentStreak(for: habit, logs: logs, asOf: today)
        
        // Assert
        #expect(result == 0, "Should return 0 when no logs exist")
    }
    
    @Test("Current streak returns zero when today not completed")
    func currentStreak_whenTodayNotCompleted_thenReturnsZero() {
        // Arrange
        let habit = createBinaryHabit()
        let today = createTestDate(day: 10)
        let logs = [
            createHabitLog(date: createTestDate(day: 9)), // Yesterday completed
            createHabitLog(date: createTestDate(day: 8))  // Day before completed
        ]
        let mockDateProvider = MockDateProvider()
        mockDateProvider.startOfDayReturnValue = today
        let streakEngine = DefaultStreakEngine(dateProvider: mockDateProvider)
        
        // Act
        let result = streakEngine.currentStreak(for: habit, logs: logs, asOf: today)
        
        // Assert
        #expect(result == 0, "Should return 0 when today is not completed")
    }
    
    @Test("Current streak returns one when only today completed")
    func currentStreak_whenOnlyTodayCompleted_thenReturnsOne() {
        // Arrange
        let habit = createBinaryHabit()
        let today = createTestDate(day: 10)
        let logs = [
            createHabitLog(date: today) // Only today completed
        ]
        let mockDateProvider = MockDateProvider()
        mockDateProvider.startOfDayReturnValue = today
        let streakEngine = DefaultStreakEngine(dateProvider: mockDateProvider)
        
        // Act
        let result = streakEngine.currentStreak(for: habit, logs: logs, asOf: today)
        
        // Assert
        #expect(result == 1, "Should return 1 when only today is completed")
    }
    
    @Test("Current streak counts consecutive days from today backwards")
    func currentStreak_whenConsecutiveDaysFromToday_thenReturnsCorrectCount() {
        // Arrange
        let habit = createBinaryHabit()
        let today = createTestDate(day: 10)
        let logs = [
            createHabitLog(date: today),                 // Day 10 (today)
            createHabitLog(date: createTestDate(day: 9)), // Day 9
            createHabitLog(date: createTestDate(day: 8)), // Day 8
            createHabitLog(date: createTestDate(day: 7)), // Day 7
            // Gap at day 6
            createHabitLog(date: createTestDate(day: 5))  // Day 5 (shouldn't count)
        ]
        let mockDateProvider = MockDateProvider()
        mockDateProvider.startOfDayReturnValue = today
        let streakEngine = DefaultStreakEngine(dateProvider: mockDateProvider)
        
        // Act
        let result = streakEngine.currentStreak(for: habit, logs: logs, asOf: today)
        
        // Assert
        #expect(result == 4, "Should return 4 for consecutive days 7,8,9,10")
    }
    
    @Test("Current streak stops at gap in middle")
    func currentStreak_whenGapInMiddle_thenStopsAtGap() {
        // Arrange
        let habit = createBinaryHabit()
        let today = createTestDate(day: 10)
        let logs = [
            createHabitLog(date: today),                 // Day 10 (today)
            createHabitLog(date: createTestDate(day: 9)), // Day 9
            // Gap at day 8
            createHabitLog(date: createTestDate(day: 7)), // Day 7 (shouldn't count)
            createHabitLog(date: createTestDate(day: 6))  // Day 6 (shouldn't count)
        ]
        let mockDateProvider = MockDateProvider()
        mockDateProvider.startOfDayReturnValue = today
        let streakEngine = DefaultStreakEngine(dateProvider: mockDateProvider)
        
        // Act
        let result = streakEngine.currentStreak(for: habit, logs: logs, asOf: today)
        
        // Assert
        #expect(result == 2, "Should return 2 for days 9,10 (stops at gap on day 8)")
    }
    
    // MARK: - Current Streak Tests - Numeric Habits
    
    @Test("Current streak for numeric habit doesn't count when below target")
    func currentStreak_numericHabit_whenBelowTarget_thenDoesNotCount() {
        // Arrange
        let habit = createNumericHabit(target: 8.0)
        let today = createTestDate(day: 10)
        let logs = [
            createHabitLog(date: today, value: 5.0),     // Below target
            createHabitLog(date: createTestDate(day: 9), value: 10.0) // Above target
        ]
        let mockDateProvider = MockDateProvider()
        mockDateProvider.startOfDayReturnValue = today
        let streakEngine = DefaultStreakEngine(dateProvider: mockDateProvider)
        
        // Act
        let result = streakEngine.currentStreak(for: habit, logs: logs, asOf: today)
        
        // Assert
        #expect(result == 0, "Should return 0 when today's value is below target")
    }
    
    @Test("Current streak for numeric habit counts when at target")
    func currentStreak_numericHabit_whenAtTarget_thenCounts() {
        // Arrange
        let habit = createNumericHabit(target: 8.0)
        let today = createTestDate(day: 10)
        let logs = [
            createHabitLog(date: today, value: 8.0),     // Exactly at target
            createHabitLog(date: createTestDate(day: 9), value: 10.0) // Above target
        ]
        let mockDateProvider = MockDateProvider()
        mockDateProvider.startOfDayReturnValue = today
        let streakEngine = DefaultStreakEngine(dateProvider: mockDateProvider)
        
        // Act
        let result = streakEngine.currentStreak(for: habit, logs: logs, asOf: today)
        
        // Assert
        #expect(result == 2, "Should return 2 when values meet or exceed target")
    }
    
    // MARK: - Best Streak Tests
    
    @Test("Best streak returns zero when no logs exist")
    func bestStreak_whenNoDays_thenReturnsZero() {
        // Arrange
        let habit = createBinaryHabit()
        let logs: [HabitLog] = []
        let mockDateProvider = MockDateProvider()
        let streakEngine = DefaultStreakEngine(dateProvider: mockDateProvider)
        
        // Act
        let result = streakEngine.bestStreak(for: habit, logs: logs)
        
        // Assert
        #expect(result == 0, "Should return 0 when no logs exist")
    }
    
    @Test("Best streak returns one for single completed day")
    func bestStreak_whenSingleDay_thenReturnsOne() {
        // Arrange
        let habit = createBinaryHabit()
        let logs = [
            createHabitLog(date: createTestDate(day: 5))
        ]
        let mockDateProvider = MockDateProvider()
        let streakEngine = DefaultStreakEngine(dateProvider: mockDateProvider)
        
        // Act
        let result = streakEngine.bestStreak(for: habit, logs: logs)
        
        // Assert
        #expect(result == 1, "Should return 1 for single completed day")
    }
    
    @Test("Best streak returns longest streak among multiple streaks")
    func bestStreak_whenMultipleStreaks_thenReturnsLongest() {
        // Arrange
        let habit = createBinaryHabit()
        let logs = [
            // First streak: 3 days (1,2,3)
            createHabitLog(date: createTestDate(day: 1)),
            createHabitLog(date: createTestDate(day: 2)),
            createHabitLog(date: createTestDate(day: 3)),
            // Gap at day 4,5
            // Second streak: 4 days (6,7,8,9) - this should be the best
            createHabitLog(date: createTestDate(day: 6)),
            createHabitLog(date: createTestDate(day: 7)),
            createHabitLog(date: createTestDate(day: 8)),
            createHabitLog(date: createTestDate(day: 9)),
            // Gap at day 10
            // Third streak: 2 days (11,12)
            createHabitLog(date: createTestDate(day: 11)),
            createHabitLog(date: createTestDate(day: 12))
        ]
        let mockDateProvider = MockDateProvider()
        let streakEngine = DefaultStreakEngine(dateProvider: mockDateProvider)
        
        // Act
        let result = streakEngine.bestStreak(for: habit, logs: logs)
        
        // Assert
        #expect(result == 4, "Should return 4 for the longest streak (days 6-9)")
    }
    
    @Test("Best streak handles scattered days correctly")
    func bestStreak_whenScatteredDays_thenReturnsCorrectStreaks() {
        // Arrange
        let habit = createBinaryHabit()
        let logs = [
            createHabitLog(date: createTestDate(day: 1)),  // Single day
            // Gap
            createHabitLog(date: createTestDate(day: 5)),  // 2-day streak starts
            createHabitLog(date: createTestDate(day: 6)),  // 2-day streak ends
            // Gap
            createHabitLog(date: createTestDate(day: 10)), // Single day
        ]
        let mockDateProvider = MockDateProvider()
        let streakEngine = DefaultStreakEngine(dateProvider: mockDateProvider)
        
        // Act
        let result = streakEngine.bestStreak(for: habit, logs: logs)
        
        // Assert
        #expect(result == 2, "Should return 2 for the longest streak (days 5-6)")
    }
    
    @Test("Best streak for numeric habit only counts values at or above target")
    func bestStreak_numericHabit_onlyCountsValuesAtOrAboveTarget() {
        // Arrange
        let habit = createNumericHabit(target: 8.0)
        let logs = [
            createHabitLog(date: createTestDate(day: 1), value: 10.0), // Above target ✓
            createHabitLog(date: createTestDate(day: 2), value: 8.0),  // At target ✓
            createHabitLog(date: createTestDate(day: 3), value: 5.0),  // Below target ✗
            createHabitLog(date: createTestDate(day: 4), value: 9.0),  // Above target ✓
            createHabitLog(date: createTestDate(day: 5), value: 8.5)   // Above target ✓
        ]
        let mockDateProvider = MockDateProvider()
        let streakEngine = DefaultStreakEngine(dateProvider: mockDateProvider)
        
        // Act
        let result = streakEngine.bestStreak(for: habit, logs: logs)
        
        // Assert
        #expect(result == 2, "Should return 2 for consecutive days meeting target (days 1-2, gap on 3, then 4-5)")
    }
    
    // MARK: - Edge Cases
    
    @Test("Current streak handles duplicate dates correctly")
    func currentStreak_whenDuplicateDates_thenHandlesCorrectly() {
        // Arrange
        let habit = createBinaryHabit()
        let today = createTestDate(day: 10)
        let logs = [
            createHabitLog(date: today, value: 1.0),
            createHabitLog(date: today, value: 1.0), // Duplicate same day
            createHabitLog(date: createTestDate(day: 9), value: 1.0)
        ]
        let mockDateProvider = MockDateProvider()
        mockDateProvider.startOfDayReturnValue = today
        let streakEngine = DefaultStreakEngine(dateProvider: mockDateProvider)
        
        // Act
        let result = streakEngine.currentStreak(for: habit, logs: logs, asOf: today)
        
        // Assert
        #expect(result == 2, "Should handle duplicate dates correctly")
    }
    
    @Test("Best streak handles unordered logs correctly")
    func bestStreak_whenUnorderedLogs_thenHandlesCorrectly() {
        // Arrange
        let habit = createBinaryHabit()
        let logs = [
            createHabitLog(date: createTestDate(day: 3)), // Out of order
            createHabitLog(date: createTestDate(day: 1)),
            createHabitLog(date: createTestDate(day: 2))
        ]
        let mockDateProvider = MockDateProvider()
        let streakEngine = DefaultStreakEngine(dateProvider: mockDateProvider)
        
        // Act
        let result = streakEngine.bestStreak(for: habit, logs: logs)
        
        // Assert
        #expect(result == 3, "Should handle unordered logs correctly")
    }
}

// MARK: - Mock DateProvider

class MockDateProvider: DateProvider {
    var startOfDayReturnValue: Date?
    var nowReturnValue: Date = Date()
    
    var now: Date {
        return nowReturnValue
    }
    
    func startOfDay(_ date: Date) -> Date {
        if let mockValue = startOfDayReturnValue {
            return mockValue
        }
        return Calendar.current.startOfDay(for: date)
    }
    
    func weekOfYear(for date: Date, firstWeekday: Int) -> (year: Int, week: Int) {
        let calendar = Calendar.current
        let year = calendar.component(.yearForWeekOfYear, from: date)
        let week = calendar.component(.weekOfYear, from: date)
        return (year: year, week: week)
    }
}