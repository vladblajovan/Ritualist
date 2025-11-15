import SwiftUI
import Foundation
import FactoryKit
import RitualistCore

@MainActor
@Observable
public final class RootTabViewModel {
    
    // MARK: - Dependencies
    private let getOnboardingState: GetOnboardingState
    private let loadProfile: LoadProfile
    private let logger: DebugLogger
    
    // MARK: - Services (exposed for view binding)
    public let appearanceManager: AppearanceManager
    public var navigationService: NavigationService
    public let personalityDeepLinkCoordinator: PersonalityDeepLinkCoordinator
    
    // MARK: - State
    public var showOnboarding = false
    public var isCheckingOnboarding = true
    
    public init(
        getOnboardingState: GetOnboardingState,
        loadProfile: LoadProfile,
        appearanceManager: AppearanceManager,
        navigationService: NavigationService,
        personalityDeepLinkCoordinator: PersonalityDeepLinkCoordinator,
        logger: DebugLogger
    ) {
        self.getOnboardingState = getOnboardingState
        self.loadProfile = loadProfile
        self.appearanceManager = appearanceManager
        self.navigationService = navigationService
        self.personalityDeepLinkCoordinator = personalityDeepLinkCoordinator
        self.logger = logger
    }
    
    // MARK: - Public Methods
    
    public func checkOnboardingStatus() async {
        do {
            let state = try await getOnboardingState.execute()
            showOnboarding = !state.isCompleted
            isCheckingOnboarding = false
        } catch {
            logger.log("Failed to check onboarding status: \(error)", level: .error, category: .ui)
            showOnboarding = true
            isCheckingOnboarding = false
        }
    }
    
    public func loadUserAppearancePreference() async {
        do {
            let profile = try await loadProfile.execute()
            appearanceManager.updateFromProfile(profile)
        } catch {
            logger.log("Failed to load user appearance preference: \(error)", level: .error, category: .ui)
        }
    }
}
