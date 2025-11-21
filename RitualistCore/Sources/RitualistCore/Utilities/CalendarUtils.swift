//
//  CalendarUtils.swift
//  RitualistCore
//
//  Created by Claude on 28.08.2025.
//
//  Provides LOCAL timezone utilities for habit tracking business logic.
//  All business operations should use LOCAL methods (not UTC) to respect user's timezone.
//

import Foundation

/// Centralized calendar utilities that handle timezone-aware date operations consistently
/// Uses UTC for all business logic to ensure consistent behavior across timezones
public struct CalendarUtils {
    
    /// UTC calendar for business logic - ensures consistent day boundaries regardless of user timezone
    public static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(abbreviation: "UTC")!
        return calendar
    }()
    
    /// User's current device timezone calendar (for display)
    public static var currentLocalCalendar: Calendar {
        Calendar.current
    }
    
    /// Create calendar for specific timezone (for home timezone feature)
    /// Uses Calendar.current as base to preserve user's locale settings (firstWeekday, etc.)
    /// Note: Creates a new instance each time. For hot paths, use `cachedCalendar(for:)` instead.
    public static func localCalendar(for timezone: TimeZone) -> Calendar {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        return calendar
    }

    // MARK: - Calendar Caching

    /// Thread-safe cache for Calendar instances by timezone identifier.
    /// Avoids creating thousands of Calendar instances in hot paths like streak calculations.
    /// Limited to maxCalendarCacheSize entries to prevent unbounded growth.
    private static var calendarCache: [String: Calendar] = [:]
    private static let calendarCacheLock = NSLock()
    private static let maxCalendarCacheSize = 20  // More than enough for typical use (1-3 timezones)

    /// Get a cached Calendar for the given timezone.
    /// Thread-safe and reuses Calendar instances across calls.
    /// Use this in hot paths (loops over many logs/days) to avoid excessive object creation.
    public static func cachedCalendar(for timezone: TimeZone) -> Calendar {
        let identifier = timezone.identifier

        calendarCacheLock.lock()
        defer { calendarCacheLock.unlock() }

        if let cached = calendarCache[identifier] {
            return cached
        }

        // Evict oldest entry if cache is full (simple FIFO eviction)
        if calendarCache.count >= maxCalendarCacheSize {
            if let firstKey = calendarCache.keys.first {
                calendarCache.removeValue(forKey: firstKey)
            }
        }

        let calendar = localCalendar(for: timezone)
        calendarCache[identifier] = calendar
        return calendar
    }

    // MARK: - Storage with Timezone Context
    
    /// ISO8601 formatter for consistent date storage  
    public static let storageDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    /// Create timestamped entry with timezone context for logging
    public static func createTimestampedEntry() -> (timestamp: Date, timezone: String) {
        return (Date(), TimeZone.current.identifier)
    }
    
    /// Format timestamp in its original timezone context
    public static func formatInOriginalTimezone(_ utc: Date, _ timezoneId: String, 
                                              style: DateFormatter.Style = .medium) -> String {
        guard let timezone = TimeZone(identifier: timezoneId) else { 
            return formatInTimezone(utc, TimeZone.current, style: style)
        }
        return formatInTimezone(utc, timezone, style: style)
    }
    
    /// Format timestamp with timezone context indicator
    public static func formatWithTimezoneContext(_ utc: Date, _ timezoneId: String,
                                               currentTimezone: TimeZone = .current) -> String {
        guard let originalTz = TimeZone(identifier: timezoneId) else {
            return formatInTimezone(utc, currentTimezone)
        }
        
        let originalTime = formatInTimezone(utc, originalTz)
        
        // If different from current timezone, show context
        if originalTz.identifier != currentTimezone.identifier {
            let currentTime = formatInTimezone(utc, currentTimezone)
            return "\(currentTime) (was \(originalTime) \(originalTz.abbreviation() ?? ""))" 
        } else {
            return originalTime
        }
    }
    
    // MARK: - Business Logic (DEPRECATED: Use LOCAL methods)

    /// Checks if two dates are on the same day in UTC
    @available(*, deprecated, message: "Use areSameDayLocal() instead - habit tracking should use user's local timezone")
    public static func areSameDayUTC(_ date1: Date, _ date2: Date) -> Bool {
        utcCalendar.isDate(date1, inSameDayAs: date2)
    }

    /// Gets the start of day in UTC
    @available(*, deprecated, message: "Use startOfDayLocal() instead - habit tracking should use user's local timezone")
    public static func startOfDayUTC(for date: Date) -> Date {
        utcCalendar.startOfDay(for: date)
    }

    /// Gets the end of day in UTC (start of next day - 1 second)
    @available(*, deprecated, message: "Use endOfDayLocal() instead - habit tracking should use user's local timezone")
    public static func endOfDayUTC(for date: Date) -> Date {
        let startOfNextDay = utcCalendar.date(byAdding: .day, value: 1, to: startOfDayUTC(for: date))!
        return utcCalendar.date(byAdding: .second, value: -1, to: startOfNextDay)!
    }

    /// Calculate days between dates in UTC
    @available(*, deprecated, message: "Use daysBetweenLocal() instead - habit tracking should use user's local timezone")
    public static func daysBetweenUTC(_ from: Date, _ to: Date) -> Int {
        let dateFrom = startOfDayUTC(for: from)
        let dateTo = startOfDayUTC(for: to)
        return utcCalendar.dateComponents([.day], from: dateFrom, to: dateTo).day ?? 0
    }

    /// Check if date is today in UTC
    @available(*, deprecated, message: "Use isTodayLocal() instead - habit tracking should use user's local timezone")
    public static func isTodayUTC(_ date: Date) -> Bool {
        return areSameDayUTC(date, Date())
    }

    /// Check if date is yesterday in UTC
    @available(*, deprecated, message: "Use isYesterdayLocal() instead (add this method if needed) - habit tracking should use user's local timezone")
    public static func isYesterdayUTC(_ date: Date) -> Bool {
        guard let yesterday = utcCalendar.date(byAdding: .day, value: -1, to: Date()) else { return false }
        return areSameDayUTC(date, yesterday)
    }

    /// Check if date is tomorrow in UTC
    @available(*, deprecated, message: "Use isTomorrowLocal() instead (add this method if needed) - habit tracking should use user's local timezone")
    public static func isTomorrowUTC(_ date: Date) -> Bool {
        guard let tomorrow = utcCalendar.date(byAdding: .day, value: 1, to: Date()) else { return false }
        return areSameDayUTC(date, tomorrow)
    }
    
    // MARK: - Day Operations (Local)
    
    /// Check if two dates are on the same day in local timezone
    public static func areSameDayLocal(_ date1: Date, _ date2: Date, timezone: TimeZone = .current) -> Bool {
        let calendar = localCalendar(for: timezone)
        return calendar.isDate(date1, inSameDayAs: date2)
    }
    
    /// Get start of day in local timezone
    public static func startOfDayLocal(for date: Date, timezone: TimeZone = .current) -> Date {
        let calendar = localCalendar(for: timezone)
        return calendar.startOfDay(for: date)
    }
    
    /// Get end of day in local timezone
    public static func endOfDayLocal(for date: Date, timezone: TimeZone = .current) -> Date {
        let calendar = localCalendar(for: timezone)
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDayLocal(for: date, timezone: timezone))!
        return calendar.date(byAdding: .second, value: -1, to: startOfNextDay)!
    }
    
    /// Calculate days between dates in local timezone
    public static func daysBetweenLocal(_ from: Date, _ to: Date, timezone: TimeZone = .current) -> Int {
        let calendar = localCalendar(for: timezone)
        let dateFrom = startOfDayLocal(for: from, timezone: timezone)
        let dateTo = startOfDayLocal(for: to, timezone: timezone)
        return calendar.dateComponents([.day], from: dateFrom, to: dateTo).day ?? 0
    }
    
    /// Check if date is today in local timezone
    public static func isTodayLocal(_ date: Date, timezone: TimeZone = .current) -> Bool {
        return areSameDayLocal(date, Date(), timezone: timezone)
    }
    
    // MARK: - Month Operations (DEPRECATED: Use LOCAL methods)

    /// Get month interval in UTC
    @available(*, deprecated, message: "Use monthIntervalLocal() instead - habit tracking should use user's local timezone")
    public static func monthInterval(for date: Date) -> DateInterval? {
        return utcCalendar.dateInterval(of: .month, for: date)
    }

    /// Get month interval in UTC (alternative name)
    @available(*, deprecated, message: "Use monthIntervalLocal() instead - habit tracking should use user's local timezone")
    public static func monthIntervalUTC(for date: Date) -> DateInterval? {
        return monthInterval(for: date)
    }

    /// Check if two dates are in the same month (UTC)
    @available(*, deprecated, message: "Use isSameMonthLocal() (add this method if needed) - habit tracking should use user's local timezone")
    public static func isSameMonth(_ date1: Date, _ date2: Date) -> Bool {
        let components1 = utcCalendar.dateComponents([.year, .month], from: date1)
        let components2 = utcCalendar.dateComponents([.year, .month], from: date2)
        return components1.year == components2.year && components1.month == components2.month
    }

    /// Check if two dates are the same day (UTC)
    @available(*, deprecated, message: "Use areSameDayLocal() instead - habit tracking should use user's local timezone")
    public static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        return areSameDayUTC(date1, date2)
    }

    /// Get weekday component (UTC)
    @available(*, deprecated, message: "Use weekdayComponentLocal() (add this method if needed) - habit tracking should use user's local timezone")
    public static func weekdayComponent(from date: Date) -> Int {
        return weekdayComponentUTC(from: date)
    }
    
    /// Get first weekday of calendar
    public static func firstWeekday() -> Int {
        return utcCalendar.firstWeekday
    }
    
    // MARK: - Week Operations (DEPRECATED: Use LOCAL methods)

    /// Get week interval in UTC
    @available(*, deprecated, message: "Use weekIntervalLocal() instead - habit tracking should use user's local timezone")
    public static func weekIntervalUTC(for date: Date) -> DateInterval? {
        return utcCalendar.dateInterval(of: .weekOfYear, for: date)
    }

    /// Get start of week in UTC
    @available(*, deprecated, message: "Use startOfWeekLocal() instead - habit tracking should use user's local timezone")
    public static func startOfWeekUTC(for date: Date) -> Date {
        return weekIntervalUTC(for: date)?.start ?? startOfDayUTC(for: date)
    }

    /// Get end of week in UTC
    @available(*, deprecated, message: "Use endOfWeekLocal() instead - habit tracking should use user's local timezone")
    public static func endOfWeekUTC(for date: Date) -> Date {
        guard let weekInterval = weekIntervalUTC(for: date) else {
            return endOfDayUTC(for: date)
        }
        return utcCalendar.date(byAdding: .second, value: -1, to: weekInterval.end) ?? endOfDayUTC(for: date)
    }

    /// Get ISO week number
    @available(*, deprecated, message: "Use weekNumberLocal() (add this method if needed) - habit tracking should use user's local timezone")
    public static func weekNumberUTC(for date: Date) -> (year: Int, week: Int) {
        let components = utcCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return (components.yearForWeekOfYear ?? 0, components.weekOfYear ?? 0)
    }

    /// Check if two dates are in the same week
    @available(*, deprecated, message: "Use isInSameWeekLocal() (add this method if needed) - habit tracking should use user's local timezone")
    public static func isInSameWeekUTC(_ date1: Date, _ date2: Date) -> Bool {
        let week1 = weekNumberUTC(for: date1)
        let week2 = weekNumberUTC(for: date2)
        return week1.year == week2.year && week1.week == week2.week
    }

    /// Calculate weeks between dates
    @available(*, deprecated, message: "Use weeksBetweenLocal() (add this method if needed) - habit tracking should use user's local timezone")
    public static func weeksBetweenUTC(_ from: Date, _ to: Date) -> Int {
        return utcCalendar.dateComponents([.weekOfYear], from: startOfWeekUTC(for: from), to: startOfWeekUTC(for: to)).weekOfYear ?? 0
    }
    
    // MARK: - Week Operations (Local)
    
    /// Get week interval in local timezone
    public static func weekIntervalLocal(for date: Date, timezone: TimeZone = .current) -> DateInterval? {
        let calendar = localCalendar(for: timezone)
        return calendar.dateInterval(of: .weekOfYear, for: date)
    }
    
    /// Get start of week in local timezone
    public static func startOfWeekLocal(for date: Date, timezone: TimeZone = .current) -> Date {
        return weekIntervalLocal(for: date, timezone: timezone)?.start ?? startOfDayLocal(for: date, timezone: timezone)
    }
    
    /// Get end of week in local timezone
    public static func endOfWeekLocal(for date: Date, timezone: TimeZone = .current) -> Date {
        let calendar = localCalendar(for: timezone)
        guard let weekInterval = weekIntervalLocal(for: date, timezone: timezone) else {
            return endOfDayLocal(for: date, timezone: timezone)
        }
        return calendar.date(byAdding: .second, value: -1, to: weekInterval.end) ?? endOfDayLocal(for: date, timezone: timezone)
    }

    // MARK: - Month Operations (Local)

    /// Get month interval in local timezone
    public static func monthIntervalLocal(for date: Date, timezone: TimeZone = .current) -> DateInterval? {
        let calendar = localCalendar(for: timezone)
        return calendar.dateInterval(of: .month, for: date)
    }

    /// Get start of month in local timezone
    public static func startOfMonthLocal(for date: Date, timezone: TimeZone = .current) -> Date {
        return monthIntervalLocal(for: date, timezone: timezone)?.start ?? startOfDayLocal(for: date, timezone: timezone)
    }

    // MARK: - Component Extraction (DEPRECATED: Use LOCAL methods)

    /// Extract date components (year, month, day, hour, minute, second)
    @available(*, deprecated, message: "Use componentsLocal() (add this method if needed) - habit tracking should use user's local timezone")
    public static func componentsUTC(from date: Date, components: Set<Calendar.Component>) -> DateComponents {
        return utcCalendar.dateComponents(components, from: date)
    }

    /// Get weekday component in UTC (1=Sunday...7=Saturday)
    @available(*, deprecated, message: "Use weekdayComponentLocal() (add this method if needed) - habit tracking should use user's local timezone")
    public static func weekdayComponentUTC(from date: Date) -> Int {
        return utcCalendar.component(.weekday, from: date)
    }

    /// Get weekday component in local timezone (1=Sunday...7=Saturday)
    /// Uses cached calendar for performance in hot paths.
    public static func weekdayComponentLocal(from date: Date, timezone: TimeZone = .current) -> Int {
        let calendar = cachedCalendar(for: timezone)
        return calendar.component(.weekday, from: date)
    }

    /// Get ISO week number in local timezone
    public static func weekNumberLocal(for date: Date, timezone: TimeZone = .current) -> (year: Int, week: Int) {
        let calendar = localCalendar(for: timezone)
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return (components.yearForWeekOfYear ?? 0, components.weekOfYear ?? 0)
    }

    /// Get hour component in local timezone (0-23)
    public static func hourComponentLocal(from date: Date, timezone: TimeZone = .current) -> Int {
        let calendar = localCalendar(for: timezone)
        return calendar.component(.hour, from: date)
    }

    /// Get hour component (0-23)
    @available(*, deprecated, message: "Use hourComponentLocal() instead - habit tracking should use user's local timezone")
    public static func hourComponentUTC(from date: Date) -> Int {
        return utcCalendar.component(.hour, from: date)
    }
    
    /// Get time of day components (hour, minute)
    public static func timeOfDayUTC(from date: Date) -> (hour: Int, minute: Int) {
        let components = utcCalendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0, components.minute ?? 0)
    }
    
    // MARK: - Date Math Operations
    
    /// Add days to date
    public static func addDays(_ days: Int, to date: Date) -> Date {
        return utcCalendar.date(byAdding: .day, value: days, to: date) ?? date
    }
    
    /// Add weeks to date
    public static func addWeeks(_ weeks: Int, to date: Date) -> Date {
        return utcCalendar.date(byAdding: .weekOfYear, value: weeks, to: date) ?? date
    }
    
    /// Add months to date
    public static func addMonths(_ months: Int, to date: Date) -> Date {
        return utcCalendar.date(byAdding: .month, value: months, to: date) ?? date
    }
    
    /// Get next day (timezone-aware version)
    /// Adds 1 day using the specified timezone's calendar to handle DST correctly
    public static func nextDayLocal(from date: Date, timezone: TimeZone) -> Date {
        let calendar = localCalendar(for: timezone)
        return calendar.date(byAdding: .day, value: 1, to: date) ?? date
    }

    /// Add days to date (timezone-aware version)
    /// Adds days using the specified timezone's calendar to handle DST correctly
    public static func addDaysLocal(_ days: Int, to date: Date, timezone: TimeZone) -> Date {
        let calendar = localCalendar(for: timezone)
        return calendar.date(byAdding: .day, value: days, to: date) ?? date
    }

    /// Add years to date (timezone-aware version)
    /// Adds years using the specified timezone's calendar to handle DST correctly
    public static func addYearsLocal(_ years: Int, to date: Date, timezone: TimeZone) -> Date {
        let calendar = localCalendar(for: timezone)
        return calendar.date(byAdding: .year, value: years, to: date) ?? date
    }

    /// Get next day (UTC version - deprecated for timezone-aware code)
    public static func nextDay(from date: Date) -> Date {
        return addDays(1, to: date)
    }

    /// Get previous day
    public static func previousDay(from date: Date) -> Date {
        return addDays(-1, to: date)
    }
    
    /// Get next week
    public static func nextWeek(from date: Date) -> Date {
        return addWeeks(1, to: date)
    }
    
    /// Get previous week
    public static func previousWeek(from date: Date) -> Date {
        return addWeeks(-1, to: date)
    }
    
    /// Add minutes to a date
    public static func addMinutes(_ minutes: Int, to date: Date) -> Date {
        return utcCalendar.date(byAdding: .minute, value: minutes, to: date) ?? date
    }
    
    /// Add years to a date
    public static func addYears(_ years: Int, to date: Date) -> Date {
        return utcCalendar.date(byAdding: .year, value: years, to: date) ?? date
    }
    
    // MARK: - Weekday Handling (Habit-specific)
    
    /// Convert Calendar weekday (1=Sunday) to Habit weekday (1=Monday)
    public static func calendarWeekdayToHabitWeekday(_ calendarWeekday: Int) -> Int {
        return calendarWeekday == 1 ? 7 : calendarWeekday - 1
    }
    
    /// Convert Habit weekday (1=Monday) to Calendar weekday (1=Sunday)
    public static func habitWeekdayToCalendarWeekday(_ habitWeekday: Int) -> Int {
        return habitWeekday == 7 ? 1 : habitWeekday + 1
    }

    /// Get habit weekday (1=Monday...7=Sunday) from date in local timezone
    /// Convenience method combining weekdayComponentLocal() and calendarWeekdayToHabitWeekday()
    public static func habitWeekday(from date: Date, timezone: TimeZone = .current) -> Int {
        let calendarWeekday = weekdayComponentLocal(from: date, timezone: timezone)
        return calendarWeekdayToHabitWeekday(calendarWeekday)
    }

    /// Check if date falls on scheduled weekday(s)
    public static func isScheduledWeekday(_ date: Date, scheduledDays: Set<Int>) -> Bool {
        let calendarWeekday = weekdayComponentUTC(from: date)
        let habitWeekday = calendarWeekdayToHabitWeekday(calendarWeekday)
        return scheduledDays.contains(habitWeekday)
    }
    
    // MARK: - Formatting & Display
    
    /// Format date in specified timezone
    private static func formatInTimezone(_ date: Date, _ timezone: TimeZone, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeZone = timezone
        return formatter.string(from: date)
    }
    
    /// Format date for UI display in specified timezone
    public static func formatForDisplay(_ date: Date, style: DateFormatter.Style = .medium, timezone: TimeZone = .current) -> String {
        return formatInTimezone(date, timezone, style: style)
    }
    
    /// Format time components in specified timezone
    public static func formatTime(_ date: Date, timezone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = timezone
        return formatter.string(from: date)
    }
    
    /// Format log entry based on user's display preference
    /// - Parameters:
    ///   - utcTimestamp: The UTC timestamp to format
    ///   - originalTimezone: The timezone where the log was originally recorded (preserved for context)
    ///   - displayMode: How to display the timestamp (current/home/custom timezone)
    ///   - userTimezone: The device's current timezone
    ///   - homeTimezone: The user's designated home timezone
    /// - Returns: Formatted string representation of the timestamp
    public static func formatLogEntry(_ utcTimestamp: Date, _ originalTimezone: String,
                                    displayMode: DisplayTimezoneMode,
                                    userTimezone: TimeZone = .current,
                                    homeTimezone: TimeZone? = nil) -> String {
        switch displayMode {
        case .current:
            // Display in user's current device timezone
            return formatWithTimezoneContext(utcTimestamp, originalTimezone, currentTimezone: userTimezone)
        case .home:
            // Display in user's home timezone
            guard let homeTimezone = homeTimezone else {
                // Fallback to current timezone if home timezone not set
                return formatWithTimezoneContext(utcTimestamp, originalTimezone, currentTimezone: userTimezone)
            }
            return formatInTimezone(utcTimestamp, homeTimezone)
        case .custom(let timezoneIdentifier):
            // Display in specific custom timezone
            guard let customTimezone = TimeZone(identifier: timezoneIdentifier) else {
                // Fallback to current timezone if custom timezone is invalid
                return formatWithTimezoneContext(utcTimestamp, originalTimezone, currentTimezone: userTimezone)
            }
            return formatInTimezone(utcTimestamp, customTimezone)
        }
    }
    
    /// Check if user is in different timezone than when log was created
    public static func isInDifferentTimezone(originalTimezone: String, currentTimezone: TimeZone = .current) -> Bool {
        return originalTimezone != currentTimezone.identifier
    }
    
    // MARK: - Unique Day Counting (for habit completion)
    
    /// Get set of unique days from array of dates (normalized to day start)
    public static func uniqueDaysUTC(from dates: [Date]) -> Set<Date> {
        return Set(dates.map { startOfDayUTC(for: $0) })
    }
    
    /// Count unique days in date array
    public static func countUniqueDaysUTC(in dates: [Date]) -> Int {
        return uniqueDaysUTC(from: dates).count
    }
    
    // MARK: - Validation
    
    /// Check if date is in the past
    public static func isInPast(_ date: Date) -> Bool {
        return date < Date()
    }
    
    /// Check if date is in the future
    public static func isInFuture(_ date: Date) -> Bool {
        return date > Date()
    }
    
    /// Check if date is within range
    public static func isWithinRange(_ date: Date, from: Date, to: Date) -> Bool {
        return date >= from && date <= to
    }

    // MARK: - Cross-Timezone Day Comparison

    /// Check if two dates fall on the same calendar day when each is interpreted in its own timezone.
    ///
    /// Unlike `areSameDayLocal` which uses one timezone for both dates, this method allows
    /// each date to be interpreted in a different timezone before comparing calendar days.
    ///
    /// Example: A timestamp at 11 PM EST (Nov 20) and a timestamp at 2 AM UTC (Nov 21)
    /// would be considered the same calendar day if tz1=EST and tz2=UTC, because:
    /// - Date1 in EST = Nov 20
    /// - Date2 in UTC = Nov 21
    /// Result: NOT the same day
    ///
    /// - Parameters:
    ///   - date1: First date to compare
    ///   - timezone1: Timezone to interpret date1 in
    ///   - date2: Second date to compare
    ///   - timezone2: Timezone to interpret date2 in
    /// - Returns: `true` if both dates fall on the same calendar day (year, month, day match)
    public static func areSameDayAcrossTimezones(
        _ date1: Date,
        timezone1: TimeZone,
        _ date2: Date,
        timezone2: TimeZone
    ) -> Bool {
        // Use cached calendars to avoid creating thousands of instances in hot paths
        let calendar1 = cachedCalendar(for: timezone1)
        let components1 = calendar1.dateComponents([.year, .month, .day], from: date1)

        let calendar2 = cachedCalendar(for: timezone2)
        let components2 = calendar2.dateComponents([.year, .month, .day], from: date2)

        return components1.year == components2.year &&
               components1.month == components2.month &&
               components1.day == components2.day
    }
}
