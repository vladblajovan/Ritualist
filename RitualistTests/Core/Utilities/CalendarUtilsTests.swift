import Foundation
import Testing
@testable import RitualistCore

/// Tests for CalendarUtils cross-timezone day comparison
///
/// These tests verify that `areSameDayAcrossTimezones` correctly determines
/// whether two dates represent the same calendar day when each is interpreted
/// in its own timezone.
@Suite("CalendarUtils - Cross-Timezone Day Comparison")
@MainActor
struct CalendarUtilsTests {

    // MARK: - areSameDayAcrossTimezones Tests

    @Test("Same instant can be different calendar days in different timezones")
    func sameInstantDifferentCalendarDays() {
        // 2024-01-15 23:30 EST (America/New_York) = 2024-01-16 04:30 UTC
        // In New York: January 15
        // In UTC: January 16
        let newYork = TimezoneTestHelpers.newYork
        let utc = TimezoneTestHelpers.utc

        // Create a date at 23:30 EST on Jan 15
        let dateInNewYork = TimezoneTestHelpers.createDate(
            year: 2024, month: 1, day: 15,
            hour: 23, minute: 30,
            timezone: newYork
        )

        // Same instant should be different calendar days
        let result = CalendarUtils.areSameDayAcrossTimezones(
            dateInNewYork, timezone1: newYork,
            dateInNewYork, timezone2: utc
        )

        #expect(!result, "23:30 EST Jan 15 should be Jan 16 in UTC - different calendar days")
    }

    @Test("Same calendar day in same timezone returns true")
    func sameCalendarDaySameTimezone() {
        let tokyo = TimezoneTestHelpers.tokyo

        let morning = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 20,
            hour: 9, minute: 0,
            timezone: tokyo
        )

        let evening = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 20,
            hour: 21, minute: 30,
            timezone: tokyo
        )

        let result = CalendarUtils.areSameDayAcrossTimezones(
            morning, timezone1: tokyo,
            evening, timezone2: tokyo
        )

        #expect(result, "Morning and evening of same day in same timezone should be same calendar day")
    }

    @Test("Different calendar days returns false")
    func differentCalendarDaysReturnsFalse() {
        let utc = TimezoneTestHelpers.utc

        let day1 = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 20,
            hour: 12, minute: 0,
            timezone: utc
        )

        let day2 = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 21,
            hour: 12, minute: 0,
            timezone: utc
        )

        let result = CalendarUtils.areSameDayAcrossTimezones(
            day1, timezone1: utc,
            day2, timezone2: utc
        )

        #expect(!result, "Different days should return false")
    }

    @Test("Late night in far-ahead timezone matches previous day in far-behind timezone")
    func extremeTimezoneOffsets() {
        // Kiritimati (UTC+14) vs Los Angeles (UTC-8) = 22 hour difference
        // 2:00 AM on Jan 2 in Kiritimati = 4:00 AM on Jan 1 in Los Angeles (previous day!)
        let kiritimati = TimezoneTestHelpers.kiritimati
        let losAngeles = TimezoneTestHelpers.losAngeles

        // Create date at 2 AM Kiritimati time on Jan 2
        let dateInKiritimati = TimezoneTestHelpers.createDate(
            year: 2025, month: 1, day: 2,
            hour: 2, minute: 0,
            timezone: kiritimati
        )

        // This same instant is still Jan 1 in Los Angeles
        // Query: Is Jan 2 Kiritimati the same as this instant in LA time?
        let result = CalendarUtils.areSameDayAcrossTimezones(
            dateInKiritimati, timezone1: kiritimati,
            dateInKiritimati, timezone2: losAngeles
        )

        #expect(!result, "Early morning Kiritimati Jan 2 is still Jan 1 in Los Angeles")
    }

    @Test("Cross-timezone comparison: log created late at night matches query for that day")
    func lateNightLogMatchesQueryDay() {
        // User logs habit at 11:30 PM New York time
        // Query should find this log when looking for that calendar day
        let newYork = TimezoneTestHelpers.newYork

        let logDate = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 20,
            hour: 23, minute: 30,
            timezone: newYork
        )

        // Query for Nov 20 at noon (same day, same timezone)
        let queryDate = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 20,
            hour: 12, minute: 0,
            timezone: newYork
        )

        let result = CalendarUtils.areSameDayAcrossTimezones(
            logDate, timezone1: newYork,
            queryDate, timezone2: newYork
        )

        #expect(result, "11:30 PM log should match query for that same calendar day")
    }

    @Test("Year boundary: Dec 31 vs Jan 1")
    func yearBoundary() {
        let utc = TimezoneTestHelpers.utc

        let dec31 = TimezoneTestHelpers.createDate(
            year: 2024, month: 12, day: 31,
            hour: 23, minute: 59,
            timezone: utc
        )

        let jan1 = TimezoneTestHelpers.createDate(
            year: 2025, month: 1, day: 1,
            hour: 0, minute: 1,
            timezone: utc
        )

        let result = CalendarUtils.areSameDayAcrossTimezones(
            dec31, timezone1: utc,
            jan1, timezone2: utc
        )

        #expect(!result, "Dec 31 and Jan 1 are different days")
    }

    @Test("Month boundary: Jan 31 vs Feb 1")
    func monthBoundary() {
        let utc = TimezoneTestHelpers.utc

        let jan31 = TimezoneTestHelpers.createDate(
            year: 2025, month: 1, day: 31,
            hour: 12, minute: 0,
            timezone: utc
        )

        let feb1 = TimezoneTestHelpers.createDate(
            year: 2025, month: 2, day: 1,
            hour: 12, minute: 0,
            timezone: utc
        )

        let result = CalendarUtils.areSameDayAcrossTimezones(
            jan31, timezone1: utc,
            feb1, timezone2: utc
        )

        #expect(!result, "Jan 31 and Feb 1 are different days")
    }

    // MARK: - Calendar Caching Tests

    @Test("Cached calendar returns consistent results")
    func cachedCalendarConsistency() {
        let tokyo = TimezoneTestHelpers.tokyo

        // Get calendar twice - should use cache
        let calendar1 = CalendarUtils.cachedCalendar(for: tokyo)
        let calendar2 = CalendarUtils.cachedCalendar(for: tokyo)

        // Both should have same timezone
        #expect(calendar1.timeZone.identifier == tokyo.identifier)
        #expect(calendar2.timeZone.identifier == tokyo.identifier)
    }

    @Test("Multiple timezone calendars work correctly")
    func multipleTimezoneCalendars() {
        let timezones = TimezoneTestHelpers.testTimezones

        for timezone in timezones {
            let calendar = CalendarUtils.cachedCalendar(for: timezone)
            #expect(
                calendar.timeZone.identifier == timezone.identifier,
                "Calendar for \(timezone.identifier) should have correct timezone"
            )
        }
    }
}
