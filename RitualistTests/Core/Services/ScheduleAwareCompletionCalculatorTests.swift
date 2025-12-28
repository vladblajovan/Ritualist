//
//  ScheduleAwareCompletionCalculatorTests.swift
//  RitualistTests
//
//  Created by Claude on 29.11.2025.
//

import Testing
import Foundation
@testable import RitualistCore

@Suite("ScheduleAwareCompletionCalculator - Core Functionality")
@MainActor
struct ScheduleAwareCompletionCalculatorTests {

    // MARK: - Test Setup

    var calculator: ScheduleAwareCompletionCalculator {
        DefaultScheduleAwareCompletionCalculator()
    }

    // MARK: - calculateExpectedDays Tests

    @Test("Expected days for daily habit over 7 days is 7")
    func expectedDaysForDailyHabit() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(30))
        let startDate = TestDates.daysAgo(6)
        let endDate = TestDates.today

        // Act
        let expectedDays = calculator.calculateExpectedDays(for: habit, startDate: startDate, endDate: endDate)

        // Assert
        #expect(expectedDays == 7, "Daily habit over 7 days should have 7 expected days")
    }

    @Test("Expected days for daily habit on same day is 1")
    func expectedDaysForSameDayRange() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(30))
        let date = TestDates.today

        // Act
        let expectedDays = calculator.calculateExpectedDays(for: habit, startDate: date, endDate: date)

        // Assert
        #expect(expectedDays == 1, "Same start and end date should count as 1 day")
    }

    @Test("Expected days respects habit start date")
    func expectedDaysRespectsHabitStartDate() async throws {
        // Arrange - habit starts 3 days ago but query asks for 7 days
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(3))
        let startDate = TestDates.daysAgo(6)
        let endDate = TestDates.today

        // Act
        let expectedDays = calculator.calculateExpectedDays(for: habit, startDate: startDate, endDate: endDate)

        // Assert
        #expect(expectedDays == 4, "Should only count days from habit start (3 days ago to today = 4 days)")
    }

    @Test("Expected days for Mon/Wed/Fri habit in one week")
    func expectedDaysForDaysOfWeekHabit() async throws {
        // Arrange - Mon/Wed/Fri habit (days 1, 3, 5)
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([1, 3, 5]),
            startDate: TestDates.daysAgo(30)
        )
        // Query a full week to ensure we capture 3 scheduled days
        let startDate = TestDates.daysAgo(6)
        let endDate = TestDates.today

        // Act
        let expectedDays = calculator.calculateExpectedDays(for: habit, startDate: startDate, endDate: endDate)

        // Assert
        #expect(expectedDays >= 2 && expectedDays <= 4, "Mon/Wed/Fri habit should have 2-4 expected days in a week depending on start day")
    }

    @Test("Expected days is 0 when habit starts after date range")
    func expectedDaysZeroWhenHabitStartsAfterRange() async throws {
        // Arrange - habit starts tomorrow but query is for past week
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.tomorrow)
        let startDate = TestDates.daysAgo(6)
        let endDate = TestDates.today

        // Act
        let expectedDays = calculator.calculateExpectedDays(for: habit, startDate: startDate, endDate: endDate)

        // Assert
        #expect(expectedDays == 0, "Expected days should be 0 when habit hasn't started yet")
    }

    // MARK: - calculateCompletionRate Tests

    @Test("Completion rate is 100% when all days completed")
    func completionRateFullWhenAllCompleted() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(30))
        let startDate = TestDates.daysAgo(2)
        let endDate = TestDates.today

        // Create logs for all 3 days
        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.yesterday),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(2))
        ]

        // Act
        let rate = calculator.calculateCompletionRate(for: habit, logs: logs, startDate: startDate, endDate: endDate)

        // Assert
        #expect(rate == 1.0, "Completion rate should be 100% when all days completed")
    }

    @Test("Completion rate is 0% when no days completed")
    func completionRateZeroWhenNoneCompleted() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(30))
        let startDate = TestDates.daysAgo(6)
        let endDate = TestDates.today
        let logs: [HabitLog] = []

        // Act
        let rate = calculator.calculateCompletionRate(for: habit, logs: logs, startDate: startDate, endDate: endDate)

        // Assert
        #expect(rate == 0.0, "Completion rate should be 0% when no days completed")
    }

    @Test("Completion rate is 50% when half days completed")
    func completionRateHalfWhenHalfCompleted() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(30))
        let startDate = TestDates.daysAgo(3)
        let endDate = TestDates.today

        // Create logs for 2 of 4 days
        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(2))
        ]

        // Act
        let rate = calculator.calculateCompletionRate(for: habit, logs: logs, startDate: startDate, endDate: endDate)

        // Assert
        #expect(rate == 0.5, "Completion rate should be 50% when 2 of 4 days completed")
    }

    @Test("Completion rate ignores logs outside date range")
    func completionRateIgnoresLogsOutsideRange() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(30))
        let startDate = TestDates.daysAgo(2)
        let endDate = TestDates.today

        // Create logs including one outside the range
        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(10)) // Outside range
        ]

        // Act
        let rate = calculator.calculateCompletionRate(for: habit, logs: logs, startDate: startDate, endDate: endDate)

        // Assert
        // Only 1 of 3 days completed within range
        #expect(abs(rate - (1.0/3.0)) < 0.01, "Should only count logs within the date range")
    }

    @Test("Completion rate ignores logs for other habits")
    func completionRateIgnoresOtherHabitLogs() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(30))
        let otherHabit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(30))
        let startDate = TestDates.daysAgo(2)
        let endDate = TestDates.today

        // Create logs for this habit and another habit
        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: otherHabit.id, date: TestDates.yesterday),
            HabitLogBuilder.binary(habitId: otherHabit.id, date: TestDates.daysAgo(2))
        ]

        // Act
        let rate = calculator.calculateCompletionRate(for: habit, logs: logs, startDate: startDate, endDate: endDate)

        // Assert
        // Only 1 of 3 days completed for this habit
        #expect(abs(rate - (1.0/3.0)) < 0.01, "Should only count logs for the specified habit")
    }

    // MARK: - isHabitCompleted Tests

    @Test("Binary habit is completed when logged")
    func binaryHabitCompletedWhenLogged() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)
        let log = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)

        // Act
        let isCompleted = calculator.isHabitCompleted(habit: habit, logs: [log], date: TestDates.today)

        // Assert
        #expect(isCompleted == true, "Binary habit should be completed when logged")
    }

    @Test("Binary habit is not completed when not logged")
    func binaryHabitNotCompletedWhenNotLogged() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)
        let logs: [HabitLog] = []

        // Act
        let isCompleted = calculator.isHabitCompleted(habit: habit, logs: logs, date: TestDates.today)

        // Assert
        #expect(isCompleted == false, "Binary habit should not be completed when not logged")
    }

    @Test("Numeric habit is completed when target met")
    func numericHabitCompletedWhenTargetMet() async throws {
        // Arrange
        let habit = HabitBuilder.numeric(target: 8.0, unit: "glasses")
        let log = HabitLogBuilder.numeric(habitId: habit.id, value: 8.0, date: TestDates.today)

        // Act
        let isCompleted = calculator.isHabitCompleted(habit: habit, logs: [log], date: TestDates.today)

        // Assert
        #expect(isCompleted == true, "Numeric habit should be completed when target met")
    }

    @Test("Numeric habit is not completed when target not met")
    func numericHabitNotCompletedWhenTargetNotMet() async throws {
        // Arrange
        let habit = HabitBuilder.numeric(target: 8.0, unit: "glasses")
        let log = HabitLogBuilder.numeric(habitId: habit.id, value: 5.0, date: TestDates.today)

        // Act
        let isCompleted = calculator.isHabitCompleted(habit: habit, logs: [log], date: TestDates.today)

        // Assert
        #expect(isCompleted == false, "Numeric habit should not be completed when target not met")
    }

    // MARK: - calculateCompletionStats Tests

    @Test("Completion stats counts active habits only")
    func completionStatsCountsActiveHabitsOnly() async throws {
        // Arrange
        let activeHabit = HabitBuilder.binary(name: "Active", isActive: true, startDate: TestDates.daysAgo(30))
        let inactiveHabit = HabitBuilder.binary(name: "Inactive", isActive: false, startDate: TestDates.daysAgo(30))
        let habits = [activeHabit, inactiveHabit]

        let logs = [
            HabitLogBuilder.binary(habitId: activeHabit.id, date: TestDates.today)
        ]

        let startDate = TestDates.today
        let endDate = TestDates.today

        // Act
        let stats = calculator.calculateCompletionStats(for: habits, logs: logs, startDate: startDate, endDate: endDate)

        // Assert
        #expect(stats.totalHabits == 1, "Should only count active habits")
    }

    @Test("Completion stats calculates overall rate correctly")
    func completionStatsCalculatesOverallRate() async throws {
        // Arrange - 2 habits, both with 100% completion
        let habit1 = HabitBuilder.binary(name: "Habit 1", startDate: TestDates.daysAgo(30))
        let habit2 = HabitBuilder.binary(name: "Habit 2", startDate: TestDates.daysAgo(30))
        let habits = [habit1, habit2]

        let logs = [
            HabitLogBuilder.binary(habitId: habit1.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habit2.id, date: TestDates.today)
        ]

        let startDate = TestDates.today
        let endDate = TestDates.today

        // Act
        let stats = calculator.calculateCompletionStats(for: habits, logs: logs, startDate: startDate, endDate: endDate)

        // Assert
        #expect(stats.completionRate == 1.0, "Overall completion rate should be 100% when all habits completed")
        #expect(stats.completedHabits == 2, "Both habits should count as completed (>50% rate)")
    }

    @Test("Completion stats counts habits with >50% as completed")
    func completionStatsCountsHabitsAbove50PercentAsCompleted() async throws {
        // Arrange - 2 habits over 2 days
        let habit1 = HabitBuilder.binary(name: "Habit 1", startDate: TestDates.daysAgo(30))
        let habit2 = HabitBuilder.binary(name: "Habit 2", startDate: TestDates.daysAgo(30))
        let habits = [habit1, habit2]

        // Habit1: 2/2 days = 100%, Habit2: 1/2 days = 50%
        let logs = [
            HabitLogBuilder.binary(habitId: habit1.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habit1.id, date: TestDates.yesterday),
            HabitLogBuilder.binary(habitId: habit2.id, date: TestDates.today)
        ]

        let startDate = TestDates.yesterday
        let endDate = TestDates.today

        // Act
        let stats = calculator.calculateCompletionStats(for: habits, logs: logs, startDate: startDate, endDate: endDate)

        // Assert
        // Habit1 is >50%, Habit2 is exactly 50% (not >50%)
        #expect(stats.completedHabits == 1, "Only habits with >50% completion rate count as completed")
    }

    @Test("Completion stats handles empty habits list")
    func completionStatsHandlesEmptyHabits() async throws {
        // Arrange
        let habits: [Habit] = []
        let logs: [HabitLog] = []
        let startDate = TestDates.daysAgo(6)
        let endDate = TestDates.today

        // Act
        let stats = calculator.calculateCompletionStats(for: habits, logs: logs, startDate: startDate, endDate: endDate)

        // Assert
        #expect(stats.totalHabits == 0, "Total habits should be 0")
        #expect(stats.completedHabits == 0, "Completed habits should be 0")
        #expect(stats.completionRate == 0.0, "Completion rate should be 0")
    }
}

