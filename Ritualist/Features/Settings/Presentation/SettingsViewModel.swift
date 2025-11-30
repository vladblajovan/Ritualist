import Foundation
import Observation
import FactoryKit
import RitualistCore

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
    @ObservationIgnored @Injected(\.userActionTracker) var userActionTracker
    @ObservationIgnored @Injected(\.appearanceManager) var appearanceManager
    @ObservationIgnored @Injected(\.paywallViewModel) var paywallViewModel
    @ObservationIgnored @Injected(\.subscriptionService) var subscriptionService
    @ObservationIgnored @Injected(\.paywallService) var paywallService
    @ObservationIgnored @Injected(\.debugLogger) var logger
    @ObservationIgnored @Injected(\.restoreGeofenceMonitoring) var restoreGeofenceMonitoring
    @ObservationIgnored @Injected(\.dailyNotificationScheduler) var dailyNotificationScheduler

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
        #if DEBUG
        self.populateTestData = populateTestData as? PopulateTestDataUseCase
        #endif
    }
    
    public func load() async {
        isLoading = true
        error = nil
        do {
            profile = try await loadProfile.execute()
            await loadStatusesInParallel()
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
        async let notificationStatus = checkNotificationStatus.execute()
        async let locationStatus = getLocationAuthStatus.execute()
        async let premiumStatus = checkPremiumStatus.execute()
        async let syncDate = getLastSyncDate.execute()
        async let subscriptionPlan = getCurrentSubscriptionPlan.execute()
        async let subscriptionExpiry = getSubscriptionExpiryDate.execute()

        // Await all results (runs in parallel)
        hasNotificationPermission = await notificationStatus
        locationAuthStatus = await locationStatus
        cachedPremiumStatus = await premiumStatus
        lastSyncDate = await syncDate
        cachedSubscriptionPlan = await subscriptionPlan
        cachedSubscriptionExpiryDate = await subscriptionExpiry

        // iCloud status has its own loading indicator, run after parallel batch
        await refreshiCloudStatus()
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
            try? await restoreGeofenceMonitoring.execute()

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
            }
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "appearance_update", additionalProperties: ["appearance": String(appearance)])
        }
    }

    // MARK: - iCloud Sync Methods

    /// Refresh iCloud account status
    public func refreshiCloudStatus() async {
        isCheckingCloudStatus = true

        // Note: checkiCloudStatus never throws - it returns .unknown for all error cases
        iCloudStatus = await checkiCloudStatus.execute()

        isCheckingCloudStatus = false
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

            // Track deletion action
            let eventParams: [String: Any] = [
                "icloud_configured": iCloudStatus.canSync,
                "offline_warning": shouldWarnAboutSync
            ]
            userActionTracker.track(.custom(event: "all_data_deleted_by_user", parameters: eventParams))

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

            // Track the debug action
            userActionTracker.track(.custom(event: "debug_onboarding_reset", parameters: [:]))
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "debug_onboarding_reset")
        }
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
    public func showPaywall() {
        Task {
            await paywallViewModel.load()
            paywallViewModel.trackPaywallShown(source: "settings", trigger: "subscribe_button")
            paywallItem = PaywallItem(viewModel: paywallViewModel)
        }
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
