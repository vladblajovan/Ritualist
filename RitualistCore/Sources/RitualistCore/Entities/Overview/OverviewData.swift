//
//  OverviewData.swift
//  RitualistCore
//
//  Migrated from Features/OverviewV2/Presentation on 15.08.2025.
//

import Foundation

/// Single source of truth data structure for OverviewV2
/// Replaces multiple independent data loading methods to ensure consistency
public struct OverviewData {
    public let habits: [Habit]
    public let habitLogs: [UUID: [HabitLog]]  // Cached logs by habitId
    public let dateRange: ClosedRange<Date>   // Date range we have data for
    
    public init(habits: [Habit], habitLogs: [UUID: [HabitLog]], dateRange: ClosedRange<Date>) {
        self.habits = habits
        self.habitLogs = habitLogs
        self.dateRange = dateRange
    }
    
    // MARK: - Helper Methods
    
    /// Get habits scheduled for a specific date
    public func scheduledHabits(for date: Date) -> [Habit] {
        habits.filter { $0.schedule.isActiveOn(date: date) }
    }
    
    // REMOVED: completionRate(for:) and completionStatus(for:) methods
    // These methods contained duplicate completion logic that competed with HabitCompletionService
    // All completion calculations should now use HabitCompletionService for consistency
    
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
    
    // REMOVED: isHabitCompleted(_:on:) method
    // This method used simple log existence logic that ignored numeric habit targets
    // Use HabitCompletionService.isCompleted() instead for proper validation
    
    /// Generate smart insights using unified data and HabitCompletionService
    /// This replaces the separate insight loading in OverviewViewModel
    public func generateSmartInsights(completionService: HabitCompletionService) -> [SmartInsight] {
        var insights: [SmartInsight] = []
        let calendar = Calendar.current
        let today = Date()
        
        // Get the proper week interval that respects user's first day of week preference
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return insights
        }
        let startOfWeek = weekInterval.start
        
        // Use unified data instead of separate queries
        guard !habits.isEmpty else {
            return []
        }
        
        // Analyze completion patterns over the past week using unified data
        var totalCompletions = 0
        var dailyCompletions: [Int] = Array(repeating: 0, count: 7)
        
        for habit in habits {
            let logs = habitLogs[habit.id] ?? []
            let recentLogs = logs.filter { log in
                log.date >= startOfWeek && log.date < weekInterval.end
            }
            
            // Count actual completions using HabitCompletionService for single source of truth
            for log in recentLogs {
                let dayLogs = logs.filter { calendar.isDate($0.date, inSameDayAs: log.date) }
                if completionService.isCompleted(habit: habit, on: log.date, logs: dayLogs) {
                    totalCompletions += 1
                    
                    // Count completions per day
                    let daysSinceStart = calendar.dateComponents([.day], from: startOfWeek, to: log.date).day ?? 0
                    if daysSinceStart >= 0 && daysSinceStart < 7 {
                        dailyCompletions[daysSinceStart] += 1
                    }
                }
            }
        }
        
        let totalPossibleCompletions = habits.count * 7
        let completionRate = totalPossibleCompletions > 0 ? Double(totalCompletions) / Double(totalPossibleCompletions) : 0.0
        
        // Generate insights based on actual patterns
        if completionRate >= 0.8 {
            insights.append(SmartInsight(
                title: "Excellent Consistency",
                message: "You're completing \(Int(completionRate * 100))% of your habits this week!",
                type: .celebration
            ))
        } else if completionRate >= 0.6 {
            insights.append(SmartInsight(
                title: "Good Progress",
                message: "You're on track with \(Int(completionRate * 100))% completion. Keep building momentum!",
                type: .pattern
            ))
        } else if completionRate >= 0.3 {
            insights.append(SmartInsight(
                title: "Room for Growth",
                message: "Focus on consistency - even small daily wins add up to big results.",
                type: .suggestion
            ))
        } else {
            insights.append(SmartInsight(
                title: "Fresh Start",
                message: "Every day is a new opportunity. Start with just one habit today.",
                type: .suggestion
            ))
        }
        
        // Find best performing day
        if let bestDayIndex = dailyCompletions.enumerated().max(by: { $0.element < $1.element })?.offset {
            // Get the actual date for the best performing day
            guard let bestDate = calendar.date(byAdding: .day, value: bestDayIndex, to: startOfWeek) else {
                return insights
            }
            
            // Get the day name using the proper date
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            let bestDayName = dayFormatter.string(from: bestDate)
            
            if dailyCompletions[bestDayIndex] > 0 {
                insights.append(SmartInsight(
                    title: "\(bestDayName) Strength",
                    message: "You completed \(dailyCompletions[bestDayIndex]) habits on \(bestDayName) - your strongest day!",
                    type: .pattern
                ))
            }
        }
        
        // Add motivational insight if they have multiple habits
        if habits.count >= 3 {
            insights.append(SmartInsight(
                title: "Multi-Habit Builder",
                message: "Tracking \(habits.count) habits shows commitment to growth. Focus on consistency over perfection.",
                type: .suggestion
            ))
        }
        
        return insights
    }
}