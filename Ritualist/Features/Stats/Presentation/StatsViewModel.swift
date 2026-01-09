import SwiftUI
import Foundation
import FactoryKit
import RitualistCore

// MARK: - WeeklyPatterns Helper Types

/// Internal validation result for weekly patterns data quality checks
private struct WeeklyPatternsValidationResult {
    let isDataSufficient: Bool
    let isOptimizationMeaningful: Bool
    let isConsistentExcellence: Bool
    let isConsistentPerformance: Bool
    let optimizationMessage: String
    let requirements: [StatsViewModel.ThresholdRequirement]
}

/// Input for weekly patterns data quality validation
private struct WeeklyPatternsValidationInput {
    let domain: WeeklyPatternsResult
    let daysWithData: Int
    let averageRate: Double
    let habitCount: Int
    let timePeriod: TimePeriod
    let bestDayRate: Double
    let worstDayRate: Double
}

/// Input for building optimization messages
private struct WeeklyPatternsOptimizationMessageInput {
    let isOptimizationMeaningful: Bool
    let hasMeaningfulGap: Bool
    let bestDayNotPerfect: Bool
    let performanceGap: Double
    let bestDay: String
    let worstDay: String
}

/// Input for building threshold requirements list
private struct WeeklyPatternsRequirementsInput {
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

// swiftlint:disable type_body_length
@MainActor
@Observable
public final class StatsViewModel {
    public var selectedTimePeriod: TimePeriod = .thisWeek {
        didSet {
            if oldValue != selectedTimePeriod {
                Task {
                    await refresh()
                }
            }
        }
    }
    public var hasHabits = false
    public var habitPerformanceData: [HabitPerformanceViewModel]?
    public var progressChartData: [ChartDataPointViewModel]?
    public var weeklyPatterns: WeeklyPatternsViewModel?
    public var streakAnalysis: StreakAnalysisViewModel?
    public var categoryBreakdown: [CategoryPerformanceViewModel]?
    public var isLoading = false
    public var error: Error?

    // Consistency Heatmap
    public var allHabits: [Habit] = []
    public var selectedHeatmapHabit: Habit?
    public var heatmapData: ConsistencyHeatmapData?
    public var isLoadingHeatmap = false
    /// Pre-computed grid data for heatmap (memoized to avoid recalculation on every render)
    public var heatmapGridData: [[ConsistencyHeatmapViewLogic.CellData]] = []

    /// Track if initial data has been loaded to prevent duplicate loads during startup
    @ObservationIgnored private var hasLoadedInitialData = false

    /// Track if a refresh was requested while a load was in progress
    /// When true, performLoad() will re-run after current load completes
    @ObservationIgnored private var needsRefreshAfterLoad = false

    /// Track view visibility for tab switch detection
    public var isViewVisible: Bool = false

    /// Track if view has disappeared at least once (to distinguish initial appear from tab switch)
    @ObservationIgnored private var viewHasDisappearedOnce = false

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
    @ObservationIgnored @Injected(\.timezoneService) private var timezoneService
    @ObservationIgnored @Injected(\.getConsistencyHeatmapData) private var getConsistencyHeatmapData
    @ObservationIgnored @Injected(\.userDefaultsService) private var userDefaults

    /// Cached display timezone for synchronous access in computed properties.
    /// Fetched once on load from TimezoneService.getDisplayTimezone().
    /// NOT marked @ObservationIgnored - allows SwiftUI to observe direct changes.
    /// Currently, timezone changes trigger full reload via iCloudDidSyncRemoteChanges notification,
    /// but keeping this observable provides a safeguard for future direct timezone updates.
    internal var displayTimezone: TimeZone = .current

    internal let logger: DebugLogger

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
    
    // MARK: - Public Methods

    public func loadData() async {
        // Skip redundant loads after initial data is loaded
        guard !hasLoadedInitialData else {
            logger.log("Dashboard load skipped - data already loaded", level: .debug, category: .ui)
            return
        }

        await performLoad()
    }

    /// Force reload dashboard data (for pull-to-refresh, iCloud sync, etc.)
    public func refresh() async {
        // If a load is in progress, mark that we need to refresh after it completes
        // This handles the race condition where timezone changes during an ongoing load
        if isLoading {
            needsRefreshAfterLoad = true
            logger.log(
                "Dashboard load in progress - marking for refresh after current load completes",
                level: .info,
                category: .ui
            )
            return
        }

        hasLoadedInitialData = false
        await performLoad()
    }

    /// Invalidate cache when switching to this tab
    /// Ensures fresh data is loaded after changes made in other tabs
    public func invalidateCacheForTabSwitch() {
        if hasLoadedInitialData {
            logger.log("Dashboard cache invalidated for tab switch", level: .debug, category: .ui)
            hasLoadedInitialData = false
        }
    }

    /// Mark that the view has disappeared (called from onDisappear)
    public func markViewDisappeared() {
        viewHasDisappearedOnce = true
    }

    /// Check if this is a tab switch (view returning after having left)
    /// Returns false on initial appear, true on subsequent appears after disappearing
    public var isReturningFromTabSwitch: Bool {
        viewHasDisappearedOnce
    }

    /// Set view visibility state
    public func setViewVisible(_ visible: Bool) {
        isViewVisible = visible
    }

    /// Internal load implementation
    private func performLoad() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            // Fetch display timezone from TimezoneService for all time-based calculations
            displayTimezone = (try? await timezoneService.getDisplayTimezone()) ?? .current
            logger.log(
                "Display timezone loaded for Dashboard",
                level: .debug,
                category: .ui,
                metadata: ["timezone": displayTimezone.identifier]
            )

