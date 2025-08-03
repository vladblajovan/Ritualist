import Foundation
import Observation

@MainActor @Observable
public final class HabitsViewModel {
    private let getAllHabits: GetAllHabitsUseCase
    private let createHabit: CreateHabitUseCase
    private let updateHabit: UpdateHabitUseCase
    private let deleteHabit: DeleteHabitUseCase
    private let toggleHabitActiveStatus: ToggleHabitActiveStatusUseCase
    private let reorderHabits: ReorderHabitsUseCase
    private let checkHabitCreationLimit: CheckHabitCreationLimitUseCase
    private let createHabitFromSuggestionUseCase: CreateHabitFromSuggestionUseCase
    private let getActiveCategories: GetActiveCategoriesUseCase
    private let habitDetailFactory: HabitDetailFactory
    private let paywallFactory: PaywallFactory
    public let habitSuggestionsService: HabitSuggestionsService
    public let userActionTracker: UserActionTrackerService
    
    // MARK: - Data State
    public private(set) var items: [Habit] = []
    public private(set) var isLoading = false
    public private(set) var error: Error?
    public private(set) var isCreating = false
    public private(set) var isUpdating = false
    public private(set) var isDeleting = false
    
    // MARK: - Category Filtering State
    public private(set) var categories: [Category] = []
    public private(set) var isLoadingCategories = false
    public private(set) var categoriesError: Error?
    public var selectedFilterCategory: Category?
    
    // MARK: - Navigation State
    public var showingCreateHabit = false
    public var showingHabitAssistant = false
    public var showingCategoryManagement = false
    public var selectedHabit: Habit?
    public var paywallItem: PaywallItem?
    public var shouldReopenAssistantAfterPaywall = false
    public var isHandlingPaywallDismissal = false
    public private(set) var habitsAssistantViewModel: HabitsAssistantViewModel?
    
    // MARK: - Paywall Protection
    
    /// Check if user can create more habits based on current count
    public var canCreateMoreHabits: Bool {
        checkHabitCreationLimit.execute(currentCount: items.count)
    }
    
    /// Filtered habits based on selected category and active categories only
    public var filteredHabits: [Habit] {
        let activeCategoryIds = Set(categories.map { $0.id })
        
        // First filter to only habits from active categories or habits with no category
        let habitsFromActiveCategories = items.filter { habit in
            // Include habits with no category or habits from active categories
            habit.categoryId == nil || activeCategoryIds.contains(habit.categoryId ?? "")
        }
        
        // Then apply category filter if one is selected
        guard let selectedFilterCategory = selectedFilterCategory else {
            return habitsFromActiveCategories
        }
        
        return habitsFromActiveCategories.filter { habit in
            habit.categoryId == selectedFilterCategory.id
        }
    }
    
    public init(getAllHabits: GetAllHabitsUseCase, 
                createHabit: CreateHabitUseCase,
                updateHabit: UpdateHabitUseCase,
                deleteHabit: DeleteHabitUseCase,
                toggleHabitActiveStatus: ToggleHabitActiveStatusUseCase,
                reorderHabits: ReorderHabitsUseCase,
                checkHabitCreationLimit: CheckHabitCreationLimitUseCase,
                createHabitFromSuggestionUseCase: CreateHabitFromSuggestionUseCase,
                getActiveCategories: GetActiveCategoriesUseCase,
                habitDetailFactory: HabitDetailFactory,
                paywallFactory: PaywallFactory,
                habitsAssistantViewModel: HabitsAssistantViewModel,
                habitSuggestionsService: HabitSuggestionsService,
                userActionTracker: UserActionTrackerService) {
        self.getAllHabits = getAllHabits
        self.createHabit = createHabit
        self.updateHabit = updateHabit
        self.deleteHabit = deleteHabit
        self.toggleHabitActiveStatus = toggleHabitActiveStatus
        self.reorderHabits = reorderHabits
        self.checkHabitCreationLimit = checkHabitCreationLimit
        self.createHabitFromSuggestionUseCase = createHabitFromSuggestionUseCase
        self.getActiveCategories = getActiveCategories
        self.habitDetailFactory = habitDetailFactory
        self.paywallFactory = paywallFactory
        self.habitsAssistantViewModel = habitsAssistantViewModel
        self.habitSuggestionsService = habitSuggestionsService
        self.userActionTracker = userActionTracker
        
        setupRefreshObservation()
    }
    
