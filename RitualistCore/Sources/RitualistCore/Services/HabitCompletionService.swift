//
//  HabitCompletionService.swift
//  RitualistCore
//
//  Created by Claude on 16.08.2025.
//

import Foundation

/// Centralized service for handling all habit completion logic with proper semantic handling
/// for different schedule types (daily, daysOfWeek, timesPerWeek)
public protocol HabitCompletionService {
    /// Check if a habit is completed on a specific date based on its schedule semantics
    /// - For daily/daysOfWeek: returns true if logged on that specific day
    /// - For timesPerWeek: returns true if logged on that specific day
    func isCompleted(habit: Habit, on date: Date, logs: [HabitLog]) -> Bool
    
    /// Check if a habit is scheduled to be performed on a specific date
    /// - For daily: always true
    /// - For daysOfWeek: true only on specified weekdays
    /// - For timesPerWeek: always true (user can log anytime during week)
    func isScheduledDay(habit: Habit, date: Date) -> Bool
    
    /// Calculate daily progress for a specific date
    /// - For daily/daysOfWeek: 1.0 if completed that day, 0.0 otherwise
    /// - For timesPerWeek: cumulative weekly progress up to that date
    func calculateDailyProgress(habit: Habit, logs: [HabitLog], for date: Date) -> Double
    
    /// Calculate overall progress percentage for a habit within a date range
    /// Returns value between 0.0 and 1.0
    func calculateProgress(habit: Habit, logs: [HabitLog], from startDate: Date, to endDate: Date) -> Double
    
    /// Get expected number of completions for a habit within a date range
    /// - For daily/daysOfWeek: number of scheduled days
    /// - For timesPerWeek: total weekly targets across all weeks in range
    func getExpectedCompletions(habit: Habit, from startDate: Date, to endDate: Date) -> Int
    
    /// For timesPerWeek habits: get current week progress (unique days logged)
    /// Returns tuple: (completedDays, weeklyTarget) for UI display
    func getWeeklyProgress(habit: Habit, for date: Date, logs: [HabitLog]) -> (completed: Int, target: Int)
}

// MARK: - Implementation

/// Default implementation of HabitCompletionService with proper semantic handling
public final class DefaultHabitCompletionService: HabitCompletionService {
    
    private let calendar: Calendar
    
    public init(calendar: Calendar = Calendar.current) {
        self.calendar = calendar
    }
    
    // MARK: - Public Methods
    
    public func isCompleted(habit: Habit, on date: Date, logs: [HabitLog]) -> Bool {
        switch habit.schedule {
        case .daily, .daysOfWeek:
            // For daily and daysOfWeek habits: check if completed on that specific day
            return isCompletedOnSpecificDay(habit: habit, date: date, logs: logs)
            
        case .timesPerWeek(let weeklyTarget):
            // For timesPerWeek habits: check if weekly target is met
            // This provides accurate completion status based on weekly progress
            let (completed, target) = getWeeklyProgress(habit: habit, for: date, logs: logs)
            return completed >= target
        }
    }
    
    public func calculateProgress(habit: Habit, logs: [HabitLog], from startDate: Date, to endDate: Date) -> Double {
        let habitLogs = filterLogsForHabit(logs, habitId: habit.id, from: startDate, to: endDate)
        
        switch habit.schedule {
        case .daily:
            return calculateDailyScheduleProgress(habit: habit, logs: habitLogs, from: startDate, to: endDate)
            
        case .daysOfWeek(let scheduledDays):
            return calculateDaysOfWeekProgress(habit: habit, scheduledDays: scheduledDays, logs: habitLogs, from: startDate, to: endDate)
            
        case .timesPerWeek(let weeklyTarget):
            return calculateTimesPerWeekProgress(habit: habit, weeklyTarget: weeklyTarget, logs: habitLogs, from: startDate, to: endDate)
        }
    }
    
    public func calculateDailyProgress(habit: Habit, logs: [HabitLog], for date: Date) -> Double {
        switch habit.schedule {
        case .daily, .daysOfWeek:
            // For daily and daysOfWeek: either 0.0 or 1.0 based on completion that day
            return isCompletedOnSpecificDay(habit: habit, date: date, logs: logs) ? 1.0 : 0.0
            
        case .timesPerWeek(let weeklyTarget):
            // For timesPerWeek: show cumulative weekly progress up to this date
            return calculateWeeklyProgressUpToDate(habit: habit, weeklyTarget: weeklyTarget, date: date, logs: logs)
        }
    }
    
