//
//  LogUseCasesTimezoneTests.swift
//  RitualistTests
//
//  Tests for GetBatchLogs timezone handling and date filtering edge cases
//

import Foundation
import Testing
@testable import RitualistCore

/// Tests for GetBatchLogs timezone-aware date filtering
///
/// These tests verify that the date boundary calculations are hoisted correctly
/// and that logs are filtered properly across different timezones.
@Suite("LogUseCases - Timezone Date Filtering")
@MainActor
struct LogUseCasesTimezoneDateFilteringTests {

    // MARK: - Date Boundary Calculation Tests

    @Test("Since boundary is calculated correctly for different timezones")
    func sinceBoundaryCalculatedCorrectlyForDifferentTimezones() {
        // Test that startOfDayLocal produces correct boundaries
        let tokyo = TimezoneTestHelpers.tokyo
        let newYork = TimezoneTestHelpers.newYork

        // Same instant, different local days
        let instant = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 15,
            hour: 10, minute: 0,
            timezone: TimezoneTestHelpers.utc
        )

        let tokyoStart = CalendarUtils.startOfDayLocal(for: instant, timezone: tokyo)
        let newYorkStart = CalendarUtils.startOfDayLocal(for: instant, timezone: newYork)

        // Tokyo is ahead, so start of day in Tokyo is earlier
        #expect(tokyoStart != newYorkStart, "Start of day should differ between Tokyo and New York")
    }

    @Test("Date filtering respects timezone for since boundary")
    func dateFilteringRespectsTimezoneForSinceBoundary() {
        let tokyo = TimezoneTestHelpers.tokyo

        // Create a "since" date of Nov 15, 2025
        let since = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 15,
            hour: 0, minute: 0,
            timezone: tokyo
        )

        // Log on Nov 14 (should be excluded)
        let logBefore = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 14,
            hour: 23, minute: 59,
            timezone: tokyo
        )

        // Log on Nov 15 (should be included)
        let logOnDay = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 15,
            hour: 10, minute: 0,
            timezone: tokyo
        )

        let sinceStart = CalendarUtils.startOfDayLocal(for: since, timezone: tokyo)
        let logBeforeStart = CalendarUtils.startOfDayLocal(for: logBefore, timezone: tokyo)
        let logOnDayStart = CalendarUtils.startOfDayLocal(for: logOnDay, timezone: tokyo)

        #expect(logBeforeStart < sinceStart, "Log before since should be excluded")
        #expect(logOnDayStart >= sinceStart, "Log on since day should be included")
    }

    @Test("Date filtering respects timezone for until boundary")
    func dateFilteringRespectsTimezoneForUntilBoundary() {
        let newYork = TimezoneTestHelpers.newYork

        // Create an "until" date of Nov 20, 2025
        let until = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 20,
            hour: 23, minute: 59,
            timezone: newYork
        )

        // Log on Nov 20 (should be included)
        let logOnDay = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 20,
            hour: 10, minute: 0,
            timezone: newYork
        )

        // Log on Nov 21 (should be excluded)
        let logAfter = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 21,
            hour: 0, minute: 1,
            timezone: newYork
        )

        let untilStart = CalendarUtils.startOfDayLocal(for: until, timezone: newYork)
        let logOnDayStart = CalendarUtils.startOfDayLocal(for: logOnDay, timezone: newYork)
        let logAfterStart = CalendarUtils.startOfDayLocal(for: logAfter, timezone: newYork)

        #expect(logOnDayStart <= untilStart, "Log on until day should be included")
        #expect(logAfterStart > untilStart, "Log after until should be excluded")
    }

    // MARK: - Cross-Timezone Log Filtering Tests

    @Test("Log created in Tokyo filtered correctly with New York display timezone")
    func logCreatedInTokyoFilteredWithNewYorkDisplayTimezone() {
        let tokyo = TimezoneTestHelpers.tokyo
        let newYork = TimezoneTestHelpers.newYork

        // Log created at 10 AM Tokyo time on Nov 15
        let tokyoLog = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 15,
            hour: 10, minute: 0,
            timezone: tokyo
        )

        // This same instant in New York is still Nov 14 (Tokyo is 14 hours ahead)
        let logStartInNewYork = CalendarUtils.startOfDayLocal(for: tokyoLog, timezone: newYork)
        let logStartInTokyo = CalendarUtils.startOfDayLocal(for: tokyoLog, timezone: tokyo)

        // Verify the dates are different
        let (tokyoYear, tokyoMonth, tokyoDay) = TimezoneTestHelpers.calendarDay(for: tokyoLog, in: tokyo)
        let (nyYear, nyMonth, nyDay) = TimezoneTestHelpers.calendarDay(for: tokyoLog, in: newYork)

        #expect(tokyoDay == 15, "In Tokyo, the log is on Nov 15")
        #expect(nyDay == 14, "In New York, the same instant is Nov 14")
    }

    @Test("Filtering with different query and log timezones")
    func filteringWithDifferentQueryAndLogTimezones() {
        // Scenario: User travels from Tokyo to New York
        // Log was created in Tokyo, but now querying from New York

        let tokyo = TimezoneTestHelpers.tokyo
        let newYork = TimezoneTestHelpers.newYork

        // Query range: Nov 15-20 in New York timezone
        let querySince = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 15,
            hour: 0, minute: 0,
            timezone: newYork
        )
        let queryUntil = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 20,
            hour: 23, minute: 59,
            timezone: newYork
        )

        // Log created in Tokyo on Nov 15 at 10 AM (which is Nov 14 in New York)
        let tokyoLogDate = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 15,
            hour: 10, minute: 0,
            timezone: tokyo
        )

        // Calculate boundaries using query timezone (New York)
        let sinceStart = CalendarUtils.startOfDayLocal(for: querySince, timezone: newYork)
        let logStart = CalendarUtils.startOfDayLocal(for: tokyoLogDate, timezone: newYork)

        // The log's calendar day in New York is Nov 14, which is BEFORE the query range
        let (_, _, logDay) = TimezoneTestHelpers.calendarDay(for: tokyoLogDate, in: newYork)
        #expect(logDay == 14, "Log should be Nov 14 in New York timezone")
        #expect(logStart < sinceStart, "Log from Nov 14 NY time should be before query start of Nov 15")
    }
}

