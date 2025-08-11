import SwiftUI
import Foundation
import FactoryKit

@MainActor
@Observable
public final class RootTabViewModel {
    
    // MARK: - Dependencies
    private let getOnboardingState: GetOnboardingState
    private let loadProfile: LoadProfile
    private let appearanceManager: AppearanceManager
    
    // MARK: - State
    public var showOnboarding = false
    public var isCheckingOnboarding = true
    
    public init(
        getOnboardingState: GetOnboardingState,
        loadProfile: LoadProfile,
        appearanceManager: AppearanceManager
    ) {
        self.getOnboardingState = getOnboardingState
        self.loadProfile = loadProfile
        self.appearanceManager = appearanceManager
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