//
//  AppLifecycleCoordinator.swift
//  Ritualist
//
//  Extracted from RitualistApp.swift for SRP compliance
//

import Foundation
import UIKit
import RitualistCore

/// Coordinates app lifecycle events including launch tasks, notifications, and geofence restoration
@MainActor
public final class AppLifecycleCoordinator {
    // MARK: - Dependencies

    private let notificationService: NotificationService
    private let dailyNotificationScheduler: DailyNotificationSchedulerService
    private let restoreGeofenceMonitoring: RestoreGeofenceMonitoringUseCase
    private let seedPredefinedCategories: SeedPredefinedCategoriesUseCase
    private let iCloudSyncCoordinator: ICloudSyncCoordinator
    private let timezoneChangeHandler: TimezoneChangeHandler
    private let userService: UserService
    private let logger: DebugLogger
    private let userActionTracker: UserActionTrackerService

    // MARK: - State

    private var hasCompletedInitialLaunch = false
    private var lastGeofenceRestorationUptime: TimeInterval?
    private var lastNotificationRescheduleUptime: TimeInterval?
    private let appStartTime: Date

    // MARK: - Constants

    private let geofenceRestorationThrottleInterval: TimeInterval = 30
    private static let notificationRescheduleThrottleInterval: TimeInterval = 5.0

    public init(
        notificationService: NotificationService,
        dailyNotificationScheduler: DailyNotificationSchedulerService,
        restoreGeofenceMonitoring: RestoreGeofenceMonitoringUseCase,
        seedPredefinedCategories: SeedPredefinedCategoriesUseCase,
        iCloudSyncCoordinator: ICloudSyncCoordinator,
        timezoneChangeHandler: TimezoneChangeHandler,
        userService: UserService,
        logger: DebugLogger,
        userActionTracker: UserActionTrackerService,
        appStartTime: Date
    ) {
        self.notificationService = notificationService
        self.dailyNotificationScheduler = dailyNotificationScheduler
        self.restoreGeofenceMonitoring = restoreGeofenceMonitoring
        self.seedPredefinedCategories = seedPredefinedCategories
        self.iCloudSyncCoordinator = iCloudSyncCoordinator
        self.timezoneChangeHandler = timezoneChangeHandler
        self.userService = userService
        self.logger = logger
        self.userActionTracker = userActionTracker
        self.appStartTime = appStartTime
    }

    /// Whether initial launch tasks have completed
    public var initialLaunchCompleted: Bool {
        hasCompletedInitialLaunch
    }

    /// Perform all initial launch tasks
    public func performInitialLaunchTasks() async {
        logStartupContext()

        // PARALLEL: Run independent tasks concurrently
        async let premiumVerification: () = verifyAndUpdatePremiumStatus()
        async let categoriesSeeding: () = seedCategories()
        async let profileLoading: () = userService.loadProfileIfNeeded()
        async let timezoneDetection: () = timezoneChangeHandler.detectTimezoneChanges(showAlert: false)
        async let cloudKitCleanup: () = iCloudSyncCoordinator.cleanupPersonalityAnalysisFromCloudKit()

        _ = await (premiumVerification, categoriesSeeding, profileLoading, timezoneDetection, cloudKitCleanup)

        // SEQUENTIAL: Notification scheduling depends on categories
        await setupNotifications()
        await scheduleInitialNotifications()

        // SEQUENTIAL: Run after local setup is complete
        await restoreGeofences()
        await iCloudSyncCoordinator.syncWithCloudIfAvailable()

        hasCompletedInitialLaunch = true

        let startupDuration = Date().timeIntervalSince(appStartTime)
        logger.logPerformance(operation: "App startup", duration: startupDuration, metadata: [
            "tasks_completed": "seed_categories, timezone_detection, notifications_setup, geofence_restore, icloud_sync"
        ])
    }

    /// Handle app becoming active
    public func handleDidBecomeActive() async {
        guard hasCompletedInitialLaunch else { return }

        // Update badge to reflect actual delivered notification count
        await notificationService.updateBadgeCount()

        await timezoneChangeHandler.detectTimezoneChanges()
        await rescheduleNotificationsIfNeeded()
        await iCloudSyncCoordinator.syncWithCloudIfAvailable()
        await restoreGeofences()
    }

    /// Handle significant time change (midnight, daylight saving, etc.)
    public func handleSignificantTimeChange() async {
        guard hasCompletedInitialLaunch else { return }

        logger.log(
            "⏰ Significant time change detected - rescheduling notifications",
            level: .info,
            category: .notifications
        )
        await rescheduleNotificationsIfNeeded()
    }

