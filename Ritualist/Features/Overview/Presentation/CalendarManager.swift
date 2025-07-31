import Foundation

public struct CalendarDay {
    public let date: Date
    public let isCurrentMonth: Bool
    
    public init(date: Date, isCurrentMonth: Bool) {
        self.date = date
        self.isCurrentMonth = isCurrentMonth
    }
}

public final class CalendarManager {
    private var userProfile: UserProfile?
    
    public init(userProfile: UserProfile? = nil) {
        self.userProfile = userProfile
    }
    
    public func updateUserProfile(_ profile: UserProfile?) {
        self.userProfile = profile
    }
    
    /// Generate days for the given month
    public func generateMonthDays(for month: Date) -> [Date] {
        let calendar = DateUtils.userCalendar(firstDayOfWeek: userProfile?.firstDayOfWeek)
        
        // Ensure we start with a normalized date (start of day)
        let normalizedCurrentMonth = calendar.startOfDay(for: month)
        guard let monthInterval = calendar.dateInterval(of: .month, for: normalizedCurrentMonth) else { return [] }
        
        // Generate current month days, ensuring we work with start of day
        var days: [Date] = []
        var date = calendar.startOfDay(for: monthInterval.start)
        let endOfMonth = monthInterval.end
        
        while date < endOfMonth {
            days.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return days
    }
    
    /// Generate full calendar grid with adjacent month days (42 days total)
    public func generateFullCalendarGrid(for month: Date) -> [CalendarDay] {
        let calendar = DateUtils.userCalendar(firstDayOfWeek: userProfile?.firstDayOfWeek)
        
        let normalizedCurrentMonth = calendar.startOfDay(for: month)
        guard let monthInterval = calendar.dateInterval(of: .month, for: normalizedCurrentMonth) else { return [] }
        
        var calendarDays: [CalendarDay] = []
        
        // Create a proper date for the first of the month using date components
        let monthComponents = calendar.dateComponents([.year, .month], from: monthInterval.start)
        guard let firstOfMonth = calendar.date(from: DateComponents(year: monthComponents.year, month: monthComponents.month, day: 1)) else {
            return []
        }
        
        // Get the weekday of the first day of the month (1 = Sunday, 2 = Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let userFirstWeekday = userProfile?.firstDayOfWeek ?? calendar.firstWeekday
        
        // Calculate how many days we need to go back to reach the start of the week
        var daysBack = firstWeekday - userFirstWeekday
        if daysBack < 0 {
            daysBack += 7
        }
        
        // Find the first date to show in our calendar grid
        guard let calendarStartDate = calendar.date(byAdding: .day, value: -daysBack, to: firstOfMonth) else {
            return []
        }
        
        // Generate 42 days (6 weeks × 7 days) starting from the calendar start date
        var currentDate = calendarStartDate
        for _ in 0..<42 {
            // Check if this date is in the same month as firstOfMonth
            let isCurrentMonth = calendar.isDate(currentDate, equalTo: firstOfMonth, toGranularity: .month)
            
            calendarDays.append(CalendarDay(date: currentDate, isCurrentMonth: isCurrentMonth))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return calendarDays
    }
    
    /// Check if currently viewing the current month
    public func isViewingCurrentMonth(_ month: Date) -> Bool {
        let calendar = Calendar.current
        let today = Date()
        let currentMonthStart = calendar.dateInterval(of: .month, for: month)?.start ?? month
        let todayMonthStart = calendar.dateInterval(of: .month, for: today)?.start ?? today
        
        return calendar.isDate(currentMonthStart, equalTo: todayMonthStart, toGranularity: .month)
    }
}