import Foundation

public struct OnboardingFactory {
    private let container: AppContainer
    public init(container: AppContainer) { self.container = container }
    
    @MainActor public func makeViewModel() -> OnboardingViewModel {
        let getOnboardingState = GetOnboardingState(repo: container.onboardingRepository)
        let saveOnboardingState = SaveOnboardingState(repo: container.onboardingRepository)
        let completeOnboarding = CompleteOnboarding(repo: container.onboardingRepository, 
                                                   profileRepo: container.profileRepository)
        let requestNotificationPermission = RequestNotificationPermission(notificationService: container.notificationService)
        let checkNotificationStatus = CheckNotificationStatus(notificationService: container.notificationService)
        
        return OnboardingViewModel(
            getOnboardingState: getOnboardingState,
            saveOnboardingState: saveOnboardingState,
            completeOnboarding: completeOnboarding,
            requestNotificationPermission: requestNotificationPermission,
            checkNotificationStatus: checkNotificationStatus
        )
    }
    
    @MainActor public func makeFlowViewModel() -> OnboardingFlowViewModel {
        let checkPremiumStatus = CheckPremiumStatus(userService: container.userService)
        
        return OnboardingFlowViewModel(
            checkPremiumStatus: checkPremiumStatus
        )
    }
}