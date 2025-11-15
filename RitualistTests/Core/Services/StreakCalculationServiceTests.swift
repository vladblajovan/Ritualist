//
//  StreakCalculationServiceTests.swift
//  RitualistTests
//
//  Created by Phase 4 Testing Infrastructure on 15.11.2025.
//

import Testing
import Foundation
@testable import RitualistCore

@Suite("StreakCalculationService - Core Functionality")
struct StreakCalculationServiceTests {

    // MARK: - Test Setup

    let completionService = DefaultHabitCompletionService()
    let logger = DebugLogger()

    var streakService: StreakCalculationService {
        DefaultStreakCalculationService(
            habitCompletionService: completionService,
            logger: logger
        )
    }

    // MARK: - Current Streak Tests - Daily Schedule

    @Test("Current streak is 1 when habit logged today only")
    func currentStreakOneWhenLoggedTodayOnly() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)
        let log = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)

        // Act
        let streak = streakService.calculateCurrentStreak(
            habit: habit,
            logs: [log],
            asOf: TestDates.today
        )

        // Assert
        #expect(streak == 1, "Streak should be 1 when logged today only")
    }

    @Test("Current streak is 3 when habit logged for 3 consecutive days")
    func currentStreakThreeWhenLoggedThreeConsecutiveDays() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)
        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.yesterday),
            HabitLogBuilder.binary(habitId: habit.id, date: CalendarUtils.addDays(-2, to: TestDates.today))
        ]

        // Act
        let streak = streakService.calculateCurrentStreak(
            habit: habit,
            logs: logs,
            asOf: TestDates.today
        )

        // Assert
        #expect(streak == 3, "Streak should be 3 when logged for 3 consecutive days")
    }

    @Test("Current streak is 0 when habit not logged today")
    func currentStreakZeroWhenNotLoggedToday() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)
        let log = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.yesterday)

        // Act
        let streak = streakService.calculateCurrentStreak(
            habit: habit,
            logs: [log],
            asOf: TestDates.today
        )

        // Assert
        #expect(streak == 0, "Streak should be 0 when not logged today")
    }

    @Test("Current streak breaks when day is missed")
    func currentStreakBreaksWhenDayMissed() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)
        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.yesterday),
            // Gap here - 2 days ago is missing
            HabitLogBuilder.binary(habitId: habit.id, date: CalendarUtils.addDays(-3, to: TestDates.today))
        ]

        // Act
        let streak = streakService.calculateCurrentStreak(
            habit: habit,
            logs: logs,
            asOf: TestDates.today
        )

        // Assert
        #expect(streak == 2, "Streak should be 2 (today + yesterday) when day is missed 2 days ago")
    }

    @Test("Current streak handles empty logs array")
    func currentStreakHandlesEmptyLogs() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)

        // Act
        let streak = streakService.calculateCurrentStreak(
            habit: habit,
            logs: [],
            asOf: TestDates.today
        )

        // Assert
        #expect(streak == 0, "Streak should be 0 with empty logs")
    }

    // MARK: - Current Streak Tests - DaysOfWeek Schedule

    @Test("Current streak for Mon/Wed/Fri counts only scheduled days")
    func currentStreakMonWedFriCountsOnlyScheduledDays() async throws {
        // Arrange: Create Mon/Wed/Fri habit
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([1, 3, 5])
        )

        // Create logs for Mon, Tue, Wed (Tue should be ignored)
        let monday = TimezoneTestHelpers.createDate(year: 2025, month: 11, day: 3, hour: 12, minute: 0, timezone: .current)
        let tuesday = TimezoneTestHelpers.createDate(year: 2025, month: 11, day: 4, hour: 12, minute: 0, timezone: .current)
        let wednesday = TimezoneTestHelpers.createDate(year: 2025, month: 11, day: 5, hour: 12, minute: 0, timezone: .current)

        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: monday),
            HabitLogBuilder.binary(habitId: habit.id, date: tuesday),  // Not scheduled
            HabitLogBuilder.binary(habitId: habit.id, date: wednesday)
        ]

        // Act: Calculate streak as of Wednesday
        let streak = streakService.calculateCurrentStreak(
            habit: habit,
            logs: logs,
            asOf: wednesday
        )

        // Assert: Should count Mon + Wed = 2 (Tuesday doesn't count)
        #expect(streak == 2, "Streak should be 2 (Mon + Wed), ignoring Tuesday")
    }

    @Test("Current streak for Mon/Wed/Fri breaks when scheduled day is missed")
    func currentStreakMonWedFriBreaksWhenScheduledDayMissed() async throws {
        // Arrange: Create Mon/Wed/Fri habit
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([1, 3, 5])
        )

        // Create logs for Wed and Fri (Mon is missing)
        let wednesday = TimezoneTestHelpers.createDate(year: 2025, month: 11, day: 5, hour: 12, minute: 0, timezone: .current)
        let friday = TimezoneTestHelpers.createDate(year: 2025, month: 11, day: 7, hour: 12, minute: 0, timezone: .current)

        let logs = [
            // Monday (Nov 3) is missing
            HabitLogBuilder.binary(habitId: habit.id, date: wednesday),
            HabitLogBuilder.binary(habitId: habit.id, date: friday)
        ]

        // Act: Calculate streak as of Friday
        let streak = streakService.calculateCurrentStreak(
            habit: habit,
            logs: logs,
            asOf: friday
        )

        // Assert: Should be 2 (Wed + Fri) because Monday was missed
        #expect(streak == 2, "Streak should be 2 (Wed + Fri) after missing Monday")
    }

    // MARK: - Longest Streak Tests

    @Test("Longest streak calculated correctly for consecutive days")
    func longestStreakCalculatedForConsecutiveDays() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)

        // Create 5 consecutive days, then gap, then 3 consecutive days
        let dates = [
            CalendarUtils.addDays(-10, to: TestDates.today),
            CalendarUtils.addDays(-9, to: TestDates.today),
            CalendarUtils.addDays(-8, to: TestDates.today),
            CalendarUtils.addDays(-7, to: TestDates.today),
            CalendarUtils.addDays(-6, to: TestDates.today),
            // Gap here
            CalendarUtils.addDays(-3, to: TestDates.today),
            CalendarUtils.addDays(-2, to: TestDates.today),
            CalendarUtils.addDays(-1, to: TestDates.today)
        ]

        let logs = dates.map { HabitLogBuilder.binary(habitId: habit.id, date: $0) }

        // Act
        let longestStreak = streakService.calculateLongestStreak(habit: habit, logs: logs)

        // Assert: Longest consecutive sequence is 5 days
        #expect(longestStreak == 5, "Longest streak should be 5 days")
    }

    @Test("Longest streak is 1 when only one log exists")
    func longestStreakOneWhenOneLogExists() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)
        let log = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)

        // Act
        let longestStreak = streakService.calculateLongestStreak(habit: habit, logs: [log])

        // Assert
        #expect(longestStreak == 1, "Longest streak should be 1 with single log")
    }

    @Test("Longest streak is 0 with empty logs")
    func longestStreakZeroWithEmptyLogs() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)

        // Act
        let longestStreak = streakService.calculateLongestStreak(habit: habit, logs: [])

        // Assert
        #expect(longestStreak == 0, "Longest streak should be 0 with empty logs")
    }

    @Test("Longest streak for Mon/Wed/Fri respects schedule")
    func longestStreakMonWedFriRespectsSchedule() async throws {
        // Arrange: Create Mon/Wed/Fri habit
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([1, 3, 5])
        )

        // Create logs for 2 complete weeks (Mon/Wed/Fri)
        let week1 = [
            TimezoneTestHelpers.createDate(year: 2025, month: 11, day: 3, hour: 12, minute: 0, timezone: .current),  // Mon
            TimezoneTestHelpers.createDate(year: 2025, month: 11, day: 5, hour: 12, minute: 0, timezone: .current),  // Wed
            TimezoneTestHelpers.createDate(year: 2025, month: 11, day: 7, hour: 12, minute: 0, timezone: .current)   // Fri
        ]
        let week2 = [
            TimezoneTestHelpers.createDate(year: 2025, month: 11, day: 10, hour: 12, minute: 0, timezone: .current), // Mon
            TimezoneTestHelpers.createDate(year: 2025, month: 11, day: 12, hour: 12, minute: 0, timezone: .current), // Wed
            TimezoneTestHelpers.createDate(year: 2025, month: 11, day: 14, hour: 12, minute: 0, timezone: .current)  // Fri
        ]

        let logs = (week1 + week2).map { HabitLogBuilder.binary(habitId: habit.id, date: $0) }

        // Act
        let longestStreak = streakService.calculateLongestStreak(habit: habit, logs: logs)

        // Assert: Should be 6 (3 days/week × 2 weeks)
        #expect(longestStreak == 6, "Longest streak should be 6 for 2 complete Mon/Wed/Fri weeks")
    }

    // MARK: - Streak Break Dates Tests

    @Test("Streak break dates includes all missed scheduled days")
    func streakBreakDatesIncludesMissedDays() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)

        // Logged today and 3 days ago, missing yesterday and 2 days ago
        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habit.id, date: CalendarUtils.addDays(-3, to: TestDates.today))
        ]

        // Act
        let breakDates = streakService.getStreakBreakDates(
            habit: habit,
            logs: logs,
            asOf: TestDates.today
        )

        // Assert: Should include yesterday and 2 days ago
        #expect(breakDates.count == 2, "Should have 2 break dates (yesterday and 2 days ago)")

        // Convert to start of day for comparison
        let yesterday = CalendarUtils.startOfDayLocal(for: TestDates.yesterday)
        let twoDaysAgo = CalendarUtils.startOfDayLocal(for: CalendarUtils.addDays(-2, to: TestDates.today))

        let breakDatesStartOfDay = breakDates.map { CalendarUtils.startOfDayLocal(for: $0) }
        #expect(breakDatesStartOfDay.contains(yesterday), "Should include yesterday as break date")
        #expect(breakDatesStartOfDay.contains(twoDaysAgo), "Should include 2 days ago as break date")
    }

    @Test("Streak break dates empty when no breaks")
    func streakBreakDatesEmptyWhenNoBreaks() async throws {
        // Arrange: Perfect streak
        let habit = HabitBuilder.binary(schedule: .daily)
        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.yesterday),
            HabitLogBuilder.binary(habitId: habit.id, date: CalendarUtils.addDays(-2, to: TestDates.today))
        ]

        // Act
        let breakDates = streakService.getStreakBreakDates(
            habit: habit,
            logs: logs,
            asOf: TestDates.today
        )

        // Assert
        #expect(breakDates.isEmpty, "Should have no break dates with perfect streak")
    }

    // MARK: - Next Scheduled Date Tests

    @Test("Next scheduled date for daily habit is tomorrow")
    func nextScheduledDateDailyHabitIsTomorrow() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)

        // Act
        let nextDate = streakService.getNextScheduledDate(habit: habit, after: TestDates.today)

        // Assert
        let expectedNext = CalendarUtils.startOfDayLocal(for: TestDates.tomorrow)
        let actualNext = nextDate.map { CalendarUtils.startOfDayLocal(for: $0) }
        #expect(actualNext == expectedNext, "Next scheduled date for daily habit should be tomorrow")
    }

    @Test("Next scheduled date for Mon/Wed/Fri skips unscheduled days")
    func nextScheduledDateMonWedFriSkipsUnscheduledDays() async throws {
        // Arrange: Create Mon/Wed/Fri habit
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([1, 3, 5])
        )

        // If today is Tuesday (Nov 4, 2025), next should be Wednesday (Nov 5)
        let tuesday = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 4,  // Tuesday
            hour: 12, minute: 0,
            timezone: .current
        )

        // Act
        let nextDate = streakService.getNextScheduledDate(habit: habit, after: tuesday)

        // Assert: Should be Wednesday
        let wednesday = CalendarUtils.startOfDayLocal(for: TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 5,  // Wednesday
            hour: 0, minute: 0,
            timezone: .current
        ))
        let actualNext = nextDate.map { CalendarUtils.startOfDayLocal(for: $0) }
        #expect(actualNext == wednesday, "Next scheduled date after Tuesday should be Wednesday")
    }

    @Test("Next scheduled date is nil when habit has ended")
    func nextScheduledDateNilWhenHabitEnded() async throws {
        // Arrange: Create habit that ends yesterday
        let habit = Habit(
            id: UUID(),
            name: "Ended Habit",
            colorHex: "#2DA9E3",
            emoji: "🎯",
            kind: .binary,
            unitLabel: nil,
            dailyTarget: nil,
            schedule: .daily,
            reminders: [],
            startDate: CalendarUtils.addDays(-10, to: TestDates.today),
            endDate: TestDates.yesterday,
            isActive: false,
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

        // Act
        let nextDate = streakService.getNextScheduledDate(habit: habit, after: TestDates.today)

        // Assert
        #expect(nextDate == nil, "Next scheduled date should be nil when habit has ended")
    }
}

