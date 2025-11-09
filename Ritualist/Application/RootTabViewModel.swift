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
        personalityDeepLinkCoordinator: PersonalityDeepLinkCoordinator
    ) {
        self.getOnboardingState = getOnboardingState
        self.loadProfile = loadProfile
        self.appearanceManager = appearanceManager
        self.navigationService = navigationService
        self.personalityDeepLinkCoordinator = personalityDeepLinkCoordinator
    }
    
    // MARK: - Public Methods
    
    public func checkOnboardingStatus() async {
        do {
            let state = try await getOnboardingState.execute()
            showOnboarding = !state.isCompleted
            isCheckingOnboarding = false
        } catch {
            print("Failed to check onboarding status: \(error)")
            showOnboarding = true
            isCheckingOnboarding = false
        }
    }
    
    public func loadUserAppearancePreference() async {
        do {
            let profile = try await loadProfile.execute()
            appearanceManager.updateFromProfile(profile)
        } catch {
            print("Failed to load user appearance preference: \(error)")
            // Continue with default appearance (follow system)
        }
    }
}