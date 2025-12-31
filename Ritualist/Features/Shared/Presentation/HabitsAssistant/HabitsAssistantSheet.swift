import SwiftUI
import RitualistCore
import FactoryKit

/// A reusable HabitsAssistantSheet component with integrated dependencies (Clean Architecture)
/// This component can be used by any view that wants to present the Habits Assistant
public struct HabitsAssistantSheet: View {
    @Injected(\.habitsAssistantViewModel) private var habitsAssistantViewModel
    @Injected(\.createHabitFromSuggestionUseCase) private var createHabitFromSuggestionUseCase
    @Injected(\.removeHabitFromSuggestionUseCase) private var removeHabitFromSuggestionUseCase
    @Injected(\.checkHabitCreationLimit) private var checkHabitCreationLimit
    @Injected(\.debugLogger) private var logger
    @Environment(\.dismiss) private var dismiss

    @State private var originalState: [String: Bool] = [:]
    @State private var userIntentions: [String: Bool] = [:]
    @State private var isProcessingActions = false
    @State private var canCreateMoreHabits = true

    private let existingHabits: [Habit]
    private let onShowPaywall: (() -> Void)?
    private let isFirstVisit: Bool

    /// Calculate projected habit count based on user intentions
    private var projectedHabitCount: Int {
        // Start with existing habits count
        var count = existingHabits.count

        // Add newly intended habits (not originally present)
        for (suggestionId, intended) in userIntentions {
            let wasOriginallyAdded = originalState[suggestionId] ?? false
            if intended && !wasOriginallyAdded {
                count += 1  // User wants to add this
            } else if !intended && wasOriginallyAdded {
                count -= 1  // User wants to remove this
            }
        }

        return count
    }

    /// Should show limit banner for free users
    private var shouldShowLimitBanner: Bool {
        #if ALL_FEATURES_ENABLED
        return false  // Never show in AllFeatures mode
        #else
        // Only show banner for free users who can't create more habits (at or over limit)
        return !canCreateMoreHabits
        #endif
    }

    /// Max habits allowed (from BusinessConstants)
    private var maxHabitsAllowed: Int {
        BusinessConstants.freeMaxHabits
    }
    
    /// Initialize the reusable Habits Assistant sheet
    /// - Parameters:
    ///   - existingHabits: Current habits to show context in assistant
    ///   - isFirstVisit: Whether this is first time opening assistant (e.g., post-onboarding)
    ///   - onShowPaywall: Callback to show paywall when needed
    public init(
        existingHabits: [Habit] = [],
        isFirstVisit: Bool = false,
        onShowPaywall: (() -> Void)? = nil
    ) {
        self.existingHabits = existingHabits
        self.isFirstVisit = isFirstVisit
        self.onShowPaywall = onShowPaywall
    }
    
