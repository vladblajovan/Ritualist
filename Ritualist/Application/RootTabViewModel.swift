import SwiftUI
import Foundation
import FactoryKit
import RitualistCore
import CloudKit

@MainActor
@Observable
public final class RootTabViewModel {

    // MARK: - Dependencies
    let loadProfile: LoadProfileUseCase
    let iCloudKeyValueService: iCloudKeyValueService
    let userDefaults: UserDefaultsService
    let logger: DebugLogger
    @ObservationIgnored @Injected(\.toastService) var toastService

    // MARK: - Services (exposed for view binding)
    public let appearanceManager: AppearanceManager
    public var navigationService: NavigationService
    public let personalityDeepLinkCoordinator: PersonalityDeepLinkCoordinator

    // MARK: - State
    public var showOnboarding = false
    public var isCheckingOnboarding = true

    /// Flag indicating we need to show returning user welcome once data loads
    public var pendingReturningUserWelcome = false

    /// Task for returning user welcome retry loop (cancellable)
    @ObservationIgnored var returningUserWelcomeTask: Task<Void, Never>?

    /// Flag to show returning user welcome after data loads (deferred onboarding)
    public var showReturningUserWelcome = false

    /// Flag to prevent syncing toast from being shown more than once per session
    var hasShownSyncingToast = false

    /// Synced data summary for returning user welcome screen
    public var syncedDataSummary: SyncedDataSummary?

    public init(
        loadProfile: LoadProfileUseCase,
        iCloudKeyValueService: iCloudKeyValueService,
        userDefaults: UserDefaultsService,
        appearanceManager: AppearanceManager,
        navigationService: NavigationService,
        personalityDeepLinkCoordinator: PersonalityDeepLinkCoordinator,
        logger: DebugLogger
    ) {
        self.loadProfile = loadProfile
        self.iCloudKeyValueService = iCloudKeyValueService
        self.userDefaults = userDefaults
        self.appearanceManager = appearanceManager
        self.navigationService = navigationService
        self.personalityDeepLinkCoordinator = personalityDeepLinkCoordinator
        self.logger = logger
    }

    // MARK: - Public Methods

    public func checkOnboardingStatus() async {
        #if DEBUG
        // Handle UI testing launch arguments
        if handleTestingLaunchArguments() { return }
        #endif

        await performOnboardingCheck()
    }

    /// Called from RootTabView when iCloud data has finished loading
    /// Shows the returning user welcome with actual synced data
    public func showReturningUserWelcomeIfNeeded(habits: [Habit], profile: UserProfile?) {
        handleReturningUserWelcome(habits: habits, profile: profile)
    }

    /// Called when returning user welcome is dismissed
    public func dismissReturningUserWelcome() {
        showReturningUserWelcome = false
        syncedDataSummary = nil

        // Mark this device as having completed onboarding (so we don't show welcome again)
        iCloudKeyValueService.setOnboardingCompletedLocally()
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
