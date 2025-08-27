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
    @ObservationIgnored @Injected(\.isHabitCompleted) private var isHabitCompleted
    @ObservationIgnored @Injected(\.calculateDailyProgress) private var calculateDailyProgress
    @ObservationIgnored @Injected(\.isScheduledDay) private var isScheduledDay
    @ObservationIgnored @Injected(\.validateHabitSchedule) private var validateHabitScheduleUseCase
    @ObservationIgnored @Injected(\.getSingleHabitLogs) private var getSingleHabitLogs
    
    // MARK: - Shared ViewModels
    
    // MARK: - Data State (Unified)
    public private(set) var habitsData: HabitsData = HabitsData(habits: [], categories: [])
    public private(set) var isLoading = false
    public private(set) var error: Error?
    public private(set) var isCreating = false
    public private(set) var isUpdating = false
    public private(set) var isDeleting = false
    
    // MARK: - Category Filtering State
    public var selectedFilterCategory: HabitCategory?
    
    // MARK: - Navigation State
    public var showingCreateHabit = false
    public var selectedHabit: Habit?
    public var paywallItem: PaywallItem?
    
    // MARK: - Assistant Navigation State
    public var showingHabitAssistant = false
    public var shouldReopenAssistantAfterPaywall = false
    public var isHandlingPaywallDismissal = false
    
    
    // MARK: - Paywall Protection
    
    /// Check if user can create more habits based on current count
    public var canCreateMoreHabits: Bool {
        checkHabitCreationLimit.execute(currentCount: habitsData.totalHabitsCount)
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
    
    /// Loading state for categories (always false for unified loading)
    public var isLoadingCategories: Bool {
        isLoading
    }
    
    // MARK: - Initialization
    public init() {
        setupRefreshObservation()
    }
    
    public func load() async {
        let startTime = Date()
        isLoading = true
        error = nil
        
        do { 
            habitsData = try await loadHabitsData.execute()
            
            // Track performance metrics
            let loadTime = Date().timeIntervalSince(startTime)
            userActionTracker.trackPerformance(
                metric: "habits_load_time",
                value: loadTime * 1000, // Convert to milliseconds
                unit: "ms",
                additionalProperties: ["habits_count": habitsData.totalHabitsCount, "categories_count": habitsData.categoriesCount]
            )
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
            await load() // Refresh the list
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
            await load() // Refresh the list
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
            await load() // Refresh the list
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
            await load() // Refresh the list
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
        isUpdating = true
        error = nil
        
        do {
            try await reorderHabits.execute(newOrder)
            // Update local state immediately for smooth UI
            habitsData = HabitsData(habits: newOrder, categories: habitsData.categories)
            isUpdating = false
            return true
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "habit_reorder", additionalProperties: ["habits_count": newOrder.count])
            await load() // Reload on error to restore correct order
            isUpdating = false
            return false
        }
    }
    
    public func retry() async {
        await load()
    }
    
    private func setupRefreshObservation() {
        // No manual refresh triggers needed - @Observable reactivity handles updates
    }
    
    // MARK: - Presentation Logic
    
    /// Create habit detail ViewModel for editing/creating habits
    public func makeHabitDetailViewModel(for habit: Habit?) -> HabitDetailViewModel {
        return HabitDetailViewModel(habit: habit)
    }
    
    /// Create habit from suggestion (for assistant)
    public func createHabitFromSuggestion(_ suggestion: HabitSuggestion) async -> CreateHabitFromSuggestionResult {
        return await createHabitFromSuggestionUseCase.execute(suggestion)
    }
    
    /// Handle create habit button tap from toolbar
    public func handleCreateHabitTap() {
        if canCreateMoreHabits {
            showingCreateHabit = true
        } else {
            // Show paywall for users who hit the limit
            showPaywall()
        }
    }
    
    
    /// Show paywall
    public func showPaywall() {
        Task {
            await paywallViewModel.load()
            paywallViewModel.trackPaywallShown(source: "habits", trigger: "habit_limit")
            paywallItem = PaywallItem(viewModel: paywallViewModel)
        }
    }
    
    
    
    /// Handle when create habit sheet is dismissed - refresh data
    public func handleCreateHabitDismissal() {
        Task {
            await load()
        }
    }
    
    
    /// Handle when habit detail sheet is dismissed - refresh data
    public func handleHabitDetailDismissal() {
        Task {
            await load()
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
            let today = Date()
            let logs = try await getSingleHabitLogs.execute(for: habit.id, from: today, to: today)
            return isHabitCompleted.execute(habit: habit, on: today, logs: logs)
        } catch {
            return false
        }
    }
    
    /// Get current progress for a habit today using CalculateDailyProgressUseCase
    public func getCurrentProgress(for habit: Habit) async -> Double {
        do {
            // Use dedicated UseCase to get logs for a single habit today
            let today = Date()
            let logs = try await getSingleHabitLogs.execute(for: habit.id, from: today, to: today)
            return calculateDailyProgress.execute(habit: habit, logs: logs, for: today)
        } catch {
            return 0.0
        }
    }
    
    /// Check if a habit should be shown as actionable today using IsScheduledDayUseCase
    public func isHabitActionableToday(_ habit: Habit) -> Bool {
        return isScheduledDay.execute(habit: habit, date: Date())
    }
    
    /// Get schedule validation message for a habit
    public func getScheduleValidationMessage(for habit: Habit) async -> String? {
        do {
            _ = try await validateHabitScheduleUseCase.execute(habit: habit, date: Date())
            return nil // No validation errors
        } catch {
            return error.localizedDescription
        }
    }
    
    /// Get the schedule status for a habit today
    public func getScheduleStatus(for habit: Habit) -> HabitScheduleStatus {
        return HabitScheduleStatus.forHabit(habit, date: Date(), isScheduledDay: isScheduledDay)
    }
    
    /// Check if a habit's logging should be disabled based on schedule validation
    public func shouldDisableLogging(for habit: Habit) async -> Bool {
        do {
            let validationResult = try await validateHabitScheduleUseCase.execute(habit: habit, date: Date())
            return !validationResult.isValid
        } catch {
            return true // Disable if validation fails
        }
    }
    
    /// Get validation result for a habit (used for real-time UI feedback)
    public func getValidationResult(for habit: Habit) async -> HabitScheduleValidationResult? {
        do {
            return try await validateHabitScheduleUseCase.execute(habit: habit, date: Date())
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
    
    /// Show paywall from assistant (sets flag to reopen assistant after)
    public func showPaywallFromAssistant() {
        shouldReopenAssistantAfterPaywall = true
        Task {
            await paywallViewModel.load()
            paywallViewModel.trackPaywallShown(source: "habits_assistant", trigger: "feature_limit")
            paywallItem = PaywallItem(viewModel: paywallViewModel)
        }
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
    
    /// Handle when assistant sheet is dismissed - refresh data
    public func handleAssistantDismissal() {
        Task {
            await load()
        }
    }
    
    
    /// Handle category filter selection
    public func selectFilterCategory(_ category: HabitCategory?) {
        selectedFilterCategory = category
    }
    
}
