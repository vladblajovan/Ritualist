import Foundation
import SwiftUI

// MARK: - DI Container EnvironmentKey

public protocol AppContainer {
    var habitRepository: HabitRepository { get }
    var logRepository: LogRepository { get }
    var profileRepository: ProfileRepository { get }
    var tipRepository: TipRepository { get }
    var onboardingRepository: OnboardingRepository { get }
    var categoryRepository: CategoryRepository { get }
    var notificationService: NotificationService { get }
    var appearanceManager: AppearanceManager { get }
    var habitSuggestionsService: HabitSuggestionsService { get }
    var userActionTracker: UserActionTrackerService { get }
    var userService: UserService { get }
    var paywallService: PaywallService { get }
    var featureGatingService: FeatureGatingService { get }
    var slogansService: SlogansServiceProtocol { get }
    
    // Domain UseCases
    var createHabitFromSuggestionUseCase: CreateHabitFromSuggestionUseCase { get }
    
    // Shared ViewModels
    var habitsAssistantViewModel: HabitsAssistantViewModel { get }
    
    // Feature factories
    var onboardingFactory: OnboardingFactory { get }
    var habitDetailFactory: HabitDetailFactory { get }
    var paywallFactory: PaywallFactory { get }
    var habitsAssistantFactory: HabitsAssistantFactory { get }
}

private struct AppContainerKey: EnvironmentKey {
    // Create a minimal default container - real app should inject proper container
    @MainActor
    static let defaultValue: AppContainer = DefaultAppContainer.createMinimal()
}

public extension EnvironmentValues {
    var appContainer: AppContainer {
        get { self[AppContainerKey.self] }
        set { self[AppContainerKey.self] = newValue }
    }
}
