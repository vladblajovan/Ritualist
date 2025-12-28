//
//  TimezoneChangeHandler.swift
//  Ritualist
//
//  Extracted from RitualistApp.swift for SRP compliance
//

import Foundation
import RitualistCore

/// Information about a detected timezone change for display in the alert dialog
public struct DetectedTimezoneChangeInfo {
    public let previousTimezone: String
    public let newTimezone: String

    public init(previousTimezone: String, newTimezone: String) {
        self.previousTimezone = previousTimezone
        self.newTimezone = newTimezone
    }

    /// Human-readable display name for the previous timezone
    public var previousTimezoneDisplayName: String {
        TimeZone(identifier: previousTimezone)?.localizedName(for: .standard, locale: .current) ?? previousTimezone
    }

    /// Human-readable display name for the new timezone
    public var newTimezoneDisplayName: String {
        TimeZone(identifier: newTimezone)?.localizedName(for: .standard, locale: .current) ?? newTimezone
    }
}

/// Handles timezone change detection and user preference updates
@MainActor
public final class TimezoneChangeHandler {
    private let timezoneService: TimezoneService
    private let dailyNotificationScheduler: DailyNotificationSchedulerService
    private let toastService: ToastServiceProtocol
    private let logger: DebugLogger

    /// Callback when timezone change is detected and alert should be shown
    public var onTimezoneChangeDetected: ((DetectedTimezoneChangeInfo) -> Void)?

    /// Task for timezone detection to prevent race conditions
    private var timezoneDetectionTask: Task<Void, Never>?

    public init(
        timezoneService: TimezoneService,
        dailyNotificationScheduler: DailyNotificationSchedulerService,
        toastService: ToastServiceProtocol,
        logger: DebugLogger
    ) {
        self.timezoneService = timezoneService
        self.dailyNotificationScheduler = dailyNotificationScheduler
        self.toastService = toastService
        self.logger = logger
    }

    /// Detect timezone changes on app launch/resume
    /// Uses task cancellation to prevent race conditions when called rapidly
    public func detectTimezoneChanges(showAlert: Bool = true) async {
        timezoneDetectionTask?.cancel()

        timezoneDetectionTask = Task { @MainActor in
            await performTimezoneDetection(showAlert: showAlert)
        }

        await timezoneDetectionTask?.value
    }

    /// Internal implementation of timezone detection logic
    private func performTimezoneDetection(showAlert: Bool) async {
        do {
            try Task.checkCancellation()

            guard let change = try await timezoneService.detectTimezoneChange() else {
                return
            }

            try await handleDetectedTimezoneChange(change, showAlert: showAlert)
        } catch is CancellationError {
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

    private func handleDetectedTimezoneChange(_ change: TimezoneChangeDetection, showAlert: Bool) async throws {
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

        try await timezoneService.updateCurrentTimezone()
        logger.log("✅ Updated current timezone", level: .info, category: .system, metadata: ["newTimezone": newTimezone])

        logger.log("📅 Rescheduling notifications after timezone change", level: .info, category: .notifications)
        try await dailyNotificationScheduler.rescheduleAllHabitNotifications()

        if showAlert {
            let changeInfo = DetectedTimezoneChangeInfo(previousTimezone: previousTimezone, newTimezone: newTimezone)
            onTimezoneChangeDetected?(changeInfo)
            logger.log(
                "📱 Showing timezone change alert to user",
                level: .info,
                category: .system,
                metadata: ["from": previousTimezone, "to": newTimezone]
            )
        }
    }

    /// Update display timezone mode to home
    public func keepHomeTimezone(currentLocation: String) async {
        do {
            try await timezoneService.updateDisplayTimezoneMode(.home)
            logger.log(
                "User chose to keep home timezone while traveling",
                level: .info,
                category: .system,
                metadata: ["currentLocation": currentLocation, "displayMode": "home"]
            )
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

    /// Update display timezone mode to current location
    public func useCurrentTimezone(newTimezone: String) async {
        do {
            try await timezoneService.updateDisplayTimezoneMode(.current)
            logger.log(
                "User switched to current location timezone",
                level: .info,
                category: .system,
                metadata: ["newTimezone": newTimezone, "displayMode": "current"]
            )
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

    /// Update home timezone after permanent move
    public func updateHomeTimezone(previousTimezone: String, newTimezone: String) async {
        do {
            guard let newTz = TimeZone(identifier: newTimezone) else { return }
            try await timezoneService.updateHomeTimezone(newTz)
            try await timezoneService.updateDisplayTimezoneMode(.home)
            logger.log(
                "User updated home timezone after permanent move",
                level: .info,
                category: .system,
                metadata: ["previousHome": previousTimezone, "newHome": newTimezone]
            )
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