    public func load() async {
        isLoading = true
        error = nil
        
        async let habitsResult = getAllHabits.execute()
        async let categoriesResult: () = loadCategories()
        
        do { 
            items = try await habitsResult
            await categoriesResult
        } catch { 
            self.error = error
            items = [] 
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
            return true
        } catch {
            self.error = error
            isCreating = false
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
            return true
        } catch {
            self.error = error
            isUpdating = false
            return false
        }
    }
    
    public func delete(id: UUID) async -> Bool {
        isDeleting = true
        error = nil
        
        do {
            try await deleteHabit.execute(id: id)
            await load() // Refresh the list
            isDeleting = false
            return true
        } catch {
            self.error = error
            isDeleting = false
            return false
        }
    }
    
    public func toggleActiveStatus(id: UUID) async -> Bool {
        isUpdating = true
        error = nil
        
        do {
            _ = try await toggleHabitActiveStatus.execute(id: id)
            await load() // Refresh the list
            isUpdating = false
            return true
        } catch {
            self.error = error
            isUpdating = false
            return false
        }
    }
    
    public func reorderHabits(_ newOrder: [Habit]) async -> Bool {
        isUpdating = true
        error = nil
        
        do {
            try await reorderHabits.execute(newOrder)
            items = newOrder // Update local state immediately for smooth UI
            isUpdating = false
            return true
        } catch {
            self.error = error
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
        return habitDetailFactory.makeViewModel(for: habit)
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
    
    /// Handle habit assistant button tap
    public func handleAssistantTap(source: String) {
        userActionTracker.track(.habitsAssistantOpened(source: source == "emptyState" ? .emptyState : .habitsPage))
        showingHabitAssistant = true
    }
    
    /// Handle category management button tap
    public func handleCategoryManagementTap() {
        showingCategoryManagement = true
    }
    
    /// Show paywall
    public func showPaywall() {
        Task { @MainActor in
            let paywallViewModel = paywallFactory.makeViewModel()
            await paywallViewModel.load()
            paywallItem = PaywallItem(viewModel: paywallViewModel)
        }
    }
    
    /// Show paywall from assistant (sets flag to reopen assistant after)
    public func showPaywallFromAssistant() {
        shouldReopenAssistantAfterPaywall = true
        showPaywall()
    }
    
    /// Handle paywall dismissal
    public func handlePaywallDismissal() {
        // Guard against multiple calls
        guard !isHandlingPaywallDismissal else { return }
        
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
    
    /// Handle when create habit sheet is dismissed - refresh data
    public func handleCreateHabitDismissal() {
        Task {
            await load()
        }
    }
    
    /// Handle when assistant sheet is dismissed - refresh data  
    public func handleAssistantDismissal() {
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
    
    /// Handle when category management sheet is dismissed - refresh data
    public func handleCategoryManagementDismissal() {
        Task {
            await load()
        }
    }
    
    /// Select a habit for editing
    public func selectHabit(_ habit: Habit) {
        selectedHabit = habit
    }
    
    // MARK: - Category Management
    
    /// Load categories for filtering
    private func loadCategories() async {
        isLoadingCategories = true
        categoriesError = nil
        
        do {
            categories = try await getActiveCategories.execute()
        } catch {
            categoriesError = error
            categories = []
        }
        
        isLoadingCategories = false
    }
    
    /// Handle category filter selection
    public func selectFilterCategory(_ category: Category?) {
        selectedFilterCategory = category
    }
}
