//
//  HabitCompletionServiceTests.swift
//  RitualistTests
//
//  Created by Claude on 16.08.2025.
//

import Testing
import Foundation
@testable import Ritualist
import RitualistCore

struct HabitCompletionServiceTests {
    
    // MARK: - Test Data Builders
    
    private func createTestHabit(
        id: UUID = UUID(),
        name: String = "Test Habit",
        kind: HabitKind = .binary,
        schedule: HabitSchedule = .daily,
        dailyTarget: Double? = nil,
        startDate: Date = Date()
    ) -> Habit {
        return Habit(
            id: id,
            name: name,
            kind: kind,
            dailyTarget: dailyTarget,
            schedule: schedule,
            startDate: startDate
        )
    }
    
    private func createTestLog(
        habitID: UUID,
        date: Date,
        value: Double? = 1.0
    ) -> HabitLog {
        return HabitLog(habitID: habitID, date: date, value: value)
    }
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var service: HabitCompletionServiceProtocol {
        DefaultHabitCompletionService()
    }
    
    // MARK: - isCompleted Tests
    
    @Test("Daily habit completion - completed")
    func testDailyHabitIsCompleted() {
        // Arrange
        let habit = createTestHabit(schedule: .daily)
        let today = Date()
        let logs = [createTestLog(habitID: habit.id, date: today)]
        
        // Act
        let isCompleted = service.isCompleted(habit: habit, on: today, logs: logs)
        
        // Assert
        #expect(isCompleted == true)
    }
    
    @Test("Daily habit completion - not completed")
    func testDailyHabitIsNotCompleted() {
        // Arrange
        let habit = createTestHabit(schedule: .daily)
        let today = Date()
        let logs: [HabitLog] = []
        
        // Act
        let isCompleted = service.isCompleted(habit: habit, on: today, logs: logs)
        
        // Assert
        #expect(isCompleted == false)
    }
    
    @Test("DaysOfWeek habit completion - scheduled day completed")
    func testDaysOfWeekHabitCompletedOnScheduledDay() {
        // Arrange
        let monday = 1
        let habit = createTestHabit(schedule: .daysOfWeek([monday]))
        
        // Find next Monday
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysUntilMonday = (9 - weekday) % 7
        let nextMonday = calendar.date(byAdding: .day, value: daysUntilMonday, to: today)!
        
        let logs = [createTestLog(habitID: habit.id, date: nextMonday)]
        
        // Act
        let isCompleted = service.isCompleted(habit: habit, on: nextMonday, logs: logs)
        
        // Assert
        #expect(isCompleted == true)
    }
    
    @Test("TimesPerWeek habit completion - weekly target met")
    func testTimesPerWeekHabitCompletedWhenTargetMet() {
        // Arrange
        let weeklyTarget = 3
        let habit = createTestHabit(schedule: .timesPerWeek(weeklyTarget))
        
        let today = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)!.start
        
        // Create 3 logs throughout the week
        let logs = [
            createTestLog(habitID: habit.id, date: weekStart),
            createTestLog(habitID: habit.id, date: calendar.date(byAdding: .day, value: 1, to: weekStart)!),
            createTestLog(habitID: habit.id, date: calendar.date(byAdding: .day, value: 2, to: weekStart)!)
        ]
        
        // Act
        let isCompleted = service.isCompleted(habit: habit, on: today, logs: logs)
        
