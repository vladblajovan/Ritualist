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
    func execute(logs: [HabitLog]) -> Int
}

public final class DefaultCalculateConsecutiveTrackingDaysService: CalculateConsecutiveTrackingDaysService {

    public init() {}

    public func execute(logs: [HabitLog]) -> Int {
        // Group logs by date using LOCAL timezone business logic
        let logsByDate = Dictionary(grouping: logs, by: {
            CalendarUtils.startOfDayLocal(for: $0.date)
        })

        let sortedDates = logsByDate.keys.sorted(by: >)

        var consecutiveDays = 0
        var currentDate = CalendarUtils.startOfDayLocal(for: Date())

        for date in sortedDates {
            if CalendarUtils.areSameDayLocal(date, currentDate) {
                consecutiveDays += 1
                currentDate = CalendarUtils.addDays(-1, to: currentDate)
            } else if date < currentDate {
                // Gap in tracking, stop counting
                break
            }
        }

        return consecutiveDays
    }
}
