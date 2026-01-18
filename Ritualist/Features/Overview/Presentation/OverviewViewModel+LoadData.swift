//
//  OverviewViewModel+LoadData.swift
//  Ritualist
//
//  Data loading methods extracted from OverviewViewModel to reduce function and type body length.
//

import Foundation
import RitualistCore

// MARK: - Data Loading Methods

extension OverviewViewModel {

    /// Main data loading entry point - coordinates all loading steps.
    /// This is the public method called by the view.
    public func loadData() async {
        // Early exit checks
        guard shouldProceedWithLoad() else { return }

        // Pre-load checks and setup
        performPreLoadChecks()

        // Check timezone changes
        let newTimezone = (try? await timezoneService.getDisplayTimezone()) ?? .current
        let timezoneChanged = displayTimezone.identifier != newTimezone.identifier

        // Skip redundant loads
        guard shouldLoadData(timezoneChanged: timezoneChanged) else { return }

        // Perform the actual load
        await performDataLoad(newTimezone: newTimezone, timezoneChanged: timezoneChanged)

        // Handle pending refresh requests
        await handlePendingRefresh()
    }

    /// Checks if load should proceed (not already loading, not migrating).
    func shouldProceedWithLoad() -> Bool {
        // Prevent duplicate loads while one is already in progress
        guard !isLoading else {
            logger.logStateTransition(
                from: "loading_blocked",
                to: "already_loading",
                context: ["reason": "Preventing duplicate load, will check needsRefreshAfterLoad"]
            )
            return false
        }

        // MIGRATION GUARD: Check migration state on first load
        if !hasLoadedInitialData && getMigrationStatus.isMigrating {
            logger.logStateTransition(
                from: "initial_load_deferred",
                to: "migration_in_progress",
                context: ["reason": "Waiting for migration completion"]
            )
            wasMigrating = true
            return false
        }

        return true
    }

    /// Performs pre-load checks like day change and migration cache invalidation.
    func performPreLoadChecks() {
        // DAY CHANGE CHECK: Reset dismissed triggers if midnight passed while app was open
        inspirationVM.resetDismissedTriggersIfNewDay()

        // MIGRATION CHECK: Detect completion and invalidate cache if needed
        if checkMigrationAndInvalidateCache() {
            logger.logStateTransition(
                from: "migration_completed",
                to: "cache_invalidated",
                context: ["action": "Proceeding with fresh load"]
            )
        }
    }

    /// Checks if data should be loaded based on cache state and timezone changes.
    func shouldLoadData(timezoneChanged: Bool) -> Bool {
        // Skip redundant loads after initial data is loaded
        // Allow loads if: cache is nil OR migration just completed OR timezone changed
        if hasLoadedInitialData && overviewData != nil && !timezoneChanged {
            logger.log(
                "Load skipped - data already loaded",
                level: .debug,
                category: .stateManagement,
                metadata: ["hint": "Use refresh() to force reload"]
            )
            return false
        }
        return true
    }

    /// Performs the main data loading operation.
    func performDataLoad(newTimezone: TimeZone, timezoneChanged: Bool) async {
        logger.logStateTransition(
            from: "idle",
            to: "loading",
            context: ["operation": "Full database reload"]
        )
        isLoading = true
        error = nil

        do {
            // Handle timezone updates and recalculate viewingDate if needed
            handleTimezoneAndViewingDate(newTimezone: newTimezone, timezoneChanged: timezoneChanged)

            // Cache user name for synchronous message generation
            let userName = await getUserName()

            // Load unified data once instead of multiple parallel operations
            let overviewData = try await loadOverviewData()
            logDataLoadSuccess(overviewData: overviewData)

            // Update state with loaded data
            updateStateWithLoadedData(overviewData: overviewData, userName: userName)

            // Post-load tasks
            await performPostLoadTasks(habitCount: overviewData.habits.count)
        } catch {
            handleLoadError(error)
        }

        isLoading = false
    }

