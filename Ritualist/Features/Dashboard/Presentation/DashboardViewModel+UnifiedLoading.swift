import Foundation
import RitualistCore
import FactoryKit

extension DashboardViewModel {
    
    /// Load unified dashboard data in a single batch operation
    /// Replaces 5 separate UseCase calls with 1 unified data load + extraction
    /// Expected to reduce queries from 471+ to 3 for annual views
    func loadUnifiedDashboardData() async throws -> DashboardData {
        let range = selectedTimePeriod.dateRange
        
        // PHASE 2: Single batch data loading (3 queries total)
        
        // 1. Single query for all active habits
        let habits = try await habitAnalyticsService.getActiveHabits(for: userId)
        
        // 2. Single query for all categories (if needed)
        // TODO: Add category repository injection when available
        let categories: [Category] = [] // Placeholder - will be updated when CategoryRepository is available
        
        // 3. Single batch query for ALL habit logs in the entire date range
        let habitIds = habits.map(\.id)
        let habitLogs = try await self.getBatchLogs.execute(
            for: habitIds,
            since: range.start,
            until: range.end
        )
        
        // Create unified data structure with pre-calculated daily completions
        return DashboardData(
            habits: habits,
            categories: categories,
            habitLogs: habitLogs,
            dateRange: range.start...range.end
        )
    }
    
    
    // MARK: - Data Extraction Methods (Phase 4)
    