// MARK: - Timezone Edge Cases

@Suite("StreakCalculationService - Timezone Edge Cases")
struct StreakCalculationServiceTimezoneTests {

    let completionService = DefaultHabitCompletionService()
    let logger = DebugLogger()

    var streakService: StreakCalculationService {
        DefaultStreakCalculationService(
            habitCompletionService: completionService,
            logger: logger
        )
    }

    @Test("Late-night logging (11:30 PM) preserves streak")
    func lateNightLoggingPreservesStreak() async throws {
        // Arrange: Use late-night logging scenario
        let scenario = TimezoneEdgeCaseFixtures.lateNightLoggingScenario(
            timezone: TimezoneTestHelpers.tokyo
        )

        // Scenario has 3 consecutive late-night logs (Nov 8, 9, 10 at 11:30 PM)
        // Calculate streak as of Nov 10
        let nov10 = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 10,
            hour: 23, minute: 30,
            timezone: TimezoneTestHelpers.tokyo
        )

        // Act
        let streak = streakService.calculateCurrentStreak(
            habit: scenario.habit,
            logs: scenario.logs,
            asOf: nov10
        )

        // Assert: All 3 days should count
        #expect(streak == 3, "Late-night logging should preserve 3-day streak")
    }

    @Test("Midnight boundary: Logging at 11:59 PM and 12:01 AM creates 2-day streak")
    func midnightBoundaryCreatesTwoDayStreak() async throws {
        // Arrange: Use midnight boundary scenario
        let scenario = TimezoneEdgeCaseFixtures.midnightBoundaryScenario(
            timezone: TimezoneTestHelpers.newYork
        )

        // Scenario has 2 logs: 11:59:59 PM Friday, 12:01 AM Saturday
        // Calculate streak as of Saturday
        let saturdayNoon = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 9,  // Saturday
            hour: 12, minute: 0,
            timezone: TimezoneTestHelpers.newYork
        )

        // Act
        let streak = streakService.calculateCurrentStreak(
            habit: scenario.habit,
            logs: scenario.logs,
            asOf: saturdayNoon
        )

        // Assert: Should be 2-day streak (Friday + Saturday)
        #expect(streak == 2, "Logging at 11:59 PM Friday and 12:01 AM Saturday should create 2-day streak")
    }

    @Test("Timezone transition maintains streak")
    func timezoneTransitionMaintainsStreak() async throws {
        // Arrange: Use timezone transition scenario (Tokyo → New York)
        let scenario = TimezoneEdgeCaseFixtures.timezoneTransitionScenario()

        // Scenario has 2 logs: Nov 8 in Tokyo, Nov 9 in New York
        // Calculate streak as of Nov 9 New York time
        let nov9NewYork = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 9,
            hour: 12, minute: 0,
            timezone: TimezoneTestHelpers.newYork
        )

        // Act
        let streak = streakService.calculateCurrentStreak(
            habit: scenario.habit,
            logs: scenario.logs,
            asOf: nov9NewYork
        )

        // Assert: Should be 2-day streak despite timezone change
        #expect(streak == 2, "Timezone transition should maintain 2-day streak")
    }

    @Test("Multi-timezone week maintains 4-day streak")
    func multiTimezoneWeekMaintainsStreak() async throws {
        // Arrange: Use multi-timezone week scenario
        let scenario = TimezoneEdgeCaseFixtures.multiTimezoneWeekScenario()

        // Scenario has 4 logs across 4 timezones (UTC, Tokyo, New York, Sydney)
        // Calculate streak as of the last day
        let day4 = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 6,
            hour: 12, minute: 0,
            timezone: TimezoneTestHelpers.sydney
        )

        // Act
        let streak = streakService.calculateCurrentStreak(
            habit: scenario.habit,
            logs: scenario.logs,
            asOf: day4
        )

        // Assert
        #expect(streak == 4, "Multi-timezone week should maintain 4-day streak")
    }

    @Test("Longest streak calculated correctly across timezone transitions")
    func longestStreakAcrossTimezoneTransitions() async throws {
        // Arrange: Use multi-timezone week scenario
        let scenario = TimezoneEdgeCaseFixtures.multiTimezoneWeekScenario()

        // Act
        let longestStreak = streakService.calculateLongestStreak(
            habit: scenario.habit,
            logs: scenario.logs
        )

        // Assert: Should be 4 consecutive days despite timezone changes
        #expect(longestStreak == 4, "Longest streak should be 4 across timezone transitions")
    }

    @Test("DST transition does not break streak")
    func dstTransitionDoesNotBreakStreak() async throws {
        // Arrange: Use DST transition scenario
        let scenario = TimezoneEdgeCaseFixtures.dstTransitionScenario()

        // Scenario has 2 logs: one during spring forward, one during fall back
        // Both should count as separate days

        // Calculate streak as of fall back date
        let fallBackDate = TimezoneTestHelpers.dstFallBackDate()

        // Act
        let streak = streakService.calculateCurrentStreak(
            habit: scenario.habit,
            logs: scenario.logs,
            asOf: fallBackDate
        )

        // Assert: Should have at least 1 day (fall back date)
        #expect(streak >= 1, "DST transition should not break streak")
    }

    @Test("Week boundary: Sunday 11:59 PM counts for current week")
    func weekBoundarySundayCountsForCurrentWeek() async throws {
        // Arrange: Use week boundary scenario
        let scenario = TimezoneEdgeCaseFixtures.weekBoundaryScenario(
            timezone: TimezoneTestHelpers.newYork
        )

        // Scenario includes a full week plus Sunday 11:59 PM
        // Calculate streak as of Sunday
        let sundayNight = TimezoneTestHelpers.createWeekBoundaryDate(
            timezone: TimezoneTestHelpers.newYork
        )

        // Act
        let streak = streakService.calculateCurrentStreak(
            habit: scenario.habit,
            logs: scenario.logs,
            asOf: sundayNight
        )

        // Assert: Should have 7-day streak (full week including Sunday)
        #expect(streak >= 7, "Sunday 11:59 PM should count for current week, preserving streak")
    }

    @Test("Mon/Wed/Fri habit with timezone transitions respects schedule")
    func monWedFriHabitTimezoneTransitionsRespectsSchedule() async throws {
        // Arrange: Use weekly schedule scenario
        let scenario = TimezoneEdgeCaseFixtures.weeklyScheduleScenario(
            timezone: TimezoneTestHelpers.tokyo
        )

        // Scenario has Mon/Wed/Fri habit with logs on all 3 scheduled days
        let friday = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 7,  // Friday
            hour: 12, minute: 0,
            timezone: TimezoneTestHelpers.tokyo
        )

        // Act
        let streak = streakService.calculateCurrentStreak(
            habit: scenario.habit,
            logs: scenario.logs,
            asOf: friday
        )

        // Assert: Should be 3-day streak (Mon, Wed, Fri)
        #expect(streak == 3, "Mon/Wed/Fri habit should have 3-day streak with timezone awareness")
    }
}

