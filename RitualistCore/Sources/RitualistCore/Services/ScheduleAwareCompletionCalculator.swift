//
//  ScheduleAwareCompletionCalculator.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import Foundation

/// Service responsible for calculating accurate completion rates based on habit schedules and types
public protocol ScheduleAwareCompletionCalculator {
    /// Calculate completion rate for a specific habit within a date range
    func calculateCompletionRate(
        for habit: Habit,
        logs: [HabitLog],
        startDate: Date,
        endDate: Date
    ) -> Double
    
    /// Check if a habit was completed on a specific date
    func isHabitCompleted(habit: Habit, logs: [HabitLog], date: Date) -> Bool
    
    /// Calculate total expected days for a habit within a date range
    func calculateExpectedDays(
        for habit: Habit,
        startDate: Date,
        endDate: Date
    ) -> Int
    
    /// Calculate completion stats for multiple habits
    func calculateCompletionStats(
        for habits: [Habit],
        logs: [HabitLog],
        startDate: Date,
        endDate: Date
    ) -> HabitCompletionStats
}

public final class DefaultScheduleAwareCompletionCalculator: ScheduleAwareCompletionCalculator {
    
    private let habitCompletionService: HabitCompletionService
    
    public init(habitCompletionService: HabitCompletionService = DefaultHabitCompletionService()) {
        self.habitCompletionService = habitCompletionService
    }
    
    public func calculateCompletionRate(
        for habit: Habit,
        logs: [HabitLog],
        startDate: Date,
        endDate: Date
    ) -> Double {
        let habitLogs = logs.filter { $0.habitID == habit.id }
        
        let completionRate: Double
        switch habit.schedule {
        case .daily:
            completionRate = calculateDailyCompletionRate(habit: habit, logs: habitLogs, startDate: startDate, endDate: endDate)
        case .daysOfWeek(let days):
            completionRate = calculateDaysOfWeekCompletionRate(habit: habit, logs: habitLogs, scheduledDays: days, startDate: startDate, endDate: endDate)
        }
        
        return completionRate
    }
    
    public func isHabitCompleted(habit: Habit, logs: [HabitLog], date: Date) -> Bool {
        return habitCompletionService.isCompleted(habit: habit, on: date, logs: logs)
    }
    
    public func calculateExpectedDays(
        for habit: Habit,
        startDate: Date,
        endDate: Date
    ) -> Int {
        let habitStartDate = max(habit.startDate, startDate)
        let habitEndDate = habit.endDate.map { min($0, endDate) } ?? endDate
        
        guard habitStartDate <= habitEndDate else { return 0 }
        
        switch habit.schedule {
        case .daily:
            let daysDifference = CalendarUtils.daysBetweenUTC(
                habitStartDate,
                habitEndDate
            )
            // Fix: If start and end are on the same day, count it as 1 day
            return max(1, daysDifference + 1)
            
        case .daysOfWeek(let days):
            return calculateExpectedDaysForSchedule(scheduledDays: days, startDate: habitStartDate, endDate: habitEndDate)
        }
    }
    
    public func calculateCompletionStats(
        for habits: [Habit],
        logs: [HabitLog],
        startDate: Date,
        endDate: Date
    ) -> HabitCompletionStats {
        let activeHabits = habits.filter { $0.isActive }
        var totalExpectedEntries = 0
        var totalCompletedEntries = 0
        var habitsWithGoodCompletion = 0
        
        for habit in activeHabits {
            let completionRate = calculateCompletionRate(for: habit, logs: logs, startDate: startDate, endDate: endDate)
            let expectedDays = calculateExpectedDays(for: habit, startDate: startDate, endDate: endDate)
            let completedDays = Int(ceil(completionRate * Double(expectedDays)))
            
            totalExpectedEntries += expectedDays
            totalCompletedEntries += completedDays
            
            // Consider a habit "completed" if it has >50% completion rate
            if completionRate > 0.5 {
                habitsWithGoodCompletion += 1
            }
        }
        
        let overallCompletionRate = totalExpectedEntries > 0 ? 
            Double(totalCompletedEntries) / Double(totalExpectedEntries) : 0.0
        
        return HabitCompletionStats(
            totalHabits: activeHabits.count,
            completedHabits: habitsWithGoodCompletion,
            completionRate: overallCompletionRate
        )
    }
    
