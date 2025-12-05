import Foundation
import FactoryKit
import RitualistCore

// MARK: - Onboarding Use Cases Container Extensions

extension Container {
    
    // MARK: - Onboarding Operations
    
    var getOnboardingState: Factory<GetOnboardingState> {
        self { GetOnboardingState(repo: self.onboardingRepository()) }
    }
    
    var saveOnboardingState: Factory<SaveOnboardingState> {
        self { SaveOnboardingState(repo: self.onboardingRepository()) }
    }
    
    var completeOnboarding: Factory<CompleteOnboarding> {
        self {
            CompleteOnboarding(
                repo: self.onboardingRepository(),
                profileRepo: self.profileRepository(),
                iCloudKeyValueService: self.iCloudKeyValueService()
            )
        }
    }
}