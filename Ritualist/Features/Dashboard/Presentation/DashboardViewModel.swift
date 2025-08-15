import SwiftUI
import Foundation
import FactoryKit
import RitualistCore

// swiftlint:disable type_body_length
@MainActor
@Observable
public final class DashboardViewModel {
    public var selectedTimePeriod: TimePeriod = .thisMonth {
        didSet {
            if oldValue != selectedTimePeriod {
                Task {
                    await loadData()
                }
            }
        }
    }
    public var completionStats: HabitCompletionStats?
    public var habitPerformanceData: [HabitPerformanceViewModel]?
    public var progressChartData: [ChartDataPointViewModel]?
    public var weeklyPatterns: WeeklyPatternsViewModel?
    public var streakAnalysis: StreakAnalysisViewModel?
    public var categoryBreakdown: [CategoryPerformanceViewModel]?
    public var isLoading = false
    public var error: Error?
    
    @ObservationIgnored @Injected(\.habitAnalyticsService) internal var habitAnalyticsService
    @ObservationIgnored @Injected(\.userService) internal var userService
    @ObservationIgnored @Injected(\.getBatchLogs) internal var getBatchLogs
    @ObservationIgnored @Injected(\.getSingleHabitLogs) internal var getSingleHabitLogs
    @ObservationIgnored @Injected(\.getAllCategories) internal var getAllCategories
    @ObservationIgnored @Injected(\.calculateCurrentStreak) internal var calculateCurrentStreak
    @ObservationIgnored @Injected(\.habitScheduleAnalyzer) internal var scheduleAnalyzer
    @ObservationIgnored @Injected(\.performanceAnalysisService) internal var performanceAnalysisService
    
    internal var userId: UUID { 
        userService.currentProfile.id 
    }
    
    public init() {}
    
    // MARK: - Data Models
    
    // MARK: - Presentation Models
    
    /// UI-specific model for habit performance display
    public struct HabitPerformanceViewModel: Identifiable {
        public let id: UUID
        public let name: String
        public let emoji: String
        public let completionRate: Double
        public let completedDays: Int
        public let expectedDays: Int
        
        init(from domain: HabitPerformanceResult) {
            self.id = domain.habitId
            self.name = domain.habitName
            self.emoji = domain.emoji
            self.completionRate = domain.completionRate
            self.completedDays = domain.completedDays
            self.expectedDays = domain.expectedDays
        }
    }
    
    /// UI-specific model for chart data display
    public struct ChartDataPointViewModel: Identifiable {
        public let id = UUID()
        public let date: Date
        public let completionRate: Double
        
        init(from domain: ProgressChartDataPoint) {
            self.date = domain.date
            self.completionRate = domain.completionRate
        }
    }
    
    /// UI-specific model for weekly patterns display
    public struct WeeklyPatternsViewModel {
        public let dayOfWeekPerformance: [DayOfWeekPerformanceViewModel]
        public let bestDay: String
        public let worstDay: String
        public let averageWeeklyCompletion: Double
        
        init(from domain: WeeklyPatternsResult) {
            self.dayOfWeekPerformance = domain.dayOfWeekPerformance.map(DayOfWeekPerformanceViewModel.init)
            self.bestDay = domain.bestDay
            self.worstDay = domain.worstDay
            self.averageWeeklyCompletion = domain.averageWeeklyCompletion
        }
    }
    
    /// UI-specific model for day of week performance display
    public struct DayOfWeekPerformanceViewModel: Identifiable {
        public let id: String
        public let dayName: String
        public let completionRate: Double
        public let averageHabitsCompleted: Int
        
        init(from domain: DayOfWeekPerformanceResult) {
            self.id = domain.dayName
            self.dayName = domain.dayName
            self.completionRate = domain.completionRate
            self.averageHabitsCompleted = domain.averageHabitsCompleted
        }
    }
    
    /// UI-specific model for streak analysis display
    public struct StreakAnalysisViewModel {
        public let currentStreak: Int
        public let longestStreak: Int
        public let streakTrend: String
        public let daysWithFullCompletion: Int
        public let consistencyScore: Double
        
        init(from domain: StreakAnalysisResult) {
            self.currentStreak = domain.currentStreak
            self.longestStreak = domain.longestStreak
            self.streakTrend = domain.streakTrend
            self.daysWithFullCompletion = domain.daysWithFullCompletion
            self.consistencyScore = domain.consistencyScore
        }
    }
    
    /// UI-specific model for category performance display
    public struct CategoryPerformanceViewModel: Identifiable {
        public let id: String
        public let categoryName: String
        public let completionRate: Double
        public let habitCount: Int
        public let color: String
        public let emoji: String?
        
        init(from domain: CategoryPerformanceResult) {
            self.id = domain.categoryId
            self.categoryName = domain.categoryName
            self.completionRate = domain.completionRate
            self.habitCount = domain.habitCount
            self.color = domain.color
            self.emoji = domain.emoji
        }
    }
    
    // MARK: - Public Methods
    
    public func loadData() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            // PHASE 2: Unified data loading - reduces queries from 471+ to 3
            let dashboardData = try await loadUnifiedDashboardData()
            
            // Extract all metrics from single source (no additional queries)
            if !dashboardData.habits.isEmpty {
                self.completionStats = extractCompletionStats(from: dashboardData)
                self.habitPerformanceData = extractHabitPerformanceData(from: dashboardData)
                self.progressChartData = extractProgressChartData(from: dashboardData)
                self.weeklyPatterns = extractWeeklyPatterns(from: dashboardData)
                self.streakAnalysis = extractStreakAnalysis(from: dashboardData)
                self.categoryBreakdown = extractCategoryBreakdown(from: dashboardData)
            } else {
                // No habits - set empty states
                self.completionStats = HabitCompletionStats(totalHabits: 0, completedHabits: 0, completionRate: 0.0)
                self.habitPerformanceData = []
                self.progressChartData = []
                self.weeklyPatterns = nil
                self.streakAnalysis = nil
                self.categoryBreakdown = []
            }
            
        } catch {
            self.error = error
            print("Failed to load dashboard data: \(error)")
        }
        
        self.isLoading = false
    }
    
    public func refresh() async {
        await loadData()
    }
    
}
// swiftlint:enable type_body_length
