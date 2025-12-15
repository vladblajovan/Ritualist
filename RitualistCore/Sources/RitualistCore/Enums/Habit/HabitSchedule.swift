//
//  HabitSchedule.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public enum HabitSchedule: Codable, Equatable, Hashable {
    case daily
    case daysOfWeek(Set<Int>) // 1=Mon…7=Sun
}

public extension HabitSchedule {
    /// Check if this schedule is active on the given date using the specified timezone.
    /// - Parameters:
    ///   - date: The date to check
    ///   - timezone: The timezone to use for weekday calculation (defaults to device timezone for backward compatibility)
    /// - Returns: `true` if the schedule is active on this date
    func isActiveOn(date: Date, timezone: TimeZone = .current) -> Bool {
        // Use the specified timezone for schedule checking since users think of schedules in their display timezone context
        // When viewingDate is "Tuesday midnight in display timezone", we want to check if Tuesday is in the schedule
        let calendarWeekday = CalendarUtils.weekdayComponentLocal(from: date, timezone: timezone)
        let habitWeekday = CalendarUtils.calendarWeekdayToHabitWeekday(calendarWeekday)

        switch self {
        case .daily:
            return true
        case .daysOfWeek(let days):
            return days.contains(habitWeekday)
        }
    }
}