            // PHASE 2: Unified data loading - reduces queries from 471+ to 3
            let dashboardData = try await loadUnifiedDashboardData()

            // Extract all metrics from single source (no additional queries)
            self.allHabits = dashboardData.habits
            if !dashboardData.habits.isEmpty {
                self.hasHabits = true
                self.habitPerformanceData = extractHabitPerformanceData(from: dashboardData)
                self.progressChartData = extractProgressChartData(from: dashboardData)
                self.weeklyPatterns = extractWeeklyPatterns(from: dashboardData)
                self.streakAnalysis = extractStreakAnalysis(from: dashboardData)
                self.categoryBreakdown = extractCategoryBreakdown(from: dashboardData)
            } else {
                // No habits - set empty states
                self.hasHabits = false
                self.habitPerformanceData = []
                self.progressChartData = []
                self.weeklyPatterns = nil
                self.streakAnalysis = nil
                self.categoryBreakdown = []
            }

            // Initialize or reload heatmap selection
            await initializeHeatmapSelection()

            hasLoadedInitialData = true
        } catch {
            self.error = error
            logger.log("Failed to load dashboard data: \(error)", level: .error, category: .ui)
        }

        self.isLoading = false

        // Check if a refresh was requested while we were loading
        // This handles the race condition where timezone changes during an ongoing load
        if needsRefreshAfterLoad {
            needsRefreshAfterLoad = false
            logger.log(
                "Processing pending Dashboard refresh that was requested during load",
                level: .info,
                category: .ui
            )
            hasLoadedInitialData = false
            await performLoad()
        }
    }
    
    // MARK: - Habit Completion Methods

    /// Check if a habit is completed on a specific date using IsHabitCompletedUseCase
    public func isHabitCompleted(_ habit: Habit, on date: Date) async -> Bool {
        do {
            let logs = try await getSingleHabitLogs.execute(for: habit.id, from: date, to: date)
            return isHabitCompleted.execute(habit: habit, on: date, logs: logs, timezone: displayTimezone)
        } catch {
            logger.log(
                "Failed to check habit completion",
                level: .error,
                category: .dataIntegrity,
                metadata: ["habit_id": habit.id.uuidString, "error": error.localizedDescription]
            )
            return false
        }
    }

    /// Get progress for a habit on a specific date using CalculateDailyProgressUseCase
    public func getHabitProgress(_ habit: Habit, on date: Date) async -> Double {
        do {
            let logs = try await getSingleHabitLogs.execute(for: habit.id, from: date, to: date)
            return calculateDailyProgress.execute(habit: habit, logs: logs, for: date, timezone: displayTimezone)
        } catch {
            logger.log(
                "Failed to get habit progress",
                level: .error,
                category: .dataIntegrity,
                metadata: ["habit_id": habit.id.uuidString, "error": error.localizedDescription]
            )
            return 0.0
        }
    }

    /// Check if a habit should be shown as actionable on a specific date using IsScheduledDayUseCase
    public func isHabitActionable(_ habit: Habit, on date: Date) -> Bool {
        isScheduledDay.execute(habit: habit, date: date, timezone: displayTimezone)
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

    // MARK: - Consistency Heatmap

    /// Select a habit for heatmap display and load its data
    public func selectHeatmapHabit(_ habit: Habit) async {
        selectedHeatmapHabit = habit
        // Persist the selection
        userDefaults.set(habit.id.uuidString, forKey: UserDefaultsKeys.selectedHeatmapHabitId)
        await loadHeatmapData()
    }

    /// Initialize heatmap habit selection - restores saved selection or falls back to first habit
    private func initializeHeatmapSelection() async {
        guard !allHabits.isEmpty else { return }

        // Try to restore saved selection
        if let savedIdString = userDefaults.string(forKey: UserDefaultsKeys.selectedHeatmapHabitId),
           let savedId = UUID(uuidString: savedIdString),
           let savedHabit = allHabits.first(where: { $0.id == savedId }) {
            selectedHeatmapHabit = savedHabit
        } else {
            // Fall back to first habit
            selectedHeatmapHabit = allHabits.first
            // Persist the fallback selection
            if let firstHabit = allHabits.first {
                userDefaults.set(firstHabit.id.uuidString, forKey: UserDefaultsKeys.selectedHeatmapHabitId)
            }
        }

        await loadHeatmapData()
    }

    /// Load heatmap data for the currently selected habit
    public func loadHeatmapData() async {
        guard let habit = selectedHeatmapHabit else {
            heatmapData = nil
            heatmapGridData = []
            return
        }

        isLoadingHeatmap = true

        // Capture values locally to avoid data races in Swift 6
        let period = selectedTimePeriod
        let timezone = displayTimezone
        let habitId = habit.id

        do {
            let data = try await getConsistencyHeatmapData.execute(
                habitId: habitId,
                period: period,
                timezone: timezone
            )
            heatmapData = data

            // Pre-compute grid data (memoized - only recalculated when data changes)
            heatmapGridData = ConsistencyHeatmapViewLogic.buildGridData(
                from: data.dailyCompletions,
                period: period,
                timezone: timezone
            )
        } catch {
            logger.log(
                "Failed to load heatmap data",
                level: .error,
                category: .dataIntegrity,
                metadata: ["habit_id": habitId.uuidString, "error": error.localizedDescription]
            )
            heatmapData = nil
            heatmapGridData = []
        }

        isLoadingHeatmap = false
    }
}
// swiftlint:enable type_body_length
