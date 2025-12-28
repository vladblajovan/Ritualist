//
//  DSTComprehensiveTests.swift
//  RitualistTests
//
//  Created by Claude on 22.12.2025.
//
//  Comprehensive test coverage for Daylight Saving Time (DST) transitions.
//  Tests streak calculations, week boundaries, and habit completion during:
//  - US Spring Forward (March 9, 2025): 2:00 AM -> 3:00 AM (23-hour day)
//  - US Fall Back (November 2, 2025): 2:00 AM -> 1:00 AM (25-hour day)
//  - EU Spring Forward (March 30, 2025): 1:00 AM -> 2:00 AM
//  - EU Fall Back (October 26, 2025): 2:00 AM -> 1:00 AM
//

import Foundation
import Testing
@testable import RitualistCore

// MARK: - US DST Streak Tests

@Suite("DST - US Streak Continuity")
@MainActor
struct USDSTStreakTests {

    let completionService = DefaultHabitCompletionService()
    let logger = DebugLogger()

    var streakService: StreakCalculationService {
        DefaultStreakCalculationService(
            habitCompletionService: completionService,
            logger: logger
        )
    }

    @Test("7-day streak across US spring forward maintains continuity")
    func sevenDayStreakAcrossUSSpringForward() async throws {
        // Arrange
        let scenario = TimezoneEdgeCaseFixtures.dstStreakAcrossSpringForwardScenario()

        // The last day of the week (March 12)
        let asOfDate = TimezoneTestHelpers.weekContainingUSSpringForward().last!

        // Act
        let streak = streakService.calculateCurrentStreak(
            habit: scenario.habit,
            logs: scenario.logs,
            asOf: asOfDate,
            timezone: TimezoneTestHelpers.newYork
        )

        // Assert
        #expect(streak == 7, "7-day streak should remain unbroken across spring forward (23-hour day)")
    }

    @Test("7-day streak across US fall back maintains continuity")
    func sevenDayStreakAcrossUSFallBack() async throws {
        // Arrange
        let scenario = TimezoneEdgeCaseFixtures.dstStreakAcrossFallBackScenario()

        // The last day of the week (November 5)
        let asOfDate = TimezoneTestHelpers.weekContainingUSFallBack().last!

        // Act
        let streak = streakService.calculateCurrentStreak(
            habit: scenario.habit,
            logs: scenario.logs,
            asOf: asOfDate,
            timezone: TimezoneTestHelpers.newYork
        )

        // Assert
        #expect(streak == 7, "7-day streak should remain unbroken across fall back (25-hour day)")
    }

    @Test("Streak status correctly identifies at-risk on DST day")
    func streakStatusOnDSTDay() async throws {
        // Arrange: 6-day streak, DST day not yet logged
        let weekDates = TimezoneTestHelpers.weekContainingUSSpringForward()
        let startDate = CalendarUtils.startOfDayLocal(for: weekDates.first!, timezone: TimezoneTestHelpers.newYork)

        let habit = HabitBuilder.binary(
            name: "Test Habit",
            emoji: "🧪",
            schedule: .daily,
            startDate: startDate
        )

        // Log for first 6 days (March 6-11), skip March 12
        let logs = weekDates.dropLast().map { date in
            HabitLogBuilder.binary(
                habitId: habit.id,
                date: CalendarUtils.startOfDayLocal(for: date, timezone: TimezoneTestHelpers.newYork),
                timezone: TimezoneTestHelpers.newYork.identifier
            )
        }

        // Act: Check status on the 7th day (March 12) before logging
        let asOfDate = weekDates.last!
        let status = streakService.getStreakStatus(
            habit: habit,
            logs: logs,
            asOf: asOfDate,
            timezone: TimezoneTestHelpers.newYork
        )

        // Assert: When today is scheduled but not logged, current=0 and atRisk=6
        // The displayStreak property returns atRisk when isAtRisk is true
        #expect(status.atRisk == 6, "At-risk streak should be 6 (days logged before today)")
        #expect(status.current == 0, "Current streak should be 0 (today scheduled but not logged)")
        #expect(status.isAtRisk == true, "Streak should be at risk (not logged for today)")
        #expect(status.displayStreak == 6, "Display streak should show at-risk value")
    }
}

// MARK: - EU DST Tests

@Suite("DST - EU Timezone Coverage")
@MainActor
struct EUDSTTests {

    let completionService = DefaultHabitCompletionService()
    let logger = DebugLogger()

    var streakService: StreakCalculationService {
        DefaultStreakCalculationService(
            habitCompletionService: completionService,
            logger: logger
        )
    }

