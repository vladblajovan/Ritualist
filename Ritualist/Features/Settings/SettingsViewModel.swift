import Foundation
import Observation
import FactoryKit
import RitualistCore
import StoreKit

// MARK: - Restore Purchases Result

/// Result of a restore purchases operation
public struct RestorePurchasesResult {
    public let success: Bool
    public let message: String
    public let count: Int
}

// MARK: - Settings View Model

@MainActor @Observable
public final class SettingsViewModel {
    private let loadProfile: LoadProfileUseCase
    private let saveProfile: SaveProfileUseCase
    private let permissionCoordinator: PermissionCoordinatorProtocol
    private let checkNotificationStatus: CheckNotificationStatusUseCase
    private let getLocationAuthStatus: GetLocationAuthStatusUseCase
    private let clearPurchases: ClearPurchasesUseCase
    private let checkPremiumStatus: CheckPremiumStatusUseCase
    private let getCurrentSubscriptionPlan: GetCurrentSubscriptionPlanUseCase
    private let getSubscriptionExpiryDate: GetSubscriptionExpiryDateUseCase
    private let getIsOnTrial: GetIsOnTrialUseCase
    private let syncWithiCloud: SyncWithiCloudUseCase
    private let checkiCloudStatus: CheckiCloudStatusUseCase
    private let getLastSyncDate: GetLastSyncDateUseCase
    private let deleteData: DeleteDataUseCase
    private let exportUserData: ExportUserDataUseCase
    private let importUserData: ImportUserDataUseCase
    @ObservationIgnored @Injected(\.userActionTracker) var userActionTracker
    @ObservationIgnored @Injected(\.appearanceManager) var appearanceManager
    @ObservationIgnored @Injected(\.paywallViewModel) var paywallViewModel
    @ObservationIgnored @Injected(\.subscriptionService) var subscriptionService
    @ObservationIgnored @Injected(\.paywallService) var paywallService
    @ObservationIgnored @Injected(\.debugLogger) var logger
    @ObservationIgnored @Injected(\.toastService) var toastService
    @ObservationIgnored @Injected(\.onboardingViewModel) var onboardingViewModel
    @ObservationIgnored @Injected(\.deduplicateData) var deduplicateData
    @ObservationIgnored @Injected(\.iCloudKeyValueService) var iCloudKeyValueService

    #if DEBUG
    private let populateTestData: PopulateTestDataUseCase?
    @ObservationIgnored @Injected(\.getDatabaseStats) var getDatabaseStats
    @ObservationIgnored @Injected(\.clearDatabase) var clearDatabase
    @ObservationIgnored @Injected(\.saveOnboardingState) var saveOnboardingState
    @ObservationIgnored @Injected(\.userDefaultsService) var userDefaults
    #endif

    public var profile = UserProfile()
    public private(set) var isLoading = false
    public private(set) var isSaving = false
    public private(set) var error: Error?
    public private(set) var hasNotificationPermission = false
    public private(set) var isRequestingNotifications = false
    public private(set) var locationAuthStatus: LocationAuthorizationStatus = .notDetermined
    public private(set) var isRequestingLocationPermission = false
    public private(set) var isCancellingSubscription = false
    public private(set) var isUpdatingUser = false

    // iCloud Sync state
    public private(set) var lastSyncDate: Date?
    public private(set) var iCloudStatus: iCloudSyncStatus = .unknown
    public private(set) var isCheckingCloudStatus = false
    public private(set) var isDeletingCloudData = false
    public private(set) var isExportingData = false

    // Account setup status (for informational display)
    public private(set) var canMakePayments: Bool = true
    public var exportedDataJSON: String?
    public var exportedFileURL: URL?
    public private(set) var isImportingData = false

    #if DEBUG
    public private(set) var isClearingDatabase = false
    public private(set) var databaseStats: DebugDatabaseStats?
    public private(set) var isPopulatingTestData = false
    public private(set) var testDataProgress: Double = 0.0
    public private(set) var testDataProgressMessage: String = ""

    // Performance monitoring
    public var showPerformanceStats = false
    #endif

    /// Track if initial data has been loaded to prevent duplicate loads during startup
    @ObservationIgnored private var hasLoadedInitialData = false

