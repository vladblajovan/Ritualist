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

    /// The timezone used for all date calculations in this data set.
    /// This should be the user's display timezone from TimezoneService.
    public let timezone: TimeZone

    public init(
        habits: [Habit],
        habitLogs: [UUID: [HabitLog]],
        dateRange: ClosedRange<Date>,
        timezone: TimeZone = .current
    ) {
        self.habits = habits
        self.habitLogs = habitLogs
        self.dateRange = dateRange
        self.timezone = timezone
    }
    
    // MARK: - Helper Methods

    /// Get habits scheduled for a specific date using the display timezone
    /// Only includes habits that have started (date >= habit.startDate) and are scheduled for that day
    public func scheduledHabits(for date: Date) -> [Habit] {
        return habits.filter { $0.isScheduledOn(date: date, timezone: timezone) }
    }
    
    // REMOVED: completionRate(for:) and completionStatus(for:) methods
    // These methods contained duplicate completion logic that competed with HabitCompletionService
    // All completion calculations should now use HabitCompletionService for consistency

    /// Get all logs for a specific date across all habits using the display timezone
    public func logs(for date: Date) -> [HabitLog] {
        return habitLogs.values.flatMap { logs in
            logs.filter { CalendarUtils.areSameDayLocal($0.date, date, timezone: timezone) }
        }
    }

    /// Get logs for a specific habit on a specific date using the display timezone
    public func logs(for habitId: UUID, on date: Date) -> [HabitLog] {
        guard let logs = habitLogs[habitId] else { return [] }

        return logs.filter { CalendarUtils.areSameDayLocal($0.date, date, timezone: timezone) }
    }
    
    // REMOVED: isHabitCompleted(_:on:) method
    // This method used simple log existence logic that ignored numeric habit targets
    // Use HabitCompletionService.isCompleted() instead for proper validation
    
    /// Generate smart insights using unified data and HabitCompletionService
    /// This replaces the separate insight loading in OverviewViewModel
    public func generateSmartInsights(completionService: HabitCompletionService) -> [SmartInsight] {
        var insights: [SmartInsight] = []
        let today = Date()

        // Get the proper week interval using the display timezone
        guard let weekInterval = CalendarUtils.weekIntervalLocal(for: today, timezone: timezone) else {
            return insights
        }
        let startOfWeek = weekInterval.start
        // End date is one day before weekInterval.end (which is start of next week)
        let endOfWeek = CalendarUtils.addDaysLocal(-1, to: weekInterval.end, timezone: timezone)

        // Use unified data instead of separate queries
        guard !habits.isEmpty else {
            return []
        }

        // Use HabitScheduleAnalyzer to correctly calculate expected days per habit
        // This accounts for both habit schedules (daily vs specific days) and start dates
        let scheduleAnalyzer = HabitScheduleAnalyzer()

        // Analyze completion patterns over the past week using unified data
        var totalCompletions = 0
        var totalExpectedCompletions = 0
        var dailyCompletions: [Int] = Array(repeating: 0, count: 7)

        for habit in habits {
            let logs = habitLogs[habit.id] ?? []

            // Calculate expected completions for this habit in the week
            // This respects both the habit's schedule AND start date
            let expectedDays = scheduleAnalyzer.calculateExpectedDays(
                for: habit,
                from: startOfWeek,
                to: endOfWeek,
                timezone: timezone
            )
            totalExpectedCompletions += expectedDays

            // Count actual completions per unique day (not per log)
            // This prevents double-counting when a habit has multiple logs on same day
            var countedDates: Set<Date> = []

            for dayOffset in 0..<7 {
                let checkDate = CalendarUtils.addDaysLocal(dayOffset, to: startOfWeek, timezone: timezone)
                let dateKey = CalendarUtils.startOfDayLocal(for: checkDate, timezone: timezone)

                // Skip if already counted this day
                guard !countedDates.contains(dateKey) else { continue }

                // Only count if habit was expected on this day
                guard scheduleAnalyzer.isHabitExpectedOnDate(habit: habit, date: checkDate, timezone: timezone) else { continue }

                let dayLogs = logs.filter { CalendarUtils.areSameDayLocal($0.date, checkDate, timezone: timezone) }
                if completionService.isCompleted(habit: habit, on: checkDate, logs: dayLogs, timezone: timezone) {
                    totalCompletions += 1
                    dailyCompletions[dayOffset] += 1
                    countedDates.insert(dateKey)
                }
            }
        }

        let completionRate = totalExpectedCompletions > 0 ? Double(totalCompletions) / Double(totalExpectedCompletions) : 0.0
        
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
            let bestDate = CalendarUtils.addDaysLocal(bestDayIndex, to: startOfWeek, timezone: timezone)

            // Get the day name using the proper date and timezone
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            dayFormatter.timeZone = timezone
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