    @Test("EU spring forward (March 30) calculates correct day boundaries")
    func euSpringForwardDayBoundaries() {
        let london = TimezoneTestHelpers.london

        // Before DST: March 30, 2025 at 00:30 AM GMT
        let beforeDst = TimezoneTestHelpers.euDstSpringForwardDate()

        // After DST: March 30, 2025 at 3:30 AM BST
        let afterDst = TimezoneTestHelpers.createDate(
            year: 2025, month: 3, day: 30,
            hour: 3, minute: 30,
            timezone: london
        )

        let beforeStart = CalendarUtils.startOfDayLocal(for: beforeDst, timezone: london)
        let afterStart = CalendarUtils.startOfDayLocal(for: afterDst, timezone: london)

        // Both should be the same calendar day (March 30)
        #expect(beforeStart == afterStart, "Before and after EU spring forward should be same calendar day")
    }

    @Test("EU fall back (October 26) calculates correct day boundaries")
    func euFallBackDayBoundaries() {
        let london = TimezoneTestHelpers.london

        // Before fall back: October 26, 2025 at 00:30 AM BST
        let beforeFallBack = TimezoneTestHelpers.euDstFallBackDate()

        // After fall back: October 26, 2025 at 3:30 AM GMT
        let afterFallBack = TimezoneTestHelpers.createDate(
            year: 2025, month: 10, day: 26,
            hour: 3, minute: 30,
            timezone: london
        )

        let beforeStart = CalendarUtils.startOfDayLocal(for: beforeFallBack, timezone: london)
        let afterStart = CalendarUtils.startOfDayLocal(for: afterFallBack, timezone: london)

        // Both should be the same calendar day (October 26)
        #expect(beforeStart == afterStart, "Before and after EU fall back should be same calendar day")
    }

    @Test("EU DST scenario logs count for correct days")
    func euDstScenarioLogsCountCorrectly() async throws {
        // Arrange
        let scenario = TimezoneEdgeCaseFixtures.euDstTransitionScenario()
        let london = TimezoneTestHelpers.london

        // Act: Verify each log is on its expected date
        let springForwardLog = scenario.logs[0]
        let fallBackLog = scenario.logs[1]

        let springForwardDay = TimezoneTestHelpers.calendarDay(for: springForwardLog.date, in: london)
        let fallBackDay = TimezoneTestHelpers.calendarDay(for: fallBackLog.date, in: london)

        // Assert
        #expect(springForwardDay.month == 3 && springForwardDay.day == 30, "Spring forward log should be March 30")
        #expect(fallBackDay.month == 10 && fallBackDay.day == 26, "Fall back log should be October 26")
    }

    @Test("7-day streak across EU spring forward maintains continuity")
    func sevenDayStreakAcrossEUSpringForward() async throws {
        // Arrange
        let weekDates = TimezoneTestHelpers.weekContainingEUSpringForward()
        let startDate = CalendarUtils.startOfDayLocal(for: weekDates.first!, timezone: TimezoneTestHelpers.london)

        let habit = HabitBuilder.binary(
            name: "EU Test Habit",
            emoji: "🇬🇧",
            schedule: .daily,
            startDate: startDate
        )

        let logs = weekDates.map { date in
            HabitLogBuilder.binary(
                habitId: habit.id,
                date: CalendarUtils.startOfDayLocal(for: date, timezone: TimezoneTestHelpers.london),
                timezone: TimezoneTestHelpers.london.identifier
            )
        }

        let asOfDate = weekDates.last!

        // Act
        let streak = streakService.calculateCurrentStreak(
            habit: habit,
            logs: logs,
            asOf: asOfDate,
            timezone: TimezoneTestHelpers.london
        )

        // Assert
        #expect(streak == 7, "7-day streak should remain unbroken across EU spring forward")
    }
}

// MARK: - DST Week Calculation Tests

@Suite("DST - Week Calculations")
@MainActor
struct DSTWeekCalculationTests {

    let analyzer = HabitScheduleAnalyzer()

    /// Helper to convert calendar day tuple to string for Set uniqueness
    private func dayString(for date: Date, in timezone: TimeZone) -> String {
        let day = TimezoneTestHelpers.calendarDay(for: date, in: timezone)
        return "\(day.year)-\(day.month)-\(day.day)"
    }

