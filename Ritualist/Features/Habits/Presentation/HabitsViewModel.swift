import Foundation
import Observation
import FactoryKit
import RitualistCore

@MainActor @Observable
public final class HabitsViewModel { // swiftlint:disable:this type_body_length
    // MARK: - Factory Injected Dependencies
    @ObservationIgnored @Injected(\.loadHabitsData) var loadHabitsData
    @ObservationIgnored @Injected(\.createHabit) var createHabit
    @ObservationIgnored @Injected(\.updateHabit) var updateHabit
    @ObservationIgnored @Injected(\.deleteHabit) var deleteHabit
    @ObservationIgnored @Injected(\.toggleHabitActiveStatus) var toggleHabitActiveStatus
    @ObservationIgnored @Injected(\.reorderHabits) var reorderHabits
    @ObservationIgnored @Injected(\.checkHabitCreationLimit) var checkHabitCreationLimit
    @ObservationIgnored @Injected(\.createHabitFromSuggestionUseCase) var createHabitFromSuggestionUseCase
    @ObservationIgnored @Injected(\.userActionTracker) var userActionTracker
    @ObservationIgnored @Injected(\.paywallViewModel) var paywallViewModel
    @ObservationIgnored @Injected(\.cleanupOrphanedHabits) var cleanupOrphanedHabits
    @ObservationIgnored @Injected(\.isHabitCompleted) private var isHabitCompleted
    @ObservationIgnored @Injected(\.calculateDailyProgress) private var calculateDailyProgress
    @ObservationIgnored @Injected(\.isScheduledDay) private var isScheduledDay
    @ObservationIgnored @Injected(\.validateHabitSchedule) private var validateHabitScheduleUseCase
    @ObservationIgnored @Injected(\.getSingleHabitLogs) private var getSingleHabitLogs
    @ObservationIgnored @Injected(\.debugLogger) private var logger
    @ObservationIgnored @Injected(\.timezoneService) private var timezoneService
    
    // MARK: - Shared ViewModels
    
    // MARK: - Data State (Unified)
    public private(set) var habitsData = HabitsData(habits: [], categories: [])
    public private(set) var isLoading = false
    public private(set) var error: Error?
    public private(set) var isCreating = false
    public private(set) var isUpdating = false
    public private(set) var isDeleting = false
    public private(set) var isReordering = false

    /// Track if initial data has been loaded to prevent duplicate loads during startup
    @ObservationIgnored private var hasLoadedInitialData = false

    /// Track view visibility for tab switch detection
    public var isViewVisible: Bool = false

    /// Track if view has disappeared at least once (to distinguish initial appear from tab switch)
    @ObservationIgnored private var viewHasDisappearedOnce = false

    /// Cached display timezone for synchronous access in computed properties.
    /// Fetched once on load from TimezoneService.getDisplayTimezone().
    /// NOT marked @ObservationIgnored - allows SwiftUI to observe direct changes.
    /// Currently, timezone changes trigger full reload via iCloudDidSyncRemoteChanges notification,
    /// but keeping this observable provides a safeguard for future direct timezone updates.
    internal var displayTimezone: TimeZone = .current
    
    // MARK: - Category Filtering State
    public var selectedFilterCategory: HabitCategory?
    private var originalCategoryOrder: [HabitCategory] = []

    // MARK: - Navigation State
    public var showingCreateHabit = false
    public var selectedHabit: Habit?
    public var paywallItem: PaywallItem?
    
    // MARK: - Assistant Navigation State
    public var showingHabitAssistant = false
    public var shouldReopenAssistantAfterPaywall = false
    public var isHandlingPaywallDismissal = false
    public var pendingPaywallAfterAssistantDismiss = false
    
    // MARK: - Paywall Protection

    /// Cached premium status for SwiftUI reactivity.
    /// Updated during load and when view becomes visible to ensure banner state is correct.
    public private(set) var cachedCanCreateMoreHabits: Bool = true

    /// Check if user can create more habits based on current count
    public var canCreateMoreHabits: Bool {
        checkHabitCreationLimit.execute(currentCount: habitsData.totalHabitsCount)
    }

    /// Check if user is at or over the free limit
    public var isOverFreeLimit: Bool {
        // Show banner if:
        // 1. User has reached or exceeded the free limit (>= 5 habits)
        // 2. User is NOT in AllFeatures mode (build config check)
        // 3. User cannot create more habits (not premium) - uses CACHED value for reactivity
        #if ALL_FEATURES_ENABLED
        return false  // Never show in AllFeatures mode
        #else
        return habitsData.totalHabitsCount >= freeMaxHabits && !cachedCanCreateMoreHabits
        #endif
    }

    /// Free plan max habits constant
    public var freeMaxHabits: Int {
        BusinessConstants.freeMaxHabits
    }