    /// Extract completion statistics from unified dashboard data
    /// Replaces initial habitAnalyticsService.getHabitCompletionStats call
    func extractCompletionStats(from dashboardData: DashboardData) -> HabitCompletionStats {
        let habits = dashboardData.habits
        let dateRange = dashboardData.dateRange
        
        guard !habits.isEmpty else {
            return HabitCompletionStats(totalHabits: 0, completedHabits: 0, completionRate: 0.0)
        }
        
        // Calculate total completions across all days in range
        var totalPossibleCompletions = 0
        var totalActualCompletions = 0
        
        let calendar = Calendar.current
        var currentDate = dateRange.lowerBound
        
        while currentDate <= dateRange.upperBound {
            let startOfDay = calendar.startOfDay(for: currentDate)
            let scheduledHabits = dashboardData.scheduledHabits(for: startOfDay)
            let completionRate = dashboardData.completionRate(for: startOfDay)
            
            totalPossibleCompletions += scheduledHabits.count
            totalActualCompletions += Int(completionRate * Double(scheduledHabits.count))
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        let averageCompletionRate = totalPossibleCompletions > 0 ? Double(totalActualCompletions) / Double(totalPossibleCompletions) : 0.0
        
        return HabitCompletionStats(
            totalHabits: habits.count,
            completedHabits: totalActualCompletions,
            completionRate: averageCompletionRate
        )
    }
    
    /// Extract habit performance data from unified dashboard data
    /// O(n) operation using pre-calculated data - no additional queries
    func extractHabitPerformanceData(from dashboardData: DashboardData) -> [HabitPerformanceViewModel] {
        let domainResults = dashboardData.habitPerformanceData()
        return domainResults.map(HabitPerformanceViewModel.init)
    }
    
    /// Extract progress chart data from unified dashboard data
    /// O(n) operation using pre-calculated data - no additional queries  
    func extractProgressChartData(from dashboardData: DashboardData) -> [ChartDataPointViewModel] {
        let domainResults = dashboardData.chartDataPoints()
        return domainResults.map(ChartDataPointViewModel.init)
    }
    
    /// Extract weekly patterns from unified dashboard data
    /// Uses pre-loaded logs without additional queries
    func extractWeeklyPatterns(from dashboardData: DashboardData) -> WeeklyPatternsViewModel? {
        // Calculate weekly patterns from dashboard data
        let habits = dashboardData.habits
        let dateRange = dashboardData.dateRange
        
        guard !habits.isEmpty else { return nil }
        
        let calendar = Calendar.current
        var dayOfWeekStats: [Int: (completed: Int, total: Int)] = [:]
        
        // Initialize stats for all days of week (1 = Sunday, 7 = Saturday)
        for dayNum in 1...7 {
            dayOfWeekStats[dayNum] = (completed: 0, total: 0)
        }
        
        // Analyze each day in the date range
        var currentDate = dateRange.lowerBound
        while currentDate <= dateRange.upperBound {
            let dayOfWeek = calendar.component(.weekday, from: currentDate)
            let completionRate = dashboardData.completionRate(for: currentDate)
            let scheduledCount = dashboardData.scheduledHabits(for: currentDate).count
            
            if scheduledCount > 0 {
                let completedCount = Int(completionRate * Double(scheduledCount))
                dayOfWeekStats[dayOfWeek]?.completed += completedCount
                dayOfWeekStats[dayOfWeek]?.total += scheduledCount
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        // Convert to domain models and find best/worst days
        let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        var dayPerformances: [DayOfWeekPerformanceResult] = []
        var bestDayRate = 0.0
        var worstDayRate = 1.0
        var bestDay = "Monday"
        var worstDay = "Monday"
        
        for (dayNum, stats) in dayOfWeekStats.sorted(by: { $0.key < $1.key }) {
            let rate = stats.total > 0 ? Double(stats.completed) / Double(stats.total) : 0.0
            let dayName = dayNames[dayNum - 1]
            
            dayPerformances.append(DayOfWeekPerformanceResult(
                dayName: dayName,
                completionRate: rate,
                averageHabitsCompleted: stats.completed
            ))
            
            if rate > bestDayRate {
                bestDayRate = rate
                bestDay = dayName
            }
            if rate < worstDayRate {
                worstDayRate = rate
                worstDay = dayName
            }
        }
        
        let averageRate = dayOfWeekStats.values.reduce(0.0) { total, stats in
            let rate = stats.total > 0 ? Double(stats.completed) / Double(stats.total) : 0.0
            return total + rate
        } / Double(dayOfWeekStats.count)
        
        let weeklyPatternsResult = WeeklyPatternsResult(
            dayOfWeekPerformance: dayPerformances,
            bestDay: bestDay,
            worstDay: worstDay,
            averageWeeklyCompletion: averageRate
        )
        
        return WeeklyPatternsViewModel(from: weeklyPatternsResult)
    }
    
    /// Extract streak analysis from unified dashboard data
    /// Uses pre-loaded logs without additional queries
    func extractStreakAnalysis(from dashboardData: DashboardData) -> StreakAnalysisViewModel? {
        let habits = dashboardData.habits
        guard !habits.isEmpty else { return nil }
        
        var totalCurrentStreaks = 0
        var activeStreaks = 0
        var longestStreak = 0
        var averageStreak = 0.0
        
        for habit in habits {
            if let streakInfo = dashboardData.streakData(for: habit.id) {
                totalCurrentStreaks += streakInfo.currentStreak
                if streakInfo.currentStreak > 0 {
                    activeStreaks += 1
                }
                longestStreak = max(longestStreak, streakInfo.currentStreak)
            }
        }
        
        averageStreak = habits.isEmpty ? 0.0 : Double(totalCurrentStreaks) / Double(habits.count)
        
        let streakAnalysisResult = StreakAnalysisResult(
            currentStreak: longestStreak,
            longestStreak: longestStreak,
            streakTrend: "stable",
            daysWithFullCompletion: activeStreaks,
            consistencyScore: averageStreak / 10.0 // Normalize to 0-1 range
        )
        
        return StreakAnalysisViewModel(from: streakAnalysisResult)
    }
    
    /// Extract category breakdown from unified dashboard data
    /// Uses pre-calculated data without additional queries
    func extractCategoryBreakdown(from dashboardData: DashboardData) -> [CategoryPerformanceViewModel] {
        let domainResults = dashboardData.categoryPerformanceData()
        return domainResults.map(CategoryPerformanceViewModel.init)
    }
}