    @Test("Week containing US spring forward has 7 calendar days")
    func weekWithUSSpringForwardHasSevenDays() {
        let weekDates = TimezoneTestHelpers.weekContainingUSSpringForward()

        #expect(weekDates.count == 7, "Week should have 7 dates")

        // Verify all dates are distinct calendar days
        let uniqueDays = Set(weekDates.map { date in
            dayString(for: date, in: TimezoneTestHelpers.newYork)
        })

        #expect(uniqueDays.count == 7, "All 7 dates should be distinct calendar days")
    }

    @Test("Week containing US fall back has 7 calendar days")
    func weekWithUSFallBackHasSevenDays() {
        let weekDates = TimezoneTestHelpers.weekContainingUSFallBack()

        #expect(weekDates.count == 7, "Week should have 7 dates")

        // Verify all dates are distinct calendar days
        let uniqueDays = Set(weekDates.map { date in
            dayString(for: date, in: TimezoneTestHelpers.newYork)
        })

        #expect(uniqueDays.count == 7, "All 7 dates should be distinct calendar days")
    }

    @Test("Week containing EU spring forward has 7 calendar days")
    func weekWithEUSpringForwardHasSevenDays() {
        let weekDates = TimezoneTestHelpers.weekContainingEUSpringForward()

        #expect(weekDates.count == 7, "Week should have 7 dates")

        // Verify all dates are distinct calendar days
        let uniqueDays = Set(weekDates.map { date in
            dayString(for: date, in: TimezoneTestHelpers.london)
        })

        #expect(uniqueDays.count == 7, "All 7 dates should be distinct calendar days")
    }

    @Test("Week containing EU fall back has 7 calendar days")
    func weekWithEUFallBackHasSevenDays() {
        let weekDates = TimezoneTestHelpers.weekContainingEUFallBack()

        #expect(weekDates.count == 7, "Week should have 7 dates")

        // Verify all dates are distinct calendar days
        let uniqueDays = Set(weekDates.map { date in
            dayString(for: date, in: TimezoneTestHelpers.london)
        })

        #expect(uniqueDays.count == 7, "All 7 dates should be distinct calendar days")
    }

    @Test("Expected days calculation handles spring forward week correctly")
    func expectedDaysHandlesSpringForwardWeek() async throws {
        // Arrange
        let weekDates = TimezoneTestHelpers.weekContainingUSSpringForward()
        let startDate = weekDates.first!
        let endDate = weekDates.last!

        // Habit must start before or on the range start date
        let habit = HabitBuilder.binary(schedule: .daily, startDate: startDate)

        // Act
        let expectedDays = analyzer.calculateExpectedDays(
            for: habit,
            from: startDate,
            to: endDate,
            timezone: TimezoneTestHelpers.newYork
        )

        // Assert
        #expect(expectedDays == 7, "Daily habit should expect 7 days even with 23-hour day")
    }

    @Test("Expected days calculation handles fall back week correctly")
    func expectedDaysHandlesFallBackWeek() async throws {
        // Arrange
        let weekDates = TimezoneTestHelpers.weekContainingUSFallBack()
        let startDate = weekDates.first!
        let endDate = weekDates.last!

        // Habit must start before or on the range start date
        let habit = HabitBuilder.binary(schedule: .daily, startDate: startDate)

        // Act
        let expectedDays = analyzer.calculateExpectedDays(
            for: habit,
            from: startDate,
            to: endDate,
            timezone: TimezoneTestHelpers.newYork
        )

        // Assert
        #expect(expectedDays == 7, "Daily habit should expect 7 days even with 25-hour day")
    }
}

// MARK: - DST Same-Day Multiple Logs Tests

@Suite("DST - Same Day Multiple Logs")
@MainActor
struct DSTSameDayLogsTests {

    @Test("Logs before and after spring forward count as same day")
    func logsBeforeAndAfterSpringForwardSameDay() {
        // Arrange
        let scenario = TimezoneEdgeCaseFixtures.dstSameDayMultipleLogsScenario()
        let newYork = TimezoneTestHelpers.newYork

        // Act: Get start of day for both logs
        let log1Start = CalendarUtils.startOfDayLocal(for: scenario.logs[0].date, timezone: newYork)
        let log2Start = CalendarUtils.startOfDayLocal(for: scenario.logs[1].date, timezone: newYork)

        // Assert
        #expect(log1Start == log2Start, "Both logs should have same start of day")

        // Verify it's March 9
        let day = TimezoneTestHelpers.calendarDay(for: log1Start, in: newYork)
        #expect(day.month == 3 && day.day == 9, "Logs should be for March 9 (spring forward day)")
    }

