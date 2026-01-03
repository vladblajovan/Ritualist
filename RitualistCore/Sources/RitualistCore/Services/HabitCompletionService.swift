//
//  HabitCompletionService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import Foundation

/// Centralized service for handling all habit completion logic with proper semantic handling
/// for different schedule types (daily, daysOfWeek)
///
/// ## Timezone Support
/// All methods accept an optional `timezone` parameter (defaults to `.current`).
/// For timezone-aware calculations, use the display timezone from `TimezoneService`.
public protocol HabitCompletionService: Sendable {
    /// Check if a habit is completed on a specific date based on its schedule semantics
    /// - For daily/daysOfWeek: returns true if logged on that specific day
    /// - Parameter timezone: Timezone for date calculations (defaults to current)
    func isCompleted(habit: Habit, on date: Date, logs: [HabitLog], timezone: TimeZone) -> Bool

    /// Check if a habit is scheduled to be performed on a specific date
    /// - For daily: always true
    /// - For daysOfWeek: true only on specified weekdays
    /// - Parameter timezone: Timezone for date calculations (defaults to current)
    func isScheduledDay(habit: Habit, date: Date, timezone: TimeZone) -> Bool

    /// Calculate daily progress for a specific date
    /// - For daily/daysOfWeek: 1.0 if completed that day, 0.0 otherwise
    /// - Parameter timezone: Timezone for date calculations (defaults to current)
    func calculateDailyProgress(habit: Habit, logs: [HabitLog], for date: Date, timezone: TimeZone) -> Double

    /// Calculate overall progress percentage for a habit within a date range
    /// Returns value between 0.0 and 1.0
    /// - Parameter timezone: Timezone for date calculations (defaults to current)
    func calculateProgress(habit: Habit, logs: [HabitLog], from startDate: Date, to endDate: Date, timezone: TimeZone) -> Double

    /// Get expected number of completions for a habit within a date range
    /// - For daily/daysOfWeek: number of scheduled days
    /// - Parameter timezone: Timezone for date calculations (defaults to current)
    func getExpectedCompletions(habit: Habit, from startDate: Date, to endDate: Date, timezone: TimeZone) -> Int
}

// MARK: - Backward Compatibility Extensions

extension HabitCompletionService {
    /// Backward compatible version using current timezone
    public func isCompleted(habit: Habit, on date: Date, logs: [HabitLog]) -> Bool {
        return isCompleted(habit: habit, on: date, logs: logs, timezone: .current)
    }

    /// Backward compatible version using current timezone
    public func isScheduledDay(habit: Habit, date: Date) -> Bool {
        return isScheduledDay(habit: habit, date: date, timezone: .current)
    }

    /// Backward compatible version using current timezone
    public func calculateDailyProgress(habit: Habit, logs: [HabitLog], for date: Date) -> Double {
        return calculateDailyProgress(habit: habit, logs: logs, for: date, timezone: .current)
    }

    /// Backward compatible version using current timezone
    public func calculateProgress(habit: Habit, logs: [HabitLog], from startDate: Date, to endDate: Date) -> Double {
        return calculateProgress(habit: habit, logs: logs, from: startDate, to: endDate, timezone: .current)
    }

    /// Backward compatible version using current timezone
    public func getExpectedCompletions(habit: Habit, from startDate: Date, to endDate: Date) -> Int {
        return getExpectedCompletions(habit: habit, from: startDate, to: endDate, timezone: .current)
    }
}

// MARK: - Implementation

/// Default implementation of HabitCompletionService with proper semantic handling
/// Uses CalendarUtils for all date operations to ensure LOCAL timezone business logic
public final class DefaultHabitCompletionService: HabitCompletionService {

    public init() {}

    // MARK: - Public Methods

    public func isCompleted(habit: Habit, on date: Date, logs: [HabitLog], timezone: TimeZone) -> Bool {
        switch habit.schedule {
        case .daily, .daysOfWeek:
            // For daily and daysOfWeek habits: check if completed on that specific day
            return isCompletedOnSpecificDay(habit: habit, date: date, logs: logs, timezone: timezone)
        }
    }