    // MARK: - Private Methods
    
    /// Standardized completion check for habit logs
    private func isLogCompleted(log: HabitLog, habit: Habit) -> Bool {
        switch habit.kind {
        case .binary:
            // For binary habits: log exists AND value > 0 (standardized logic)
            return log.value != nil && log.value! > 0
            
        case .numeric:
            guard let logValue = log.value else { return false }
            
            // For numeric habits: must meet daily target if set, otherwise any positive value
            if let target = habit.dailyTarget {
                return logValue >= target
            } else {
                // Require positive value for numeric habits without explicit targets
                return logValue > 0
            }
        }
    }
    
    private func calculateDailyCompletionRate(
        habit: Habit,
        logs: [HabitLog],
        startDate: Date,
        endDate: Date
    ) -> Double {
        let expectedDays = calculateExpectedDays(for: habit, startDate: startDate, endDate: endDate)
        guard expectedDays > 0 else { return 0.0 }
        
        var completedDays = 0
        var currentDate = CalendarUtils.startOfDayUTC(for: max(habit.startDate, startDate))
        let endOfRange = CalendarUtils.startOfDayUTC(for: min(habit.endDate ?? endDate, endDate))
        
        while currentDate <= endOfRange {
            if isHabitCompleted(habit: habit, logs: logs, date: currentDate) {
                completedDays += 1
            }
            currentDate = CalendarUtils.addDays(1, to: currentDate)
        }
        
        return Double(completedDays) / Double(expectedDays)
    }
    
    private func calculateDaysOfWeekCompletionRate(
        habit: Habit,
        logs: [HabitLog],
        scheduledDays: Set<Int>,
        startDate: Date,
        endDate: Date
    ) -> Double {
        let expectedDays = calculateExpectedDaysForSchedule(
            scheduledDays: scheduledDays,
            startDate: max(habit.startDate, startDate),
            endDate: min(habit.endDate ?? endDate, endDate)
        )
        guard expectedDays > 0 else { return 0.0 }
        
        var completedDays = 0
        var currentDate = CalendarUtils.startOfDayUTC(for: max(habit.startDate, startDate))
        let endOfRange = CalendarUtils.startOfDayUTC(for: min(habit.endDate ?? endDate, endDate))
        
        while currentDate <= endOfRange {
            let weekday = CalendarUtils.weekdayComponentUTC(from: currentDate)
            let habitWeekday = CalendarUtils.calendarWeekdayToHabitWeekday(weekday)
            
            if scheduledDays.contains(habitWeekday) {
                if isHabitCompleted(habit: habit, logs: logs, date: currentDate) {
                    completedDays += 1
                }
            }
            
            currentDate = CalendarUtils.addDays(1, to: currentDate)
        }
        
        return Double(completedDays) / Double(expectedDays)
    }
    
    
    private func calculateExpectedDaysForSchedule(
        scheduledDays: Set<Int>,
        startDate: Date,
        endDate: Date
    ) -> Int {
        var expectedDays = 0
        var currentDate = CalendarUtils.startOfDayUTC(for: startDate)
        let endOfRange = CalendarUtils.startOfDayUTC(for: endDate)
        
        while currentDate <= endOfRange {
            let weekday = CalendarUtils.weekdayComponentUTC(from: currentDate)
            let habitWeekday = CalendarUtils.calendarWeekdayToHabitWeekday(weekday)
            
            if scheduledDays.contains(habitWeekday) {
                expectedDays += 1
            }
            
            currentDate = CalendarUtils.addDays(1, to: currentDate)
        }
        
        return expectedDays
    }
    
}
