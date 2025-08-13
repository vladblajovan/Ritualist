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
    case timesPerWeek(Int) // 1…7
}

public extension HabitSchedule {
    func isActiveOn(date: Date) -> Bool {
        let calendar = Calendar.current
        let calendarWeekday = calendar.component(.weekday, from: date)
        let habitWeekday = DateUtils.calendarWeekdayToHabitWeekday(calendarWeekday)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        let weekdayName = calendar.weekdaySymbols[calendarWeekday - 1]
        
        switch self {
        case .daily:
            return true
        case .daysOfWeek(let days):
            let isActive = days.contains(habitWeekday)
            let dayNames = days.sorted().map { dayNum in
                let calWeekday = DateUtils.habitWeekdayToCalendarWeekday(dayNum)
                return calendar.weekdaySymbols[calWeekday - 1]
            }
            return isActive
        case .timesPerWeek(let times):
            return true
        }
    }
}
