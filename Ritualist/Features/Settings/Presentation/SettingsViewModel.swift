import Foundation
import Observation
import FactoryKit
import RitualistCore
import StoreKit

// swiftlint:disable type_body_length
@MainActor @Observable
public final class SettingsViewModel {
    private let loadProfile: LoadProfileUseCase
    private let saveProfile: SaveProfileUseCase
    private let requestNotificationPermission: RequestNotificationPermissionUseCase
    private let checkNotificationStatus: CheckNotificationStatusUseCase
    private let requestLocationPermissions: RequestLocationPermissionsUseCase
    private let getLocationAuthStatus: GetLocationAuthStatusUseCase
    private let clearPurchases: ClearPurchasesUseCase
    private let checkPremiumStatus: CheckPremiumStatusUseCase
    private let getCurrentSubscriptionPlan: GetCurrentSubscriptionPlanUseCase
    private let getSubscriptionExpiryDate: GetSubscriptionExpiryDateUseCase
    private let syncWithiCloud: SyncWithiCloudUseCase
    private let checkiCloudStatus: CheckiCloudStatusUseCase
    private let getLastSyncDate: GetLastSyncDateUseCase
    private let deleteiCloudData: DeleteiCloudDataUseCase
    private let exportUserData: ExportUserDataUseCase
    private let importUserData: ImportUserDataUseCase
    private let getICloudSyncPreference: GetICloudSyncPreferenceUseCase
    private let setICloudSyncPreference: SetICloudSyncPreferenceUseCase
    @ObservationIgnored @Injected(\.userActionTracker) var userActionTracker
    @ObservationIgnored @Injected(\.appearanceManager) var appearanceManager
    @ObservationIgnored @Injected(\.paywallViewModel) var paywallViewModel
    @ObservationIgnored @Injected(\.subscriptionService) var subscriptionService
    @ObservationIgnored @Injected(\.paywallService) var paywallService
    @ObservationIgnored @Injected(\.debugLogger) var logger
    @ObservationIgnored @Injected(\.restoreGeofenceMonitoring) var restoreGeofenceMonitoring
    @ObservationIgnored @Injected(\.dailyNotificationScheduler) var dailyNotificationScheduler
    @ObservationIgnored @Injected(\.toastService) var toastService
    @ObservationIgnored @Injected(\.onboardingViewModel) var onboardingViewModel
    @ObservationIgnored @Injected(\.deduplicateData) var deduplicateData

    #if DEBUG
    private let populateTestData: PopulateTestDataUseCase?
    @ObservationIgnored @Injected(\.getDatabaseStats) var getDatabaseStats
    @ObservationIgnored @Injected(\.clearDatabase) var clearDatabase
    @ObservationIgnored @Injected(\.saveOnboardingState) var saveOnboardingState
    @ObservationIgnored @Injected(\.iCloudKeyValueService) var iCloudKeyValueService
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
    public private(set) var hasNetworkConnectivity: Bool = true
    public var exportedDataJSON: String?
    public var exportedFileURL: URL?
    public private(set) var isImportingData = false
    public var showImportPicker = false
    public var showExportPicker = false

    #if DEBUG
    public private(set) var isClearingDatabase = false
    public private(set) var databaseStats: DebugDatabaseStats?
    public private(set) var isPopulatingTestData = false
    public private(set) var testDataProgress: Double = 0.0
    public private(set) var testDataProgressMessage: String = ""

    // Performance monitoring
    public var showFPSOverlay = false
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

    // Paywall state
    public var paywallItem: PaywallItem?

    // Computed properties
    public var isPremiumUser: Bool {
        cachedPremiumStatus
    }

    /// Current subscription plan from service (not database)
    public var subscriptionPlan: SubscriptionPlan {
        cachedSubscriptionPlan
    }

    /// Subscription expiry date from service (not database)
    /// Returns nil for lifetime subscriptions or free users
    public var subscriptionExpiryDate: Date? {
        cachedSubscriptionExpiryDate
    }

    /// Whether iCloud sync is enabled (user preference)
    /// Default: true (sync enabled by default for premium users)
    /// Premium users can disable in Settings; free users see upgrade prompt instead
    public var iCloudSyncEnabled: Bool {
        getICloudSyncPreference.execute()
    }

    // MARK: - Account Setup Status

    /// Whether iCloud account is signed in
    public var isICloudSignedIn: Bool {
        iCloudStatus == .available
    }

    /// Whether there are any account setup issues that might affect purchases
    /// Note: iCloud status is shown in the iCloud Sync section, not here
    public var hasAccountSetupIssues: Bool {
        !canMakePayments || !hasNetworkConnectivity
    }

