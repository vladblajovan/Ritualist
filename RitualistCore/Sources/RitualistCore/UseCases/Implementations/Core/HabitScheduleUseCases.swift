import Foundation

// MARK: - Habit Schedule Use Case Implementations

public final class ValidateHabitSchedule: ValidateHabitScheduleUseCase {
    private let habitCompletionService: HabitCompletionService
    
    public init(habitCompletionService: HabitCompletionService) {
        self.habitCompletionService = habitCompletionService
    }
    
    public func execute(habit: Habit, date: Date) async throws -> HabitScheduleValidationResult {
        // Use HabitCompletionService to check if the habit is scheduled for this date
        let isScheduled = habitCompletionService.isScheduledDay(habit: habit, date: date)
        
        if isScheduled {
            return .valid()
        } else {
            let reason = generateUserFriendlyReason(for: habit, date: date)
            return .invalid(reason: reason)
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func generateUserFriendlyReason(for habit: Habit, date: Date) -> String {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        let formattedDate = dateFormatter.string(from: date)
        let weekdayName = calendar.weekdaySymbols[calendar.component(.weekday, from: date) - 1]
        
        switch habit.schedule {
        case .daily:
            // This shouldn't happen since daily habits are always valid, but provide a fallback
            return "This habit is not scheduled for \(formattedDate)."
            
        case .daysOfWeek(let scheduledDays):
            let dayNames = scheduledDays.sorted().compactMap { dayNum in
                let calWeekday = DateUtils.habitWeekdayToCalendarWeekday(dayNum)
                return calendar.weekdaySymbols[calWeekday - 1]
            }
            
            if dayNames.count == 1 {
                return "This habit is only scheduled for \(dayNames[0])s."
            } else if dayNames.count == 2 {
                return "This habit is only scheduled for \(dayNames[0])s and \(dayNames[1])s."
            } else {
                let lastDay = dayNames.last!
                let otherDays = dayNames.dropLast().joined(separator: ", ")
                return "This habit is only scheduled for \(otherDays), and \(lastDay)s."
            }
            
        case .timesPerWeek:
            // This shouldn't happen since timesPerWeek habits can be logged any day, but provide a fallback
            return "This habit is not available for logging on \(formattedDate)."
        }
    }
}

public final class CheckWeeklyTarget: CheckWeeklyTargetUseCase {
    public init() {}
    
    public func execute(date: Date, habit: Habit, habitLogValues: [Date: Double], userProfile: UserProfile?) -> Bool {
        switch habit.schedule {
        case .timesPerWeek(let target):
            let weekKey = DateUtils.weekKey(for: date, firstWeekday: Calendar.current.firstWeekday)
            let logsInWeek = habitLogValues.filter { (logDate, value) in
                let logWeekKey = DateUtils.weekKey(for: logDate, firstWeekday: Calendar.current.firstWeekday)
                return logWeekKey.year == weekKey.year && logWeekKey.week == weekKey.week && value > 0
            }
            return logsInWeek.count >= target
        case .daysOfWeek(let requiredDays):
            let weekKey = DateUtils.weekKey(for: date, firstWeekday: Calendar.current.firstWeekday)
            let logsInWeek = habitLogValues.filter { (logDate, value) in
                let logWeekKey = DateUtils.weekKey(for: logDate, firstWeekday: Calendar.current.firstWeekday)
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