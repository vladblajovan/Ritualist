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
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return (start: startOfWeek, end: now)
            
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return (start: startOfMonth, end: now)
            
        case .last6Months:
            let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now) ?? now
            return (start: sixMonthsAgo, end: now)
            
        case .lastYear:
            let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return (start: oneYearAgo, end: now)
            
        case .allTime:
            // Use a date far in the past to capture all available data
            let allTimeStart = calendar.date(byAdding: .year, value: -10, to: now) ?? now
            return (start: allTimeStart, end: now)
        }
    }
}