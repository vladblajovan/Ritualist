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
@MainActor
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
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(2))
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
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(3))
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
            TestDates.daysAgo(10),
            TestDates.daysAgo(9),
            TestDates.daysAgo(8),
            TestDates.daysAgo(7),
            TestDates.daysAgo(6),
            // Gap here
            TestDates.daysAgo(3),
            TestDates.daysAgo(2),
            TestDates.daysAgo(1)
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
        // Arrange: Habit started 3 days ago (matching first log) to avoid counting start date as break
        let habitStartDate = TestDates.daysAgo(3)
        let habit = HabitBuilder.binary(schedule: .daily, startDate: habitStartDate)

        // Logged today and 3 days ago, missing yesterday and 2 days ago
        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habit.id, date: habitStartDate)
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
        let twoDaysAgo = CalendarUtils.startOfDayLocal(for: TestDates.daysAgo(2))

        let breakDatesStartOfDay = breakDates.map { CalendarUtils.startOfDayLocal(for: $0) }
        #expect(breakDatesStartOfDay.contains(yesterday), "Should include yesterday as break date")
        #expect(breakDatesStartOfDay.contains(twoDaysAgo), "Should include 2 days ago as break date")
    }

    @Test("Streak break dates empty when no breaks")
    func streakBreakDatesEmptyWhenNoBreaks() async throws {
        // Arrange: Perfect streak starting 3 days ago (matches number of logs)
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(2))
        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.yesterday),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(2))
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
            startDate: TestDates.daysAgo(10),
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
@MainActor
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
            asOf: nov10,
            timezone: TimezoneTestHelpers.tokyo
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
            asOf: saturdayNoon,
            timezone: TimezoneTestHelpers.newYork
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
            asOf: nov9NewYork,
            timezone: TimezoneTestHelpers.newYork
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
            asOf: day4,
            timezone: TimezoneTestHelpers.sydney
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
            logs: scenario.logs,
            timezone: TimezoneTestHelpers.sydney
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
            asOf: fallBackDate,
            timezone: TimezoneTestHelpers.newYork
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
            asOf: sundayNight,
            timezone: TimezoneTestHelpers.newYork
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
            asOf: friday,
            timezone: TimezoneTestHelpers.tokyo
        )

        // Assert: Should be 3-day streak (Mon, Wed, Fri)
        #expect(streak == 3, "Mon/Wed/Fri habit should have 3-day streak with timezone awareness")
    }
}

// MARK: - Error Path Tests

@Suite("StreakCalculationService - Error Paths")
@MainActor
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

        let farFutureDate = CalendarUtils.addYearsLocal(2, to: TestDates.today, timezone: .current)

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

// MARK: - Start Date and Retroactive Logging Tests

@Suite("StreakCalculationService - Start Date Validation")
@MainActor
struct StreakCalculationServiceStartDateTests {

    let completionService = DefaultHabitCompletionService()
    let logger = DebugLogger()

    var streakService: StreakCalculationService {
        DefaultStreakCalculationService(
            habitCompletionService: completionService,
            logger: logger
        )
    }

    @Test("Streak respects edited start date - logs before start date ignored")
    func streakRespectsEditedStartDate() async throws {
        // Arrange: Habit with start date 3 days ago, but logs exist for 5 days
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(3))

