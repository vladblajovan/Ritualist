//
//  LogValidationTests.swift
//  RitualistTests
//
//  Tests for habit logging validation, including start date restrictions.
//

import Testing
import Foundation
@testable import RitualistCore

@Suite("Log Validation - Start Date Restrictions")
@MainActor
struct LogValidationStartDateTests {

    // MARK: - HabitScheduleValidationError Tests

    @Test("dateBeforeStartDate error has correct description")
    func dateBeforeStartDateErrorDescription() async throws {
        // Arrange
        let error = HabitScheduleValidationError.dateBeforeStartDate(habitName: "Morning Run")

        // Assert
        #expect(error.errorDescription?.contains("Morning Run") == true, "Error should include habit name")
        #expect(error.errorDescription?.contains("before") == true, "Error should mention 'before'")
    }

    @Test("dateBeforeStartDate error has helpful recovery suggestion")
    func dateBeforeStartDateRecoverySuggestion() async throws {
        // Arrange
        let error = HabitScheduleValidationError.dateBeforeStartDate(habitName: "Test Habit")

        // Assert
        let suggestion = error.recoverySuggestion ?? ""
        #expect(suggestion.contains("edit") || suggestion.contains("start date"), "Recovery should mention editing start date")
    }

    @Test("dateBeforeStartDate error is Equatable")
    func dateBeforeStartDateIsEquatable() async throws {
        // Arrange
        let error1 = HabitScheduleValidationError.dateBeforeStartDate(habitName: "Habit A")
        let error2 = HabitScheduleValidationError.dateBeforeStartDate(habitName: "Habit A")
        let error3 = HabitScheduleValidationError.dateBeforeStartDate(habitName: "Habit B")

        // Assert
        #expect(error1 == error2, "Same habit name should be equal")
        #expect(error1 != error3, "Different habit names should not be equal")
    }

    // MARK: - Start Date Validation Logic Tests

    @Test("Log date on start date is valid")
    func logDateOnStartDateIsValid() async throws {
        // Arrange
        let startDate = TestDates.today
        let logDate = TestDates.today

        // Act
        let logDay = CalendarUtils.startOfDayLocal(for: logDate)
        let startDay = CalendarUtils.startOfDayLocal(for: startDate)
        let isValid = logDay >= startDay

        // Assert
        #expect(isValid, "Logging on start date should be valid")
    }

    @Test("Log date after start date is valid")
    func logDateAfterStartDateIsValid() async throws {
        // Arrange
        let startDate = TestDates.yesterday
        let logDate = TestDates.today

        // Act
        let logDay = CalendarUtils.startOfDayLocal(for: logDate)
        let startDay = CalendarUtils.startOfDayLocal(for: startDate)
        let isValid = logDay >= startDay

        // Assert
        #expect(isValid, "Logging after start date should be valid")
    }

    @Test("Log date before start date is invalid")
    func logDateBeforeStartDateIsInvalid() async throws {
        // Arrange
        let startDate = TestDates.today
        let logDate = TestDates.yesterday

        // Act
        let logDay = CalendarUtils.startOfDayLocal(for: logDate)
        let startDay = CalendarUtils.startOfDayLocal(for: startDate)
        let isValid = logDay >= startDay

        // Assert
        #expect(!isValid, "Logging before start date should be invalid")
    }

    @Test("Log date many days before start date is invalid")
    func logDateManyDaysBeforeStartDateIsInvalid() async throws {
        // Arrange
        let startDate = TestDates.today
        let logDate = TestDates.daysAgo(30)

        // Act
        let logDay = CalendarUtils.startOfDayLocal(for: logDate)
        let startDay = CalendarUtils.startOfDayLocal(for: startDate)
        let isValid = logDay >= startDay

        // Assert
        #expect(!isValid, "Logging 30 days before start date should be invalid")
    }

    // MARK: - Edge Cases

    @Test("Same calendar day different times are valid")
    func sameDayDifferentTimesAreValid() async throws {
        // Arrange: Start date at noon, log at midnight
        let calendar = Calendar.current
        let startDate = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: TestDates.today)!
        let logDate = calendar.date(bySettingHour: 0, minute: 1, second: 0, of: TestDates.today)!

