//
//  RitualistApp.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 29.07.2025.
//

import SwiftUI
import SwiftData
import FactoryKit
import RitualistCore
import UIKit
import CoreData

// swiftlint:disable type_body_length
@main struct RitualistApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Injected(\.notificationService) private var notificationService
    @Injected(\.persistenceContainer) private var persistenceContainer
    @Injected(\.urlValidationService) private var urlValidationService
    @Injected(\.navigationService) private var navigationService
    @Injected(\.dailyNotificationScheduler) private var dailyNotificationScheduler
    @Injected(\.restoreGeofenceMonitoring) private var restoreGeofenceMonitoring
    @Injected(\.timezoneService) private var timezoneService
    @Injected(\.seedPredefinedCategories) private var seedPredefinedCategories
    @Injected(\.syncWithiCloud) private var syncWithiCloud
    @Injected(\.updateLastSyncDate) private var updateLastSyncDate
    @Injected(\.checkiCloudStatus) private var checkiCloudStatus
    @Injected(\.debugLogger) private var logger
    @Injected(\.userActionTracker) private var userActionTracker
    @Injected(\.deduplicateData) private var deduplicateData

    /// Track if initial launch tasks have completed to avoid duplicate work.
    ///
    /// SYNCHRONIZATION: This flag prevents race conditions between `.task` and `.onReceive` handlers.
    /// - `.task` runs `performInitialLaunchTasks()` which includes `restoreGeofences()`
    /// - `.onReceive` handlers check this flag and return early if initial launch isn't complete
    /// - After initial launch, `lastGeofenceRestorationUptime` throttle provides additional protection
    /// This ensures geofence restoration never runs concurrently from multiple sources.
    @State private var hasCompletedInitialLaunch = false

    /// Track last geofence restoration time (using system uptime for clock-drift immunity)
    /// Uses ProcessInfo.systemUptime which is monotonic and unaffected by user clock changes
    @State private var lastGeofenceRestorationUptime: TimeInterval?

    /// Track last deduplication time (using system uptime for clock-drift immunity)
    @State private var lastDeduplicationUptime: TimeInterval?

    /// Track whether the last deduplication run had data to check
    /// If false, we don't throttle because data may arrive later
    @State private var lastDeduplicationHadData: Bool = false

    /// App startup time for performance monitoring
    private let appStartTime = Date()

    /// Minimum interval between geofence restorations (in seconds).
    ///
    /// CloudKit can fire multiple NSPersistentStoreRemoteChange notifications in quick succession
    /// (observed: 16+ notifications within seconds during bulk sync). Without throttling, each
    /// notification would trigger a full geofence restoration cycle, causing:
    /// - Excessive iOS CLLocationManager region registration calls
    /// - Database contention from concurrent reads
    /// - Unnecessary CPU/battery usage
    ///
    /// 30 seconds provides a balance between responsiveness (user gets geofences within 30s of sync)
    /// and efficiency (bulk syncs are batched into a single restoration).
    private let geofenceRestorationThrottleInterval: TimeInterval = 30

    /// Minimum interval between deduplication runs (in seconds).
    ///
    /// CloudKit can fire multiple NSPersistentStoreRemoteChange notifications in quick succession.
    /// Deduplication is idempotent (running it twice has no additional effect), but we throttle
    /// to avoid unnecessary database reads during bulk sync operations.
    private let deduplicationThrottleInterval: TimeInterval = 30

    var body: some Scene {
        WindowGroup {
            RootAppView()
                .modelContainer(persistenceContainer.container)
                .task { @MainActor in
                    await performInitialLaunchTasks()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Re-schedule notifications when app becomes active (handles day changes while backgrounded)
                    // Skip if this is the initial launch (already handled in task above)
                    guard hasCompletedInitialLaunch else { return }
                    Task {
                        await detectTimezoneChanges()
                        await rescheduleNotificationsIfNeeded()
                        await syncWithCloudIfAvailable()
                        // Restore geofences after iCloud sync to handle new device setup scenario:
                        // When user sets up a new device, iCloud syncs habit data including location configs,
                        // but geofences are device-local and must be re-registered with iOS.
                        await restoreGeofences()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                    // Handle significant time changes: midnight crossing, daylight saving, user clock changes
                    // Our notifications are scheduled for "today" only, so midnight crossings require rescheduling
                    guard hasCompletedInitialLaunch else { return }
                    Task {
                        logger.log(
                            "⏰ Significant time change detected - rescheduling notifications",
                            level: .info,
                            category: .notifications
                        )
                        await rescheduleNotificationsIfNeeded()
                    }
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onReceive(NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)) { _ in
                    // Handle background iCloud sync: iOS/CloudKit synced data to local store
                    // This covers the scenario where user sets up new device and iCloud syncs
                    // habit data with location configs while app is backgrounded or suspended.
                    // Geofences are device-local, so we must re-register them after sync.
                    //
                    // NOTE: SwiftUI's .onReceive automatically manages subscription lifecycle.
                    // We delay to allow SwiftData to complete merging the remote changes.
                    // See BusinessConstants.remoteChangeMergeDelay documentation for rationale.
                    guard hasCompletedInitialLaunch else { return }

                    // Update last sync timestamp when real CloudKit sync occurs
                    UserDefaults.standard.set(Date(), forKey: UserDefaultsKeys.lastSyncDate)

                    Task {
                        try? await Task.sleep(for: .seconds(BusinessConstants.remoteChangeMergeDelay))

                        // ALWAYS notify UI that iCloud synced data - this triggers auto-refresh in OverviewView
                        // and the one-time toast in RootTabView. Do this outside throttle checks so UI
                        // always gets notified even if geofences/dedup are throttled.
                        NotificationCenter.default.post(name: .iCloudDidSyncRemoteChanges, object: nil)

                        // Deduplicate any duplicates created by CloudKit sync before restoring geofences
                        // Uses throttling to avoid excessive database operations during bulk sync
                        await deduplicateSyncedDataThrottled()
                        await restoreGeofencesThrottled()
                    }
                }
        }
    }

    /// Perform all initial launch tasks and log startup metrics
    private func performInitialLaunchTasks() async {
        // Log startup context
        logStartupContext()

        await seedCategories()
        await deduplicateSyncedData()
        await detectTimezoneChanges()
        await setupNotifications()
        await scheduleInitialNotifications()
        await restoreGeofences()
        await syncWithCloudIfAvailable()

        // Mark initial launch as complete
        hasCompletedInitialLaunch = true

        // Log total startup time
        let startupDuration = Date().timeIntervalSince(appStartTime)
        logger.logPerformance(operation: "App startup", duration: startupDuration, metadata: [
            "tasks_completed": "seed_categories, timezone_detection, notifications_setup, geofence_restore, icloud_sync"
        ])
    }

    /// Log app startup context for debugging
    private func logStartupContext() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"

        // Base metadata for all builds
        var metadata: [String: Any] = [
            "version": appVersion,
            "build": buildNumber,
            "schema_version": RitualistMigrationPlan.currentSchemaVersion.description
        ]

        // Device details only in DEBUG (device_name can contain user's real name)
        #if DEBUG
        metadata["device_model"] = UIDevice.current.model
        metadata["device_name"] = UIDevice.current.name
        metadata["os"] = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        metadata["cloudkit_container"] = PersistenceContainer.cloudKitContainerIdentifier
        #endif

        logger.log(
            "🚀 App starting",
            level: .info,
            category: .system,
            metadata: metadata
        )
    }
    
    // Fallback container if dependency injection fails
    // CRITICAL: This should never reference a specific schema version!
    // Schema version should always come from PersistenceContainer
    private func createFallbackContainer() -> ModelContainer {
        fatalError("Fallback container should never be used - PersistenceContainer must be properly initialized via DI")
    }
    
    private func seedCategories() async {
        // Seed predefined categories into database on app launch
        // This ensures category relationships work for habits from suggestions
        do {
            try await seedPredefinedCategories.execute()
        } catch {
            logger.log(
                "⚠️ Failed to seed predefined categories",
                level: .warning,
                category: .system,
                metadata: ["error": error.localizedDescription]
            )
        }
    }

    /// Deduplicate any duplicate records that may have been created during iCloud sync
    /// CloudKit + SwiftData can create duplicates when @Attribute(.unique) is not available
    private func deduplicateSyncedData() async {
        do {
            let result = try await deduplicateData.execute()
            lastDeduplicationUptime = ProcessInfo.processInfo.systemUptime
            lastDeduplicationHadData = result.hadDataToCheck

            if result.hadDuplicates {
                logger.log(
                    "🔄 Cleaned up duplicate records from iCloud sync",
                    level: .info,
                    category: .system,
                    metadata: [
                        "habits_removed": result.habitsRemoved,
                        "categories_removed": result.categoriesRemoved,
                        "logs_removed": result.habitLogsRemoved,
                        "profiles_removed": result.profilesRemoved,
                        "total_items_checked": result.totalItemsChecked
                    ]
                )
            } else if !result.hadDataToCheck {
                logger.log(
                    "🔄 Deduplication complete - no data in database yet (waiting for iCloud sync)",
                    level: .debug,
                    category: .system
                )
            }
        } catch {
            logger.log(
                "⚠️ Failed to deduplicate synced data",
                level: .warning,
                category: .system,
                metadata: ["error": error.localizedDescription]
            )
        }
    }

    /// Deduplicate with throttling to avoid excessive database operations during rapid sync events
    /// CloudKit can fire multiple NSPersistentStoreRemoteChange notifications in quick succession
    private func deduplicateSyncedDataThrottled() async {
        // Check if we've deduplicated recently (using monotonic system uptime, immune to clock changes)
        let currentUptime = ProcessInfo.processInfo.systemUptime
        if let lastUptime = lastDeduplicationUptime,
           (currentUptime - lastUptime) < deduplicationThrottleInterval {
            // Only throttle if the previous run had data to check.
            // If no data existed (fresh install waiting for iCloud), keep trying until data arrives.
            if lastDeduplicationHadData {
                logger.log(
                    "⏭️ Skipping deduplication (throttled)",
                    level: .debug,
                    category: .system,
                    metadata: ["secondsSinceLast": String(format: "%.1f", currentUptime - lastUptime)]
                )
                return
            } else {
                logger.log(
                    "🔄 Running deduplication despite throttle (no data found in previous run)",
                    level: .debug,
                    category: .system
                )
            }
        }

        await deduplicateSyncedData()
    }

    private func setupNotifications() async {
        // Setup notification categories on app launch
        await notificationService.setupNotificationCategories()

        // Set up notification delegate - handled by LocalNotificationService
        // Removed: UNUserNotificationCenter.current().delegate = appDelegate
    }

    /// Schedule initial notifications on app launch
    ///
    /// IMPORTANT: Only schedules if notification authorization is granted.
    /// iOS silently drops notifications when unauthorized, so we check first.
    private func scheduleInitialNotifications() async {
        // Check authorization status first - scheduling without authorization silently fails
        let isAuthorized = await notificationService.checkAuthorizationStatus()

        guard isAuthorized else {
            logger.log(
                "⏭️ Skipping notification scheduling - not authorized",
                level: .info,
                category: .system,
                metadata: ["reason": "authorization_not_granted"]
            )
            return
        }

        do {
            logger.log(
                "🚀 Scheduling initial notifications on app launch",
                level: .info,
                category: .system
            )
            try await dailyNotificationScheduler.rescheduleAllHabitNotifications()
        } catch {
            logger.log(
                "⚠️ Failed to schedule initial notifications",
                level: .warning,
                category: .system,
                metadata: ["error": error.localizedDescription]
            )
        }
    }

    /// Re-schedule notifications if needed (e.g., when app becomes active)
    /// This handles day changes and completion status updates while the app was backgrounded
    ///
    /// IMPORTANT: Only schedules if notification authorization is granted.
    private func rescheduleNotificationsIfNeeded() async {
        // Check authorization status first - scheduling without authorization silently fails
        let isAuthorized = await notificationService.checkAuthorizationStatus()

        guard isAuthorized else {
            logger.log(
                "⏭️ Skipping notification re-scheduling - not authorized",
                level: .debug,
                category: .system
            )
            return
        }

        do {
            logger.log(
                "🔄 Re-scheduling notifications on app active",
                level: .info,
                category: .system
            )
            try await dailyNotificationScheduler.rescheduleAllHabitNotifications()
        } catch {
            logger.log(
                "⚠️ Failed to re-schedule notifications",
                level: .warning,
                category: .system,
                metadata: ["error": error.localizedDescription]
            )
        }
    }

    /// Restore geofence monitoring for habits with location-based reminders
    /// This is called on app launch to restore geofences after app restart/kill
    private func restoreGeofences() async {
        do {
            logger.log(
                "🌍 Restoring geofence monitoring",
                level: .info,
                category: .system
            )
            try await restoreGeofenceMonitoring.execute()
            lastGeofenceRestorationUptime = ProcessInfo.processInfo.systemUptime
        } catch {
            logger.log(
                "⚠️ Failed to restore geofence monitoring",
                level: .warning,
                category: .system,
                metadata: ["error": error.localizedDescription]
            )
            userActionTracker.trackError(error, context: "geofence_restoration")
        }
    }

    /// Restore geofences with throttling to avoid excessive calls during rapid sync events
    /// CloudKit can fire multiple NSPersistentStoreRemoteChange notifications in quick succession
    private func restoreGeofencesThrottled() async {
        // Check if we've restored recently (using monotonic system uptime, immune to clock changes)
        let currentUptime = ProcessInfo.processInfo.systemUptime
        if let lastUptime = lastGeofenceRestorationUptime,
           (currentUptime - lastUptime) < geofenceRestorationThrottleInterval {
            logger.log(
                "⏭️ Skipping geofence restoration (throttled)",
                level: .debug,
                category: .system,
                metadata: ["secondsSinceLast": String(format: "%.1f", currentUptime - lastUptime)]
            )
            return
        }

        logger.log(
            "☁️ iCloud remote change detected - restoring geofences",
            level: .info,
            category: .system
        )

        // NOTE: UI notification (.iCloudDidSyncRemoteChanges) is now posted earlier in the
        // .NSPersistentStoreRemoteChange handler, BEFORE throttle checks. This ensures UI
        // always gets notified even when geofences/dedup are throttled.

        await restoreGeofences()
    }

    /// Detect timezone changes on app launch/resume
    /// Updates stored current timezone if device timezone changed
    /// This is part of the three-timezone model for proper travel handling
    private func detectTimezoneChanges() async {
        do {
            // Atomically capture current device timezone to prevent race conditions
            let currentDeviceTimezone = TimeZone.current.identifier
            let storedTimezone = try await timezoneService.getCurrentTimezone().identifier

            // Check if timezone changed
            guard currentDeviceTimezone != storedTimezone else { return }

            logger.log(
                "🌐 Timezone change detected",
                level: .info,
                category: .system,
                metadata: [
                    "previousTimezone": storedTimezone,
                    "newTimezone": currentDeviceTimezone,
                    "detectedAt": Date().ISO8601Format()
                ]
            )

            // Update stored current timezone with the captured value
            try await timezoneService.updateCurrentTimezone()

            logger.log(
                "✅ Updated current timezone",
                level: .info,
                category: .system,
                metadata: ["newTimezone": currentDeviceTimezone]
            )

            // CRITICAL: Reschedule notifications when timezone changes
            // Notifications are scheduled at local times, so they need to be rescheduled
            // to fire at the correct local time in the new timezone
            logger.log(
                "📅 Rescheduling notifications after timezone change",
                level: .info,
                category: .notifications
            )
            try await dailyNotificationScheduler.rescheduleAllHabitNotifications()

            // TODO Phase 3: Show travel notification to user
            // if let travelStatus = try await timezoneService.detectTravelStatus(), travelStatus.isTravel {
            //     // Show notification about timezone change and travel mode
            // }
        } catch {
            logger.log(
                "⚠️ Failed to detect timezone changes",
                level: .warning,
                category: .system,
                metadata: ["error": error.localizedDescription]
            )
        }
    }

    /// Handle deep links from widget taps
    /// Navigates to appropriate habit or overview section with enhanced validation
    private func handleDeepLink(_ url: URL) {
        // Validate the URL first using centralized service
        let validationResult = urlValidationService.validateDeepLinkURL(url)

        guard validationResult.isValid else {
            logger.log(
                "🔗 Deep link validation failed",
                level: .warning,
                category: .system,
                metadata: ["url": url.absoluteString, "reason": validationResult.description]
            )
            // Fallback to overview for invalid URLs
            handleOverviewDeepLink()
            return
        }
        
        switch url.host {
        case "habit":
            handleHabitDeepLink(url)
        case "overview":
            handleOverviewDeepLink()
        default:
            // Unknown deep link - navigate to overview as fallback
            handleOverviewDeepLink()
        }
    }
    
    /// Handle habit-specific deep links from widget
    /// Formats:
    /// - Legacy: ritualist://habit/{habitId}
    /// - Enhanced: ritualist://habit/{habitId}?date={ISO8601}&action={action}
    private func handleHabitDeepLink(_ url: URL) {
        // Use centralized validation service to extract habit ID
        guard let habitId = urlValidationService.extractHabitId(from: url) else {
            // Invalid habit ID - fallback to overview
            logger.log(
                "🔗 Failed to extract valid habit ID",
                level: .warning,
                category: .system,
                metadata: ["url": url.absoluteString]
            )
            handleOverviewDeepLink()
            return
        }
        
        // Extract date and action parameters using validation service
        let targetDate = urlValidationService.extractDate(from: url)
        let action = urlValidationService.extractAction(from: url)
        
        Task { @MainActor in            
            // For enhanced deep links with date and action parameters
            if let targetDate = targetDate {
                
                // Navigate to Overview tab with date context
                navigationService.navigateToOverview(shouldRefresh: true)
                
                // Handle specific actions using type-safe enum
                switch action {
                case .progress:
                    // For numeric habits: Navigate and show progress sheet
                    await handleProgressDeepLinkAction(habitId: habitId, targetDate: targetDate)
                    
                case .view:
                    // For completed binary habits: Just navigate to view the date
                    logger.log(
                        "🔗 View action requested",
                        level: .info,
                        category: .system,
                        metadata: ["habitId": habitId.uuidString, "date": targetDate.ISO8601Format()]
                    )

                    // Navigate to the specific date in overview
                    // The overview will show the habit status for that date
                    await navigateToDateInOverview(targetDate)
                }
            } else {
                // Legacy deep link: Navigate to Overview tab and trigger habit completion flow
                navigationService.navigateToOverview(shouldRefresh: true)
                logger.log(
                    "🔗 Legacy deep link - navigated to overview",
                    level: .info,
                    category: .system,
                    metadata: ["habitId": habitId.uuidString]
                )
            }
        }
    }
    
    /// Handle progress deep link action for numeric habits
    /// Opens the progress sheet for the specified habit and date
    @MainActor
    private func handleProgressDeepLinkAction(habitId: UUID, targetDate: Date) async {
        logger.log(
            "🔗 Progress action requested",
            level: .info,
            category: .system,
            metadata: ["habitId": habitId.uuidString, "date": targetDate.ISO8601Format()]
        )

        do {
            // Fetch the habit to verify it exists and is numeric
            let habitRepository = Container.shared.habitRepository()
            let habits = try await habitRepository.fetchAllHabits()

            guard let habit = habits.first(where: { $0.id == habitId }),
                  habit.kind == .numeric else {
                logger.log(
                    "🔗 Habit not found or not numeric",
                    level: .warning,
                    category: .system,
                    metadata: ["habitId": habitId.uuidString]
                )
                return
            }

            // Navigate to Overview tab first - regardless of current tab
            let navigationService = Container.shared.navigationService()
            navigationService.navigateToOverview(shouldRefresh: true)

            let overviewViewModel = Container.shared.overviewViewModel()

            // Navigate to the specific date first and wait for completion
            await navigateToDateInOverview(targetDate)

            // Set the habit as pending for progress sheet auto-opening
            // The sheet will open when OverviewView appears and calls processPendingNumericHabit()
            overviewViewModel.setPendingNumericHabit(habit)
        } catch {
            logger.log(
                "🔗 Error fetching habit for progress action",
                level: .warning,
                category: .system,
                metadata: ["habitId": habitId.uuidString, "error": error.localizedDescription]
            )
        }
    }
    
    /// Navigate to a specific date in the Overview
    /// Sets the overview to display the specific date and refreshes data
    @MainActor
    private func navigateToDateInOverview(_ targetDate: Date) async {
        let overviewViewModel = Container.shared.overviewViewModel()
        
        // Set the date first - normalize to local calendar's start of day
        overviewViewModel.viewingDate = CalendarUtils.startOfDayLocal(for: targetDate)
        
        // Wait for data loading to complete before proceeding
        await overviewViewModel.loadData()
    }
    
    /// Handle overview deep links from widget
    /// Simply navigates to the Overview tab
    private func handleOverviewDeepLink() {
        Task { @MainActor in
            navigationService.navigateToOverview(shouldRefresh: true)
        }
    }

    /// Sync with iCloud on app launch/resume (silent background sync)
    /// This method performs automatic synchronization with iCloud at key lifecycle points:
    /// - App launch: Ensures latest profile is loaded from cloud
    /// - App becomes active: Syncs changes made on other devices while this app was backgrounded
    ///
    /// Failures are handled gracefully and logged but do not block app functionality.
    /// Users can always manually sync from Settings if automatic sync fails.
    private func syncWithCloudIfAvailable() async {
        do {
            logger.log(
                "☁️ Auto-syncing with iCloud",
                level: .info,
                category: .system
            )
            try await syncWithiCloud.execute()

            // Update last sync timestamp so Settings UI shows correct "Last Synced" time
            await updateLastSyncDate.execute(Date())

            // Get iCloud status for logging
            let iCloudStatus = await checkiCloudStatus.execute()

            logger.log(
                "✅ Auto-sync completed successfully",
                level: .info,
                category: .system,
                metadata: [
                    "icloud_status": iCloudStatus.displayMessage,
                    "cloudkit_container": PersistenceContainer.cloudKitContainerIdentifier
                ]
            )
        } catch {
            // Silent failure - don't block app launch or disrupt user experience
            // User can manually sync from Settings if needed
            logger.log(
                "⚠️ Auto-sync failed (non-critical)",
                level: .warning,
                category: .system,
                metadata: ["error": error.localizedDescription]
            )
            userActionTracker.trackError(error, context: "icloud_auto_sync")
        }
    }
}