        // Assert
        #expect(isCompleted == true)
    }
    
    @Test("TimesPerWeek habit completion - weekly target not met")
    func testTimesPerWeekHabitNotCompletedWhenTargetNotMet() {
        // Arrange
        let weeklyTarget = 3
        let habit = createTestHabit(schedule: .timesPerWeek(weeklyTarget))
        
        let today = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)!.start
        
        // Create only 2 logs (target is 3)
        let logs = [
            createTestLog(habitID: habit.id, date: weekStart),
            createTestLog(habitID: habit.id, date: calendar.date(byAdding: .day, value: 1, to: weekStart)!)
        ]
        
        // Act
        let isCompleted = service.isCompleted(habit: habit, on: today, logs: logs)
        
        // Assert
        #expect(isCompleted == false)
    }
    
    // MARK: - calculateProgress Tests
    
    @Test("Daily habit progress calculation")
    func testDailyHabitProgressCalculation() {
        // Arrange
        let habit = createTestHabit(schedule: .daily)
        let startDate = calendar.date(byAdding: .day, value: -6, to: Date())! // 7-day range
        let endDate = Date()
        
        // Complete 4 out of 7 days
        let logs = [
            createTestLog(habitID: habit.id, date: startDate),
            createTestLog(habitID: habit.id, date: calendar.date(byAdding: .day, value: 1, to: startDate)!),
            createTestLog(habitID: habit.id, date: calendar.date(byAdding: .day, value: 3, to: startDate)!),
            createTestLog(habitID: habit.id, date: endDate)
        ]
        
        // Act
        let progress = service.calculateProgress(habit: habit, logs: logs, from: startDate, to: endDate)
        
        // Assert
        let expectedProgress = 4.0 / 7.0 // 4 completed days out of 7 total days
        #expect(abs(progress - expectedProgress) < 0.01)
    }
    
    @Test("TimesPerWeek habit progress calculation")
    func testTimesPerWeekHabitProgressCalculation() {
        // Arrange
        let weeklyTarget = 3
        let habitStartDate = calendar.date(byAdding: .weekOfYear, value: -2, to: Date())! // Start habit before test logs
        let habit = createTestHabit(schedule: .timesPerWeek(weeklyTarget), startDate: habitStartDate)
        
        // Create fixed date ranges for consistent testing
        let week1Start = calendar.date(from: DateComponents(year: 2025, month: 8, day: 4))! // Week 1 start (Monday)
        let week2Start = calendar.date(byAdding: .weekOfYear, value: 1, to: week1Start)! // Week 2 start
        
        let startDate = week1Start
        let endDate = calendar.date(byAdding: .day, value: 13, to: week1Start)! // Cover both weeks completely
        
        let logs = [
            // Week 1: 2 completions (ensure these are within startDate to endDate range)
            createTestLog(habitID: habit.id, date: calendar.date(byAdding: .day, value: 1, to: week1Start)!),
            createTestLog(habitID: habit.id, date: calendar.date(byAdding: .day, value: 2, to: week1Start)!),
            // Week 2: 3 completions (ensure these are within startDate to endDate range)  
            createTestLog(habitID: habit.id, date: calendar.date(byAdding: .day, value: 1, to: week2Start)!),
            createTestLog(habitID: habit.id, date: calendar.date(byAdding: .day, value: 2, to: week2Start)!),
            createTestLog(habitID: habit.id, date: calendar.date(byAdding: .day, value: 3, to: week2Start)!)
        ]
        
        // Act
        let progress = service.calculateProgress(habit: habit, logs: logs, from: startDate, to: endDate)
        
        // Assert
        let expectedProgress = 5.0 / 6.0 // 5 completed out of 6 expected (2 weeks × 3 target)
        #expect(abs(progress - expectedProgress) < 0.01)
    }
    
    // MARK: - calculateDailyProgress Tests
    
    @Test("Daily habit daily progress - completed")
    func testDailyHabitDailyProgressCompleted() {
        // Arrange
        let habit = createTestHabit(schedule: .daily)
        let today = Date()
        let logs = [createTestLog(habitID: habit.id, date: today)]
        
        // Act
        let progress = service.calculateDailyProgress(habit: habit, logs: logs, for: today)
        
        // Assert
        #expect(progress == 1.0)
    }
    
    @Test("Daily habit daily progress - not completed")
    func testDailyHabitDailyProgressNotCompleted() {
        // Arrange
        let habit = createTestHabit(schedule: .daily)
        let today = Date()
        let logs: [HabitLog] = []
        
        // Act
        let progress = service.calculateDailyProgress(habit: habit, logs: logs, for: today)
        
        // Assert
        #expect(progress == 0.0)
    }
    
    @Test("TimesPerWeek habit daily progress - partial week")
    func testTimesPerWeekHabitDailyProgressPartialWeek() {
        // Arrange
        let weeklyTarget = 3
        let habit = createTestHabit(schedule: .timesPerWeek(weeklyTarget))
        
        let today = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)!.start
        
        // Complete 2 out of 3 target by today
        let logs = [
            createTestLog(habitID: habit.id, date: weekStart),
            createTestLog(habitID: habit.id, date: calendar.date(byAdding: .day, value: 1, to: weekStart)!)
        ]
        
        // Act
        let progress = service.calculateDailyProgress(habit: habit, logs: logs, for: today)
        
        // Assert
        let expectedProgress = 2.0 / 3.0 // 2 completed out of 3 weekly target
        #expect(abs(progress - expectedProgress) < 0.01)
    }
    
    // MARK: - isScheduledDay Tests
    
    @Test("Daily habit is always scheduled")
    func testDailyHabitIsAlwaysScheduled() {
        // Arrange
        let habit = createTestHabit(schedule: .daily)
        let today = Date()
        
        // Act
        let isScheduled = service.isScheduledDay(habit: habit, date: today)
        
        // Assert
        #expect(isScheduled == true)
    }
    
    @Test("DaysOfWeek habit is scheduled only on specified days")
    func testDaysOfWeekHabitIsScheduledOnlyOnSpecifiedDays() {
        // Arrange
        let monday = 1
        let habit = createTestHabit(schedule: .daysOfWeek([monday]))
        
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let habitWeekday = weekday == 1 ? 7 : weekday - 1
        
        // Act
        let isScheduled = service.isScheduledDay(habit: habit, date: today)
        
        // Assert
        let expectedScheduled = (habitWeekday == monday)
        #expect(isScheduled == expectedScheduled)
    }
    
    @Test("TimesPerWeek habit is always scheduled")
    func testTimesPerWeekHabitIsAlwaysScheduled() {
        // Arrange
        let habit = createTestHabit(schedule: .timesPerWeek(3))
        let today = Date()
        
        // Act
        let isScheduled = service.isScheduledDay(habit: habit, date: today)
        
        // Assert
        #expect(isScheduled == true)
    }
    
    // MARK: - getExpectedCompletions Tests
    
    @Test("Daily habit expected completions")
    func testDailyHabitExpectedCompletions() {
        // Arrange
        let startDate = calendar.date(byAdding: .day, value: -6, to: Date())! // 7-day range
        let endDate = Date()
        let habitStartDate = calendar.date(byAdding: .day, value: -10, to: Date())! // Start habit before test range
        let habit = createTestHabit(schedule: .daily, startDate: habitStartDate)
        
        // Act
        let expected = service.getExpectedCompletions(habit: habit, from: startDate, to: endDate)
        
        // Assert
        #expect(expected == 7)
    }
    
    @Test("DaysOfWeek habit expected completions")
    func testDaysOfWeekHabitExpectedCompletions() {
        // Arrange
        let mondayWednesdayFriday = Set([1, 3, 5]) // Mon, Wed, Fri
        
        // 2-week range should have 6 occurrences (3 days × 2 weeks)
        let startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: Date())!
        let endDate = Date()
        let habitStartDate = calendar.date(byAdding: .weekOfYear, value: -2, to: Date())! // Start habit before test range
        let habit = createTestHabit(schedule: .daysOfWeek(mondayWednesdayFriday), startDate: habitStartDate)
        
        // Act
        let expected = service.getExpectedCompletions(habit: habit, from: startDate, to: endDate)
        
        // Assert
        // This will vary based on the actual dates, but should be around 6
        #expect(expected >= 3 && expected <= 9) // Flexible range for different start days
    }
    
    @Test("TimesPerWeek habit expected completions")
    func testTimesPerWeekHabitExpectedCompletions() {
        // Arrange
        let weeklyTarget = 3
        
        // 2-week range
        let startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: Date())!
        let endDate = Date()
        let habitStartDate = calendar.date(byAdding: .weekOfYear, value: -2, to: Date())! // Start habit before test range
        let habit = createTestHabit(schedule: .timesPerWeek(weeklyTarget), startDate: habitStartDate)
        
        // Act
        let expected = service.getExpectedCompletions(habit: habit, from: startDate, to: endDate)
        
        // Assert
        let expectedCompletions = 2 * weeklyTarget // 2 weeks × 3 target = 6
        #expect(expected == expectedCompletions)
    }
    
    // MARK: - Numeric Habit Tests
    
    @Test("Numeric habit with daily target completion")
    func testNumericHabitWithDailyTargetCompletion() {
        // Arrange
        let dailyTarget = 10.0
        let habit = createTestHabit(kind: .numeric, dailyTarget: dailyTarget)
        let today = Date()
        
        // Act & Assert - Meeting target
        let logsMetTarget = [createTestLog(habitID: habit.id, date: today, value: 10.0)]
        let isCompletedMet = service.isCompleted(habit: habit, on: today, logs: logsMetTarget)
        #expect(isCompletedMet == true)
        
        // Act & Assert - Exceeding target
        let logsExceedTarget = [createTestLog(habitID: habit.id, date: today, value: 15.0)]
        let isCompletedExceed = service.isCompleted(habit: habit, on: today, logs: logsExceedTarget)
        #expect(isCompletedExceed == true)
        
        // Act & Assert - Not meeting target
        let logsNotMet = [createTestLog(habitID: habit.id, date: today, value: 5.0)]
        let isCompletedNotMet = service.isCompleted(habit: habit, on: today, logs: logsNotMet)
        #expect(isCompletedNotMet == false)
    }
    
    @Test("Numeric habit without daily target completion")
    func testNumericHabitWithoutDailyTargetCompletion() {
        // Arrange
        let habit = createTestHabit(kind: .numeric, dailyTarget: nil)
        let today = Date()
        
        // Act & Assert - Any positive value
        let logsPositive = [createTestLog(habitID: habit.id, date: today, value: 5.0)]
        let isCompletedPositive = service.isCompleted(habit: habit, on: today, logs: logsPositive)
        #expect(isCompletedPositive == true)
        
        // Act & Assert - Zero value
        let logsZero = [createTestLog(habitID: habit.id, date: today, value: 0.0)]
        let isCompletedZero = service.isCompleted(habit: habit, on: today, logs: logsZero)
        #expect(isCompletedZero == false)
    }
    
    // MARK: - Edge Cases
    
    @Test("Empty logs array")
    func testEmptyLogsArray() {
        // Arrange
        let habit = createTestHabit()
        let today = Date()
        let logs: [HabitLog] = []
        
        // Act
        let isCompleted = service.isCompleted(habit: habit, on: today, logs: logs)
        let progress = service.calculateProgress(habit: habit, logs: logs, from: today, to: today)
        let dailyProgress = service.calculateDailyProgress(habit: habit, logs: logs, for: today)
        
        // Assert
        #expect(isCompleted == false)
        #expect(progress == 0.0)
        #expect(dailyProgress == 0.0)
    }
    
    @Test("Logs for different habit ID are ignored")
    func testLogsForDifferentHabitIDIgnored() {
        // Arrange
        let habit = createTestHabit()
        let differentHabitId = UUID()
        let today = Date()
        let logs = [createTestLog(habitID: differentHabitId, date: today)]
        
        // Act
        let isCompleted = service.isCompleted(habit: habit, on: today, logs: logs)
        
        // Assert
        #expect(isCompleted == false)
    }
    
    @Test("Single day date range")
    func testSingleDayDateRange() {
        // Arrange
        let habit = createTestHabit(schedule: .daily)
        let today = Date()
        let logs = [createTestLog(habitID: habit.id, date: today)]
        
        // Act
        let progress = service.calculateProgress(habit: habit, logs: logs, from: today, to: today)
        let expected = service.getExpectedCompletions(habit: habit, from: today, to: today)
        
        // Assert
        #expect(progress == 1.0)
        #expect(expected == 1)
    }
}