    public func calculateProgress(habit: Habit, logs: [HabitLog], from startDate: Date, to endDate: Date, timezone: TimeZone) -> Double {
        let habitLogs = filterLogsForHabit(logs, habitId: habit.id, from: startDate, to: endDate)

        switch habit.schedule {
        case .daily:
            return calculateDailyScheduleProgress(habit: habit, logs: habitLogs, from: startDate, to: endDate, timezone: timezone)

        case .daysOfWeek(let scheduledDays):
            return calculateDaysOfWeekProgress(habit: habit, scheduledDays: scheduledDays, logs: habitLogs, from: startDate, to: endDate, timezone: timezone)
        }
    }

    public func calculateDailyProgress(habit: Habit, logs: [HabitLog], for date: Date, timezone: TimeZone) -> Double {
        switch habit.schedule {
        case .daily, .daysOfWeek:
            // For daily and daysOfWeek: either 0.0 or 1.0 based on completion that day
            return isCompletedOnSpecificDay(habit: habit, date: date, logs: logs, timezone: timezone) ? 1.0 : 0.0
        }
    }

    public func isScheduledDay(habit: Habit, date: Date, timezone: TimeZone) -> Bool {
        // First check if date is before habit's start date - habit isn't scheduled before it starts
        let dateStart = CalendarUtils.startOfDayLocal(for: date, timezone: timezone)
        let habitStartDay = CalendarUtils.startOfDayLocal(for: habit.startDate, timezone: timezone)
        guard dateStart >= habitStartDay else { return false }

        switch habit.schedule {
        case .daily:
            return true

        case .daysOfWeek(let scheduledDays):
            let weekday = CalendarUtils.habitWeekday(from: date, timezone: timezone)
            return scheduledDays.contains(weekday)
        }
    }

    public func getExpectedCompletions(habit: Habit, from startDate: Date, to endDate: Date, timezone: TimeZone) -> Int {
        let habitStartDate = max(habit.startDate, startDate)
        let habitEndDate = habit.endDate.map { min($0, endDate) } ?? endDate

        guard habitStartDate <= habitEndDate else { return 0 }

        switch habit.schedule {
        case .daily:
            return calculateDaysBetween(from: habitStartDate, to: habitEndDate, timezone: timezone)

        case .daysOfWeek(let scheduledDays):
            return calculateScheduledDays(scheduledDays: scheduledDays, from: habitStartDate, to: habitEndDate, timezone: timezone)
        }
    }
    
    
    // MARK: - Private Helper Methods

    private func isCompletedOnSpecificDay(habit: Habit, date: Date, logs: [HabitLog], timezone: TimeZone) -> Bool {
        // Check if any log for this habit was created on the specified calendar day
        //
        // IMPORTANT: The log's `date` field is stored as "start of day in DISPLAY timezone at creation time".
        // The log's `timezone` field stores the DISPLAY timezone that was used to calculate the date,
        // which tells us which calendar day the log represents.
        //
        // When comparing, we use areSameDayAcrossTimezones to check if:
        // - The log's calendar day (in its stored timezone) matches
        // - The query's calendar day (in the query timezone)
        //
        // This ensures a log created for "Dec 11 in Melbourne" will ALWAYS represent Dec 11,
        // regardless of what timezone you're viewing from. The log is "sticky" to its original day.

        let dayLogs = logs.filter { log in
            guard log.habitID == habit.id else { return false }

            let logTimezone = log.resolvedTimezone(fallback: timezone)

            // Compare calendar days across timezones:
            // - Log's date interpreted in log's stored timezone (the display timezone when created)
            // - Query date interpreted in query timezone (current display timezone)
            return CalendarUtils.areSameDayAcrossTimezones(
                log.date,
                timezone1: logTimezone,
                date,
                timezone2: timezone
            )
        }

        return dayLogs.contains { log in
            HabitLogCompletionValidator.isLogCompleted(log: log, habit: habit)
        }
    }

