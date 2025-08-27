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
        public let isDataSufficient: Bool
        public let thresholdRequirements: [ThresholdRequirement]
        
        init(from domain: WeeklyPatternsResult, daysWithData: Int, averageRate: Double, habitCount: Int, timePeriod: TimePeriod) {
            self.dayOfWeekPerformance = domain.dayOfWeekPerformance.map(DayOfWeekPerformanceViewModel.init)
            self.bestDay = domain.bestDay
            self.worstDay = domain.worstDay
            self.averageWeeklyCompletion = domain.averageWeeklyCompletion
            
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
        private static func calculateMinDaysRequired(for timePeriod: TimePeriod) -> Int {
            switch timePeriod {
            case .thisWeek:
                return 5  // Need at least 5 days for weekly patterns
            case .thisMonth:
                return 14 // Need 2 weeks for reliable patterns
            case .last6Months, .lastYear, .allTime:
                return 30 // Need more data for longer periods
            }
        }
        
        /// Get period-appropriate tracking title
        private static func getTrackingTitle(for timePeriod: TimePeriod) -> String {
            switch timePeriod {
            case .thisWeek:
                return "Track for 5 days"
            case .thisMonth:
                return "Track for 2 weeks"
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
            print("Failed to load dashboard data: \(error)")
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
        return isScheduledDay.execute(habit: habit, date: date)
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