    /// Refresh the cached premium status. Call when view appears or after potential status changes.
    public func refreshPremiumStatus() {
        cachedCanCreateMoreHabits = canCreateMoreHabits
    }
    
    /// Filtered habits based on selected category and active categories only
    public var filteredHabits: [Habit] {
        habitsData.filteredHabits(for: selectedFilterCategory)
    }
    
    /// Direct access to habits array (for backward compatibility)
    public var items: [Habit] {
        habitsData.habits
    }
    
    /// Direct access to categories array (for backward compatibility)
    public var categories: [HabitCategory] {
        habitsData.categories
    }

    /// Display categories with selected category moved to position 1 (after cogwheel)
    public var displayCategories: [HabitCategory] {
        guard let selected = selectedFilterCategory else {
            // No selection - return original order
            return originalCategoryOrder.isEmpty ? habitsData.categories : originalCategoryOrder
        }

        // Selected category exists - move it to first position
        var reordered = originalCategoryOrder.isEmpty ? habitsData.categories : originalCategoryOrder

        // Find and remove selected category
        if let selectedIndex = reordered.firstIndex(where: { $0.id == selected.id }) {
            let selectedCategory = reordered.remove(at: selectedIndex)
            // Insert at position 0 (will be position 1 after cogwheel in UI)
            reordered.insert(selectedCategory, at: 0)
        }

        return reordered
    }

    /// Loading state for categories (always false for unified loading)
    public var isLoadingCategories: Bool {
        isLoading
    }
    
    // MARK: - Initialization
    public init() {
        setupRefreshObservation()
    }
    
    public func load() async {
        // Skip redundant loads after initial data is loaded
        guard !hasLoadedInitialData else { return }
        await performLoad()
    }

    /// Force reload habits data (for pull-to-refresh, iCloud sync, sheet dismissals, etc.)
    public func refresh() async {
        hasLoadedInitialData = false
        await performLoad()
    }

    /// Invalidate cache when switching to this tab
    /// Ensures fresh data is loaded after changes made in other tabs
    public func invalidateCacheForTabSwitch() {
        if hasLoadedInitialData {
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
        // Refresh premium status when view becomes visible to catch any status changes
        if visible {
            refreshPremiumStatus()
        }
    }

    /// Internal load implementation
    private func performLoad() async {
        let startTime = Date()
        isLoading = true
        error = nil

        do {
            // Fetch display timezone from TimezoneService for all time-based calculations
            displayTimezone = (try? await timezoneService.getDisplayTimezone()) ?? .current

            habitsData = try await loadHabitsData.execute()

            // Always update original category order to include newly added categories
            originalCategoryOrder = habitsData.categories

            // Track performance metrics
            let loadTime = Date().timeIntervalSince(startTime)
            userActionTracker.trackPerformance(
                metric: "habits_load_time",
                value: loadTime * 1000, // Convert to milliseconds
                unit: "ms",
                additionalProperties: ["habits_count": habitsData.totalHabitsCount, "categories_count": habitsData.categoriesCount]
            )

            // Refresh premium status after loading data (ensures correct banner state)
            refreshPremiumStatus()

            hasLoadedInitialData = true
        } catch {
            self.error = error
            habitsData = HabitsData(habits: [], categories: [])
            userActionTracker.trackError(error, context: "habits_load")
        }

        isLoading = false
    }
    
    public func create(_ habit: Habit) async -> Bool {
        isCreating = true
        error = nil
        
        do {
            _ = try await createHabit.execute(habit)

            // Notify other tabs (Overview) to refresh immediately
            // Post before local refresh so observers start their own independent refresh
            NotificationCenter.default.post(name: .habitsDataDidChange, object: nil)

            await refresh() // Refresh the list
            isCreating = false

            // Track habit creation
            userActionTracker.track(.habitCreated(
                habitId: habit.id.uuidString,
                habitName: habit.name,
                habitType: habit.kind == .binary ? "binary" : "numeric"
            ))

            return true
        } catch {
            self.error = error
            isCreating = false
            userActionTracker.trackError(error, context: "habit_create", additionalProperties: ["habit_name": habit.name, "habit_type": habit.kind == .binary ? "binary" : "numeric"])
            return false
        }
    }
    
    public func update(_ habit: Habit) async -> Bool {
        isUpdating = true
        error = nil
        
        do {
            try await updateHabit.execute(habit)

            // Notify other tabs (Overview) to refresh immediately
            // Post before local refresh so observers start their own independent refresh
            NotificationCenter.default.post(name: .habitsDataDidChange, object: nil)

            await refresh() // Refresh the list
            isUpdating = false

            // Track habit update
            userActionTracker.track(.habitUpdated(
                habitId: habit.id.uuidString,
                habitName: habit.name
            ))

            return true
        } catch {
            self.error = error
            isUpdating = false
            userActionTracker.trackError(error, context: "habit_update", additionalProperties: ["habit_id": habit.id.uuidString, "habit_name": habit.name])
            return false
        }
    }
    
    public func delete(id: UUID) async -> Bool {
        isDeleting = true
        error = nil
        
        // Capture habit info before deletion for tracking
        let habitToDelete = habitsData.habits.first { $0.id == id }
        
        do {
            try await deleteHabit.execute(id: id)

            // Notify other tabs (Overview) to refresh immediately
            // Post before local refresh so observers start their own independent refresh
            NotificationCenter.default.post(name: .habitsDataDidChange, object: nil)

            await refresh() // Refresh the list
            isDeleting = false

            // Track habit deletion
            if let habit = habitToDelete {
                userActionTracker.track(.habitDeleted(
                    habitId: habit.id.uuidString,
                    habitName: habit.name
                ))
            }

            return true
        } catch {
            self.error = error
            isDeleting = false
            userActionTracker.trackError(error, context: "habit_delete", additionalProperties: ["habit_id": id.uuidString])
            return false
        }
    }
    
    public func toggleActiveStatus(id: UUID) async -> Bool {
        isUpdating = true
        error = nil
        
        // Capture habit info before toggle for tracking
        let habitToToggle = habitsData.habits.first { $0.id == id }
        
        do {
            _ = try await toggleHabitActiveStatus.execute(id: id)
            await refresh() // Refresh the list
            isUpdating = false
            
            // Track habit activation/deactivation
            if let habit = habitToToggle {
                if habit.isActive {
                    // Was active, now archived
                    userActionTracker.track(.habitArchived(
                        habitId: habit.id.uuidString,
                        habitName: habit.name
                    ))
                } else {
                    // Was inactive, now restored
                    userActionTracker.track(.habitRestored(
                        habitId: habit.id.uuidString,
                        habitName: habit.name
                    ))
                }
            }
            
            return true
        } catch {
            self.error = error
            isUpdating = false
            userActionTracker.trackError(error, context: "habit_toggle_status", additionalProperties: ["habit_id": id.uuidString])
            return false
        }
    }
    
    public func reorderHabits(_ newOrder: [Habit]) async -> Bool {
        isReordering = true
        error = nil

        do {
            try await reorderHabits.execute(newOrder)
            // Update local state immediately for smooth UI
            habitsData = HabitsData(habits: newOrder, categories: habitsData.categories)
            isReordering = false
            return true
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "habit_reorder", additionalProperties: ["habits_count": newOrder.count])
            await refresh() // Reload on error to restore correct order
            isReordering = false
            return false
        }
    }
    
