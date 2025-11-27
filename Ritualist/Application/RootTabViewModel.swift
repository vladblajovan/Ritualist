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
    private let detectiCloudData: DetectiCloudDataUseCase
    private let logger: DebugLogger

    // MARK: - Services (exposed for view binding)
    public let appearanceManager: AppearanceManager
    public var navigationService: NavigationService
    public let personalityDeepLinkCoordinator: PersonalityDeepLinkCoordinator

    // MARK: - State
    public var showOnboarding = false
    public var isCheckingOnboarding = true
    public var onboardingFlowType: OnboardingFlowType = .newUser

    public init(
        getOnboardingState: GetOnboardingState,
        loadProfile: LoadProfile,
        detectiCloudData: DetectiCloudDataUseCase,
        appearanceManager: AppearanceManager,
        navigationService: NavigationService,
        personalityDeepLinkCoordinator: PersonalityDeepLinkCoordinator,
        logger: DebugLogger
    ) {
        self.getOnboardingState = getOnboardingState
        self.loadProfile = loadProfile
        self.detectiCloudData = detectiCloudData
        self.appearanceManager = appearanceManager
        self.navigationService = navigationService
        self.personalityDeepLinkCoordinator = personalityDeepLinkCoordinator
        self.logger = logger
    }

    // MARK: - Public Methods

    public func checkOnboardingStatus() async {
        do {
            let state = try await getOnboardingState.execute()

            if state.isCompleted {
                // Onboarding already completed - go directly to main app
                showOnboarding = false
                isCheckingOnboarding = false
                logger.log(
                    "Onboarding already completed - skipping",
                    level: .info,
                    category: .ui
                )
            } else {
                // Onboarding not completed - detect iCloud data to determine flow
                logger.log(
                    "Onboarding not completed - detecting iCloud data",
                    level: .info,
                    category: .ui
                )
                onboardingFlowType = await detectiCloudData.execute(timeout: 3.5)
                showOnboarding = true
                isCheckingOnboarding = false

                logger.log(
                    "Onboarding flow determined",
                    level: .info,
                    category: .ui,
                    metadata: ["flowType": String(describing: onboardingFlowType)]
                )
            }
        } catch {
            logger.log("Failed to check onboarding status: \(error)", level: .error, category: .ui)
            // Default to new user flow on error
            onboardingFlowType = .newUser
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
