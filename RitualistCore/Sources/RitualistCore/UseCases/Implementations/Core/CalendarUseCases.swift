import Foundation

// MARK: - Calendar Use Case Implementations

public final class GenerateCalendarDays: GenerateCalendarDaysUseCase {
    public init() {}
    
    public func execute(for month: Date, userProfile: UserProfile?) -> [Date] {
        let calendar = DateUtils.userCalendar()
        
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
}

public final class GenerateCalendarGrid: GenerateCalendarGridUseCase {
    public init() {}
    
    public func execute(for month: Date, userProfile: UserProfile?) -> [CalendarDay] {
        let calendar = DateUtils.userCalendar()
        
        let normalizedCurrentMonth = calendar.startOfDay(for: month)
        guard let monthInterval = calendar.dateInterval(of: .month, for: normalizedCurrentMonth) else { return [] }
        
        let startOfMonth = monthInterval.start
        let endOfMonth = monthInterval.end
        
        // Find the first day to display (might be from previous month)
        let weekdayOfFirst = calendar.component(.weekday, from: startOfMonth)
        // Calculate days to subtract based on calendar's firstWeekday setting
        let daysToSubtract = (weekdayOfFirst - calendar.firstWeekday + 7) % 7
        let firstDisplayDay = calendar.date(byAdding: .day, value: -daysToSubtract, to: startOfMonth) ?? startOfMonth
        
        // Generate 42 days (6 weeks) for a complete calendar grid
        var calendarDays: [CalendarDay] = []
        var currentDate = firstDisplayDay
        
        for _ in 0..<42 {
            let isCurrentMonth = calendar.isDate(currentDate, equalTo: normalizedCurrentMonth, toGranularity: .month)
            calendarDays.append(CalendarDay(date: currentDate, isCurrentMonth: isCurrentMonth))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return calendarDays
    }
}