    /// List of current account setup issues for display in Subscription section
    /// Note: iCloud status is shown in the iCloud Sync section, not here
    public var accountSetupIssues: [AccountSetupIssue] {
        var issues: [AccountSetupIssue] = []

        if !canMakePayments {
            issues.append(.purchasesRestricted)
        }

        if !hasNetworkConnectivity {
            issues.append(.noNetwork)
        }

        return issues
    }

    /// Set iCloud sync preference (requires app restart to take effect)
    public func setICloudSyncEnabled(_ enabled: Bool) {
        setICloudSyncPreference.execute(enabled)
        userActionTracker.track(.custom(
            event: "icloud_sync_toggled",
            parameters: ["enabled": enabled]
        ))
        logger.log(
            "☁️ iCloud sync preference changed",
            level: .info,
            category: .system,
            metadata: ["enabled": enabled, "requires_restart": true]
        )
    }

    public init(loadProfile: LoadProfileUseCase,
                saveProfile: SaveProfileUseCase,
                requestNotificationPermission: RequestNotificationPermissionUseCase,
                checkNotificationStatus: CheckNotificationStatusUseCase,
                requestLocationPermissions: RequestLocationPermissionsUseCase,
                getLocationAuthStatus: GetLocationAuthStatusUseCase,
                clearPurchases: ClearPurchasesUseCase,
                checkPremiumStatus: CheckPremiumStatusUseCase,
                getCurrentSubscriptionPlan: GetCurrentSubscriptionPlanUseCase,
                getSubscriptionExpiryDate: GetSubscriptionExpiryDateUseCase,
                syncWithiCloud: SyncWithiCloudUseCase,
                checkiCloudStatus: CheckiCloudStatusUseCase,
                getLastSyncDate: GetLastSyncDateUseCase,
                deleteiCloudData: DeleteiCloudDataUseCase,
                exportUserData: ExportUserDataUseCase,
                importUserData: ImportUserDataUseCase,
                getICloudSyncPreference: GetICloudSyncPreferenceUseCase,
                setICloudSyncPreference: SetICloudSyncPreferenceUseCase,
                populateTestData: (any Any)? = nil) {
        self.loadProfile = loadProfile
        self.saveProfile = saveProfile
        self.requestNotificationPermission = requestNotificationPermission
        self.checkNotificationStatus = checkNotificationStatus
        self.requestLocationPermissions = requestLocationPermissions
        self.getLocationAuthStatus = getLocationAuthStatus
        self.clearPurchases = clearPurchases
        self.checkPremiumStatus = checkPremiumStatus
        self.getCurrentSubscriptionPlan = getCurrentSubscriptionPlan
        self.getSubscriptionExpiryDate = getSubscriptionExpiryDate
        self.syncWithiCloud = syncWithiCloud
        self.checkiCloudStatus = checkiCloudStatus
        self.getLastSyncDate = getLastSyncDate
        self.deleteiCloudData = deleteiCloudData
        self.exportUserData = exportUserData
        self.importUserData = importUserData
        self.getICloudSyncPreference = getICloudSyncPreference
        self.setICloudSyncPreference = setICloudSyncPreference
        #if DEBUG
        self.populateTestData = populateTestData as? PopulateTestDataUseCase
        #endif
    }
    
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
        async let networkStatus = NetworkUtilities.hasNetworkConnectivity()
        async let cloudStatus = checkiCloudStatus.execute()

        // Await all results (runs in parallel)
        hasNotificationPermission = await notificationStatus
        locationAuthStatus = await locationStatus
        cachedPremiumStatus = await premiumStatus
        lastSyncDate = await syncDate
        cachedSubscriptionPlan = await subscriptionPlan
        cachedSubscriptionExpiryDate = await subscriptionExpiry
        hasNetworkConnectivity = await networkStatus
        iCloudStatus = await cloudStatus

        // Check if device allows in-app purchases (parental controls, etc.)
        canMakePayments = SKPaymentQueue.canMakePayments()

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

            // Send notification after successful save
            // try? await notificationService.sendImmediate(
            //     title: "Settings Saved",
            //     body: "Your preferences have been updated successfully."
            // )

