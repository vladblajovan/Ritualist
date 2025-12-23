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
import CloudKit
import TipKit

// swiftlint:disable type_body_length file_length
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
    @Injected(\.cloudKitCleanupService) private var cloudKitCleanupService
    @Injected(\.toastService) private var toastService
    @Injected(\.userDefaultsService) private var userDefaults
    @Injected(\.profileCache) private var profileCache

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

    /// Track whether initial sync deduplication has completed
    /// On first remote change, we run dedup immediately (not throttled) to catch duplicates
    /// created when cloud data merges with local data
    @State private var hasCompletedInitialSyncDedup: Bool = false

    /// Guard against concurrent initial sync dedup operations
    /// Prevents race condition when multiple remote change notifications fire rapidly
    ///
    /// THREAD SAFETY NOTE: This guard relies on SwiftUI's MainActor serialization.
    /// All @State mutations and reads happen on the main thread because:
    /// 1. The `Task { @MainActor in ... }` block in `.onReceive` forces main thread execution
    /// 2. SwiftUI @State properties are MainActor-isolated by default
    ///
    /// Without MainActor: Two tasks could both read `isInitialDedupInProgress = false` before
    /// either sets it to `true`, causing both to proceed. MainActor serializes these operations.
    ///
    /// If dedup logic moves off MainActor in future, consider:
    /// - Using an actor for atomic state management
    /// - Using `os_unfair_lock` for synchronization
    @State private var isInitialDedupInProgress: Bool = false

    /// Counter for initial sync dedup attempts (for diagnostics and safety limit)
    /// Prevents infinite dedup loops if duplicates keep appearing due to a bug
    @State private var initialDedupAttemptCount: Int = 0

    /// Maximum initial dedup attempts before switching to throttled mode
    /// This prevents infinite CPU usage if something is continuously creating duplicates
    private static let maxInitialDedupAttempts = 50

    /// Cached iCloud status to avoid repeated CloudKit API calls during bulk sync
    @State private var cachedICloudStatus: iCloudSyncStatus?

    /// Track when iCloud status was last checked (using system uptime for clock-drift immunity)
    @State private var lastICloudStatusCheckUptime: TimeInterval?

    /// Debounce task for UI refresh notification
    /// Cancels previous pending notification when new changes arrive, ensuring ONE refresh after activity settles
    @State private var uiRefreshDebounceTask: Task<Void, Never>?

    // MARK: - Timezone Change Alert State

    /// Whether to show the timezone change alert dialog
    @State private var showTimezoneChangeAlert = false

    /// Details about the detected timezone change for the alert
    @State private var detectedTimezoneChange: DetectedTimezoneChangeInfo?

    /// Task for timezone detection to prevent race conditions from rapid calls
    /// Cancels previous detection if a new one starts before completion
    @State private var timezoneDetectionTask: Task<Void, Never>?

    /// Track last notification rescheduling time (using system uptime for clock-drift immunity)
    /// Prevents duplicate rescheduling when both significantTimeChange and timezone detection fire together
    @State private var lastNotificationRescheduleUptime: TimeInterval?

    /// Minimum interval between notification reschedulings (5 seconds)
    /// This debounces rapid-fire events like midnight + timezone change
    private static let notificationRescheduleThrottleInterval: TimeInterval = 5.0

    /// App startup time for performance monitoring
    private let appStartTime = Date()

    init() {
        // Check if tips should be reset (set from Debug Menu)
        // Note: Using DefaultUserDefaultsService directly here since @Injected is not available during init
        let initUserDefaults = DefaultUserDefaultsService()
        if initUserDefaults.bool(forKey: "shouldResetTipsOnNextLaunch") {
            // Clear flag BEFORE reset attempt to prevent crash loops
            // If resetDatastore() crashes, we don't want to retry on every launch
            initUserDefaults.set(false, forKey: "shouldResetTipsOnNextLaunch")
            do {
                try Tips.resetDatastore()
                logger.log("TipKit datastore reset successfully", level: .debug, category: .system)
            } catch {
                logger.log("TipKit datastore reset failed: \(error.localizedDescription)", level: .error, category: .system)
            }
        }

        // Configure TipKit
        do {
            try Tips.configure([
                .displayFrequency(.immediate)
            ])
            logger.log("TipKit configured successfully", level: .debug, category: .system)
        } catch {
            logger.log("TipKit configuration failed: \(error.localizedDescription)", level: .error, category: .system)
        }
    }

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

    /// Minimum interval between iCloud status checks (in seconds).
    ///
    /// CloudKit can fire multiple NSPersistentStoreRemoteChange notifications in quick succession.
    /// Each notification handler needs to check iCloud status before updating lastSyncDate.
    /// Caching the status avoids redundant CloudKit API calls during bulk sync.
    private let iCloudStatusCacheInterval: TimeInterval = 10

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

                    // Record remote change for diagnostics
                    #if DEBUG
                    Task { @MainActor in
                        ICloudSyncDiagnostics.shared.recordRemoteChange()
                    }
                    #endif

                    logger.log(
                        "☁️ NSPersistentStoreRemoteChange received",
                        level: .info,
                        category: .system,
                        metadata: ["timestamp": Date().ISO8601Format()]
                    )

                    // @MainActor ensures thread-safe access to @State properties and
                    // serializes all debounce/throttle operations despite background notification origin
                    Task { @MainActor in
                        // Invalidate profile cache to pick up any profile changes from other devices
                        // This ensures the next profile read fetches fresh data from the database
                        await profileCache.invalidate()

                        // Only update last sync timestamp if iCloud is actually available
                        // This prevents stale "Last Synced" times when user isn't signed in
                        // Uses cached status to avoid redundant CloudKit API calls during bulk sync
                        let iCloudStatus = await getCachedICloudStatus()
                        if iCloudStatus == .available {
                            userDefaults.set(Date(), forKey: UserDefaultsKeys.lastSyncDate)
                        }

                        try? await Task.sleep(for: .seconds(BusinessConstants.remoteChangeMergeDelay))

                        // Debounce UI refresh notification to prevent rapid flashing when multiple changes arrive
                        // (e.g., user editing profile fields, bulk sync from another device)
                        postUIRefreshNotificationDebounced()

                        // Deduplicate any duplicates created by CloudKit sync before restoring geofences
                        // During initial sync: run dedup on EVERY change (not throttled) until no duplicates found
                        // This ensures we catch all duplicates as data arrives in batches
                        // Once dedup finds zero duplicates, sync is effectively "complete" and we switch to throttling
                        //
                        // Note on fresh installs with no CloudKit data:
                        // - hasCompletedInitialSyncDedup stays false since no data arrives
                        // - This is intentional: fresh users don't need dedup, and the flag only affects
                        //   whether dedup is throttled (not whether it runs at all)
                        // - Once user creates first habit, subsequent notifications will set hadDataToCheck=true
                        if !hasCompletedInitialSyncDedup && initialDedupAttemptCount < Self.maxInitialDedupAttempts {
                            // Guard against concurrent initial dedup operations
                            // If another dedup is already running, skip this one
                            // Note: Early return is safe - the running operation will reset isInitialDedupInProgress
                            // when it completes, and dedup is idempotent so skipping is harmless
                            guard !isInitialDedupInProgress else {
                                logger.log(
                                    "⏭️ Skipping initial dedup - another operation in progress",
                                    level: .debug,
                                    category: .system
                                )
                                return
                            }

                            isInitialDedupInProgress = true
                            initialDedupAttemptCount += 1

                            let startTime = Date()
                            let result = await deduplicateSyncedDataAndGetResult()
                            let duration = Date().timeIntervalSince(startTime)

                            isInitialDedupInProgress = false

                            // Log duration for performance monitoring
                            if duration > 0.5 {
                                logger.log(
                                    "⏱️ Initial dedup took longer than expected",
                                    level: .warning,
                                    category: .system,
                                    metadata: [
                                        "duration_ms": Int(duration * 1000),
                                        "attempt": initialDedupAttemptCount,
                                        "items_checked": result.totalItemsChecked
                                    ]
                                )
                            }

                            if !result.hadDuplicates && result.hadDataToCheck {
                                // No duplicates found and we had data to check = sync settled
                                hasCompletedInitialSyncDedup = true
                                logger.log(
                                    "✅ Initial sync deduplication complete - no duplicates found",
                                    level: .info,
                                    category: .system,
                                    metadata: ["total_attempts": initialDedupAttemptCount]
                                )
                            }

                            // Safety check: if we hit max attempts, switch to throttled mode
                            if initialDedupAttemptCount >= Self.maxInitialDedupAttempts {
                                hasCompletedInitialSyncDedup = true
                                logger.log(
                                    "⚠️ Initial dedup hit max attempts, switching to throttled mode",
                                    level: .warning,
                                    category: .system,
                                    metadata: ["max_attempts": Self.maxInitialDedupAttempts]
                                )
                            }
                        } else {
                            await deduplicateSyncedDataThrottled()
                        }
                        await restoreGeofencesThrottled()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.NSUbiquityIdentityDidChange)) { _ in
                    // Invalidate iCloud status cache when user signs in/out of iCloud
                    Task { @MainActor in
                        cachedICloudStatus = nil
                        lastICloudStatusCheckUptime = nil
                    }
                }
                // MARK: - Timezone Change Alert
                .alert(
                    "Timezone Changed",
                    isPresented: $showTimezoneChangeAlert,
                    presenting: detectedTimezoneChange
                ) { change in
                    // Option 1: Keep using home timezone (good for short trips)
                    Button("Keep Home Timezone") {
                        // User wants to keep using their home timezone for display
                        // This is useful for short trips where they want consistency
                        Task { @MainActor in
                            do {
                                try await timezoneService.updateDisplayTimezoneMode(.home)
                                logger.log(
                                    "User chose to keep home timezone while traveling",
                                    level: .info,
                                    category: .system,
                                    metadata: [
                                        "currentLocation": change.newTimezone,
                                        "displayMode": "home"
                                    ]
                                )
                                // Trigger UI refresh so ViewModels reload with new timezone
                                NotificationCenter.default.post(name: .iCloudDidSyncRemoteChanges, object: nil)
                            } catch {
                                logger.log(
                                    "Failed to update display timezone mode",
                                    level: .error,
                                    category: .system,
                                    metadata: ["error": error.localizedDescription]
                                )
                                toastService.error("Failed to update timezone: \(error.localizedDescription)")
                            }
                        }
                    }

                    // Option 2: Use current location timezone (good for longer stays)
                    Button("Use Current Timezone") {
                        // User wants to use their current location's timezone
                        // This switches display mode to .current
                        Task { @MainActor in
                            do {
                                try await timezoneService.updateDisplayTimezoneMode(.current)
                                logger.log(
                                    "User switched to current location timezone",
                                    level: .info,
                                    category: .system,
                                    metadata: [
                                        "newTimezone": change.newTimezone,
                                        "displayMode": "current"
                                    ]
                                )
                                // Trigger UI refresh so ViewModels reload with new timezone
                                NotificationCenter.default.post(name: .iCloudDidSyncRemoteChanges, object: nil)
                            } catch {
                                logger.log(
                                    "Failed to update display timezone mode",
                                    level: .error,
                                    category: .system,
                                    metadata: ["error": error.localizedDescription]
                                )
                                toastService.error("Failed to update timezone: \(error.localizedDescription)")
                            }
                        }
                    }

                    // Option 3: Update home timezone (user moved permanently)
                    Button("I Moved Here") {
                        // User moved permanently - update home timezone to match current location
                        Task { @MainActor in
                            do {
                                guard let newTz = TimeZone(identifier: change.newTimezone) else { return }
                                try await timezoneService.updateHomeTimezone(newTz)
                                // Also switch to home mode so display uses the new home timezone
                                try await timezoneService.updateDisplayTimezoneMode(.home)
                                logger.log(
                                    "User updated home timezone after permanent move",
                                    level: .info,
                                    category: .system,
                                    metadata: [
                                        "previousHome": change.previousTimezone,
                                        "newHome": change.newTimezone
                                    ]
                                )
                                // Trigger UI refresh so ViewModels reload with new timezone
                                NotificationCenter.default.post(name: .iCloudDidSyncRemoteChanges, object: nil)
                            } catch {
                                logger.log(
                                    "Failed to update home timezone",
                                    level: .error,
                                    category: .system,
                                    metadata: ["error": error.localizedDescription]
                                )
                                toastService.error("Failed to update timezone: \(error.localizedDescription)")
                            }
                        }
                    }
                } message: { change in
                    Text("You're now in \(change.newTimezoneDisplayName).\n\nHow would you like to track your habits?")
                }
        }
    }

    /// Perform all initial launch tasks and log startup metrics
    private func performInitialLaunchTasks() async {
        // Log startup context
        logStartupContext()

        // PARALLEL EXECUTION: Run independent tasks concurrently for faster startup
        // These tasks have no dependencies on each other
        async let premiumVerification: () = verifyAndUpdatePremiumStatus()
        async let categoriesSeeding: () = seedCategories()
        async let timezoneDetection: () = detectTimezoneChanges()
        // REMOVAL NOTICE: cleanupPersonalityAnalysisFromCloudKit() can be removed after v2.5.0 (March 2025)
        async let cloudKitCleanup: () = cleanupPersonalityAnalysisFromCloudKit()

        // Wait for all parallel tasks to complete
        _ = await (premiumVerification, categoriesSeeding, timezoneDetection, cloudKitCleanup)

        // NOTE: Deduplication is NOT run here on purpose.
        // We wait for NSPersistentStoreRemoteChange notifications to indicate CloudKit sync activity.
        // Dedup runs on each remote change until no duplicates are found, ensuring we catch all
        // duplicates as data arrives in batches from iCloud. See remote change handler for details.
        //
        // EDGE CASE: Offline users or users with iCloud disabled
        // - If user is never online after update: duplicates would not be cleaned up
        // - If CloudKit sync is disabled: no remote change notifications fire
        // - ACCEPTABLE RISK: Duplicates can only be created BY CloudKit sync merging
        //   remote data with local data. Without CloudKit sync, no duplicates are created.
        // - When user goes online later, sync will trigger dedup as expected.

        // SEQUENTIAL: Notification scheduling depends on categories being set up first
        await setupNotifications()
        await scheduleInitialNotifications()

        // SEQUENTIAL: These should run after local setup is complete
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
        metadata["cloudkit_container"] = iCloudConstants.containerIdentifier
        #endif

        logger.log(
            "🚀 App starting",
            level: .info,
            category: .system,
            metadata: metadata
        )
    }

    /// Verify the cached premium status against StoreKit and update if needed.
    ///
    /// Verify premium status for feature gating (habit limits, analytics, etc.)
    ///
    /// Note: This is no longer needed for iCloud sync (which is now free for all users).
    /// It's kept for premium feature gating only.
    private func verifyAndUpdatePremiumStatus() async {
        let cachedPremium = SecurePremiumCache.shared.getCachedPremiumStatus()

        logger.log(
            "🔐 Verifying premium status (for feature gating)",
            level: .info,
            category: .system,
            metadata: ["cached_premium": cachedPremium]
        )

        // Query StoreKit for actual premium status
        let actualPremium = await StoreKitSubscriptionService.verifyPremiumAsync()

        // Always update cache with fresh value from StoreKit
        SecurePremiumCache.shared.updateCache(isPremium: actualPremium)

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

    /// One-time cleanup to remove PersonalityAnalysis records from CloudKit
    /// This is needed after moving PersonalityAnalysisModel to local-only storage
    /// REMOVAL NOTICE: This method can be removed after v2.5.0 (target: March 2025)
    private func cleanupPersonalityAnalysisFromCloudKit() async {
        do {
            if let deletedCount = try await cloudKitCleanupService.cleanupPersonalityAnalysisFromCloudKit() {
                logger.log(
                    "🧹 CloudKit PersonalityAnalysis cleanup completed",
                    level: .info,
                    category: .system,
                    metadata: ["records_deleted": deletedCount]
                )
            }
        } catch {
            // Distinguish between retryable and non-retryable errors
            // to avoid making unnecessary CloudKit API calls forever
            if case CloudKitCleanupError.partialFailure = error {
                // Retryable - some records failed to delete, will retry next launch
                logger.log(
                    "⚠️ Partial CloudKit cleanup failure, will retry on next launch",
                    level: .warning,
                    category: .system,
                    metadata: ["error": error.localizedDescription]
                )
            } else if let ckError = error as? CKError {
                switch ckError.code {
                case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited:
                    // Retryable network/service errors
                    logger.log(
                        "⚠️ CloudKit cleanup failed due to network/service, will retry",
                        level: .warning,
                        category: .system,
                        metadata: ["error_code": ckError.code.rawValue]
                    )
                case .notAuthenticated, .permissionFailure, .managedAccountRestricted:
                    // Non-retryable auth/permission errors - mark as complete to stop trying
                    // User either doesn't have iCloud or has restrictions that won't change
                    markCloudKitCleanupComplete()
                    logger.log(
                        "❌ CloudKit cleanup skipped due to auth/permission, marking complete",
                        level: .info,
                        category: .system,
                        metadata: ["error_code": ckError.code.rawValue]
                    )
                default:
                    // Other CloudKit errors - log and retry
                    logger.log(
                        "⚠️ CloudKit cleanup failed, will retry on next launch",
                        level: .warning,
                        category: .system,
                        metadata: ["error_code": ckError.code.rawValue, "error": ckError.localizedDescription]
                    )
                }
            } else {
                // Unknown error - log and retry
                logger.log(
                    "⚠️ Failed to cleanup PersonalityAnalysis from CloudKit",
                    level: .warning,
                    category: .system,
                    metadata: ["error": error.localizedDescription]
                )
            }
        }
    }

    /// Mark CloudKit cleanup as complete (used when cleanup should not be retried)
    private func markCloudKitCleanupComplete() {
        userDefaults.set(true, forKey: "personalityAnalysisCloudKitCleanupCompleted")
    }

    /// Deduplicate and return the result for callers that need to check if duplicates were found
    /// Used during initial sync to determine when sync has "settled" (no more duplicates arriving)
    private func deduplicateSyncedDataAndGetResult() async -> DeduplicationResult {
        do {
            let result = try await deduplicateData.execute()
            lastDeduplicationUptime = ProcessInfo.processInfo.systemUptime
            lastDeduplicationHadData = result.hadDataToCheck

            // Record for diagnostics
            #if DEBUG
            Task { @MainActor in
                ICloudSyncDiagnostics.shared.recordDeduplication(
                    habitsRemoved: result.habitsRemoved,
                    categoriesRemoved: result.categoriesRemoved,
                    logsRemoved: result.habitLogsRemoved,
                    profilesRemoved: result.profilesRemoved
                )
            }
            #endif

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

            return result
        } catch {
            logger.log(
                "⚠️ Failed to deduplicate synced data",
                level: .warning,
                category: .system,
                metadata: ["error": error.localizedDescription]
            )
            // Return empty result on error - don't mark initial sync as complete
            return DeduplicationResult(
                habitsRemoved: 0,
                categoriesRemoved: 0,
                habitLogsRemoved: 0,
                profilesRemoved: 0,
                totalItemsChecked: 0
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

        _ = await deduplicateSyncedDataAndGetResult()
    }

    /// Post UI refresh notification with debouncing to prevent rapid flashing
    ///
    /// When multiple iCloud changes arrive in quick succession (e.g., user editing profile fields,
    /// bulk sync from another device), this ensures ONE UI refresh after activity settles.
    /// Each call cancels any pending notification and starts a new timer.
    @MainActor
    private func postUIRefreshNotificationDebounced() {
        // Cancel any pending notification
        uiRefreshDebounceTask?.cancel()

        // Start new debounce timer
        uiRefreshDebounceTask = Task {
            do {
                try await Task.sleep(for: .seconds(BusinessConstants.uiRefreshDebounceInterval))

                // Only post if not cancelled
                guard !Task.isCancelled else { return }

                logger.log(
                    "📢 Posting UI refresh notification (debounced)",
                    level: .debug,
                    category: .system
                )
                NotificationCenter.default.post(name: .iCloudDidSyncRemoteChanges, object: nil)
            } catch {
                // Task was cancelled - another change arrived, skip this notification
            }
        }
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
    /// Includes throttling to prevent duplicate rescheduling when multiple events fire together
    /// (e.g., significantTimeChange and timezone detection at midnight).
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

        // Throttle to prevent duplicate rescheduling when multiple events fire together
        let currentUptime = ProcessInfo.processInfo.systemUptime
        if let lastReschedule = lastNotificationRescheduleUptime,
           currentUptime - lastReschedule < Self.notificationRescheduleThrottleInterval {
            logger.log(
                "⏭️ Skipping notification re-scheduling - throttled (rescheduled \(String(format: "%.1f", currentUptime - lastReschedule))s ago)",
                level: .debug,
                category: .system
            )
            return
        }

        let startTime = Date()
        do {
            logger.log(
                "🔄 Re-scheduling notifications on app active",
                level: .info,
                category: .system
            )
            try await dailyNotificationScheduler.rescheduleAllHabitNotifications()
            lastNotificationRescheduleUptime = currentUptime

            // Log timing for performance monitoring
            let duration = Date().timeIntervalSince(startTime)
            if duration > 1.0 {
                logger.log(
                    "⏱️ Notification rescheduling took longer than expected",
                    level: .warning,
                    category: .notifications,
                    metadata: ["duration_ms": Int(duration * 1000)]
                )
            } else {
                logger.log(
                    "✅ Notification rescheduling completed",
                    level: .debug,
                    category: .notifications,
                    metadata: ["duration_ms": Int(duration * 1000)]
                )
            }
        } catch {
            logger.log(
                "⚠️ Failed to re-schedule notifications",
                level: .warning,
                category: .system,
                metadata: [
                    "error": error.localizedDescription,
                    "duration_ms": Int(Date().timeIntervalSince(startTime) * 1000)
                ]
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

    /// Get iCloud status with caching to avoid redundant CloudKit API calls during bulk sync
    /// CloudKit can fire 16+ NSPersistentStoreRemoteChange notifications in quick succession.
    /// Each handler needs to check iCloud status, but calling CloudKit repeatedly is wasteful.
    /// This caches the status for a short duration (10 seconds) during bulk sync operations.
    ///
    /// - Note: Must be @MainActor to safely access @State properties (cachedICloudStatus, lastICloudStatusCheckUptime)
    ///   which are MainActor-isolated. Called from Task blocks in .onReceive handlers that may originate from
    ///   background threads (NSPersistentStoreRemoteChange notifications).
    @MainActor
    private func getCachedICloudStatus() async -> iCloudSyncStatus {
        let currentUptime = ProcessInfo.processInfo.systemUptime

        // Return cached status if it's still fresh
        if let cachedStatus = cachedICloudStatus,
           let lastCheckUptime = lastICloudStatusCheckUptime,
           (currentUptime - lastCheckUptime) < iCloudStatusCacheInterval {
            logger.log(
                "☁️ Using cached iCloud status",
                level: .debug,
                category: .system,
                metadata: [
                    "status": cachedStatus.displayMessage,
                    "cacheAge": String(format: "%.1fs", currentUptime - lastCheckUptime)
                ]
            )
            return cachedStatus
        }

        // Fetch fresh status and cache it
        let freshStatus = await checkiCloudStatus.execute()
        cachedICloudStatus = freshStatus
        lastICloudStatusCheckUptime = currentUptime

        logger.log(
            "☁️ Fetched fresh iCloud status",
            level: .debug,
            category: .system,
            metadata: ["status": freshStatus.displayMessage]
        )

        return freshStatus
    }

    /// Detect timezone changes on app launch/resume
    /// Updates stored current timezone if device timezone changed
    /// This is part of the three-timezone model for proper travel handling
    ///
    /// Uses task cancellation to prevent race conditions when called rapidly
    /// (e.g., multiple foreground transitions in quick succession)
    private func detectTimezoneChanges() async {
        // Cancel any existing detection task to prevent race conditions
        timezoneDetectionTask?.cancel()

        timezoneDetectionTask = Task { @MainActor in
            await performTimezoneDetection()
        }

        // Wait for the task to complete
        await timezoneDetectionTask?.value
    }

    /// Internal implementation of timezone detection logic
    private func performTimezoneDetection() async {
        do {
            // Check for cancellation early
            try Task.checkCancellation()

            // Use TimezoneService.detectTimezoneChange() which compares device timezone
            // against the STORED currentTimezoneIdentifier in UserProfile (not TimeZone.current)
            guard let change = try await timezoneService.detectTimezoneChange() else {
                // No timezone change detected
                return
            }

            let previousTimezone = change.previousTimezone
            let newTimezone = change.newTimezone

            logger.log(
                "🌐 Timezone change detected",
                level: .info,
                category: .system,
                metadata: [
                    "previousTimezone": previousTimezone,
                    "newTimezone": newTimezone,
                    "detectedAt": Date().ISO8601Format()
                ]
            )

            // Update stored current timezone with the new device timezone
            try await timezoneService.updateCurrentTimezone()

            logger.log(
                "✅ Updated current timezone",
                level: .info,
                category: .system,
                metadata: ["newTimezone": newTimezone]
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

            // Show timezone change alert to user
            // Only show if app is in foreground (hasCompletedInitialLaunch is true)
            // This prevents the alert from showing during initial app launch when timezone is first detected
            // Also check if alert is not already showing to prevent race conditions with rapid timezone changes
            if hasCompletedInitialLaunch && !showTimezoneChangeAlert {
                await MainActor.run {
                    detectedTimezoneChange = DetectedTimezoneChangeInfo(
                        previousTimezone: previousTimezone,
                        newTimezone: newTimezone
                    )
                    showTimezoneChangeAlert = true
                }

                logger.log(
                    "📱 Showing timezone change alert to user",
                    level: .info,
                    category: .system,
                    metadata: [
                        "from": previousTimezone,
                        "to": newTimezone
                    ]
                )
            }
        } catch is CancellationError {
            // Task was cancelled (superseded by a newer detection), silently ignore
            logger.log(
                "Timezone detection cancelled (superseded by newer detection)",
                level: .debug,
                category: .system
            )
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

        // Load data first to ensure displayTimezone is correctly set from user preferences
        // This prevents the viewingDate from being calculated with the wrong timezone
        await overviewViewModel.loadData()

        // Now set the target date using the correctly loaded displayTimezone
        // This must happen AFTER loadData() because loadData() resets viewingDate to today on first load
        overviewViewModel.viewingDate = CalendarUtils.startOfDayLocal(for: targetDate, timezone: overviewViewModel.displayTimezone)
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
    /// iCloud sync is free for all users.
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

            // Get iCloud account status for logging
            // Note: This is the user's iCloud account status, not our app's sync configuration
            let iCloudAccountStatus = await checkiCloudStatus.execute()

            logger.log(
                "✅ Auto-sync completed successfully",
                level: .info,
                category: .system,
                metadata: [
                    "icloud_account": iCloudAccountStatus.displayMessage,
                    "cloudkit_container": iCloudConstants.containerIdentifier
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
    // Local logger: AppDelegate runs before DI container is initialized
    private let logger = DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "appDelegate")

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
        Container.shared.quickActionCoordinator().registerQuickActions()

        // Register for remote notifications (required for CloudKit sync)
        // CloudKit uses silent push notifications to notify devices of remote changes
        application.registerForRemoteNotifications()

        return true
    }

    /// Called when the app successfully registers for remote notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        logger.log(
            "✅ Registered for remote notifications",
            level: .info,
            category: .system,
            metadata: ["tokenPrefix": String(tokenString.prefix(16)) + "..."]
        )

        #if DEBUG
        ICloudSyncDiagnostics.shared.recordRemoteNotificationRegistration(success: true)
        #endif
    }

    /// Called when remote notification registration fails
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger.log(
            "❌ Failed to register for remote notifications",
            level: .error,
            category: .system,
            metadata: ["error": error.localizedDescription]
        )

        #if DEBUG
        ICloudSyncDiagnostics.shared.recordRemoteNotificationRegistration(success: false)
        #endif
    }

    /// Handle silent push notifications from CloudKit
    /// CloudKit sends these when data changes on another device to trigger sync
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        logger.log(
            "☁️ Received remote notification (CloudKit sync trigger)",
            level: .info,
            category: .system,
            metadata: ["userInfo": String(describing: userInfo)]
        )

        // CloudKit notifications contain "ck" key
        if userInfo["ck"] != nil {
            logger.log(
                "☁️ CloudKit remote change notification received",
                level: .info,
                category: .system
            )

            #if DEBUG
            ICloudSyncDiagnostics.shared.recordPushNotification()
            #endif

            // The NSPersistentStoreRemoteChange notification will fire automatically
            // when the persistent store processes the incoming changes.
            // We just need to give the system time to process.
            //
            // Note: The actual sync handling is done in RitualistApp's .onReceive handler
            // for NSPersistentStoreRemoteChange - this method just acknowledges the push.

            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
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
            Container.shared.quickActionCoordinator().handleShortcutItem(shortcutItem)
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
        let coordinator = Container.shared.quickActionCoordinator()
        let handled = coordinator.handleShortcutItem(shortcutItem)
        // Don't process here - let RootTabView handle it via onChange observers
        // Processing here would set flags before SwiftUI observers are ready
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

// MARK: - Timezone Change Info

/// Information about a detected timezone change for display in the alert dialog
struct DetectedTimezoneChangeInfo {
    let previousTimezone: String
    let newTimezone: String

    /// Human-readable display name for the previous timezone (e.g., "Eastern Standard Time")
    var previousTimezoneDisplayName: String {
        TimeZone(identifier: previousTimezone)?.localizedName(for: .standard, locale: .current) ?? previousTimezone
    }

    /// Human-readable display name for the new timezone (e.g., "Pacific Standard Time")
    var newTimezoneDisplayName: String {
        TimeZone(identifier: newTimezone)?.localizedName(for: .standard, locale: .current) ?? newTimezone
    }
}
