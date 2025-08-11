import Foundation

public extension HabitSchedule {
    func isActiveOn(date: Date) -> Bool {
        let calendar = Calendar.current
        let calendarWeekday = calendar.component(.weekday, from: date)
        let habitWeekday = DateUtils.calendarWeekdayToHabitWeekday(calendarWeekday)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        let weekdayName = calendar.weekdaySymbols[calendarWeekday - 1]
        
        switch self {
        case .daily:
            print("🟢 [SCHEDULE] Daily habit: ACTIVE on \(weekdayName) (\(dateFormatter.string(from: date)))")
            return true
        case .daysOfWeek(let days):
            let isActive = days.contains(habitWeekday)
            let dayNames = days.sorted().map { dayNum in
                let calWeekday = DateUtils.habitWeekdayToCalendarWeekday(dayNum)
                return calendar.weekdaySymbols[calWeekday - 1]
            }
            if isActive {
                print("🟢 [SCHEDULE] DaysOfWeek habit: ACTIVE on \(weekdayName) (\(dateFormatter.string(from: date))) - scheduled for: \(dayNames.joined(separator: ", "))")
            } else {
                print("🔴 [SCHEDULE] DaysOfWeek habit: INACTIVE on \(weekdayName) (\(dateFormatter.string(from: date))) - scheduled for: \(dayNames.joined(separator: ", "))")
            }
            return isActive
        case .timesPerWeek(let times):
            print("🟡 [SCHEDULE] TimesPerWeek habit (\(times)x): ACTIVE on \(weekdayName) (\(dateFormatter.string(from: date))) - can complete any day")
            return true
        }
    }
}