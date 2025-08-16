//
//  ScheduleAwareCompletionCalculator.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 16.08.2025.
//


import Foundation

/// Service responsible for calculating accurate completion rates based on habit schedules and types
public protocol ScheduleAwareCompletionCalculator {
    /// Calculate completion rate for a specific habit within a date range
    func calculateCompletionRate(
        for habit: Habit,
        logs: [HabitLog],
        startDate: Date,
        endDate: Date
    ) -> Double
    
    /// Check if a habit was completed on a specific date
    func isHabitCompleted(habit: Habit, logs: [HabitLog], date: Date) -> Bool
    
    /// Calculate total expected days for a habit within a date range
    func calculateExpectedDays(
        for habit: Habit,
        startDate: Date,
        endDate: Date
    ) -> Int
    
    /// Calculate completion stats for multiple habits
    func calculateCompletionStats(
        for habits: [Habit],
        logs: [HabitLog],
        startDate: Date,
        endDate: Date
    ) -> HabitCompletionStats
}