    public var body: some View {
        NavigationStack {
            HabitsAssistantView(
                vm: habitsAssistantViewModel,
                existingHabits: existingHabits,
                shouldShowLimitBanner: shouldShowLimitBanner,
                maxHabitsAllowed: maxHabitsAllowed,
                getCurrentHabitCount: { [self] in
                    // Return the projected count based on user intentions
                    projectedHabitCount
                },
                isFirstVisit: isFirstVisit,
                onHabitCreate: { suggestion in
                    // Track user's intention to have this habit
                    toggleHabitIntention(suggestion.id, intended: true)
                    return .success(habitId: UUID()) // This is only for UI feedback
                },
                onHabitRemove: { habitId in
                    // Find suggestion ID and track intention to not have this habit
                    if let suggestionId = habitsAssistantViewModel.suggestionToHabitMappings.first(where: { $0.value == habitId })?.key {
                        toggleHabitIntention(suggestionId, intended: false)
                    }
                    return true // This is only for UI feedback
                },
                onShowPaywall: onShowPaywall ?? {}
            )
            .navigationTitle("Habits Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        Task {
                            await processIntentionChanges()
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(isProcessingActions)
                }
            }
        }
        .task {
            // Initialize and check habit creation limit
            logger.log(
                "🔍 Initializing Habits Assistant",
                level: .debug,
                category: .ui,
                metadata: ["existingHabits": existingHabits.map { "\($0.name) (suggestionId: \($0.suggestionId ?? "nil"))" }.joined(separator: ", ")]
            )
            habitsAssistantViewModel.initializeWithExistingHabits(existingHabits)
            initializeIntentionState()
            canCreateMoreHabits = await checkHabitCreationLimit.execute(currentCount: projectedHabitCount)
        }
        .onChange(of: userIntentions) {
            Task {
                canCreateMoreHabits = await checkHabitCreationLimit.execute(currentCount: projectedHabitCount)
            }
        }
    }
    
    private func initializeIntentionState() {
        // Capture the original state when sheet opens - we need ALL suggestions, not just filtered ones
        let allSuggestions = getAllSuggestions()
        
        for suggestion in allSuggestions {
            let isCurrentlyAdded = habitsAssistantViewModel.addedSuggestionIds.contains(suggestion.id)
            originalState[suggestion.id] = isCurrentlyAdded
            userIntentions[suggestion.id] = isCurrentlyAdded // Start with no changes
        }
    }
    
    private func toggleHabitIntention(_ suggestionId: String, intended: Bool) {
        userIntentions[suggestionId] = intended
    }
    
    private func processIntentionChanges() async {
        let operations = calculateRequiredOperations()
        logOperations(operations)

        guard !operations.isEmpty else {
            logger.log("🔍 No operations to process", level: .debug, category: .ui)
            return
        }

        isProcessingActions = true
        defer { isProcessingActions = false }

        for operation in operations {
            let shouldStop = await executeOperation(operation)
            if shouldStop {
                break
            }
        }
    }

    private func logOperations(_ operations: [RequiredOperation]) {
        let operationsDescription = operations.map { operation -> String in
            switch operation {
            case .add(let suggestion): return "ADD: \(suggestion.name)"
            case .remove(let suggestionId, let habitId): return "REMOVE: \(suggestionId) (habitId: \(habitId))"
            }
        }.joined(separator: ", ")

        logger.log(
            "🔍 Processing habit intentions",
            level: .debug,
            category: .ui,
            metadata: [
                "originalState": String(describing: originalState),
                "userIntentions": String(describing: userIntentions),
                "mappings": String(describing: habitsAssistantViewModel.suggestionToHabitMappings),
                "operationCount": operations.count,
                "operations": operationsDescription
            ]
        )
    }

    /// Returns true if processing should stop (e.g., limit reached)
    private func executeOperation(_ operation: RequiredOperation) async -> Bool {
        switch operation {
        case .add(let suggestion):
            return await executeAddOperation(suggestion)
        case .remove(let suggestionId, let habitId):
            let success = await removeHabitFromSuggestionUseCase.execute(suggestionId: suggestionId, habitId: habitId)
            if success {
                habitsAssistantViewModel.markSuggestionAsRemoved(suggestionId)
            }
            return false
        }
    }

    /// Returns true if limit was reached and processing should stop
    private func executeAddOperation(_ suggestion: HabitSuggestion) async -> Bool {
        let result = await createHabitFromSuggestionUseCase.execute(suggestion)
        switch result {
        case .success(let habitId):
            habitsAssistantViewModel.markSuggestionAsAdded(suggestion.id, habitId: habitId)
            habitsAssistantViewModel.trackHabitAdded(habitId: suggestion.id, habitName: suggestion.name, category: suggestion.categoryId)
            return false
        case .limitReached:
            habitsAssistantViewModel.trackHabitAddFailed(habitId: suggestion.id, error: "Habit limit reached")
            onShowPaywall?()
            return true
        case .error(let errorMessage):
            habitsAssistantViewModel.trackHabitAddFailed(habitId: suggestion.id, error: errorMessage)
            return false
        }
    }
    
    private func calculateRequiredOperations() -> [RequiredOperation] {
        var operations: [RequiredOperation] = []
        
        // Compare user intentions with original state to determine required operations
        for (suggestionId, intendedState) in userIntentions {
            let originalStateForSuggestion = originalState[suggestionId] ?? false
            
            // Only create operations when intention differs from original state
            if intendedState != originalStateForSuggestion {
                if intendedState {
                    // User wants habit, but it wasn't originally added → Add it
                    if let suggestion = getAllSuggestions().first(where: { $0.id == suggestionId }) {
                        operations.append(.add(suggestion))
                    }
                } else {
                    // User doesn't want habit, but it was originally added → Remove it
                    if let habitId = habitsAssistantViewModel.suggestionToHabitMappings[suggestionId] {
                        operations.append(.remove(suggestionId, habitId))
                    } else {
                        // Fallback: find habit by matching suggestion properties
                        if let suggestion = getAllSuggestions().first(where: { $0.id == suggestionId }),
                           let habit = findHabitMatchingSuggestion(suggestion) {
                            logger.log(
                                "🔍 Found habit via fallback matching",
                                level: .debug,
                                category: .ui,
                                metadata: ["habitName": habit.name, "suggestionId": suggestionId]
                            )
                            operations.append(.remove(suggestionId, habit.id))
                        } else {
                            logger.log(
                                "⚠️ Could not find habit to remove",
                                level: .warning,
                                category: .ui,
                                metadata: ["suggestionId": suggestionId]
                            )
                        }
                    }
                }
            }
            // If intendedState == originalState, no operation needed (prevents data loss)
        }
        
        return operations
    }
    
    private func getAllSuggestions() -> [HabitSuggestion] {
        // Get ALL suggestions, not just the currently filtered ones
        habitsAssistantViewModel.getAllSuggestions()
    }

    private func findHabitMatchingSuggestion(_ suggestion: HabitSuggestion) -> Habit? {
        // Find habit by matching key properties with the suggestion
        existingHabits.first { habit in
            habit.name == suggestion.name &&
            habit.emoji == suggestion.emoji &&
            habit.colorHex == suggestion.colorHex &&
            habit.kind == suggestion.kind
        }
    }
}

