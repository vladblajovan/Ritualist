//
//  HabitScheduleAnalyzer.swift
//  Ritualist
//
//  Created by Claude on 07.08.2025.
//

import Foundation

public protocol HabitScheduleAnalyzerProtocol {
    func calculateExpectedDays(for habit: Habit, from startDate: Date, to endDate: Date) -> Int
    func isHabitExpectedOnDate(habit: Habit, date: Date) -> Bool
}

public final class HabitScheduleAnalyzer: HabitScheduleAnalyzerProtocol {
    private let calendar: Calendar
    
    public init(calendar: Calendar = Calendar.current) {
        self.calendar = calendar
    }
    
    public func calculateExpectedDays(for habit: Habit, from startDate: Date, to endDate: Date) -> Int {
        var expectedDays = 0
        var currentDate = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        
        while currentDate <= end {
            defer {
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            
            // For retroactive logging: don't skip days before habit creation
            // The caller should handle the date range appropriately
            
            // Skip if habit ended before this date
            if let habitEndDate = habit.endDate, currentDate > calendar.startOfDay(for: habitEndDate) {
                continue
            }
            
            // Check if habit was expected on this day based on schedule
            if isHabitExpectedOnDate(habit: habit, date: currentDate) {
                expectedDays += 1
            }
        }
        
        return expectedDays
    }
    
    public func isHabitExpectedOnDate(habit: Habit, date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        
        switch habit.schedule {
        case .daily:
            return true
            
        case .daysOfWeek(let days):
            // Convert Calendar weekday (Sunday=1) to HabitSchedule format (Monday=1)
            let habitWeekday: Int
            if weekday == 1 { // Sunday
                habitWeekday = 7
            } else { // Monday=2 -> 1, Tuesday=3 -> 2, etc.
                habitWeekday = weekday - 1
            }
            return days.contains(habitWeekday)
            
        case .timesPerWeek(_):
            // For times per week, we consider the habit expected every day
            // The actual completion rate calculation will handle the flexible nature
            return true
        }
    }
}