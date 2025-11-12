import Foundation
import RitualistCore

// MARK: - Debug Formatters
private extension DateFormatter {
    static let debugDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter
    }()
    
    static let weekdayName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
}
import FactoryKit

extension DashboardViewModel {
    
    /// Load unified dashboard data in a single batch operation
    /// Replaces 5 separate UseCase calls with 1 unified data load + extraction
    /// Expected to reduce queries from 471+ to 3 for annual views
    func loadUnifiedDashboardData() async throws -> DashboardData {
        let range = selectedTimePeriod.dateRange
        
        // PHASE 2: Single batch data loading (3 queries total)
        
        // 1. Single query for all active habits
        let habits = try await getActiveHabits.execute()
        
        // 2. Single query for all categories
        let categories = try await getAllCategories.execute()
        
        // 3. Single batch query for ALL habit logs in the entire date range
        let habitIds: [UUID] = habits.map { $0.id }
        let habitLogs = try await self.getBatchLogs.execute(
            for: habitIds,
            since: range.start,
            until: range.end
        )
        
        // Create unified data structure with pre-calculated daily completions using UseCases
        return DashboardData(
            habits: habits,
            categories: categories,
            habitLogs: habitLogs,
            dateRange: range.start...range.end,
            isHabitCompleted: self.isHabitCompleted,
            calculateDailyProgress: self.calculateDailyProgress,
            isScheduledDay: self.isScheduledDay
        )
    }
    
    // MARK: - Data Extraction Methods (Phase 4)
    
    /// Extract completion statistics from unified dashboard data
    /// Replaces initial service calls with efficient data extraction
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
        
        var currentDate = dateRange.lowerBound

        while currentDate <= dateRange.upperBound {
            let startOfDay = CalendarUtils.startOfDayLocal(for: currentDate)
            let scheduledHabits = dashboardData.scheduledHabits(for: startOfDay)
            let completionRate = dashboardData.completionRate(for: startOfDay)
            
            totalPossibleCompletions += scheduledHabits.count
            totalActualCompletions += Int(completionRate * Double(scheduledHabits.count))
            
            // Track habits that had any completions on this day
            if completionRate > 0 {
                let completedHabitsToday = dashboardData.completedHabits(for: startOfDay)
                habitsWithCompletions.formUnion(completedHabitsToday)
            }
            
            currentDate = CalendarUtils.addDays(1, to: currentDate)
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
        
        logPerfectDayPatternsStart(habits: habits, dateRange: dateRange)
        
        guard !habits.isEmpty else { 
            print("🔍 [DEBUG] No habits found - returning nil")
            return nil 
        }
        
        let calendar = CalendarUtils.currentLocalCalendar // Use system calendar with user's week start preference
        var dayOfWeekStats: [Int: (completed: Int, total: Int)] = [:]
        
        // Initialize stats for all days of week (1 = Sunday, 7 = Saturday)
        for dayNum in 1...7 {
            dayOfWeekStats[dayNum] = (completed: 0, total: 0)
        }
        
        // Analyze each day in the date range
        let (updatedStats, daysWithData) = analyzeDayByDayData(
            dashboardData: dashboardData,
            dateRange: dateRange,
            calendar: calendar,
            initialStats: dayOfWeekStats
        )
        dayOfWeekStats = updatedStats
        
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
        
        logPerfectDayPatternsResults(
            dayPerformances: dayPerformances,
            bestDay: bestDay,
            worstDay: worstDay,
            bestDayRate: bestDayRate,
            worstDayRate: worstDayRate,
            averageRate: averageRate,
            daysWithData: daysWithData,
            habitCount: habits.count
        )
        
        let weeklyPatternsResult = WeeklyPatternsResult(
            dayOfWeekPerformance: dayPerformances,
            bestDay: bestDay,
            worstDay: worstDay,
            averageWeeklyCompletion: averageRate
        )
        
        // Debug the performance spread calculation
        let performanceSpread = bestDayRate - worstDayRate
        print("🔍 [DEBUG] Performance spread calculation:")
        for performance in dayPerformances {
            print("🔍 [DEBUG] - \(performance.dayName): \(Int(performance.completionRate * 100))% completion rate")
        }
        print("🔍 [DEBUG] Performance spread: \(Int(performanceSpread * 100))% (best: \(Int(bestDayRate * 100))%, worst: \(Int(worstDayRate * 100))%)")
        
        print("🔍 [DEBUG] Schedule Optimization Analysis Complete ✅")
        
        return WeeklyPatternsViewModel(from: weeklyPatternsResult, daysWithData: daysWithData, averageRate: averageRate, habitCount: habits.count, timePeriod: self.selectedTimePeriod)
    }
    
