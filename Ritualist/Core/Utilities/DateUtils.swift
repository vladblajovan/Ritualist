//
//  DateUtils.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 29.07.2025.
//

import Foundation

public enum DateUtils {
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
    
    /// Creates a locale-aware calendar with user's preferred first day of week
    public static func userCalendar(firstDayOfWeek: Int? = nil) -> Calendar {
        var calendar = Calendar.current
        // Respect user preference if provided, otherwise use locale default
        if let userFirstDay = firstDayOfWeek {
            calendar.firstWeekday = userFirstDay
        }
        // Ensure proper locale is set
        calendar.locale = Locale.current
        return calendar
    }
    
    /// Get properly ordered weekday symbols respecting user's week start preference
    public static func orderedWeekdaySymbols(firstDayOfWeek: Int, style: WeekdaySymbolStyle = .veryShort) -> [String] {
        let calendar = userCalendar(firstDayOfWeek: firstDayOfWeek)
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
        // firstDayOfWeek: 1=Sunday, 2=Monday, etc.
        // Convert to 0-based index for array access
        let startIndex = firstDayOfWeek - 1
        
        // Ensure we don't go out of bounds
        guard startIndex >= 0 && startIndex < symbols.count else {
            return symbols
        }
        
        return Array(symbols[startIndex...]) + Array(symbols[..<startIndex])
    }
    
    public enum WeekdaySymbolStyle {
        case veryShort, short, standalone
    }
}
