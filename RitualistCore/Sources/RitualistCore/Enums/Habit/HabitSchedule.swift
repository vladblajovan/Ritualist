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
    func isActiveOn(date: Date) -> Bool {
        // Use LOCAL timezone for schedule checking since users think of schedules in their local context
        // When viewingDate is "Tuesday midnight local", we want to check if Tuesday is in the schedule
        let calendarWeekday = CalendarUtils.weekdayComponentLocal(from: date)
        let habitWeekday = CalendarUtils.calendarWeekdayToHabitWeekday(calendarWeekday)

        print("📅 isActiveOn DEBUG: date=\(date), calendarWeekday=\(calendarWeekday), habitWeekday=\(habitWeekday)")

        switch self {
        case .daily:
            return true
        case .daysOfWeek(let days):
            let result = days.contains(habitWeekday)
            print("📅 isActiveOn DEBUG: schedule=\(days), contains \(habitWeekday)? \(result)")
            return result
        }
    }
}
