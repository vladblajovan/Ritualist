import Foundation
import Observation
import FactoryKit
import RitualistCore

@MainActor @Observable
public final class HabitsAssistantPresentationService {
    
    // MARK: - Factory Injected Dependencies
    @ObservationIgnored @Injected(\.createHabitFromSuggestionUseCase) var createHabitFromSuggestionUseCase
    @ObservationIgnored @Injected(\.userActionTracker) var userActionTracker
    @ObservationIgnored @Injected(\.paywallViewModel) var paywallViewModel
    @ObservationIgnored @Injected(\.habitsAssistantViewModel) var habitsAssistantViewModelInjected
    
    // MARK: - Navigation State
    public var showingHabitAssistant = false
    public var paywallItem: PaywallItem?
    public var shouldReopenAssistantAfterPaywall = false
    public var isHandlingPaywallDismissal = false
    
    // MARK: - ViewModel Access
    public var habitsAssistantViewModel: HabitsAssistantViewModel {
        habitsAssistantViewModelInjected
    }
    
    // MARK: - Callbacks
    /// Callback executed when data needs to be refreshed (e.g., after habit creation)
    public var onDataRefreshNeeded: (() async -> Void)?
    
    // MARK: - Public Interface
    
    /// Handle habit assistant button tap
    public func handleAssistantTap(source: String) {
        userActionTracker.track(.habitsAssistantOpened(source: source == "emptyState" ? .emptyState : .habitsPage))
        showingHabitAssistant = true
    }
    
    /// Create habit from suggestion (for assistant)
    public func createHabitFromSuggestion(_ suggestion: HabitSuggestion) async -> CreateHabitFromSuggestionResult {
        return await createHabitFromSuggestionUseCase.execute(suggestion)
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
            await onDataRefreshNeeded?()
        }
    }
    
    // MARK: - Initialization
    public init() {}
}