    public func isScheduledDay(habit: Habit, date: Date) -> Bool {
        switch habit.schedule {
        case .daily:
            return true
            
        case .daysOfWeek(let scheduledDays):
            let weekday = getHabitWeekday(from: date)
            return scheduledDays.contains(weekday)
            
        case .timesPerWeek:
            // User can log anytime during the week
            return true
        }
    }
    
    public func getExpectedCompletions(habit: Habit, from startDate: Date, to endDate: Date) -> Int {
        let habitStartDate = max(habit.startDate, startDate)
        let habitEndDate = habit.endDate.map { min($0, endDate) } ?? endDate
        
        guard habitStartDate <= habitEndDate else { return 0 }
        
        switch habit.schedule {
        case .daily:
            return calculateDaysBetween(from: habitStartDate, to: habitEndDate)
            
        case .daysOfWeek(let scheduledDays):
            return calculateScheduledDays(scheduledDays: scheduledDays, from: habitStartDate, to: habitEndDate)
            
        case .timesPerWeek(let weeklyTarget):
            return calculateWeeklyTargets(weeklyTarget: weeklyTarget, from: habitStartDate, to: habitEndDate)
        }
    }
    
    public func getWeeklyProgress(habit: Habit, for date: Date, logs: [HabitLog]) -> (completed: Int, target: Int) {
        guard case .timesPerWeek(let weeklyTarget) = habit.schedule else {
            return (0, 0) // Only applicable for timesPerWeek habits
        }
        
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return (0, weeklyTarget)
        }
        
        // Find all completed logs in the current week
        let weekLogs = logs.filter { log in
            log.habitID == habit.id &&
            log.date >= weekInterval.start &&
            log.date < weekInterval.end &&
            isLogCompleted(log: log, habit: habit)
        }
        
        // Count unique days (not total logs) - this is the key fix
        let uniqueDays = Set(weekLogs.map { log in
            calendar.startOfDay(for: log.date)
        })
        
