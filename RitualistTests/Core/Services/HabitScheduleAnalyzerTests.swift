//
//  HabitScheduleAnalyzerTests.swift
//  RitualistTests
//
//  Created by Phase 4 Testing Infrastructure on 15.11.2025.
//

import Testing
import Foundation
@testable import RitualistCore

@Suite("HabitScheduleAnalyzer - Core Functionality")
struct HabitScheduleAnalyzerTests {

    // MARK: - Test Setup

    let analyzer = HabitScheduleAnalyzer()

    // MARK: - Daily Schedule Tests

    @Test("Daily habit is expected every day")
    func dailyHabitExpectedEveryDay() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)

        // Act & Assert: Check multiple dates
        let dates = [TestDates.today, TestDates.yesterday, TestDates.tomorrow]
        for date in dates {
            let isExpected = analyzer.isHabitExpectedOnDate(habit: habit, date: date)
            #expect(isExpected == true, "Daily habit should be expected on \(date)")
        }
    }

    @Test("Daily habit expected days calculated correctly")
    func dailyHabitExpectedDaysCalculatedCorrectly() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)
        let startDate = TestDates.today
        let endDate = CalendarUtils.addDays(6, to: startDate)  // 7 days total

        // Act
        let expectedDays = analyzer.calculateExpectedDays(
            for: habit,
            from: startDate,
            to: endDate
        )

        // Assert
        #expect(expectedDays == 7, "Daily habit should expect 7 days over 7-day period")
    }

    @Test("Daily habit expected days respects habit end date")
    func dailyHabitExpectedDaysRespectsEndDate() async throws {
        // Arrange: Habit that ends in 3 days
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
            endDate: CalendarUtils.addDays(2, to: TestDates.today),
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
        let endDate = CalendarUtils.addDays(6, to: startDate)  // Query 7 days

        // Act
        let expectedDays = analyzer.calculateExpectedDays(
            for: habit,
            from: startDate,
            to: endDate
        )

        // Assert: Should only count 3 days (today + 2 more)
        #expect(expectedDays == 3, "Expected days should respect habit end date")
    }

    // MARK: - DaysOfWeek Schedule Tests

    @Test("Mon/Wed/Fri habit expected only on scheduled days")
    func monWedFriHabitExpectedOnlyOnScheduledDays() async throws {
        // Arrange
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([1, 3, 5])  // Mon, Wed, Fri
        )

        // Act: Check specific days
        let monday = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 3,  // Monday
            hour: 12, minute: 0,
            timezone: .current
        )
        let tuesday = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 4,  // Tuesday
            hour: 12, minute: 0,
            timezone: .current
        )
        let wednesday = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 5,  // Wednesday
            hour: 12, minute: 0,
            timezone: .current
        )

        // Assert
        #expect(analyzer.isHabitExpectedOnDate(habit: habit, date: monday) == true, "Mon/Wed/Fri habit should be expected on Monday")
        #expect(analyzer.isHabitExpectedOnDate(habit: habit, date: tuesday) == false, "Mon/Wed/Fri habit should NOT be expected on Tuesday")
        #expect(analyzer.isHabitExpectedOnDate(habit: habit, date: wednesday) == true, "Mon/Wed/Fri habit should be expected on Wednesday")
    }

    @Test("Mon/Wed/Fri habit expected days calculated correctly")
    func monWedFriHabitExpectedDaysCalculatedCorrectly() async throws {
        // Arrange
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([1, 3, 5])
        )

        // Full week: Monday Nov 3 to Sunday Nov 9, 2025
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

        // Act
        let expectedDays = analyzer.calculateExpectedDays(
            for: habit,
            from: startDate,
            to: endDate
        )

        // Assert: Should expect 3 days (Mon, Wed, Fri)
        #expect(expectedDays == 3, "Mon/Wed/Fri habit should expect 3 days in one week")
    }

    @Test("Weekend habit expected only on Saturday and Sunday")
    func weekendHabitExpectedOnlyOnWeekends() async throws {
        // Arrange
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([6, 7])  // Sat, Sun
        )

        // Act: Check days in a week
        let friday = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 7,  // Friday
            hour: 12, minute: 0,
            timezone: .current
        )
        let saturday = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 8,  // Saturday
            hour: 12, minute: 0,
            timezone: .current
        )
        let sunday = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 9,  // Sunday
            hour: 12, minute: 0,
            timezone: .current
        )
        let monday = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 10,  // Monday
            hour: 12, minute: 0,
            timezone: .current
        )

        // Assert
        #expect(analyzer.isHabitExpectedOnDate(habit: habit, date: friday) == false, "Weekend habit should NOT be expected on Friday")
        #expect(analyzer.isHabitExpectedOnDate(habit: habit, date: saturday) == true, "Weekend habit should be expected on Saturday")
        #expect(analyzer.isHabitExpectedOnDate(habit: habit, date: sunday) == true, "Weekend habit should be expected on Sunday")
        #expect(analyzer.isHabitExpectedOnDate(habit: habit, date: monday) == false, "Weekend habit should NOT be expected on Monday")
    }

    @Test("Weekend habit expected days calculated correctly for month")
    func weekendHabitExpectedDaysCalculatedCorrectlyForMonth() async throws {
        // Arrange
        // Define the date range for testing
        let startDate = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 1,  // Saturday, Nov 1
            hour: 12, minute: 0,
            timezone: .current
        )
        let endDate = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 30,  // Sunday, Nov 30
            hour: 12, minute: 0,
            timezone: .current
        )

        // November 2025: 30 days, starts on Saturday (Nov 1)
        // Saturdays: Nov 1, 8, 15, 22, 29 = 5 days
        // Sundays: Nov 2, 9, 16, 23, 30 = 5 days
        // Total weekend days: 10
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([6, 7]),  // Sat, Sun
            startDate: startDate  // Align with query range
        )

        // Act
        let expectedDays = analyzer.calculateExpectedDays(
            for: habit,
            from: startDate,
            to: endDate
        )

        // Assert: November 2025 has 5 Saturdays + 5 Sundays = 10 weekend days
        #expect(expectedDays == 10, "Weekend habit should expect correct number of weekend days in November 2025")
    }

    // MARK: - Edge Cases

    @Test("Expected days calculation handles single day range")
    func expectedDaysHandlesSingleDayRange() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)

        // Act: Same start and end date
        let expectedDays = analyzer.calculateExpectedDays(
            for: habit,
            from: TestDates.today,
            to: TestDates.today
        )

        // Assert: Should expect 1 day
        #expect(expectedDays == 1, "Expected days should be 1 for single-day range")
    }

    @Test("Expected days calculation handles empty range")
    func expectedDaysHandlesEmptyRange() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)

        // Act: End date before start date (invalid range)
        let expectedDays = analyzer.calculateExpectedDays(
            for: habit,
            from: TestDates.tomorrow,
            to: TestDates.today
        )

        // Assert: Should expect 0 days
        #expect(expectedDays == 0, "Expected days should be 0 for invalid range")
    }

    @Test("Expected days handles habit that hasn't started yet")
    func expectedDaysHandlesHabitNotStarted() async throws {
        // Arrange: Habit starts in the future
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
            startDate: CalendarUtils.addDays(5, to: TestDates.today),
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

        // Act: Query before habit starts
        let expectedDays = analyzer.calculateExpectedDays(
            for: habit,
            from: TestDates.today,
            to: CalendarUtils.addDays(3, to: TestDates.today)
        )

        // Assert: Note - The analyzer doesn't filter by habit.startDate for retroactive logging support
        // So it will count all days in the range
        #expect(expectedDays == 4, "Expected days counts all days in range for retroactive logging support")
    }
}

