import Foundation
import Observation
import FactoryKit
import RitualistCore

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
    private let updateLastSyncDate: UpdateLastSyncDateUseCase
    @ObservationIgnored @Injected(\.userActionTracker) var userActionTracker
    @ObservationIgnored @Injected(\.appearanceManager) var appearanceManager
    @ObservationIgnored @Injected(\.paywallViewModel) var paywallViewModel
    @ObservationIgnored @Injected(\.subscriptionService) var subscriptionService
    @ObservationIgnored @Injected(\.paywallService) var paywallService
    @ObservationIgnored @Injected(\.debugLogger) var logger

    #if DEBUG
    private let populateTestData: PopulateTestDataUseCase?
    @ObservationIgnored @Injected(\.getDatabaseStats) var getDatabaseStats
    @ObservationIgnored @Injected(\.clearDatabase) var clearDatabase
    @ObservationIgnored @Injected(\.saveOnboardingState) var saveOnboardingState
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
    public private(set) var isSyncing = false
    public private(set) var lastSyncDate: Date?
    public private(set) var iCloudStatus: iCloudSyncStatus = .unknown
    public private(set) var isCheckingCloudStatus = false
    
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
                updateLastSyncDate: UpdateLastSyncDateUseCase,
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
        self.updateLastSyncDate = updateLastSyncDate
        #if DEBUG
        self.populateTestData = populateTestData as? PopulateTestDataUseCase
        #endif
    }
    
    public func load() async {
        isLoading = true
        error = nil
        do {
            profile = try await loadProfile.execute()
            hasNotificationPermission = await checkNotificationStatus.execute()
            locationAuthStatus = await getLocationAuthStatus.execute()
            cachedPremiumStatus = await checkPremiumStatus.execute()
            lastSyncDate = await getLastSyncDate.execute()
            await refreshiCloudStatus()

            // Cache subscription data from service (not database)
            cachedSubscriptionPlan = await getCurrentSubscriptionPlan.execute()
            cachedSubscriptionExpiryDate = await getSubscriptionExpiryDate.execute()
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
            hasNotificationPermission = await checkNotificationStatus.execute()
            locationAuthStatus = await getLocationAuthStatus.execute()
            cachedPremiumStatus = await checkPremiumStatus.execute()
            lastSyncDate = await getLastSyncDate.execute()

            // Cache subscription data from service even on error
            cachedSubscriptionPlan = await getCurrentSubscriptionPlan.execute()
            cachedSubscriptionExpiryDate = await getSubscriptionExpiryDate.execute()
        }
        isLoading = false
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

        // Apply the appearance change to the appearance manager
        appearanceManager.updateFromProfile(profile)

        // Track appearance change
        userActionTracker.track(.profileUpdated(field: "appearance"))
    }

    // MARK: - iCloud Sync Methods

    /// Manually trigger iCloud sync
    public func syncNow() async {
        isSyncing = true
        error = nil

        do {
            try await syncWithiCloud.execute()
            await updateLastSyncDate.execute(Date())
            lastSyncDate = Date()

            // Track sync action
            userActionTracker.track(.custom(event: "icloud_manual_sync", parameters: [:]))
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "icloud_manual_sync")
        }

        isSyncing = false
    }

    /// Refresh iCloud account status
    public func refreshiCloudStatus() async {
        isCheckingCloudStatus = true

        // Note: checkiCloudStatus never throws - it returns .unknown for all error cases
        iCloudStatus = await checkiCloudStatus.execute()

        isCheckingCloudStatus = false
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
