import SwiftUI
import Foundation
import FactoryKit
import RitualistCore

// swiftlint:disable type_body_length
@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public var selectedTimePeriod: TimePeriod = .thisMonth {
        didSet {
            if oldValue != selectedTimePeriod {
                Task {
                    await loadData()
                }
            }
        }
    }
    @Published public var completionStats: HabitCompletionStats?
    @Published public var habitPerformanceData: [HabitPerformanceViewModel]?
    @Published public var progressChartData: [ChartDataPointViewModel]?
    @Published public var weeklyPatterns: WeeklyPatternsViewModel?
    @Published public var streakAnalysis: StreakAnalysisViewModel?
    @Published public var categoryBreakdown: [CategoryPerformanceViewModel]?
    @Published public var isLoading = false
    @Published public var error: Error?
    
    @Injected(\.habitAnalyticsService) internal var habitAnalyticsService
    @Injected(\.userService) internal var userService
    @Injected(\.calculateHabitPerformanceUseCase) private var calculateHabitPerformanceUseCase
    @Injected(\.generateProgressChartDataUseCase) private var generateProgressChartDataUseCase
    @Injected(\.analyzeWeeklyPatternsUseCase) private var analyzeWeeklyPatternsUseCase
    @Injected(\.calculateStreakAnalysisUseCase) private var calculateStreakAnalysisUseCase
    @Injected(\.aggregateCategoryPerformanceUseCase) private var aggregateCategoryPerformanceUseCase
    @Injected(\.getBatchLogs) internal var getBatchLogs
    
    internal var userId: UUID { 
        userService.currentProfile.id 
    }
    
    public init() {}
    
    // MARK: - Data Models
    
    public enum TimePeriod: CaseIterable {
        case thisWeek
        case thisMonth
        case last6Months
        case lastYear
        case allTime
        
        public var displayName: String {
            switch self {
            case .thisWeek: return Strings.Dashboard.thisWeek
            case .thisMonth: return Strings.Dashboard.thisMonth
            case .last6Months: return Strings.Dashboard.last6Months
            case .lastYear: return Strings.Dashboard.lastYear
            case .allTime: return Strings.Dashboard.allTime
            }
        }
        
        public var dateRange: (start: Date, end: Date) {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .thisWeek:
                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
                return (start: startOfWeek, end: now)
                
            case .thisMonth:
                let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
                return (start: startOfMonth, end: now)
                
            case .last6Months:
                let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now) ?? now
                return (start: sixMonthsAgo, end: now)
                
            case .lastYear:
                let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
                return (start: oneYearAgo, end: now)
                
            case .allTime:
                // Use a date far in the past to capture all available data
                let allTimeStart = calendar.date(byAdding: .year, value: -10, to: now) ?? now
                return (start: allTimeStart, end: now)
            }
        }
    }
    
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
    
    // MARK: - Private Methods
    
    private func loadHabitPerformanceData() async {
        do {
            let range = selectedTimePeriod.dateRange
            let results = try await calculateHabitPerformanceUseCase.execute(
                for: userId,
                from: range.start,
                to: range.end
            )
            
            let viewModels = results.map(HabitPerformanceViewModel.init)
            self.habitPerformanceData = viewModels
            
        } catch {
            print("Failed to load habit performance data: \(error)")
        }
    }
    
    private func loadProgressChartData() async {
        do {
            let range = selectedTimePeriod.dateRange
            let results = try await generateProgressChartDataUseCase.execute(
                for: userId,
                from: range.start,
                to: range.end
            )
            
            let viewModels = results.map(ChartDataPointViewModel.init)
            self.progressChartData = viewModels
            
        } catch {
            print("Failed to load progress chart data: \(error)")
        }
    }
    
    private func loadWeeklyPatterns() async {
        do {
            let range = selectedTimePeriod.dateRange
            let result = try await analyzeWeeklyPatternsUseCase.execute(
                for: userId,
                from: range.start,
                to: range.end
            )
            
            let viewModel = WeeklyPatternsViewModel(from: result)
            self.weeklyPatterns = viewModel
            
        } catch {
            print("Failed to load weekly patterns: \(error)")
        }
    }
    
    private func loadStreakAnalysis() async {
        do {
            let range = selectedTimePeriod.dateRange
            let result = try await calculateStreakAnalysisUseCase.execute(
                for: userId,
                from: range.start,
                to: range.end
            )
            
            let viewModel = StreakAnalysisViewModel(from: result)
            self.streakAnalysis = viewModel
            
        } catch {
            print("Failed to load streak analysis: \(error)")
        }
    }
    
    private func loadCategoryBreakdown() async {
        do {
            let range = selectedTimePeriod.dateRange
            let results = try await aggregateCategoryPerformanceUseCase.execute(
                for: userId,
                from: range.start,
                to: range.end
            )
            
            let viewModels = results.map(CategoryPerformanceViewModel.init)
            self.categoryBreakdown = viewModels
        } catch {
            print("Failed to load category breakdown: \(error)")
        }
    }
}
// swiftlint:enable type_body_length
