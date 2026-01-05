// swiftlint:disable file_length
import SwiftUI
import Foundation
import FactoryKit
import RitualistCore
import TipKit

// MARK: - ViewModel

@MainActor
@Observable
public final class OverviewViewModel { // swiftlint:disable:this type_body_length
    // MARK: - Child ViewModels (SRP Extraction)

    /// Handles inspiration card display and trigger evaluation
    public let inspirationVM = InspirationCardViewModel()

    /// Handles personality insights and premium feature management
    public let personalityVM = PersonalityInsightsCardViewModel()

    // MARK: - Observable Properties
    public var todaysSummary: TodaysSummary?
    public var activeStreaks: [StreakInfo] = []
    public var selectedDate = Date()
    public var viewingDate = CalendarUtils.startOfDayLocal(for: Date()) // The date being viewed in Today's Progress card

    public var isLoading: Bool = false
    public var error: Error?

    // Shared sheet state
    public var selectedHabitForSheet: Habit?
    public var showingNumericSheet = false

    // Notification-triggered sheet state
    public var pendingNumericHabitFromNotification: Habit?
    public var pendingBinaryHabitFromNotification: Habit?
    public var showingCompleteHabitSheet = false

    // Track if pending habit has been processed to prevent double-processing
    @ObservationIgnored private var hasPendingHabitBeenProcessed: Bool = false
    @ObservationIgnored private var hasPendingBinaryHabitBeenProcessed: Bool = false

    // Track view visibility to handle immediate processing when habit is set
    public var isViewVisible: Bool = false

    // Single source of truth for all overview data
    public var overviewData: OverviewData?

    // MARK: - Cache Invalidation State

    /// Track previous migration state to detect completion
    @ObservationIgnored private var wasMigrating = false

    /// Track if initial data has been loaded to prevent duplicate loads
    @ObservationIgnored private var hasLoadedInitialData = false
    @ObservationIgnored private var hasEverLoadedData = false // True first load flag, never reset

    /// Track if a refresh was requested while a load was in progress
    /// When true, loadData() will re-run after current load completes
    @ObservationIgnored private var needsRefreshAfterLoad = false

    /// Public accessor for view to check if initial load has completed
    public var hasInitialDataLoaded: Bool {
        hasLoadedInitialData
    }

    /// Track if view has disappeared at least once (to distinguish initial appear from tab switch)
    @ObservationIgnored private var viewHasDisappearedOnce = false

    /// Mark that the view has disappeared (called from onDisappear)
    public func markViewDisappeared() {
        viewHasDisappearedOnce = true
    }

    /// Check if this is a tab switch (view returning after having left)
    /// Returns false on initial appear, true on subsequent appears after disappearing
    public var isReturningFromTabSwitch: Bool {
        viewHasDisappearedOnce
    }

    // MARK: - Computed Properties
    public var incompleteHabits: [Habit] {
        todaysSummary?.incompleteHabits ?? []
    }

    public var completedHabits: [Habit] {
        todaysSummary?.completedHabits ?? []
    }

    public var shouldShowQuickActions: Bool {
        // Only show QuickActions when there are incomplete habits (completed habits now shown in Today's card)
        !incompleteHabits.isEmpty
    }

    public var shouldShowActiveStreaks: Bool {
        !activeStreaks.isEmpty
    }

    public var canGoToPreviousDay: Bool {
        let today = Date()
        let thirtyDaysAgo = CalendarUtils.addDaysLocal(-30, to: today, timezone: displayTimezone)
        let viewingDayStart = CalendarUtils.startOfDayLocal(for: viewingDate, timezone: displayTimezone)
        let boundaryStart = CalendarUtils.startOfDayLocal(for: thirtyDaysAgo, timezone: displayTimezone)
        return viewingDayStart > boundaryStart
    }

    public var canGoToNextDay: Bool {
        let today = Date()
        let viewingDayStart = CalendarUtils.startOfDayLocal(for: viewingDate, timezone: displayTimezone)
        let todayStart = CalendarUtils.startOfDayLocal(for: today, timezone: displayTimezone)
        return viewingDayStart < todayStart
    }

    public var isViewingToday: Bool {
        CalendarUtils.areSameDayLocal(viewingDate, Date(), timezone: displayTimezone)
    }

    public var currentSlogan: String {
        getCurrentSlogan.execute()
    }

    public var currentTimeOfDay: TimeOfDay {
        TimeOfDay.current()
    }

    public var monthlyCompletionData: [Date: Double] = [:]

    // MARK: - Child ViewModel Accessors (Convenience)

    /// Whether to show the inspiration card (delegates to child VM)
    public var shouldShowInspirationCard: Bool {
        inspirationVM.shouldShowInspirationCard
    }

    /// Inspiration items for carousel (delegates to child VM)
    public var inspirationItems: [InspirationItem] {
        inspirationVM.inspirationItems
    }

    /// Whether to show personality insights card (delegates to child VM)
    public var shouldShowPersonalityInsights: Bool {
        personalityVM.shouldShowPersonalityInsights
    }

    /// Personality insights (delegates to child VM)
    public var personalityInsights: [OverviewPersonalityInsight] {
        personalityVM.personalityInsights
    }

