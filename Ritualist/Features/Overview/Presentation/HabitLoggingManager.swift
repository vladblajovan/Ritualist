import Foundation

public final class HabitLoggingManager {
    private let getLogForDate: GetLogForDateUseCase
    private let logHabit: LogHabitUseCase
    private let deleteLog: DeleteLogUseCase
    
    public init(getLogForDate: GetLogForDateUseCase, logHabit: LogHabitUseCase, deleteLog: DeleteLogUseCase) {
        self.getLogForDate = getLogForDate
        self.logHabit = logHabit
        self.deleteLog = deleteLog
    }
    
    /// Handle habit logging/unlogging for a specific date
    public func incrementHabitForDate(
        _ date: Date,
        habit: Habit,
        currentLoggedDates: Set<Date>,
        currentHabitLogValues: [Date: Double]
    ) async throws -> (loggedDates: Set<Date>, habitLogValues: [Date: Double]) {
        let existingLog = try await getLogForDate.execute(habitID: habit.id, date: date)
        let normalizedDate = Calendar.current.startOfDay(for: date)
        
        var updatedLoggedDates = currentLoggedDates
        var updatedHabitLogValues = currentHabitLogValues
        
        if habit.kind == .binary {
            // Binary habit: toggle on/off
            if existingLog != nil {
                // Remove log
                try await deleteLog.execute(id: existingLog!.id)
                updatedLoggedDates.remove(normalizedDate)
                updatedHabitLogValues.removeValue(forKey: normalizedDate)
            } else {
                // Add log
                let newLog = HabitLog(habitID: habit.id, date: date, value: 1.0)
                try await logHabit.execute(newLog)
                updatedLoggedDates.insert(normalizedDate)
                updatedHabitLogValues[normalizedDate] = 1.0
            }
        } else {
            // Count habit: increment value or reset if target is reached
            let currentValue = existingLog?.value ?? 0.0
            
            // If target is already reached, reset to 0
            let newValue = if let target = habit.dailyTarget, currentValue >= target {
                0.0
            } else {
                currentValue + 1.0
            }
            
            if newValue == 0.0 {
                // Reset to 0: delete the log entry
                if let existingLog = existingLog {
                    try await deleteLog.execute(id: existingLog.id)
                }
                updatedHabitLogValues.removeValue(forKey: normalizedDate)
                updatedLoggedDates.remove(normalizedDate)
            } else {
                // Increment: update or create log
                if let existingLog = existingLog {
                    // Update existing log
                    let updatedLog = HabitLog(id: existingLog.id, habitID: habit.id, date: date, value: newValue)
                    try await logHabit.execute(updatedLog)
                } else {
                    // Create new log
                    let newLog = HabitLog(habitID: habit.id, date: date, value: newValue)
                    try await logHabit.execute(newLog)
                }
                
                updatedHabitLogValues[normalizedDate] = newValue
                
                // Check if target is reached for logged dates tracking
                if let target = habit.dailyTarget, newValue >= target {
                    updatedLoggedDates.insert(normalizedDate)
                } else {
                    updatedLoggedDates.remove(normalizedDate)
                }
            }
        }
        
        return (loggedDates: updatedLoggedDates, habitLogValues: updatedHabitLogValues)
    }
    
    /// Load logs for a habit for the given dates
    public func loadLogsForHabit(
        _ habit: Habit,
        dates: [Date]
    ) async throws -> (loggedDates: Set<Date>, habitLogValues: [Date: Double]) {
        let calendar = Calendar.current
        var loggedDays: Set<Date> = []
        var logValues: [Date: Double] = [:]
        
        for day in dates {
            let logForDate = try await getLogForDate.execute(habitID: habit.id, date: day)
            let normalizedDay = calendar.startOfDay(for: day)
            
            if let log = logForDate, let value = log.value {
                logValues[normalizedDay] = value
                
                // For count habits, only mark as "logged" if target is reached
                if habit.kind == .binary {
                    loggedDays.insert(normalizedDay)
                } else if let target = habit.dailyTarget, value >= target {
                    loggedDays.insert(normalizedDay)
                }
            } else if logForDate != nil {
                // Handle legacy logs without value (treat as binary)
                logValues[normalizedDay] = 1.0
                loggedDays.insert(normalizedDay)
            }
        }
        
        return (loggedDates: loggedDays, habitLogValues: logValues)
    }
}