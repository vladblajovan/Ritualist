//
//  StatsViewModel+Helpers.swift
//  Ritualist
//
//  Helper methods extracted from StatsViewModel to reduce type body length.
//

import Foundation
import RitualistCore

// MARK: - Data Loading Methods

extension StatsViewModel {

    /// Load dashboard data (skips if already loaded).
    public func loadData() async {
        // Skip redundant loads after initial data is loaded
        guard !hasLoadedInitialData else {
            logger.log("Dashboard load skipped - data already loaded", level: .debug, category: .ui)
            return
        }

        await performLoad()
    }

    /// Force reload dashboard data (for pull-to-refresh, iCloud sync, etc.).
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

    /// Internal load implementation.
    func performLoad() async {
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
}

// MARK: - Habit Completion Methods

extension StatsViewModel {

    /// Check if a habit is completed on a specific date using IsHabitCompletedUseCase.
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

    /// Get progress for a habit on a specific date using CalculateDailyProgressUseCase.
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

    /// Check if a habit should be shown as actionable on a specific date using IsScheduledDayUseCase.
    public func isHabitActionable(_ habit: Habit, on date: Date) -> Bool {
        isScheduledDay.execute(habit: habit, date: date, timezone: displayTimezone)
    }

    /// Get schedule validation message for a habit on a specific date.
    public func getScheduleValidationMessage(for habit: Habit, on date: Date) async -> String? {
        do {
            _ = try await validateHabitScheduleUseCase.execute(habit: habit, date: date)
            return nil // No validation errors
        } catch {
            return error.localizedDescription
        }
    }
}

// MARK: - View Lifecycle & Navigation Methods

extension StatsViewModel {

    /// Invalidate cache when switching to this tab.
    /// Ensures fresh data is loaded after changes made in other tabs.
    public func invalidateCacheForTabSwitch() {
        if hasLoadedInitialData {
            logger.log("Dashboard cache invalidated for tab switch", level: .debug, category: .ui)
            hasLoadedInitialData = false
        }
    }

    /// Mark that the view has disappeared (called from onDisappear).
    public func markViewDisappeared() {
        viewHasDisappearedOnce = true
    }

    /// Set view visibility state.
    public func setViewVisible(_ visible: Bool) {
        isViewVisible = visible
    }

    /// Navigate to the habits list filtered by a specific category.
    /// - Parameter categoryId: The ID of the category to filter by
    public func navigateToCategory(_ categoryId: String) {
        HapticFeedbackService.shared.trigger(.light)
        navigationService.navigateToHabits(withCategoryId: categoryId)
    }
}

// MARK: - Consistency Heatmap Methods

extension StatsViewModel {

    /// Select a habit for heatmap display and load its data.
    public func selectHeatmapHabit(_ habit: Habit) async {
        selectedHeatmapHabit = habit
        // Persist the selection
        userDefaults.set(habit.id.uuidString, forKey: UserDefaultsKeys.selectedHeatmapHabitId)
        await loadHeatmapData()
    }

    /// Initialize heatmap habit selection - restores saved selection or falls back to first habit.
    func initializeHeatmapSelection() async {
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

    /// Load heatmap data for the currently selected habit.
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