    /// Dominant personality trait (delegates to child VM)
    public var dominantPersonalityTrait: String? {
        personalityVM.dominantPersonalityTrait
    }

    /// Is personality data sufficient (delegates to child VM)
    public var isPersonalityDataSufficient: Bool {
        personalityVM.isPersonalityDataSufficient
    }

    /// Personality threshold requirements (delegates to child VM)
    public var personalityThresholdRequirements: [ThresholdRequirement] {
        personalityVM.personalityThresholdRequirements
    }

    /// Whether to show personality upsell card (free users with sufficient data)
    public var showPersonalityUpsell: Bool {
        personalityVM.showPersonalityUpsell
    }

    /// Paywall item for personality insights upsell (binding for sheet presentation)
    public var personalityPaywallItem: PaywallItem? {
        get { personalityVM.paywallItem }
        set { personalityVM.paywallItem = newValue }
    }

    /// Show paywall for personality insights upsell
    public func showPersonalityPaywall() {
        Task {
            await personalityVM.showPaywall()
        }
    }

    /// Handle personality paywall dismissal
    public func handlePersonalityPaywallDismissal() {
        personalityVM.handlePaywallDismissal()
    }

    /// Immediately hide personality upsell (in case user purchased elsewhere)
    public func hidePersonalityUpsell() {
        personalityVM.hideUpsell()
    }

    // MARK: - Migration State (exposed via UseCase)

    /// Whether a migration is currently in progress
    public var isMigrating: Bool {
        getMigrationStatus.isMigrating
    }

    /// Current migration details (from version → to version)
    public var migrationDetails: MigrationDetails? {
        getMigrationStatus.migrationDetails
    }

    // MARK: - Habit Limit State

    /// Whether to show the "deactivate habits" banner for users over the free tier limit
    public var showDeactivateHabitsBanner = false

    /// Number of active habits (for banner display)
    public var activeHabitsCount = 0

    // MARK: - Dependencies
    @ObservationIgnored @Injected(\.featureGatingService) private var featureGating
    @ObservationIgnored @Injected(\.getActiveHabits) private var getActiveHabits
    @ObservationIgnored @Injected(\.getLogs) private var getLogs
    @ObservationIgnored @Injected(\.getBatchLogs) private var getBatchLogs
    @ObservationIgnored @Injected(\.logHabit) private var logHabit
    @ObservationIgnored @Injected(\.deleteLog) private var deleteLog
    @ObservationIgnored @Injected(\.getCurrentSlogan) private var getCurrentSlogan
    @ObservationIgnored @Injected(\.getCurrentUserProfile) private var getCurrentUserProfile
    @ObservationIgnored @Injected(\.calculateCurrentStreak) private var calculateCurrentStreakUseCase
    @ObservationIgnored @Injected(\.getStreakStatus) private var getStreakStatusUseCase
    @ObservationIgnored @Injected(\.isHabitCompleted) private var isHabitCompleted
    @ObservationIgnored @Injected(\.calculateDailyProgress) private var calculateDailyProgress
    @ObservationIgnored @Injected(\.isScheduledDay) private var isScheduledDay
    @ObservationIgnored @Injected(\.validateHabitSchedule) private var validateHabitScheduleUseCase
    @ObservationIgnored @Injected(\.refreshWidget) private var refreshWidget
    @ObservationIgnored @Injected(\.getMigrationStatus) private var getMigrationStatus
    @ObservationIgnored @Injected(\.timezoneService) private var timezoneService
    @ObservationIgnored @Injected(\.debugLogger) private var logger

    /// Cached display timezone for use in synchronous calculations.
    /// Updated on loadData() and when timezone settings change.
    /// Exposed publicly for UI components that need timezone-aware date calculations.
    /// NOT marked @ObservationIgnored - allows SwiftUI to observe direct changes.
    /// Currently, timezone changes trigger full reload via iCloudDidSyncRemoteChanges notification,
    /// but keeping this observable provides a safeguard for future direct timezone updates.
    public internal(set) var displayTimezone: TimeZone = .current

    private func getUserId() async -> UUID {
        await getCurrentUserProfile.execute().id
    }

    public init() {
        // Child VMs handle their own initialization
    }

    // MARK: - Public Methods

