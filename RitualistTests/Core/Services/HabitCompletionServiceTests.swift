//
//  HabitCompletionServiceTests.swift
//  RitualistTests
//
//  Created by Phase 4 Testing Infrastructure on 15.11.2025.
//

import Testing
import Foundation
@testable import RitualistCore

@Suite("HabitCompletionService - Core Functionality")
struct HabitCompletionServiceTests {

    // MARK: - Test Setup

    let service = DefaultHabitCompletionService()

    // MARK: - Basic Completion Tests

    @Test("Binary habit marked as completed when logged on specific day")
    func binaryHabitCompletedWhenLogged() async throws {
        // Arrange: Create binary habit and log
        let habit = HabitBuilder.binary(name: "Morning Meditation", schedule: .daily)
        let log = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)

        // Act: Check if completed
        let isCompleted = service.isCompleted(habit: habit, on: TestDates.today, logs: [log])

        // Assert
        #expect(isCompleted == true, "Binary habit should be completed when logged on the day")
    }

    @Test("Binary habit not completed when not logged")
    func binaryHabitNotCompletedWhenNotLogged() async throws {
        // Arrange: Create binary habit with no logs
        let habit = HabitBuilder.binary(name: "Morning Meditation", schedule: .daily)

        // Act: Check if completed
        let isCompleted = service.isCompleted(habit: habit, on: TestDates.today, logs: [])

        // Assert
        #expect(isCompleted == false, "Binary habit should not be completed when not logged")
    }

    @Test("Numeric habit completed when target met")
    func numericHabitCompletedWhenTargetMet() async throws {
        // Arrange: Create numeric habit with target of 8 glasses
        let habit = HabitBuilder.numeric(
            name: "Drink Water",
            target: 8.0,
            unit: "glasses",
            schedule: .daily
        )
        let log = HabitLogBuilder.numeric(
            habitId: habit.id,
            value: 8.0,
            date: TestDates.today
        )

        // Act: Check if completed
        let isCompleted = service.isCompleted(habit: habit, on: TestDates.today, logs: [log])

        // Assert
        #expect(isCompleted == true, "Numeric habit should be completed when target is met")
    }

    @Test("Numeric habit not completed when target not met")
    func numericHabitNotCompletedWhenTargetNotMet() async throws {
        // Arrange: Create numeric habit with target of 8 glasses
        let habit = HabitBuilder.numeric(
            name: "Drink Water",
            target: 8.0,
            unit: "glasses",
            schedule: .daily
        )
        let log = HabitLogBuilder.numeric(
            habitId: habit.id,
            value: 5.0,  // Below target
            date: TestDates.today
        )

        // Act: Check if completed
        let isCompleted = service.isCompleted(habit: habit, on: TestDates.today, logs: [log])

        // Assert
        #expect(isCompleted == false, "Numeric habit should not be completed when target not met")
    }

    // MARK: - Schedule-Specific Tests

    @Test("Daily habit is scheduled every day")
    func dailyHabitScheduledEveryDay() async throws {
        // Arrange: Create daily habit
        let habit = HabitBuilder.binary(schedule: .daily)

        // Act & Assert: Check multiple dates
        let dates = [TestDates.today, TestDates.yesterday, TestDates.tomorrow]
        for date in dates {
            let isScheduled = service.isScheduledDay(habit: habit, date: date)
            #expect(isScheduled == true, "Daily habit should be scheduled on \(date)")
        }
    }

    @Test("DaysOfWeek habit scheduled only on specified days")
    func daysOfWeekHabitScheduledOnlyOnSpecifiedDays() async throws {
        // Arrange: Create Mon/Wed/Fri habit
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([1, 3, 5])  // Mon, Wed, Fri
        )

        // Act: Check if Monday is scheduled (Nov 11, 2025 is a Tuesday)
        // We need to use actual Mon/Wed/Fri dates
        let mondayDate = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 3,  // Monday
            hour: 12, minute: 0,
            timezone: .current
        )
        let tuesdayDate = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 4,  // Tuesday
            hour: 12, minute: 0,
            timezone: .current
        )
        let wednesdayDate = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 5,  // Wednesday
            hour: 12, minute: 0,
            timezone: .current
        )

        // Assert
        #expect(service.isScheduledDay(habit: habit, date: mondayDate) == true, "Mon/Wed/Fri habit should be scheduled on Monday")
        #expect(service.isScheduledDay(habit: habit, date: tuesdayDate) == false, "Mon/Wed/Fri habit should NOT be scheduled on Tuesday")
        #expect(service.isScheduledDay(habit: habit, date: wednesdayDate) == true, "Mon/Wed/Fri habit should be scheduled on Wednesday")
    }

    @Test("DaysOfWeek habit completed only when logged on scheduled day")
    func daysOfWeekHabitCompletedOnlyOnScheduledDay() async throws {
        // Arrange: Create Mon/Wed/Fri habit
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([1, 3, 5])
        )

        let mondayDate = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 3,
            hour: 12, minute: 0,
            timezone: .current
        )
        let mondayLog = HabitLogBuilder.binary(habitId: habit.id, date: mondayDate)

        // Act: Check completion on Monday
        let isCompleted = service.isCompleted(habit: habit, on: mondayDate, logs: [mondayLog])

        // Assert
        #expect(isCompleted == true, "Mon/Wed/Fri habit should be completed when logged on Monday")
    }

    // MARK: - Progress Calculation Tests

    @Test("Daily progress is 1.0 when habit completed")
    func dailyProgressOneWhenCompleted() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)
        let log = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)

        // Act
        let progress = service.calculateDailyProgress(habit: habit, logs: [log], for: TestDates.today)

        // Assert
        #expect(progress == 1.0, "Daily progress should be 1.0 when habit is completed")
    }

    @Test("Daily progress is 0.0 when habit not completed")
    func dailyProgressZeroWhenNotCompleted() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)

        // Act
        let progress = service.calculateDailyProgress(habit: habit, logs: [], for: TestDates.today)

        // Assert
        #expect(progress == 0.0, "Daily progress should be 0.0 when habit is not completed")
    }

    @Test("Overall progress calculated correctly for date range")
    func overallProgressCalculatedCorrectly() async throws {
        // Arrange: Create habit with 3 days of logs
        let habit = HabitBuilder.binary(schedule: .daily)
        let threeDaysAgo = CalendarUtils.addDays(-3, to: TestDates.today)
        let twoDaysAgo = CalendarUtils.addDays(-2, to: TestDates.today)

        // Logged on 2 out of 4 days
        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: threeDaysAgo),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)
        ]

        // Act: Calculate progress from 3 days ago to today (4 days total)
        let progress = service.calculateProgress(
            habit: habit,
            logs: logs,
            from: threeDaysAgo,
            to: TestDates.today
        )

        // Assert: 2 completed out of 4 days = 0.5 (50%)
        #expect(progress == 0.5, "Progress should be 50% when 2 out of 4 days completed")
    }

    @Test("Expected completions calculated correctly for daily habit")
    func expectedCompletionsCalculatedForDailyHabit() async throws {
        // Arrange: Create daily habit
        let habit = HabitBuilder.binary(schedule: .daily)
        let startDate = TestDates.today
        let endDate = CalendarUtils.addDays(6, to: startDate)  // 7 days total

        // Act
        let expected = service.getExpectedCompletions(habit: habit, from: startDate, to: endDate)

        // Assert
        #expect(expected == 7, "Daily habit should expect 7 completions over 7 days")
    }

    @Test("Expected completions calculated correctly for daysOfWeek habit")
    func expectedCompletionsCalculatedForDaysOfWeekHabit() async throws {
        // Arrange: Define the date range for testing
        let startDate = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 3,  // Monday
            hour: 12, minute: 0,
            timezone: .current
        )
        let endDate = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 9,  // Sunday
            hour: 12, minute: 0,
            timezone: .current
        )

        // Create Mon/Wed/Fri habit starting at the beginning of our date range
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([1, 3, 5]),
            startDate: startDate
        )

        // Act
        let expected = service.getExpectedCompletions(habit: habit, from: startDate, to: endDate)

        // Assert: Should expect 3 completions (Mon, Wed, Fri)
        #expect(expected == 3, "Mon/Wed/Fri habit should expect 3 completions in one week")
    }
}