    // MARK: - View Visibility Tracking (for tab switch refresh)

    /// Track view visibility for tab switch detection
    public var isViewVisible: Bool = false

    /// Track if view has disappeared at least once (to distinguish initial appear from tab switch)
    @ObservationIgnored private var viewHasDisappearedOnce = false

    // Cache premium status to avoid async issues
    private var cachedPremiumStatus = false

    // Cache subscription data from service to avoid async issues in UI
    private var cachedSubscriptionPlan: SubscriptionPlan = .free
    private var cachedSubscriptionExpiryDate: Date?
    private var cachedIsOnTrial: Bool = false
    private var cachedHasBillingIssue: Bool = false

    // Paywall state
    public var paywallItem: PaywallItem?

    // Task tracking
    @ObservationIgnored var statusCheckTask: Task<Void, Never>?

    // Computed properties
    public var isPremiumUser: Bool {
        cachedPremiumStatus
    }

    /// Current subscription plan from service (not database)
    public var subscriptionPlan: SubscriptionPlan {
        cachedSubscriptionPlan
    }

    /// Subscription expiry date from service (not database)
    /// Returns nil for free users
    public var subscriptionExpiryDate: Date? {
        cachedSubscriptionExpiryDate
    }

    /// Whether the user is currently on a free trial period
    public var isOnTrial: Bool {
        cachedIsOnTrial
    }

    /// Whether the user has a billing issue (payment failed, in grace period)
    /// When true, user should be prompted to update their payment method
    public var hasBillingIssue: Bool {
        cachedHasBillingIssue
    }

    // MARK: - Account Setup Status

    /// Whether iCloud account is signed in
    public var isICloudSignedIn: Bool {
        iCloudStatus == .available
    }

    /// Whether there are any account setup issues that might affect purchases
    /// Note: iCloud status is shown in the iCloud Sync section, not here
    /// Note: Network connectivity is NOT shown here - subscription cache has a grace period
    public var hasAccountSetupIssues: Bool {
        !canMakePayments
    }

    /// List of current account setup issues for display in Subscription section
    /// Note: iCloud status is shown in the iCloud Sync section, not here
    /// Note: Network connectivity is NOT shown here - subscription cache has a grace period
    public var accountSetupIssues: [AccountSetupIssue] {
        var issues: [AccountSetupIssue] = []

        if !canMakePayments {
            issues.append(.purchasesRestricted)
        }

        return issues
    }

    public init(loadProfile: LoadProfileUseCase,
                saveProfile: SaveProfileUseCase,
                permissionCoordinator: PermissionCoordinatorProtocol,
                checkNotificationStatus: CheckNotificationStatusUseCase,
                getLocationAuthStatus: GetLocationAuthStatusUseCase,
                clearPurchases: ClearPurchasesUseCase,
                checkPremiumStatus: CheckPremiumStatusUseCase,
                getCurrentSubscriptionPlan: GetCurrentSubscriptionPlanUseCase,
                getSubscriptionExpiryDate: GetSubscriptionExpiryDateUseCase,
                getIsOnTrial: GetIsOnTrialUseCase,
                syncWithiCloud: SyncWithiCloudUseCase,
                checkiCloudStatus: CheckiCloudStatusUseCase,
                getLastSyncDate: GetLastSyncDateUseCase,
                deleteData: DeleteDataUseCase,
                exportUserData: ExportUserDataUseCase,
                importUserData: ImportUserDataUseCase,
                populateTestData: (any Any)? = nil) {
        self.loadProfile = loadProfile
        self.saveProfile = saveProfile
        self.permissionCoordinator = permissionCoordinator
        self.checkNotificationStatus = checkNotificationStatus
        self.getLocationAuthStatus = getLocationAuthStatus
        self.clearPurchases = clearPurchases
        self.checkPremiumStatus = checkPremiumStatus
        self.getCurrentSubscriptionPlan = getCurrentSubscriptionPlan
        self.getSubscriptionExpiryDate = getSubscriptionExpiryDate
        self.getIsOnTrial = getIsOnTrial
        self.syncWithiCloud = syncWithiCloud
        self.checkiCloudStatus = checkiCloudStatus
        self.getLastSyncDate = getLastSyncDate
        self.deleteData = deleteData
        self.exportUserData = exportUserData
        self.importUserData = importUserData
        #if DEBUG
        self.populateTestData = populateTestData as? PopulateTestDataUseCase
        #endif
    }