            // Auto-sync with iCloud after profile changes
            do {
                try await syncWithiCloud.execute()
            } catch {
                logger.log(
                    "Auto-sync after save failed (non-blocking)",
                    level: .warning,
                    category: .network,
                    metadata: ["error": error.localizedDescription]
                )
                #if DEBUG
                toastService.info(Strings.ICloudSync.syncDelayed, icon: "icloud.slash")
                #endif
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

    public func retry() async {
        await load()
    }

    public func requestNotifications() async {
        isRequestingNotifications = true
        error = nil

        do {
            let granted = try await requestNotificationPermission.execute()
            hasNotificationPermission = granted

            // CRITICAL: If permission was just granted, schedule notifications for existing habits
            // This handles the case where user had habits but denied notifications initially
            if granted {
                logger.log(
                    "📅 Scheduling notifications after permission granted",
                    level: .info,
                    category: .notifications
                )
                try await dailyNotificationScheduler.rescheduleAllHabitNotifications()
            }

            // Track notification settings change
            userActionTracker.track(.notificationSettingsChanged(enabled: granted))
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "notification_permission_request")
            hasNotificationPermission = await checkNotificationStatus.execute()
        }
        
        isRequestingNotifications = false
    }
    
    public func refreshNotificationStatus() async {
        hasNotificationPermission = await checkNotificationStatus.execute()
    }

    public func requestLocationPermission() async {
        isRequestingLocationPermission = true
        error = nil

        // Track permission request
        userActionTracker.track(.locationPermissionRequested(context: "settings"))

        let result = await requestLocationPermissions.execute(requestAlways: true)

        switch result {
        case .granted(let status):
            locationAuthStatus = status
            // Track location permission granted
            userActionTracker.track(.locationPermissionGranted(status: String(describing: status), context: "settings"))
            userActionTracker.track(.profileUpdated(field: "location_permission"))

            // CRITICAL: If permission was just granted, restore geofences for existing habits
            // This handles the case where user had location-based habits but denied permission initially
            logger.log(
                "🌍 Restoring geofences after location permission granted",
                level: .info,
                category: .location
            )
            do {
                try await restoreGeofenceMonitoring.execute()
            } catch {
                logger.log(
                    "Failed to restore geofences after permission granted",
                    level: .error,
                    category: .location,
                    metadata: ["error": error.localizedDescription]
                )
                userActionTracker.trackError(error, context: "geofence_restore_after_permission")
                #if DEBUG
                toastService.warning(Strings.Location.geofenceRestoreFailed)
                #endif
            }

        case .denied:
            locationAuthStatus = .denied
            // Track location permission denied
            userActionTracker.track(.locationPermissionDenied(context: "settings"))
        case .failed(let locationError):
            self.error = locationError
            userActionTracker.trackError(locationError, context: "location_permission_request")
            locationAuthStatus = await getLocationAuthStatus.execute()
        }

        isRequestingLocationPermission = false
    }

    public func refreshLocationStatus() async {
        locationAuthStatus = await getLocationAuthStatus.execute()
    }

    // MARK: - Authentication Methods
    
    // Sign out is no longer needed since there's no authentication
    
    public func updateUserName(_ name: String) async {
        isUpdatingUser = true
        error = nil

        // Update both the local profile state and via UserService
        profile.name = name
        profile.updatedAt = Date()

        do {
            try await saveProfile.execute(profile)

            // Track user name update
            userActionTracker.track(.profileUpdated(field: "name"))

            // Auto-sync with iCloud after profile changes
            do {
                try await syncWithiCloud.execute()
            } catch {
                logger.log(
                    "Auto-sync after name update failed (non-blocking)",
                    level: .warning,
                    category: .network,
                    metadata: ["error": error.localizedDescription]
                )
                #if DEBUG
                toastService.info(Strings.ICloudSync.syncDelayed, icon: "icloud.slash")
                #endif
            }
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "user_name_update", additionalProperties: ["name": name])
        }

