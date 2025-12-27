//
//  ICloudSyncCoordinator.swift
//  Ritualist
//
//  Extracted from RitualistApp.swift for SRP compliance
//

import Foundation
import CloudKit
import RitualistCore
import FactoryKit

/// Coordinates iCloud sync operations including deduplication and status caching
@MainActor
public final class ICloudSyncCoordinator {
    private let syncWithiCloud: SyncWithiCloudUseCase
    private let updateLastSyncDate: UpdateLastSyncDateUseCase
    private let checkiCloudStatus: CheckiCloudStatusUseCase
    private let deduplicateData: DeduplicateDataUseCase
    private let cloudKitCleanupService: CloudKitCleanupServiceProtocol
    private let userDefaults: UserDefaultsService
    private let profileCache: ProfileCache
    private let logger: DebugLogger
    private let userActionTracker: UserActionTrackerService

    // MARK: - iCloud Status Caching

    private var cachedICloudStatus: iCloudSyncStatus?
    private var lastICloudStatusCheckUptime: TimeInterval?
    private let iCloudStatusCacheInterval: TimeInterval = 10

    // MARK: - Deduplication State

    private var lastDeduplicationUptime: TimeInterval?
    private var lastDeduplicationHadData: Bool = false
    private var hasCompletedInitialSyncDedup: Bool = false
    private var isInitialDedupInProgress: Bool = false
    private var initialDedupAttemptCount: Int = 0
    private let deduplicationThrottleInterval: TimeInterval = 30
    private static let maxInitialDedupAttempts = 50

    // MARK: - UI Refresh Debouncing

    private var uiRefreshDebounceTask: Task<Void, Never>?

    public init(
        syncWithiCloud: SyncWithiCloudUseCase,
        updateLastSyncDate: UpdateLastSyncDateUseCase,
        checkiCloudStatus: CheckiCloudStatusUseCase,
        deduplicateData: DeduplicateDataUseCase,
        cloudKitCleanupService: CloudKitCleanupServiceProtocol,
        userDefaults: UserDefaultsService,
        profileCache: ProfileCache,
        logger: DebugLogger,
        userActionTracker: UserActionTrackerService
    ) {
        self.syncWithiCloud = syncWithiCloud
        self.updateLastSyncDate = updateLastSyncDate
        self.checkiCloudStatus = checkiCloudStatus
        self.deduplicateData = deduplicateData
        self.cloudKitCleanupService = cloudKitCleanupService
        self.userDefaults = userDefaults
        self.profileCache = profileCache
        self.logger = logger
        self.userActionTracker = userActionTracker
    }

    /// Invalidate iCloud status cache (called when user signs in/out)
    public func invalidateStatusCache() {
        cachedICloudStatus = nil
        lastICloudStatusCheckUptime = nil
    }

    /// Sync with iCloud on app launch/resume
    public func syncWithCloudIfAvailable() async {
        do {
            logger.log("☁️ Auto-syncing with iCloud", level: .info, category: .system)
            try await syncWithiCloud.execute()
            await updateLastSyncDate.execute(Date())

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
            logger.log(
                "⚠️ Auto-sync failed (non-critical)",
                level: .warning,
                category: .system,
                metadata: ["error": error.localizedDescription]
            )
            userActionTracker.trackError(error, context: "icloud_auto_sync")
        }
    }

    /// Handle remote change notification from CloudKit
    public func handleRemoteChange() async {
        await profileCache.invalidate()

        let iCloudStatus = await getCachedICloudStatus()
        if iCloudStatus == .available {
            userDefaults.set(Date(), forKey: UserDefaultsKeys.lastSyncDate)
        }

        try? await Task.sleep(for: .seconds(BusinessConstants.remoteChangeMergeDelay))

        postUIRefreshNotificationDebounced()

        if !hasCompletedInitialSyncDedup && initialDedupAttemptCount < Self.maxInitialDedupAttempts {
            await performInitialDeduplication()
        } else {
            await deduplicateSyncedDataThrottled()
        }
    }

