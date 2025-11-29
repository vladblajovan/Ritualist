import SwiftUI
import Foundation
import FactoryKit
import RitualistCore
import CloudKit

@MainActor
@Observable
public final class RootTabViewModel {

    // MARK: - Dependencies
    private let loadProfile: LoadProfile
    private let iCloudKeyValueService: iCloudKeyValueService
    private let logger: DebugLogger

    // MARK: - Services (exposed for view binding)
    public let appearanceManager: AppearanceManager
    public var navigationService: NavigationService
    public let personalityDeepLinkCoordinator: PersonalityDeepLinkCoordinator

    // MARK: - State
    public var showOnboarding = false
    public var isCheckingOnboarding = true

    /// Flag indicating we need to show returning user welcome once data loads
    public var pendingReturningUserWelcome = false

    /// Flag to show returning user welcome after data loads (deferred onboarding)
    public var showReturningUserWelcome = false

    /// Synced data summary for returning user welcome screen
    public var syncedDataSummary: SyncedDataSummary?

    public init(
        loadProfile: LoadProfile,
        iCloudKeyValueService: iCloudKeyValueService,
        appearanceManager: AppearanceManager,
        navigationService: NavigationService,
        personalityDeepLinkCoordinator: PersonalityDeepLinkCoordinator,
        logger: DebugLogger
    ) {
        self.loadProfile = loadProfile
        self.iCloudKeyValueService = iCloudKeyValueService
        self.appearanceManager = appearanceManager
        self.navigationService = navigationService
        self.personalityDeepLinkCoordinator = personalityDeepLinkCoordinator
        self.logger = logger
    }

    // MARK: - Public Methods

    public func checkOnboardingStatus() async {
        // Handle UI testing launch arguments
        if handleTestingLaunchArguments() { return }

        // First, synchronize iCloud key-value store to get latest flags
        iCloudKeyValueService.synchronize()

        // Step 1: Check LOCAL device flag (UserDefaults - not synced)
        // This tells us if THIS device has completed onboarding
        let localDeviceCompleted = iCloudKeyValueService.hasCompletedOnboardingLocally()

        if localDeviceCompleted {
            // This device already went through onboarding - skip everything
            showOnboarding = false
            isCheckingOnboarding = false
            logger.log(
                "Onboarding already completed on this device - skipping",
                level: .info,
                category: .ui
            )
            return
        }

        // Step 2: Local device flag is false - check iCloud flag
        // But ONLY if iCloud is actually available. Without an iCloud account,
        // NSUbiquitousKeyValueStore may contain stale data from previous sessions.
        // Skip real CloudKit check in unit tests (XCTest environment)
        let isICloudAvailable: Bool
        if NSClassFromString("XCTestCase") != nil {
            // In unit tests, assume iCloud is available (use mock service)
            isICloudAvailable = true
        } else {
            let container = CKContainer(identifier: iCloudConstants.containerIdentifier)
            let accountStatus: CKAccountStatus
            do {
                accountStatus = try await container.accountStatus()
            } catch {
                logger.log(
                    "Failed to check iCloud account status - defaulting to new user flow",
                    level: .warning,
                    category: .ui,
                    metadata: ["error": error.localizedDescription]
                )
                showOnboarding = true
                isCheckingOnboarding = false
                return
            }
            isICloudAvailable = accountStatus == .available
        }

        guard isICloudAvailable else {
            // No iCloud account - treat as new user, show onboarding
            logger.log(
                "No iCloud account available - showing onboarding for new user",
                level: .info,
                category: .ui
            )
            showOnboarding = true
            isCheckingOnboarding = false
            return
        }

        // iCloud flag tells us if user completed onboarding on ANY device
        let iCloudOnboardingCompleted = iCloudKeyValueService.hasCompletedOnboarding()

        if iCloudOnboardingCompleted {
            // Returning user! iCloud flag is set but local device flag is not
            // This means user completed onboarding on another device
            logger.log(
                "iCloud onboarding flag set, local device flag not set - returning user detected",
                level: .info,
                category: .ui
            )

            // Don't show onboarding, let the app load normally
            // We'll show the returning user welcome AFTER iCloud data fully syncs
            showOnboarding = false
            isCheckingOnboarding = false

            // Set flag - RootTabView will show welcome once data is loaded
            pendingReturningUserWelcome = true
            return
        }

        // Step 3: Neither flag set - this is a new user
        logger.log(
            "No iCloud onboarding flag and no local flag - new user flow",
            level: .info,
            category: .ui
        )
        showOnboarding = true
        isCheckingOnboarding = false
    }