    /// Handle remote change from CloudKit
    public func handleRemoteChange() async {
        guard hasCompletedInitialLaunch else { return }

        #if DEBUG
        ICloudSyncDiagnostics.shared.recordRemoteChange()
        #endif

        logger.log(
            "☁️ NSPersistentStoreRemoteChange received",
            level: .info,
            category: .system,
            metadata: ["timestamp": Date().ISO8601Format()]
        )

        await iCloudSyncCoordinator.handleRemoteChange()
        await restoreGeofencesThrottled()
    }

    /// Handle iCloud identity change (sign in/out)
    public func handleICloudIdentityChange() {
        iCloudSyncCoordinator.invalidateStatusCache()
    }

    // MARK: - Private Methods

    private func logStartupContext() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"

        var metadata: [String: Any] = [
            "version": appVersion,
            "build": buildNumber,
            "schema_version": RitualistMigrationPlan.currentSchemaVersion.description
        ]

        #if DEBUG
        metadata["device_model"] = UIDevice.current.model
        metadata["device_name"] = UIDevice.current.name
        metadata["os"] = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        metadata["cloudkit_container"] = iCloudConstants.containerIdentifier
        #endif

        logger.log("🚀 App starting", level: .info, category: .system, metadata: metadata)
    }

    private func verifyAndUpdatePremiumStatus() async {
        let cachedPremium = await SecurePremiumCache.shared.getCachedPremiumStatus()

        logger.log(
            "🔐 Verifying premium status (for feature gating)",
            level: .info,
            category: .system,
            metadata: ["cached_premium": cachedPremium]
        )

        // verifyPremiumAsync() already updates the cache internally with the full plan
        let actualPremium = await StoreKitSubscriptionService.verifyPremiumAsync()

        if actualPremium != cachedPremium {
            logger.log(
                "⚠️ Premium status changed",
                level: .info,
                category: .system,
                metadata: ["cached": cachedPremium, "actual": actualPremium]
            )
        } else {
            logger.log(
                "✅ Premium status verified",
                level: .debug,
                category: .system,
                metadata: ["is_premium": actualPremium]
            )
        }
    }

    private func seedCategories() async {
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
        await notificationService.setupNotificationCategories()
    }

    private func scheduleInitialNotifications() async {
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
            // Sync fired notification state from delivered notifications to prevent duplicates
            await notificationService.syncFiredNotificationsFromDelivered()

            logger.log("🚀 Scheduling initial notifications on app launch", level: .info, category: .system)
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

    private func rescheduleNotificationsIfNeeded() async {
        let isAuthorized = await notificationService.checkAuthorizationStatus()

        guard isAuthorized else {
            logger.log(
                "⏭️ Skipping notification re-scheduling - not authorized",
                level: .debug,
                category: .system
            )
            return
        }

        let currentUptime = ProcessInfo.processInfo.systemUptime
        if let lastReschedule = lastNotificationRescheduleUptime,
           currentUptime - lastReschedule < Self.notificationRescheduleThrottleInterval {
            logger.log(
                "⏭️ Skipping notification re-scheduling - throttled",
                level: .debug,
                category: .system
            )
            return
        }

        let startTime = Date()
        do {
            // Sync fired notification state from delivered notifications to prevent duplicates
            await notificationService.syncFiredNotificationsFromDelivered()

            logger.log("🔄 Re-scheduling notifications on app active", level: .info, category: .system)
            try await dailyNotificationScheduler.rescheduleAllHabitNotifications()
            lastNotificationRescheduleUptime = currentUptime

            let duration = Date().timeIntervalSince(startTime)
            if duration > 1.0 {
                logger.log(
                    "⏱️ Notification rescheduling took longer than expected",
                    level: .warning,
                    category: .notifications,
                    metadata: ["duration_ms": Int(duration * 1000)]
                )
            }
        } catch {
            logger.log(
                "⚠️ Failed to re-schedule notifications",
                level: .warning,
                category: .system,
                metadata: ["error": error.localizedDescription]
            )
        }
    }

    private func restoreGeofences() async {
        do {
            logger.log("🌍 Restoring geofence monitoring", level: .info, category: .system)
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

    private func restoreGeofencesThrottled() async {
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

        logger.log("☁️ iCloud remote change detected - restoring geofences", level: .info, category: .system)
        await restoreGeofences()
    }
}