    public func retry() async {
        await refresh()
    }
    
    private func setupRefreshObservation() {
        // No manual refresh triggers needed - @Observable reactivity handles updates
    }
    
    // MARK: - Presentation Logic
    
    /// Create habit detail ViewModel for editing/creating habits
    public func makeHabitDetailViewModel(for habit: Habit?) -> HabitDetailViewModel {
        HabitDetailViewModel(habit: habit)
    }

    /// Create habit from suggestion (for assistant)
    /// Note: Feature gating is handled by CreateHabitFromSuggestion UseCase
    /// and HabitsAssistantSheet's onShowPaywall callback
    public func createHabitFromSuggestion(_ suggestion: HabitSuggestion) async -> CreateHabitFromSuggestionResult {
        let result = await createHabitFromSuggestionUseCase.execute(suggestion)

        // Notify other tabs (Overview) to refresh immediately on success
        if case .success = result {
            NotificationCenter.default.post(name: .habitsDataDidChange, object: nil)
        }

        return result
    }
    
    /// Handle create habit button tap from toolbar
    public func handleCreateHabitTap() {
        if canCreateMoreHabits {
            showingCreateHabit = true
        } else {
            // Show paywall for users who hit the limit
            Task {
                await showPaywall()
            }
        }
    }
    
    /// Show paywall
    public func showPaywall() async {
        await paywallViewModel.load()
        paywallViewModel.trackPaywallShown(source: "habits", trigger: "habit_limit")
        paywallItem = PaywallItem(viewModel: paywallViewModel)
    }
    
    /// Handle when create habit sheet is dismissed - refresh data
    public func handleCreateHabitDismissal() {
        Task {
            await refresh()
        }
    }

    /// Handle when habit detail sheet is dismissed - refresh data
    public func handleHabitDetailDismissal() {
        Task {
            await refresh()
        }
    }
    
    /// Select a habit for editing
    public func selectHabit(_ habit: Habit) {
        selectedHabit = habit
    }
    
    // MARK: - Habit Completion Methods

