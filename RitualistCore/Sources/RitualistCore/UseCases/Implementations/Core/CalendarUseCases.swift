import Foundation

// MARK: - Calendar Use Case Implementations

public final class GenerateCalendarDays: GenerateCalendarDaysUseCase {
    public init() {}
    
    public func execute(for month: Date, userProfile: UserProfile?) -> [Date] {
        // Ensure we start with a normalized date (start of day)
        let normalizedCurrentMonth = CalendarUtils.startOfDayUTC(for: month)
        guard let monthInterval = CalendarUtils.monthInterval(for: normalizedCurrentMonth) else { return [] }
        
        // Generate current month days, ensuring we work with start of day
        var days: [Date] = []
        var date = CalendarUtils.startOfDayUTC(for: monthInterval.start)
        let endOfMonth = monthInterval.end
        
        while date < endOfMonth {
            days.append(date)
            date = CalendarUtils.addDays(1, to: date)
        }
        
        return days
    }
}

public final class GenerateCalendarGrid: GenerateCalendarGridUseCase {
    public init() {}
    
    public func execute(for month: Date, userProfile: UserProfile?) -> [CalendarDay] {
        let normalizedCurrentMonth = CalendarUtils.startOfDayUTC(for: month)
        guard let monthInterval = CalendarUtils.monthInterval(for: normalizedCurrentMonth) else { return [] }
        
        let startOfMonth = monthInterval.start
        let endOfMonth = monthInterval.end
        
        // Find the first day to display (might be from previous month)
        let weekdayOfFirst = CalendarUtils.weekdayComponent(from: startOfMonth)
        // Calculate days to subtract based on calendar's firstWeekday setting
        let firstWeekday = CalendarUtils.firstWeekday()
        let daysToSubtract = (weekdayOfFirst - firstWeekday + 7) % 7
        let firstDisplayDay = CalendarUtils.addDays(-daysToSubtract, to: startOfMonth)
        
        // Generate 42 days (6 weeks) for a complete calendar grid
        var calendarDays: [CalendarDay] = []
        var currentDate = firstDisplayDay
        
        for _ in 0..<42 {
            let isCurrentMonth = CalendarUtils.isSameMonth(currentDate, normalizedCurrentMonth)
            calendarDays.append(CalendarDay(date: currentDate, isCurrentMonth: isCurrentMonth))
            currentDate = CalendarUtils.addDays(1, to: currentDate)
        }
        
        return calendarDays
    }
}