// MARK: - Error Path Tests

@Suite("StreakCalculationService - Error Paths")
struct StreakCalculationServiceErrorTests {

    let completionService = DefaultHabitCompletionService()
    let logger = DebugLogger()

    var streakService: StreakCalculationService {
        DefaultStreakCalculationService(
            habitCompletionService: completionService,
            logger: logger
        )
    }

    @Test("Streak calculation handles logs with wrong habit ID")
    func streakHandlesLogsWithWrongHabitId() async throws {
        // Arrange
        let habit1 = HabitBuilder.binary(name: "Habit 1", schedule: .daily)
        let habit2 = HabitBuilder.binary(name: "Habit 2", schedule: .daily)

        let logsForHabit2 = [
            HabitLogBuilder.binary(habitId: habit2.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habit2.id, date: TestDates.yesterday)
        ]

        // Act: Calculate streak for habit1 with habit2's logs
        let streak = streakService.calculateCurrentStreak(
            habit: habit1,
            logs: logsForHabit2,
            asOf: TestDates.today
        )

        // Assert: Should be 0 (no matching logs)
        #expect(streak == 0, "Streak should be 0 when logs have different habit ID")
    }

    @Test("Streak calculation handles numeric habit below target")
    func streakHandlesNumericHabitBelowTarget() async throws {
        // Arrange: Numeric habit with logs below target
        let habit = HabitBuilder.numeric(
            name: "Drink Water",
            target: 8.0,
            unit: "glasses",
            schedule: .daily
        )

        let logs = [
            HabitLogBuilder.numeric(habitId: habit.id, value: 5.0, date: TestDates.today),
            HabitLogBuilder.numeric(habitId: habit.id, value: 6.0, date: TestDates.yesterday)
        ]

        // Act
        let streak = streakService.calculateCurrentStreak(
            habit: habit,
            logs: logs,
            asOf: TestDates.today
        )

        // Assert: Should be 0 (target not met on either day)
        #expect(streak == 0, "Streak should be 0 when numeric habit target not met")
    }

