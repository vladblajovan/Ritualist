import Foundation

/// Time period enumeration for analytics and dashboard functionality.
/// 
/// Provides standardized time periods commonly used across analytics features,
/// with sophisticated date range calculation logic that respects calendar boundaries.
///
/// Usage:
/// ```swift
/// let period = TimePeriod.thisMonth
/// let range = period.dateRange
/// let displayName = period.displayName
/// ```
public enum TimePeriod: CaseIterable {
    case thisWeek
    case thisMonth
    case last6Months
    case lastYear
    case allTime
    
    /// Human-readable display name for the time period
    public var displayName: String {
        switch self {
        case .thisWeek: return "Last 7 Days"
        case .thisMonth: return "This Month"
        case .last6Months: return "Last 6 Months"
        case .lastYear: return "Last Year"
        case .allTime: return "All Time"
        }
    }

    /// Short display name for compact UI (segmented controls, tabs)
    public var shortDisplayName: String {
        switch self {
        case .thisWeek: return "7D"
        case .thisMonth: return "1M"
        case .last6Months: return "6M"
        case .lastYear: return "1Y"
        case .allTime: return "All"
        }
    }

    /// Accessibility label for VoiceOver (expands abbreviations)
    public var accessibilityLabel: String {
        switch self {
        case .thisWeek: return "Last 7 days"
        case .thisMonth: return "Last month"
        case .last6Months: return "Last 6 months"
        case .lastYear: return "Last year"
        case .allTime: return "All time"
        }
    }
    
    /// Calculated date range for the time period
    /// 
    /// Returns a tuple with start and end dates based on calendar calculations.
    /// Uses current calendar and date for accurate period boundaries.
    ///
    /// - Returns: A tuple containing start and end dates for the period
    public var dateRange: (start: Date, end: Date) {
        let now = Date()

        switch self {
        case .thisWeek:
            // Rolling 7-day window (last 7 days including today)
            // Matches the "7D" label and "Last 7 days" accessibility text
            let sevenDaysAgo = CalendarUtils.addDaysLocal(-6, to: now, timezone: .current)
            let startOfDay = CalendarUtils.startOfDayLocal(for: sevenDaysAgo)
            return (start: startOfDay, end: now)
            
        case .thisMonth:
            let startOfMonth = CalendarUtils.startOfMonthLocal(for: now)
            return (start: startOfMonth, end: now)
            
        case .last6Months:
            let sixMonthsAgo = CalendarUtils.addMonths(-6, to: now)
            let startOfDay = CalendarUtils.startOfDayLocal(for: sixMonthsAgo)
            return (start: startOfDay, end: now)

        case .lastYear:
            let oneYearAgo = CalendarUtils.addYears(-1, to: now)
            let startOfDay = CalendarUtils.startOfDayLocal(for: oneYearAgo)
            return (start: startOfDay, end: now)

        case .allTime:
            // Use a date far in the past to capture all available data
            let allTimeStart = CalendarUtils.addYears(-10, to: now)
            let startOfDay = CalendarUtils.startOfDayLocal(for: allTimeStart)
            return (start: startOfDay, end: now)
        }
    }
}