    deinit { statusCheckTask?.cancel() }

    public func load() async {
        // Skip redundant loads after initial data is loaded
        // Use reload() for explicit refresh (pull-to-refresh, iCloud sync, etc.)
        guard !hasLoadedInitialData else {
            logger.log(
                "Settings load skipped - data already loaded",
                level: .debug,
                category: .ui
            )
            return
        }

        await performLoad()
    }

    /// Force reload settings data (for pull-to-refresh, iCloud sync, etc.)
    public func reload() async {
        hasLoadedInitialData = false
        await performLoad()
    }

    // MARK: - View Visibility Methods

    /// Mark that view has disappeared (for tab switch detection)
    public func markViewDisappeared() {
        viewHasDisappearedOnce = true
    }

    /// Check if this is a tab switch (view returning after having left)
    /// Returns false on initial appear, true on subsequent appears after disappearing
    public var isReturningFromTabSwitch: Bool {
        viewHasDisappearedOnce
    }

    /// Set view visibility state
    public func setViewVisible(_ visible: Bool) {
        isViewVisible = visible
    }

    /// Internal load implementation
    private func performLoad() async {
        isLoading = true
        error = nil
        do {
            // Run deduplication before loading profile to ensure we get the correct one
            // This handles cases where CloudKit sync created duplicate profiles
            //
            // Note on race conditions: If CloudKit sync completes during this call,
            // new duplicates could arrive after dedup but before profile load.
            // This is acceptable because:
            // 1. The .onReceive(iCloudDidSyncRemoteChanges) will trigger reload()
            // 2. Deduplication runs again on next load, catching any new duplicates
            // 3. The window for this race is very small (milliseconds)
            let dedupResult = try await deduplicateData.execute()
            if dedupResult.profilesRemoved > 0 {
                logger.log(
                    "⚙️ Settings: Cleaned up duplicate profiles before load",
                    level: .info,
                    category: .dataIntegrity,
                    metadata: ["profiles_removed": dedupResult.profilesRemoved]
                )
            }

            profile = try await loadProfile.execute()

            // Note: Don't post .userProfileDidChange here - it causes infinite loop
            // when AppBrandHeader responds to notification by calling reload()
            // The notification is posted from CompleteOnboarding when profile actually changes

            await loadStatusesInParallel()
            hasLoadedInitialData = true
            logger.logSubscription(
                event: "Cached subscription from service",
                plan: cachedSubscriptionPlan.rawValue,
                metadata: [
                    "expiry": cachedSubscriptionExpiryDate?.description ?? "nil"
                ]
            )
        } catch {
            self.error = error
            profile = UserProfile()
            userActionTracker.trackError(error, context: "settings_load")
            await loadStatusesInParallel()
        }
        isLoading = false
    }

    /// Load all status checks in parallel for faster startup
    private func loadStatusesInParallel() async {
        // Set iCloud loading indicator immediately
        isCheckingCloudStatus = true

        async let notificationStatus = checkNotificationStatus.execute()
        async let locationStatus = getLocationAuthStatus.execute()
        async let premiumStatus = checkPremiumStatus.execute()
        async let syncDate = getLastSyncDate.execute()
        async let subscriptionPlan = getCurrentSubscriptionPlan.execute()
        async let subscriptionExpiry = getSubscriptionExpiryDate.execute()
        async let trialStatus = getIsOnTrial.execute()
        async let cloudStatus = checkiCloudStatus.execute()
        async let billingIssue = SecurePremiumCache.shared.shouldSuppressBillingDialog()

        // Await all results (runs in parallel)
        hasNotificationPermission = await notificationStatus
        locationAuthStatus = await locationStatus
        cachedPremiumStatus = await premiumStatus
        lastSyncDate = await syncDate
        cachedSubscriptionPlan = await subscriptionPlan
        cachedSubscriptionExpiryDate = await subscriptionExpiry
        cachedIsOnTrial = await trialStatus
        iCloudStatus = await cloudStatus
        cachedHasBillingIssue = await billingIssue

        // Check if device allows in-app purchases (parental controls, etc.)
        canMakePayments = AppStore.canMakePayments

        // Clear iCloud loading indicator
        isCheckingCloudStatus = false
    }

