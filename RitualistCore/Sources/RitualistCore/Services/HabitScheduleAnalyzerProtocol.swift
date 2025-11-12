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
    func calculateExpectedDays(for habit: Habit, from startDate: Date, to endDate: Date) -> Int
    
    /// Check if a habit is expected to be completed on a specific date
    func isHabitExpectedOnDate(habit: Habit, date: Date) -> Bool
}

public final class HabitScheduleAnalyzer: HabitScheduleAnalyzerProtocol {
    
    public init() {
        // Using CalendarUtils for LOCAL timezone business logic consistency
    }
    
    public func calculateExpectedDays(for habit: Habit, from startDate: Date, to endDate: Date) -> Int {
        var expectedDays = 0
        var currentDate = CalendarUtils.startOfDayLocal(for: startDate)
        let end = CalendarUtils.startOfDayLocal(for: endDate)
        
        while currentDate <= end {
            defer {
                currentDate = CalendarUtils.addDays(1, to: currentDate)
            }
            
            // For retroactive logging: don't skip days before habit creation
            // The caller should handle the date range appropriately
            
            // Skip if habit ended before this date
            if let habitEndDate = habit.endDate, currentDate > CalendarUtils.startOfDayLocal(for: habitEndDate) {
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
        let weekday = CalendarUtils.weekdayComponentLocal(from: date)
        
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
            
        }
    }
}