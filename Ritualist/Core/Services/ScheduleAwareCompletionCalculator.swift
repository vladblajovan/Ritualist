//
//  ScheduleAwareCompletionCalculator.swift
//  Ritualist
//
//  Created by Claude on 08.08.2025.
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
    
    private let calendar = Calendar.current
    
    public init() {}
    
    public func calculateCompletionRate(
        for habit: Habit,
        logs: [HabitLog],
        startDate: Date,
        endDate: Date
    ) -> Double {
        let habitLogs = logs.filter { $0.habitID == habit.id }
        
        print("🔍 [ScheduleCalculator] Calculating completion for habit: '\(habit.name)'")
        print("   📅 Schedule: \(habit.schedule)")
        print("   🎯 Kind: \(habit.kind)")
        print("   🎯 Daily Target: \(habit.dailyTarget?.description ?? "nil")")
        print("   📊 Total logs found: \(habitLogs.count)")
        print("   📅 Date range: \(startDate) to \(endDate)")
        
        let completionRate: Double
        switch habit.schedule {
        case .daily:
            completionRate = calculateDailyCompletionRate(habit: habit, logs: habitLogs, startDate: startDate, endDate: endDate)
        case .daysOfWeek(let days):
            print("   🗓️ Scheduled days: \(days)")
            completionRate = calculateDaysOfWeekCompletionRate(habit: habit, logs: habitLogs, scheduledDays: days, startDate: startDate, endDate: endDate)
        case .timesPerWeek(let count):
            print("   📊 Weekly target: \(count) times")
            completionRate = calculateTimesPerWeekCompletionRate(habit: habit, logs: habitLogs, weeklyTarget: count, startDate: startDate, endDate: endDate)
        }
        
        print("   ✅ Final completion rate: \(String(format: "%.2f", completionRate * 100))%")
        print("")
        
        return completionRate
    }
    
    public func isHabitCompleted(habit: Habit, logs: [HabitLog], date: Date) -> Bool {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        
        let dayLogs = logs.filter { log in
            log.habitID == habit.id && log.date >= dayStart && log.date < dayEnd
        }
        
        return dayLogs.contains { log in
            isLogCompleted(log: log, habit: habit)
        }
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
            return calendar.dateComponents([.day], from: habitStartDate, to: habitEndDate).day ?? 0
            
        case .daysOfWeek(let days):
            return calculateExpectedDaysForSchedule(scheduledDays: days, startDate: habitStartDate, endDate: habitEndDate)
            
        case .timesPerWeek(let count):
            let totalWeeks = calendar.dateComponents([.weekOfYear], from: habitStartDate, to: habitEndDate).weekOfYear ?? 0
            let remainingDays = calendar.dateComponents([.day], from: habitStartDate, to: habitEndDate).day ?? 0
            
            // For partial weeks, calculate proportionally
            if totalWeeks == 0 {
                let weeklyRatio = Double(remainingDays) / 7.0
                return Int(ceil(Double(count) * weeklyRatio))
            } else {
                return totalWeeks * count
            }
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
        var currentDate = calendar.startOfDay(for: max(habit.startDate, startDate))
        let endOfRange = calendar.startOfDay(for: min(habit.endDate ?? endDate, endDate))
        
        while currentDate <= endOfRange {
            if isHabitCompleted(habit: habit, logs: logs, date: currentDate) {
                completedDays += 1
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
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
        var currentDate = calendar.startOfDay(for: max(habit.startDate, startDate))
        let endOfRange = calendar.startOfDay(for: min(habit.endDate ?? endDate, endDate))
        
        while currentDate <= endOfRange {
            let weekday = calendar.component(.weekday, from: currentDate)
            let habitWeekday = weekday == 1 ? 7 : weekday - 1 // Convert Sunday=1 to Sunday=7
            
            if scheduledDays.contains(habitWeekday) {
                if isHabitCompleted(habit: habit, logs: logs, date: currentDate) {
                    completedDays += 1
                }
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return Double(completedDays) / Double(expectedDays)
    }
    
    private func calculateTimesPerWeekCompletionRate(
        habit: Habit,
        logs: [HabitLog],
        weeklyTarget: Int,
        startDate: Date,
        endDate: Date
    ) -> Double {
        let habitStartDate = max(habit.startDate, startDate)
        let habitEndDate = min(habit.endDate ?? endDate, endDate)
        
        print("      🗓️ [TimesPerWeek] Habit active period: \(habitStartDate) to \(habitEndDate)")
        
        guard habitStartDate <= habitEndDate else { 
            print("      ❌ [TimesPerWeek] Invalid date range!")
            return 0.0 
        }
        
        // Group completed days by week
        let completedDates = logs.compactMap { log -> Date? in
            guard log.habitID == habit.id && isLogCompleted(log: log, habit: habit) else { return nil }
            let logDate = calendar.startOfDay(for: log.date)
            guard logDate >= habitStartDate && logDate <= habitEndDate else { return nil }
            return logDate
        }
        
        print("      📊 [TimesPerWeek] Completed dates: \(completedDates.count) total")
        
        let completionsByWeek = Dictionary(grouping: completedDates) { date in
            calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        }
        
        print("      📈 [TimesPerWeek] Completions by week: \(completionsByWeek.count) weeks")
        
        // Calculate weekly completion rates
        var totalWeeklyTargets = 0
        var totalWeeklyCompletions = 0
        var currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: habitStartDate)?.start ?? habitStartDate
        let endWeekStart = calendar.dateInterval(of: .weekOfYear, for: habitEndDate)?.start ?? habitEndDate
        
        var weekIndex = 0
        while currentWeekStart <= endWeekStart {
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) ?? currentWeekStart
            
            // Calculate target for this week (proportional if partial week)
            let weekOverlap = calculateWeekOverlap(
                weekStart: currentWeekStart,
                weekEnd: weekEnd,
                habitStart: habitStartDate,
                habitEnd: habitEndDate
            )
            
            let weekTarget = Int(ceil(Double(weeklyTarget) * weekOverlap))
            let weekCompletions = min(completionsByWeek[currentWeekStart]?.count ?? 0, weekTarget)
            
            print("      📊 Week \(weekIndex + 1): Target=\(weekTarget), Completions=\(weekCompletions), Overlap=\(String(format: "%.2f", weekOverlap))")
            
            totalWeeklyTargets += weekTarget
            totalWeeklyCompletions += weekCompletions
            
            currentWeekStart = weekEnd
            weekIndex += 1
        }
        
        let finalRate = totalWeeklyTargets > 0 ? Double(totalWeeklyCompletions) / Double(totalWeeklyTargets) : 0.0
        print("      🎯 [TimesPerWeek] Final: \(totalWeeklyCompletions)/\(totalWeeklyTargets) = \(String(format: "%.2f", finalRate * 100))%")
        
        return finalRate
    }
    
    private func calculateExpectedDaysForSchedule(
        scheduledDays: Set<Int>,
        startDate: Date,
        endDate: Date
    ) -> Int {
        var expectedDays = 0
        var currentDate = calendar.startOfDay(for: startDate)
        let endOfRange = calendar.startOfDay(for: endDate)
        
        while currentDate <= endOfRange {
            let weekday = calendar.component(.weekday, from: currentDate)
            let habitWeekday = weekday == 1 ? 7 : weekday - 1 // Convert Sunday=1 to Sunday=7
            
            if scheduledDays.contains(habitWeekday) {
                expectedDays += 1
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return expectedDays
    }
    
    private func calculateWeekOverlap(
        weekStart: Date,
        weekEnd: Date,
        habitStart: Date,
        habitEnd: Date
    ) -> Double {
        let overlapStart = max(weekStart, habitStart)
        let overlapEnd = min(weekEnd, habitEnd)
        
        guard overlapStart < overlapEnd else { return 0.0 }
        
        let overlapDays = calendar.dateComponents([.day], from: overlapStart, to: overlapEnd).day ?? 0
        return Double(overlapDays) / 7.0
    }
}