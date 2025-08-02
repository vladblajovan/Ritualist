import Foundation

@MainActor
@Observable
public final class OnboardingFlowViewModel {
    // Use cases
    private let checkPremiumStatus: CheckPremiumStatusUseCase
    
    // State
    public var isPremiumUser: Bool = false
    
    public init(checkPremiumStatus: CheckPremiumStatusUseCase) {
        self.checkPremiumStatus = checkPremiumStatus
    }
    
    public func checkUserPremiumStatus() async {
        isPremiumUser = await checkPremiumStatus.execute()
    }
    
    public func shouldShowPaywallAfterOnboarding() -> Bool {
        !isPremiumUser
    }
}