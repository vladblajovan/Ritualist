//
//  CalendarUtils.swift
//  RitualistCore
//
//  Created by Claude on 28.08.2025.
//

import Foundation

/// Display mode for showing timestamps with timezone context
public enum DisplayTimezoneMode: String, CaseIterable {
    case original      // Show times as they were originally experienced
    case current      // Show times in user's current timezone
    case home         // Show times in user's designated home timezone
}

/// Centralized calendar utilities that handle timezone-aware date operations consistently
/// Uses UTC for all business logic to ensure consistent behavior across timezones
public struct CalendarUtils {
    
    /// UTC calendar for business logic - ensures consistent day boundaries regardless of user timezone
    public static let utcCalendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(abbreviation: "UTC")!
        return calendar
    }()
    
    /// User's current device timezone calendar (for display)
    public static var currentLocalCalendar: Calendar {
        Calendar.current
    }
    
    /// Create calendar for specific timezone (for home timezone feature)
    public static func localCalendar(for timezone: TimeZone) -> Calendar {
        var calendar = Calendar.current
        calendar.timeZone = timezone
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
    
    // MARK: - Business Logic (Always UTC)
    
    /// Checks if two dates are on the same day in UTC
    /// Use this for business logic like "already logged today"
    public static func areSameDayUTC(_ date1: Date, _ date2: Date) -> Bool {
        utcCalendar.isDate(date1, inSameDayAs: date2)
    }
    
    /// Gets the start of day in UTC
    /// Use this for business logic date range calculations
    public static func startOfDayUTC(for date: Date) -> Date {
        utcCalendar.startOfDay(for: date)
    }
    
    /// Gets the end of day in UTC (start of next day - 1 second)
    public static func endOfDayUTC(for date: Date) -> Date {
        let startOfNextDay = utcCalendar.date(byAdding: .day, value: 1, to: startOfDayUTC(for: date))!
        return utcCalendar.date(byAdding: .second, value: -1, to: startOfNextDay)!
    }
    
    /// Calculate days between dates in UTC
    public static func daysBetweenUTC(_ from: Date, _ to: Date) -> Int {
        let dateFrom = startOfDayUTC(for: from)
        let dateTo = startOfDayUTC(for: to)
        return utcCalendar.dateComponents([.day], from: dateFrom, to: dateTo).day ?? 0
    }
    
    /// Check if date is today in UTC
    public static func isTodayUTC(_ date: Date) -> Bool {
        return areSameDayUTC(date, Date())
    }
    
    /// Check if date is yesterday in UTC
    public static func isYesterdayUTC(_ date: Date) -> Bool {
        guard let yesterday = utcCalendar.date(byAdding: .day, value: -1, to: Date()) else { return false }
        return areSameDayUTC(date, yesterday)
    }
    
    /// Check if date is tomorrow in UTC
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
    
    // MARK: - Month Operations (UTC)
    
    /// Get month interval in UTC
    public static func monthInterval(for date: Date) -> DateInterval? {
        return utcCalendar.dateInterval(of: .month, for: date)
    }
    
    /// Get month interval in UTC (alternative name)
    public static func monthIntervalUTC(for date: Date) -> DateInterval? {
        return monthInterval(for: date)
    }
    
    /// Check if two dates are in the same month (UTC)
    public static func isSameMonth(_ date1: Date, _ date2: Date) -> Bool {
        let components1 = utcCalendar.dateComponents([.year, .month], from: date1)
        let components2 = utcCalendar.dateComponents([.year, .month], from: date2)
        return components1.year == components2.year && components1.month == components2.month
    }
    
    /// Check if two dates are the same day (UTC)
    public static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        return areSameDayUTC(date1, date2)
    }
    
    /// Get weekday component (UTC)
    public static func weekdayComponent(from date: Date) -> Int {
        return weekdayComponentUTC(from: date)
    }
    
    /// Get first weekday of calendar
    public static func firstWeekday() -> Int {
        return utcCalendar.firstWeekday
    }
    
    // MARK: - Week Operations (UTC)
    
    /// Get week interval in UTC
    public static func weekIntervalUTC(for date: Date) -> DateInterval? {
        return utcCalendar.dateInterval(of: .weekOfYear, for: date)
    }
    
    /// Get start of week in UTC
    public static func startOfWeekUTC(for date: Date) -> Date {
        return weekIntervalUTC(for: date)?.start ?? startOfDayUTC(for: date)
    }
    
    /// Get end of week in UTC
    public static func endOfWeekUTC(for date: Date) -> Date {
        guard let weekInterval = weekIntervalUTC(for: date) else {
            return endOfDayUTC(for: date)
        }
        return utcCalendar.date(byAdding: .second, value: -1, to: weekInterval.end) ?? endOfDayUTC(for: date)
    }
    
    /// Get ISO week number
    public static func weekNumberUTC(for date: Date) -> (year: Int, week: Int) {
        let components = utcCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return (components.yearForWeekOfYear ?? 0, components.weekOfYear ?? 0)
    }
    
    /// Check if two dates are in the same week
    public static func isInSameWeekUTC(_ date1: Date, _ date2: Date) -> Bool {
        let week1 = weekNumberUTC(for: date1)
        let week2 = weekNumberUTC(for: date2)
        return week1.year == week2.year && week1.week == week2.week
    }
    
    /// Calculate weeks between dates
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
    
    // MARK: - Component Extraction
    
    /// Extract date components (year, month, day, hour, minute, second)
    public static func componentsUTC(from date: Date, components: Set<Calendar.Component>) -> DateComponents {
        return utcCalendar.dateComponents(components, from: date)
    }
    
    /// Get weekday component (1=Sunday...7=Saturday)
    public static func weekdayComponentUTC(from date: Date) -> Int {
        return utcCalendar.component(.weekday, from: date)
    }
    
    /// Get hour component (0-23)
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
    
    /// Get next day
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
    public static func formatLogEntry(_ utcTimestamp: Date, _ originalTimezone: String,
                                    displayMode: DisplayTimezoneMode, 
                                    userTimezone: TimeZone = .current,
                                    homeTimezone: TimeZone? = nil) -> String {
        switch displayMode {
        case .original:
            return formatInOriginalTimezone(utcTimestamp, originalTimezone)
        case .current:
            return formatWithTimezoneContext(utcTimestamp, originalTimezone, currentTimezone: userTimezone)
        case .home:
            guard let homeTimezone = homeTimezone else {
                return formatInOriginalTimezone(utcTimestamp, originalTimezone)
            }
            return formatInTimezone(utcTimestamp, homeTimezone)
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
}