        // Create logs for 5 consecutive days (2 before start date)
        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.yesterday),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(2)),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(3)),
            // These logs are before start date and should be ignored
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(4)),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(5))
        ]

        // Act
        let streak = streakService.calculateCurrentStreak(
            habit: habit,
            logs: logs,
            asOf: TestDates.today
        )

        // Assert: Should only count 4 days (from start date to today)
        #expect(streak == 4, "Streak should be 4, ignoring logs before start date")
    }

    @Test("Longest streak bounded by start date")
    func longestStreakBoundedByStartDate() async throws {
        // Arrange: Habit started 5 days ago
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(5))

        // Logs for 10 consecutive days (5 before start date)
        var logs: [HabitLog] = []
        for dayOffset in 0...9 {
            logs.append(HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(dayOffset)))
        }

        // Act
        let longestStreak = streakService.calculateLongestStreak(habit: habit, logs: logs)

        // Assert: Should be 6 days (start date to today inclusive)
        #expect(longestStreak == 6, "Longest streak should be bounded by start date")
    }

    @Test("Retroactive logging after editing start date creates valid streak")
    func retroactiveLoggingCreatesValidStreak() async throws {
        // Scenario: User edits start date to 7 days ago, then logs retroactively
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(7))

        // User logs for all 8 days (start date to today)
        var logs: [HabitLog] = []
        for dayOffset in 0...7 {
            logs.append(HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(dayOffset)))
        }

        // Act
        let streak = streakService.calculateCurrentStreak(
            habit: habit,
            logs: logs,
            asOf: TestDates.today
        )

        // Assert: Should be 8 days
        #expect(streak == 8, "Retroactive logging should create valid 8-day streak")
    }

    @Test("Streak break dates ignores dates before start date")
    func streakBreakDatesIgnoresPreStartDate() async throws {
        // Arrange: Habit started 3 days ago
        let startDate = TestDates.daysAgo(3)
        let habit = HabitBuilder.binary(schedule: .daily, startDate: startDate)

        // Logs only for today and start date (missing yesterday and 2 days ago)
        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habit.id, date: startDate)
        ]

        // Act
        let breakDates = streakService.getStreakBreakDates(
            habit: habit,
            logs: logs,
            asOf: TestDates.today
        )

        // Assert: Should have 2 break dates (yesterday and 2 days ago), but NOT anything before start date
        #expect(breakDates.count == 2, "Should have exactly 2 break dates within the start date range")

        // Verify no break dates are before start date
        let startDay = CalendarUtils.startOfDayLocal(for: startDate)
        for breakDate in breakDates {
            let breakDay = CalendarUtils.startOfDayLocal(for: breakDate)
            #expect(breakDay >= startDay, "Break dates should not be before start date")
        }
    }

    @Test("Current streak starts from edited start date when habit is new")
    func currentStreakStartsFromEditedStartDate() async throws {
        // Scenario: User creates habit today but backdates start to 2 days ago
        let backdatedStart = TestDates.daysAgo(2)
        let habit = HabitBuilder.binary(schedule: .daily, startDate: backdatedStart)

        // User logs for all 3 days retroactively
        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.yesterday),
            HabitLogBuilder.binary(habitId: habit.id, date: backdatedStart)
        ]

        // Act
        let streak = streakService.calculateCurrentStreak(
            habit: habit,
            logs: logs,
            asOf: TestDates.today
        )

        // Assert
        #expect(streak == 3, "Streak should be 3 with backdated start date and retroactive logs")
    }

    @Test("Start date on same day as today counts that day")
    func startDateTodayCountsToday() async throws {
        // Arrange: Habit starts today
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.today)
        let log = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)

        // Act
        let streak = streakService.calculateCurrentStreak(
            habit: habit,
            logs: [log],
            asOf: TestDates.today
        )

        // Assert
        #expect(streak == 1, "Streak should be 1 when habit starts and is logged today")
    }

    @Test("Partial week logging with backdated start date calculates correctly")
    func partialWeekLoggingWithBackdatedStartDate() async throws {
        // Scenario: Mon/Wed/Fri habit, user backdates to include previous week
        let lastMonday = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 3,  // Monday
            hour: 12, minute: 0,
            timezone: .current
        )
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([1, 3, 5]),  // Mon/Wed/Fri
            startDate: lastMonday
        )

        // Log for Mon, Wed, Fri of that week
        let wednesday = TimezoneTestHelpers.createDate(year: 2025, month: 11, day: 5, hour: 12, minute: 0, timezone: .current)
        let friday = TimezoneTestHelpers.createDate(year: 2025, month: 11, day: 7, hour: 12, minute: 0, timezone: .current)

        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: lastMonday),
            HabitLogBuilder.binary(habitId: habit.id, date: wednesday),
            HabitLogBuilder.binary(habitId: habit.id, date: friday)
        ]

        // Act
        let streak = streakService.calculateCurrentStreak(
            habit: habit,
            logs: logs,
            asOf: friday
        )

        // Assert: Should be 3 (Mon + Wed + Fri)
        #expect(streak == 3, "Backdated Mon/Wed/Fri habit should have 3-day streak")
    }

    @Test("Future start date returns zero current streak")
    func futureStartDateReturnsZeroStreak() async throws {
        // Arrange: Habit starts tomorrow
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysFromNow(1))

        // No logs (can't log before start date anyway)
        let logs: [HabitLog] = []

        // Act
        let streak = streakService.calculateCurrentStreak(habit: habit, logs: logs, asOf: TestDates.today)

        // Assert
        #expect(streak == 0, "Streak should be 0 for habit that hasn't started yet")
    }

    @Test("Future start date returns zero longest streak even with logs")
    func futureStartDateReturnsZeroLongestStreak() async throws {
        // Arrange: Habit starts tomorrow, but somehow has logs (edge case)
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysFromNow(1))

        // These logs are technically invalid but test the filter
        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.yesterday)
        ]

        // Act
        let longestStreak = streakService.calculateLongestStreak(habit: habit, logs: logs)

        // Assert
        #expect(longestStreak == 0, "Longest streak should be 0 when start date is in future")
    }

    @Test("DaysOfWeek habit respects start date mid-week")
    func daysOfWeekHabitRespectsStartDateMidWeek() async throws {
        // Arrange: Mon/Wed/Fri habit that started on Wednesday
        // Create specific dates for a known week
        let wednesday = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 12,  // Wednesday
            hour: 12, minute: 0,
            timezone: .current
        )
        let friday = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 14,  // Friday
            hour: 12, minute: 0,
            timezone: .current
        )
        let mondayBefore = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 10,  // Monday (before start)
            hour: 12, minute: 0,
            timezone: .current
        )

        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([1, 3, 5]),  // Mon/Wed/Fri
            startDate: wednesday
        )

        // Logs for Wed, Fri, and even Monday before (which should be ignored)
        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: friday),
            HabitLogBuilder.binary(habitId: habit.id, date: wednesday),
            HabitLogBuilder.binary(habitId: habit.id, date: mondayBefore)  // Before start, should be ignored
        ]

        // Act
        let streak = streakService.calculateCurrentStreak(habit: habit, logs: logs, asOf: friday)

        // Assert: Should be 2 (Wed + Fri only, Monday is before start date)
        #expect(streak == 2, "Streak should be 2 - Monday log ignored because before start date")
    }

    @Test("Completion rate calculation respects start date boundary")
    func completionRateRespectsStartDateBoundary() async throws {
        // Arrange: Habit started 3 days ago, query range is 7 days
        let startDate = TestDates.daysAgo(3)
        let habit = HabitBuilder.binary(schedule: .daily, startDate: startDate)

        // Logs for all 4 valid days (start date to today)
        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.yesterday),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(2)),
            HabitLogBuilder.binary(habitId: habit.id, date: startDate)
        ]

        // Get compliant dates (should only include dates from start date onwards)
        let longestStreak = streakService.calculateLongestStreak(habit: habit, logs: logs)

        // Assert: Should be 4 (only counting from start date)
        #expect(longestStreak == 4, "Longest streak should be 4 - only days from start date count")
    }

    @Test("Streak with gap after start date calculates correctly")
    func streakWithGapAfterStartDateCalculatesCorrectly() async throws {
        // Arrange: Habit started 5 days ago, logged first 2 days, then gap, then last 2 days
        let startDate = TestDates.daysAgo(5)
        let habit = HabitBuilder.binary(schedule: .daily, startDate: startDate)

        // Day 1 (start) = logged
        // Day 2 = logged
        // Day 3 = MISSED
        // Day 4 = logged
        // Day 5 = logged
        // Day 6 (today) = logged
        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.yesterday),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(2)),
            // Gap on day -3
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(4)),
            HabitLogBuilder.binary(habitId: habit.id, date: startDate)
        ]

        // Act
        let currentStreak = streakService.calculateCurrentStreak(habit: habit, logs: logs, asOf: TestDates.today)
        let longestStreak = streakService.calculateLongestStreak(habit: habit, logs: logs)

        // Assert
        #expect(currentStreak == 3, "Current streak should be 3 (today, yesterday, 2 days ago)")
        #expect(longestStreak == 3, "Longest streak should be 3 (the current run)")
    }
}

