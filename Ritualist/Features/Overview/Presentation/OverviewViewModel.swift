// swiftlint:disable file_length
import SwiftUI
import Foundation
import FactoryKit
import RitualistCore

// MARK: - ViewModel

@MainActor
@Observable
public final class OverviewViewModel { // swiftlint:disable:this type_body_length
    // MARK: - Observable Properties
    public var todaysSummary: TodaysSummary?
    public var activeStreaks: [StreakInfo] = []
    public var smartInsights: [SmartInsight] = []
    public var personalityInsights: [OverviewPersonalityInsight] = []
    public var shouldShowPersonalityInsights = true // Always show the card
    public var isPersonalityDataSufficient = false // Track if data is sufficient for new analysis
    public var personalityThresholdRequirements: [ThresholdRequirement] = [] // Current requirements status
    public var dominantPersonalityTrait: String? = nil
    public var selectedDate = Date()
    public var viewingDate = CalendarUtils.startOfDayLocal(for: Date()) // The date being viewed in Today's Progress card
    public var showInspirationCard: Bool = false

    /// Multiple inspiration items for carousel display, sorted by priority
    public var inspirationItems: [InspirationItem] = []

    // Inspiration card tracking
    @ObservationIgnored private var lastShownInspirationTrigger: InspirationTrigger?
    @ObservationIgnored private var sessionStartTime = Date()
    @ObservationIgnored private var dismissedTriggersToday: Set<InspirationTrigger> = []
    @ObservationIgnored private var cachedInspirationMessage: String?

    /// Tracks the last set of triggers shown in the carousel to prevent unnecessary rebuilds
    @ObservationIgnored private var lastEvaluatedTriggerSet: Set<InspirationTrigger> = []
    
    public var isLoading: Bool = false
    public var error: Error?
    
    // Shared sheet state
    public var selectedHabitForSheet: Habit?
    public var showingNumericSheet = false
    
    // Notification-triggered sheet state
    public var pendingNumericHabitFromNotification: Habit?
    
    // Track if pending habit has been processed to prevent double-processing
    @ObservationIgnored private var hasPendingHabitBeenProcessed: Bool = false
    
    // Track view visibility to handle immediate processing when habit is set
    public var isViewVisible: Bool = false
    
    // Single source of truth for all overview data
    public var overviewData: OverviewData?

    // MARK: - Cache Invalidation State

    /// Track previous migration state to detect completion
    @ObservationIgnored private var wasMigrating = false

    /// Track if initial data has been loaded to prevent duplicate loads
    @ObservationIgnored private var hasLoadedInitialData = false

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

