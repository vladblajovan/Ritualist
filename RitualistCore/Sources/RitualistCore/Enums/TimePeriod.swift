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
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .last6Months: return "Last 6 Months"
        case .lastYear: return "Last Year"
        case .allTime: return "All Time"
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
            // Use actual calendar week respecting user's week start preference
            let startOfWeek = CalendarUtils.startOfWeekLocal(for: now)
            return (start: startOfWeek, end: now)
            
        case .thisMonth:
            let startOfMonth = CalendarUtils.startOfMonthLocal(for: now)
            return (start: startOfMonth, end: now)
            
        case .last6Months:
            let sixMonthsAgo = CalendarUtils.addMonths(-6, to: now)
            return (start: sixMonthsAgo, end: now)
            
        case .lastYear:
            let oneYearAgo = CalendarUtils.addYears(-1, to: now)
            return (start: oneYearAgo, end: now)
            
        case .allTime:
            // Use a date far in the past to capture all available data
            let allTimeStart = CalendarUtils.addYears(-10, to: now)
            return (start: allTimeStart, end: now)
        }
    }
}