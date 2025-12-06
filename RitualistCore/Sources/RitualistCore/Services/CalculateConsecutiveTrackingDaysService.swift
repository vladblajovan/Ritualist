//
//  CalculateConsecutiveTrackingDaysService.swift
//  RitualistCore
//
//  Created by Claude on 14.11.2025.
//

import Foundation

/// Service for calculating consecutive tracking days from habit logs
public protocol CalculateConsecutiveTrackingDaysService {
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
        // Group logs by date using the specified timezone
        let logsByDate = Dictionary(grouping: logs, by: {
            CalendarUtils.startOfDayLocal(for: $0.date, timezone: timezone)
        })

        let sortedDates = logsByDate.keys.sorted(by: >)

        var consecutiveDays = 0
        var currentDate = CalendarUtils.startOfDayLocal(for: Date(), timezone: timezone)

        for date in sortedDates {
            if CalendarUtils.areSameDayLocal(date, currentDate, timezone: timezone) {
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