    /// Logs successful data load with metadata.
    private func logDataLoadSuccess(overviewData: OverviewData) {
        logger.log(
            "Data loaded successfully",
            level: .info,
            category: .stateManagement,
            metadata: [
                "habits_count": overviewData.habits.count,
                "logs_count": overviewData.habitLogs.values.flatMap { $0 }.count,
                "timezone": displayTimezone.identifier
            ]
        )
    }

    /// Updates all state properties with loaded data.
    func updateStateWithLoadedData(overviewData: OverviewData, userName: String?) {
        // Store the overview data and extract all card data from it using unified approach
        self.overviewData = overviewData
        self.hasLoadedInitialData = true
        self.hasEverLoadedData = true

        self.todaysSummary = extractTodaysSummary(from: overviewData)
        self.activeStreaks = extractActiveStreaks(from: overviewData)
        self.monthlyCompletionData = extractMonthlyData(from: overviewData)

        // Configure child VMs with context
        configureChildViewModels(userName: userName)
    }

    /// Performs post-load tasks like habit limit check and personality insights.
    func performPostLoadTasks(habitCount: Int) async {
        // Check if user is over the free tier habit limit
        await checkHabitLimitStatus(habitCount: habitCount)

        // Cancel any previous personality insights task to prevent Task storms
        personalityInsightsTask?.cancel()

        // Load personality insights separately (non-blocking)
        personalityInsightsTask = Task { @MainActor in
            guard !Task.isCancelled else { return }
            await personalityVM.loadPersonalityInsights()
        }

        // Check if we should show inspiration card contextually
        inspirationVM.checkAndShowInspirationCard()
    }

    /// Handles errors during data load.
    private func handleLoadError(_ error: Error) {
        self.error = error
        logger.log(
            "Failed to load overview data",
            level: .error,
            category: .dataIntegrity,
            metadata: ["error": error.localizedDescription]
        )
    }

    /// Handles pending refresh requests that came in during loading.
    func handlePendingRefresh() async {
        // Check if a refresh was requested while we were loading
        // This handles the race condition where timezone changes during an ongoing load
        if needsRefreshAfterLoad {
            needsRefreshAfterLoad = false
            logger.log(
                "Processing pending refresh that was requested during load",
                level: .info,
                category: .stateManagement
            )
            hasLoadedInitialData = false
            await loadData()
        }
    }
}

// MARK: - Refresh Methods

extension OverviewViewModel {

    public func refresh() async {
        logger.log(
            "Manual refresh requested",
            level: .info,
            category: .userAction,
            metadata: ["action": "User initiated data reload", "isLoading": isLoading]
        )

        // If a load is in progress, mark that we need to refresh after it completes
        if isLoading {
            needsRefreshAfterLoad = true
            logger.log(
                "Load in progress - marking for refresh after current load completes",
                level: .info,
                category: .stateManagement
            )
            return
        }

        hasLoadedInitialData = false  // Allow reload
        await loadData()
    }

    public func invalidateCacheForTabSwitch() {
        // Restore pre-cache-sync behavior: reload on tab switch
        if hasLoadedInitialData {
            logger.logStateTransition(
                from: "cached",
                to: "invalidated",
                context: ["reason": "Tab switch detected"]
            )
            hasLoadedInitialData = false
        }
    }
}

// MARK: - Child ViewModel Delegation Methods

extension OverviewViewModel {

    public func openPersonalityAnalysis() {
        personalityVM.openPersonalityAnalysis()
    }

    public func refreshPersonalityInsights() async {
        await personalityVM.refreshPersonalityInsights()
    }

    public func dismissInspirationItem(_ item: InspirationItem) {
        inspirationVM.dismissInspirationItem(item)
    }

    public func dismissAllInspirationItems() {
        inspirationVM.dismissAllInspirationItems()
    }
}