// MARK: - GetStreakStatus Tests

@Suite("StreakCalculationService - GetStreakStatus")
@MainActor
struct StreakCalculationServiceGetStreakStatusTests {

    let completionService = DefaultHabitCompletionService()
    let logger = DebugLogger()

    var streakService: StreakCalculationService {
        DefaultStreakCalculationService(
            habitCompletionService: completionService,
            logger: logger
        )
    }

    @Test("isAtRisk is true when today is scheduled, not logged, and yesterday has streak")
    func isAtRiskWhenScheduledUnloggedWithStreak() async throws {
        // Arrange: Habit with 3-day streak, today not logged
        let startDate = TestDates.daysAgo(3)
        let habit = HabitBuilder.binary(schedule: .daily, startDate: startDate)

        // Logs for yesterday, 2 days ago, 3 days ago - but NOT today
        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.yesterday),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(2)),
            HabitLogBuilder.binary(habitId: habit.id, date: startDate)
        ]

        // Act
        let status = streakService.getStreakStatus(habit: habit, logs: logs, asOf: TestDates.today)

        // Assert
        #expect(status.isAtRisk == true, "Should be at risk when today not logged but yesterday has streak")
        #expect(status.atRisk == 3, "At-risk streak should be 3 (yesterday's streak)")
        #expect(status.current == 0, "Current streak should be 0 (today not completed)")
        #expect(status.isTodayScheduled == true, "Today should be scheduled for daily habit")
    }

    @Test("isAtRisk is false when today is already logged")
    func notAtRiskWhenTodayLogged() async throws {
        // Arrange: Habit with streak including today
        let startDate = TestDates.daysAgo(2)
        let habit = HabitBuilder.binary(schedule: .daily, startDate: startDate)

        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.yesterday),
            HabitLogBuilder.binary(habitId: habit.id, date: startDate)
        ]

        // Act
        let status = streakService.getStreakStatus(habit: habit, logs: logs, asOf: TestDates.today)

        // Assert
        #expect(status.isAtRisk == false, "Should not be at risk when today is logged")
        #expect(status.current == 3, "Current streak should be 3")
    }

    @Test("isAtRisk is false when no streak exists to lose")
    func notAtRiskWhenNoStreak() async throws {
        // Arrange: New habit with no logs
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.today)
        let logs: [HabitLog] = []

        // Act
        let status = streakService.getStreakStatus(habit: habit, logs: logs, asOf: TestDates.today)

        // Assert
        #expect(status.isAtRisk == false, "Should not be at risk when no streak exists")
        #expect(status.atRisk == 0, "At-risk value should be 0")
        #expect(status.current == 0, "Current streak should be 0")
    }

    @Test("isAtRisk is false when today is not scheduled")
    func notAtRiskWhenNotScheduledDay() async throws {
        // Arrange: Mon/Wed/Fri habit checked on a non-scheduled day
        // Create a habit that is NOT scheduled today
        let today = TestDates.today
        let todayWeekday = CalendarUtils.habitWeekday(from: today, timezone: .current)

        // Pick days that exclude today
        var scheduledDays: Set<Int> = [1, 3, 5]  // Mon/Wed/Fri
        if scheduledDays.contains(todayWeekday) {
            scheduledDays = [2, 4, 6]  // Tue/Thu/Sat instead
        }

        let habit = HabitBuilder.binary(schedule: .daysOfWeek(scheduledDays), startDate: TestDates.daysAgo(7))

        // Create some logs on previous scheduled days
        var logs: [HabitLog] = []
        for dayOffset in 1...7 {
            let date = TestDates.daysAgo(dayOffset)
            let weekday = CalendarUtils.habitWeekday(from: date, timezone: .current)
            if scheduledDays.contains(weekday) {
                logs.append(HabitLogBuilder.binary(habitId: habit.id, date: date))
            }
        }

        // Act
        let status = streakService.getStreakStatus(habit: habit, logs: logs, asOf: TestDates.today)

        // Assert
        #expect(status.isTodayScheduled == false, "Today should not be scheduled")
        #expect(status.isAtRisk == false, "Should not be at risk on non-scheduled day")
    }

    @Test("displayStreak returns atRisk value when at risk")
    func displayStreakShowsAtRiskValue() async throws {
        // Arrange: Habit at risk with 5-day streak from yesterday
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(5))

        // Logs for 5 consecutive days, but NOT today
        var logs: [HabitLog] = []
        for dayOffset in 1...5 {
            logs.append(HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(dayOffset)))
        }

        // Act
        let status = streakService.getStreakStatus(habit: habit, logs: logs, asOf: TestDates.today)

        // Assert
        #expect(status.isAtRisk == true, "Should be at risk")
        #expect(status.displayStreak == 5, "displayStreak should show at-risk value (5)")
        #expect(status.current == 0, "current should be 0 (today not logged)")
        #expect(status.atRisk == 5, "atRisk should be 5")
    }

    @Test("displayStreak returns current value when not at risk")
    func displayStreakShowsCurrentValueWhenNotAtRisk() async throws {
        // Arrange: Habit with streak including today
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(4))

        var logs: [HabitLog] = []
        for dayOffset in 0...4 {
            logs.append(HabitLogBuilder.binary(habitId: habit.id, date: TestDates.daysAgo(dayOffset)))
        }

        // Act
        let status = streakService.getStreakStatus(habit: habit, logs: logs, asOf: TestDates.today)

        // Assert
        #expect(status.isAtRisk == false, "Should not be at risk when today logged")
        #expect(status.displayStreak == 5, "displayStreak should show current value (5)")
        #expect(status.current == 5, "current should be 5")
    }

    @Test("Streak status respects habit start date")
    func streakStatusRespectsStartDate() async throws {
        // Arrange: Habit started yesterday, logs for today and yesterday
        let startDate = TestDates.yesterday
        let habit = HabitBuilder.binary(schedule: .daily, startDate: startDate)

        let logs = [
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today),
            HabitLogBuilder.binary(habitId: habit.id, date: TestDates.yesterday)
        ]

        // Act
        let status = streakService.getStreakStatus(habit: habit, logs: logs, asOf: TestDates.today)

        // Assert
        #expect(status.current == 2, "Current streak should be 2 (yesterday + today)")
        #expect(status.isAtRisk == false, "Should not be at risk")
    }

    @Test("HabitStreakStatus is Equatable")
    func habitStreakStatusIsEquatable() async throws {
        // Arrange
        let status1 = HabitStreakStatus(current: 5, atRisk: 5, isAtRisk: true, isTodayScheduled: true)
        let status2 = HabitStreakStatus(current: 5, atRisk: 5, isAtRisk: true, isTodayScheduled: true)
        let status3 = HabitStreakStatus(current: 3, atRisk: 3, isAtRisk: false, isTodayScheduled: true)

        // Assert
        #expect(status1 == status2, "Same values should be equal")
        #expect(status1 != status3, "Different values should not be equal")
    }
}
