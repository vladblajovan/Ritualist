import SwiftUI

// MARK: - DI Container EnvironmentKey

public protocol AppContainer {
    var habitRepository: HabitRepository { get }
    var logRepository: LogRepository { get }
    var profileRepository: ProfileRepository { get }
    var tipRepository: TipRepository { get }
    var onboardingRepository: OnboardingRepository { get }
    var userAuthRepository: UserAuthRepository { get }
    var notificationService: NotificationService { get }
    var dateProvider: DateProvider { get }
    var streakEngine: StreakEngine { get }
    var appearanceManager: AppearanceManager { get }
    var habitSuggestionsService: HabitSuggestionsService { get }
    var userActionTracker: UserActionTracker { get }
    var authenticationService: any AuthenticationService { get }
    var userSession: any UserSessionProtocol { get }
    var paywallService: PaywallService { get }
    var featureGatingService: FeatureGatingService { get }
    var stateCoordinator: any StateCoordinatorProtocol { get }
    var secureUserDefaults: SecureUserDefaults { get }
    var stateValidationService: any StateValidationServiceProtocol { get }
    var errorRecoveryService: any ErrorRecoveryServiceProtocol { get }
    var systemHealthMonitor: any SystemHealthMonitorProtocol { get }
    var errorHandlingStrategy: any ErrorHandlingStrategyProtocol { get }
    var refreshTrigger: RefreshTrigger { get }
    
    // Factory methods
    var onboardingFactory: OnboardingFactory { get }
}

private struct AppContainerKey: EnvironmentKey {
    // Create a minimal default container - real app should inject proper container
    static let defaultValue: AppContainer = DefaultAppContainer.createMinimal()
}

public extension EnvironmentValues {
    var appContainer: AppContainer {
        get { self[AppContainerKey.self] }
        set { self[AppContainerKey.self] = newValue }
    }
}
