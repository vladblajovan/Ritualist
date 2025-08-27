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
    private let calendar: Calendar
    
    public init(
        habitCompletionService: HabitCompletionService,
        calendar: Calendar = Calendar.current
    ) {
        self.habitCompletionService = habitCompletionService
        self.calendar = calendar
    }
    
    // MARK: - Public Methods
    
    public func calculateCurrentStreak(habit: Habit, logs: [HabitLog], asOf date: Date) -> Int {
        switch habit.schedule {
        case .daily:
            return calculateDailyCurrentStreak(habit: habit, logs: logs, asOf: date)
        case .daysOfWeek:
            return calculateDaysOfWeekCurrentStreak(habit: habit, logs: logs, asOf: date)
        case .timesPerWeek:
            return calculateTimesPerWeekCurrentStreak(habit: habit, logs: logs, asOf: date)
        }
    }
    
    public func calculateLongestStreak(habit: Habit, logs: [HabitLog]) -> Int {
        switch habit.schedule {
        case .daily:
            return calculateDailyLongestStreak(habit: habit, logs: logs)
        case .daysOfWeek:
            return calculateDaysOfWeekLongestStreak(habit: habit, logs: logs)
        case .timesPerWeek:
            return calculateTimesPerWeekLongestStreak(habit: habit, logs: logs)
        }
    }
    
    public func getStreakBreakDates(habit: Habit, logs: [HabitLog], asOf date: Date) -> [Date] {
        switch habit.schedule {
        case .timesPerWeek(let weeklyTarget):
            return getTimesPerWeekBreakDates(habit: habit, logs: logs, asOf: date, weeklyTarget: weeklyTarget)
        default:
            return getDailyBreakDates(habit: habit, logs: logs, asOf: date)
        }
    }
    
    private func getDailyBreakDates(habit: Habit, logs: [HabitLog], asOf date: Date) -> [Date] {
        var breakDates: [Date] = []
        var currentDate = calendar.startOfDay(for: date)
        let habitStartDate = calendar.startOfDay(for: habit.startDate)
        
        // Work backwards from the current date
        while currentDate >= habitStartDate {
            if habitCompletionService.isScheduledDay(habit: habit, date: currentDate) {
                let isCompleted = habitCompletionService.isCompleted(habit: habit, on: currentDate, logs: logs)
                if !isCompleted {
                    breakDates.append(currentDate)
                }
            }
            
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDay
        }
        
        return breakDates.reversed() // Return in chronological order
    }
    
    private func getTimesPerWeekBreakDates(habit: Habit, logs: [HabitLog], asOf date: Date, weeklyTarget: Int) -> [Date] {
        var breakDates: [Date] = []
        var weekDate = calendar.startOfDay(for: date)
        let habitStartDate = habit.startDate
        
        // Check each week backwards
        while weekDate >= habitStartDate {
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekDate) else { break }
            
            // Don't count future weeks or weeks before habit start
            if weekInterval.start > date || weekInterval.end < habitStartDate {
                break
            }
            
            let weekLogs = logs.filter { log in
                log.date >= weekInterval.start &&
                log.date < weekInterval.end &&
                isLogCompleted(log: log, habit: habit)
            }
            
            // If weekly target isn't met, add all days in that week as break dates
            if weekLogs.count < weeklyTarget {
                var dayDate = weekInterval.start
                while dayDate < weekInterval.end {
                    if dayDate >= habitStartDate && dayDate <= date {
                        breakDates.append(dayDate)
                    }
                    guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayDate) else { break }
                    dayDate = nextDay
                }
            }
            
            // Move to previous week
            guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: weekDate) else { break }
            weekDate = previousWeek
        }
        
        return breakDates.sorted() // Return in chronological order
    }
    
    public func getNextScheduledDate(habit: Habit, after date: Date) -> Date? {
        // If habit has an end date and we're past it, no future schedule
        if let endDate = habit.endDate, date >= endDate {
            return nil
        }
        
        var searchDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) ?? date
        let searchLimit = calendar.date(byAdding: .year, value: 1, to: date) ?? date // Prevent infinite loops
        
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
            
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: searchDate) else { break }
            searchDate = nextDay
        }
        
        return nil
    }
    
    // MARK: - Daily Schedule Algorithms
    
    private func calculateDailyCurrentStreak(habit: Habit, logs: [HabitLog], asOf date: Date) -> Int {
        var streak = 0
        var currentDate = calendar.startOfDay(for: date)
        let habitStartDate = calendar.startOfDay(for: habit.startDate)
        
        // For daily habits, check every day backwards
        while currentDate >= habitStartDate {
            if habitCompletionService.isCompleted(habit: habit, on: currentDate, logs: logs) {
                streak += 1
            } else {
                break
            }
            
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDay
        }
        
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
        var currentDate = calendar.startOfDay(for: date)
        let habitStartDate = calendar.startOfDay(for: habit.startDate)
        
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
            
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDay
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
    
    // MARK: - TimesPerWeek Schedule Algorithms
    
    private func calculateTimesPerWeekCurrentStreak(habit: Habit, logs: [HabitLog], asOf date: Date) -> Int {
        guard case .timesPerWeek(let weeklyTarget) = habit.schedule else { return 0 }
        
        var streak = 0
        var weekDate = calendar.startOfDay(for: date)
        let habitStartDate = habit.startDate
        
        // Count consecutive weeks that meet the target
        while weekDate >= habitStartDate {
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekDate) else { break }
            
            // Don't count future weeks or weeks before habit start
            if weekInterval.start > date || weekInterval.end < habitStartDate {
                break
            }
            
            let weekLogs = logs.filter { log in
                log.date >= weekInterval.start && 
                log.date < weekInterval.end &&
                isLogCompleted(log: log, habit: habit)
            }
            
            if weekLogs.count >= weeklyTarget {
                streak += 1
            } else {
                break
            }
            
            // Move to previous week
            guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: weekDate) else { break }
            weekDate = previousWeek
        }
        
        return streak
    }
    
    private func calculateTimesPerWeekLongestStreak(habit: Habit, logs: [HabitLog]) -> Int {
        guard case .timesPerWeek(let weeklyTarget) = habit.schedule else { return 0 }
        
        // Group logs by week and check which weeks meet target
        let weeklyCompletions = groupLogsByWeek(logs: logs, habit: habit)
        let sortedWeeks = weeklyCompletions.keys.sorted()
        
        var maxStreak = 0
        var currentStreak = 0
        
        for weekStart in sortedWeeks {
            let completions = weeklyCompletions[weekStart] ?? 0
            
            if completions >= weeklyTarget {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        return maxStreak
    }
    
    // MARK: - Helper Methods
    
    private func getCompliantDates(habit: Habit, logs: [HabitLog]) -> [Date] {
        return logs.compactMap { log in
            guard isLogCompleted(log: log, habit: habit) else { return nil }
            return calendar.startOfDay(for: log.date)
        }
        .sorted()
    }
    
    private func findLongestConsecutiveSequence(in dates: [Date]) -> Int {
        guard !dates.isEmpty else { return 0 }
        
        let uniqueDates = Array(Set(dates)).sorted()
        var maxStreak = 1
        var currentStreak = 1
        
        for i in 1..<uniqueDates.count {
            let daysBetween = calendar.dateComponents([.day], from: uniqueDates[i-1], to: uniqueDates[i]).day ?? 0
            
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
        var checkDate = calendar.startOfDay(for: startDate)
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
            
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: checkDate) else { break }
            checkDate = nextDay
        }
        
        return maxStreak
    }
    
    private func groupLogsByWeek(logs: [HabitLog], habit: Habit) -> [Date: Int] {
        var weeklyCompletions: [Date: Int] = [:]
        
        for log in logs {
            guard isLogCompleted(log: log, habit: habit) else { continue }
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: log.date) else { continue }
            
            let weekStart = weekInterval.start
            weeklyCompletions[weekStart, default: 0] += 1
        }
        
        return weeklyCompletions
    }
    
    private func getHabitWeekday(from date: Date) -> Int {
        let calendarWeekday = calendar.component(.weekday, from: date)
        return DateUtils.calendarWeekdayToHabitWeekday(calendarWeekday)
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