    // swiftlint:disable:next function_body_length
    public func loadData() async {
        // Prevent duplicate loads while one is already in progress
        // If refresh() is called during a load, we'll catch it at the end and re-run
        guard !isLoading else {
            logger.logStateTransition(
                from: "loading_blocked",
                to: "already_loading",
                context: ["reason": "Preventing duplicate load, will check needsRefreshAfterLoad"]
            )
            return
        }

        // MIGRATION GUARD: Check migration state on first load
        // Handles: (1) App restart during migration, (2) ViewModel created after migration
        if !hasLoadedInitialData && getMigrationStatus.isMigrating {
            logger.logStateTransition(
                from: "initial_load_deferred",
                to: "migration_in_progress",
                context: ["reason": "Waiting for migration completion"]
            )
            wasMigrating = true
            return  // Don't load during migration - wait for completion
        }

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

        // Check if timezone changed BEFORE the early return check
        // This ensures we reload when user changes timezone in settings
        let newTimezone = (try? await timezoneService.getDisplayTimezone()) ?? .current
        let timezoneChanged = displayTimezone.identifier != newTimezone.identifier

        // Skip redundant loads after initial data is loaded
        // Allow loads if: cache is nil OR migration just completed OR timezone changed
        if hasLoadedInitialData && overviewData != nil && !timezoneChanged {
            logger.log(
                "Load skipped - data already loaded",
                level: .debug,
                category: .stateManagement,
                metadata: ["hint": "Use refresh() to force reload"]
            )
            return
        }

        logger.logStateTransition(
            from: "idle",
            to: "loading",
            context: ["operation": "Full database reload"]
        )
        isLoading = true
        error = nil

        do {
            // Use timezone already fetched above (before early return check)
            displayTimezone = newTimezone

            // Recalculate viewingDate when:
            // 1. Timezone actually changed (user updated settings)
            // 2. True first load (viewingDate was initialized with device timezone, not user's setting)
            // Note: Use hasEverLoadedData to avoid resetting date during navigation-triggered reloads
            // This ensures MonthlyCalendarCard and TodaysSummaryCard show correct "today" highlighting
            if timezoneChanged || !hasEverLoadedData {
                let oldViewingDate = viewingDate
                viewingDate = CalendarUtils.startOfDayLocal(for: Date(), timezone: displayTimezone)
                logger.log(
                    "Recalculated viewingDate for today",
                    level: .info,
                    category: .stateManagement,
                    metadata: [
                        "reason": !hasEverLoadedData ? "first_load" : "timezone_changed",
                        "timezone": displayTimezone.identifier,
                        "oldViewingDate": oldViewingDate.description,
                        "newViewingDate": viewingDate.description
                    ]
                )
            }

            logger.log(
                "Display timezone loaded",
                level: .debug,
                category: .stateManagement,
                metadata: ["timezone": displayTimezone.identifier]
            )

            // Cache user name for synchronous message generation
            let userName = await getUserName()

            // Load unified data once instead of multiple parallel operations
            let overviewData = try await loadOverviewData()
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

            // Store the overview data and extract all card data from it using unified approach
            self.overviewData = overviewData
            self.hasLoadedInitialData = true
            self.hasEverLoadedData = true
            self.todaysSummary = extractTodaysSummary(from: overviewData)
            self.activeStreaks = extractActiveStreaks(from: overviewData)
            self.monthlyCompletionData = extractMonthlyData(from: overviewData)

            // Configure child VMs with context
            configureChildViewModels(userName: userName)

            // Check if user is over the free tier habit limit
            await checkHabitLimitStatus(habitCount: overviewData.habits.count)

            // Load personality insights separately (non-blocking)
            Task { @MainActor in
                await personalityVM.loadPersonalityInsights()
            }

            // Check if we should show inspiration card contextually
            inspirationVM.checkAndShowInspirationCard()
        } catch {
            self.error = error
            logger.log(
                "Failed to load overview data",
                level: .error,
                category: .dataIntegrity,
                metadata: ["error": error.localizedDescription]
            )
        }

        self.isLoading = false

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

    public func refresh() async {
        logger.log(
            "Manual refresh requested",
            level: .info,
            category: .userAction,
            metadata: ["action": "User initiated data reload", "isLoading": isLoading]
        )

        // If a load is in progress, mark that we need to refresh after it completes
        // This handles the race condition where timezone changes during an ongoing load
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
        // This ensures users see new habits/categories created in other tabs
        if hasLoadedInitialData {
            logger.logStateTransition(
                from: "cached",
                to: "invalidated",
                context: ["reason": "Tab switch detected"]
            )
            hasLoadedInitialData = false
        }
    }

    // MARK: - Child ViewModel Delegation Methods

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

    // MARK: - Habit Interaction Methods

    public func completeHabit(_ habit: Habit) async {
        // MIGRATION CHECK: Invalidate cache if migration just completed
        if checkMigrationAndInvalidateCache() {
            await loadData()
        }

        do {
            if habit.kind == .numeric {
                // For numeric habits, set to daily target (this should primarily be used for binary habits)
                // Most numeric habit interactions should go through updateNumericHabit instead
                try await updateNumericHabit(habit, value: habit.dailyTarget ?? 1.0)
            } else {
                // Binary habit - just create a log with value 1.0
                // - date: Uses overviewData's timezone (single source of truth) to determine which "day" the log belongs to
                // - timezone: Records the DISPLAY timezone used to calculate the date, so we can correctly
                //   determine which calendar day this log represents when checking completion later
                // CRITICAL: Must store DISPLAY timezone (not device timezone) to match the date calculation!
                let effectiveTimezone = overviewData?.timezone ?? displayTimezone
                let logDate = CalendarUtils.startOfDayLocal(for: viewingDate, timezone: effectiveTimezone)
                let log = HabitLog(
                    id: UUID(),
                    habitID: habit.id,
                    date: logDate,
                    value: 1.0,
                    timezone: effectiveTimezone.identifier  // Store DISPLAY timezone, not device timezone
                )

                // DEBUG: Log what timezone we're using to create the log
                logger.log(
                    "DEBUG completeHabit creating log",
                    level: .warning,
                    category: .stateManagement,
                    metadata: [
                        "habit_name": habit.name,
                        "viewingDate_utc": viewingDate.description,
                        "effectiveTimezone": effectiveTimezone.identifier,
                        "overviewData_timezone": overviewData?.timezone.identifier ?? "nil",
                        "displayTimezone": displayTimezone.identifier,
                        "logDate_utc": logDate.description,
                        "device_timezone": TimeZone.current.identifier
                    ]
                )

                try await logHabit.execute(log)

                // CACHE SYNC: Update cache instead of full reload
                updateCachedLog(log)

                // Donate tip event when user completes a habit
                await TapCompletedHabitTip.firstHabitCompleted.donate()

                // Small delay to ensure data is committed to shared container before widget refresh
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

                // Refresh widget to show updated habit status
                refreshWidget.execute(habitId: habit.id)
            }
        } catch {
            self.error = error
            logger.logError(
                error,
                context: "Failed to complete habit",
                metadata: ["habit_id": habit.id.uuidString]
            )
        }
    }

    public func getCurrentProgress(for habit: Habit) async -> Double {
        do {
            // Use display timezone for date filtering
            let allLogs = try await getLogs.execute(for: habit.id, since: viewingDate, until: viewingDate, timezone: displayTimezone)
            // Use cross-timezone comparison: log's calendar day (in its stored timezone) vs viewing date (in display timezone)
            let logsForDate = allLogs.filter { log in
                let logTimezone = log.resolvedTimezone(fallback: displayTimezone)
                return CalendarUtils.areSameDayAcrossTimezones(
                    log.date,
                    timezone1: logTimezone,
                    viewingDate,
                    timezone2: displayTimezone
                )
            }

            if habit.kind == .numeric {
                return logsForDate.reduce(0.0) { $0 + ($1.value ?? 0.0) }
            } else {
                return logsForDate.isEmpty ? 0.0 : 1.0
            }
        } catch {
            logger.logError(
                error,
                context: "Failed to get current progress",
                metadata: ["habit_name": habit.name, "habit_id": habit.id.uuidString]
            )
            return 0.0
        }
    }

    public func updateNumericHabit(_ habit: Habit, value: Double) async throws {
        // MIGRATION CHECK: Invalidate cache if migration just completed
        if checkMigrationAndInvalidateCache() {
            await loadData()
        }

        do {
            // Get existing logs FROM CACHE (not database)
            let existingLogsForDate = overviewData?.logs(for: habit.id, on: viewingDate) ?? []

            let log: HabitLog
            // CRITICAL: Use overviewData's timezone (single source of truth) to match extraction logic
            let effectiveTimezone = overviewData?.timezone ?? displayTimezone

            if existingLogsForDate.isEmpty {
                // No existing log for this date - create new one
                // - date: Uses overviewData's timezone to determine which "day" the log belongs to
                // - timezone: Records the DISPLAY timezone used to calculate the date
                // CRITICAL: Must store DISPLAY timezone (not device timezone) to match the date calculation!
                log = HabitLog(
                    id: UUID(),
                    habitID: habit.id,
                    date: CalendarUtils.startOfDayLocal(for: viewingDate, timezone: effectiveTimezone),
                    value: value,
                    timezone: effectiveTimezone.identifier  // Store DISPLAY timezone, not device timezone
                )
                try await logHabit.execute(log)
            } else if existingLogsForDate.count == 1 {
                // Single existing log - update it
                var updatedLog = existingLogsForDate[0]
                updatedLog.value = value
                log = updatedLog
                try await logHabit.execute(log)
            } else {
                // Multiple logs exist for this date - this shouldn't happen for our UI
                // But let's handle it properly: delete all existing logs and create one new log
                for existingLog in existingLogsForDate {
                    try await deleteLog.execute(id: existingLog.id)
                }

                // - date: Uses overviewData's timezone to determine which "day" the log belongs to
                // - timezone: Records the DISPLAY timezone used to calculate the date
                // CRITICAL: Must store DISPLAY timezone (not device timezone) to match the date calculation!
                log = HabitLog(
                    id: UUID(),
                    habitID: habit.id,
                    date: CalendarUtils.startOfDayLocal(for: viewingDate, timezone: effectiveTimezone),
                    value: value,
                    timezone: effectiveTimezone.identifier  // Store DISPLAY timezone, not device timezone
                )
                try await logHabit.execute(log)
            }

            // CACHE SYNC: Update cache instead of full reload
            updateCachedLog(log)

            // Donate tip event when user completes a habit
            await TapCompletedHabitTip.firstHabitCompleted.donate()

            // Small delay to ensure data is committed to shared container before widget refresh
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

            // Refresh widget to show updated habit status
            refreshWidget.execute(habitId: habit.id)
        } catch {
            self.error = error
            logger.logError(
                error,
                context: "Failed to update numeric habit",
                metadata: ["habit_id": habit.id.uuidString]
            )
            throw error
        }
    }

    public func getProgressSync(for habit: Habit) -> Double {
        // Use single source of truth from overviewData if available
        guard let data = overviewData else {
            return 0.0
        }

        let logs = data.logs(for: habit.id, on: viewingDate)

        if habit.kind == .binary {
            return logs.isEmpty ? 0.0 : 1.0
        } else {
            return logs.reduce(0.0) { $0 + ($1.value ?? 0.0) }
        }
    }

    // MARK: - Schedule Status and Validation Methods

    public func getScheduleStatus(for habit: Habit) -> HabitScheduleStatus {
        // Use display timezone for consistent schedule status across timezone changes
        HabitScheduleStatus.forHabit(habit, date: viewingDate, isScheduledDay: isScheduledDay, timezone: displayTimezone)
    }

    public func getStreakStatusSync(for habit: Habit) -> HabitStreakStatus {
        // Use single source of truth from overviewData if available
        guard let data = overviewData else {
            // Return default status with no streak if data not loaded
            return HabitStreakStatus(current: 0, atRisk: 0, isAtRisk: false, isTodayScheduled: false)
        }

        let logs = data.habitLogs[habit.id] ?? []
        // Use data's timezone (display timezone) for consistent streak calculation
        return getStreakStatusUseCase.execute(habit: habit, logs: logs, asOf: viewingDate, timezone: data.timezone)
    }

    private func loadLogsSynchronously(for habitId: UUID, from startDate: Date, to endDate: Date) throws -> [HabitLog] {
        // This is a simplified synchronous version - in production you'd want to cache this data
        // For now, we'll use cached data from overviewData if available
        guard let data = overviewData else { return [] }
        let habitLogs = data.habitLogs[habitId] ?? []
        return habitLogs.filter { log in
            log.date >= startDate && log.date <= endDate
        }
    }

    public func getScheduleValidationMessage(for habit: Habit) async -> String? {
        do {
            _ = try await validateHabitScheduleUseCase.execute(habit: habit, date: viewingDate)
            return nil // No validation errors
        } catch let error as HabitScheduleValidationError {
            return error.localizedDescription
        } catch {
            return "Unable to validate habit schedule"
        }
    }

    public func showNumericSheet(for habit: Habit) {
        selectedHabitForSheet = habit
        showingNumericSheet = true
    }

    public func showBinarySheet(for habit: Habit) {
        selectedHabitForSheet = habit
        showingCompleteHabitSheet = true
    }

    public func setPendingNumericHabit(_ habit: Habit) {
        pendingNumericHabitFromNotification = habit
        hasPendingHabitBeenProcessed = false // Reset processing flag when new habit is set

        // RACE CONDITION FIX: If view is visible and ready, process immediately instead of waiting for onAppear
        if isViewVisible {
            processPendingNumericHabit()
        }
    }

    public var isPendingHabitProcessed: Bool {
        hasPendingHabitBeenProcessed
    }

    public func setViewVisible(_ visible: Bool) {
        isViewVisible = visible
    }

    public func processPendingNumericHabit() {
        // Prevent double-processing if already handled
        guard !hasPendingHabitBeenProcessed,
              let habit = pendingNumericHabitFromNotification else {
            return
        }

        showNumericSheet(for: habit)

        // Clean up state after processing
        pendingNumericHabitFromNotification = nil
        hasPendingHabitBeenProcessed = true
    }

    // MARK: - Binary Habit Completion (from Notification)

    public func setPendingBinaryHabit(_ habit: Habit) {
        pendingBinaryHabitFromNotification = habit
        hasPendingBinaryHabitBeenProcessed = false

        // If view is visible, process immediately
        if isViewVisible {
            processPendingBinaryHabit()
        }
    }

    public var isPendingBinaryHabitProcessed: Bool {
        hasPendingBinaryHabitBeenProcessed
    }

    public func processPendingBinaryHabit() {
        // Prevent double-processing if already handled
        guard !hasPendingBinaryHabitBeenProcessed,
              let habit = pendingBinaryHabitFromNotification else {
            return
        }

        selectedHabitForSheet = habit
        showingCompleteHabitSheet = true

        // Clean up state after processing
        pendingBinaryHabitFromNotification = nil
        hasPendingBinaryHabitBeenProcessed = true
    }

    public func deleteHabitLog(_ habit: Habit) async {
        // MIGRATION CHECK: Invalidate cache if migration just completed
        if checkMigrationAndInvalidateCache() {
            await loadData()
        }

        do {
            // Get logs FROM CACHE (not database)
            let existingLogsForDate = overviewData?.logs(for: habit.id, on: viewingDate) ?? []

            // Delete from database
            for log in existingLogsForDate {
                try await deleteLog.execute(id: log.id)
            }

            // CACHE SYNC: Update cache instead of full reload
            removeCachedLogs(habitId: habit.id, on: viewingDate)

            // Small delay to ensure data is committed to shared container before widget refresh
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

            // Refresh widget to show updated habit status
            refreshWidget.execute(habitId: habit.id)
        } catch {
            self.error = error
            logger.logError(
                error,
                context: "Failed to delete habit log",
                metadata: ["habit_id": habit.id.uuidString]
            )
        }
    }

    public func goToPreviousDay() {
        guard canGoToPreviousDay else { return }

        viewingDate = CalendarUtils.addDaysLocal(-1, to: viewingDate, timezone: displayTimezone)

        // MIGRATION CHECK: Invalidate cache if migration just completed
        if checkMigrationAndInvalidateCache() {
            Task { await loadData() }
            return
        }

        // SELECTIVE RELOAD: Only if date out of cached range
        if needsReload(for: viewingDate) {
            hasLoadedInitialData = false  // Allow reload
            Task { await loadData() }
        } else {
            guard let data = overviewData else { return }
            refreshUIState(with: data)
        }
    }

    public func goToNextDay() {
        guard canGoToNextDay else { return }

        viewingDate = CalendarUtils.addDaysLocal(1, to: viewingDate, timezone: displayTimezone)

        // MIGRATION CHECK: Invalidate cache if migration just completed
        if checkMigrationAndInvalidateCache() {
            Task { await loadData() }
            return
        }

        // SELECTIVE RELOAD: Only if date out of cached range
        if needsReload(for: viewingDate) {
            hasLoadedInitialData = false  // Allow reload
            Task { await loadData() }
        } else {
            guard let data = overviewData else { return }
            refreshUIState(with: data)
        }
    }

    public func goToToday() {
        viewingDate = CalendarUtils.startOfDayLocal(for: Date(), timezone: displayTimezone)

        // MIGRATION CHECK: Invalidate cache if migration just completed
        if checkMigrationAndInvalidateCache() {
            Task { await loadData() }
            return
        }

        // SELECTIVE RELOAD: Only if date out of cached range
        if needsReload(for: Date()) {
            hasLoadedInitialData = false  // Allow reload
            Task { await loadData() }
        } else {
            guard let data = overviewData else { return }
            refreshUIState(with: data)
        }
    }

    public func goToDate(_ date: Date) {
        viewingDate = CalendarUtils.startOfDayLocal(for: date, timezone: displayTimezone)

        // MIGRATION CHECK: Invalidate cache if migration just completed
        if checkMigrationAndInvalidateCache() {
            Task { await loadData() }
            return
        }

        // SELECTIVE RELOAD: Only if date out of cached range
        if needsReload(for: date) {
            hasLoadedInitialData = false  // Allow reload
            Task { await loadData() }
        } else {
            guard let data = overviewData else { return }
            refreshUIState(with: data)
        }
    }

    // MARK: - Private Methods

    /// Load overview data from database using the display timezone
    private func loadOverviewData() async throws -> OverviewData {
        // 1. Load habits ONCE
        let habits = try await getActiveHabits.execute()

        // 2. Determine date range for UI purposes (past 30 days)
        let today = Date()
        let startDate = CalendarUtils.addDaysLocal(-30, to: today, timezone: displayTimezone)

        // 3. Load ALL logs without date filtering
        // CRITICAL: Don't filter by date range here - logs created in different timezones
        // have UTC timestamps that may fall on different "days" when interpreted in the
        // current display timezone. Let the presentation layer filter by date instead.
        let habitIds = habits.map(\.id)
        let habitLogs = try await getBatchLogs.execute(
            for: habitIds,
            since: nil,
            until: nil,
            timezone: displayTimezone
        )

        return OverviewData(
            habits: habits,
            habitLogs: habitLogs,
            dateRange: startDate...today,
            timezone: displayTimezone
        )
    }

    /// Configure child ViewModels with current context
    private func configureChildViewModels(userName: String?) {
        let configuration = InspirationCardConfiguration(
            activeStreaks: activeStreaks,
            todaysSummary: todaysSummary,
            displayTimezone: displayTimezone,
            isViewingToday: isViewingToday,
            totalHabitsCount: overviewData?.habits.count ?? 0,
            userName: userName
        )
        inspirationVM.configure(with: configuration)
    }

    /// Check if migration just completed and invalidate cache if needed
    /// Returns true if cache was invalidated (caller should reload)
    private func checkMigrationAndInvalidateCache() -> Bool {
        let currentlyMigrating = getMigrationStatus.isMigrating

        // Detect migration completion: was migrating, now not
        let justCompletedMigration = wasMigrating && !currentlyMigrating

        // Update tracking state
        wasMigrating = currentlyMigrating

        if justCompletedMigration {
            // Migration just completed - cache is STALE
            logger.logStateTransition(
                from: "migration_completed",
                to: "cache_invalidated",
                context: ["action": "Force reload required"]
            )
            overviewData = nil  // Force reload
            hasLoadedInitialData = false  // Allow reload
            return true
        }

        return false
    }

    // MARK: - Cache Update Helpers (Memory Leak Fix)

    /// Update cache after successful database write
    /// This eliminates the need for full database reload
    private func updateCachedLog(_ log: HabitLog) {
        guard let data = overviewData else {
            logger.log(
                "Cache miss - no cache available",
                level: .debug,
                category: .stateManagement,
                metadata: ["operation": "updateCachedLog"]
            )
            return
        }

        var habitLogs = data.habitLogs[log.habitID] ?? []

        // Check if log already exists (update scenario)
        if let existingIndex = habitLogs.firstIndex(where: { $0.id == log.id }) {
            habitLogs[existingIndex] = log
            logger.log(
                "Cache updated - existing log modified",
                level: .debug,
                category: .stateManagement,
                metadata: ["habit_id": log.habitID.uuidString]
            )
        } else {
            habitLogs.append(log)
            logger.log(
                "Cache updated - new log added",
                level: .debug,
                category: .stateManagement,
                metadata: ["habit_id": log.habitID.uuidString]
            )
        }

        var updatedHabitLogs = data.habitLogs
        updatedHabitLogs[log.habitID] = habitLogs

        let updatedData = OverviewData(
            habits: data.habits,
            habitLogs: updatedHabitLogs,
            dateRange: data.dateRange,
            timezone: data.timezone  // Preserve display timezone in cache
        )

        refreshUIState(with: updatedData)
    }

    /// Remove logs from cache after successful database delete
    private func removeCachedLogs(habitId: UUID, on date: Date) {
        guard let data = overviewData else {
            logger.log(
                "Cache miss - no cache available for delete",
                level: .debug,
                category: .stateManagement,
                metadata: ["habit_id": habitId.uuidString]
            )
            return
        }

        var habitLogs = data.habitLogs[habitId] ?? []
        let beforeCount = habitLogs.count
        // Use cross-timezone comparison: log's calendar day (in its stored timezone) vs query date (in display timezone)
        habitLogs.removeAll { log in
            let logTimezone = log.resolvedTimezone(fallback: displayTimezone)
            return CalendarUtils.areSameDayAcrossTimezones(
                log.date,
                timezone1: logTimezone,
                date,
                timezone2: displayTimezone
            )
        }
        let removedCount = beforeCount - habitLogs.count
        logger.log(
            "Cache updated - logs removed",
            level: .debug,
            category: .stateManagement,
            metadata: [
                "habit_id": habitId.uuidString,
                "removed_count": removedCount
            ]
        )

        var updatedHabitLogs = data.habitLogs
        updatedHabitLogs[habitId] = habitLogs

        let updatedData = OverviewData(
            habits: data.habits,
            habitLogs: updatedHabitLogs,
            dateRange: data.dateRange,
            timezone: data.timezone  // Preserve display timezone in cache
        )

        refreshUIState(with: updatedData)
    }

    /// Refresh all derived UI properties from OverviewData
    /// Ensures consistency across all cards
    private func refreshUIState(with data: OverviewData) {
        self.overviewData = data
        self.todaysSummary = extractTodaysSummary(from: data)
        self.activeStreaks = extractActiveStreaks(from: data)
        self.monthlyCompletionData = extractMonthlyData(from: data)

        // Update child VM context
        Task { @MainActor in
            let userName = await getUserName()
            configureChildViewModels(userName: userName)
            inspirationVM.checkAndShowInspirationCard()
        }
    }

    /// Check if date requires database reload (outside cached range)
    private func needsReload(for date: Date) -> Bool {
        guard let data = overviewData else {
            logger.log(
                "Reload needed - no cache available",
                level: .debug,
                category: .stateManagement
            )
            return true
        }
        let dateStart = CalendarUtils.startOfDayLocal(for: date, timezone: displayTimezone)
        let needsReload = !data.dateRange.contains(dateStart)
        if needsReload {
            logger.log(
                "Reload needed - date outside cached range",
                level: .debug,
                category: .stateManagement,
                metadata: ["date": dateStart.description]
            )
        } else {
            logger.log(
                "Cache hit - date within range",
                level: .debug,
                category: .stateManagement,
                metadata: ["date": dateStart.description]
            )
        }
        return needsReload
    }

    // MARK: - Data Extraction Methods

    /// Extract TodaysSummary from overview data
    internal func extractTodaysSummary(from data: OverviewData) -> TodaysSummary {
        let targetDate = CalendarUtils.startOfDayLocal(for: viewingDate, timezone: data.timezone)
        let habits = data.scheduledHabits(for: targetDate)

        logExtractTodaysSummaryDebugInfo(data: data, habits: habits, targetDate: targetDate)

        let result = categorizeHabitsByCompletion(habits: habits, data: data, targetDate: targetDate)
        let sortedCompleted = sortCompletedHabitsByLatestLog(result.completed, logs: result.logs)

        return TodaysSummary(
            completedHabitsCount: sortedCompleted.count,
            completedHabits: sortedCompleted,
            totalHabits: habits.count,
            incompleteHabits: result.incomplete
        )
    }

    /// Log debug info for extractTodaysSummary (extracted to reduce function length)
    private func logExtractTodaysSummaryDebugInfo(data: OverviewData, habits: [Habit], targetDate: Date) {
        if let firstHabit = habits.first {
            let allLogs = data.habitLogs[firstHabit.id] ?? []
            let filteredLogs = data.logs(for: firstHabit.id, on: targetDate)
            logger.log(
                "DEBUG extractTodaysSummary",
                level: .debug,
                category: .stateManagement,
                metadata: [
                    "viewingDate_utc": viewingDate.description,
                    "targetDate_utc": targetDate.description,
                    "data_timezone": data.timezone.identifier,
                    "habit_name": firstHabit.name,
                    "all_logs_count": allLogs.count,
                    "filtered_logs_count": filteredLogs.count
                ]
            )
        }
    }

    /// Result of categorizing habits by completion status
    private struct HabitCategorizationResult {
        let completed: [Habit]
        let incomplete: [Habit]
        let logs: [HabitLog]
    }

    /// Categorize habits into completed and incomplete lists
    private func categorizeHabitsByCompletion(
        habits: [Habit],
        data: OverviewData,
        targetDate: Date
    ) -> HabitCategorizationResult {
        var allTargetDateLogs: [HabitLog] = []
        var incompleteHabits: [Habit] = []
        var completedHabits: [Habit] = []
        let isFutureDate = targetDate > Date()

        for habit in habits {
            let logs = data.logs(for: habit.id, on: targetDate)
            allTargetDateLogs.append(contentsOf: logs)

            let isCompleted = isHabitCompleted.execute(
                habit: habit, on: targetDate, logs: logs, timezone: data.timezone
            )

            if isCompleted {
                completedHabits.append(habit)
            } else if !isFutureDate {
                incompleteHabits.append(habit)
            }
        }

        return HabitCategorizationResult(
            completed: completedHabits,
            incomplete: incompleteHabits,
            logs: allTargetDateLogs
        )
    }

    /// Sort completed habits by latest log time (most recent first)
    private func sortCompletedHabitsByLatestLog(_ habits: [Habit], logs: [HabitLog]) -> [Habit] {
        habits.sorted { habit1, habit2 in
            let habit1LatestTime = logs.filter { $0.habitID == habit1.id }.map { $0.date }.max() ?? .distantPast
            let habit2LatestTime = logs.filter { $0.habitID == habit2.id }.map { $0.date }.max() ?? .distantPast
            return habit1LatestTime > habit2LatestTime
        }
    }

    /// Extract monthly completion data from overview data using the data's timezone
    private func extractMonthlyData(from data: OverviewData) -> [Date: Double] {
        var result: [Date: Double] = [:]
        let timezone = data.timezone  // Use data's timezone for consistency

        // Get dates from range, ensuring we use startOfDay for consistency with data's timezone
        for dayOffset in 0...30 {
            let date = CalendarUtils.addDaysLocal(-dayOffset, to: Date(), timezone: timezone)
            let startOfDay = CalendarUtils.startOfDayLocal(for: date, timezone: timezone)
            // Use HabitCompletionService for single source of truth completion rate
            let scheduledHabits = data.scheduledHabits(for: startOfDay)
            if scheduledHabits.isEmpty {
                result[startOfDay] = 0.0
            } else {
                let completedCount = scheduledHabits.count { habit in
                    let logs = data.logs(for: habit.id, on: startOfDay)
                    return isHabitCompleted.execute(habit: habit, on: startOfDay, logs: logs, timezone: timezone)
                }
                result[startOfDay] = Double(completedCount) / Double(scheduledHabits.count)
            }
        }

        return result
    }

    /// Extract active streaks from overview data (with grace period support) using data's timezone
    private func extractActiveStreaks(from data: OverviewData) -> [StreakInfo] {
        var streaks: [StreakInfo] = []
        let today = Date()

        for habit in data.habits {
            // Get logs for this habit from unified data
            let logs = data.habitLogs[habit.id] ?? []

            // Use getStreakStatus for grace period support with data's timezone for consistency
            let streakStatus = getStreakStatusUseCase.execute(habit: habit, logs: logs, asOf: today, timezone: data.timezone)

            // Show streak if either current > 0 OR at risk (grace period)
            let displayStreak = streakStatus.displayStreak
            if displayStreak >= 1 {
                let streakInfo = StreakInfo(
                    id: habit.id.uuidString,
                    habitName: habit.name,
                    emoji: habit.emoji ?? "📊",
                    currentStreak: displayStreak,
                    isActive: !streakStatus.isAtRisk // Active if not at risk
                )
                streaks.append(streakInfo)
            }
        }

        // Sort by streak length (longest first)
        let sortedStreaks = streaks.sorted { $0.currentStreak > $1.currentStreak }

        return sortedStreaks
    }

    private func getUserName() async -> String? {
        let profile = await getCurrentUserProfile.execute()
        return profile.name.isEmpty ? nil : profile.name
    }

    // MARK: - Habit Limit Check

    /// Check if user is over the free tier habit limit and update banner state
    private func checkHabitLimitStatus(habitCount: Int) async {
        activeHabitsCount = habitCount
        showDeactivateHabitsBanner = await featureGating.isOverActiveHabitLimit(activeCount: habitCount)

        if showDeactivateHabitsBanner {
            logger.log(
                "User over free tier habit limit",
                level: .info,
                category: .stateManagement,
                metadata: [
                    "activeCount": habitCount,
                    "maxFree": BusinessConstants.freeMaxHabits
                ]
            )
        }
    }
}
