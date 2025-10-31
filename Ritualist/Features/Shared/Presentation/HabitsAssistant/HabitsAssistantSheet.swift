import SwiftUI
import RitualistCore
import FactoryKit

/// A reusable HabitsAssistantSheet component with integrated dependencies (Clean Architecture)
/// This component can be used by any view that wants to present the Habits Assistant
public struct HabitsAssistantSheet: View {
    @Injected(\.habitsAssistantViewModel) private var habitsAssistantViewModel
    @Injected(\.createHabitFromSuggestionUseCase) private var createHabitFromSuggestionUseCase
    @Injected(\.removeHabitFromSuggestionUseCase) private var removeHabitFromSuggestionUseCase
    @Environment(\.dismiss) private var dismiss
    
    @State private var originalState: [String: Bool] = [:]
    @State private var userIntentions: [String: Bool] = [:]
    @State private var isProcessingActions = false
    
    private let existingHabits: [Habit]
    private let onShowPaywall: (() -> Void)?
    
    /// Initialize the reusable Habits Assistant sheet
    /// - Parameters:
    ///   - existingHabits: Current habits to show context in assistant
    ///   - onShowPaywall: Callback to show paywall when needed
    public init(
        existingHabits: [Habit] = [],
        onShowPaywall: (() -> Void)? = nil
    ) {
        self.existingHabits = existingHabits
        self.onShowPaywall = onShowPaywall
    }
    
    public var body: some View {
        NavigationStack {
            HabitsAssistantView(
                vm: habitsAssistantViewModel,
                existingHabits: existingHabits,
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
        .deviceAwareSheetSizing(
            compactMultiplier: SizeMultiplier(min: 1.0, ideal: 1.0, max: 1.0),
            regularMultiplier: SizeMultiplier(min: 1.0, ideal: 1.0, max: 1.0),
            largeMultiplier: SizeMultiplier(min: 1.0, ideal: 1.0, max: 1.0)
        )
        .onAppear {
            // Initialize the ViewModel with existing habits to populate mappings
            print("DEBUG: Existing habits: \(existingHabits.map { "\($0.name) (suggestionId: \($0.suggestionId ?? "nil"))" })")
            habitsAssistantViewModel.initializeWithExistingHabits(existingHabits)
            initializeIntentionState()
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
        
        print("DEBUG: Original state: \(originalState)")
        print("DEBUG: User intentions: \(userIntentions)")
        print("DEBUG: Suggestion to habit mappings: \(habitsAssistantViewModel.suggestionToHabitMappings)")
        print("DEBUG: Calculated \(operations.count) operations:")
        for operation in operations {
            switch operation {
            case .add(let suggestion):
                print("  - ADD: \(suggestion.name)")
            case .remove(let suggestionId, let habitId):
                print("  - REMOVE: \(suggestionId) (habitId: \(habitId))")
            }
        }
        
        guard !operations.isEmpty else { 
            print("DEBUG: No operations to process")
            return 
        }
        
        isProcessingActions = true
        defer { isProcessingActions = false }
        
        for operation in operations {
            switch operation {
            case .add(let suggestion):
                let result = await createHabitFromSuggestionUseCase.execute(suggestion)
                switch result {
                case .success(let habitId):
                    habitsAssistantViewModel.markSuggestionAsAdded(suggestion.id, habitId: habitId)
                    habitsAssistantViewModel.trackHabitAdded(
                        habitId: suggestion.id,
                        habitName: suggestion.name,
                        category: suggestion.categoryId
                    )
                case .limitReached:
                    habitsAssistantViewModel.trackHabitAddFailed(
                        habitId: suggestion.id,
                        error: "Habit limit reached"
                    )
                    onShowPaywall?()
                case .error(let errorMessage):
                    habitsAssistantViewModel.trackHabitAddFailed(
                        habitId: suggestion.id,
                        error: errorMessage
                    )
                }
            case .remove(let suggestionId, let habitId):
                let success = await removeHabitFromSuggestionUseCase.execute(suggestionId: suggestionId, habitId: habitId)
                if success {
                    habitsAssistantViewModel.markSuggestionAsRemoved(suggestionId)
                }
            }
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
                            print("DEBUG: Found habit via fallback matching: \(habit.name)")
                            operations.append(.remove(suggestionId, habit.id))
                        } else {
                            print("DEBUG: Could not find habit to remove for suggestion: \(suggestionId)")
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
        return habitsAssistantViewModel.getAllSuggestions()
    }
    
    private func findHabitMatchingSuggestion(_ suggestion: HabitSuggestion) -> Habit? {
        // Find habit by matching key properties with the suggestion
        return existingHabits.first { habit in
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
    ///   - onDataRefreshNeeded: Callback triggered when data should be refreshed
    func habitsAssistantSheet(
        isPresented: Binding<Bool>,
        existingHabits: [Habit] = [],
        onDataRefreshNeeded: @escaping () async -> Void = {}
    ) -> some View {
        self.modifier(
            HabitsAssistantSheetModifier(
                isPresented: isPresented,
                existingHabits: existingHabits,
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

    let existingHabits: [Habit]
    let onDataRefreshNeeded: () async -> Void

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                HabitsAssistantSheet(
                    existingHabits: existingHabits,
                    onShowPaywall: {
                        shouldReopenAssistant = true
                        isPresented = false
                        Task {
                            await paywallViewModel.load()
                            paywallViewModel.trackPaywallShown(source: "habits_assistant", trigger: "feature_limit")
                            showingPaywall = true
                        }
                    }
                )
                .deviceAwareSheetSizing(
                    compactMultiplier: SizeMultiplier(min: 1.0, ideal: 1.0, max: 1.0),
                    regularMultiplier: SizeMultiplier(min: 1.0, ideal: 1.0, max: 1.0),
                    largeMultiplier: SizeMultiplier(min: 1.0, ideal: 1.0, max: 1.0)
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
                            // Wait for dismissal animation before reopening
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                isPresented = true
                            }
                        }
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