// MARK: - Days of Week Schedule Tests

@Suite("ScheduleAwareCompletionCalculator - Days of Week Schedules")
@MainActor
struct ScheduleAwareCompletionCalculatorDaysOfWeekTests {

    var calculator: ScheduleAwareCompletionCalculator {
        DefaultScheduleAwareCompletionCalculator()
    }

    @Test("Mon/Wed/Fri habit completion rate counts only scheduled days")
    func monWedFriCompletionRateCountsScheduledDays() async throws {
        // Arrange - Mon/Wed/Fri habit
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([1, 3, 5]), // Mon/Wed/Fri
            startDate: TestDates.daysAgo(30)
        )

        // Get 2 weeks of range to ensure we have scheduled days
        let startDate = TestDates.daysAgo(13)
        let endDate = TestDates.today

        // Create logs for all days (but only scheduled days should count)
        var logs: [HabitLog] = []
        for i in 0...13 {
            logs.append(HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(i)))
        }

        // Act
        let rate = calculator.calculateCompletionRate(for: habit, logs: logs, startDate: startDate, endDate: endDate)

        // Assert
        // Should be 100% since we logged every day (including all scheduled days)
        #expect(rate == 1.0, "Should be 100% when all scheduled days are completed")
    }

    @Test("Weekend-only habit ignores weekday logs")
    func weekendOnlyHabitIgnoresWeekdayLogs() async throws {
        // Arrange - Saturday/Sunday habit (days 6, 7)
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([6, 7]),
            startDate: TestDates.daysAgo(30)
        )

        let startDate = TestDates.daysAgo(13)
        let endDate = TestDates.today

        // Expected days should only count weekends
        let expectedDays = calculator.calculateExpectedDays(for: habit, startDate: startDate, endDate: endDate)

        // Assert
        #expect(expectedDays >= 2 && expectedDays <= 4, "Weekend habit should have 2-4 expected days in 2 weeks")
    }
}
