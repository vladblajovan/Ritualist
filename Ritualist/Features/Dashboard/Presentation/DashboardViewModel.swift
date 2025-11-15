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
    
    @ObservationIgnored @Injected(\.getActiveHabits) internal var getActiveHabits
    @ObservationIgnored @Injected(\.calculateStreakAnalysis) internal var calculateStreakAnalysis
    @ObservationIgnored @Injected(\.getBatchLogs) internal var getBatchLogs
    @ObservationIgnored @Injected(\.getSingleHabitLogs) internal var getSingleHabitLogs
    @ObservationIgnored @Injected(\.getAllCategories) internal var getAllCategories
    @ObservationIgnored @Injected(\.habitScheduleAnalyzer) internal var scheduleAnalyzer
    @ObservationIgnored @Injected(\.isHabitCompleted) internal var isHabitCompleted
    @ObservationIgnored @Injected(\.calculateDailyProgress) internal var calculateDailyProgress
    @ObservationIgnored @Injected(\.isScheduledDay) internal var isScheduledDay
    @ObservationIgnored @Injected(\.validateHabitSchedule) private var validateHabitScheduleUseCase

    private let logger: DebugLogger

    public init(logger: DebugLogger) {
        self.logger = logger
    }
    
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
        public let bestDayCompletionRate: Double
        public let worstDayCompletionRate: Double
        public let averageWeeklyCompletion: Double
        public let isDataSufficient: Bool
        public let isOptimizationMeaningful: Bool
        public let optimizationMessage: String
        public let thresholdRequirements: [ThresholdRequirement]

        // MARK: - Constants

        /// Minimum performance gap (15%) required for meaningful optimization suggestions
        private static let minimumMeaningfulPerformanceGap: Double = 0.15

        /// Near-perfect completion threshold (95%) - beyond this, optimization suggestions aren't needed
        private static let nearPerfectCompletionThreshold: Double = 0.95

        init(from domain: WeeklyPatternsResult, daysWithData: Int, averageRate: Double, habitCount: Int, timePeriod: TimePeriod) {
            self.dayOfWeekPerformance = domain.dayOfWeekPerformance.map(DayOfWeekPerformanceViewModel.init)
            self.bestDay = domain.bestDay
            self.worstDay = domain.worstDay
            self.averageWeeklyCompletion = domain.averageWeeklyCompletion

            // Calculate best/worst day completion rates (Fix #2: Performance)
            self.bestDayCompletionRate = domain.dayOfWeekPerformance.first { $0.dayName == domain.bestDay }?.completionRate ?? 0
            self.worstDayCompletionRate = domain.dayOfWeekPerformance.first { $0.dayName == domain.worstDay }?.completionRate ?? 0

            // Calculate period-aware data quality requirements
            let minDaysRequired = Self.calculateMinDaysRequired(for: timePeriod)
            let minCompletionRate = 0.3
            let minHabitsRequired = 2
            // Only calculate spread from days with actual data (not 0%)
            let daysWithPerformanceData = domain.dayOfWeekPerformance.filter { $0.completionRate > 0 }
            let performanceSpread = daysWithPerformanceData.isEmpty ? 0.0 :
                (daysWithPerformanceData.max(by: { $0.completionRate < $1.completionRate })?.completionRate ?? 0) -
                (daysWithPerformanceData.min(by: { $0.completionRate < $1.completionRate })?.completionRate ?? 0)

            let hasEnoughDays = daysWithData >= minDaysRequired
            let hasEnoughCompletion = averageRate >= minCompletionRate
            let hasEnoughHabits = habitCount >= minHabitsRequired
            let hasVariation = performanceSpread > 0.1

            self.isDataSufficient = hasEnoughDays && hasEnoughCompletion && hasEnoughHabits && hasVariation

            // Fix #3: Validation - Check if optimization is meaningful
            let performanceGap = self.bestDayCompletionRate - self.worstDayCompletionRate
            let hasMeaningfulGap = performanceGap >= Self.minimumMeaningfulPerformanceGap
            let bestDayNotPerfect = self.bestDayCompletionRate < Self.nearPerfectCompletionThreshold
            self.isOptimizationMeaningful = self.isDataSufficient && hasMeaningfulGap && bestDayNotPerfect

            // Fix #4: Smart messaging based on actual performance
            if !self.isOptimizationMeaningful {
                if !hasMeaningfulGap {
                    self.optimizationMessage = "Great! Your performance is consistent across all days"
                } else if !bestDayNotPerfect {
                    self.optimizationMessage = "Excellent! You're completing nearly all habits every day"
                } else {
                    self.optimizationMessage = "Keep building your tracking habit"
                }
            } else {
                let gapPercentage = Int(performanceGap * 100)
                self.optimizationMessage = "Try scheduling more habits on \(domain.bestDay) (performs \(gapPercentage)% better than \(domain.worstDay))"
            }
            
            // Build requirements list
            var requirements: [ThresholdRequirement] = []
            
            requirements.append(ThresholdRequirement(
                title: Self.getTrackingTitle(for: timePeriod),
                description: "Need consistent tracking data",
                current: daysWithData,
                target: minDaysRequired,
                isMet: hasEnoughDays,
                unit: "days"
            ))
            
            requirements.append(ThresholdRequirement(
                title: "30% completion rate",
                description: "Need regular habit completion",
                current: Int(averageRate * 100),
                target: Int(minCompletionRate * 100),
                isMet: hasEnoughCompletion,
                unit: "%"
            ))
            
            requirements.append(ThresholdRequirement(
                title: "Multiple active habits",
                description: "Need variety for optimization",
                current: habitCount,
                target: minHabitsRequired,
                isMet: hasEnoughHabits,
                unit: "habits"
            ))
            
            requirements.append(ThresholdRequirement(
                title: "Performance variation",
                description: "Need different completion rates across days",
                current: Int(performanceSpread * 100),
                target: 10,
                isMet: hasVariation,
                unit: "% spread"
            ))
            
            self.thresholdRequirements = requirements
        }
        
        // MARK: - Helper Methods
        
        /// Calculate minimum days required based on time period
        /// For current periods (thisWeek/thisMonth), uses elapsed days to ensure achievable targets
        /// For historical periods, uses fixed minimums since full period has passed
        private static func calculateMinDaysRequired(for timePeriod: TimePeriod) -> Int {
            let dateRange = timePeriod.dateRange
            let calendar = CalendarUtils.currentLocalCalendar

            switch timePeriod {
            case .thisWeek, .thisMonth:
                // Calculate days from start of period to now
                let startOfDay = calendar.startOfDay(for: dateRange.start)
                let endOfDay = calendar.startOfDay(for: dateRange.end)
                let elapsedDays = calendar.dateComponents([.day], from: startOfDay, to: endOfDay).day ?? 0

                // Use 70% of elapsed days as minimum requirement (allows for missed days)
                // But at least 3 days for meaningful pattern detection
                let minRequired = max(3, Int(Double(elapsedDays) * 0.7))

                return minRequired

            case .last6Months, .lastYear, .allTime:
                // Historical periods use fixed minimums since full period has passed
                return 30
            }
        }
        
        /// Get period-appropriate tracking title
        /// Shows dynamic requirements based on elapsed days for current periods
        private static func getTrackingTitle(for timePeriod: TimePeriod) -> String {
            let minDays = calculateMinDaysRequired(for: timePeriod)

            switch timePeriod {
            case .thisWeek, .thisMonth:
                // Dynamic title based on elapsed days
                return "Track for \(minDays) days"
            case .last6Months, .lastYear, .allTime:
                return "Track for 30 days"
            }
        }
    }
    
    /// Requirement for Schedule Optimization feature
    public struct ThresholdRequirement {
        public let title: String
        public let description: String
        public let current: Int
        public let target: Int
        public let isMet: Bool
        public let unit: String
        
        public var progressText: String {
            "\(current)/\(target) \(unit)"
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
                self.completionStats = nil
                self.habitPerformanceData = []
                self.progressChartData = []
                self.weeklyPatterns = nil
                self.streakAnalysis = nil
                self.categoryBreakdown = []
            }
        } catch {
            self.error = error
            logger.log("Failed to load dashboard data: \(error)", level: .error, category: .ui)
        }
        
        self.isLoading = false
    }
    
    public func refresh() async {
        await loadData()
    }
    
    // MARK: - Habit Completion Methods
    
    /// Check if a habit is completed on a specific date using IsHabitCompletedUseCase
    public func isHabitCompleted(_ habit: Habit, on date: Date) async -> Bool {
        do {
            let logs = try await getSingleHabitLogs.execute(for: habit.id, from: date, to: date)
            return isHabitCompleted.execute(habit: habit, on: date, logs: logs)
        } catch {
            return false
        }
    }
    
    /// Get progress for a habit on a specific date using CalculateDailyProgressUseCase
    public func getHabitProgress(_ habit: Habit, on date: Date) async -> Double {
        do {
            let logs = try await getSingleHabitLogs.execute(for: habit.id, from: date, to: date)
            return calculateDailyProgress.execute(habit: habit, logs: logs, for: date)
        } catch {
            return 0.0
        }
    }
    
    /// Check if a habit should be shown as actionable on a specific date using IsScheduledDayUseCase
    public func isHabitActionable(_ habit: Habit, on date: Date) -> Bool {
        isScheduledDay.execute(habit: habit, date: date)
    }
    
    /// Get schedule validation message for a habit on a specific date
    public func getScheduleValidationMessage(for habit: Habit, on date: Date) async -> String? {
        do {
            _ = try await validateHabitScheduleUseCase.execute(habit: habit, date: date)
            return nil // No validation errors
        } catch {
            return error.localizedDescription
        }
    }
}
// swiftlint:enable type_body_length
