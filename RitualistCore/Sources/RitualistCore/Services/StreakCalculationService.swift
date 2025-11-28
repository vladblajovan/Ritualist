//
//  StreakCalculationService.swift
//  RitualistCore
//
//  Created by Claude on 16.08.2025.
//

import Foundation

/// Service responsible for calculating habit streaks with proper schedule awareness.
/// Each schedule type has its own semantic meaning for what constitutes a streak.
///
/// ## Timezone Support
/// All methods accept a `timezone` parameter for timezone-aware streak calculations.
/// For timezone-aware calculations, use the display timezone from `TimezoneService`.
public protocol StreakCalculationService {
    /// Calculate the current active streak for a habit as of a specific date
    /// - Parameters:
    ///   - habit: The habit to calculate streak for
    ///   - logs: All logs for the habit (should be pre-filtered by habitID)
    ///   - date: The date to calculate streak as of (typically today)
    ///   - timezone: Timezone for date calculations
    /// - Returns: Current streak count respecting schedule semantics
    func calculateCurrentStreak(habit: Habit, logs: [HabitLog], asOf date: Date, timezone: TimeZone) -> Int

    /// Calculate the longest streak ever achieved for a habit
    /// - Parameters:
    ///   - habit: The habit to calculate streak for
    ///   - logs: All logs for the habit (should be pre-filtered by habitID)
    ///   - timezone: Timezone for date calculations
    /// - Returns: Longest streak count respecting schedule semantics
    func calculateLongestStreak(habit: Habit, logs: [HabitLog], timezone: TimeZone) -> Int

    /// Get dates where the streak was broken (missed scheduled days)
    /// - Parameters:
    ///   - habit: The habit to analyze
    ///   - logs: All logs for the habit
    ///   - date: The end date to analyze up to
    ///   - timezone: Timezone for date calculations
    /// - Returns: Array of dates where streaks were broken
    func getStreakBreakDates(habit: Habit, logs: [HabitLog], asOf date: Date, timezone: TimeZone) -> [Date]

    /// Get the next scheduled date for a habit after a given date
    /// - Parameters:
    ///   - habit: The habit to check schedule for
    ///   - date: The date to find next scheduled date after
    ///   - timezone: Timezone for date calculations
    /// - Returns: Next scheduled date, or nil if habit has no future schedule
    func getNextScheduledDate(habit: Habit, after date: Date, timezone: TimeZone) -> Date?
}

// MARK: - Backward Compatibility Extensions

extension StreakCalculationService {
    /// Backward compatible version using current timezone
    public func calculateCurrentStreak(habit: Habit, logs: [HabitLog], asOf date: Date) -> Int {
        return calculateCurrentStreak(habit: habit, logs: logs, asOf: date, timezone: .current)
    }

    /// Backward compatible version using current timezone
    public func calculateLongestStreak(habit: Habit, logs: [HabitLog]) -> Int {
        return calculateLongestStreak(habit: habit, logs: logs, timezone: .current)
    }

    /// Backward compatible version using current timezone
    public func getStreakBreakDates(habit: Habit, logs: [HabitLog], asOf date: Date) -> [Date] {
        return getStreakBreakDates(habit: habit, logs: logs, asOf: date, timezone: .current)
    }

    /// Backward compatible version using current timezone
    public func getNextScheduledDate(habit: Habit, after date: Date) -> Date? {
        return getNextScheduledDate(habit: habit, after: date, timezone: .current)
    }
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

    public func calculateCurrentStreak(habit: Habit, logs: [HabitLog], asOf date: Date, timezone: TimeZone) -> Int {
        switch habit.schedule {
        case .daily:
            return calculateDailyCurrentStreak(habit: habit, logs: logs, asOf: date, timezone: timezone)
        case .daysOfWeek:
            return calculateDaysOfWeekCurrentStreak(habit: habit, logs: logs, asOf: date, timezone: timezone)
        }
    }

    public func calculateLongestStreak(habit: Habit, logs: [HabitLog], timezone: TimeZone) -> Int {
        switch habit.schedule {
        case .daily:
            return calculateDailyLongestStreak(habit: habit, logs: logs, timezone: timezone)
        case .daysOfWeek:
            return calculateDaysOfWeekLongestStreak(habit: habit, logs: logs, timezone: timezone)
        }
    }

    public func getStreakBreakDates(habit: Habit, logs: [HabitLog], asOf date: Date, timezone: TimeZone) -> [Date] {
        return getDailyBreakDates(habit: habit, logs: logs, asOf: date, timezone: timezone)
    }
    
