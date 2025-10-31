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
        let calendarWeekday = CalendarUtils.weekdayComponentUTC(from: date)
        let habitWeekday = CalendarUtils.calendarWeekdayToHabitWeekday(calendarWeekday)
        
        switch self {
        case .daily:
            return true
        case .daysOfWeek(let days):
            return days.contains(habitWeekday)
        }
    }
}