    private func isWeeklyTargetMet(habit: Habit, weeklyTarget: Int, date: Date, logs: [HabitLog], timezone: TimeZone) -> Bool {
        guard let weekInterval = CalendarUtils.weekIntervalLocal(for: date, timezone: timezone) else { return false }

        let weekLogs = logs.filter { log in
            log.habitID == habit.id &&
            log.date >= weekInterval.start &&
            log.date < weekInterval.end &&
            HabitLogCompletionValidator.isLogCompleted(log: log, habit: habit)
        }

        return weekLogs.count >= weeklyTarget
    }

    private func calculateWeeklyProgressUpToDate(habit: Habit, weeklyTarget: Int, date: Date, logs: [HabitLog], timezone: TimeZone) -> Double {
        guard let weekInterval = CalendarUtils.weekIntervalLocal(for: date, timezone: timezone) else { return 0.0 }

        let weekLogs = logs.filter { log in
            log.habitID == habit.id &&
            log.date >= weekInterval.start &&
            log.date <= date &&
            HabitLogCompletionValidator.isLogCompleted(log: log, habit: habit)
        }

        return min(Double(weekLogs.count) / Double(weeklyTarget), 1.0)
    }
    
    private func filterLogsForHabit(_ logs: [HabitLog], habitId: UUID, from startDate: Date, to endDate: Date) -> [HabitLog] {
        // Filter logs with timezone-aware buffer to handle logs across different timezones
        //
        // RATIONALE: The world's timezones span from UTC-12 (Baker Island) to UTC+14 (Line Islands),
        // a total range of 26 hours. A log created at 1:00 AM on Nov 3 in UTC+14 has a UTC timestamp
        // of 11:00 AM on Nov 2. Without a buffer, this log would be incorrectly excluded when querying
        // for Nov 3 progress.
        //
        // The 15-hour buffer on each side ensures we capture all logs that could represent calendar days
        // within the query range, regardless of their timezone. The extra hour beyond UTC+14 accounts for
        // daylight saving time transitions. The final calendar day comparison in isCompletedOnSpecificDay()
        // then filters out logs that don't actually match.
        //
        // PERFORMANCE: This adds ~30 hours to each query range, but it's necessary for correctness
        // and the overhead is acceptable since the final filtering is done in memory.
        let bufferSeconds: TimeInterval = 15 * 60 * 60  // Maximum UTC offset is UTC+14 + 1 hour for DST
        let bufferedStart = startDate.addingTimeInterval(-bufferSeconds)
        let bufferedEnd = endDate.addingTimeInterval(bufferSeconds)

        return logs.filter { log in
            log.habitID == habitId && log.date >= bufferedStart && log.date <= bufferedEnd
        }
    }
    
    private func calculateDailyScheduleProgress(habit: Habit, logs: [HabitLog], from startDate: Date, to endDate: Date, timezone: TimeZone) -> Double {
        let expectedDays = calculateDaysBetween(from: startDate, to: endDate, timezone: timezone)
        guard expectedDays > 0 else { return 0.0 }

        var completedDays = 0
        var currentDate = CalendarUtils.startOfDayLocal(for: startDate, timezone: timezone)
        let endOfRange = CalendarUtils.startOfDayLocal(for: endDate, timezone: timezone)

        while currentDate <= endOfRange {
            if isCompletedOnSpecificDay(habit: habit, date: currentDate, logs: logs, timezone: timezone) {
                completedDays += 1
            }
            currentDate = CalendarUtils.nextDayLocal(from: currentDate, timezone: timezone)
        }

        return Double(completedDays) / Double(expectedDays)
    }

    private func calculateDaysOfWeekProgress(habit: Habit, scheduledDays: Set<Int>, logs: [HabitLog], from startDate: Date, to endDate: Date, timezone: TimeZone) -> Double {
        let expectedDays = calculateScheduledDays(scheduledDays: scheduledDays, from: startDate, to: endDate, timezone: timezone)
        guard expectedDays > 0 else { return 0.0 }

        var completedDays = 0
        var currentDate = CalendarUtils.startOfDayLocal(for: startDate, timezone: timezone)
        let endOfRange = CalendarUtils.startOfDayLocal(for: endDate, timezone: timezone)

        while currentDate <= endOfRange {
            let weekday = CalendarUtils.habitWeekday(from: currentDate, timezone: timezone)
            if scheduledDays.contains(weekday) && isCompletedOnSpecificDay(habit: habit, date: currentDate, logs: logs, timezone: timezone) {
                completedDays += 1
            }
            currentDate = CalendarUtils.nextDayLocal(from: currentDate, timezone: timezone)
        }

        return Double(completedDays) / Double(expectedDays)
    }