    @Test("Logs during fall back repeated hour count as same day")
    func logsDuringFallBackRepeatedHourSameDay() {
        // Arrange
        let scenario = TimezoneEdgeCaseFixtures.dstFallBackRepeatedHourScenario()
        let newYork = TimezoneTestHelpers.newYork

        // Act: Get start of day for both logs
        let log1Start = CalendarUtils.startOfDayLocal(for: scenario.logs[0].date, timezone: newYork)
        let log2Start = CalendarUtils.startOfDayLocal(for: scenario.logs[1].date, timezone: newYork)

        // Assert
        #expect(log1Start == log2Start, "Both logs should have same start of day")

        // Verify it's November 2
        let day = TimezoneTestHelpers.calendarDay(for: log1Start, in: newYork)
        #expect(day.month == 11 && day.day == 2, "Logs should be for November 2 (fall back day)")
    }

    @Test("Numeric habit aggregates values correctly on spring forward day")
    func numericHabitAggregatesOnSpringForwardDay() {
        // Arrange
        let scenario = TimezoneEdgeCaseFixtures.dstSameDayMultipleLogsScenario()
        let newYork = TimezoneTestHelpers.newYork
        let dstDay = CalendarUtils.startOfDayLocal(for: scenario.logs[0].date, timezone: newYork)

        // Act: Filter logs for DST day and sum values
        let logsForDay = scenario.logs.filter { log in
            CalendarUtils.startOfDayLocal(for: log.date, timezone: newYork) == dstDay
        }
        let totalValue = logsForDay.reduce(0.0) { $0 + ($1.value ?? 0) }

        // Assert
        #expect(logsForDay.count == 2, "Should find 2 logs for DST day")
        #expect(totalValue == 8.0, "Total value should be 3 + 5 = 8")
    }

    @Test("Numeric habit aggregates values correctly on fall back day")
    func numericHabitAggregatesOnFallBackDay() {
        // Arrange
        let scenario = TimezoneEdgeCaseFixtures.dstFallBackRepeatedHourScenario()
        let newYork = TimezoneTestHelpers.newYork
        let dstDay = CalendarUtils.startOfDayLocal(for: scenario.logs[0].date, timezone: newYork)

        // Act: Filter logs for DST day and sum values
        let logsForDay = scenario.logs.filter { log in
            CalendarUtils.startOfDayLocal(for: log.date, timezone: newYork) == dstDay
        }
        let totalValue = logsForDay.reduce(0.0) { $0 + ($1.value ?? 0) }

        // Assert
        #expect(logsForDay.count == 2, "Should find 2 logs for DST day")
        #expect(totalValue == 11000.0, "Total value should be 5000 + 6000 = 11000")
    }
}

// MARK: - DST Completion Check Tests

@Suite("DST - Habit Completion")
@MainActor
struct DSTHabitCompletionTests {

    let calculator = DefaultScheduleAwareCompletionCalculator()

    @Test("Binary habit completion recognizes log on spring forward day")
    func binaryHabitCompletionOnSpringForwardDay() {
        // Arrange
        let scenario = TimezoneEdgeCaseFixtures.dstTransitionScenario()

        // Spring forward log (first in array)
        let springForwardDate = scenario.logs[0].date

        // Act
        let isCompleted = calculator.isHabitCompleted(
            habit: scenario.habit,
            logs: scenario.logs,
            date: springForwardDate
        )

        // Assert
        #expect(isCompleted == true, "Habit should be completed on spring forward day")
    }

    @Test("Binary habit completion recognizes log on fall back day")
    func binaryHabitCompletionOnFallBackDay() {
        // Arrange
        let scenario = TimezoneEdgeCaseFixtures.dstTransitionScenario()

        // Fall back log (second in array)
        let fallBackDate = scenario.logs[1].date

        // Act
        let isCompleted = calculator.isHabitCompleted(
            habit: scenario.habit,
            logs: scenario.logs,
            date: fallBackDate
        )

        // Assert
        #expect(isCompleted == true, "Habit should be completed on fall back day")
    }

    @Test("Numeric habit progress calculates correctly on spring forward day")
    func numericHabitProgressOnSpringForwardDay() {
        // Arrange
        let scenario = TimezoneEdgeCaseFixtures.dstSameDayMultipleLogsScenario()
        let newYork = TimezoneTestHelpers.newYork
        let dstDay = CalendarUtils.startOfDayLocal(for: scenario.logs[0].date, timezone: newYork)

        // Act: Sum logs for DST day and calculate progress
        let logsForDay = scenario.logs.filter { log in
            CalendarUtils.startOfDayLocal(for: log.date, timezone: newYork) == dstDay
        }
        let totalValue = logsForDay.reduce(0.0) { $0 + ($1.value ?? 0) }
        let target = scenario.habit.dailyTarget ?? 1.0
        let progress = totalValue / target

        // Assert: Target is 8.0, total value is 8.0, so progress should be 1.0 (100%)
        #expect(progress == 1.0, "Progress should be 100% (8/8 glasses)")
    }