    public func save() async -> Bool {
        isSaving = true
        error = nil

        do {
            try await saveProfile.execute(profile)

            // Track profile update
            userActionTracker.track(.profileUpdated(field: "general_settings"))

            // Notify UI that profile changed (for AppBrandHeader avatar/initials)
            NotificationCenter.default.post(name: .userProfileDidChange, object: nil)

            // Send notification after successful save
            // try? await notificationService.sendImmediate(
            //     title: "Settings Saved",
            //     body: "Your preferences have been updated successfully."
            // )

            // Auto-sync with iCloud after profile changes (silent - don't show toast on failure)
            do {
                try await syncWithiCloud.execute()
            } catch {
                logger.log(
                    "Auto-sync after save failed (non-blocking)",
                    level: .warning,
                    category: .network,
                    metadata: ["error": error.localizedDescription]
                )
                // Don't show toast - iCloud sync is non-critical and will retry automatically
            }

            isSaving = false
            return true
        } catch {
            self.error = error
            isSaving = false
            userActionTracker.trackError(error, context: "settings_save")
            return false
        }
    }

    public func retry() async { await load() }
    public func refreshNotificationStatus() async { hasNotificationPermission = await checkNotificationStatus.execute() }
    public func refreshLocationStatus() async { locationAuthStatus = await getLocationAuthStatus.execute() }
    public func refreshPremiumStatus() async { cachedPremiumStatus = await checkPremiumStatus.execute() }
}

// MARK: - Permissions

extension SettingsViewModel {
    public func requestNotifications() async {
        isRequestingNotifications = true
        error = nil
        let result = await permissionCoordinator.requestNotificationPermission()
        hasNotificationPermission = result.granted
        if let permissionError = result.error {
            self.error = permissionError
            userActionTracker.trackError(permissionError, context: "notification_permission_request")
            hasNotificationPermission = await checkNotificationStatus.execute()
        } else {
            userActionTracker.track(.notificationSettingsChanged(enabled: result.granted))
        }
        isRequestingNotifications = false
    }

    public func requestLocationPermission() async {
        isRequestingLocationPermission = true
        error = nil
        userActionTracker.track(.locationPermissionRequested(context: "settings"))
        let result = await permissionCoordinator.requestLocationPermission(requestAlways: true)
        locationAuthStatus = result.status
        if let permissionError = result.error {
            self.error = permissionError
            userActionTracker.trackError(permissionError, context: "location_permission_request")
        } else if result.isAuthorized {
            userActionTracker.track(.locationPermissionGranted(status: String(describing: result.status), context: "settings"))
            userActionTracker.track(.profileUpdated(field: "location_permission"))
        } else {
            userActionTracker.track(.locationPermissionDenied(context: "settings"))
        }
        isRequestingLocationPermission = false
    }
}

// MARK: - Profile Updates

extension SettingsViewModel {
    public func updateUserName(_ name: String) async {
        isUpdatingUser = true
        error = nil
        profile.name = name
        profile.updatedAt = Date()
        do {
            try await saveProfile.execute(profile)
            userActionTracker.track(.profileUpdated(field: "name"))
            try? await syncWithiCloud.execute()
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "user_name_update", additionalProperties: ["name": name])
        }
        isUpdatingUser = false
    }

    public func cancelSubscription() async {
        isCancellingSubscription = true
        error = nil
        do { try await clearPurchases.execute() } catch {
            logger.log("Failed to clear purchases: \(error)", level: .error, category: .subscription)
        }
        isCancellingSubscription = false
    }

    public func updateAppearance(_ appearance: Int) async {
        profile.appearance = appearance
        profile.updatedAt = Date()
        appearanceManager.updateFromProfile(profile)
        do {
            try await saveProfile.execute(profile)
            userActionTracker.track(.profileUpdated(field: "appearance"))
            try? await syncWithiCloud.execute()
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "appearance_update", additionalProperties: ["appearance": String(appearance)])
        }
    }
}