    /// Check if a habit is completed today using IsHabitCompletedUseCase
    public func isHabitCompletedToday(_ habit: Habit) async -> Bool {
        do {
            // Use dedicated UseCase to get logs for a single habit today
            let today = CalendarUtils.startOfDayLocal(for: Date(), timezone: displayTimezone)
            let logs = try await getSingleHabitLogs.execute(for: habit.id, from: today, to: today)
            return isHabitCompleted.execute(habit: habit, on: today, logs: logs, timezone: displayTimezone)
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

    /// Get current progress for a habit today using CalculateDailyProgressUseCase
    public func getCurrentProgress(for habit: Habit) async -> Double {
        do {
            // Use dedicated UseCase to get logs for a single habit today
            let today = CalendarUtils.startOfDayLocal(for: Date(), timezone: displayTimezone)
            let logs = try await getSingleHabitLogs.execute(for: habit.id, from: today, to: today)
            return calculateDailyProgress.execute(habit: habit, logs: logs, for: today, timezone: displayTimezone)
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

    /// Check if a habit should be shown as actionable today using IsScheduledDayUseCase
    public func isHabitActionableToday(_ habit: Habit) -> Bool {
        let today = CalendarUtils.startOfDayLocal(for: Date(), timezone: displayTimezone)
        return isScheduledDay.execute(habit: habit, date: today, timezone: displayTimezone)
    }

    /// Get schedule validation message for a habit
    public func getScheduleValidationMessage(for habit: Habit) async -> String? {
        do {
            let today = CalendarUtils.startOfDayLocal(for: Date(), timezone: displayTimezone)
            _ = try await validateHabitScheduleUseCase.execute(habit: habit, date: today)
            return nil // No validation errors
        } catch {
            return error.localizedDescription
        }
    }

    /// Get the schedule status for a habit today
    public func getScheduleStatus(for habit: Habit) -> HabitScheduleStatus {
        let today = CalendarUtils.startOfDayLocal(for: Date(), timezone: displayTimezone)
        return HabitScheduleStatus.forHabit(habit, date: today, isScheduledDay: isScheduledDay, timezone: displayTimezone)
    }

    /// Check if a habit's logging should be disabled based on schedule validation
    public func shouldDisableLogging(for habit: Habit) async -> Bool {
        do {
            let today = CalendarUtils.startOfDayLocal(for: Date(), timezone: displayTimezone)
            let validationResult = try await validateHabitScheduleUseCase.execute(habit: habit, date: today)
            return !validationResult.isValid
        } catch {
            return true // Disable if validation fails
        }
    }

    /// Get validation result for a habit (used for real-time UI feedback)
    public func getValidationResult(for habit: Habit) async -> HabitScheduleValidationResult? {
        do {
            let today = CalendarUtils.startOfDayLocal(for: Date(), timezone: displayTimezone)
            return try await validateHabitScheduleUseCase.execute(habit: habit, date: today)
        } catch {
            return nil
        }
    }
    
    // MARK: - Assistant Navigation
    
    /// Handle habit assistant button tap
    public func handleAssistantTap(source: String = "toolbar") {
        userActionTracker.track(.habitsAssistantOpened(source: source == "emptyState" ? .emptyState : .habitsPage))
        showingHabitAssistant = true
    }
    
    /// Dismiss assistant and show paywall (called from assistant's upgrade button)
    /// Sets flag to show paywall after assistant dismissal completes
    public func dismissAssistantAndShowPaywall() {
        pendingPaywallAfterAssistantDismiss = true
        shouldReopenAssistantAfterPaywall = true
        showingHabitAssistant = false
    }
    
    /// Handle paywall dismissal
    public func handlePaywallDismissal() {
        // Guard against multiple calls
        guard !isHandlingPaywallDismissal else { return }
        
        // Track paywall dismissal
        paywallViewModel.trackPaywallDismissed()
        
        isHandlingPaywallDismissal = true
        
        if shouldReopenAssistantAfterPaywall {
            // Reset the flag
            shouldReopenAssistantAfterPaywall = false
            
            // Wait for paywall dismissal animation to complete before reopening assistant
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showingHabitAssistant = true
                self.isHandlingPaywallDismissal = false
            }
        } else {
            isHandlingPaywallDismissal = false
        }
    }
    
    /// Handle when assistant sheet is dismissed - refresh data and show pending paywall
    public func handleAssistantDismissal() {
        Task {
            await refresh()
        }

        // Check if we need to show paywall after assistant dismissal
        if pendingPaywallAfterAssistantDismiss {
            pendingPaywallAfterAssistantDismiss = false
            // Small delay to let the sheet dismissal animation complete
            Task {
                try? await Task.sleep(for: .milliseconds(350))
                await showPaywall()
            }
        }
    }
    
    /// Handle category filter selection
    public func selectFilterCategory(_ category: HabitCategory?) {
        selectedFilterCategory = category
    }
}
