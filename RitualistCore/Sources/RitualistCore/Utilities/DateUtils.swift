//
//  DateUtils.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 29.07.2025.
//

import Foundation

public enum DateUtils {
    
    // MARK: - Current Time
    public static var now: Date { Date() }
    /// Normalize a Date to local midnight (00:00) in the given calendar.
    public static func startOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Returns true if two Dates fall on the same local day.
    public static func isSameDay(_ firstDate: Date, _ secondDate: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(firstDate, inSameDayAs: secondDate)
    }

    /// Whole days between two Dates, ignoring time‐of‐day.
    public static func daysBetween(_ from: Date, _ to: Date, calendar: Calendar = .current) -> Int {
        let dateFrom = calendar.startOfDay(for: from)
        let dateTo = calendar.startOfDay(for: to)
        return calendar.dateComponents([.day], from: dateFrom, to: dateTo).day ?? 0
    }

    /// ISO week‐of‐year key (year, week number) based on a custom firstWeekday.
    public static func weekKey(
        for date: Date,
        firstWeekday: Int,
        calendar base: Calendar = .current
    ) -> (year: Int, week: Int) {
        var cal = base
        cal.firstWeekday = firstWeekday
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return (comps.yearForWeekOfYear ?? 0, comps.weekOfYear ?? 0)
    }
    
    /// Creates a locale-aware calendar using system first day of week
    public static func userCalendar() -> Calendar {
        // Always use system calendar settings
        var calendar = Calendar.current
        calendar.locale = Locale.current
        return calendar
    }
    
    /// Get properly ordered weekday symbols respecting system week start preference
    public static func orderedWeekdaySymbols(style: WeekdaySymbolStyle = .veryShort) -> [String] {
        let calendar = userCalendar()
        var symbols: [String]
        
        switch style {
        case .veryShort:
            symbols = calendar.veryShortWeekdaySymbols
            // Check for duplicate symbols (common in German) and use short symbols instead
            if Set(symbols).count != symbols.count {
                symbols = calendar.shortWeekdaySymbols.map { symbol in
                    // Truncate short symbols to 2 characters for consistency
                    String(symbol.prefix(2))
                }
            }
        case .short:
            symbols = calendar.shortWeekdaySymbols
        case .standalone:
            symbols = calendar.standaloneWeekdaySymbols
        }
        
        // Calendar weekday symbols are ordered starting from Sunday (index 0)
        // System firstWeekday: 1=Sunday, 2=Monday, etc.
        // Convert to 0-based index for array access
        let startIndex = calendar.firstWeekday - 1
        
        // Ensure we don't go out of bounds
        guard startIndex >= 0 && startIndex < symbols.count else {
            return symbols
        }
        
        return Array(symbols[startIndex...]) + Array(symbols[..<startIndex])
    }
    
    public enum WeekdaySymbolStyle {
        case veryShort, short, standalone
    }
    
    /// Converts Calendar weekday (1=Sunday, 2=Monday...7=Saturday) to Habit weekday format (1=Monday, 2=Tuesday...7=Sunday)
    public static func calendarWeekdayToHabitWeekday(_ calendarWeekday: Int) -> Int {
        return calendarWeekday == 1 ? 7 : calendarWeekday - 1
    }
    
    /// Converts Habit weekday format (1=Monday, 2=Tuesday...7=Sunday) to Calendar weekday (1=Sunday, 2=Monday...7=Saturday)
    public static func habitWeekdayToCalendarWeekday(_ habitWeekday: Int) -> Int {
        return habitWeekday == 7 ? 1 : habitWeekday + 1
    }
    
    /// Generate dates inside a date interval matching specified components
    public static func generateDates(inside interval: DateInterval, matching components: DateComponents, calendar: Calendar = .current) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)
        
        calendar.enumerateDates(startingAfter: interval.start, matching: components, matchingPolicy: .nextTime) { date, _, stop in
            if let date = date {
                if date < interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }
        
        return dates
    }
    
    /// Check if a date falls on one of the scheduled weekdays
    /// Used by habit completion services to determine if a habit is scheduled for a given day
    /// @param scheduledDays: Set of weekday integers (1=Monday, 2=Tuesday...7=Sunday)
    public static func isDateInScheduledDays(_ date: Date, scheduledDays: Set<Int>, calendar: Calendar = .current) -> Bool {
        let calendarWeekday = calendar.component(.weekday, from: date)
        let habitWeekday = calendarWeekdayToHabitWeekday(calendarWeekday)
        return scheduledDays.contains(habitWeekday)
    }
    
    // MARK: - Timezone-Aware Date Normalization
    
    /// Normalize a date to the start of its calendar day in the user's current timezone.
    /// This ensures consistent day boundary calculations regardless of when logs were created.
    /// 
    /// **Critical for completion calculations**: Logs at 11:59 PM and 12:01 AM should count
    /// as the same day if they fall within the same calendar day in the user's timezone.
    ///
    /// - Parameters:
    ///   - date: The date to normalize
    ///   - calendar: The calendar to use (defaults to current user calendar with proper timezone)
    /// - Returns: The start of the calendar day in the user's timezone
    public static func normalizedStartOfDay(for date: Date, calendar: Calendar = .current) -> Date {
        var userCalendar = calendar
        // Ensure we're using the current timezone (in case calendar was cached with different timezone)
        userCalendar.timeZone = TimeZone.current
        return userCalendar.startOfDay(for: date)
    }
    
    /// Create a set of normalized dates (start of day) from an array of dates.
    /// This is specifically designed for counting unique days in habit completion logic.
    ///
    /// **Use case**: TimesPerWeek habits need to count unique days, not individual logs.
    /// Multiple logs on the same calendar day should count as one completion day.
    ///
    /// - Parameters:
    ///   - dates: Array of dates to normalize
    ///   - calendar: The calendar to use (defaults to current user calendar)
    /// - Returns: Set of normalized dates (start of day in user's timezone)
    public static func uniqueNormalizedDays(from dates: [Date], calendar: Calendar = .current) -> Set<Date> {
        return Set(dates.map { normalizedStartOfDay(for: $0, calendar: calendar) })
    }
    
    /// Check if two dates fall on the same calendar day in the user's current timezone.
    /// This is timezone-aware and handles edge cases like DST transitions.
    ///
    /// - Parameters:
    ///   - date1: First date to compare
    ///   - date2: Second date to compare
    ///   - calendar: The calendar to use (defaults to current user calendar)
    /// - Returns: True if both dates fall on the same calendar day
    public static func isSameCalendarDay(_ date1: Date, _ date2: Date, calendar: Calendar = .current) -> Bool {
        var userCalendar = calendar
        userCalendar.timeZone = TimeZone.current
        return userCalendar.isDate(date1, inSameDayAs: date2)
    }
}