    private func calculateTimesPerWeekProgress(habit: Habit, weeklyTarget: Int, logs: [HabitLog], from startDate: Date, to endDate: Date, timezone: TimeZone) -> Double {
        // Use duration-based week calculation for consistency with calculateWeeklyTargets
        let totalDays = CalendarUtils.daysBetweenLocal(startDate, endDate, timezone: timezone) + 1 // +1 because range is inclusive
        let totalWeeks = max(1, Int(round(Double(totalDays) / 7.0))) // Use rounding to match user expectations

        // Filter for only completed logs within the date range
        let completedLogs = logs.filter { log in
            log.date >= startDate && log.date <= endDate && HabitLogCompletionValidator.isLogCompleted(log: log, habit: habit)
        }

        // Group completed logs by week start date
        let completionsByWeek = Dictionary(grouping: completedLogs) { log in
            CalendarUtils.startOfWeekLocal(for: log.date, timezone: timezone)
        }

        var totalActualCompletions = 0

        // Calculate week by week using calendar week boundaries
        var currentWeekStart = CalendarUtils.startOfWeekLocal(for: startDate, timezone: timezone)
        let endWeekStart = CalendarUtils.startOfWeekLocal(for: endDate, timezone: timezone)

        while currentWeekStart <= endWeekStart {
            // Count unique days (not total logs) - consistent with getWeeklyProgress
            let weekLogs = completionsByWeek[currentWeekStart] ?? []
            let uniqueDaysInWeek = Set(weekLogs.map { CalendarUtils.startOfDayLocal(for: $0.date, timezone: timezone) }).count

            totalActualCompletions += min(uniqueDaysInWeek, weeklyTarget)

            currentWeekStart = CalendarUtils.addWeeks(1, to: currentWeekStart)
        }

        let totalExpected = totalWeeks * weeklyTarget
        guard totalExpected > 0 else { return 0.0 }

        return Double(totalActualCompletions) / Double(totalExpected)
    }

    private func calculateDaysBetween(from startDate: Date, to endDate: Date, timezone: TimeZone) -> Int {
        let daysDifference = CalendarUtils.daysBetweenLocal(startDate, endDate, timezone: timezone)
        return max(1, daysDifference + 1)
    }

    private func calculateScheduledDays(scheduledDays: Set<Int>, from startDate: Date, to endDate: Date, timezone: TimeZone) -> Int {
        var count = 0
        var currentDate = CalendarUtils.startOfDayLocal(for: startDate, timezone: timezone)
        let endOfRange = CalendarUtils.startOfDayLocal(for: endDate, timezone: timezone)

        while currentDate <= endOfRange {
            let weekday = CalendarUtils.habitWeekday(from: currentDate, timezone: timezone)
            if scheduledDays.contains(weekday) {
                count += 1
            }
            currentDate = CalendarUtils.nextDayLocal(from: currentDate, timezone: timezone)
        }

        return count
    }

    private func calculateWeeklyTargets(weeklyTarget: Int, from startDate: Date, to endDate: Date, timezone: TimeZone) -> Int {
        // Count the number of calendar weeks that overlap with the date range
        var weekCount = 0
        var currentWeekStart = CalendarUtils.startOfWeekLocal(for: startDate, timezone: timezone)
        let endWeekStart = CalendarUtils.startOfWeekLocal(for: endDate, timezone: timezone)

        while currentWeekStart <= endWeekStart {
            weekCount += 1
            currentWeekStart = CalendarUtils.addWeeks(1, to: currentWeekStart)
        }

        return weekCount * weeklyTarget
    }
}