// MARK: - Timezone Edge Cases

@Suite("HabitCompletionService - Timezone Edge Cases")
struct HabitCompletionServiceTimezoneTests {

    let service = DefaultHabitCompletionService()

    @Test("Late-night logging (11:30 PM) counts for same day, not next day")
    func lateNightLoggingCountsForSameDay() async throws {
        // Arrange: Use pre-built late-night scenario
        let scenario = TimezoneEdgeCaseFixtures.lateNightLoggingScenario(
            timezone: TimezoneTestHelpers.tokyo
        )

        // Get the first log (11:30 PM on Nov 8)
        let lateNightLog = scenario.logs.first!

        // Create the "expected day" - Nov 8 at noon
        let nov8Noon = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 8,
            hour: 12, minute: 0,
            timezone: TimezoneTestHelpers.tokyo
        )

        // Act: Check if completed on Nov 8
        let isCompletedNov8 = service.isCompleted(
            habit: scenario.habit,
            on: nov8Noon,
            logs: [lateNightLog]
        )

        // Create the "next day" - Nov 9 at noon
        let nov9Noon = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 9,
            hour: 12, minute: 0,
            timezone: TimezoneTestHelpers.tokyo
        )

        // Check if completed on Nov 9 (should be false)
        let isCompletedNov9 = service.isCompleted(
            habit: scenario.habit,
            on: nov9Noon,
            logs: [lateNightLog]
        )

        // Assert
        #expect(isCompletedNov8 == true, "Log at 11:30 PM on Nov 8 should count for Nov 8")
        #expect(isCompletedNov9 == false, "Log at 11:30 PM on Nov 8 should NOT count for Nov 9")
    }

    @Test("Midnight boundary edge case: 11:59 PM and 12:01 AM are different days")
    func midnightBoundaryEdgeCase() async throws {
        // Arrange: Use midnight boundary scenario
        let scenario = TimezoneEdgeCaseFixtures.midnightBoundaryScenario(
            timezone: TimezoneTestHelpers.newYork
        )

        // Scenario has 2 logs: one at 11:59:59 PM Friday, one at 12:01 AM Saturday
        let fridayLog = scenario.logs[0]
        let saturdayLog = scenario.logs[1]

        // Create Friday noon and Saturday noon for checking
        let fridayNoon = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 8,
            hour: 12, minute: 0,
            timezone: TimezoneTestHelpers.newYork
        )
        let saturdayNoon = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 9,
            hour: 12, minute: 0,
            timezone: TimezoneTestHelpers.newYork
        )

        // Act & Assert: Friday log should count for Friday only
        let fridayCompleted = service.isCompleted(
            habit: scenario.habit,
            on: fridayNoon,
            logs: [fridayLog]
        )
        #expect(fridayCompleted == true, "11:59:59 PM Friday log should count for Friday")

        let saturdayFromFridayLog = service.isCompleted(
            habit: scenario.habit,
            on: saturdayNoon,
            logs: [fridayLog]
        )
        #expect(saturdayFromFridayLog == false, "11:59:59 PM Friday log should NOT count for Saturday")

        // Act & Assert: Saturday log should count for Saturday only
        let saturdayCompleted = service.isCompleted(
            habit: scenario.habit,
            on: saturdayNoon,
            logs: [saturdayLog]
        )
        #expect(saturdayCompleted == true, "12:01 AM Saturday log should count for Saturday")
    }

    @Test("Week boundary: Sunday 11:59 PM counts for current week")
    func weekBoundaryEdgeCase() async throws {
        // Arrange: Use week boundary scenario
        let scenario = TimezoneEdgeCaseFixtures.weekBoundaryScenario(
            timezone: TimezoneTestHelpers.newYork
        )

        // The scenario includes a log at Sunday 11:59 PM
        let sundayLateLog = scenario.logs.last! // Last log is Sunday night

        // Create Sunday noon for checking
        let sundayNoon = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 10,  // Sunday
            hour: 12, minute: 0,
            timezone: TimezoneTestHelpers.newYork
        )

        // Act: Check if completed on Sunday
        let isCompleted = service.isCompleted(
            habit: scenario.habit,
            on: sundayNoon,
            logs: [sundayLateLog]
        )

        // Assert
        #expect(isCompleted == true, "Log at Sunday 11:59 PM should count for Sunday (same week)")
    }

    @Test("Timezone transition: Logs in different timezones count correctly")
    func timezoneTransitionLogsCountCorrectly() async throws {
        // Arrange: Use timezone transition scenario (Tokyo → New York)
        let scenario = TimezoneEdgeCaseFixtures.timezoneTransitionScenario()

        // Scenario has 2 logs: one in Tokyo on Nov 8, one in New York on Nov 9
        let tokyoLog = scenario.logs[0]
        let newYorkLog = scenario.logs[1]

        // Create Nov 8 noon Tokyo and Nov 9 noon New York
        let nov8Tokyo = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 8,
            hour: 12, minute: 0,
            timezone: TimezoneTestHelpers.tokyo
        )
        let nov9NewYork = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 9,
            hour: 12, minute: 0,
            timezone: TimezoneTestHelpers.newYork
        )

        // Act & Assert: Tokyo log counts for Nov 8
        let nov8Completed = service.isCompleted(
            habit: scenario.habit,
            on: nov8Tokyo,
            logs: [tokyoLog]
        )
        #expect(nov8Completed == true, "Tokyo log should count for Nov 8 Tokyo time")

        // Act & Assert: New York log counts for Nov 9
        let nov9Completed = service.isCompleted(
            habit: scenario.habit,
            on: nov9NewYork,
            logs: [newYorkLog]
        )
        #expect(nov9Completed == true, "New York log should count for Nov 9 New York time")
    }

    @Test("Multi-timezone week scenario: Streak remains unbroken across timezones")
    func multiTimezoneWeekScenario() async throws {
        // Arrange: Use multi-timezone week scenario
        let scenario = TimezoneEdgeCaseFixtures.multiTimezoneWeekScenario()

        // Scenario has 4 logs across 4 different timezones on consecutive days
        // Each log should count for its respective day
        let allDates = [
            TimezoneTestHelpers.createDate(year: 2025, month: 11, day: 3, hour: 12, minute: 0, timezone: TimezoneTestHelpers.utc),
            TimezoneTestHelpers.createDate(year: 2025, month: 11, day: 4, hour: 12, minute: 0, timezone: TimezoneTestHelpers.tokyo),
            TimezoneTestHelpers.createDate(year: 2025, month: 11, day: 5, hour: 12, minute: 0, timezone: TimezoneTestHelpers.newYork),
            TimezoneTestHelpers.createDate(year: 2025, month: 11, day: 6, hour: 12, minute: 0, timezone: TimezoneTestHelpers.sydney)
        ]

        // Act & Assert: Each day should be completed
        for (index, date) in allDates.enumerated() {
            let log = scenario.logs[index]
            let isCompleted = service.isCompleted(
                habit: scenario.habit,
                on: date,
                logs: [log]
            )
            #expect(isCompleted == true, "Day \(index + 1) should be completed despite timezone changes")
        }

        // Act: Calculate progress for all 4 days
        let progress = service.calculateProgress(
            habit: scenario.habit,
            logs: scenario.logs,
            from: allDates.first!,
            to: allDates.last!
        )

        // Assert: Should have 100% completion (4 out of 4 days)
        #expect(progress == 1.0, "Progress should be 100% for all 4 consecutive days logged")
    }

    @Test("Numeric habit with timezone transition aggregates correctly")
    func numericHabitTimezoneTransition() async throws {
        // Arrange: Use numeric habit timezone scenario
        let scenario = TimezoneEdgeCaseFixtures.numericHabitTimezoneScenario()

        // Scenario:
        // - Day 1: 6 glasses in Tokyo (below target of 8)
        // - Day 2: 8 glasses in New York (meets target)
        // - Day 3: 10 glasses in New York (exceeds target)

        let day1Date = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 8,
            hour: 14, minute: 0,
            timezone: TimezoneTestHelpers.tokyo
        )
        let day2Date = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 9,
            hour: 14, minute: 0,
            timezone: TimezoneTestHelpers.newYork
        )
        let day3Date = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 10,
            hour: 14, minute: 0,
            timezone: TimezoneTestHelpers.newYork
        )

        // Act & Assert
        let day1Completed = service.isCompleted(habit: scenario.habit, on: day1Date, logs: [scenario.logs[0]])
        #expect(day1Completed == false, "Day 1: 6 glasses should NOT meet target of 8")

        let day2Completed = service.isCompleted(habit: scenario.habit, on: day2Date, logs: [scenario.logs[1]])
        #expect(day2Completed == true, "Day 2: 8 glasses should meet target of 8")

        let day3Completed = service.isCompleted(habit: scenario.habit, on: day3Date, logs: [scenario.logs[2]])
        #expect(day3Completed == true, "Day 3: 10 glasses should exceed target of 8")
    }
}

