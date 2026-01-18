import Foundation
import Observation
import FactoryKit
import RitualistCore

@MainActor @Observable
public final class HabitsViewModel {
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
    @ObservationIgnored @Injected(\.isHabitCompleted) var isHabitCompleted
    @ObservationIgnored @Injected(\.calculateDailyProgress) var calculateDailyProgress
    @ObservationIgnored @Injected(\.isScheduledDay) var isScheduledDay
    @ObservationIgnored @Injected(\.validateHabitSchedule) var validateHabitScheduleUseCase
    @ObservationIgnored @Injected(\.getSingleHabitLogs) var getSingleHabitLogs
    @ObservationIgnored @Injected(\.getBatchLogs) var getBatchLogs
    @ObservationIgnored @Injected(\.debugLogger) var logger
    @ObservationIgnored @Injected(\.timezoneService) var timezoneService
    @ObservationIgnored @Injected(\.checkPremiumStatus) private var checkPremiumStatus
    
    // MARK: - Shared ViewModels
    
    // MARK: - Data State (Unified)
    public var habitsData = HabitsData(habits: [], categories: [])
    public var isLoading = false
    public var error: Error?
    public var isCreating = false
    public var isUpdating = false
    public var isDeleting = false
    public var isReordering = false

    /// Track if initial data has been loaded to prevent duplicate loads during startup
    @ObservationIgnored private var hasLoadedInitialData = false

    /// Task for coalescing rapid notification posts (prevents notification spam)
    @ObservationIgnored private var notificationCoalesceTask: Task<Void, Never>?

    /// Task for pending assistant reopen after paywall dismissal (cancellable to prevent race conditions)
    @ObservationIgnored var pendingAssistantReopenTask: Task<Void, Never>?

    /// Task for pending paywall show after assistant dismissal (cancellable to prevent race conditions)
    @ObservationIgnored var pendingPaywallShowTask: Task<Void, Never>?

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

    /// Cached premium user status for UI components that need to show/hide premium features.
    /// Updated during load and when view becomes visible.
    public private(set) var isPremiumUser: Bool = false

    /// Today's completion percentage for the avatar progress ring.
    /// Calculated during load based on scheduled habits completed today.
    public private(set) var todayCompletionPercentage: Double?

    /// Check if user can create more habits based on current count
    public func canCreateMoreHabits() async -> Bool {
        await checkHabitCreationLimit.execute(currentCount: habitsData.totalHabitsCount)
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
    public func refreshPremiumStatus() async {
        cachedCanCreateMoreHabits = await canCreateMoreHabits()
        isPremiumUser = await checkPremiumStatus.execute()
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
            // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
            Task { @MainActor in
                await refreshPremiumStatus()
            }
        } else {
            // Cancel any pending background tasks when view disappears
            notificationCoalesceTask?.cancel()
            notificationCoalesceTask = nil
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

            // Calculate today's completion percentage for the avatar progress ring
            todayCompletionPercentage = await calculateTodayCompletionPercentage()

            // Track performance metrics
            let loadTime = Date().timeIntervalSince(startTime)
            userActionTracker.trackPerformance(
                metric: "habits_load_time",
                value: loadTime * 1000, // Convert to milliseconds
                unit: "ms",
                additionalProperties: ["habits_count": habitsData.totalHabitsCount, "categories_count": habitsData.categoriesCount]
            )

            // Refresh premium status after loading data (ensures correct banner state)
            await refreshPremiumStatus()

            hasLoadedInitialData = true
        } catch {
            self.error = error
            habitsData = HabitsData(habits: [], categories: [])
            userActionTracker.trackError(error, context: "habits_load")
        }

        isLoading = false
    }

    /// Posts habitsDataDidChange notification with coalescing to prevent spam.
    /// Multiple rapid calls within 100ms are coalesced into a single notification.
    func postCoalescedDataChangeNotification() {
        // Cancel any pending notification
        notificationCoalesceTask?.cancel()

        // Schedule new notification with short delay for coalescing
        // Note: Task { } does NOT inherit MainActor isolation, so we must explicitly specify it
        notificationCoalesceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            guard !Task.isCancelled else { return }
            NotificationCenter.default.post(name: .habitsDataDidChange, object: nil)
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

    /// Handle create habit button tap from toolbar
    public func handleCreateHabitTap() {
        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        Task { @MainActor in
            if await canCreateMoreHabits() {
                showingCreateHabit = true
            } else {
                // Show paywall for users who hit the limit
                await showPaywall()
            }
        }
    }
    
    /// Show paywall
    public func showPaywall() async {
        // Cancel any pending assistant reopen to prevent showing it after paywall closes
        // if the user directly triggered paywall (not via assistant flow)
        pendingAssistantReopenTask?.cancel()
        pendingAssistantReopenTask = nil

        await paywallViewModel.load()
        paywallViewModel.trackPaywallShown(source: "habits", trigger: "habit_limit")
        paywallItem = PaywallItem(viewModel: paywallViewModel)
    }
    
    /// Handle when create habit sheet is dismissed - refresh data
    public func handleCreateHabitDismissal() {
        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        Task { @MainActor in
            await refresh()
        }
    }

    /// Handle when habit detail sheet is dismissed - refresh data
    public func handleHabitDetailDismissal() {
        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        Task { @MainActor in
            await refresh()
        }
    }
    
    /// Select a habit for editing
    public func selectHabit(_ habit: Habit) {
        selectedHabit = habit
    }
}