// MARK: - iCloud Sync Methods

extension SettingsViewModel {
    /// Refresh iCloud account status
    public func refreshiCloudStatus() async {
        if statusCheckTask != nil { return }

        // Note: Task { } does NOT inherit MainActor isolation, so we must explicitly specify it
        // to safely update @Observable properties
        statusCheckTask = Task { @MainActor [weak self] in
            guard let self, !Task.isCancelled else { return }
            isCheckingCloudStatus = true
            iCloudStatus = await checkiCloudStatus.execute()
            guard !Task.isCancelled else { isCheckingCloudStatus = false; return }
            isCheckingCloudStatus = false
            statusCheckTask = nil
        }

        await statusCheckTask?.value
    }

    /// Force a fresh iCloud status check with logging
    public func forceCloudStatusCheck() async {
        logger.log("Force iCloud status check requested", level: .info, category: .system)
        await refreshiCloudStatus()
        logger.log("iCloud status check complete", level: .info, category: .system, metadata: ["status": iCloudStatus.displayMessage])
    }
}

// MARK: - Data Management

extension SettingsViewModel {
    /// Delete all data (GDPR compliance - Right to be forgotten)
    public func deleteAllData() async -> DeleteAllDataResult {
        isDeletingCloudData = true
        error = nil

        let isOnline = await NetworkUtilities.hasNetworkConnectivity()
        let shouldWarnAboutSync = iCloudStatus.canSync && !isOnline

        do {
            try await deleteData.execute()
            lastSyncDate = nil
            profile = UserProfile()
            userActionTracker.track(.custom(event: "all_data_deleted_by_user", parameters: [
                "icloud_configured": iCloudStatus.canSync, "offline_warning": shouldWarnAboutSync
            ]))
            onboardingViewModel.reset()
            isDeletingCloudData = false
            return shouldWarnAboutSync ? .successButCloudSyncMayBeDelayed : .success
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "delete_all_data")
            isDeletingCloudData = false
            return .failed(error)
        }
    }

    /// Export user data (GDPR compliance - Right to data portability)
    public func exportData() async {
        isExportingData = true
        error = nil
        do {
            exportedDataJSON = try await exportUserData.execute()
            userActionTracker.track(.custom(event: "user_data_exported", parameters: [:]))
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "export_user_data")
        }
        isExportingData = false
    }

    /// Import user data (GDPR compliance - Right to data portability)
    public func importData(jsonString: String) async {
        isImportingData = true
        error = nil
        do {
            let importResult = try await importUserData.execute(jsonString: jsonString)
            await load()
            try await permissionCoordinator.scheduleAllNotifications()
            await handleImportedLocationConfigurations(importResult: importResult)
            userActionTracker.track(.custom(event: "user_data_imported", parameters: [
                "habits_count": importResult.habitsImported,
                "logs_count": importResult.habitLogsImported,
                "has_location_configs": importResult.hasLocationConfigurations
            ]))
            iCloudKeyValueService.setOnboardingCompletedLocally()
            iCloudKeyValueService.setOnboardingCompleted()
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "import_user_data")
        }
        isImportingData = false
    }

    private func handleImportedLocationConfigurations(importResult: ImportResult) async {
        guard importResult.hasLocationConfigurations else { return }
        let currentAuthStatus = await getLocationAuthStatus.execute()
        if !currentAuthStatus.canMonitorGeofences {
            let permissionResult = await permissionCoordinator.requestLocationPermission(requestAlways: true)
            locationAuthStatus = permissionResult.status
            if permissionResult.isAuthorized {
                userActionTracker.track(.locationPermissionGranted(status: String(describing: permissionResult.status), context: "import_geofence"))
            } else {
                userActionTracker.track(.locationPermissionDenied(context: "import_geofence"))
            }
        } else {
            try? await permissionCoordinator.restoreAllGeofences()
        }
    }
}

// MARK: - Paywall

extension SettingsViewModel {
    /// Show paywall for subscription management
    public func showPaywall() async {
        await paywallViewModel.load()
        paywallViewModel.trackPaywallShown(source: "settings", trigger: "subscribe_button")
        paywallItem = PaywallItem(viewModel: paywallViewModel)
    }