    public var shouldShowInsights: Bool {
        !smartInsights.isEmpty
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
    
    public var shouldShowInspirationCard: Bool {
        guard isViewingToday else { return false }
        return showInspirationCard
    }
    
    // InspirationTrigger moved to RitualistCore/Enums/MotivationEnums.swift
    private typealias InspirationTrigger = RitualistCore.InspirationTrigger
    
    public var monthlyCompletionData: [Date: Double] = [:]

    // MARK: - Migration State (exposed via UseCase)

    /// Whether a migration is currently in progress
    public var isMigrating: Bool {
        getMigrationStatus.isMigrating
    }

    /// Current migration details (from version → to version)
    public var migrationDetails: MigrationDetails? {
        getMigrationStatus.migrationDetails
    }

    // MARK: - Dependencies
    @ObservationIgnored @Injected(\.getActiveHabits) private var getActiveHabits
    @ObservationIgnored @Injected(\.getLogs) private var getLogs
    @ObservationIgnored @Injected(\.getBatchLogs) private var getBatchLogs
    @ObservationIgnored @Injected(\.logHabit) private var logHabit
    @ObservationIgnored @Injected(\.deleteLog) private var deleteLog
    @ObservationIgnored @Injected(\.getCurrentSlogan) private var getCurrentSlogan
    @ObservationIgnored @Injected(\.getCurrentUserProfile) private var getCurrentUserProfile
    @ObservationIgnored @Injected(\.calculateCurrentStreak) private var calculateCurrentStreakUseCase
    @ObservationIgnored @Injected(\.getStreakStatus) private var getStreakStatusUseCase
    @ObservationIgnored @Injected(\.getPersonalityProfileUseCase) private var getPersonalityProfileUseCase
    @ObservationIgnored @Injected(\.getPersonalityInsightsUseCase) private var getPersonalityInsightsUseCase
    @ObservationIgnored @Injected(\.updatePersonalityAnalysisUseCase) private var updatePersonalityAnalysisUseCase
    @ObservationIgnored @Injected(\.validateAnalysisDataUseCase) private var validateAnalysisDataUseCase
    @ObservationIgnored @Injected(\.isPersonalityAnalysisEnabledUseCase) private var isPersonalityAnalysisEnabledUseCase
    @ObservationIgnored @Injected(\.personalityDeepLinkCoordinator) private var personalityDeepLinkCoordinator
    @ObservationIgnored @Injected(\.isHabitCompleted) private var isHabitCompleted
    @ObservationIgnored @Injected(\.calculateDailyProgress) private var calculateDailyProgress
    @ObservationIgnored @Injected(\.isScheduledDay) private var isScheduledDay
    @ObservationIgnored @Injected(\.validateHabitSchedule) private var validateHabitScheduleUseCase
    @ObservationIgnored @Injected(\.refreshWidget) private var refreshWidget
    @ObservationIgnored @Injected(\.personalizedMessageGenerator) private var personalizedMessageGenerator
    @ObservationIgnored @Injected(\.getMigrationStatus) private var getMigrationStatus
    @ObservationIgnored @Injected(\.timezoneService) private var timezoneService
    @ObservationIgnored @Injected(\.debugLogger) private var logger

    /// Cached display timezone for use in synchronous calculations.
    /// Updated on loadData() and when timezone settings change.
    /// Exposed publicly for UI components that need timezone-aware date calculations.
    /// Note: NOT marked @ObservationIgnored so SwiftUI re-renders when timezone changes.
    public internal(set) var displayTimezone: TimeZone = .current

    private func getUserId() async -> UUID {
        await getCurrentUserProfile.execute().id
    }
    
    public init() {
        // Initialize dismissed triggers for the current day
        resetDismissedTriggersIfNewDay()
    }
    
    // MARK: - Public Methods
    
    public func loadData() async {
        // Prevent duplicate loads while one is already in progress
        guard !isLoading else {
            logger.logStateTransition(
                from: "loading_blocked",
                to: "already_loading",
                context: ["reason": "Preventing duplicate load"]
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
        // This handles the case where user leaves app open overnight
        resetDismissedTriggersIfNewDay()

        // MIGRATION CHECK: Detect completion and invalidate cache if needed
        if checkMigrationAndInvalidateCache() {
            logger.logStateTransition(
                from: "migration_completed",
                to: "cache_invalidated",
                context: ["action": "Proceeding with fresh load"]
            )
        }

        // Skip redundant loads after initial data is loaded
        // Allow loads if: cache is nil OR migration just completed
        if hasLoadedInitialData && overviewData != nil {
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
            // Fetch display timezone from TimezoneService (respects user's Settings > Advanced choice)
            let newTimezone = (try? await timezoneService.getDisplayTimezone()) ?? .current
            let timezoneChanged = displayTimezone.identifier != newTimezone.identifier
            displayTimezone = newTimezone

            // When timezone changes, recalculate viewingDate to maintain "today" in the new timezone
            // This ensures MonthlyCalendarCard and TodaysSummaryCard show correct "today" highlighting
            if timezoneChanged {
                viewingDate = CalendarUtils.startOfDayLocal(for: Date(), timezone: displayTimezone)
                logger.log(
                    "Timezone changed - recalculated viewingDate",
                    level: .info,
                    category: .stateManagement,
                    metadata: [
                        "newTimezone": displayTimezone.identifier,
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
            cachedUserName = await getUserName()

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
            self.todaysSummary = extractTodaysSummary(from: overviewData)
            self.activeStreaks = extractActiveStreaks(from: overviewData)
            self.monthlyCompletionData = extractMonthlyData(from: overviewData)
            self.smartInsights = extractSmartInsights(from: overviewData)
            
            // Load personality insights separately (non-blocking)
            // Note: loadPersonalityInsights() handles errors internally with logging
            Task { @MainActor in
                await loadPersonalityInsights()
            }
            
            // Check if we should show inspiration card contextually
            self.checkAndShowInspirationCard()
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
    }
    
    public func refresh() async {
        logger.log(
            "Manual refresh requested",
            level: .info,
            category: .userAction,
            metadata: ["action": "User initiated data reload"]
        )
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

    public func openPersonalityAnalysis() {
        personalityDeepLinkCoordinator.showPersonalityAnalysisDirectly()
    }
    
    public func refreshPersonalityInsights() async {
        await loadPersonalityInsights()
    }
    
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
                // - date: Uses display timezone to determine which "day" the log belongs to
                // - timezone: Records device timezone (where user physically is) for audit/analytics
                let log = HabitLog(
                    id: UUID(),
                    habitID: habit.id,
                    date: CalendarUtils.startOfDayLocal(for: viewingDate, timezone: displayTimezone),
                    value: 1.0,
                    timezone: TimeZone.current.identifier
                )

                try await logHabit.execute(log)

                // CACHE SYNC: Update cache instead of full reload
                updateCachedLog(log)

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
            let allLogs = try await getLogs.execute(for: habit.id, since: viewingDate, until: viewingDate)
            let logsForDate = allLogs.filter { CalendarUtils.areSameDayLocal($0.date, viewingDate, timezone: displayTimezone) }

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

            if existingLogsForDate.isEmpty {
                // No existing log for this date - create new one
                // - date: Uses display timezone to determine which "day" the log belongs to
                // - timezone: Records device timezone (where user physically is) for audit/analytics
                log = HabitLog(
                    id: UUID(),
                    habitID: habit.id,
                    date: CalendarUtils.startOfDayLocal(for: viewingDate, timezone: displayTimezone),
                    value: value,
                    timezone: TimeZone.current.identifier
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

                // - date: Uses display timezone to determine which "day" the log belongs to
                // - timezone: Records device timezone (where user physically is) for audit/analytics
                log = HabitLog(
                    id: UUID(),
                    habitID: habit.id,
                    date: CalendarUtils.startOfDayLocal(for: viewingDate, timezone: displayTimezone),
                    value: value,
                    timezone: TimeZone.current.identifier
                )
                try await logHabit.execute(log)
            }

            // CACHE SYNC: Update cache instead of full reload
            updateCachedLog(log)

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
        HabitScheduleStatus.forHabit(habit, date: viewingDate, isScheduledDay: isScheduledDay)
    }

    public func getStreakStatusSync(for habit: Habit) -> HabitStreakStatus {
        // Use single source of truth from overviewData if available
        guard let data = overviewData else {
            // Return default status with no streak if data not loaded
            return HabitStreakStatus(current: 0, atRisk: 0, isAtRisk: false, isTodayScheduled: false)
        }

        let logs = data.habitLogs[habit.id] ?? []
        return getStreakStatusUseCase.execute(habit: habit, logs: logs, asOf: viewingDate)
    }
    
//    public func getWeeklyProgress(for habit: Habit) -> (completed: Int, target: Int) {
//        guard case .timesPerWeek = habit.schedule else {
//            return (completed: 0, target: 0)
//        }
//        
//        do {
//            // Get logs for the current week
//            let weekStart = CalendarUtils.startOfWeekUTC(for: viewingDate)
//            let weekEnd = CalendarUtils.endOfWeekUTC(for: viewingDate)
//            let logs = try loadLogsSynchronously(for: habit.id, from: weekStart, to: weekEnd)
//            
//            // Calculate weekly progress using business logic
//            guard case .timesPerWeek(let weeklyTarget) = habit.schedule else { return (0, 0) }
//            let filteredLogs = logs.filter { log in
//                log.habitID == habit.id && log.value != nil && log.value! > 0
//            }
//            let uniqueDays = Set(filteredLogs.map { log in
//                CalendarUtils.startOfDayUTC(for: log.date)
//            })
//            
//            return (uniqueDays.count, weeklyTarget)
//        } catch {
//            return (completed: 0, target: 0)
//        }
//    }
    
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
    
    public func showInspiration() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showInspirationCard = true
        }
    }
    
    public func triggerMotivation() {
        // Manual motivation trigger - can be called from UI buttons or gestures
        let trigger: InspirationTrigger = {
            guard let summary = todaysSummary else { return .morningMotivation }
            
            let completionRate = summary.completionPercentage
            let timeOfDay = currentTimeOfDay
            
            if completionRate >= 1.0 {
                return .perfectDay
            } else if completionRate >= 0.75 {
                return .strongFinish
            } else if completionRate >= 0.5 {
                return .halfwayPoint
            } else {
                switch timeOfDay {
                case .morning: return .morningMotivation
                case .noon: return .strugglingMidDay
                case .evening: return .eveningReflection
                }
            }
        }()
        
        showInspirationWithTrigger(trigger)
    }
    
    private func checkForComebackStory(currentCompletion: Double) async -> Bool {
        // Check if today's progress is significantly better than yesterday
        let yesterday = CalendarUtils.addDaysLocal(-1, to: Date(), timezone: displayTimezone)

        do {
            let yesterdayHabits = try await getActiveHabits.execute()
            var yesterdayCompletedCount = 0

            for habit in yesterdayHabits {
                let logs = try await getLogs.execute(for: habit.id, since: yesterday, until: yesterday)
                if logs.contains(where: { CalendarUtils.areSameDayLocal($0.date, yesterday, timezone: displayTimezone) }) {
                    yesterdayCompletedCount += 1
                }
            }
            
            let yesterdayCompletion = yesterdayHabits.isEmpty ? 0.0 : Double(yesterdayCompletedCount) / Double(yesterdayHabits.count)
            
            // If today is 25%+ better than yesterday, it's a comeback story
            return currentCompletion > yesterdayCompletion + 0.25 && yesterdayCompletion < 0.6
        } catch {
            // Log error but gracefully degrade - comeback detection is non-critical
            logger.log(
                "Comeback story detection failed - falling back to false",
                level: .warning,
                category: .dataIntegrity,
                metadata: ["error": error.localizedDescription]
            )
            return false
        }
    }
    
    public func hideInspiration() {
        // Mark current trigger as dismissed for today
        if let currentTrigger = lastShownInspirationTrigger {
            dismissedTriggersToday.insert(currentTrigger)
            saveDismissedTriggers()
        }
        showInspirationCard = false
        inspirationItems = []
    }

    /// Dismiss a single inspiration item from the carousel
    public func dismissInspirationItem(_ item: InspirationItem) {
        // Mark the trigger as dismissed
        dismissedTriggersToday.insert(item.trigger)
        saveDismissedTriggers()

        // Remove from items
        inspirationItems.removeAll { $0.id == item.id }

        // Update trigger cache to reflect dismissal
        lastEvaluatedTriggerSet.remove(item.trigger)

        // Update cached message if needed
        if inspirationItems.isEmpty {
            showInspirationCard = false
            cachedInspirationMessage = nil
            lastEvaluatedTriggerSet = []
        } else {
            cachedInspirationMessage = inspirationItems.first?.message
        }

        logger.log(
            "Dismissed inspiration item",
            level: .debug,
            category: .ui,
            metadata: [
                "trigger": item.trigger.displayName,
                "remaining_count": inspirationItems.count
            ]
        )
    }

    /// Dismiss all inspiration items in the carousel
    public func dismissAllInspirationItems() {
        // Mark all triggers as dismissed
        for item in inspirationItems {
            dismissedTriggersToday.insert(item.trigger)
        }
        saveDismissedTriggers()

        // Clear trigger cache since all items are dismissed
        lastEvaluatedTriggerSet = []

        // Hide the carousel first (triggers slide-up animation on container)
        showInspirationCard = false
        cachedInspirationMessage = nil

        // Clear items synchronously since carousel is already hidden
        // Previous implementation used a delayed Task which could leak if called rapidly
        inspirationItems = []

        logger.log(
            "Dismissed all inspiration items",
            level: .debug,
            category: .ui,
            metadata: ["dismissed_count": dismissedTriggersToday.count]
        )
    }
    
    private func checkAndShowInspirationCard() {
        guard isViewingToday, let summary = todaysSummary else {
            logger.log(
                "Skipping inspiration check",
                level: .debug,
                category: .ui,
                metadata: [
                    "is_viewing_today": isViewingToday,
                    "has_summary": todaysSummary != nil
                ]
            )
            return
        }

        // Skip inspiration entirely if user has no habits at all (new user)
        let totalHabitsCount = overviewData?.habits.count ?? 0
        guard totalHabitsCount > 0 else {
            logger.log(
                "Skipping inspiration - user has no habits",
                level: .debug,
                category: .ui
            )
            return
        }

        logger.log(
            "Evaluating inspiration triggers",
            level: .debug,
            category: .ui,
            metadata: ["completion": summary.completionPercentage]
        )

        Task {
            let triggers = await evaluateInspirationTriggers(summary: summary, totalHabitsCount: totalHabitsCount)
            logger.log(
                "Evaluated inspiration triggers",
                level: .debug,
                category: .ui,
                metadata: [
                    "trigger_count": triggers.count,
                    "triggers": triggers.map { $0.displayName }.joined(separator: ", ")
                ]
            )

            // Get all available triggers (filtered and sorted by priority)
            let availableTriggers = selectAvailableTriggers(from: triggers)

            if !availableTriggers.isEmpty {
                // Check if triggers have actually changed to prevent unnecessary carousel rebuilds
                let newTriggerSet = Set(availableTriggers)
                if newTriggerSet == lastEvaluatedTriggerSet && showInspirationCard && !inspirationItems.isEmpty {
                    logger.log(
                        "Skipping carousel rebuild - triggers unchanged",
                        level: .debug,
                        category: .ui,
                        metadata: ["trigger_count": availableTriggers.count]
                    )
                    return
                }

                logger.log(
                    "Showing inspiration carousel",
                    level: .debug,
                    category: .ui,
                    metadata: [
                        "trigger_count": availableTriggers.count,
                        "triggers": availableTriggers.map { $0.displayName }.joined(separator: ", "),
                        "triggers_changed": newTriggerSet != lastEvaluatedTriggerSet
                    ]
                )

                lastEvaluatedTriggerSet = newTriggerSet
                await showInspirationWithTriggers(availableTriggers)
            } else {
                logger.log(
                    "No inspiration trigger selected",
                    level: .debug,
                    category: .ui,
                    metadata: ["reason": "All triggers filtered or empty"]
                )
                // Clear the cached trigger set when no triggers available
                lastEvaluatedTriggerSet = []
            }
        }
    }
    
    // MARK: - Trigger Evaluation System
    //
    // The inspiration trigger system uses category-based selection to show relevant,
    // non-redundant messages. Each category allows at most ONE trigger to avoid
    // showing multiple cards that say essentially the same thing.
    //
    // ## Categories (max 1 trigger per category):
    //
    // 1. **Progress** - Based on completion percentage (mutually exclusive):
    //    - `perfectDay` (100%) - Highest priority, celebration
    //    - `strongFinish` (75%+) - Almost there
    //    - `halfwayPoint` (50%+) - Good progress
    //    - `firstHabitComplete` (>0%, 1 habit) - Just getting started
    //
    // 2. **Time-of-Day** - Based on current time period (mutually exclusive):
    //    - `morningMotivation` (morning, 0% done) - Start the day
    //    - `strugglingMidDay` (noon, <40%) - Behind at midday
    //    - `afternoonPush` (3-4:59 PM, <60%) - Afternoon encouragement
    //    - `eveningReflection` (evening, 60%+) - End of day reflection
    //
    // 3. **Special Context** - Situational triggers (mutually exclusive):
    //    - `weekendMotivation` (weekend) - Weekend dedication
    //    - `comebackStory` (improved from yesterday) - Recovery celebration
    //
    // 4. **Edge Cases** (shown alone):
    //    - `emptyDay` - No habits scheduled today
    //
    // ## Valid Combinations (1-3 cards):
    // - Progress + Time + Special (e.g., `halfwayPoint` + `afternoonPush` + `comebackStory`)
    // - Progress + Special (e.g., `strongFinish` + `weekendMotivation`)
    // - Progress alone (e.g., `perfectDay` - celebration is enough)
    // - Time alone (e.g., `morningMotivation` when no progress yet)
    //
    // ## Invalid Combinations (avoided by design):
    // - Multiple progress triggers (e.g., `halfwayPoint` + `strongFinish`)
    // - Multiple time triggers (e.g., `morningMotivation` + `afternoonPush`)
    // - Multiple special triggers (e.g., `weekendMotivation` + `comebackStory`)
    //
    // ## Edge Case Triggers (shown alone):
    // - `sessionStart` - User has no habits created yet (welcome/onboarding)
    // - `emptyDay` - User has habits but none scheduled today

    private func evaluateInspirationTriggers(summary: TodaysSummary, totalHabitsCount: Int) async -> [InspirationTrigger] {
        var triggers: [InspirationTrigger] = []
        let completionRate = summary.completionPercentage
        let now = Date()
        let hour = CalendarUtils.hourComponentLocal(from: now)
        let isWeekend = [1, 7].contains(CalendarUtils.weekdayComponentLocal(from: now))

        // EDGE CASE: No habits created yet (brand new user)
        // Shows sessionStart as welcome/onboarding message
        if totalHabitsCount == 0 {
            return [.sessionStart]
        }

        // EDGE CASE: Empty Day (no habits scheduled today but has habits on other days)
        // Shows alone - other triggers don't make sense without scheduled habits
        if summary.totalHabits == 0 {
            return [.emptyDay]
        }

        // CATEGORY 1: Progress-based (pick highest applicable, mutually exclusive)
        let progressTrigger = evaluateProgressTrigger(
            completionRate: completionRate,
            completedCount: summary.completedHabitsCount
        )
        if let trigger = progressTrigger {
            triggers.append(trigger)
        }

        // CATEGORY 2: Time-of-day (pick one based on current time, mutually exclusive)
        let timeTrigger = evaluateTimeTrigger(
            completionRate: completionRate,
            hour: hour
        )
        if let trigger = timeTrigger {
            triggers.append(trigger)
        }

        // CATEGORY 3: Special context (pick one if applicable, mutually exclusive)
        let specialTrigger = await evaluateSpecialTrigger(
            completionRate: completionRate,
            isWeekend: isWeekend
        )
        if let trigger = specialTrigger {
            triggers.append(trigger)
        }

        return triggers
    }

    /// Evaluates progress-based triggers (Category 1)
    /// Returns at most ONE trigger based on completion percentage
    /// Priority: perfectDay > strongFinish > halfwayPoint > firstHabitComplete
    private func evaluateProgressTrigger(completionRate: Double, completedCount: Int) -> InspirationTrigger? {
        if completionRate >= 1.0 {
            return .perfectDay
        } else if completionRate >= 0.75 {
            return .strongFinish
        } else if completionRate >= 0.5 {
            return .halfwayPoint
        } else if completionRate > 0.0 && completedCount == 1 {
            return .firstHabitComplete
        }
        return nil
    }

    /// Evaluates time-of-day triggers (Category 2)
    /// Returns at most ONE trigger based on current time and progress
    /// Triggers are mutually exclusive by time period
    private func evaluateTimeTrigger(completionRate: Double, hour: Int) -> InspirationTrigger? {
        let timeOfDay = currentTimeOfDay

        switch timeOfDay {
        case .morning:
            // Morning motivation only when no progress yet
            if completionRate == 0.0 {
                return .morningMotivation
            }
        case .noon:
            // Struggling mid-day when significantly behind
            if completionRate < 0.4 {
                return .strugglingMidDay
            }
            // Afternoon push (3-4:59 PM) when moderately behind
            // Note: This can fire during "noon" period if hour is 15-16
            if hour >= 15 && hour < 17 && completionRate < 0.6 {
                return .afternoonPush
            }
        case .evening:
            // Evening reflection when good progress made
            if completionRate >= 0.6 {
                return .eveningReflection
            }
        }

        return nil
    }

    /// Evaluates special context triggers (Category 3)
    /// Returns at most ONE trigger based on situational context
    /// Priority: comebackStory > weekendMotivation (comeback is more specific)
    private func evaluateSpecialTrigger(completionRate: Double, isWeekend: Bool) async -> InspirationTrigger? {
        // Comeback story takes priority (more specific achievement)
        if await checkForComebackStory(currentCompletion: completionRate) {
            return .comebackStory
        }

        // Weekend motivation as fallback special context
        if isWeekend {
            return .weekendMotivation
        }

        return nil
    }
    
    /// Returns all available triggers sorted by priority (highest first), limited to BusinessConstants.maxInspirationCarouselItems
    private func selectAvailableTriggers(from triggers: [InspirationTrigger]) -> [InspirationTrigger] {
        logger.log(
            "Filtering dismissed triggers",
            level: .debug,
            category: .ui,
            metadata: [
                "dismissed_today": dismissedTriggersToday.map { $0.displayName }.joined(separator: ", ")
            ]
        )

        // Filter out triggers that are dismissed today
        let filteredTriggers = triggers.filter { trigger in
            // Skip if already dismissed today
            if dismissedTriggersToday.contains(trigger) {
                logger.log(
                    "Skipping trigger",
                    level: .debug,
                    category: .ui,
                    metadata: [
                        "trigger": trigger.displayName,
                        "reason": "Already dismissed today"
                    ]
                )
                return false
            }
            return true
        }

        // Sort by priority and limit to max items
        let sorted = filteredTriggers.sorted { $0.priority > $1.priority }
        return Array(sorted.prefix(BusinessConstants.maxInspirationCarouselItems))
    }
    
    private func showInspirationWithTrigger(_ trigger: InspirationTrigger) {
        let delay: Int = {
            switch trigger {
            case .perfectDay:
                return 1200  // Celebrate immediately but with dramatic pause
            case .firstHabitComplete, .halfwayPoint, .strongFinish:
                return 800   // Quick positive reinforcement
            case .sessionStart:
                return 2000  // Let user settle in first
            case .emptyDay:
                return 1500  // Standard timing - gentle reminder
            default:
                return 1500  // Standard timing
            }
        }()

        logger.log(
            "Showing inspiration trigger",
            level: .debug,
            category: .ui,
            metadata: [
                "trigger": trigger.displayName,
                "delay_ms": delay
            ]
        )

        Task {
            try? await Task.sleep(for: .milliseconds(delay))

            // Generate and cache personalized message before showing card
            let message = await getPersonalizedMessage(for: trigger)
            self.cachedInspirationMessage = message

            logger.log(
                "Activating inspiration card",
                level: .debug,
                category: .ui,
                metadata: ["trigger": trigger.displayName]
            )
            self.lastShownInspirationTrigger = trigger
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.showInspirationCard = true
            }
        }
    }

    /// Shows multiple inspiration cards in the carousel
    private func showInspirationWithTriggers(_ triggers: [InspirationTrigger]) async {
        // Safe unwrap - defensive programming even though we check isEmpty
        guard let primaryTrigger = triggers.first else { return }
        let delay: Int = {
            switch primaryTrigger {
            case .perfectDay:
                return 1200
            case .firstHabitComplete, .halfwayPoint, .strongFinish:
                return 800
            case .sessionStart:
                return 2000
            default:
                return 1500
            }
        }()

        try? await Task.sleep(for: .milliseconds(delay))

        // Generate personalized messages for all triggers
        var items: [InspirationItem] = []

        // Get unique slogans for each card (one per trigger)
        let uniqueSlogans = getCurrentSlogan.getUniqueSlogans(count: triggers.count, for: currentTimeOfDay)

        // Track seen messages to prevent duplicates
        var seenMessages: Set<String> = []
        var sloganIndex = 0

        for trigger in triggers {
            let message = await getPersonalizedMessage(for: trigger)

            // Skip if we already have this exact message (prevents duplicate cards)
            guard !seenMessages.contains(message) else {
                logger.log(
                    "Skipping duplicate message",
                    level: .debug,
                    category: .ui,
                    metadata: ["trigger": trigger.displayName, "message": message]
                )
                continue
            }
            seenMessages.insert(message)

            // Use unique slogan for each card
            let slogan = sloganIndex < uniqueSlogans.count
                ? uniqueSlogans[sloganIndex]
                : getCurrentSlogan.execute()
            sloganIndex += 1

            if let item = InspirationItem(
                trigger: trigger,
                message: message,
                slogan: slogan
            ) {
                items.append(item)
            }
        }

        logger.log(
            "Activating inspiration carousel",
            level: .debug,
            category: .ui,
            metadata: [
                "item_count": items.count,
                "triggers": triggers.map { $0.displayName }.joined(separator: ", "),
                "duplicates_filtered": triggers.count - items.count
            ]
        )

        // Update state with animation for smooth entrance
        self.inspirationItems = items
        self.cachedInspirationMessage = items.first?.message
        self.lastShownInspirationTrigger = primaryTrigger
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            self.showInspirationCard = true
        }
    }

    public var currentInspirationMessage: String {
        // Use cached message if available, otherwise fallback to slogan
        cachedInspirationMessage ?? getCurrentSlogan.execute()
    }
    
    // MARK: - Private Methods

    /// Load overview data from database using the display timezone
    private func loadOverviewData() async throws -> OverviewData {
        // 1. Load habits ONCE
        let habits = try await getActiveHabits.execute()

        // 2. Determine date range (past 30 days for monthly data) using display timezone
        let today = Date()
        let startDate = CalendarUtils.addDaysLocal(-30, to: today, timezone: displayTimezone)

        // 3. Load logs ONCE for entire date range using batch operation
        let habitIds = habits.map(\.id)
        let habitLogs = try await getBatchLogs.execute(
            for: habitIds,
            since: startDate,
            until: today
        )

        return OverviewData(
            habits: habits,
            habitLogs: habitLogs,
            dateRange: startDate...today,
            timezone: displayTimezone
        )
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
        guard var data = overviewData else {
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
            dateRange: data.dateRange
        )

        refreshUIState(with: updatedData)
    }

    /// Remove logs from cache after successful database delete
    private func removeCachedLogs(habitId: UUID, on date: Date) {
        guard var data = overviewData else {
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
        habitLogs.removeAll { log in
            CalendarUtils.areSameDayLocal(log.date, date)
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
            dateRange: data.dateRange
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
        self.smartInsights = extractSmartInsights(from: data)
        self.checkAndShowInspirationCard()
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
        let dateStart = CalendarUtils.startOfDayLocal(for: date)
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
        let targetDate = viewingDate
        let habits = data.scheduledHabits(for: targetDate)

        logger.logDataIntegrity(
            check: "extractTodaysSummary",
            passed: true,
            metadata: [
                "target_date": targetDate.description,
                "total_habits": data.habits.count,
                "scheduled_habits": habits.count,
                "habits_detail": data.habits.map { habit in
                    let isScheduled = habit.schedule.isActiveOn(date: targetDate)
                    return "\(habit.name): \(isScheduled ? "scheduled" : "not scheduled")"
                }.joined(separator: "; ")
            ]
        )
        
        var allTargetDateLogs: [HabitLog] = []
        var incompleteHabits: [Habit] = []
        var completedHabits: [Habit] = []
        
        for habit in habits {
            let logs = data.logs(for: habit.id, on: targetDate)
            allTargetDateLogs.append(contentsOf: logs)
            
            // Use centralized completion service for consistent calculation
            let isCompleted = isHabitCompleted.execute(habit: habit, on: targetDate, logs: logs)
            
            // Only show as incomplete if not completed AND not a future date
            if targetDate > Date() {
                // Don't add future dates to incomplete list
                if isCompleted {
                    completedHabits.append(habit)
                }
            } else {
                // Past/present dates
                if isCompleted {
                    completedHabits.append(habit)
                } else {
                    incompleteHabits.append(habit)
                }
            }
        }
        
        // Sort completed habits by latest log time (most recent first)
        completedHabits.sort { habit1, habit2 in
            let habit1Logs = allTargetDateLogs.filter { $0.habitID == habit1.id }
            let habit2Logs = allTargetDateLogs.filter { $0.habitID == habit2.id }
            let habit1LatestTime = habit1Logs.map { $0.date }.max() ?? Date.distantPast
            let habit2LatestTime = habit2Logs.map { $0.date }.max() ?? Date.distantPast
            return habit1LatestTime > habit2LatestTime  // Most recent first
        }
        
        let completionPercentage = habits.isEmpty ? 0.0 : Double(completedHabits.count) / Double(habits.count)
        
        return TodaysSummary(
            completedHabitsCount: completedHabits.count,
            completedHabits: completedHabits,
            totalHabits: habits.count,
            incompleteHabits: incompleteHabits
        )
    }
    
    /// Extract monthly completion data from overview data using the display timezone
    private func extractMonthlyData(from data: OverviewData) -> [Date: Double] {
        var result: [Date: Double] = [:]

        // Get dates from range, ensuring we use startOfDay for consistency with display timezone
        for dayOffset in 0...30 {
            let date = CalendarUtils.addDaysLocal(-dayOffset, to: Date(), timezone: displayTimezone)
            let startOfDay = CalendarUtils.startOfDayLocal(for: date, timezone: displayTimezone)
            // Use HabitCompletionService for single source of truth completion rate
            let scheduledHabits = data.scheduledHabits(for: startOfDay)
            if scheduledHabits.isEmpty {
                result[startOfDay] = 0.0
            } else {
                let completedCount = scheduledHabits.count { habit in
                    let logs = data.logs(for: habit.id, on: startOfDay)
                    return isHabitCompleted.execute(habit: habit, on: startOfDay, logs: logs, timezone: displayTimezone)
                }
                result[startOfDay] = Double(completedCount) / Double(scheduledHabits.count)
            }
        }

        return result
    }
    
    /// Extract active streaks from overview data (with grace period support) using display timezone
    private func extractActiveStreaks(from data: OverviewData) -> [StreakInfo] {
        var streaks: [StreakInfo] = []
        let today = Date()

        for habit in data.habits {
            // Get logs for this habit from unified data
            let logs = data.habitLogs[habit.id] ?? []

            // Use getStreakStatus for grace period support with display timezone
            let streakStatus = getStreakStatusUseCase.execute(habit: habit, logs: logs, asOf: today, timezone: displayTimezone)

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
    
    /// Extract smart insights from unified overview data using the display timezone
    /// Uses pre-loaded data and UseCases for consistency
    private func extractSmartInsights(from data: OverviewData) -> [SmartInsight] {
        var insights: [SmartInsight] = []
        let today = Date()

        // Get the proper week interval that respects user's first day of week preference and display timezone
        let weekInterval = CalendarUtils.weekIntervalLocal(for: today, timezone: displayTimezone) ?? DateInterval(start: today, duration: 0)
        let startOfWeek = weekInterval.start

        // Use unified data instead of separate queries
        guard !data.habits.isEmpty else {
            return []
        }

        // Analyze completion patterns over the past week using unified data
        var totalCompletions = 0
        var dailyCompletions: [Int] = Array(repeating: 0, count: 7)

        for habit in data.habits {
            let logs = data.habitLogs[habit.id] ?? []
            let recentLogs = logs.filter { log in
                log.date >= startOfWeek && log.date < weekInterval.end
            }

            // Count actual completions using IsHabitCompletedUseCase for single source of truth
            for log in recentLogs {
                let dayLogs = logs.filter { CalendarUtils.areSameDayLocal($0.date, log.date, timezone: displayTimezone) }
                if isHabitCompleted.execute(habit: habit, on: log.date, logs: dayLogs, timezone: displayTimezone) {
                    totalCompletions += 1

                    // Count completions per day
                    let daysSinceStart = CalendarUtils.daysBetweenLocal(startOfWeek, log.date, timezone: displayTimezone)
                    if daysSinceStart >= 0 && daysSinceStart < 7 {
                        dailyCompletions[daysSinceStart] += 1
                    }
                }
            }
        }
        
        let totalPossibleCompletions = data.habits.count * 7
        let completionRate = totalPossibleCompletions > 0 ? Double(totalCompletions) / Double(totalPossibleCompletions) : 0.0
        
        // Generate insights based on actual patterns
        if completionRate >= 0.8 {
            insights.append(SmartInsight(
                title: "Excellent Consistency",
                message: "You're completing \(Int(completionRate * 100))% of your habits this week!",
                type: .celebration
            ))
        } else if completionRate >= 0.6 {
            insights.append(SmartInsight(
                title: "Good Progress",
                message: "You're on track with \(Int(completionRate * 100))% completion. Keep building momentum!",
                type: .pattern
            ))
        } else if completionRate >= 0.3 {
            insights.append(SmartInsight(
                title: "Room for Growth",
                message: "Focus on consistency - even small daily wins add up to big results.",
                type: .suggestion
            ))
        } else {
            insights.append(SmartInsight(
                title: "Fresh Start",
                message: "Every day is a new opportunity. Start with just one habit today.",
                type: .suggestion
            ))
        }
        
        return insights
    }
    
    private func loadSmartInsights() async throws -> [SmartInsight] {
        // DEPRECATED: This method is being replaced by extractSmartInsights()
        // which uses unified OverviewData instead of separate queries
        try await generateBasicHabitInsights()
    }
    
    private func loadPersonalityInsights() async {
        do {
            // Always get eligibility and requirements info using the UseCase
            let userId = await getUserId()
            let eligibility = try await validateAnalysisDataUseCase.execute(for: userId)
            let requirements = try await validateAnalysisDataUseCase.getProgressDetails(for: userId)
            
            // Update state with eligibility info
            isPersonalityDataSufficient = eligibility.isEligible
            personalityThresholdRequirements = requirements
            
            // Always show the card now - it will handle different states internally
            shouldShowPersonalityInsights = true
            
            // Get existing personality profile
            var personalityProfile = try await getPersonalityProfileUseCase.execute(for: userId)
            
            // If user is eligible but no profile exists, attempt to create one
            if eligibility.isEligible && personalityProfile == nil {
                do {
                    let newProfile = try await updatePersonalityAnalysisUseCase.execute(for: userId)
                    personalityProfile = newProfile
                } catch {
                    // Log the error - analysis creation failures shouldn't crash the app
                    logger.log("Failed to create personality analysis: \(error.localizedDescription)", level: .error, category: .dataIntegrity)
                    // If analysis fails, we still show the card but with error state
                    personalityInsights = []
                    dominantPersonalityTrait = nil
                    return
                }
            }
            
            // If we have a profile, get insights from it
            if let profile = personalityProfile {
                let insights = getPersonalityInsightsUseCase.getAllInsights(for: profile)
                
                // Convert to OverviewPersonalityInsight format for the new card
                var cardInsights: [OverviewPersonalityInsight] = []
                
                // Add pattern insights
                for insight in insights.patternInsights.prefix(2) {
                    cardInsights.append(OverviewPersonalityInsight(
                        title: insight.title,
                        message: insight.description,
                        type: .pattern
                    ))
                }
                
                // Add habit recommendations
                for insight in insights.habitRecommendations.prefix(2) {
                    cardInsights.append(OverviewPersonalityInsight(
                        title: insight.title,
                        message: insight.actionable,
                        type: .recommendation
                    ))
                }
                
                // Add one motivational insight
                if let motivationalInsight = insights.motivationalInsights.first {
                    cardInsights.append(OverviewPersonalityInsight(
                        title: motivationalInsight.title,
                        message: motivationalInsight.actionable,
                        type: .motivation
                    ))
                }
                
                personalityInsights = cardInsights
                dominantPersonalityTrait = profile.dominantTrait.displayName
            } else {
                // No profile available (either data insufficient or analysis failed)
                personalityInsights = []
                dominantPersonalityTrait = nil
            }
        } catch {
            // Log the error for debugging - personality analysis failures shouldn't crash the app
            logger.log("Failed to load personality insights: \(error.localizedDescription)", level: .error, category: .dataIntegrity)
            // Even on error, show the card but with empty state
            personalityInsights = []
            dominantPersonalityTrait = nil
            isPersonalityDataSufficient = false
            personalityThresholdRequirements = []
        }
    }
    
    private func checkPersonalityAnalysisEligibility() async throws -> Bool {
        // Use proper UseCases instead of direct repository access
        do {
            let userId = await getUserId()
            // Check if personality analysis service is enabled for this user
            let isEnabled = try await isPersonalityAnalysisEnabledUseCase.execute(for: userId)
            
            guard isEnabled else {
                return false
            }
            
            // Use the proper eligibility validation UseCase
            let eligibility = try await validateAnalysisDataUseCase.execute(for: userId)
            return eligibility.isEligible
        } catch {
            return false
        }
    }
    
    private func generateBasicHabitInsights() async throws -> [SmartInsight] {
        var insights: [SmartInsight] = []
        let today = Date()

        // Get the proper week interval that respects user's first day of week preference
        let weekInterval = CalendarUtils.weekIntervalLocal(for: today) ?? DateInterval(start: today, duration: 0)
        let startOfWeek = weekInterval.start
        
        // Get user's active habits and recent logs
        let habits = try await getActiveHabits.execute()
        guard !habits.isEmpty else {
            return []
        }
        
        // Analyze completion patterns over the past week
        var totalCompletions = 0
        var dailyCompletions: [Int] = Array(repeating: 0, count: 7)
        
        // OPTIMIZATION: Batch load logs for all habits to avoid N+1 queries
        let habitIds = habits.map(\.id)
        let logsByHabitId = try await getBatchLogs.execute(for: habitIds, since: startOfWeek, until: weekInterval.end)
        
        for habit in habits {
            let logs = logsByHabitId[habit.id] ?? []
            let recentLogs = logs.filter { log in
                log.date >= startOfWeek && log.date < weekInterval.end
            }
            
            totalCompletions += recentLogs.count
            
            // Count completions per day
            for log in recentLogs {
                let daysSinceStart = CalendarUtils.daysBetweenLocal(startOfWeek, log.date)
                if daysSinceStart >= 0 && daysSinceStart < 7 {
                    dailyCompletions[daysSinceStart] += 1
                }
            }
        }
        
        let totalPossibleCompletions = habits.count * 7
        let completionRate = totalPossibleCompletions > 0 ? Double(totalCompletions) / Double(totalPossibleCompletions) : 0.0
        
        // Generate insights based on actual patterns
        if completionRate >= 0.8 {
            insights.append(SmartInsight(
                title: "Excellent Consistency",
                message: "You're completing \(Int(completionRate * 100))% of your habits this week!",
                type: .celebration
            ))
        } else if completionRate >= 0.6 {
            insights.append(SmartInsight(
                title: "Good Progress",
                message: "You're on track with \(Int(completionRate * 100))% completion. Keep building momentum!",
                type: .pattern
            ))
        } else if completionRate >= 0.3 {
            insights.append(SmartInsight(
                title: "Room for Growth",
                message: "Focus on consistency - even small daily wins add up to big results.",
                type: .suggestion
            ))
        } else {
            insights.append(SmartInsight(
                title: "Fresh Start",
                message: "Every day is a new opportunity. Start with just one habit today.",
                type: .suggestion
            ))
        }
        
        // Find best performing day
        if let bestDayIndex = dailyCompletions.enumerated().max(by: { $0.element < $1.element })?.offset {
            // Get the actual date for the best performing day using display timezone
            let bestDate = CalendarUtils.addDaysLocal(bestDayIndex, to: startOfWeek, timezone: displayTimezone)

            // Get the day name using the proper date and timezone
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            dayFormatter.timeZone = displayTimezone
            let bestDayName = dayFormatter.string(from: bestDate)
            
            if dailyCompletions[bestDayIndex] > 0 {
                insights.append(SmartInsight(
                    title: "\(bestDayName) Strength",
                    message: "You completed \(dailyCompletions[bestDayIndex]) habits on \(bestDayName) - your strongest day!",
                    type: .pattern
                ))
            }
        }
        
        // Add motivational insight if they have multiple habits
        if habits.count >= 3 {
            insights.append(SmartInsight(
                title: "Multi-Habit Builder",
                message: "Tracking \(habits.count) habits shows commitment to growth. Focus on consistency over perfection.",
                type: .suggestion
            ))
        }
        
        return insights
    }
    
    private func resetDismissedTriggersIfNewDay() {
        let today = Date()

        // Check if we've moved to a new day since last session
        if let lastResetDate = UserDefaults.standard.object(forKey: UserDefaultsKeys.lastInspirationResetDate) as? Date {
            if !CalendarUtils.areSameDayLocal(lastResetDate, today) {
                // New day - reset all inspiration state
                dismissedTriggersToday.removeAll()
                lastEvaluatedTriggerSet = []
                UserDefaults.standard.set(today, forKey: UserDefaultsKeys.lastInspirationResetDate)
            } else {
                // Load dismissed triggers for today from UserDefaults
                if let dismissedData = UserDefaults.standard.data(forKey: UserDefaultsKeys.dismissedTriggersToday) {
                    do {
                        let dismissedArray = try JSONDecoder().decode([String].self, from: dismissedData)
                        dismissedTriggersToday = Set(dismissedArray.compactMap { triggerString in
                            InspirationTrigger.allCases.first { "\($0)" == triggerString }
                        })
                    } catch {
                        logger.log(
                            "Failed to decode dismissed triggers - resetting to empty",
                            level: .warning,
                            category: .dataIntegrity,
                            metadata: ["error": error.localizedDescription]
                        )
                        dismissedTriggersToday = []
                    }
                }
            }
        } else {
            // First time - set today as reset date
            UserDefaults.standard.set(today, forKey: UserDefaultsKeys.lastInspirationResetDate)
        }
    }
    
    private func saveDismissedTriggers() {
        let dismissedArray = dismissedTriggersToday.map { "\($0)" }
        do {
            let data = try JSONEncoder().encode(dismissedArray)
            UserDefaults.standard.set(data, forKey: UserDefaultsKeys.dismissedTriggersToday)
        } catch {
            logger.log(
                "Failed to encode dismissed triggers",
                level: .warning,
                category: .dataIntegrity,
                metadata: ["error": error.localizedDescription]
            )
        }
    }
    
    // MARK: - Personalized Inspiration Messages

    private func getPersonalizedMessage(for trigger: InspirationTrigger) async -> String {
        // Load personality profile
        let personalityProfile = await loadPersonalityProfileForMessage()

        // Get current streak (longest streak from activeStreaks, or 0)
        let currentStreakValue = activeStreaks.first?.currentStreak ?? 0

        // Build message context
        let context = MessageContext(
            trigger: trigger,
            personality: personalityProfile,
            completionPercentage: todaysSummary?.completionPercentage ?? 0.0,
            timeOfDay: currentTimeOfDay,
            userName: userName,
            currentStreak: currentStreakValue,
            recentPattern: analyzeRecentPattern()
        )

        // Generate personalized message
        let message = await personalizedMessageGenerator.generateMessage(for: context)
        return message.content
    }

    private func loadPersonalityProfileForMessage() async -> PersonalityProfile? {
        // Get user ID
        let userId = await getUserId()

        do {
            // Check if personality analysis is enabled and available
            let isEnabled = try await isPersonalityAnalysisEnabledUseCase.execute(for: userId)
            guard isEnabled else { return nil }

            // Get current personality profile
            return try await getPersonalityProfileUseCase.execute(for: userId)
        } catch {
            // Log error but gracefully degrade to generic messages
            logger.log(
                "Failed to load personality profile for message generation",
                level: .warning,
                category: .dataIntegrity,
                metadata: ["error": error.localizedDescription, "userId": userId]
            )
            return nil
        }
    }

    private func analyzeRecentPattern() -> CompletionPattern {
        // For Phase 1, return a basic pattern
        // Phase 2 will implement more sophisticated pattern analysis
        guard let completionPercentage = todaysSummary?.completionPercentage else {
            return .insufficient
        }

        // Simple heuristic based on current completion
        if completionPercentage >= 0.8 {
            return .consistent
        } else if completionPercentage >= 0.5 {
            return .improving
        } else if completionPercentage > 0 {
            return .declining
        } else {
            return .insufficient
        }
    }
    
    private var cachedUserName: String? = nil

    private func getUserName() async -> String? {
        let profile = await getCurrentUserProfile.execute()
        return profile.name.isEmpty ? nil : profile.name
    }

    private var userName: String? { cachedUserName }
}