    private func getDailyBreakDates(habit: Habit, logs: [HabitLog], asOf date: Date, timezone: TimeZone) -> [Date] {
        var breakDates: [Date] = []
        var currentDate = CalendarUtils.startOfDayLocal(for: date, timezone: timezone)
        let habitStartDate = CalendarUtils.startOfDayLocal(for: habit.startDate, timezone: timezone)

        // Work backwards from the current date
        while currentDate >= habitStartDate {
            if habitCompletionService.isScheduledDay(habit: habit, date: currentDate, timezone: timezone) {
                let isCompleted = habitCompletionService.isCompleted(habit: habit, on: currentDate, logs: logs, timezone: timezone)
                if !isCompleted {
                    breakDates.append(currentDate)
                }
            }

            currentDate = CalendarUtils.addDaysLocal(-1, to: currentDate, timezone: timezone)
            // currentDate already updated above
        }

        return breakDates.reversed() // Return in chronological order
    }
    
    
    public func getNextScheduledDate(habit: Habit, after date: Date, timezone: TimeZone) -> Date? {
        // If habit has an end date and we're past it, no future schedule
        if let endDate = habit.endDate, date >= endDate {
            return nil
        }

        var searchDate = CalendarUtils.addDaysLocal(1, to: CalendarUtils.startOfDayLocal(for: date, timezone: timezone), timezone: timezone)
        let searchLimit = CalendarUtils.addYearsLocal(1, to: date, timezone: timezone) // Prevent infinite loops

        while searchDate <= searchLimit {
            if habitCompletionService.isScheduledDay(habit: habit, date: searchDate, timezone: timezone) {
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

            searchDate = CalendarUtils.addDaysLocal(1, to: searchDate, timezone: timezone)
        }

        return nil
    }
    
    // MARK: - Daily Schedule Algorithms

    private func calculateDailyCurrentStreak(habit: Habit, logs: [HabitLog], asOf date: Date, timezone: TimeZone) -> Int {
        var streak = 0
        var currentDate = CalendarUtils.startOfDayLocal(for: date, timezone: timezone)
        let habitStartDate = CalendarUtils.startOfDayLocal(for: habit.startDate, timezone: timezone)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = timezone

        // Also log in UTC for comparison
        let utcFormatter = DateFormatter()
        utcFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        utcFormatter.timeZone = TimeZone(identifier: "UTC")

        logger.log(
            "🔥 Starting streak calculation",
            level: .debug,
            category: .dataIntegrity,
            metadata: [
                "habit": habit.name,
                "asOf_local": dateFormatter.string(from: date),
                "startOfDay_local": dateFormatter.string(from: currentDate),
                "habit_startDate_RAW_UTC": utcFormatter.string(from: habit.startDate),
                "habit_startDate_RAW_local": dateFormatter.string(from: habit.startDate),
                "habitStartDate_calculated": dateFormatter.string(from: habitStartDate),
                "timezone": timezone.identifier,
                "logsCount": logs.count
            ]
        )

        // For daily habits, check every day backwards
        while currentDate >= habitStartDate {
            let isCompleted = habitCompletionService.isCompleted(habit: habit, on: currentDate, logs: logs, timezone: timezone)

            logger.log(
                "🔥 Checking day",
                level: .debug,
                category: .dataIntegrity,
                metadata: [
                    "habit": habit.name,
                    "date": dateFormatter.string(from: currentDate),
                    "isCompleted": isCompleted,
                    "currentStreak": streak
                ]
            )

            if isCompleted {
                streak += 1
            } else {
                logger.log(
                    "🔥 Streak broken - day not completed",
                    level: .debug,
                    category: .dataIntegrity,
                    metadata: [
                        "habit": habit.name,
                        "brokenAt": dateFormatter.string(from: currentDate),
                        "finalStreak": streak
                    ]
                )
                break
            }

            currentDate = CalendarUtils.addDaysLocal(-1, to: currentDate, timezone: timezone)
        }

        logger.log(
            "🔥 Streak calculation complete",
            level: .debug,
            category: .dataIntegrity,
            metadata: ["habit": habit.name, "streak": streak]
        )

        return streak
    }
    
    private func calculateDailyLongestStreak(habit: Habit, logs: [HabitLog], timezone: TimeZone) -> Int {
        // Get all compliant dates and find longest consecutive sequence
        let compliantDates = getCompliantDates(habit: habit, logs: logs, timezone: timezone)
        return findLongestConsecutiveSequence(in: compliantDates, timezone: timezone)
    }
    
    // MARK: - DaysOfWeek Schedule Algorithms

    private func calculateDaysOfWeekCurrentStreak(habit: Habit, logs: [HabitLog], asOf date: Date, timezone: TimeZone) -> Int {
        var streak = 0
        var currentDate = CalendarUtils.startOfDayLocal(for: date, timezone: timezone)
        let habitStartDate = CalendarUtils.startOfDayLocal(for: habit.startDate, timezone: timezone)

        // For daysOfWeek habits, only count scheduled days
        while currentDate >= habitStartDate {
            if habitCompletionService.isScheduledDay(habit: habit, date: currentDate, timezone: timezone) {
                if habitCompletionService.isCompleted(habit: habit, on: currentDate, logs: logs, timezone: timezone) {
                    streak += 1
                } else {
                    break // Missed a scheduled day, streak broken
                }
            }
            // Skip non-scheduled days - they don't affect the streak

            currentDate = CalendarUtils.addDaysLocal(-1, to: currentDate, timezone: timezone)
            // currentDate already updated above
        }

        return streak
    }

    private func calculateDaysOfWeekLongestStreak(habit: Habit, logs: [HabitLog], timezone: TimeZone) -> Int {
        guard case .daysOfWeek(let scheduledDays) = habit.schedule else { return 0 }

        // Get all compliant dates that fall on scheduled days
        let compliantDates = getCompliantDates(habit: habit, logs: logs, timezone: timezone)
        let scheduledCompliantDates = compliantDates.filter { date in
            let weekday = CalendarUtils.habitWeekday(from: date, timezone: timezone)
            return scheduledDays.contains(weekday)
        }

        // Find longest sequence considering only scheduled days
        return findLongestScheduledSequence(
            in: scheduledCompliantDates,
            scheduledDays: scheduledDays,
            startDate: habit.startDate,
            timezone: timezone
        )
    }
    
    
    // MARK: - Helper Methods

    private func getCompliantDates(habit: Habit, logs: [HabitLog], timezone: TimeZone) -> [Date] {
        return logs.compactMap { log in
            guard HabitLogCompletionValidator.isLogCompleted(log: log, habit: habit) else { return nil }
            // Use the log's own timezone to determine which calendar day it represents
            let logTimezone: TimeZone
            if let tz = TimeZone(identifier: log.timezone) {
                logTimezone = tz
            } else {
                // Invalid timezone identifier - log for monitoring and fall back to query timezone
                logger.log(
                    "Invalid timezone identifier for log, using fallback",
                    level: .warning,
                    category: .dataIntegrity,
                    metadata: [
                        "log_timezone": log.timezone,
                        "log_id": log.id.uuidString,
                        "fallback_timezone": timezone.identifier
                    ]
                )
                logTimezone = timezone
            }
            return CalendarUtils.startOfDayLocal(for: log.date, timezone: logTimezone)
        }
        .sorted()
    }
    
    private func findLongestConsecutiveSequence(in dates: [Date], timezone: TimeZone) -> Int {
        guard !dates.isEmpty else { return 0 }

        let uniqueDates = Array(Set(dates)).sorted()
        var maxStreak = 1
        var currentStreak = 1

        for i in 1..<uniqueDates.count {
            let daysBetween = CalendarUtils.daysBetweenLocal(uniqueDates[i-1], uniqueDates[i], timezone: timezone)

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
        startDate: Date,
        timezone: TimeZone
    ) -> Int {
        guard !compliantDates.isEmpty else { return 0 }

        // Convert to Set for O(1) lookup instead of O(n) array contains
        let uniqueDatesSet = Set(compliantDates)
        let sortedDates = uniqueDatesSet.sorted()
        var maxStreak = 0
        var currentStreak = 0

        // Start from habit start date and check each scheduled day
        var checkDate = CalendarUtils.startOfDayLocal(for: startDate, timezone: timezone)
        let endDate = sortedDates.last ?? startDate

        while checkDate <= endDate {
            let weekday = CalendarUtils.habitWeekday(from: checkDate, timezone: timezone)

            if scheduledDays.contains(weekday) {
                // O(1) lookup in Set vs O(n) in Array (prevents O(n²) performance)
                if uniqueDatesSet.contains(checkDate) {
                    currentStreak += 1
                    maxStreak = max(maxStreak, currentStreak)
                } else {
                    currentStreak = 0
                }
            }

            checkDate = CalendarUtils.addDaysLocal(1, to: checkDate, timezone: timezone)
        }

        return maxStreak
    }
    
    private func groupLogsByWeek(logs: [HabitLog], habit: Habit, timezone: TimeZone) -> [Date: Int] {
        var weeklyCompletions: [Date: Int] = [:]

        for log in logs {
            guard HabitLogCompletionValidator.isLogCompleted(log: log, habit: habit) else { continue }
            guard let weekInterval = CalendarUtils.weekIntervalLocal(for: log.date, timezone: timezone) else { continue }

            let weekStart = weekInterval.start
            weeklyCompletions[weekStart, default: 0] += 1
        }

        return weeklyCompletions
    }
}