        return (uniqueDays.count, weeklyTarget)
    }
    
    // MARK: - Private Helper Methods
    
    private func isCompletedOnSpecificDay(habit: Habit, date: Date, logs: [HabitLog]) -> Bool {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        
        let dayLogs = logs.filter { log in
            log.habitID == habit.id && log.date >= dayStart && log.date < dayEnd
        }
        
        return dayLogs.contains { log in
            isLogCompleted(log: log, habit: habit)
        }
    }
    
    private func isWeeklyTargetMet(habit: Habit, weeklyTarget: Int, date: Date, logs: [HabitLog]) -> Bool {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else { return false }
        
        let weekLogs = logs.filter { log in
            log.habitID == habit.id && 
            log.date >= weekInterval.start && 
            log.date < weekInterval.end &&
            isLogCompleted(log: log, habit: habit)
        }
        
        return weekLogs.count >= weeklyTarget
    }
    
    private func calculateWeeklyProgressUpToDate(habit: Habit, weeklyTarget: Int, date: Date, logs: [HabitLog]) -> Double {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else { return 0.0 }
        
        let weekLogs = logs.filter { log in
            log.habitID == habit.id && 
            log.date >= weekInterval.start && 
            log.date <= date &&
            isLogCompleted(log: log, habit: habit)
        }
        
        return min(Double(weekLogs.count) / Double(weeklyTarget), 1.0)
    }
    
    private func filterLogsForHabit(_ logs: [HabitLog], habitId: UUID, from startDate: Date, to endDate: Date) -> [HabitLog] {
        return logs.filter { log in
            log.habitID == habitId && log.date >= startDate && log.date <= endDate
        }
    }
    
    private func calculateDailyScheduleProgress(habit: Habit, logs: [HabitLog], from startDate: Date, to endDate: Date) -> Double {
        let expectedDays = calculateDaysBetween(from: startDate, to: endDate)
        guard expectedDays > 0 else { return 0.0 }
        
        var completedDays = 0
        var currentDate = calendar.startOfDay(for: startDate)
        let endOfRange = calendar.startOfDay(for: endDate)
        
        while currentDate <= endOfRange {
            if isCompletedOnSpecificDay(habit: habit, date: currentDate, logs: logs) {
                completedDays += 1
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return Double(completedDays) / Double(expectedDays)
    }
    
    private func calculateDaysOfWeekProgress(habit: Habit, scheduledDays: Set<Int>, logs: [HabitLog], from startDate: Date, to endDate: Date) -> Double {
        let expectedDays = calculateScheduledDays(scheduledDays: scheduledDays, from: startDate, to: endDate)
        guard expectedDays > 0 else { return 0.0 }
        
        var completedDays = 0
        var currentDate = calendar.startOfDay(for: startDate)
        let endOfRange = calendar.startOfDay(for: endDate)
        
        while currentDate <= endOfRange {
            let weekday = getHabitWeekday(from: currentDate)
            if scheduledDays.contains(weekday) && isCompletedOnSpecificDay(habit: habit, date: currentDate, logs: logs) {
                completedDays += 1
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return Double(completedDays) / Double(expectedDays)
    }
    
    private func calculateTimesPerWeekProgress(habit: Habit, weeklyTarget: Int, logs: [HabitLog], from startDate: Date, to endDate: Date) -> Double {
        // Use duration-based week calculation for consistency with calculateWeeklyTargets
        let dayComponents = calendar.dateComponents([.day], from: startDate, to: endDate)
        let totalDays = max(1, (dayComponents.day ?? 0) + 1) // +1 because range is inclusive
        let totalWeeks = max(1, Int(round(Double(totalDays) / 7.0))) // Use rounding to match user expectations
        
        // Filter for only completed logs within the date range
        let completedLogs = logs.filter { log in
            log.date >= startDate && log.date <= endDate && isLogCompleted(log: log, habit: habit)
        }
        
        // Filter for only completed logs within the date range
        
        // Group completed logs by week start date
        let completionsByWeek = Dictionary(grouping: completedLogs) { log in
            calendar.dateInterval(of: .weekOfYear, for: log.date)?.start ?? log.date
        }
        
        var totalActualCompletions = 0
        
        // Calculate week by week using calendar week boundaries
        var currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: startDate)?.start ?? startDate
        let endWeekStart = calendar.dateInterval(of: .weekOfYear, for: endDate)?.start ?? endDate
        
        while currentWeekStart <= endWeekStart {
            // Count unique days (not total logs) - consistent with getWeeklyProgress
            let weekLogs = completionsByWeek[currentWeekStart] ?? []
            let uniqueDaysInWeek = Set(weekLogs.map { log in
                calendar.startOfDay(for: log.date)
            }).count
            
            totalActualCompletions += min(uniqueDaysInWeek, weeklyTarget)
            
            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) else { break }
            currentWeekStart = nextWeek
        }
        
        let totalExpected = totalWeeks * weeklyTarget
        guard totalExpected > 0 else { return 0.0 }
        
        return Double(totalActualCompletions) / Double(totalExpected)
    }
    
    private func isLogCompleted(log: HabitLog, habit: Habit) -> Bool {
        switch habit.kind {
        case .binary:
            // For binary habits: log exists AND value > 0
            return log.value != nil && log.value! > 0
            
        case .numeric:
            guard let logValue = log.value else { return false }
            
            // For numeric habits: must meet daily target if set, otherwise any positive value
            if let target = habit.dailyTarget {
                return logValue >= target
            } else {
                return logValue > 0
            }
        }
    }
    
    private func getHabitWeekday(from date: Date) -> Int {
        let calendarWeekday = calendar.component(.weekday, from: date)
        return DateUtils.calendarWeekdayToHabitWeekday(calendarWeekday)
    }
    
    private func calculateDaysBetween(from startDate: Date, to endDate: Date) -> Int {
        let daysDifference = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        return max(1, daysDifference + 1)
    }
    
    private func calculateScheduledDays(scheduledDays: Set<Int>, from startDate: Date, to endDate: Date) -> Int {
        var count = 0
        var currentDate = calendar.startOfDay(for: startDate)
        let endOfRange = calendar.startOfDay(for: endDate)
        
        while currentDate <= endOfRange {
            let weekday = getHabitWeekday(from: currentDate)
            if scheduledDays.contains(weekday) {
                count += 1
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return count
    }
    
    private func calculateWeeklyTargets(weeklyTarget: Int, from startDate: Date, to endDate: Date) -> Int {
        // Count the number of calendar weeks that overlap with the date range
        var weekCount = 0
        var currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: startDate)?.start ?? startDate
        let endWeekStart = calendar.dateInterval(of: .weekOfYear, for: endDate)?.start ?? endDate
        
        while currentWeekStart <= endWeekStart {
            weekCount += 1
            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) else { break }
            currentWeekStart = nextWeek
        }
        
        return weekCount * weeklyTarget
    }
}