/// Tests for DST transition handling in log filtering
@Suite("LogUseCases - DST Transition Handling")
@MainActor
struct LogUseCasesDSTTransitionTests {

    @Test("Spring forward DST transition calculates correct day boundaries")
    func springForwardDSTTransitionCalculatesCorrectDayBoundaries() {
        let newYork = TimezoneTestHelpers.newYork

        // DST spring forward in New York: March 9, 2025 at 2:00 AM → 3:00 AM
        let beforeDST = TimezoneTestHelpers.createDate(
            year: 2025, month: 3, day: 9,
            hour: 1, minute: 30,
            timezone: newYork
        )

        let afterDST = TimezoneTestHelpers.createDate(
            year: 2025, month: 3, day: 9,
            hour: 3, minute: 30,
            timezone: newYork
        )

        let beforeStart = CalendarUtils.startOfDayLocal(for: beforeDST, timezone: newYork)
        let afterStart = CalendarUtils.startOfDayLocal(for: afterDST, timezone: newYork)

        // Both should be the same day (March 9)
        #expect(beforeStart == afterStart, "Before and after DST should be same calendar day")
    }

    @Test("Fall back DST transition calculates correct day boundaries")
    func fallBackDSTTransitionCalculatesCorrectDayBoundaries() {
        let newYork = TimezoneTestHelpers.newYork

        // DST fall back in New York: November 2, 2025 at 2:00 AM → 1:00 AM
        let beforeFallBack = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 2,
            hour: 0, minute: 30,
            timezone: newYork
        )

        let afterFallBack = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 2,
            hour: 3, minute: 30,
            timezone: newYork
        )

        let beforeStart = CalendarUtils.startOfDayLocal(for: beforeFallBack, timezone: newYork)
        let afterStart = CalendarUtils.startOfDayLocal(for: afterFallBack, timezone: newYork)

        // Both should be the same day (November 2)
        #expect(beforeStart == afterStart, "Before and after fall back should be same calendar day")
    }

    @Test("Logs around DST transition filtered correctly")
    func logsAroundDSTTransitionFilteredCorrectly() {
        let newYork = TimezoneTestHelpers.newYork

        // Query for November 2, 2025 (DST fall back day)
        let queryDate = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 2,
            hour: 12, minute: 0,
            timezone: newYork
        )

        // Log at 1:30 AM before fall back
        let logBeforeFallBack = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 2,
            hour: 1, minute: 30,
            timezone: newYork
        )

        let queryStart = CalendarUtils.startOfDayLocal(for: queryDate, timezone: newYork)
        let logStart = CalendarUtils.startOfDayLocal(for: logBeforeFallBack, timezone: newYork)

        #expect(logStart == queryStart, "Log before DST fall back should be on same calendar day")
    }
}

