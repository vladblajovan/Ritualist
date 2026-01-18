//
//  StatsViewModel+PresentationModels.swift
//  Ritualist
//
//  Presentation model types extracted from StatsViewModel to reduce type body length.
//

import SwiftUI
import RitualistCore

// MARK: - WeeklyPatterns Helper Types (File-private)

/// Internal validation result for weekly patterns data quality checks
struct WeeklyPatternsValidationResult {
    let isDataSufficient: Bool
    let isOptimizationMeaningful: Bool
    let isConsistentExcellence: Bool
    let isConsistentPerformance: Bool
    let optimizationMessage: String
    let requirements: [StatsViewModel.ThresholdRequirement]
}

/// Input for weekly patterns data quality validation
struct WeeklyPatternsValidationInput {
    let domain: WeeklyPatternsResult
    let daysWithData: Int
    let averageRate: Double
    let habitCount: Int
    let timePeriod: TimePeriod
    let bestDayRate: Double
    let worstDayRate: Double
}

/// Input for building optimization messages
struct WeeklyPatternsOptimizationMessageInput {
    let isOptimizationMeaningful: Bool
    let hasMeaningfulGap: Bool
    let bestDayNotPerfect: Bool
    let performanceGap: Double
    let bestDay: String
    let worstDay: String
}

/// Input for building threshold requirements list
struct WeeklyPatternsRequirementsInput {
    let timePeriod: TimePeriod
    let daysWithData: Int
    let minDaysRequired: Int
    let averageRate: Double
    let habitCount: Int
    let performanceSpread: Double
    let hasEnoughDays: Bool
    let hasEnoughCompletion: Bool
    let hasEnoughHabits: Bool
    let hasVariation: Bool
}

// MARK: - Presentation Models

extension StatsViewModel {

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

        /// Indicates excellent consistent performance across all days (no meaningful gap + near-perfect rates)
        public let isConsistentExcellence: Bool

        /// Indicates consistent performance without excellence (small gap but not near-perfect)
        public let isConsistentPerformance: Bool

        // MARK: - Constants

        /// Minimum performance gap (15%) required for meaningful optimization suggestions.
        ///
        /// **UX Reasoning:**
        /// Below 15%, the performance difference between best and worst days is too small to justify
        /// suggesting users reschedule their habits. This threshold prevents suggesting optimizations
        /// for statistically insignificant variations that could be due to:
        /// - Random day-to-day variance
        /// - External factors (work schedule, social commitments)
        /// - Small sample sizes
        ///
        /// A 15% gap represents a meaningful behavioral pattern worth addressing.
        private static let minimumMeaningfulPerformanceGap: Double = 0.15

        /// Near-perfect completion threshold (95%) - beyond this, optimization suggestions aren't needed.
        ///
        /// **UX Reasoning:**
        /// When users are completing 95%+ of their habits on their best day, they're already performing
        /// exceptionally well. Suggesting further optimization would be:
        /// - Unnecessary microoptimization
        /// - Potentially demotivating ("I'm at 96% and you still want me to improve?")
        /// - Ignoring the reality that 100% completion is unrealistic long-term
        ///
        /// At this level, we celebrate success rather than push for marginal gains.
        private static let nearPerfectCompletionThreshold: Double = 0.95

        /// Minimum completion rate (30%) required for schedule optimization insights.
        ///
        /// **Data Quality Reasoning:**
        /// Below 30%, users are struggling with basic habit consistency. Optimization suggestions
        /// would be premature - they need to focus on building the habit tracking practice first.
        /// This threshold ensures we only suggest optimizations when there's meaningful data.
        private static let minimumCompletionRateForOptimization: Double = 0.3

        /// Minimum number of habits required for meaningful schedule optimization analysis.
        private static let minimumHabitsRequired: Int = 2

        /// Minimum performance spread (10%) required to show optimization insights.
        ///
        /// **Data Quality Reasoning:**
        /// Below 10%, the difference between best and worst performing days is too small to
        /// provide meaningful optimization insights. This threshold ensures we have sufficient
        /// variation in the data to make useful recommendations. A 10% spread indicates that
        /// some days are clearly more successful than others, making schedule optimization valuable.
        private static let minimumPerformanceSpread: Double = 0.1

        init(from domain: WeeklyPatternsResult, daysWithData: Int, averageRate: Double, habitCount: Int, timePeriod: TimePeriod, logger: DebugLogger? = nil) {
            self.dayOfWeekPerformance = domain.dayOfWeekPerformance.map(DayOfWeekPerformanceViewModel.init)
            self.bestDay = domain.bestDay
            self.worstDay = domain.worstDay
            self.averageWeeklyCompletion = domain.averageWeeklyCompletion

            let rates = Self.extractCompletionRates(from: domain, logger: logger)
            self.bestDayCompletionRate = rates.best
            self.worstDayCompletionRate = rates.worst

            let validation = Self.validateDataQuality(input: WeeklyPatternsValidationInput(
                domain: domain, daysWithData: daysWithData, averageRate: averageRate,
                habitCount: habitCount, timePeriod: timePeriod,
                bestDayRate: rates.best, worstDayRate: rates.worst
            ))

            self.isDataSufficient = validation.isDataSufficient
            self.isOptimizationMeaningful = validation.isOptimizationMeaningful
            self.isConsistentExcellence = validation.isConsistentExcellence
            self.isConsistentPerformance = validation.isConsistentPerformance
            self.optimizationMessage = validation.optimizationMessage
            self.thresholdRequirements = validation.requirements
        }