// MARK: - Timezone Edge Cases

@Suite("HabitScheduleAnalyzer - Timezone Edge Cases")
struct HabitScheduleAnalyzerTimezoneTests {

    let analyzer = HabitScheduleAnalyzer()

    @Test("isHabitExpectedOnDate uses LOCAL weekday, not UTC")
    func isHabitExpectedUsesLocalWeekday() async throws {
        // Arrange: Create Mon/Wed/Fri habit
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([1, 3, 5])
        )

        // Create a date that is Monday in Tokyo but Sunday in UTC
        // Monday Nov 3, 2025 at 1:00 AM Tokyo time = Sunday Nov 2, 2025 at 4:00 PM UTC
        let tokyoMonday = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 3,  // Monday in Tokyo
            hour: 1, minute: 0,
            timezone: TimezoneTestHelpers.tokyo
        )

        // Act: Check if expected (should use Tokyo timezone, not UTC)
        let isExpected = analyzer.isHabitExpectedOnDate(habit: habit, date: tokyoMonday, timezone: TimezoneTestHelpers.tokyo)

        // Assert: Should be true (it's Monday in Tokyo, which is scheduled)
        #expect(isExpected == true, "Should use LOCAL weekday (Monday in Tokyo), not UTC weekday (Sunday)")
    }

    @Test("calculateExpectedDays respects LOCAL week boundaries")
    func calculateExpectedDaysRespectsLocalWeekBoundaries() async throws {
        // Arrange: Create Mon/Wed/Fri habit
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([1, 3, 5])
        )

        // Use a full week in Tokyo timezone
        let startDate = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 3,  // Monday
            hour: 0, minute: 0,
            timezone: TimezoneTestHelpers.tokyo
        )
        let endDate = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 9,  // Sunday
            hour: 23, minute: 59,
            timezone: TimezoneTestHelpers.tokyo
        )

        // Act
        let expectedDays = analyzer.calculateExpectedDays(
            for: habit,
            from: startDate,
            to: endDate,
            timezone: TimezoneTestHelpers.tokyo
        )

        // Assert: Should expect 3 days (Mon, Wed, Fri) in LOCAL timezone
        #expect(expectedDays == 3, "Should count 3 scheduled days using LOCAL week boundaries")
    }

    @Test("Late-night date (11:30 PM) uses correct LOCAL weekday")
    func lateNightDateUsesCorrectLocalWeekday() async throws {
        // Arrange: Create Mon/Wed/Fri habit
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([1, 3, 5])
        )

        // Create Monday at 11:30 PM Tokyo time
        let mondayNight = TimezoneTestHelpers.createLateNightDate(
            timezone: TimezoneTestHelpers.tokyo
        )

        // Note: The lateNightDate is Nov 8 which is a Friday, not Monday
        // Let's create a proper Monday late night
        let mondayLateNight = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 3,  // Monday
            hour: 23, minute: 30,
            timezone: TimezoneTestHelpers.tokyo
        )

        // Act
        let isExpected = analyzer.isHabitExpectedOnDate(habit: habit, date: mondayLateNight, timezone: TimezoneTestHelpers.tokyo)

        // Assert: Should be true (it's still Monday at 11:30 PM)
        #expect(isExpected == true, "Late-night Monday (11:30 PM) should still count as Monday")
    }

    @Test("Midnight boundary: 11:59 PM and 12:01 AM have different weekdays")
    func midnightBoundaryHasDifferentWeekdays() async throws {
        // Arrange: Create Mon/Wed/Fri habit
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([1, 3, 5])
        )

        // Friday Nov 8 at 11:59 PM
        let fridayNight = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 7,  // Friday
            hour: 23, minute: 59,
            timezone: TimezoneTestHelpers.newYork
        )

        // Saturday Nov 9 at 12:01 AM
        let saturdayMorning = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 8,  // Saturday
            hour: 0, minute: 1,
            timezone: TimezoneTestHelpers.newYork
        )

        // Act
        let fridayExpected = analyzer.isHabitExpectedOnDate(habit: habit, date: fridayNight, timezone: TimezoneTestHelpers.newYork)
        let saturdayExpected = analyzer.isHabitExpectedOnDate(habit: habit, date: saturdayMorning, timezone: TimezoneTestHelpers.newYork)

        // Assert
        #expect(fridayExpected == true, "Friday 11:59 PM should be expected (Friday is scheduled)")
        #expect(saturdayExpected == false, "Saturday 12:01 AM should NOT be expected (Saturday not scheduled)")
    }

    @Test("Week boundary calculation respects LOCAL timezone")
    func weekBoundaryCalculationRespectsLocalTimezone() async throws {
        // Arrange: Create weekend habit (Sat/Sun)
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([6, 7])
        )

        // Week: Monday Nov 3 to Sunday Nov 9, 2025 (Tokyo time)
        let startDate = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 3,  // Monday
            hour: 0, minute: 0,
            timezone: TimezoneTestHelpers.tokyo
        )
        let endDate = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 9,  // Sunday
            hour: 23, minute: 59,
            timezone: TimezoneTestHelpers.tokyo
        )

        // Act
        let expectedDays = analyzer.calculateExpectedDays(
            for: habit,
            from: startDate,
            to: endDate,
            timezone: TimezoneTestHelpers.tokyo
        )

        // Assert: Should expect 2 days (Saturday + Sunday) in LOCAL timezone
        #expect(expectedDays == 2, "Should count 2 weekend days using LOCAL timezone")
    }

    @Test("Multi-timezone scenario: Expected days consistent across timezones")
    func multiTimezoneExpectedDaysConsistent() async throws {
        // Arrange: Create daily habit
        let habit = HabitBuilder.binary(schedule: .daily)

        // Same 7-day period in different timezones
        let tokyoStart = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 3,
            hour: 0, minute: 0,
            timezone: TimezoneTestHelpers.tokyo
        )
        let tokyoEnd = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 9,
            hour: 23, minute: 59,
            timezone: TimezoneTestHelpers.tokyo
        )

        let newYorkStart = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 3,
            hour: 0, minute: 0,
            timezone: TimezoneTestHelpers.newYork
        )
        let newYorkEnd = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 9,
            hour: 23, minute: 59,
            timezone: TimezoneTestHelpers.newYork
        )

        // Act
        let tokyoExpected = analyzer.calculateExpectedDays(
            for: habit,
            from: tokyoStart,
            to: tokyoEnd,
            timezone: TimezoneTestHelpers.tokyo
        )
        let newYorkExpected = analyzer.calculateExpectedDays(
            for: habit,
            from: newYorkStart,
            to: newYorkEnd,
            timezone: TimezoneTestHelpers.newYork
        )

        // Assert: Both should expect 7 days
        #expect(tokyoExpected == 7, "Tokyo should expect 7 days for daily habit")
        #expect(newYorkExpected == 7, "New York should expect 7 days for daily habit")
        #expect(tokyoExpected == newYorkExpected, "Expected days should be consistent across timezones")
    }

    @Test("DST transition: Weekday calculated correctly during spring forward")
    func dstTransitionWeekdayCorrectDuringSpringForward() async throws {
        // Arrange: Create weekday habit (Mon-Fri)
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([1, 2, 3, 4, 5])
        )

        // March 9, 2025 at 1:30 AM (before spring forward in NY)
        // This is a Sunday
        let beforeSpringForward = TimezoneTestHelpers.dstSpringForwardDate()

        // Act
        let isExpected = analyzer.isHabitExpectedOnDate(habit: habit, date: beforeSpringForward, timezone: TimezoneTestHelpers.newYork)

        // Assert: Sunday should NOT be expected for Mon-Fri habit
        #expect(isExpected == false, "Sunday during DST transition should not be expected for weekday habit")
    }

    @Test("DST transition: Expected days calculation handles fall back")
    func dstTransitionExpectedDaysHandlesFallBack() async throws {
        // Arrange: Create daily habit
        let habit = HabitBuilder.binary(schedule: .daily)

        // Week containing DST fall back (Nov 2, 2025)
        let startDate = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 1,  // Saturday
            hour: 0, minute: 0,
            timezone: TimezoneTestHelpers.newYork
        )
        let endDate = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 7,  // Friday
            hour: 23, minute: 59,
            timezone: TimezoneTestHelpers.newYork
        )

        // Act
        let expectedDays = analyzer.calculateExpectedDays(
            for: habit,
            from: startDate,
            to: endDate,
            timezone: TimezoneTestHelpers.newYork
        )

        // Assert: Should still expect 7 days (DST doesn't change calendar days)
        #expect(expectedDays == 7, "DST fall back should not affect expected days count")
    }
}