    /// Refresh subscription status from service after purchase
    /// Call this after paywall dismissal to update Settings UI
    public func refreshSubscriptionStatus() async {
        logger.logSubscription(event: "Refreshing subscription status from service")
        cachedSubscriptionPlan = await subscriptionService.getCurrentSubscriptionPlan()
        cachedSubscriptionExpiryDate = await subscriptionService.getSubscriptionExpiryDate()
        cachedIsOnTrial = await subscriptionService.isOnTrial()
        cachedPremiumStatus = await checkPremiumStatus.execute()
        cachedHasBillingIssue = await SecurePremiumCache.shared.shouldSuppressBillingDialog()
        logger.logSubscription(
            event: "Updated subscription status",
            plan: cachedSubscriptionPlan.rawValue,
            metadata: [
                "expiry": cachedSubscriptionExpiryDate?.description ?? "nil",
                "is_premium": cachedPremiumStatus,
                "is_on_trial": cachedIsOnTrial,
                "has_billing_issue": cachedHasBillingIssue
            ]
        )
    }

    /// Restore purchases using the proper service (ensures cache registration)
    ///
    /// Uses `PaywallService.restorePurchases()` which:
    /// 1. Calls `AppStore.sync()` via StoreKit
    /// 2. Iterates over `Transaction.currentEntitlements`
    /// 3. Registers each purchase in the premium cache
    /// 4. Logs any failures for visibility
    ///
    /// - Returns: Result with success flag, message, and restored product count
    ///
    public func restorePurchases() async -> RestorePurchasesResult {
        do {
            // First sync with App Store
            try await AppStore.sync()

            // Then restore using service (registers in cache)
            let result = try await paywallService.restorePurchases()

            switch result {
            case .success(let productIds):
                // Refresh local state after restore
                await refreshSubscriptionStatus()

                // Notify app that premium status may have changed
                NotificationCenter.default.post(name: .premiumStatusDidChange, object: nil)

                logger.logSubscription(
                    event: "Restore purchases completed",
                    metadata: ["restored_count": productIds.count]
                )

                return RestorePurchasesResult(success: true, message: "Restored \(productIds.count) purchase(s)", count: productIds.count)

            case .noProductsToRestore:
                return RestorePurchasesResult(success: false, message: "No purchases to restore", count: 0)

            case .failed(let errorMessage):
                logger.log(
                    "Restore purchases failed",
                    level: .error,
                    category: .subscription,
                    metadata: ["error": errorMessage]
                )
                return RestorePurchasesResult(success: false, message: "Restore failed: \(errorMessage)", count: 0)
            }
        } catch {
            logger.log(
                "Failed to restore purchases",
                level: .error,
                category: .subscription,
                metadata: ["error": error.localizedDescription]
            )
            return RestorePurchasesResult(success: false, message: "Restore failed: \(error.localizedDescription)", count: 0)
        }
    }
}

// MARK: - Toast Helpers

extension SettingsViewModel {
    /// Check if any toast is currently being displayed
    public var isToastActive: Bool {
        toastService.hasActiveToasts
    }
}

// MARK: - Profile Updates with Toast

extension SettingsViewModel {
    /// Update gender and show toast on success
    /// Only saves and shows toast if value actually changed
    public func updateGender(_ gender: UserGender) async {
        guard profile.gender != gender.rawValue else { return }
        profile.gender = gender.rawValue
        let success = await save()
        if success {
            toastService.success(Strings.Profile.genderUpdated, icon: "person.fill.checkmark")
        }
    }

    /// Update age group and show toast on success
    /// Only saves and shows toast if value actually changed
    public func updateAgeGroup(_ ageGroup: UserAgeGroup) async {
        guard profile.ageGroup != ageGroup.rawValue else { return }
        profile.ageGroup = ageGroup.rawValue
        let success = await save()
        if success {
            toastService.success(Strings.Profile.ageGroupUpdated, icon: "number.circle.fill")
        }
    }