        isUpdatingUser = false
    }
    
    public func cancelSubscription() async {
        isCancellingSubscription = true
        error = nil

        // Clear any stored purchases
        // NOTE: Subscription cancellation now happens entirely through StoreKit/App Store
        // The SecureSubscriptionService automatically reflects the cancellation status
        clearPurchases.execute()

        isCancellingSubscription = false
    }
    
    // Method to refresh premium status after purchases
    public func refreshPremiumStatus() async {
        cachedPremiumStatus = await checkPremiumStatus.execute()
    }
    
    /// Update the app appearance based on the appearance setting
    public func updateAppearance(_ appearance: Int) async {
        // Update the profile appearance setting
        profile.appearance = appearance
        profile.updatedAt = Date()

        // Apply the appearance change to the appearance manager
        appearanceManager.updateFromProfile(profile)

        // Save the profile changes
        do {
            try await saveProfile.execute(profile)

            // Track appearance change
            userActionTracker.track(.profileUpdated(field: "appearance"))

            // Auto-sync with iCloud after profile changes
            do {
                try await syncWithiCloud.execute()
            } catch {
                logger.log(
                    "Auto-sync after appearance update failed (non-blocking)",
                    level: .warning,
                    category: .network,
                    metadata: ["error": error.localizedDescription]
                )
                #if DEBUG
                toastService.info(Strings.ICloudSync.syncDelayed, icon: "icloud.slash")
                #endif
            }
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "appearance_update", additionalProperties: ["appearance": String(appearance)])
        }
    }

    // MARK: - iCloud Sync Methods

    /// Track in-progress status check to prevent concurrent calls
    /// Marked @ObservationIgnored since task state shouldn't trigger view updates
    @ObservationIgnored private var statusCheckTask: Task<Void, Never>?

    deinit {
        // Cancel any in-progress status check to prevent work on deallocated instance
        statusCheckTask?.cancel()
    }

    /// Refresh iCloud account status
    /// Timeout protection is handled by CheckiCloudStatusUseCase
    public func refreshiCloudStatus() async {
        // Prevent concurrent status checks - reuse existing if in progress
        if let existingTask = statusCheckTask {
            await existingTask.value
            return
        }

        // Create and store the task before starting work
        let task = Task { [weak self] in
            guard let self, !Task.isCancelled else { return }

            isCheckingCloudStatus = true
            iCloudStatus = await checkiCloudStatus.execute()

            // Check cancellation after async work completes
            guard !Task.isCancelled else {
                isCheckingCloudStatus = false
                return
            }

            isCheckingCloudStatus = false
            statusCheckTask = nil
        }

        statusCheckTask = task
        await task.value
    }

    /// Force a fresh iCloud status check with logging for diagnostics
    public func forceCloudStatusCheck() async {
        logger.log(
            "🔍 Force iCloud status check requested",
            level: .info,
            category: .system
        )
        await refreshiCloudStatus()
        logger.log(
            "✅ iCloud status check complete",
            level: .info,
            category: .system,
            metadata: ["status": iCloudStatus.displayMessage]
        )
    }

    /// Result of delete all data operation
    public enum DeleteAllDataResult {
        case success
        case successButCloudSyncMayBeDelayed
        case failed(Error)
    }

    /// Delete all data (GDPR compliance - Right to be forgotten)
    /// Permanently deletes all habits, logs, and profile from device and iCloud (if configured)
    /// - Returns: Result indicating success and whether cloud sync might be delayed
    public func deleteAllData() async -> DeleteAllDataResult {
        isDeletingCloudData = true
        error = nil

        // Check if we should warn about delayed iCloud sync
        let isOnline = await NetworkUtilities.hasNetworkConnectivity()
        let shouldWarnAboutSync = iCloudStatus.canSync && !isOnline

        do {
            try await deleteiCloudData.execute()

            // Clear last sync date since there's no data anymore
            lastSyncDate = nil

            // Reset profile to empty state for immediate UI feedback
            profile = UserProfile()

            // Track deletion action
            let eventParams: [String: Any] = [
                "icloud_configured": iCloudStatus.canSync,
                "offline_warning": shouldWarnAboutSync
            ]
            userActionTracker.track(.custom(event: "all_data_deleted_by_user", parameters: eventParams))

            // Reset onboarding view model to clear any cached state
            onboardingViewModel.reset()

            isDeletingCloudData = false

            if shouldWarnAboutSync {
                return .successButCloudSyncMayBeDelayed
            }
            return .success
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "delete_all_data")
            isDeletingCloudData = false
            return .failed(error)
        }
    }

    /// Export user data (GDPR compliance - Right to data portability)
    /// Exports all user data as JSON string for sharing/backup
    public func exportData() async {
        isExportingData = true
        error = nil

        do {
            let jsonString = try await exportUserData.execute()
            exportedDataJSON = jsonString

            // Track export action
            userActionTracker.track(.custom(event: "user_data_exported", parameters: [:]))
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "export_user_data")
        }

        isExportingData = false
    }

    /// Import user data (GDPR compliance - Right to data portability)
    /// Imports all user data from JSON string, merging with existing data
    public func importData(jsonString: String) async {
        isImportingData = true
        error = nil

        do {
            try await importUserData.execute(jsonString: jsonString)

            // Reload profile after import
            await load()

            // CRITICAL: Reschedule notifications for imported habits
            // Import happens after app launch, so initial scheduling missed the imported data
            logger.log(
                "📅 Rescheduling notifications after import",
                level: .info,
                category: .dataIntegrity
            )
            try await dailyNotificationScheduler.rescheduleAllHabitNotifications()

            // CRITICAL: Restore geofences for imported habits with location-based reminders
            // Geofences are device-local and must be re-registered after import
            logger.log(
                "🌍 Restoring geofences after import",
                level: .info,
                category: .dataIntegrity
            )
            try await restoreGeofenceMonitoring.execute()

            // Track import action
            userActionTracker.track(.custom(event: "user_data_imported", parameters: [:]))
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "import_user_data")
        }

        isImportingData = false
    }

    // MARK: - Debug Methods
    
    #if DEBUG
    public func loadDatabaseStats() async {
        do {
            databaseStats = try await getDatabaseStats.execute()
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "debug_database_stats")
        }
    }
    
    public func clearDatabase() async {
        isClearingDatabase = true
        error = nil
        
        do {
            try await clearDatabase.execute()
            
            // Reload stats after clearing
            databaseStats = try await getDatabaseStats.execute()
            
            // Track the debug action
            userActionTracker.track(.custom(event: "debug_database_cleared", parameters: [:]))
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "debug_database_clear")
        }
        
        isClearingDatabase = false
    }

    public func resetOnboarding() async {
        do {
            // Reset onboarding state to default (not completed)
            let resetState = OnboardingState(
                isCompleted: false,
                completedDate: nil,
                userName: nil,
                hasGrantedNotifications: false
            )

            try await saveOnboardingState.execute(resetState)

            // Also reset the iCloud onboarding flag
            iCloudKeyValueService.resetOnboardingFlag()

            // Reset the local device flag (so this device sees new user flow)
            iCloudKeyValueService.resetLocalOnboardingFlag()

            // Reset categorySeedingCompleted flag (used in migration check)
            // Without this, the app treats the user as "existing" and skips onboarding
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.categorySeedingCompleted)

            // Reset onboarding view model to clear any cached state
            onboardingViewModel.reset()

            // Track the debug action
            userActionTracker.track(.custom(event: "debug_onboarding_reset", parameters: [:]))
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "debug_onboarding_reset")
        }
    }

    /// Simulates a returning user on a new device for testing.
    /// Keeps the iCloud onboarding flag (hasCompletedOnboarding) but clears local flags.
    /// This allows testing the returning user welcome flow without deleting the app.
    public func simulateNewDevice() async {
        // Keep iCloud flag set (user completed onboarding on "another device")
        // Just ensure it's set in case it isn't
        iCloudKeyValueService.setOnboardingCompleted()

        // Clear local device flag (this "device" hasn't seen onboarding)
        iCloudKeyValueService.resetLocalOnboardingFlag()

        // Clear categorySeedingCompleted (so migration check doesn't skip onboarding)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.categorySeedingCompleted)

        // Reset onboarding view model
        onboardingViewModel.reset()

        // Track the debug action
        userActionTracker.track(.custom(event: "debug_simulate_new_device", parameters: [:]))
    }

    public func populateTestData(scenario: TestDataScenario = .full) async {
        guard var populateTestData = populateTestData else { return }

        isPopulatingTestData = true
        testDataProgress = 0.0
        testDataProgressMessage = "Starting test data population..."
        error = nil

        // Setup progress callback
        populateTestData.progressUpdate = { [weak self] message, progress in
            Task { @MainActor in
                self?.testDataProgressMessage = message
                self?.testDataProgress = progress
            }
        }

        do {
            try await populateTestData.execute(scenario: scenario)

            // Reload stats after populating data
            databaseStats = try await getDatabaseStats.execute()

            // Track the debug action with scenario info
            userActionTracker.track(.custom(event: "debug_test_data_populated", parameters: ["scenario": scenario.rawValue]))
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "debug_test_data_population")
        }

        isPopulatingTestData = false
        testDataProgress = 0.0
        testDataProgressMessage = ""
    }
    #endif
}

// MARK: - Performance Utilities

#if DEBUG
import Darwin

extension SettingsViewModel {
    /// Current memory usage in megabytes
    ///
    /// Uses mach_task_basic_info to get accurate resident memory size
    /// Returns nil if unable to retrieve memory info
    public var memoryUsageMB: Double? {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return nil }

        // Convert bytes to megabytes
        return Double(info.resident_size) / 1024.0 / 1024.0
    }

    /// Updates performance statistics (triggers view refresh)
    public func updatePerformanceStats() {
        // Access memoryUsageMB to trigger observable update
        _ = memoryUsageMB
    }
}
#endif

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
        cachedPremiumStatus = await checkPremiumStatus.execute()
        logger.logSubscription(
            event: "Updated subscription status",
            plan: cachedSubscriptionPlan.rawValue,
            metadata: [
                "expiry": cachedSubscriptionExpiryDate?.description ?? "nil",
                "is_premium": cachedPremiumStatus
            ]
        )
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
