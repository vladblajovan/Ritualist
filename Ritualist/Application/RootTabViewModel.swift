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
    private let premiumVerifier: () async -> Bool
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
        logger: DebugLogger,
        /// Testing seam: Inject a mock to verify premium status in tests
        premiumVerifier: @escaping () async -> Bool = { await StoreKitSubscriptionService.verifyPremiumAsync() }
    ) {
        self.loadProfile = loadProfile
        self.iCloudKeyValueService = iCloudKeyValueService
        self.appearanceManager = appearanceManager
        self.navigationService = navigationService
        self.personalityDeepLinkCoordinator = personalityDeepLinkCoordinator
        self.logger = logger
        self.premiumVerifier = premiumVerifier
    }

    // MARK: - Public Methods

    public func checkOnboardingStatus() async {
        // Handle UI testing launch arguments
        if handleTestingLaunchArguments() { return }

        // IMPORTANT: Capture categorySeedingCompleted flag BEFORE any async operations
        // This avoids race condition where seedCategories() runs in parallel and sets this flag
        let hasRunAppBeforeCapture = UserDefaults.standard.bool(forKey: UserDefaultsKeys.categorySeedingCompleted)

        // CRITICAL: Verify subscription status BEFORE checking onboarding
        // This automatically "restores" purchases for returning users on new devices.
        // Transaction.currentEntitlements is tied to the Apple ID, not the device.
        // Without this, returning users would see new user onboarding because
        // isCloudKitSyncActive would return false (cached premium status is false).
        //
        // SLOW VERIFICATION NOTE: StoreKit has a 5s internal timeout. If verification
        // is slow (>2s), the user may see a brief loading state. This is acceptable
        // because: (1) it only affects first launch on new devices, (2) showing new
        // user onboarding is a safe fallback, (3) on next launch, cached status is
        // used. No retry logic is needed - StoreKit handles network retries internally.
        let isPremiumVerified = await premiumVerifier()
        if isPremiumVerified {
            logger.log(
                "Premium subscription verified at startup - enabling sync for returning user check",
                level: .info,
                category: .subscription
            )
        } else {
            // Log for production monitoring - helps identify StoreKit verification issues
            logger.log(
                "Premium subscription not verified at startup - user treated as free tier",
                level: .debug,
                category: .subscription
            )
        }

        // Synchronize iCloud KV store with short timeout (0.3s)
        // This is enough for cached data; longer waits hurt new user experience
        //
        // TELEMETRY NOTE: If timeout frequency becomes a concern, consider:
        // 1. Adding analytics to track timeout rates in production
        // 2. Increasing timeout to 0.5s if >10% of users experience timeouts
        // 3. The timeout only affects returning user detection, not app functionality
        let syncCompleted = await iCloudKeyValueService.synchronizeAndWait(timeout: 0.3)
        if !syncCompleted {
            logger.log(
                "iCloud KV sync timed out - may affect returning user detection",
                level: .warning,
                category: .ui,
                metadata: ["syncCompleted": syncCompleted, "timeoutSeconds": 0.3]
            )
        }

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

        // Step 2: Check iCloud availability (returns nil on error, to trigger new user flow)
        guard let isICloudAvailable = await checkICloudAvailability() else {
            showOnboarding = true
            isCheckingOnboarding = false
            return
        }
        guard isICloudAvailable else {
            logger.log("No iCloud account available - showing onboarding for new user", level: .info, category: .ui)
            showOnboarding = true
            isCheckingOnboarding = false
            return
        }

        // iCloud flag tells us if user completed onboarding on ANY device
        let iCloudOnboardingCompleted = iCloudKeyValueService.hasCompletedOnboarding()

        // Check if CloudKit sync will be active - use the freshly verified premium status
        // to handle returning users on new devices correctly
        //
        // RACE CONDITION ANALYSIS: We intentionally use the cached `isPremiumVerified` value
        // here rather than calling premiumVerifier() again. Theoretical race conditions:
        // 1. User restores purchase in another app instance during this check
        // 2. CloudKit sync brings updated subscription status mid-check
        //
        // These are acceptable because:
        // - checkOnboardingStatus() only runs ONCE at app startup
        // - The check completes in milliseconds (StoreKit has 5s timeout, iCloud KV has 0.3s)
        // - Concurrent purchase restoration requires user action in Settings/App Store
        // - Worst case: user sees onboarding instead of welcome, which is still valid UX
        // - On next app launch, the correct flow will be shown
        let syncPreference = ICloudSyncPreferenceService.shared.isICloudSyncEnabled
        let willSyncBeActive = isPremiumVerified && syncPreference

        // Monitor for potential race condition: sync preference enabled but premium not verified
        // This could indicate StoreKit verification took longer than expected or failed
        if syncPreference && !isPremiumVerified {
            logger.log(
                "Sync preference enabled but premium not verified - possible timing issue",
                level: .warning,
                category: .subscription
            )
        }

        if iCloudOnboardingCompleted && willSyncBeActive {
            // Returning user with active sync - show welcome after data syncs
            logger.log("Returning user detected - iCloud flag set, sync active", level: .info, category: .ui)
            showOnboarding = false
            isCheckingOnboarding = false
            pendingReturningUserWelcome = true
            return
        } else if iCloudOnboardingCompleted {
            // Free user or sync disabled - iCloud KV flag synced but data won't, treat as new user
            logger.log("iCloud flag set but sync not active - treating as new user", level: .info, category: .ui)
            // Fall through to new user check below
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

        // Use captured value from start of function to avoid race with category seeding
        if hasExistingData || hasRunAppBeforeCapture {
            // MIGRATION: User has existing data OR has run app before, but flags were never set
            // This happens when upgrading from a version that didn't set these flags (e.g., 0.2.1 → 0.3.0)
            // Set both flags to mark onboarding as complete for this device and iCloud
            logger.log(
                "Migration: existing user detected but no onboarding flags - setting flags",
                level: .info,
                category: .ui,
                metadata: [
                    "hasExistingData": hasExistingData,
                    "hasRunAppBefore": hasRunAppBeforeCapture,
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

        // Build summary from actual loaded data
        let summary = SyncedDataSummary(
            habitsCount: habits.count,
            categoriesCount: 0, // Not needed for welcome screen
            hasProfile: profile != nil,
            profileName: profile?.name,
            profileAvatar: profile?.avatarImageData,
            profileGender: profile?.gender,
            profileAgeGroup: profile?.ageGroup
        )

        // Show welcome once profile and demographics are synced
        // We don't require habits - user may have skipped adding them during onboarding
        // The welcome screen shows a generic "data synced" message instead of habit count
        guard summary.hasProfile && !summary.needsProfileCompletion else {
            logger.log(
                "Pending returning user welcome but profile/demographics not synced yet",
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

    /// Check if iCloud account is available.
    /// Returns `nil` on error (caller should show new user flow), `true`/`false` for availability.
    private func checkICloudAvailability() async -> Bool? {
        // Skip real CloudKit check in unit tests (XCTest environment)
        if NSClassFromString("XCTestCase") != nil {
            return true
        }

        let container = CKContainer(identifier: iCloudConstants.containerIdentifier)
        do {
            let accountStatus = try await container.accountStatus()
            return accountStatus == .available
        } catch {
            logger.log(
                "Failed to check iCloud account status - defaulting to new user flow",
                level: .warning,
                category: .ui,
                metadata: ["error": error.localizedDescription]
            )
            return nil
        }
    }

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
    // MARK: - CloudKit Sync Helpers

    /// Check if CloudKit sync is currently active (premium + sync preference enabled)
    ///
    /// Used to gate features that only make sense when data is actually syncing:
    /// - Returning user welcome flow
    /// - "Syncing data from iCloud" toast
    /// - Auto-sync on app launch
    ///
    /// SECURITY: Uses PersistenceContainer.premiumCheckProvider which is set up at app startup
    /// to use StoreKit-based checking (production) or mock checking (development builds).
    /// This ensures we never bypass the paywall by modifying UserDefaults.
    private var isCloudKitSyncActive: Bool {
        let isPremium = PersistenceContainer.premiumCheckProvider?() ?? false
        let syncPreference = ICloudSyncPreferenceService.shared.isICloudSyncEnabled
        return isPremium && syncPreference
    }

    // MARK: - Toast Management

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
    ///
    /// Note: Only shows if CloudKit sync is actually active (premium user with sync enabled).
    /// Free users have local-only storage, so showing "Syncing from iCloud" would be misleading.
    public func showSyncingDataToast() {
        guard !hasShownSyncingToast else { return }
        guard isCloudKitSyncActive else {
            logger.log("Skipping sync toast - CloudKit sync not active", level: .debug, category: .ui)
            return
        }

        hasShownSyncingToast = true
        toastService.infoPersistent(Strings.ICloudSync.syncingData, icon: "icloud.and.arrow.down")
    }

    /// Dismiss the syncing data toast (call when sync completes or returning user welcome shows)
    public func dismissSyncingDataToast() {
        toastService.dismiss(message: Strings.ICloudSync.syncingData)
    }
}
