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