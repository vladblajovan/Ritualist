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
    @ObservationIgnored @Injected(\.toastService) private var toastService

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

    /// Flag to prevent syncing toast from being shown more than once per session
    private var hasShownSyncingToast = false

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
            // The syncing toast will be shown by RootTabView once the launch screen is dismissed
            pendingReturningUserWelcome = true
            return
        }

        // Step 3: Neither flag set - could be new user OR upgrade from old version
        // Before showing onboarding, check if user has existing data OR has run the app before
        let existingProfile: UserProfile?
        do {
            existingProfile = try await loadProfile.execute()
        } catch {
            // Log but don't block - treat as no existing data for migration purposes
            // This could indicate database issues that warrant investigation
            logger.log(
                "Failed to load profile during upgrade migration check - treating as no data",
                level: .warning,
                category: .ui,
                metadata: ["error": error.localizedDescription]
            )
            existingProfile = nil
        }
        let hasExistingData = !(existingProfile?.name.isEmpty ?? true)

        // Also check categorySeedingCompleted flag - this persists in UserDefaults across updates
        // If true, user has definitely run the app before (even if SwiftData is empty due to migration)
        let hasRunAppBefore = UserDefaults.standard.bool(forKey: UserDefaultsKeys.categorySeedingCompleted)

        if hasExistingData || hasRunAppBefore {
            // MIGRATION: User has existing data OR has run app before, but flags were never set
            // This happens when upgrading from a version that didn't set these flags (e.g., 0.2.1 → 0.3.0)
            // Set both flags to mark onboarding as complete for this device and iCloud
            logger.log(
                "Migration: existing user detected but no onboarding flags - setting flags",
                level: .info,
                category: .ui,
                metadata: [
                    "hasExistingData": hasExistingData,
                    "hasRunAppBefore": hasRunAppBefore,
                    "profileName": existingProfile?.name ?? "none"
                ]
            )

            iCloudKeyValueService.setOnboardingCompletedLocally()
            iCloudKeyValueService.setOnboardingCompleted()

            showOnboarding = false
            isCheckingOnboarding = false
            return
        }

        // No existing data - this is truly a new user
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

        // DEBUG: Log raw profile values from iCloud
        logger.log(
            "🔍 [DEBUG] showReturningUserWelcomeIfNeeded - raw profile from iCloud",
            level: .info,
            category: .ui,
            metadata: [
                "profile_exists": profile != nil,
                "profile.name": profile?.name ?? "nil",
                "profile.gender": profile?.gender ?? "nil",
                "profile.ageGroup": profile?.ageGroup ?? "nil",
                "habitsCount": habits.count
            ]
        )

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

        // Only show if we have COMPLETE data (habits AND full profile including gender/ageGroup)
        // This ensures we wait for all iCloud data to sync before showing welcome
        // Without this check, returning users may be re-asked for gender/ageGroup if CloudKit
        // syncs the profile name before syncing the demographic fields
        guard summary.habitsCount > 0 && summary.hasProfile && !summary.needsProfileCompletion else {
            logger.log(
                "Pending returning user welcome but incomplete data - waiting for more sync",
                level: .debug,
                category: .ui,
                metadata: [
                    "habitsCount": summary.habitsCount,
                    "hasProfile": summary.hasProfile,
                    "profileName": summary.profileName ?? "nil",
                    "hasGender": summary.profileGender != nil,
                    "hasAgeGroup": summary.profileAgeGroup != nil
                ]
            )
            return
        }

        // Note: Syncing toast is dismissed when ReturningUserOnboardingView appears
        // (via onAppear in RootTabView) to ensure seamless transition

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
                "profileName": summary.profileName ?? "nil",
                "hasGender": summary.profileGender != nil,
                "hasAgeGroup": summary.profileAgeGroup != nil
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
        #if DEBUG
        // Skip onboarding entirely during UI tests
        if LaunchArgument.uiTesting.isActive {
            showOnboarding = false
            isCheckingOnboarding = false
            logger.log("UI testing mode - skipping onboarding", level: .info, category: .ui)
            return true
        }

        // Force onboarding for onboarding UI tests
        if LaunchArgument.forceOnboarding.isActive {
            showOnboarding = true
            isCheckingOnboarding = false
            logger.log("Force onboarding mode - showing onboarding", level: .info, category: .ui)
            return true
        }

        // Force returning user flow for UI tests (with incomplete profile)
        if LaunchArgument.forceReturningUser.isActive {
            configureReturningUserTest(
                profileName: "Test User",
                profileGender: nil,
                profileAgeGroup: nil,
                logMessage: "Force returning user mode - incomplete profile"
            )
            return true
        }

        // Force returning user flow with complete profile (skips profile completion)
        if LaunchArgument.forceReturningUserComplete.isActive {
            configureReturningUserTest(
                profileName: "Test User",
                profileGender: "male",
                profileAgeGroup: "25_34",
                logMessage: "Force returning user mode - complete profile"
            )
            return true
        }

        // Force returning user flow with no name (shows name input)
        if LaunchArgument.forceReturningUserNoName.isActive {
            configureReturningUserTest(
                profileName: nil,
                profileGender: nil,
                profileAgeGroup: nil,
                logMessage: "Force returning user mode - no name"
            )
            return true
        }

        return false
        #else
        return false
        #endif
    }

    #if DEBUG
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
    #endif
}

// MARK: - Toast Display Model

extension RootTabViewModel {
    /// View-friendly toast representation that doesn't expose internal ToastService types
    public struct ToastDisplayItem: Identifiable {
        public let id: UUID
        public let message: String
        public let icon: String
        public let style: ToastStyle
        public let isPersistent: Bool
    }
}

// MARK: - Toast Helpers

extension RootTabViewModel {
    /// Check if any toast is currently being displayed
    public var isToastActive: Bool {
        toastService.hasActiveToasts
    }

    /// Active toasts for display (view-friendly representation)
    public var toastItems: [ToastDisplayItem] {
        toastService.toasts.map { toast in
            ToastDisplayItem(
                id: toast.id,
                message: toast.type.message,
                icon: toast.type.icon,
                style: toast.type.style,
                isPersistent: toast.persistent
            )
        }
    }

    /// Dismiss a specific toast by ID
    public func dismissToast(_ id: UUID) {
        toastService.dismiss(id)
    }

    /// Show toast for successful iCloud sync
    public func showSyncedToast() {
        toastService.info(Strings.ICloudSync.syncedFromCloud, icon: "icloud.fill")
    }

    /// Show toast when sync is still in progress
    public func showStillSyncingToast() {
        toastService.info(Strings.ICloudSync.stillSyncing, icon: "icloud.and.arrow.down")
    }

    /// Show persistent toast while syncing data from iCloud for returning users
    /// This toast stays visible until manually dismissed
    /// Only shows once per session to prevent duplicate appearances
    public func showSyncingDataToast() {
        guard !hasShownSyncingToast else { return }
        hasShownSyncingToast = true
        toastService.infoPersistent(Strings.ICloudSync.syncingData, icon: "icloud.and.arrow.down")
    }

    /// Dismiss the syncing data toast (call when sync completes or returning user welcome shows)
    public func dismissSyncingDataToast() {
        toastService.dismiss(message: Strings.ICloudSync.syncingData)
    }
}
