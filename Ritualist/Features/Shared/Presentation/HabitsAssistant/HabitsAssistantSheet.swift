import SwiftUI
import RitualistCore
import FactoryKit
import TipKit

/// A reusable HabitsAssistantSheet component with integrated dependencies (Clean Architecture)
/// This component can be used by any view that wants to present the Habits Assistant
public struct HabitsAssistantSheet: View {
    @State private var vm = Container.shared.habitsAssistantSheetViewModel()
    @Environment(\.dismiss) private var dismiss

    private let existingHabits: [Habit]
    private let onShowPaywall: (() -> Void)?
    private let isFirstVisit: Bool

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
        // Set existing habits and paywall callback immediately (before any render)
        // swiftlint:disable:next redundant_discardable_let
        let _ = {
            vm.setExistingHabits(existingHabits)
            vm.onShowPaywall = onShowPaywall
        }()

        NavigationStack {
            HabitsAssistantView(
                vm: vm,
                isFirstVisit: isFirstVisit,
                onAddHabit: { suggestion in
                    // Track suggestion viewed when user attempts to add
                    vm.trackHabitSuggestionViewed(
                        habitId: suggestion.id,
                        category: suggestion.categoryId
                    )
                    // Immediately create the habit
                    _ = await vm.addHabit(suggestion)
                },
                onRemoveHabit: { suggestionId in
                    // Immediately delete the habit
                    _ = await vm.removeHabit(suggestionId)
                },
                onShowPaywall: onShowPaywall ?? {}
            )
            .navigationTitle(Strings.HabitsAssistant.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // No need to process anything - all operations were immediate
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .task {
            await vm.initialize(existingHabits: existingHabits)
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
            .sheet(isPresented: $isPresented) { assistantSheet }
            .sheet(isPresented: $showingPaywall) { paywallSheet }
            .onChange(of: isPresented) { _, newValue in
                if newValue { pendingReopenTask?.cancel(); pendingReopenTask = nil }
            }
    }

    private var assistantSheet: some View {
        HabitsAssistantSheet(existingHabits: existingHabits, isFirstVisit: isFirstVisit, onShowPaywall: handleShowPaywall)
            .onDisappear { Task { await handleAssistantDismiss() } }
    }

    private var paywallSheet: some View {
        PaywallView(vm: paywallViewModel).onDisappear { handlePaywallDismiss() }
    }

    private func handleShowPaywall() {
        pendingReopenTask?.cancel(); pendingReopenTask = nil
        shouldReopenAssistant = true; isPresented = false
        pendingPaywallTask?.cancel()
        pendingPaywallTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await paywallViewModel.load()
            paywallViewModel.trackPaywallShown(source: "habits_assistant", trigger: "feature_limit")
            showingPaywall = true
        }
    }

    private func handleAssistantDismiss() async {
        await onDataRefreshNeeded()
        Container.shared.habitsAssistantSheetViewModel().reset()
        if isFirstVisit { await TapHabitTip.habitsAssistantClosed.donate() }
    }

    private func handlePaywallDismiss() {
        paywallViewModel.trackPaywallDismissed()
        if shouldReopenAssistant {
            shouldReopenAssistant = false
            pendingReopenTask?.cancel()
            pendingReopenTask = Task {
                try? await Task.sleep(for: .seconds(1.0))
                guard !Task.isCancelled else { return }
                isPresented = true
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
