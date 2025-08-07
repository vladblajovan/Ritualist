//
//  DashboardEntities.swift
//  Ritualist
//
//  Created by Claude on 07.08.2025.
//

import Foundation

// MARK: - Habit Performance

public struct HabitPerformanceResult {
    public let habitId: UUID
    public let habitName: String
    public let emoji: String
    public let completionRate: Double
    public let completedDays: Int
    public let expectedDays: Int
    
    public init(habitId: UUID, habitName: String, emoji: String, completionRate: Double, completedDays: Int, expectedDays: Int) {
        self.habitId = habitId
        self.habitName = habitName
        self.emoji = emoji
        self.completionRate = completionRate
        self.completedDays = completedDays
        self.expectedDays = expectedDays
    }
}

// MARK: - Progress Chart

public struct ProgressChartDataPoint {
    public let date: Date
    public let completionRate: Double
    
    public init(date: Date, completionRate: Double) {
        self.date = date
        self.completionRate = completionRate
    }
}

// MARK: - Weekly Patterns

public struct WeeklyPatternsResult {
    public let dayOfWeekPerformance: [DayOfWeekPerformanceResult]
    public let bestDay: String
    public let worstDay: String
    public let averageWeeklyCompletion: Double
    
    public init(
        dayOfWeekPerformance: [DayOfWeekPerformanceResult],
        bestDay: String,
        worstDay: String,
        averageWeeklyCompletion: Double
    ) {
        self.dayOfWeekPerformance = dayOfWeekPerformance
        self.bestDay = bestDay
        self.worstDay = worstDay
        self.averageWeeklyCompletion = averageWeeklyCompletion
    }
}

public struct DayOfWeekPerformanceResult {
    public let dayName: String
    public let completionRate: Double
    public let averageHabitsCompleted: Int
    
    public init(dayName: String, completionRate: Double, averageHabitsCompleted: Int) {
        self.dayName = dayName
        self.completionRate = completionRate
        self.averageHabitsCompleted = averageHabitsCompleted
    }
}

// MARK: - Streak Analysis

public struct StreakAnalysisResult {
    public let currentStreak: Int
    public let longestStreak: Int
    public let streakTrend: String // "improving", "declining", "stable"
    public let daysWithFullCompletion: Int
    public let consistencyScore: Double // 0-1
    
    public init(
        currentStreak: Int,
        longestStreak: Int,
        streakTrend: String,
        daysWithFullCompletion: Int,
        consistencyScore: Double
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.streakTrend = streakTrend
        self.daysWithFullCompletion = daysWithFullCompletion
        self.consistencyScore = consistencyScore
    }
}

// MARK: - Category Performance

public struct CategoryPerformanceResult {
    public let categoryId: String
    public let categoryName: String
    public let completionRate: Double
    public let habitCount: Int
    public let color: String
    public let emoji: String?
    
    public init(
        categoryId: String,
        categoryName: String,
        completionRate: Double,
        habitCount: Int,
        color: String,
        emoji: String? = nil
    ) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.completionRate = completionRate
        self.habitCount = habitCount
        self.color = color
        self.emoji = emoji
    }
}