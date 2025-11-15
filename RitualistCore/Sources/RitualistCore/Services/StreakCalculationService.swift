//
//  StreakCalculationService.swift
//  RitualistCore
//
//  Created by Claude on 16.08.2025.
//

import Foundation

/// Service responsible for calculating habit streaks with proper schedule awareness.
/// Each schedule type has its own semantic meaning for what constitutes a streak.
public protocol StreakCalculationService {
    /// Calculate the current active streak for a habit as of a specific date
    /// - Parameters:
    ///   - habit: The habit to calculate streak for
    ///   - logs: All logs for the habit (should be pre-filtered by habitID)
    ///   - date: The date to calculate streak as of (typically today)
    /// - Returns: Current streak count respecting schedule semantics
    func calculateCurrentStreak(habit: Habit, logs: [HabitLog], asOf date: Date) -> Int
    
    /// Calculate the longest streak ever achieved for a habit
    /// - Parameters:
    ///   - habit: The habit to calculate streak for
    ///   - logs: All logs for the habit (should be pre-filtered by habitID)
    /// - Returns: Longest streak count respecting schedule semantics
    func calculateLongestStreak(habit: Habit, logs: [HabitLog]) -> Int
    
    /// Get dates where the streak was broken (missed scheduled days)
    /// - Parameters:
    ///   - habit: The habit to analyze
    ///   - logs: All logs for the habit
    ///   - date: The end date to analyze up to
    /// - Returns: Array of dates where streaks were broken
    func getStreakBreakDates(habit: Habit, logs: [HabitLog], asOf date: Date) -> [Date]
    
    /// Get the next scheduled date for a habit after a given date
    /// - Parameters:
    ///   - habit: The habit to check schedule for
    ///   - date: The date to find next scheduled date after
    /// - Returns: Next scheduled date, or nil if habit has no future schedule
    func getNextScheduledDate(habit: Habit, after date: Date) -> Date?
}

/// Default implementation of StreakCalculationService with schedule-aware algorithms
public final class DefaultStreakCalculationService: StreakCalculationService {

    private let habitCompletionService: HabitCompletionService
    private let logger: DebugLogger

    public init(
        habitCompletionService: HabitCompletionService,
        logger: DebugLogger
    ) {
        self.habitCompletionService = habitCompletionService
        self.logger = logger
        // Using CalendarUtils for LOCAL timezone business logic consistency
    }
    
    // MARK: - Public Methods
    
    public func calculateCurrentStreak(habit: Habit, logs: [HabitLog], asOf date: Date) -> Int {
        switch habit.schedule {
        case .daily:
            return calculateDailyCurrentStreak(habit: habit, logs: logs, asOf: date)
        case .daysOfWeek:
            return calculateDaysOfWeekCurrentStreak(habit: habit, logs: logs, asOf: date)
        }
    }
    
    public func calculateLongestStreak(habit: Habit, logs: [HabitLog]) -> Int {
        switch habit.schedule {
        case .daily:
            return calculateDailyLongestStreak(habit: habit, logs: logs)
        case .daysOfWeek:
            return calculateDaysOfWeekLongestStreak(habit: habit, logs: logs)
        }
    }
    
    public func getStreakBreakDates(habit: Habit, logs: [HabitLog], asOf date: Date) -> [Date] {
        return getDailyBreakDates(habit: habit, logs: logs, asOf: date)
    }
    
    private func getDailyBreakDates(habit: Habit, logs: [HabitLog], asOf date: Date) -> [Date] {
        var breakDates: [Date] = []
        var currentDate = CalendarUtils.startOfDayLocal(for: date)
        let habitStartDate = CalendarUtils.startOfDayLocal(for: habit.startDate)
        
        // Work backwards from the current date
        while currentDate >= habitStartDate {
            if habitCompletionService.isScheduledDay(habit: habit, date: currentDate) {
                let isCompleted = habitCompletionService.isCompleted(habit: habit, on: currentDate, logs: logs)
                if !isCompleted {
                    breakDates.append(currentDate)
                }
            }
            
            currentDate = CalendarUtils.addDays(-1, to: currentDate)
            // currentDate already updated above
        }
        
        return breakDates.reversed() // Return in chronological order
    }
    
    
    public func getNextScheduledDate(habit: Habit, after date: Date) -> Date? {
        // If habit has an end date and we're past it, no future schedule
        if let endDate = habit.endDate, date >= endDate {
            return nil
        }
        
        var searchDate = CalendarUtils.addDays(1, to: CalendarUtils.startOfDayLocal(for: date))
        let searchLimit = CalendarUtils.addYears(1, to: date) // Prevent infinite loops
        
        while searchDate <= searchLimit {
            if habitCompletionService.isScheduledDay(habit: habit, date: searchDate) {
                // Check if this date is within habit's active period
                if searchDate >= habit.startDate {
                    if let endDate = habit.endDate {
                        if searchDate <= endDate {
                            return searchDate
                        }
                    } else {
                        return searchDate
                    }
                }
            }
            
            searchDate = CalendarUtils.addDays(1, to: searchDate)
        }
        
        return nil
    }
    
    // MARK: - Daily Schedule Algorithms
    