    // MARK: - Debug Logging Helpers
    
    private func logPerfectDayPatternsStart(habits: [Habit], dateRange: ClosedRange<Date>) {
        print("🔍 [DEBUG] Perfect Day Patterns Analysis Starting...")
        print("🔍 [DEBUG] Date Range: \(DateFormatter.debugDate.string(from: dateRange.lowerBound)) to \(DateFormatter.debugDate.string(from: dateRange.upperBound))")
        print("🔍 [DEBUG] Total Habits: \(habits.count)")
        for habit in habits {
            print("🔍 [DEBUG] - \(habit.name) (Schedule: \(habit.schedule))")
        }
    }
    
    private func analyzeDayByDayData(
        dashboardData: DashboardData,
        dateRange: ClosedRange<Date>,
        calendar: Calendar,
        initialStats: [Int: (completed: Int, total: Int)]
    ) -> ([Int: (completed: Int, total: Int)], Int) {
        var dayOfWeekStats = initialStats
        var currentDate = dateRange.lowerBound
        var totalDaysAnalyzed = 0
        var daysWithData = 0
        
        print("🔍 [DEBUG] Starting day-by-day analysis...")
        
        while currentDate <= dateRange.upperBound {
            let dayOfWeek = calendar.component(.weekday, from: currentDate)
            let dayName = DateFormatter.weekdayName.string(from: currentDate)
            let scheduledHabits = dashboardData.scheduledHabits(for: currentDate)
            let completedHabits = dashboardData.completedHabits(for: currentDate)
            
            totalDaysAnalyzed += 1
            
            // Only count as "data day" if there are logs for this date (actual user activity)
            let hasLogsForDate = dashboardData.habitLogs.values.flatMap { $0 }.contains { log in
                CalendarUtils.areSameDayLocal(log.date, currentDate)
            }
            
            if !scheduledHabits.isEmpty && hasLogsForDate {
                daysWithData += 1
                let actualCompletedCount = scheduledHabits.filter { completedHabits.contains($0.id) }.count
                dayOfWeekStats[dayOfWeek]?.completed += actualCompletedCount
                dayOfWeekStats[dayOfWeek]?.total += scheduledHabits.count
                
                print("🔍 [DEBUG] \(DateFormatter.debugDate.string(from: currentDate)) (\(dayName)): \(actualCompletedCount)/\(scheduledHabits.count) habits completed")
                if actualCompletedCount != scheduledHabits.count {
                    let completedNames = scheduledHabits.filter { completedHabits.contains($0.id) }.map { $0.name }
                    let missedNames = scheduledHabits.filter { !completedHabits.contains($0.id) }.map { $0.name }
                    print("🔍 [DEBUG]   ✅ Completed: \(completedNames)")
                    print("🔍 [DEBUG]   ❌ Missed: \(missedNames)")
                }
            } else {
                print("🔍 [DEBUG] \(DateFormatter.debugDate.string(from: currentDate)) (\(dayName)): No habits scheduled")
            }
            
            currentDate = CalendarUtils.addDays(1, to: currentDate)
        }
        
        print("🔍 [DEBUG] Analysis complete: \(totalDaysAnalyzed) total days, \(daysWithData) days with scheduled habits")
        return (dayOfWeekStats, daysWithData)
    }
    