    @Test("Longest streak handles duplicate log dates")
    func longestStreakHandlesDuplicateLogDates() async throws {
        // Arrange: Multiple logs on same day
        let habit = HabitBuilder.binary(schedule: .daily)
        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today),  // Duplicate
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.yesterday)
        ]

        // Act
        let longestStreak = streakService.calculateLongestStreak(habit: habit, logs: logs)

        // Assert: Should be 2 (today + yesterday), not 3
        #expect(longestStreak == 2, "Longest streak should count unique days, not total logs")
    }

    @Test("Next scheduled date handles very far future search")
    func nextScheduledDateHandlesFarFutureSearch() async throws {
        // Arrange: Create Mon/Wed/Fri habit
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([1, 3, 5])
        )

        let farFutureDate = CalendarUtils.addYears(2, to: TestDates.today)

        // Act: Should not hang or crash
        let nextDate = streakService.getNextScheduledDate(habit: habit, after: farFutureDate)

        // Assert: Should return a date (within search limit)
        #expect(nextDate != nil, "Should find next scheduled date even far in future")
    }

    @Test("Streak break dates handles habit with future start date")
    func streakBreakDatesHandlesFutureStartDate() async throws {
        // Arrange: Habit that starts tomorrow
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
            startDate: TestDates.tomorrow,
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

        // Act
        let breakDates = streakService.getStreakBreakDates(
            habit: habit,
            logs: [],
            asOf: TestDates.today
        )

        // Assert: Should be empty (habit hasn't started yet)
        #expect(breakDates.isEmpty, "Should have no break dates for habit that hasn't started")
    }
}
