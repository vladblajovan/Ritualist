import Foundation

public final class HabitScheduleManager {
    private var userProfile: UserProfile?
    
    public init(userProfile: UserProfile? = nil) {
        self.userProfile = userProfile
    }
    
    public func updateUserProfile(_ profile: UserProfile?) {
        self.userProfile = profile
    }
    
    /// Check if a date is schedulable for the given habit
    public func isDateSchedulable(_ date: Date, for habit: Habit) -> Bool {
        let calendar = Calendar.current
        let calendarWeekday = calendar.component(.weekday, from: date) // 1=Sun, 2=Mon, ..., 7=Sat
        
        switch habit.schedule {
        case .daily:
            return true
        case .daysOfWeek(let allowedDays):
            // Convert calendar weekday (1=Sun, 2=Mon, ..., 7=Sat) to habit weekday (1=Mon, 2=Tue, ..., 7=Sun)
            let habitWeekday = calendarWeekday == 1 ? 7 : calendarWeekday - 1
            return allowedDays.contains(habitWeekday)
        case .timesPerWeek:
            return true // All days are available for weekly targets
        }
    }
    
    /// For weekly habits, check if the weekly target is met for the week containing this date
    public func isWeeklyTargetMet(for date: Date, habit: Habit, habitLogValues: [Date: Double]) -> Bool {
        switch habit.schedule {
        case .timesPerWeek(let target):
            let weekKey = DateUtils.weekKey(for: date, firstWeekday: userProfile?.firstDayOfWeek ?? Calendar.current.firstWeekday)
            let logsInWeek = habitLogValues.filter { (logDate, value) in
                let logWeekKey = DateUtils.weekKey(for: logDate, firstWeekday: userProfile?.firstDayOfWeek ?? Calendar.current.firstWeekday)
                return logWeekKey.year == weekKey.year && logWeekKey.week == weekKey.week && value > 0
            }
            return logsInWeek.count >= target
        case .daysOfWeek(let requiredDays):
            let weekKey = DateUtils.weekKey(for: date, firstWeekday: userProfile?.firstDayOfWeek ?? Calendar.current.firstWeekday)
            let logsInWeek = habitLogValues.filter { (logDate, value) in
                let logWeekKey = DateUtils.weekKey(for: logDate, firstWeekday: userProfile?.firstDayOfWeek ?? Calendar.current.firstWeekday)
                return logWeekKey.year == weekKey.year && logWeekKey.week == weekKey.week && value > 0
            }
            // Check if all required days for this week are logged
            let loggedDaysInWeek = Set(logsInWeek.keys.map { logDate in
                let calendarWeekday = Calendar.current.component(.weekday, from: logDate)
                return calendarWeekday == 1 ? 7 : calendarWeekday - 1 // Convert to habit weekday format
            })
            return requiredDays.isSubset(of: loggedDaysInWeek)
        default:
            return false
        }
    }
}