        // Act
        let logDay = CalendarUtils.startOfDayLocal(for: logDate)
        let startDay = CalendarUtils.startOfDayLocal(for: startDate)
        let isValid = logDay >= startDay

        // Assert
        #expect(isValid, "Same calendar day should be valid regardless of time")
    }

    @Test("Midnight boundary validation works correctly")
    func midnightBoundaryValidation() async throws {
        // Arrange: Log at 11:59 PM yesterday, start at midnight today
        let calendar = Calendar.current
        let logDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: TestDates.yesterday)!
        let startDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: TestDates.today)!

        // Act
        let logDay = CalendarUtils.startOfDayLocal(for: logDate)
        let startDay = CalendarUtils.startOfDayLocal(for: startDate)
        let isValid = logDay >= startDay

        // Assert
        #expect(!isValid, "11:59 PM yesterday should be before midnight today start date")
    }
}

@Suite("Log Validation - GetEarliestLogDate")
@MainActor
struct GetEarliestLogDateTests {

    @Test("Returns nil for empty logs")
    func returnsNilForEmptyLogs() async throws {
        // Arrange
        let logs: [HabitLog] = []

        // Act
        let earliestDate = logs.map { CalendarUtils.startOfDayLocal(for: $0.date) }.min()

        // Assert
        #expect(earliestDate == nil, "Should return nil for empty logs")
    }

    @Test("Returns single log date for one log")
    func returnsSingleLogDate() async throws {
        // Arrange
        let habitId = UUID()
        let log = HabitLogBuilder.binary(habitId: habitId, date: TestDates.today)

        // Act
        let logs = [log]
        let earliestDate = logs.map { CalendarUtils.startOfDayLocal(for: $0.date) }.min()

        // Assert
        let expectedDate = CalendarUtils.startOfDayLocal(for: TestDates.today)
        #expect(earliestDate == expectedDate, "Should return the single log's date")
    }

    @Test("Returns earliest date from multiple logs")
    func returnsEarliestFromMultipleLogs() async throws {
        // Arrange
        let habitId = UUID()
        let oldestDate = TestDates.daysAgo(10)
        let logs = [
            HabitLogBuilder.binary(habitId: habitId, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habitId, date: TestDates.yesterday),
            HabitLogBuilder.binary(habitId: habitId, date: oldestDate)
        ]

        // Act
        let earliestDate = logs.map { CalendarUtils.startOfDayLocal(for: $0.date) }.min()

        // Assert
        let expectedDate = CalendarUtils.startOfDayLocal(for: oldestDate)
        #expect(earliestDate == expectedDate, "Should return the oldest log date")
    }

    @Test("Handles logs across different times on same day")
    func handlesLogsAcrossDifferentTimes() async throws {
        // Arrange: Multiple logs on different days at different times
        let habitId = UUID()
        let calendar = Calendar.current

        let day1Morning = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: TestDates.yesterday)!
        let day1Evening = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: TestDates.yesterday)!
        let day2Noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: TestDates.today)!

        let logs = [
            HabitLogBuilder.binary(habitId: habitId, date: day2Noon),
            HabitLogBuilder.binary(habitId: habitId, date: day1Evening),
            HabitLogBuilder.binary(habitId: habitId, date: day1Morning)
        ]

        // Act
        let earliestDate = logs.map { CalendarUtils.startOfDayLocal(for: $0.date) }.min()

        // Assert: Should be start of yesterday
        let expectedDate = CalendarUtils.startOfDayLocal(for: TestDates.yesterday)
        #expect(earliestDate == expectedDate, "Should return start of earliest day")
    }
}

// MARK: - LogHabit Start Date Validation Integration Tests

@Suite("LogHabit - Start Date Validation Integration")
@MainActor
struct LogHabitStartDateIntegrationTests {

