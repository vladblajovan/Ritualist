//
//  CalendarUtils.swift
//  RitualistCore
//
//  Created by Claude on 28.08.2025.
//

import Foundation

/// Centralized calendar utilities that handle timezone-aware date operations consistently
/// Uses UTC for all business logic to ensure consistent behavior across timezones
public struct CalendarUtils {
    
    /// UTC calendar for business logic - ensures consistent day boundaries regardless of user timezone
    public static let utcCalendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(abbreviation: "UTC")!
        return calendar
    }()
    
    /// User's local calendar for UI display purposes
    public static let localCalendar = Calendar.current
    
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
    
    // MARK: - UI Display (Local Timezone)
    
    /// Checks if two dates are on the same day in user's local timezone
    /// Use this for UI display like grouping logs by day
    public static func areSameDayLocal(_ date1: Date, _ date2: Date) -> Bool {
        localCalendar.isDate(date1, inSameDayAs: date2)
    }
    
    /// Gets the start of day in user's local timezone
    /// Use this for UI display purposes
    public static func startOfDayLocal(for date: Date) -> Date {
        localCalendar.startOfDay(for: date)
    }
}