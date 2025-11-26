//
//  HabitScheduleAnalyzerProtocol.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import Foundation

/// Service for analyzing habit schedules and expected completion dates
public protocol HabitScheduleAnalyzerProtocol {
    /// Calculate number of expected days for a habit in a date range
    /// - Parameters:
    ///   - habit: The habit to analyze
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    ///   - timezone: Timezone to use for date calculations
    /// - Returns: Number of days the habit is expected to be completed
    func calculateExpectedDays(for habit: Habit, from startDate: Date, to endDate: Date, timezone: TimeZone) -> Int

    /// Check if a habit is expected to be completed on a specific date
    /// - Parameters:
    ///   - habit: The habit to check
    ///   - date: The date to check
    ///   - timezone: Timezone to use for weekday calculation
    /// - Returns: `true` if the habit is expected on this date
    func isHabitExpectedOnDate(habit: Habit, date: Date, timezone: TimeZone) -> Bool
}

// MARK: - Convenience Extensions (Backward Compatibility)

public extension HabitScheduleAnalyzerProtocol {
    /// Calculate expected days using current timezone (convenience method)
    func calculateExpectedDays(for habit: Habit, from startDate: Date, to endDate: Date) -> Int {
        return calculateExpectedDays(for: habit, from: startDate, to: endDate, timezone: .current)
    }

    /// Check if habit is expected on date using current timezone (convenience method)
    func isHabitExpectedOnDate(habit: Habit, date: Date) -> Bool {
        return isHabitExpectedOnDate(habit: habit, date: date, timezone: .current)
    }
}

public final class HabitScheduleAnalyzer: HabitScheduleAnalyzerProtocol {

    /// Maximum allowed date range in days to prevent performance issues
    /// 10 years = ~3,650 days is a reasonable upper limit for habit tracking
    private static let maxDateRangeInDays = 3650

    public init() {
        // Using CalendarUtils for LOCAL timezone business logic consistency
    }

    public func calculateExpectedDays(for habit: Habit, from startDate: Date, to endDate: Date, timezone: TimeZone) -> Int {
        var expectedDays = 0
        var currentDate = CalendarUtils.startOfDayLocal(for: startDate, timezone: timezone)
        let end = CalendarUtils.startOfDayLocal(for: endDate, timezone: timezone)

        // Performance limit: Prevent infinite loops for extremely large date ranges
        let daysDifference = CalendarUtils.daysBetweenLocal(startDate, endDate, timezone: timezone)
        guard daysDifference >= 0 && daysDifference <= Self.maxDateRangeInDays else {
            return 0
        }

        while currentDate <= end {
            defer {
                currentDate = CalendarUtils.addDaysLocal(1, to: currentDate, timezone: timezone)
            }

            // For retroactive logging: don't skip days before habit creation
            // The caller should handle the date range appropriately

            // Skip if habit ended before this date
            if let habitEndDate = habit.endDate, currentDate > CalendarUtils.startOfDayLocal(for: habitEndDate, timezone: timezone) {
                continue
            }

            // Check if habit was expected on this day based on schedule
            if isHabitExpectedOnDate(habit: habit, date: currentDate, timezone: timezone) {
                expectedDays += 1
            }
        }

        return expectedDays
    }
    
    public func isHabitExpectedOnDate(habit: Habit, date: Date, timezone: TimeZone) -> Bool {
        let weekday = CalendarUtils.weekdayComponentLocal(from: date, timezone: timezone)

        switch habit.schedule {
        case .daily:
            return true

        case .daysOfWeek(let days):
            // Convert Calendar weekday (Sunday=1) to HabitSchedule format (Monday=1)
            let habitWeekday = CalendarUtils.calendarWeekdayToHabitWeekday(weekday)
            return days.contains(habitWeekday)

        }
    }
}