    private func calculateDailyCurrentStreak(habit: Habit, logs: [HabitLog], asOf date: Date) -> Int {
        var streak = 0
        var currentDate = CalendarUtils.startOfDayLocal(for: date)
        let habitStartDate = CalendarUtils.startOfDayLocal(for: habit.startDate)

        logger.log(
            "🔥 Calculating daily streak",
            level: .debug,
            category: .dataIntegrity,
            metadata: [
                "habit": habit.name,
                "startDate": currentDate.ISO8601Format(),
                "logsCount": logs.count
            ]
        )

        // For daily habits, check every day backwards
        while currentDate >= habitStartDate {
            let isCompleted = habitCompletionService.isCompleted(habit: habit, on: currentDate, logs: logs)

            if isCompleted {
                streak += 1
            } else {
                logger.log(
                    "⛔ Streak broken",
                    level: .debug,
                    category: .dataIntegrity,
                    metadata: [
                        "habit": habit.name,
                        "brokenAt": currentDate.ISO8601Format(),
                        "streak": streak
                    ]
                )
                break
            }

            currentDate = CalendarUtils.addDays(-1, to: currentDate)
            // currentDate already updated above
        }

        logger.log(
            "🎯 Streak calculation complete",
            level: .debug,
            category: .dataIntegrity,
            metadata: ["habit": habit.name, "finalStreak": streak]
        )
        return streak
    }
    
    private func calculateDailyLongestStreak(habit: Habit, logs: [HabitLog]) -> Int {
        // Get all compliant dates and find longest consecutive sequence
        let compliantDates = getCompliantDates(habit: habit, logs: logs)
        return findLongestConsecutiveSequence(in: compliantDates)
    }
    
    // MARK: - DaysOfWeek Schedule Algorithms
    
    private func calculateDaysOfWeekCurrentStreak(habit: Habit, logs: [HabitLog], asOf date: Date) -> Int {
        var streak = 0
        var currentDate = CalendarUtils.startOfDayLocal(for: date)
        let habitStartDate = CalendarUtils.startOfDayLocal(for: habit.startDate)
        
        // For daysOfWeek habits, only count scheduled days
        while currentDate >= habitStartDate {
            if habitCompletionService.isScheduledDay(habit: habit, date: currentDate) {
                if habitCompletionService.isCompleted(habit: habit, on: currentDate, logs: logs) {
                    streak += 1
                } else {
                    break // Missed a scheduled day, streak broken
                }
            }
            // Skip non-scheduled days - they don't affect the streak
            
            currentDate = CalendarUtils.addDays(-1, to: currentDate)
            // currentDate already updated above
        }
        
        return streak
    }
    
    private func calculateDaysOfWeekLongestStreak(habit: Habit, logs: [HabitLog]) -> Int {
        guard case .daysOfWeek(let scheduledDays) = habit.schedule else { return 0 }
        
        // Get all compliant dates that fall on scheduled days
        let compliantDates = getCompliantDates(habit: habit, logs: logs)
        let scheduledCompliantDates = compliantDates.filter { date in
            let weekday = getHabitWeekday(from: date)
            return scheduledDays.contains(weekday)
        }
        
        // Find longest sequence considering only scheduled days
        return findLongestScheduledSequence(
            in: scheduledCompliantDates,
            scheduledDays: scheduledDays,
            startDate: habit.startDate
        )
    }
    
    
    // MARK: - Helper Methods
    
    private func getCompliantDates(habit: Habit, logs: [HabitLog]) -> [Date] {
        return logs.compactMap { log in
            guard isLogCompleted(log: log, habit: habit) else { return nil }
            return CalendarUtils.startOfDayLocal(for: log.date)
        }
        .sorted()
    }
    
    private func findLongestConsecutiveSequence(in dates: [Date]) -> Int {
        guard !dates.isEmpty else { return 0 }
        
        let uniqueDates = Array(Set(dates)).sorted()
        var maxStreak = 1
        var currentStreak = 1
        
        for i in 1..<uniqueDates.count {
            let daysBetween = CalendarUtils.daysBetweenLocal(uniqueDates[i-1], uniqueDates[i])
            
            if daysBetween == 1 {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        
        return maxStreak
    }
    
    private func findLongestScheduledSequence(
        in compliantDates: [Date],
        scheduledDays: Set<Int>,
        startDate: Date
    ) -> Int {
        guard !compliantDates.isEmpty else { return 0 }
        
        let uniqueDates = Array(Set(compliantDates)).sorted()
        var maxStreak = 0
        var currentStreak = 0
        
        // Start from habit start date and check each scheduled day
        var checkDate = CalendarUtils.startOfDayLocal(for: startDate)
        let endDate = uniqueDates.last ?? startDate
        
        while checkDate <= endDate {
            let weekday = getHabitWeekday(from: checkDate)
            
            if scheduledDays.contains(weekday) {
                if uniqueDates.contains(checkDate) {
                    currentStreak += 1
                    maxStreak = max(maxStreak, currentStreak)
                } else {
                    currentStreak = 0
                }
            }
            
            checkDate = CalendarUtils.addDays(1, to: checkDate)
        }
        
        return maxStreak
    }
    
    private func groupLogsByWeek(logs: [HabitLog], habit: Habit) -> [Date: Int] {
        var weeklyCompletions: [Date: Int] = [:]
        
        for log in logs {
            guard isLogCompleted(log: log, habit: habit) else { continue }
            guard let weekInterval = CalendarUtils.weekIntervalLocal(for: log.date) else { continue }
            
            let weekStart = weekInterval.start
            weeklyCompletions[weekStart, default: 0] += 1
        }
        
        return weeklyCompletions
    }
    
    private func getHabitWeekday(from date: Date) -> Int {
        let calendarWeekday = CalendarUtils.weekdayComponentLocal(from: date)
        return CalendarUtils.calendarWeekdayToHabitWeekday(calendarWeekday)
    }
    
    /// Check if a single log meets the completion criteria for its habit
    private func isLogCompleted(log: HabitLog, habit: Habit) -> Bool {
        switch habit.kind {
        case .binary:
            return log.value != nil && log.value! > 0
        case .numeric:
            guard let logValue = log.value else { return false }
            if let target = habit.dailyTarget {
                return logValue >= target
            } else {
                return logValue > 0
            }
        }
    }
}