    private func logPerfectDayPatternsResults(
        dayPerformances: [DayOfWeekPerformanceResult],
        bestDay: String,
        worstDay: String,
        bestDayRate: Double,
        worstDayRate: Double,
        averageRate: Double,
        daysWithData: Int,
        habitCount: Int
    ) {
        print("🔍 [DEBUG] Day of Week Performance Summary:")
        for performance in dayPerformances {
            let percentage = Int(performance.completionRate * 100)
            print("🔍 [DEBUG] - \(performance.dayName): \(percentage)% (\(performance.averageHabitsCompleted) completed habits)")
        }
        
        print("🔍 [DEBUG] Results:")
        print("🔍 [DEBUG] - Best Day: \(bestDay) (\(Int(bestDayRate * 100))%)")
        print("🔍 [DEBUG] - Worst Day: \(worstDay) (\(Int(worstDayRate * 100))%)")
        print("🔍 [DEBUG] - Average Weekly Completion: \(Int(averageRate * 100))%")
        
        // Analysis for Schedule Optimization insights
        let performanceSpread = bestDayRate - worstDayRate
        let minDaysRequired = 14 // 2 weeks of data
        let minCompletionRate = 0.3 // At least 30% overall completion
        let minHabitsRequired = 2 // At least 2 habits for scheduling conflicts
        
        let hasEnoughDays = daysWithData >= minDaysRequired
        let hasEnoughCompletion = averageRate >= minCompletionRate
        let hasEnoughHabits = habitCount >= minHabitsRequired
        let hasVariation = performanceSpread > 0.1
        
        let isDataSufficientForScheduleOptimization = hasEnoughDays && hasEnoughCompletion && hasEnoughHabits && hasVariation
        
        print("🔍 [DEBUG] Schedule Optimization Data Quality Analysis:")
        print("🔍 [DEBUG] - Days with data: \(daysWithData) (need \(minDaysRequired)): \(hasEnoughDays ? "✅" : "❌")")
        print("🔍 [DEBUG] - Overall completion: \(Int(averageRate * 100))% (need \(Int(minCompletionRate * 100))%): \(hasEnoughCompletion ? "✅" : "❌")")
        print("🔍 [DEBUG] - Active habits: \(habitCount) (need \(minHabitsRequired)): \(hasEnoughHabits ? "✅" : "❌")")
        print("🔍 [DEBUG] - Performance variation: \(Int(performanceSpread * 100))% (need >10%): \(hasVariation ? "✅" : "❌")")
        print("🔍 [DEBUG] - Ready for Schedule Optimization? \(isDataSufficientForScheduleOptimization ? "YES" : "NO")")
        
        if !isDataSufficientForScheduleOptimization {
            var missingRequirements: [String] = []
            if !hasEnoughDays { missingRequirements.append("Need \(minDaysRequired - daysWithData) more days of tracking") }
            if !hasEnoughCompletion { missingRequirements.append("Need higher completion rate (\(Int(minCompletionRate * 100))%+ target)") }
            if !hasEnoughHabits { missingRequirements.append("Need \(minHabitsRequired - habitCount) more active habits") }
            if !hasVariation { missingRequirements.append("Need more variation in daily performance") }
            
            print("🔍 [DEBUG] ⚠️ Missing requirements:")
            for requirement in missingRequirements {
                print("🔍 [DEBUG]   - \(requirement)")
            }
        }
    }
    
    /// Extract streak analysis from unified dashboard data
    /// Uses existing CalculateStreakAnalysisUseCase for system-wide streak calculation
    func extractStreakAnalysis(from dashboardData: DashboardData) -> StreakAnalysisViewModel? {
        let habits = dashboardData.habits
        let dateRange = dashboardData.dateRange
        guard !habits.isEmpty else { return nil }
        
        // Flatten habitLogs for service call
        let allLogs = dashboardData.habitLogs.values.flatMap { $0 }
        
        // Use existing UseCase for proper streak analysis
        let streakAnalysisResult = calculateStreakAnalysis.execute(
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
        try await getSingleHabitLogs.execute(for: habitId, from: startDate, to: endDate)
    }
}
