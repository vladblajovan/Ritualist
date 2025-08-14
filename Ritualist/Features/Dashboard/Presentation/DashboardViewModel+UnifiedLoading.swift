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
        
        // 2. Single query for all categories
        let categories = try await getAllCategories.execute()
        
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
        var habitsWithCompletions: Set<UUID> = []
        
        let calendar = Calendar.current
        var currentDate = dateRange.lowerBound
        
        while currentDate <= dateRange.upperBound {
            let startOfDay = calendar.startOfDay(for: currentDate)
            let scheduledHabits = dashboardData.scheduledHabits(for: startOfDay)
            let completionRate = dashboardData.completionRate(for: startOfDay)
            
            totalPossibleCompletions += scheduledHabits.count
            totalActualCompletions += Int(completionRate * Double(scheduledHabits.count))
            
            // Track habits that had any completions on this day
            if completionRate > 0 {
                let completedHabitsToday = dashboardData.completedHabits(for: startOfDay)
                habitsWithCompletions.formUnion(completedHabitsToday)
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        let averageCompletionRate = totalPossibleCompletions > 0 ? Double(totalActualCompletions) / Double(totalPossibleCompletions) : 0.0
        
        return HabitCompletionStats(
            totalHabits: habits.count,
            completedHabits: habitsWithCompletions.count, // Fixed: Count of unique habits with completions
            completionRate: averageCompletionRate
        )
    }
    
    /// Extract habit performance data from unified dashboard data
    /// O(n) operation using pre-calculated data - no additional queries
    func extractHabitPerformanceData(from dashboardData: DashboardData) -> [HabitPerformanceViewModel] {
        let domainResults = dashboardData.habitPerformanceData(using: scheduleAnalyzer)
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
        
        let calendar = DateUtils.userCalendar() // Use system calendar with user's week start preference
        var dayOfWeekStats: [Int: (completed: Int, total: Int)] = [:]
        
        // Initialize stats for all days of week (1 = Sunday, 7 = Saturday)
        for dayNum in 1...7 {
            dayOfWeekStats[dayNum] = (completed: 0, total: 0)
        }
        
        // Analyze each day in the date range
        var currentDate = dateRange.lowerBound
        while currentDate <= dateRange.upperBound {
            let dayOfWeek = calendar.component(.weekday, from: currentDate)
            let scheduledHabits = dashboardData.scheduledHabits(for: currentDate)
            let completedHabits = dashboardData.completedHabits(for: currentDate)
            
            if !scheduledHabits.isEmpty {
                // Count actual completed habits instead of using floating point calculation
                let actualCompletedCount = scheduledHabits.filter { completedHabits.contains($0.id) }.count
                dayOfWeekStats[dayOfWeek]?.completed += actualCompletedCount
                dayOfWeekStats[dayOfWeek]?.total += scheduledHabits.count
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        // Use proper week ordering respecting user's week start preference
        let orderedWeekdaySymbols = DateUtils.orderedWeekdaySymbols(style: .standalone)
        var dayPerformances: [DayOfWeekPerformanceResult] = []
        var bestDayRate = 0.0
        var worstDayRate = 1.0
        var bestDay = orderedWeekdaySymbols.first ?? "Monday"
        var worstDay = orderedWeekdaySymbols.first ?? "Monday"
        
        // Process days in user's preferred order
        for (index, dayName) in orderedWeekdaySymbols.enumerated() {
            // Convert back to Calendar weekday (1=Sunday, 2=Monday, etc.)
            let startIndex = calendar.firstWeekday - 1
            let calendarWeekday = ((index + startIndex) % 7) + 1
            
            let stats = dayOfWeekStats[calendarWeekday] ?? (completed: 0, total: 0)
            let rate = stats.total > 0 ? Double(stats.completed) / Double(stats.total) : 0.0
            
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
    /// Uses existing PerformanceAnalysisService for system-wide streak calculation
    func extractStreakAnalysis(from dashboardData: DashboardData) -> StreakAnalysisViewModel? {
        let habits = dashboardData.habits
        let dateRange = dashboardData.dateRange
        guard !habits.isEmpty else { return nil }
        
        // Flatten habitLogs for service call
        let allLogs = dashboardData.habitLogs.values.flatMap { $0 }
        
        // Use existing service for proper streak analysis
        let streakAnalysisResult = performanceAnalysisService.calculateStreakAnalysis(
            habits: habits,
            logs: allLogs,
            from: dateRange.lowerBound,
            to: dateRange.upperBound
        )
        
        return StreakAnalysisViewModel(from: streakAnalysisResult)
    }
    
    /// Extract category breakdown from unified dashboard data
    /// Uses pre-calculated data without additional queries
    func extractCategoryBreakdown(from dashboardData: DashboardData) -> [CategoryPerformanceViewModel] {
        let domainResults = dashboardData.categoryPerformanceData()
        return domainResults.map(CategoryPerformanceViewModel.init)
    }
    
    /// Example method showing proper UseCase usage for single habit queries
    /// Uses the new GetSingleHabitLogsUseCase with optimized batch loading
    func getLogsForSpecificHabit(_ habitId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog] {
        return try await getSingleHabitLogs.execute(for: habitId, from: startDate, to: endDate)
    }
}
