import Foundation

public struct OnboardingFactory {
    private let container: AppContainer
    public init(container: AppContainer) { self.container = container }
    
    @MainActor public func makeViewModel() -> OnboardingViewModel {
        let getOnboardingState = GetOnboardingState(repo: container.onboardingRepository)
        let saveOnboardingState = SaveOnboardingState(repo: container.onboardingRepository)
        let completeOnboarding = CompleteOnboarding(repo: container.onboardingRepository, 
                                                   profileRepo: container.profileRepository)
        
        return OnboardingViewModel(
            getOnboardingState: getOnboardingState,
            saveOnboardingState: saveOnboardingState,
            completeOnboarding: completeOnboarding,
            notificationService: container.notificationService
        )
    }
}