    private func performInitialDeduplication() async {
        guard !isInitialDedupInProgress else {
            logger.log("⏭️ Skipping initial dedup - another operation in progress", level: .debug, category: .system)
            return
        }

        isInitialDedupInProgress = true
        initialDedupAttemptCount += 1

        let startTime = Date()
        let result = await deduplicateSyncedDataAndGetResult()
        let duration = Date().timeIntervalSince(startTime)

        isInitialDedupInProgress = false

        if duration > 0.5 {
            logger.log(
                "⏱️ Initial dedup took longer than expected",
                level: .warning,
                category: .system,
                metadata: ["duration_ms": Int(duration * 1000), "attempt": initialDedupAttemptCount, "items_checked": result.totalItemsChecked]
            )
        }

        if !result.hadDuplicates && result.hadDataToCheck {
            hasCompletedInitialSyncDedup = true
            logger.log(
                "✅ Initial sync deduplication complete - no duplicates found",
                level: .info,
                category: .system,
                metadata: ["total_attempts": initialDedupAttemptCount]
            )
        }

        if initialDedupAttemptCount >= Self.maxInitialDedupAttempts {
            hasCompletedInitialSyncDedup = true
            logger.log(
                "⚠️ Initial dedup hit max attempts, switching to throttled mode",
                level: .warning,
                category: .system,
                metadata: ["max_attempts": Self.maxInitialDedupAttempts]
            )
        }
    }

    /// One-time cleanup to remove PersonalityAnalysis records from CloudKit
    public func cleanupPersonalityAnalysisFromCloudKit() async {
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
            handleCloudKitCleanupError(error)
        }
    }

    // MARK: - Private Methods

    private func getCachedICloudStatus() async -> iCloudSyncStatus {
        let currentUptime = ProcessInfo.processInfo.systemUptime

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

    private func deduplicateSyncedDataAndGetResult() async -> DeduplicationResult {
        do {
            let result = try await deduplicateData.execute()
            lastDeduplicationUptime = ProcessInfo.processInfo.systemUptime
            lastDeduplicationHadData = result.hadDataToCheck

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
            return DeduplicationResult(
                habitsRemoved: 0,
                categoriesRemoved: 0,
                habitLogsRemoved: 0,
                profilesRemoved: 0,
                totalItemsChecked: 0
            )
        }
    }

    private func deduplicateSyncedDataThrottled() async {
        let currentUptime = ProcessInfo.processInfo.systemUptime
        if let lastUptime = lastDeduplicationUptime,
           (currentUptime - lastUptime) < deduplicationThrottleInterval {
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

    private func postUIRefreshNotificationDebounced() {
        uiRefreshDebounceTask?.cancel()

        uiRefreshDebounceTask = Task {
            do {
                try await Task.sleep(for: .seconds(BusinessConstants.uiRefreshDebounceInterval))
                guard !Task.isCancelled else { return }

                logger.log(
                    "📢 Posting UI refresh notification (debounced)",
                    level: .debug,
                    category: .system
                )
                NotificationCenter.default.post(name: .iCloudDidSyncRemoteChanges, object: nil)
            } catch {
                // Task was cancelled
            }
        }
    }

    private func handleCloudKitCleanupError(_ error: Error) {
        if case CloudKitCleanupError.partialFailure = error {
            logger.log(
                "⚠️ Partial CloudKit cleanup failure, will retry on next launch",
                level: .warning,
                category: .system,
                metadata: ["error": error.localizedDescription]
            )
        } else if let ckError = error as? CKError {
            switch ckError.code {
            case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited:
                logger.log(
                    "⚠️ CloudKit cleanup failed due to network/service, will retry",
                    level: .warning,
                    category: .system,
                    metadata: ["error_code": ckError.code.rawValue]
                )
            case .notAuthenticated, .permissionFailure, .managedAccountRestricted:
                markCloudKitCleanupComplete()
                logger.log(
                    "❌ CloudKit cleanup skipped due to auth/permission, marking complete",
                    level: .info,
                    category: .system,
                    metadata: ["error_code": ckError.code.rawValue]
                )
            default:
                logger.log(
                    "⚠️ CloudKit cleanup failed, will retry on next launch",
                    level: .warning,
                    category: .system,
                    metadata: ["error_code": ckError.code.rawValue, "error": ckError.localizedDescription]
                )
            }
        } else {
            logger.log(
                "⚠️ Failed to cleanup PersonalityAnalysis from CloudKit",
                level: .warning,
                category: .system,
                metadata: ["error": error.localizedDescription]
            )
        }
    }

    private func markCloudKitCleanupComplete() {
        userDefaults.set(true, forKey: "personalityAnalysisCloudKitCleanupCompleted")
    }
}
