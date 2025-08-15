import Foundation

/// Domain service responsible for performance analysis and calculations
public protocol PerformanceAnalysisService {
    
    /// Calculate habit performance results from habits and logs
    func calculateHabitPerformance(
        habits: [Habit], 
        logs: [HabitLog], 
        from startDate: Date, 
        to endDate: Date
    ) -> [HabitPerformanceResult]
    
    /// Generate progress chart data from completion stats over time
    func generateProgressChartData(
        completionStats: [Date: HabitCompletionStats]
    ) -> [ProgressChartDataPoint]
    
    /// Analyze weekly patterns from habits and logs
    func analyzeWeeklyPatterns(
        habits: [Habit], 
        logs: [HabitLog], 
        from startDate: Date, 
        to endDate: Date
    ) -> WeeklyPatternsResult
    
    /// Calculate streak analysis from habits and logs
    func calculateStreakAnalysis(
        habits: [Habit], 
        logs: [HabitLog], 
        from startDate: Date, 
        to endDate: Date
    ) -> StreakAnalysisResult
    
    /// Aggregate category performance from habits, categories, and logs
    func aggregateCategoryPerformance(
        habits: [Habit], 
        categories: [Category], 
        logs: [HabitLog], 
        from startDate: Date, 
        to endDate: Date
    ) -> [CategoryPerformanceResult]
}