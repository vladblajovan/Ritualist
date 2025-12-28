//
//  CalculateConsecutiveTrackingDaysService.swift
//  RitualistCore
//
//  Created by Claude on 14.11.2025.
//

import Foundation

/// Service for calculating consecutive tracking days from habit logs
public protocol CalculateConsecutiveTrackingDaysService: Sendable {
    /// Calculate how many consecutive days the user has tracked habits
    /// - Parameters:
    ///   - logs: The habit logs to analyze
    ///   - timezone: The timezone to use for date calculations
    func execute(logs: [HabitLog], timezone: TimeZone) -> Int
}

// MARK: - Default Implementation for Backward Compatibility
public extension CalculateConsecutiveTrackingDaysService {
    /// Convenience method that uses the current device timezone
    func execute(logs: [HabitLog]) -> Int {
        execute(logs: logs, timezone: .current)
    }
}

public final class DefaultCalculateConsecutiveTrackingDaysService: CalculateConsecutiveTrackingDaysService {

    public init() {}

    public func execute(logs: [HabitLog], timezone: TimeZone = .current) -> Int {
        // Group logs by their calendar day using cross-timezone comparison
        // Each log's date is interpreted in its stored timezone to determine the calendar day
        var uniqueCalendarDays: Set<Date> = []

        for log in logs {
            // Use log's stored timezone to determine which calendar day this log belongs to
            let logTimezone = log.resolvedTimezone(fallback: timezone)
            let logCalendarDay = CalendarUtils.startOfDayLocal(for: log.date, timezone: logTimezone)
            uniqueCalendarDays.insert(logCalendarDay)
        }

        let sortedDates = uniqueCalendarDays.sorted(by: >)

        var consecutiveDays = 0
        var currentDate = CalendarUtils.startOfDayLocal(for: Date(), timezone: timezone)

        for date in sortedDates {
            // Check if any log exists for currentDate using cross-timezone comparison
            let hasLogForCurrentDate = logs.contains { log in
                let logTimezone = log.resolvedTimezone(fallback: timezone)
                return CalendarUtils.areSameDayAcrossTimezones(
                    log.date,
                    timezone1: logTimezone,
                    currentDate,
                    timezone2: timezone
                )
            }

            if hasLogForCurrentDate {
                consecutiveDays += 1
                currentDate = CalendarUtils.addDaysLocal(-1, to: currentDate, timezone: timezone)
            } else if date < currentDate {
                // Gap in tracking, stop counting
                break
            }
        }

        return consecutiveDays
    }
}