// MARK: - Error Path Tests

@Suite("HabitCompletionService - Error Paths & Edge Cases")
struct HabitCompletionServiceErrorTests {

    let service = DefaultHabitCompletionService()

    @Test("Empty logs array handles gracefully")
    func emptyLogsHandlesGracefully() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)

        // Act
        let isCompleted = service.isCompleted(habit: habit, on: TestDates.today, logs: [])

        // Assert
        #expect(isCompleted == false, "Habit with no logs should return false, not crash")
    }

    @Test("Logs for different habit ID do not count")
    func logsForDifferentHabitDoNotCount() async throws {
        // Arrange
        let habit1 = HabitBuilder.binary(name: "Habit 1", schedule: .daily)
        let habit2 = HabitBuilder.binary(name: "Habit 2", schedule: .daily)

        let logForHabit2 = HabitLogBuilder.binary(habitId: habit2.id, date: TestDates.today)

        // Act: Check habit1 with habit2's log
        let isCompleted = service.isCompleted(habit: habit1, on: TestDates.today, logs: [logForHabit2])

        // Assert
        #expect(isCompleted == false, "Logs for different habit should not count")
    }

    @Test("Future date logs do not affect today's completion")
    func futureDateLogsDoNotAffectToday() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)
        let futureLog = HabitLogBuilder.binary(
            habitId: habit.id,
            date: CalendarUtils.addDays(5, to: TestDates.today)
        )

        // Act: Check completion for today
        let isCompleted = service.isCompleted(habit: habit, on: TestDates.today, logs: [futureLog])

        // Assert
        #expect(isCompleted == false, "Future logs should not count for today")
    }

    @Test("Past date logs do not affect today's completion")
    func pastDateLogsDoNotAffectToday() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)
        let pastLog = HabitLogBuilder.binary(
            habitId: habit.id,
            date: CalendarUtils.addDays(-5, to: TestDates.today)
        )

        // Act: Check completion for today
        let isCompleted = service.isCompleted(habit: habit, on: TestDates.today, logs: [pastLog])

        // Assert
        #expect(isCompleted == false, "Past logs should not count for today")
    }

    @Test("Progress calculation with no logs returns 0.0")
    func progressWithNoLogsReturnsZero() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)
        let startDate = TestDates.today
        let endDate = CalendarUtils.addDays(6, to: startDate)

        // Act
        let progress = service.calculateProgress(habit: habit, logs: [], from: startDate, to: endDate)

        // Assert
        #expect(progress == 0.0, "Progress with no logs should be 0.0")
    }

    @Test("Expected completions handles habit with end date")
    func expectedCompletionsHandlesEndDate() async throws {
        // Arrange: Create habit that ends in 3 days
        let habit = Habit(
            id: UUID(),
            name: "Limited Habit",
            colorHex: "#2DA9E3",
            emoji: "🎯",
            kind: .binary,
            unitLabel: nil,
            dailyTarget: nil,
            schedule: .daily,
            reminders: [],
            startDate: TestDates.today,
            endDate: CalendarUtils.addDays(2, to: TestDates.today),  // Ends in 3 days
            isActive: true,
            displayOrder: 0,
            categoryId: nil,
            suggestionId: nil,
            isPinned: false,
            notes: nil,
            lastCompletedDate: nil,
            archivedDate: nil,
            locationConfiguration: nil,
            priorityLevel: nil
        )

        let startDate = TestDates.today
        let endDate = CalendarUtils.addDays(6, to: startDate)  // Query for 7 days

        // Act
        let expected = service.getExpectedCompletions(habit: habit, from: startDate, to: endDate)

        // Assert: Should only expect 3 completions (habit ends after day 3)
        #expect(expected == 3, "Expected completions should respect habit end date")
    }

    @Test("Expected completions handles habit that hasn't started yet")
    func expectedCompletionsHandlesHabitNotStarted() async throws {
        // Arrange: Create habit that starts in the future
        let futureStart = CalendarUtils.addDays(5, to: TestDates.today)
        let habit = Habit(
            id: UUID(),
            name: "Future Habit",
            colorHex: "#2DA9E3",
            emoji: "🎯",
            kind: .binary,
            unitLabel: nil,
            dailyTarget: nil,
            schedule: .daily,
            reminders: [],
            startDate: futureStart,
            endDate: nil,
            isActive: true,
            displayOrder: 0,
            categoryId: nil,
            suggestionId: nil,
            isPinned: false,
            notes: nil,
            lastCompletedDate: nil,
            archivedDate: nil,
            locationConfiguration: nil,
            priorityLevel: nil
        )

        // Act: Query for date range before habit starts
        let expected = service.getExpectedCompletions(
            habit: habit,
            from: TestDates.today,
            to: CalendarUtils.addDays(3, to: TestDates.today)
        )

        // Assert: Should expect 0 completions (habit hasn't started)
        #expect(expected == 0, "Expected completions should be 0 for habit that hasn't started")
    }
}
