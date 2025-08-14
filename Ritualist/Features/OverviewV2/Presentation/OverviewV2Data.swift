import Foundation
import RitualistCore

/// Single source of truth data structure for OverviewV2
/// Replaces multiple independent data loading methods to ensure consistency
public struct OverviewData {
    public let habits: [Habit]
    public let habitLogs: [UUID: [HabitLog]]  // Cached logs by habitId
    public let dateRange: ClosedRange<Date>   // Date range we have data for
    
    // MARK: - Helper Methods
    
    /// Get habits scheduled for a specific date
    public func scheduledHabits(for date: Date) -> [Habit] {
        habits.filter { $0.schedule.isActiveOn(date: date) }
    }
    
    /// Get completion rate for a specific date (0.0 to 1.0)
    /// Uses consistent schedule filtering and completion logic
    public func completionRate(for date: Date) -> Double {
        let scheduled = scheduledHabits(for: date)
        guard !scheduled.isEmpty else { return 0.0 }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        var completed = 0
        for habit in scheduled {
            if let logs = habitLogs[habit.id],
               logs.contains(where: { calendar.isDate($0.date, inSameDayAs: startOfDay) }) {
                completed += 1
            }
        }
        
        return Double(completed) / Double(scheduled.count)
    }
    
    /// Get completion status (completed/total) for a specific date
    public func completionStatus(for date: Date) -> (completed: Int, total: Int) {
        let scheduled = scheduledHabits(for: date)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        var completed = 0
        for habit in scheduled {
            if let logs = habitLogs[habit.id],
               logs.contains(where: { calendar.isDate($0.date, inSameDayAs: startOfDay) }) {
                completed += 1
            }
        }
        
        return (completed: completed, total: scheduled.count)
    }
    
    /// Get all logs for a specific date across all habits
    public func logs(for date: Date) -> [HabitLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        return habitLogs.values.flatMap { logs in
            logs.filter { calendar.isDate($0.date, inSameDayAs: startOfDay) }
        }
    }
    
    /// Get logs for a specific habit on a specific date
    public func logs(for habitId: UUID, on date: Date) -> [HabitLog] {
        guard let logs = habitLogs[habitId] else { return [] }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        return logs.filter { calendar.isDate($0.date, inSameDayAs: startOfDay) }
    }
    
    /// Check if a habit is completed on a specific date
    public func isHabitCompleted(_ habitId: UUID, on date: Date) -> Bool {
        return !logs(for: habitId, on: date).isEmpty
    }
}