    /// Called from RootTabView when iCloud data has finished loading
    /// Shows the returning user welcome with actual synced data
    public func showReturningUserWelcomeIfNeeded(habits: [Habit], profile: UserProfile?) {
        guard pendingReturningUserWelcome else { return }

        // Build summary from actual loaded data
        let summary = SyncedDataSummary(
            habitsCount: habits.count,
            categoriesCount: 0, // Not needed for welcome screen
            hasProfile: profile != nil && !(profile?.name.isEmpty ?? true),
            profileName: profile?.name,
            profileAvatar: profile?.avatarImageData,
            profileGender: profile?.gender,
            profileAgeGroup: profile?.ageGroup
        )

        // Only show if we have COMPLETE data (habits AND profile with name)
        // This ensures we wait for all iCloud data to sync before showing welcome
        guard summary.habitsCount > 0 && summary.hasProfile else {
            logger.log(
                "Pending returning user welcome but incomplete data - waiting for more sync",
                level: .debug,
                category: .ui,
                metadata: [
                    "habitsCount": summary.habitsCount,
                    "hasProfile": summary.hasProfile,
                    "profileName": summary.profileName ?? "nil"
                ]
            )
            return
        }

        pendingReturningUserWelcome = false
        syncedDataSummary = summary
        showReturningUserWelcome = true

        logger.log(
            "Showing returning user welcome with synced data",
            level: .info,
            category: .ui,
            metadata: [
                "habitsCount": summary.habitsCount,
                "hasProfile": summary.hasProfile,
                "profileName": summary.profileName ?? "nil"
            ]
        )
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

    // MARK: - Private Methods

    /// Handles UI testing launch arguments for onboarding flow control.
    /// Returns true if a testing argument was handled (caller should return early).
    private func handleTestingLaunchArguments() -> Bool {
        // Skip onboarding entirely during UI tests
        if CommandLine.arguments.contains("--uitesting") {
            showOnboarding = false
            isCheckingOnboarding = false
            logger.log("UI testing mode - skipping onboarding", level: .info, category: .ui)
            return true
        }

        // Force onboarding for onboarding UI tests
        if CommandLine.arguments.contains("--force-onboarding") {
            showOnboarding = true
            isCheckingOnboarding = false
            logger.log("Force onboarding mode - showing onboarding", level: .info, category: .ui)
            return true
        }

        // Force returning user flow for UI tests (with incomplete profile)
        if CommandLine.arguments.contains("--force-returning-user") {
            configureReturningUserTest(
                profileName: "Test User",
                profileGender: nil,
                profileAgeGroup: nil,
                logMessage: "Force returning user mode - incomplete profile"
            )
            return true
        }

        // Force returning user flow with complete profile (skips profile completion)
        if CommandLine.arguments.contains("--force-returning-user-complete") {
            configureReturningUserTest(
                profileName: "Test User",
                profileGender: "male",
                profileAgeGroup: "25_34",
                logMessage: "Force returning user mode - complete profile"
            )
            return true
        }

        // Force returning user flow with no name (shows name input)
        if CommandLine.arguments.contains("--force-returning-user-no-name") {
            configureReturningUserTest(
                profileName: nil,
                profileGender: nil,
                profileAgeGroup: nil,
                logMessage: "Force returning user mode - no name"
            )
            return true
        }

        return false
    }

    /// Configures state for returning user UI tests.
    private func configureReturningUserTest(
        profileName: String?,
        profileGender: String?,
        profileAgeGroup: String?,
        logMessage: String
    ) {
        showOnboarding = false
        isCheckingOnboarding = false
        syncedDataSummary = SyncedDataSummary(
            habitsCount: 5,
            categoriesCount: 2,
            hasProfile: true,
            profileName: profileName,
            profileAvatar: nil,
            profileGender: profileGender,
            profileAgeGroup: profileAgeGroup
        )
        showReturningUserWelcome = true
        logger.log(logMessage, level: .info, category: .ui)
    }
}
