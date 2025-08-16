//
//  PerformanceAnalysisService.swift
//  Ritualist
//
//  Created by Claude on 07.08.2025.
//

import Foundation
import RitualistCore

// PerformanceAnalysisService protocol moved to RitualistCore/Services/PerformanceAnalysisService.swift

public final class PerformanceAnalysisServiceImpl: PerformanceAnalysisService {
    
    private let scheduleAnalyzer: HabitScheduleAnalyzerProtocol
    private let calendar: Calendar
    
    public init(
        scheduleAnalyzer: HabitScheduleAnalyzerProtocol,
        calendar: Calendar = DateUtils.userCalendar()
    ) {
        self.scheduleAnalyzer = scheduleAnalyzer
        self.calendar = calendar
    }
    
    public func calculateHabitPerformance(
        habits: [Habit], 
        logs: [HabitLog], 
        from startDate: Date, 
        to endDate: Date
    ) -> [HabitPerformanceResult] {
        
        let activeHabits = habits.filter { $0.isActive }
        var results: [HabitPerformanceResult] = []
        
        for habit in activeHabits {
            let habitLogs = logs.filter { $0.habitID == habit.id }
            let logsInRange = habitLogs.filter { log in
                log.date >= startDate && log.date <= endDate
            }
            
            // For retroactive logging support: calculate expected days from the earliest relevant date
            // This ensures that if user logs retroactively, we account for those periods in expected days
            let earliestLogDate = logsInRange.map { $0.date }.min()
            let effectiveStartDate = min(habit.startDate, earliestLogDate ?? habit.startDate)
            let calculationStartDate = max(startDate, effectiveStartDate)
            
            let expectedDays = scheduleAnalyzer.calculateExpectedDays(
                for: habit,
                from: calculationStartDate,
                to: endDate
            )
            
            let completionRate = expectedDays > 0 ? Double(logsInRange.count) / Double(expectedDays) : 0.0
            
            let result = HabitPerformanceResult(
                habitId: habit.id,
                habitName: habit.name,
                emoji: habit.emoji ?? "📊",
                completionRate: min(completionRate, 1.0),
                completedDays: logsInRange.count,
                expectedDays: expectedDays
            )
            
            results.append(result)
        }
        
        return results.sorted { $0.completionRate > $1.completionRate }
    }
    
    public func generateProgressChartData(
        completionStats: [Date: HabitCompletionStats]
    ) -> [ProgressChartDataPoint] {
        
        return completionStats
            .sorted { $0.key < $1.key }
            .map { date, stats in
                ProgressChartDataPoint(
                    date: date,
                    completionRate: stats.completionRate
                )
            }
    }
    
    public func analyzeWeeklyPatterns(
        habits: [Habit], 
        logs: [HabitLog], 
        from startDate: Date, 
        to endDate: Date
    ) -> WeeklyPatternsResult {
        
        let logsByDate = Dictionary(grouping: logs, by: { calendar.startOfDay(for: $0.date) })
        
        // Initialize day performance tracking
        var dayPerformance: [Int: (total: Int, completed: Int)] = [:]
        for weekday in 1...7 {
            dayPerformance[weekday] = (0, 0)
        }
        
        // Analyze each day in the range
        var currentDate = startDate
        while currentDate <= endDate {
            let dayLogs = logsByDate[calendar.startOfDay(for: currentDate)] ?? []
            let weekday = calendar.component(.weekday, from: currentDate)
            
            for habit in habits where habit.isActive {
                if scheduleAnalyzer.isHabitExpectedOnDate(habit: habit, date: currentDate) {
                    dayPerformance[weekday]?.total += 1
                    
                    if dayLogs.contains(where: { $0.habitID == habit.id }) {
                        dayPerformance[weekday]?.completed += 1
                    }
                }
            }
            
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDay
        }
        
        // Calculate day of week performance results using proper week ordering
        let dayOfWeekResults = dayPerformance.map { weekday, performance in
            let dayName = calendar.weekdaySymbols[weekday - 1]
            let completionRate = performance.total > 0 ? Double(performance.completed) / Double(performance.total) : 0.0
            let averageCompleted = performance.total > 0 ? performance.completed / getDayCount(weekday: weekday, from: startDate, to: endDate) : 0
            
            return DayOfWeekPerformanceResult(
                dayName: dayName,
                completionRate: completionRate,
                averageHabitsCompleted: averageCompleted
            )
        }.sorted { $0.completionRate > $1.completionRate }
        
        let bestDay = dayOfWeekResults.first?.dayName ?? ""
        let worstDay = dayOfWeekResults.last?.dayName ?? ""
        let averageWeeklyCompletion = dayOfWeekResults.reduce(0.0) { $0 + $1.completionRate } / Double(dayOfWeekResults.count)
        
        return WeeklyPatternsResult(
            dayOfWeekPerformance: dayOfWeekResults,
            bestDay: bestDay,
            worstDay: worstDay,
            averageWeeklyCompletion: averageWeeklyCompletion
        )
    }
    
