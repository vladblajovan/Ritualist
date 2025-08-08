import Foundation

// MARK: - Streak Calculation Use Cases

public protocol CalculateCurrentStreakUseCase {
    func execute(habit: Habit, logs: [HabitLog], asOf: Date) -> Int
}

public protocol CalculateBestStreakUseCase {
    func execute(habit: Habit, logs: [HabitLog]) -> Int
}

// MARK: - Streak Use Case Implementations

public final class CalculateCurrentStreak: CalculateCurrentStreakUseCase {
    public init() {}
    
    public func execute(habit: Habit, logs: [HabitLog], asOf: Date) -> Int {
        switch habit.schedule {
        case .timesPerWeek(let target):
            return calculateWeeklyStreak(for: habit, logs: logs, target: target, asOf: asOf)
        case .daily, .daysOfWeek:
            return calculateDailyStreak(for: habit, logs: logs, asOf: asOf)
        }
    }
    
    private func calculateWeeklyStreak(for habit: Habit, logs: [HabitLog], target: Int, asOf: Date) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var date = DateUtils.startOfDay(asOf)
        
        while true {
            let weekKey = DateUtils.weekKey(for: date, firstWeekday: calendar.firstWeekday)
            let logsThisWeek = logs.filter { log in
                let logWeekKey = DateUtils.weekKey(for: log.date, firstWeekday: calendar.firstWeekday)
                return logWeekKey.year == weekKey.year && logWeekKey.week == weekKey.week
                    && isLogCompliant(log, for: habit)
            }
            
            if logsThisWeek.count >= target {
                streak += 1
            } else {
                break
            }
            
            guard let prevWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: date) else { break }
            date = prevWeek
        }
        
        return streak
    }
    
    private func calculateDailyStreak(for habit: Habit, logs: [HabitLog], asOf: Date) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var date = DateUtils.startOfDay(asOf)
        
        while true {
            if isDateScheduled(date, for: habit) {
                let hasCompliantLog = logs.contains { log in
                    DateUtils.isSameDay(log.date, date) && isLogCompliant(log, for: habit)
                }
                
                if hasCompliantLog {
                    streak += 1
                } else {
                    break
                }
            }
            
            guard let prev = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        
        return streak
    }
    
    private func isDateScheduled(_ date: Date, for habit: Habit) -> Bool {
        let calendar = Calendar.current
        let calendarWeekday = calendar.component(.weekday, from: date)
        
        switch habit.schedule {
        case .daily:
            return true
        case .daysOfWeek(let days):
            let habitWeekday = DateUtils.calendarWeekdayToHabitWeekday(calendarWeekday)
            return days.contains(habitWeekday)
        case .timesPerWeek:
            return true
        }
    }
    
    private func isLogCompliant(_ log: HabitLog, for habit: Habit) -> Bool {
        switch habit.kind {
        case .binary:
            return (log.value ?? 0) >= 1
        case .numeric:
            return (log.value ?? 0) >= (habit.dailyTarget ?? 0)
        }
    }
}

public final class CalculateBestStreak: CalculateBestStreakUseCase {
    public init() {}
    
    public func execute(habit: Habit, logs: [HabitLog]) -> Int {
        // Filter logs to unique, compliant dates
        let compliantDates = Set(logs.compactMap { log in
            let valueOK: Bool
            switch habit.kind {
            case .binary:
                valueOK = (log.value ?? 0) >= 1
            case .numeric:
                valueOK = (log.value ?? 0) >= (habit.dailyTarget ?? 0)
            }
            return valueOK ? DateUtils.startOfDay(log.date) : nil
        })
        
        // Sort ascending
        let sortedDates = compliantDates.sorted()
        var best = 0
        var current = 0
        var prevDate: Date?
        
        for date in sortedDates {
            if let prev = prevDate,
               DateUtils.daysBetween(prev, date) == 1 {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
            prevDate = date
        }
        
        return best
    }
}