import SwiftUI
import Foundation
import FactoryKit
import RitualistCore

@MainActor
@Observable
public final class StatsViewModel {
    public var selectedTimePeriod: TimePeriod = .thisWeek {
        didSet {
            if oldValue != selectedTimePeriod {
                // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                Task { @MainActor in
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
    @ObservationIgnored var hasLoadedInitialData = false

    /// Track if a refresh was requested while a load was in progress
    /// When true, performLoad() will re-run after current load completes
    @ObservationIgnored var needsRefreshAfterLoad = false

    /// Track view visibility for tab switch detection
    public var isViewVisible: Bool = false

    /// Track if view has disappeared at least once (to distinguish initial appear from tab switch)
    @ObservationIgnored var viewHasDisappearedOnce = false

    @ObservationIgnored @Injected(\.getActiveHabits) internal var getActiveHabits
    @ObservationIgnored @Injected(\.calculateStreakAnalysis) internal var calculateStreakAnalysis
    @ObservationIgnored @Injected(\.getBatchLogs) internal var getBatchLogs
    @ObservationIgnored @Injected(\.getSingleHabitLogs) internal var getSingleHabitLogs
    @ObservationIgnored @Injected(\.getAllCategories) internal var getAllCategories
    @ObservationIgnored @Injected(\.habitScheduleAnalyzer) internal var scheduleAnalyzer
    @ObservationIgnored @Injected(\.isHabitCompleted) internal var isHabitCompleted
    @ObservationIgnored @Injected(\.calculateDailyProgress) internal var calculateDailyProgress
    @ObservationIgnored @Injected(\.isScheduledDay) internal var isScheduledDay
    @ObservationIgnored @Injected(\.validateHabitSchedule) var validateHabitScheduleUseCase
    @ObservationIgnored @Injected(\.timezoneService) var timezoneService
    @ObservationIgnored @Injected(\.getConsistencyHeatmapData) var getConsistencyHeatmapData
    @ObservationIgnored @Injected(\.userDefaultsService) var userDefaults
    @ObservationIgnored @Injected(\.navigationService) var navigationService

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
    
    // MARK: - Public Methods

    /// Check if this is a tab switch (view returning after having left)
    /// Returns false on initial appear, true on subsequent appears after disappearing
    public var isReturningFromTabSwitch: Bool {
        viewHasDisappearedOnce
    }
}