// MARK: - App Delegate

/// AppDelegate handles app launch scenarios including location-based relaunches
/// Also conforms to UIWindowSceneDelegate to handle Quick Actions in scene-based apps
/// UIApplicationDelegate methods run on the main thread, so we mark this @MainActor
@MainActor
class AppDelegate: NSObject, UIApplicationDelegate, UIWindowSceneDelegate {
    private let logger = DebugLogger(subsystem: "com.ritualist.app", category: "appDelegate")

    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        logger.log("AppDelegate didFinishLaunchingWithOptions", level: .info, category: .system)

        // LocalNotificationService sets itself as the UNUserNotificationCenter delegate
        // All notification handling (habit + personality) is done there

        // Handle geofence-triggered app launch
        if launchOptions?[.location] != nil {
            Container.shared.initializeForGeofenceLaunch()
        }

        // Register Quick Actions (Home Screen Shortcuts)
        QuickActionCoordinator.shared.registerQuickActions()

        return true
    }

    /// Configure scene to use this class as the scene delegate for Quick Action handling
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        logger.log(
            "Configuring scene session",
            level: .debug,
            category: .system,
            metadata: ["hasShortcutItem": options.shortcutItem != nil]
        )

        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = AppDelegate.self
        return config
    }

    // MARK: - UIWindowSceneDelegate (Quick Actions)

    /// Called when scene connects - check for pending shortcut from cold start
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        logger.log(
            "Scene willConnectTo",
            level: .info,
            category: .system,
            metadata: ["hasShortcutItem": connectionOptions.shortcutItem != nil]
        )

        // Handle Quick Action if app was launched from one (cold start)
        if let shortcutItem = connectionOptions.shortcutItem {
            logger.log(
                "App launched from Quick Action (cold start)",
                level: .info,
                category: .system,
                metadata: ["shortcutType": shortcutItem.type]
            )
            QuickActionCoordinator.shared.handleShortcutItem(shortcutItem)
        }
    }

    /// Handle Quick Action when app is already running (warm start)
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        logger.log(
            "Quick Action triggered (warm start via SceneDelegate)",
            level: .info,
            category: .system,
            metadata: ["shortcutType": shortcutItem.type]
        )
        let handled = QuickActionCoordinator.shared.handleShortcutItem(shortcutItem)
        // Process immediately since app is already running
        QuickActionCoordinator.shared.processPendingAction()
        completionHandler(handled)
    }
}

// MARK: - Container Launch Helpers

extension Container {
    /// Initialize services needed when app is launched due to a geofence event.
    ///
    /// CRITICAL: When the app is killed and user crosses a geofence boundary, iOS relaunches
    /// the app in the background. We must initialize the location service IMMEDIATELY so the
    /// CLLocationManager delegate is ready to receive pending location events before iOS delivers them.
    @MainActor
    func initializeForGeofenceLaunch() {
        let logger = debugLogger()
        logger.log(
            "🌍 App launched due to location event",
            level: .info,
            category: .location,
            metadata: ["launch_reason": "geofence_event"]
        )

        // Force immediate initialization of location monitoring service
        // This sets up the CLLocationManager delegate synchronously
        _ = locationMonitoringService()

        logger.log(
            "✅ Location service initialized for background geofence handling",
            level: .info,
            category: .location
        )
    }
}

// Separate view to properly observe AppearanceManager changes
struct RootAppView: View {
    var body: some View {
        RootTabView()
            // RootTabView now handles onboarding through Factory injection
    }
}