        private static func extractCompletionRates(
            from domain: WeeklyPatternsResult,
            logger: DebugLogger?
        ) -> (best: Double, worst: Double) {
            let performanceByDay = Dictionary(
                uniqueKeysWithValues: domain.dayOfWeekPerformance.map { ($0.dayName, $0.completionRate) }
            )

            let bestRate = performanceByDay[domain.bestDay] ?? {
                logger?.log(
                    "Edge case: bestDay '\(domain.bestDay)' not found. Defaulting to 0.",
                    level: .warning, category: .dataIntegrity
                )
                return 0.0
            }()

            let worstRate = performanceByDay[domain.worstDay] ?? {
                logger?.log(
                    "Edge case: worstDay '\(domain.worstDay)' not found. Defaulting to 0.",
                    level: .warning, category: .dataIntegrity
                )
                return 0.0
            }()

            return (bestRate, worstRate)
        }

        private static func validateDataQuality(input: WeeklyPatternsValidationInput) -> WeeklyPatternsValidationResult {
            let domain = input.domain
            let daysWithData = input.daysWithData
            let averageRate = input.averageRate
            let habitCount = input.habitCount
            let timePeriod = input.timePeriod
            let bestDayRate = input.bestDayRate
            let worstDayRate = input.worstDayRate
            let minDaysRequired = calculateMinDaysRequired(for: timePeriod)
            let daysWithPerformanceData = domain.dayOfWeekPerformance.filter { $0.completionRate > 0 }
            let performanceSpread = daysWithPerformanceData.isEmpty ? 0.0 :
                (daysWithPerformanceData.max(by: { $0.completionRate < $1.completionRate })?.completionRate ?? 0) -
                (daysWithPerformanceData.min(by: { $0.completionRate < $1.completionRate })?.completionRate ?? 0)

            let hasEnoughDays = daysWithData >= minDaysRequired
            let hasEnoughCompletion = averageRate >= minimumCompletionRateForOptimization
            let hasEnoughHabits = habitCount >= minimumHabitsRequired
            let hasVariation = performanceSpread > minimumPerformanceSpread

            let isDataSufficient = hasEnoughDays && hasEnoughCompletion && hasEnoughHabits && hasVariation

            let performanceGap = bestDayRate - worstDayRate
            let hasMeaningfulGap = performanceGap >= minimumMeaningfulPerformanceGap
            let bestDayNotPerfect = bestDayRate < nearPerfectCompletionThreshold

            let isOptimizationMeaningful = isDataSufficient && hasMeaningfulGap && bestDayNotPerfect
            let isConsistentExcellence = !hasMeaningfulGap && !bestDayNotPerfect
            let isConsistentPerformance = !hasMeaningfulGap && bestDayNotPerfect

            let message = buildOptimizationMessage(input: WeeklyPatternsOptimizationMessageInput(
                isOptimizationMeaningful: isOptimizationMeaningful,
                hasMeaningfulGap: hasMeaningfulGap,
                bestDayNotPerfect: bestDayNotPerfect,
                performanceGap: performanceGap,
                bestDay: domain.bestDay,
                worstDay: domain.worstDay
            ))

            let requirements = buildRequirements(from: WeeklyPatternsRequirementsInput(
                timePeriod: timePeriod, daysWithData: daysWithData, minDaysRequired: minDaysRequired,
                averageRate: averageRate, habitCount: habitCount, performanceSpread: performanceSpread,
                hasEnoughDays: hasEnoughDays, hasEnoughCompletion: hasEnoughCompletion,
                hasEnoughHabits: hasEnoughHabits, hasVariation: hasVariation
            ))

            return WeeklyPatternsValidationResult(
                isDataSufficient: isDataSufficient,
                isOptimizationMeaningful: isOptimizationMeaningful,
                isConsistentExcellence: isConsistentExcellence,
                isConsistentPerformance: isConsistentPerformance,
                optimizationMessage: message,
                requirements: requirements
            )
        }

        private static func buildOptimizationMessage(input: WeeklyPatternsOptimizationMessageInput) -> String {
            guard input.isOptimizationMeaningful else {
                if !input.hasMeaningfulGap {
                    return Strings.Dashboard.optimizationConsistentPerformance
                } else if !input.bestDayNotPerfect {
                    return Strings.Dashboard.optimizationNearPerfect
                } else {
                    return Strings.Dashboard.optimizationKeepBuilding
                }
            }
            return String(format: Strings.Dashboard.optimizationSuggestion, input.bestDay, Int(input.performanceGap * 100), input.worstDay)
        }

        private static func buildRequirements(from input: WeeklyPatternsRequirementsInput) -> [ThresholdRequirement] {
            [
                ThresholdRequirement(
                    title: getTrackingTitle(for: input.timePeriod),
                    description: "Need consistent tracking data",
                    current: input.daysWithData, target: input.minDaysRequired,
                    isMet: input.hasEnoughDays, unit: "days"
                ),
                ThresholdRequirement(
                    title: "30% completion rate",
                    description: "Need regular habit completion",
                    current: Int(input.averageRate * 100), target: Int(minimumCompletionRateForOptimization * 100),
                    isMet: input.hasEnoughCompletion, unit: "%"
                ),
                ThresholdRequirement(
                    title: "Multiple active habits",
                    description: "Need variety for optimization",
                    current: input.habitCount, target: minimumHabitsRequired,
                    isMet: input.hasEnoughHabits, unit: "habits"
                ),
                ThresholdRequirement(
                    title: "Performance variation",
                    description: "Need different completion rates across days",
                    current: Int(input.performanceSpread * 100), target: 10,
                    isMet: input.hasVariation, unit: "% spread"
                )
            ]
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

    /// Requirement for Habit Patterns feature
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

        public var progress: CGFloat {
            guard target > 0 else { return 0 }
            return min(CGFloat(current) / CGFloat(target), 1.0)
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
}