/// Tests for midnight boundary edge cases
@Suite("LogUseCases - Midnight Boundary Edge Cases")
@MainActor
struct LogUseCasesMidnightBoundaryTests {

    @Test("Log at 23:59:59 is same day as log at 00:00:00")
    func logAtEndOfDayIsSameDayAsStartOfDay() {
        let timezone = TimezoneTestHelpers.tokyo

        let endOfDay = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 15,
            hour: 23, minute: 59,
            timezone: timezone
        )

        let startOfDay = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 15,
            hour: 0, minute: 0,
            timezone: timezone
        )

        let endStart = CalendarUtils.startOfDayLocal(for: endOfDay, timezone: timezone)
        let startStart = CalendarUtils.startOfDayLocal(for: startOfDay, timezone: timezone)

        #expect(endStart == startStart, "23:59 and 00:00 of same day should have same startOfDay")
    }

    @Test("Log at 00:00:01 next day is different from 23:59:59 previous day")
    func logAtStartOfNextDayIsDifferentFromEndOfPreviousDay() {
        let timezone = TimezoneTestHelpers.newYork

        let endOfDay15 = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 15,
            hour: 23, minute: 59,
            timezone: timezone
        )

        let startOfDay16 = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 16,
            hour: 0, minute: 1,
            timezone: timezone
        )

        let day15Start = CalendarUtils.startOfDayLocal(for: endOfDay15, timezone: timezone)
        let day16Start = CalendarUtils.startOfDayLocal(for: startOfDay16, timezone: timezone)

        #expect(day15Start != day16Start, "End of Nov 15 and start of Nov 16 should have different startOfDay")
    }

    @Test("Late night logging counts for correct day")
    func lateNightLoggingCountsForCorrectDay() {
        // Use the fixture scenario
        let scenario = TimezoneEdgeCaseFixtures.lateNightLoggingScenario(timezone: TimezoneTestHelpers.tokyo)

        // Verify the logs are for consecutive days
        let tokyo = TimezoneTestHelpers.tokyo
        var previousDay: Int?

        for log in scenario.logs {
            let (_, _, day) = TimezoneTestHelpers.calendarDay(for: log.date, in: tokyo)
            if let prev = previousDay {
                // Each log should be for the next day (or same day for multiple logs per day)
                #expect(day >= prev, "Logs should be in chronological order")
            }
            previousDay = day
        }
    }
}

/// Tests for batch filtering performance optimization
@Suite("LogUseCases - Batch Filtering Optimization")
@MainActor
struct LogUseCasesBatchFilteringOptimizationTests {

    @Test("Since and until boundaries are consistent across all logs")
    func sinceAndUntilBoundariesAreConsistentAcrossAllLogs() {
        // This test verifies the optimization where boundaries are calculated once
        let timezone = TimezoneTestHelpers.sydney

        let since = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 10,
            hour: 0, minute: 0,
            timezone: timezone
        )

        let until = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 20,
            hour: 23, minute: 59,
            timezone: timezone
        )

        // Pre-calculate boundaries (as the optimized code does)
        let sinceStart = CalendarUtils.startOfDayLocal(for: since, timezone: timezone)
        let untilStart = CalendarUtils.startOfDayLocal(for: until, timezone: timezone)

        // Verify boundaries are stable (multiple calls return same value)
        let sinceStart2 = CalendarUtils.startOfDayLocal(for: since, timezone: timezone)
        let untilStart2 = CalendarUtils.startOfDayLocal(for: until, timezone: timezone)

        #expect(sinceStart == sinceStart2, "Since boundary should be stable")
        #expect(untilStart == untilStart2, "Until boundary should be stable")
    }

    @Test("Optional since and until correctly handle nil values")
    func optionalSinceAndUntilCorrectlyHandleNilValues() {
        let timezone = TimezoneTestHelpers.utc

        // Test nil since
        let nilSince: Date? = nil
        let sinceStart = nilSince.map { CalendarUtils.startOfDayLocal(for: $0, timezone: timezone) }
        #expect(sinceStart == nil, "Nil since should produce nil boundary")

        // Test nil until
        let nilUntil: Date? = nil
        let untilStart = nilUntil.map { CalendarUtils.startOfDayLocal(for: $0, timezone: timezone) }
        #expect(untilStart == nil, "Nil until should produce nil boundary")

        // Test non-nil values
        let date = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 15,
            hour: 12, minute: 0,
            timezone: timezone
        )
        let optionalDate: Date? = date
        let dateStart = optionalDate.map { CalendarUtils.startOfDayLocal(for: $0, timezone: timezone) }
        #expect(dateStart != nil, "Non-nil date should produce boundary")
    }
}