    @Test("Numeric habit progress calculates correctly on fall back day")
    func numericHabitProgressOnFallBackDay() {
        // Arrange
        let scenario = TimezoneEdgeCaseFixtures.dstFallBackRepeatedHourScenario()
        let newYork = TimezoneTestHelpers.newYork
        let dstDay = CalendarUtils.startOfDayLocal(for: scenario.logs[0].date, timezone: newYork)

        // Act: Sum logs for DST day and calculate progress
        let logsForDay = scenario.logs.filter { log in
            CalendarUtils.startOfDayLocal(for: log.date, timezone: newYork) == dstDay
        }
        let totalValue = logsForDay.reduce(0.0) { $0 + ($1.value ?? 0) }
        let target = scenario.habit.dailyTarget ?? 1.0
        let progress = totalValue / target

        // Assert: Target is 10000, total value is 11000, so progress should be > 1.0
        #expect(progress >= 1.0, "Progress should be >= 100% (11000/10000 steps)")
    }
}

// MARK: - DST Schedule Analysis Tests

@Suite("DST - Schedule Analysis")
@MainActor
struct DSTScheduleAnalysisTests {

    let analyzer = HabitScheduleAnalyzer()

    @Test("Weekday habit correctly identifies scheduled day during spring forward")
    func weekdayHabitScheduleDuringSpringForward() async throws {
        // March 9, 2025 is a Sunday (NOT a weekday)
        let springForwardDate = TimezoneTestHelpers.dstSpringForwardDate()

        // Arrange: Weekday habit (Mon-Fri) with start date before the test date
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([1, 2, 3, 4, 5]),
            startDate: springForwardDate.addingTimeInterval(-86400 * 7) // 1 week before
        )

        // Act
        let isExpected = analyzer.isHabitExpectedOnDate(
            habit: habit,
            date: springForwardDate,
            timezone: TimezoneTestHelpers.newYork
        )

        // Assert
        #expect(isExpected == false, "Sunday should not be expected for Mon-Fri habit")
    }

    @Test("Daily habit is expected on spring forward day")
    func dailyHabitExpectedOnSpringForward() async throws {
        // Arrange
        let springForwardDate = TimezoneTestHelpers.dstSpringForwardDate()
        let habit = HabitBuilder.binary(
            schedule: .daily,
            startDate: springForwardDate.addingTimeInterval(-86400 * 7) // 1 week before
        )

        // Act
        let isExpected = analyzer.isHabitExpectedOnDate(
            habit: habit,
            date: springForwardDate,
            timezone: TimezoneTestHelpers.newYork
        )

        // Assert
        #expect(isExpected == true, "Daily habit should be expected on spring forward day")
    }

    @Test("Daily habit is expected on fall back day")
    func dailyHabitExpectedOnFallBack() async throws {
        // Arrange
        let fallBackDate = TimezoneTestHelpers.dstFallBackDate()
        let habit = HabitBuilder.binary(
            schedule: .daily,
            startDate: fallBackDate.addingTimeInterval(-86400 * 7) // 1 week before
        )

        // Act
        let isExpected = analyzer.isHabitExpectedOnDate(
            habit: habit,
            date: fallBackDate,
            timezone: TimezoneTestHelpers.newYork
        )

        // Assert
        #expect(isExpected == true, "Daily habit should be expected on fall back day")
    }

    @Test("Weekend habit correctly identifies fall back Sunday")
    func weekendHabitIdentifiesFallBackSunday() async throws {
        // November 2, 2025 is a Sunday
        let fallBackDate = TimezoneTestHelpers.dstFallBackDate()

        // Arrange: Weekend habit (Sat-Sun) with start date before the test date
        // Note: HabitSchedule uses 1=Mon…7=Sun, so Sat=6, Sun=7
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([6, 7]), // Sat=6, Sun=7
            startDate: fallBackDate.addingTimeInterval(-86400 * 7) // 1 week before
        )

        // Act
        let isExpected = analyzer.isHabitExpectedOnDate(
            habit: habit,
            date: fallBackDate,
            timezone: TimezoneTestHelpers.newYork
        )

        // Assert
        #expect(isExpected == true, "Sunday should be expected for weekend habit")
    }
}