    public func calculateStreakAnalysis(
        habits: [Habit], 
        logs: [HabitLog], 
        from startDate: Date, 
        to endDate: Date
    ) -> StreakAnalysisResult {
        
        
        let logsByDate = Dictionary(grouping: logs, by: { calendar.startOfDay(for: $0.date) })
        let activeHabits = habits.filter { $0.isActive }
        
        var streakDays: [Date] = []
        var currentStreak = 0
        var longestStreak = 0
        var daysWithFullCompletion = 0
        
        // FIXED: Always start from today for current streak calculation
        let today = calendar.startOfDay(for: Date())
        var currentDate = today
        let start = calendar.startOfDay(for: startDate)
        
        
        while currentDate >= start {
            let dayLogs = logsByDate[currentDate] ?? []
            var dayCompleted = true
            var expectedHabitsCount = 0
            var completedHabitsThisDay: [String] = []
            var missedHabitsThisDay: [String] = []
            
            for habit in activeHabits {
                if scheduleAnalyzer.isHabitExpectedOnDate(habit: habit, date: currentDate) {
                    expectedHabitsCount += 1
                    if dayLogs.contains(where: { $0.habitID == habit.id }) {
                        completedHabitsThisDay.append(habit.name)
                    } else {
                        dayCompleted = false
                        missedHabitsThisDay.append(habit.name)
                    }
                }
            }
            
            
            if expectedHabitsCount > 0 && dayCompleted {
                currentStreak += 1
                streakDays.append(currentDate)
                daysWithFullCompletion += 1
            } else if expectedHabitsCount > 0 {
                // Break current streak if we had expected habits but didn't complete them all
                longestStreak = max(longestStreak, currentStreak)
                currentStreak = 0
            } else {
            }
            
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }
        
        longestStreak = max(longestStreak, currentStreak)
        
        // Calculate consistency based on analysis period
        let totalDays = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        let consistencyScore = totalDays > 0 ? Double(daysWithFullCompletion) / Double(totalDays) : 0.0
        
        let streakTrend: String
        if currentStreak > Int(Double(longestStreak) * 0.8) {
            streakTrend = "improving"
        } else if currentStreak < Int(Double(longestStreak) * 0.5) {
            streakTrend = "declining"
        } else {
            streakTrend = "stable"
        }
        
        
        return StreakAnalysisResult(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            streakTrend: streakTrend,
            daysWithFullCompletion: daysWithFullCompletion,
            consistencyScore: consistencyScore
        )
    }
    
    public func aggregateCategoryPerformance(
        habits: [Habit], 
        categories: [HabitCategory], 
        logs: [HabitLog], 
        from startDate: Date, 
        to endDate: Date
    ) -> [CategoryPerformanceResult] {
        
        // Group habits by category
        let habitsByCategory = Dictionary(grouping: habits) { habit in
            if let categoryId = habit.categoryId, categories.contains(where: { $0.id == categoryId }) {
                return categoryId
            } else if habit.suggestionId != nil {
                return "suggestion-unknown"
            } else {
                return "uncategorized"
            }
        }
        
        var categoryPerformance: [CategoryPerformanceResult] = []
        
        for (categoryId, categoryHabits) in habitsByCategory {
            // Skip the suggestion-unknown group as it indicates a data issue
            if categoryId == "suggestion-unknown" {
                print("WARNING: Found habits from suggestions with invalid categoryId")
                continue
            }
            
            // Find category info
            let category = categories.first { $0.id == categoryId }
            let categoryName = category?.displayName ?? "Uncategorized"
            let categoryColor = "#007AFF" // Default color since Category doesn't have colorHex
            let categoryEmoji = category?.emoji
            
            // Calculate completion rate for this category
            let completionRate = calculateCategoryCompletionRate(
                habits: categoryHabits,
                logs: logs,
                from: startDate,
                to: endDate
            )
            
            let performance = CategoryPerformanceResult(
                categoryId: categoryId,
                categoryName: categoryName,
                completionRate: completionRate,
                habitCount: categoryHabits.count,
                color: categoryColor,
                emoji: categoryEmoji
            )
            
            categoryPerformance.append(performance)
        }
        
        return categoryPerformance.sorted { $0.completionRate > $1.completionRate }
    }
    
    // MARK: - Private Helpers
    
    private func getDayCount(weekday: Int, from startDate: Date, to endDate: Date) -> Int {
        var count = 0
        var currentDate = startDate
        
        while currentDate <= endDate {
            if calendar.component(.weekday, from: currentDate) == weekday {
                count += 1
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDay
        }
        
        return max(count, 1) // Avoid division by zero
    }
    
    private func calculateCategoryCompletionRate(
        habits: [Habit], 
        logs: [HabitLog], 
        from startDate: Date, 
        to endDate: Date
    ) -> Double {
        guard !habits.isEmpty else { return 0.0 }
        
        let categoryLogs = logs.filter { log in
            habits.contains { $0.id == log.habitID }
        }
        
        var totalExpectedDays = 0
        var totalCompletedDays = 0
        
        for habit in habits {
            let habitLogs = categoryLogs.filter { $0.habitID == habit.id }
            
            let expectedDays = scheduleAnalyzer.calculateExpectedDays(
                for: habit,
                from: startDate,
                to: endDate
            )
            
            totalExpectedDays += expectedDays
            totalCompletedDays += habitLogs.count
        }
        
        return totalExpectedDays > 0 ? min(Double(totalCompletedDays) / Double(totalExpectedDays), 1.0) : 0.0
    }
}
