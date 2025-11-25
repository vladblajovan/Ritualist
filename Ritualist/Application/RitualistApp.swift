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

    /// Track if initial launch tasks have completed to avoid duplicate work
    @State private var hasCompletedInitialLaunch = false

    /// Track last geofence restoration time to throttle rapid sync events
    @State private var lastGeofenceRestorationTime: Date?

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
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onReceive(NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)) { _ in
                    // Handle background iCloud sync: iOS/CloudKit synced data to local store
                    // This covers the scenario where user sets up new device and iCloud syncs
                    // habit data with location configs while app is backgrounded or suspended.
                    // Geofences are device-local, so we must re-register them after sync.
                    //
                    // NOTE: We delay slightly to allow SwiftData to complete merging the remote
                    // changes into the view context. NSPersistentStoreRemoteChange fires when
                    // the persistent store receives changes, but the merge may still be in progress.
                    guard hasCompletedInitialLaunch else { return }
                    Task {
                        try? await Task.sleep(for: .milliseconds(500))
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
        let deviceModel = UIDevice.current.model
        let deviceName = UIDevice.current.name
        let systemVersion = UIDevice.current.systemVersion
        let systemName = UIDevice.current.systemName

        logger.log(
            "🚀 App starting",
            level: .info,
            category: .system,
            metadata: [
                "version": appVersion,
                "build": buildNumber,
                "device_model": deviceModel,
                "device_name": deviceName,
                "os": "\(systemName) \(systemVersion)",
                "schema_version": RitualistMigrationPlan.currentSchemaVersion.description,
                "cloudkit_container": PersistenceContainer.cloudKitContainerIdentifier
            ]
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

    private func setupNotifications() async {
        // Setup notification categories on app launch
        await notificationService.setupNotificationCategories()

        // Set up notification delegate - handled by LocalNotificationService
        // Removed: UNUserNotificationCenter.current().delegate = appDelegate
    }
    
    /// Schedule initial notifications on app launch
    private func scheduleInitialNotifications() async {
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
    private func rescheduleNotificationsIfNeeded() async {
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
            lastGeofenceRestorationTime = Date()
        } catch {
            logger.log(
                "⚠️ Failed to restore geofence monitoring",
                level: .warning,
                category: .system,
                metadata: ["error": error.localizedDescription]
            )
        }
    }

    /// Restore geofences with throttling to avoid excessive calls during rapid sync events
    /// CloudKit can fire multiple NSPersistentStoreRemoteChange notifications in quick succession
    private func restoreGeofencesThrottled() async {
        // Check if we've restored recently
        if let lastRestoration = lastGeofenceRestorationTime,
           Date().timeIntervalSince(lastRestoration) < geofenceRestorationThrottleInterval {
            logger.log(
                "⏭️ Skipping geofence restoration (throttled)",
                level: .debug,
                category: .system,
                metadata: ["lastRestoration": lastRestoration.ISO8601Format()]
            )
            return
        }

        logger.log(
            "☁️ iCloud remote change detected - restoring geofences",
            level: .info,
            category: .system
        )

        // Notify UI that iCloud synced data from another device
        NotificationCenter.default.post(name: .iCloudDidSyncRemoteChanges, object: nil)

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
        }
    }
}

// MARK: - App Delegate

/// AppDelegate handles app launch scenarios including location-based relaunches
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // LocalNotificationService sets itself as the UNUserNotificationCenter delegate
        // All notification handling (habit + personality) is done there

        // CRITICAL: Handle app launch due to geofence event
        // When app is killed and user crosses a geofence boundary, iOS relaunches
        // the app in the background. We must initialize the location service
        // IMMEDIATELY so the CLLocationManager delegate is ready to receive
        // pending location events before iOS delivers them.
        if launchOptions?[.location] != nil {
            let logger = Container.shared.debugLogger()
            logger.log(
                "🌍 App launched due to location event",
                level: .info,
                category: .location,
                metadata: ["launch_reason": "geofence_event"]
            )

            // Force immediate initialization of location monitoring service
            // This sets up the CLLocationManager delegate synchronously,
            // ensuring we're ready to receive the pending geofence event
            _ = Container.shared.locationMonitoringService()

            logger.log(
                "✅ Location service initialized for background geofence handling",
                level: .info,
                category: .location
            )
        }

        return true
    }
}

// Separate view to properly observe AppearanceManager changes
struct RootAppView: View {
    var body: some View {
        RootTabView()
            // RootTabView now handles onboarding through Factory injection
    }
}
