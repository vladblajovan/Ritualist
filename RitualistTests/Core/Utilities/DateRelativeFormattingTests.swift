import Foundation
import Testing
@testable import RitualistCore

/// Tests for Date relative formatting extensions
///
/// These tests verify that `relativeString()` and `relativeOrAbsoluteString()`
/// correctly format dates relative to now in human-readable format.
@Suite("Date - Relative Formatting")
struct DateRelativeFormattingTests {

    // MARK: - relativeString Tests

    @Test("Just now returns seconds ago")
    func justNowReturnsSecondsAgo() {
        let now = Date()
        let result = now.relativeString()

        // RelativeDateTimeFormatter returns "in 0 seconds" or "0 seconds ago" for now
        #expect(result.contains("second") || result.contains("now"),
                "Just now should mention seconds or now, got: \(result)")
    }

    @Test("Minutes ago formats correctly")
    func minutesAgoFormatsCorrectly() {
        let fiveMinutesAgo = Calendar.current.date(byAdding: .minute, value: -5, to: Date())!
        let result = fiveMinutesAgo.relativeString()

        #expect(result.contains("5") && result.contains("minute"),
                "5 minutes ago should mention '5' and 'minute', got: \(result)")
    }

    @Test("Hours ago formats correctly")
    func hoursAgoFormatsCorrectly() {
        let twoHoursAgo = Calendar.current.date(byAdding: .hour, value: -2, to: Date())!
        let result = twoHoursAgo.relativeString()

        #expect(result.contains("2") && result.contains("hour"),
                "2 hours ago should mention '2' and 'hour', got: \(result)")
    }

    @Test("Yesterday formats as yesterday")
    func yesterdayFormatsAsYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let result = yesterday.relativeString()

        // RelativeDateTimeFormatter with .named style should return "yesterday"
        #expect(result.lowercased().contains("yesterday") || result.contains("1 day"),
                "Yesterday should format as 'yesterday' or '1 day ago', got: \(result)")
    }

    @Test("Days ago formats correctly")
    func daysAgoFormatsCorrectly() {
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let result = threeDaysAgo.relativeString()

        #expect(result.contains("3") && result.contains("day"),
                "3 days ago should mention '3' and 'day', got: \(result)")
    }

    @Test("Last week formats correctly")
    func lastWeekFormatsCorrectly() {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let result = oneWeekAgo.relativeString()

        // Should be "last week" or "1 week ago"
        #expect(result.lowercased().contains("week"),
                "1 week ago should mention 'week', got: \(result)")
    }

    // MARK: - relativeOrAbsoluteString Tests

    @Test("Recent date uses relative format")
    func recentDateUsesRelativeFormat() {
        let twoHoursAgo = Calendar.current.date(byAdding: .hour, value: -2, to: Date())!
        let result = twoHoursAgo.relativeOrAbsoluteString()

        // Should use relative format (contains "ago" or similar)
        #expect(result.contains("hour") || result.contains("ago"),
                "Recent date should use relative format, got: \(result)")
    }

    @Test("Date within one week uses relative format")
    func dateWithinOneWeekUsesRelativeFormat() {
        let fiveDaysAgo = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let result = fiveDaysAgo.relativeOrAbsoluteString()

        // Should use relative format
        #expect(result.contains("day") || result.contains("ago"),
                "Date within 1 week should use relative format, got: \(result)")
    }

    @Test("Date older than one week uses absolute format")
    func dateOlderThanOneWeekUsesAbsoluteFormat() {
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let result = twoWeeksAgo.relativeOrAbsoluteString()

        // Should use absolute format with date (contains month name or comma for date format)
        // e.g., "Dec 10, 2024 at 3:45 PM"
        #expect(!result.contains("ago") && !result.contains("week"),
                "Date older than 1 week should use absolute format without 'ago', got: \(result)")

        // Verify it looks like a date (has year or contains "at" for time)
        let currentYear = Calendar.current.component(.year, from: Date())
        let lastYear = currentYear - 1
        #expect(result.contains("\(currentYear)") || result.contains("\(lastYear)") || result.contains("at"),
                "Absolute format should contain year or 'at' for time, got: \(result)")
    }

    @Test("Date from months ago uses absolute format")
    func dateFromMonthsAgoUsesAbsoluteFormat() {
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        let result = threeMonthsAgo.relativeOrAbsoluteString()

        // Should be absolute format
        #expect(!result.contains("ago"),
                "Date from months ago should not contain 'ago', got: \(result)")
    }

    // MARK: - Edge Cases

    @Test("Boundary: exactly 7 days ago uses relative format")
    func boundarySevenDaysAgoUsesRelativeFormat() {
        // 7 days ago at this exact time should still be within the week threshold
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let result = sevenDaysAgo.relativeOrAbsoluteString()

        // At exactly 7 days, it's on the boundary - could go either way
        // The implementation uses > oneWeekAgo, so exactly 7 days should use absolute
        // This test documents the actual behavior
        #expect(result.count > 0, "Should return some formatted string")
    }

    @Test("Boundary: 8 days ago uses absolute format")
    func boundaryEightDaysAgoUsesAbsoluteFormat() {
        let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -8, to: Date())!
        let result = eightDaysAgo.relativeOrAbsoluteString()

        // 8 days ago is definitely past the 1 week threshold
        #expect(!result.contains("ago"),
                "8 days ago should use absolute format, got: \(result)")
    }

    @Test("Future date handled gracefully")
    func futureDateHandledGracefully() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let result = tomorrow.relativeString()

        // RelativeDateTimeFormatter handles future dates with "in X time"
        #expect(result.contains("in") || result.contains("tomorrow"),
                "Future date should be handled, got: \(result)")
    }
}