    /// Update avatar and show toast on success
    /// Only saves and shows toast if value actually changed
    public func updateAvatar(_ imageData: Data?) async {
        guard profile.avatarImageData != imageData else { return }
        let isRemoving = imageData == nil && profile.avatarImageData != nil
        profile.avatarImageData = imageData
        let success = await save()
        if success {
            if isRemoving {
                toastService.info(Strings.Avatar.photoRemoved, icon: "person.crop.circle.badge.minus")
            } else {
                toastService.success(Strings.Avatar.photoUpdated, icon: "person.crop.circle.fill.badge.checkmark")
            }
        }
    }

    /// Update name and show toast on success
    /// Only saves and shows toast if value actually changed
    public func updateName(_ name: String) async {
        guard profile.name != name else { return }
        await updateUserName(name)
        // updateUserName() handles profile update, save, tracking, and iCloud sync
        // Check error state to determine if save succeeded
        if error == nil {
            toastService.success(Strings.Profile.nameUpdated, icon: "person.fill.checkmark")
        }
    }

    /// Show toast for delete result
    public func showDeleteResultToast(_ result: DeleteAllDataResult) {
        switch result {
        case .success:
            toastService.success(Strings.DataManagement.deleteSuccessMessage)
        case .successButCloudSyncMayBeDelayed:
            toastService.warning(Strings.DataManagement.deleteSyncDelayedMessage, icon: "exclamationmark.icloud.fill")
        case .failed:
            toastService.error(Strings.DataManagement.deleteFailedMessage)
        }
    }
}

// MARK: - Debug Methods

#if DEBUG
import Darwin

extension SettingsViewModel {
    public func loadDatabaseStats() async {
        do {
            databaseStats = try await getDatabaseStats.execute()
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "debug_database_stats")
        }
    }

    public func clearDatabaseData() async {
        isClearingDatabase = true
        error = nil
        do {
            try await clearDatabase.execute()
            databaseStats = try await getDatabaseStats.execute()
            userActionTracker.track(.custom(event: "debug_database_cleared", parameters: [:]))
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "debug_database_clear")
        }
        isClearingDatabase = false
    }

    public func resetOnboarding() async {
        do {
            let resetState = OnboardingState(isCompleted: false, completedDate: nil, userName: nil, hasGrantedNotifications: false)
            try await saveOnboardingState.execute(resetState)
            iCloudKeyValueService.resetOnboardingFlag()
            iCloudKeyValueService.resetLocalOnboardingFlag()
            userDefaults.removeObject(forKey: UserDefaultsKeys.categorySeedingCompleted)
            // Schedule tip reset so training tour can show after re-onboarding
            userDefaults.set(true, forKey: "shouldResetTipsOnNextLaunch")
            onboardingViewModel.reset()
            userActionTracker.track(.custom(event: "debug_onboarding_reset", parameters: [:]))
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "debug_onboarding_reset")
        }
    }

    public func simulateNewDevice() async {
        iCloudKeyValueService.setOnboardingCompleted()
        iCloudKeyValueService.resetLocalOnboardingFlag()
        userDefaults.removeObject(forKey: UserDefaultsKeys.categorySeedingCompleted)
        onboardingViewModel.reset()
        userActionTracker.track(.custom(event: "debug_simulate_new_device", parameters: [:]))
    }

    public func populateTestData(scenario: TestDataScenario = .full) async {
        guard var populateTestData = populateTestData else { return }
        isPopulatingTestData = true
        testDataProgress = 0.0
        testDataProgressMessage = "Starting test data population..."
        error = nil

        populateTestData.progressUpdate = { [weak self] message, progress in
            Task { @MainActor in
                self?.testDataProgressMessage = message
                self?.testDataProgress = progress
            }
        }

        do {
            try await populateTestData.execute(scenario: scenario)
            databaseStats = try await getDatabaseStats.execute()
            userActionTracker.track(.custom(event: "debug_test_data_populated", parameters: ["scenario": scenario.rawValue]))
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "debug_test_data_population")
        }

        isPopulatingTestData = false
        testDataProgress = 0.0
        testDataProgressMessage = ""
    }

    public var memoryUsageMB: Double? {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        return Double(info.resident_size) / 1024.0 / 1024.0
    }

    public func updatePerformanceStats() {
        _ = memoryUsageMB
    }
}
#endif
