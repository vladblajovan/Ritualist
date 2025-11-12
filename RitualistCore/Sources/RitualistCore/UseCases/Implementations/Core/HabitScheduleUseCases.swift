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
        let calendar = CalendarUtils.currentLocalCalendar
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
                let calWeekday = CalendarUtils.habitWeekdayToCalendarWeekday(dayNum)
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
            
        }
    }
}

public final class CheckWeeklyTarget: CheckWeeklyTargetUseCase {
    public init() {}
    
    public func execute(date: Date, habit: Habit, habitLogValues: [Date: Double], userProfile: UserProfile?) -> Bool {
        switch habit.schedule {
        case .daysOfWeek(let requiredDays):
            let weekKey = CalendarUtils.weekNumberLocal(for: date)
            let logsInWeek = habitLogValues.filter { (logDate, value) in
                let logWeekKey = CalendarUtils.weekNumberLocal(for: logDate)
                return logWeekKey.year == weekKey.year && logWeekKey.week == weekKey.week && value > 0
            }
            // Check if all required days for this week are logged
            let loggedDaysInWeek = Set(logsInWeek.keys.map { logDate in
                let calendarWeekday = CalendarUtils.weekdayComponentLocal(from: logDate)
                return CalendarUtils.calendarWeekdayToHabitWeekday(calendarWeekday)
            })
            return requiredDays.isSubset(of: loggedDaysInWeek)
        default:
            return false
        }
    }
}