// MARK: - Supporting Types

private enum RequiredOperation: Equatable {
    case add(HabitSuggestion)
    case remove(String, UUID) // suggestionId, habitId
    
    static func == (lhs: RequiredOperation, rhs: RequiredOperation) -> Bool {
        switch (lhs, rhs) {
        case (.add(let lhsSuggestion), .add(let rhsSuggestion)):
            return lhsSuggestion.id == rhsSuggestion.id
        case (.remove(let lhsSuggestionId, let lhsHabitId), .remove(let rhsSuggestionId, let rhsHabitId)):
            return lhsSuggestionId == rhsSuggestionId && lhsHabitId == rhsHabitId
        default:
            return false
        }
    }
}

/// Extension providing convenient sheet presentation modifiers
public extension View {
    /// Present the Habits Assistant as a sheet with integrated presentation logic
    /// - Parameters:
    ///   - isPresented: Binding to control sheet presentation
    ///   - existingHabits: Current habits for context
    ///   - isFirstVisit: Whether this is first time opening assistant (e.g., post-onboarding)
    ///   - onDataRefreshNeeded: Callback triggered when data should be refreshed
    func habitsAssistantSheet(
        isPresented: Binding<Bool>,
        existingHabits: [Habit] = [],
        isFirstVisit: Bool = false,
        onDataRefreshNeeded: @escaping () async -> Void = {}
    ) -> some View {
        self.modifier(
            HabitsAssistantSheetModifier(
                isPresented: isPresented,
                existingHabits: existingHabits,
                isFirstVisit: isFirstVisit,
                onDataRefreshNeeded: onDataRefreshNeeded
            )
        )
    }
}

/// ViewModifier for presenting the Habits Assistant sheet
private struct HabitsAssistantSheetModifier: ViewModifier {
    @Injected(\.paywallViewModel) private var paywallViewModel
    @Binding var isPresented: Bool
    @State private var showingPaywall = false
    @State private var shouldReopenAssistant = false

    /// Cancellable task for pending paywall presentation (prevents race conditions)
    @State private var pendingPaywallTask: Task<Void, Never>?
    /// Cancellable task for pending assistant reopen (prevents race conditions)
    @State private var pendingReopenTask: Task<Void, Never>?

    let existingHabits: [Habit]
    let isFirstVisit: Bool
    let onDataRefreshNeeded: () async -> Void

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                HabitsAssistantSheet(
                    existingHabits: existingHabits,
                    isFirstVisit: isFirstVisit,
                    onShowPaywall: {
                        // Cancel any pending reopen task
                        pendingReopenTask?.cancel()
                        pendingReopenTask = nil

                        shouldReopenAssistant = true
                        isPresented = false

                        // Cancel any existing paywall task before creating new one
                        pendingPaywallTask?.cancel()

                        // Delay paywall presentation to allow sheet dismiss animation to complete
                        // Using cancellable Task to prevent race conditions
                        pendingPaywallTask = Task {
                            try? await Task.sleep(for: .milliseconds(500))
                            guard !Task.isCancelled else { return }
                            await paywallViewModel.load()
                            paywallViewModel.trackPaywallShown(source: "habits_assistant", trigger: "feature_limit")
                            showingPaywall = true
                        }
                    }
                )
                .onDisappear {
                    Task {
                        await onDataRefreshNeeded()
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(vm: paywallViewModel)
                    .onDisappear {
                        paywallViewModel.trackPaywallDismissed()
                        if shouldReopenAssistant {
                            shouldReopenAssistant = false

                            // Cancel any existing reopen task before creating new one
                            pendingReopenTask?.cancel()

                            // Wait for dismissal animation before reopening
                            // Using cancellable Task to prevent race conditions
                            pendingReopenTask = Task {
                                try? await Task.sleep(for: .seconds(1.0))
                                guard !Task.isCancelled else { return }
                                isPresented = true
                            }
                        }
                    }
            }
            .onChange(of: isPresented) { _, newValue in
                // If user manually opens assistant, cancel any pending reopen task
                if newValue {
                    pendingReopenTask?.cancel()
                    pendingReopenTask = nil
                }
            }
    }
}

/// Usage example:
/// ```swift
/// .habitsAssistantSheet(
///     isPresented: $showingHabitAssistant,
///     existingHabits: vm.items,
///     onDataRefreshNeeded: { await vm.load() }
/// )
/// ```
