import Foundation
@testable import RitualistCore

/// Fixed test dates to avoid time-dependent flakiness
/// All dates are set to a fixed point in time for consistent testing
enum TestDates {

    // MARK: - Base Test Date

    /// Fixed reference date for tests: November 8, 2025 at noon UTC
    /// This ensures tests don't fail due to time zone or date changes
    static let referenceDate: Date = {
        var components = DateComponents()
        components.year = 2025
        components.month = 11
        components.day = 8
        components.hour = 12
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)!
    }()

    /// Today (reference date)
    static var today: Date {
        CalendarUtils.startOfDayLocal(for: referenceDate)
    }

    /// Yesterday (reference date - 1 day)
    static var yesterday: Date {
        CalendarUtils.addDaysLocal(-1, to: today, timezone: .current)
    }

    /// Tomorrow (reference date + 1 day)
    static var tomorrow: Date {
        CalendarUtils.addDaysLocal(1, to: today, timezone: .current)
    }

    // MARK: - Relative Date Helpers

    /// Get date N days ago from reference date
    static func daysAgo(_ days: Int) -> Date {
        CalendarUtils.addDaysLocal(-days, to: today, timezone: .current)
    }

    /// Get date N days from now (from reference date)
    static func daysFromNow(_ days: Int) -> Date {
        CalendarUtils.addDaysLocal(days, to: today, timezone: .current)
    }

    /// Get date N weeks ago from reference date
    static func weeksAgo(_ weeks: Int) -> Date {
        CalendarUtils.addDaysLocal(-weeks * 7, to: today, timezone: .current)
    }

    /// Get date N months ago from reference date (approximate - 30 days)
    static func monthsAgo(_ months: Int) -> Date {
        CalendarUtils.addDaysLocal(-months * 30, to: today, timezone: .current)
    }

    // MARK: - Date Range Helpers

    /// Create a date range starting from today going back N days
    /// Example: pastDays(7) returns [today-6, today-5, ..., today-1, today]
    static func pastDays(_ count: Int) -> [Date] {
        let start = count - 1
        return (0...start).reversed().map { days in
            daysAgo(days)
        }
    }

    /// Create a date range for the last N days (inclusive)
    static func dateRange(days: Int, endingAt endDate: Date = today) -> ClosedRange<Date> {
        let startDate = CalendarUtils.addDaysLocal(-(days - 1), to: endDate, timezone: .current)
        return CalendarUtils.startOfDayLocal(for: startDate)...CalendarUtils.startOfDayLocal(for: endDate)
    }

    /// Create a standard 30-day cache range (today back to 29 days ago)
    static func standard30DayRange(from startDate: Date = today) -> ClosedRange<Date> {
        let endDate = CalendarUtils.addDaysLocal(29, to: startDate, timezone: .current)
        return CalendarUtils.startOfDayLocal(for: startDate)...CalendarUtils.startOfDayLocal(for: endDate)
    }

    // MARK: - Week Helpers

    /// Get all dates for the current week (Monday to Sunday)
    static func currentWeek() -> [Date] {
        guard let weekInterval = CalendarUtils.weekIntervalLocal(for: today) else {
            return []
        }

        var dates: [Date] = []
        var currentDate = weekInterval.start

        while currentDate < weekInterval.end {
            dates.append(currentDate)
            currentDate = CalendarUtils.addDays(1, to: currentDate)
        }

        return dates
    }

    // MARK: - Month Helpers

    /// Get all dates for the current month
    static func currentMonth() -> [Date] {
        guard let monthInterval = CalendarUtils.monthIntervalLocal(for: today) else {
            return []
        }

        var dates: [Date] = []
        var currentDate = monthInterval.start

        while currentDate < monthInterval.end {
            dates.append(currentDate)
            currentDate = CalendarUtils.addDays(1, to: currentDate)
        }

        return dates
    }
}

// MARK: - Test Assertions

/// Helper assertions for testing cache behavior
enum TestAssertions {

    /// Check if a date is within a cache range
    static func isInRange(_ date: Date, range: ClosedRange<Date>) -> Bool {
        let dateStart = CalendarUtils.startOfDayLocal(for: date)
        return range.contains(dateStart)
    }

    /// Check if two OverviewData instances have the same structure
    static func areSameStructure(_ data1: OverviewData, _ data2: OverviewData) -> Bool {
        // Same number of habits
        guard data1.habits.count == data2.habits.count else { return false }

        // Same number of habit log entries
        guard data1.habitLogs.count == data2.habitLogs.count else { return false }

        // Same date range
        guard data1.dateRange == data2.dateRange else { return false }

        return true
    }

    /// Count total logs across all habits in OverviewData
    static func totalLogCount(_ data: OverviewData) -> Int {
        return data.habitLogs.values.reduce(0) { $0 + $1.count }
    }
}