    @Test("Logging before habit start date throws dateBeforeStartDate error")
    func loggingBeforeStartDateThrows() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.today)
        let habitRepo = MockHabitRepository(habits: [habit])
        let logRepo = MockLogRepository()
        let validateSchedule = MockValidateHabitScheduleUseCase(isValid: true)

        let logUseCase = LogHabit(repo: logRepo, habitRepo: habitRepo, validateSchedule: validateSchedule)

        // Log for yesterday (before start date)
        let log = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.yesterday)

        // Act & Assert
        do {
            try await logUseCase.execute(log)
            Issue.record("Should have thrown dateBeforeStartDate error")
        } catch let error as HabitScheduleValidationError {
            if case .dateBeforeStartDate(let name) = error {
                #expect(name == habit.name, "Error should contain habit name")
            } else {
                Issue.record("Wrong error type: \(error)")
            }
        }
    }

    @Test("Logging on habit start date succeeds")
    func loggingOnStartDateSucceeds() async throws {
        // Arrange
        let habitRepo = MockHabitRepository()
        let logRepo = MockLogRepository()
        let validateSchedule = MockValidateHabitScheduleUseCase(isValid: true)

        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.today)
        habitRepo.habits = [habit]

        let logUseCase = LogHabit(repo: logRepo, habitRepo: habitRepo, validateSchedule: validateSchedule)

        // Log for today (same as start date)
        let log = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)

        // Act & Assert - should not throw
        try await logUseCase.execute(log)
        #expect(logRepo.upsertedLogs.count == 1, "Log should be saved")
    }

    @Test("Logging after habit start date succeeds")
    func loggingAfterStartDateSucceeds() async throws {
        // Arrange
        let habitRepo = MockHabitRepository()
        let logRepo = MockLogRepository()
        let validateSchedule = MockValidateHabitScheduleUseCase(isValid: true)

        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.yesterday)
        habitRepo.habits = [habit]

        let logUseCase = LogHabit(repo: logRepo, habitRepo: habitRepo, validateSchedule: validateSchedule)

        // Log for today (after start date)
        let log = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)

        // Act & Assert - should not throw
        try await logUseCase.execute(log)
        #expect(logRepo.upsertedLogs.count == 1, "Log should be saved")
    }

    @Test("Retroactive logging works when start date is backdated")
    func retroactiveLoggingAfterBackdatingSucceeds() async throws {
        // Arrange: User backdated habit start to 7 days ago
        let habitRepo = MockHabitRepository()
        let logRepo = MockLogRepository()
        let validateSchedule = MockValidateHabitScheduleUseCase(isValid: true)

        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(7))
        habitRepo.habits = [habit]

        let logUseCase = LogHabit(repo: logRepo, habitRepo: habitRepo, validateSchedule: validateSchedule)

        // Log for 5 days ago (within backdated range)
        let log = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(5))

        // Act & Assert - should succeed
        try await logUseCase.execute(log)
        #expect(logRepo.upsertedLogs.count == 1, "Retroactive log should be saved")
    }

    @Test("Retroactive logging fails when log is before backdated start date")
    func retroactiveLoggingFailsBeforeBackdatedStart() async throws {
        // Arrange: User backdated habit start to 7 days ago
        let habitRepo = MockHabitRepository()
        let logRepo = MockLogRepository()
        let validateSchedule = MockValidateHabitScheduleUseCase(isValid: true)

        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(7))
        habitRepo.habits = [habit]

        let logUseCase = LogHabit(repo: logRepo, habitRepo: habitRepo, validateSchedule: validateSchedule)

        // Log for 10 days ago (before backdated start)
        let log = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(10))

        // Act & Assert
        do {
            try await logUseCase.execute(log)
            Issue.record("Should have thrown dateBeforeStartDate error")
        } catch let error as HabitScheduleValidationError {
            if case .dateBeforeStartDate = error {
                // Expected error
            } else {
                Issue.record("Wrong error type: \(error)")
            }
        }
    }

    @Test("Multiple retroactive logs can be created within valid range")
    func multipleRetroactiveLogsSucceed() async throws {
        // Arrange
        let habitRepo = MockHabitRepository()
        let logRepo = MockLogRepository()
        let validateSchedule = MockValidateHabitScheduleUseCase(isValid: true)

        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(5))
        habitRepo.habits = [habit]

        let logUseCase = LogHabit(repo: logRepo, habitRepo: habitRepo, validateSchedule: validateSchedule)

        // Log for each day from start date to today (6 logs)
        for dayOffset in 0...5 {
            let log = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(dayOffset))
            try await logUseCase.execute(log)
        }

        // Assert
        #expect(logRepo.upsertedLogs.count == 6, "All 6 retroactive logs should be saved")
    }
}