// MARK: - Error Path Tests

@Suite("HabitScheduleAnalyzer - Error Paths")
struct HabitScheduleAnalyzerErrorTests {

    let analyzer = HabitScheduleAnalyzer()

    @Test("isHabitExpectedOnDate handles far future date")
    func isHabitExpectedHandlesFarFutureDate() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)
        let farFuture = CalendarUtils.addYears(10, to: TestDates.today)

        // Act
        let isExpected = analyzer.isHabitExpectedOnDate(habit: habit, date: farFuture)

        // Assert: Should not crash
        #expect(isExpected == true, "Should handle far future date without crashing")
    }

    @Test("isHabitExpectedOnDate handles far past date")
    func isHabitExpectedHandlesFarPastDate() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)
        let farPast = CalendarUtils.addYears(-10, to: TestDates.today)

        // Act
        let isExpected = analyzer.isHabitExpectedOnDate(habit: habit, date: farPast)

        // Assert: Should not crash
        #expect(isExpected == true, "Should handle far past date without crashing")
    }

    @Test("calculateExpectedDays handles very long date range")
    func calculateExpectedDaysHandlesVeryLongRange() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily)
        let startDate = TestDates.today
        let endDate = CalendarUtils.addYears(1, to: startDate)  // 1 year

        // Act
        let expectedDays = analyzer.calculateExpectedDays(
            for: habit,
            from: startDate,
            to: endDate
        )

        // Assert: Should be approximately 365-366 days
        #expect(expectedDays >= 365 && expectedDays <= 366, "Should calculate expected days for 1-year range")
    }

    @Test("calculateExpectedDays handles Mon/Wed/Fri with very long range")
    func calculateExpectedDaysMonWedFriVeryLongRange() async throws {
        // Arrange
        let habit = HabitBuilder.binary(
            schedule: .daysOfWeek([1, 3, 5])
        )
        let startDate = TestDates.today
        let endDate = CalendarUtils.addYears(1, to: startDate)  // 1 year

        // Act
        let expectedDays = analyzer.calculateExpectedDays(
            for: habit,
            from: startDate,
            to: endDate
        )

        // Assert: Should be approximately 156-157 days (3 days/week × 52 weeks)
        #expect(expectedDays >= 155 && expectedDays <= 160, "Should calculate Mon/Wed/Fri days for 1-year range")
    }

    @Test("isHabitExpectedOnDate handles habit with empty daysOfWeek")
    func isHabitExpectedHandlesEmptyDaysOfWeek() async throws {
        // Arrange: Create habit with empty scheduled days (edge case)
        let habit = Habit(
            id: UUID(),
            name: "No Days Habit",
            colorHex: "#2DA9E3",
            emoji: "🎯",
            kind: .binary,
            unitLabel: nil,
            dailyTarget: nil,
            schedule: .daysOfWeek([]),  // Empty set
            reminders: [],
            startDate: TestDates.today,
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
        let isExpected = analyzer.isHabitExpectedOnDate(habit: habit, date: TestDates.today)

        // Assert: Should be false (no days scheduled)
        #expect(isExpected == false, "Habit with empty daysOfWeek should never be expected")
    }

    @Test("calculateExpectedDays handles habit with empty daysOfWeek")
    func calculateExpectedDaysHandlesEmptyDaysOfWeek() async throws {
        // Arrange
        let habit = Habit(
            id: UUID(),
            name: "No Days Habit",
            colorHex: "#2DA9E3",
            emoji: "🎯",
            kind: .binary,
            unitLabel: nil,
            dailyTarget: nil,
            schedule: .daysOfWeek([]),
            reminders: [],
            startDate: TestDates.today,
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

        let startDate = TestDates.today
        let endDate = CalendarUtils.addDays(6, to: startDate)

        // Act
        let expectedDays = analyzer.calculateExpectedDays(
            for: habit,
            from: startDate,
            to: endDate
        )

        // Assert: Should be 0 (no days scheduled)
        #expect(expectedDays == 0, "Habit with empty daysOfWeek should have 0 expected days")
    }
}
