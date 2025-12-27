//
//  PermissionCoordinator.swift
//  Ritualist
//
//  Centralized permission handling with post-grant actions.
//  Eliminates duplicate permission logic across ViewModels.
//
//  Note: Tracking is intentionally NOT handled here since each ViewModel
//  has specific tracking events (onboarding vs settings vs import).
//

import Foundation
import RitualistCore

/// Result of a notification permission request from the coordinator
public struct NotificationPermissionOutcome: Sendable {
    public let granted: Bool
    public let error: Error?

    public static func success(_ granted: Bool) -> NotificationPermissionOutcome {
        NotificationPermissionOutcome(granted: granted, error: nil)
    }

    public static func failure(_ error: Error) -> NotificationPermissionOutcome {
        NotificationPermissionOutcome(granted: false, error: error)
    }
}

/// Result of a location permission request from the coordinator
public struct LocationPermissionOutcome: Sendable {
    public let status: LocationAuthorizationStatus
    public let error: Error?

    /// Whether the app has any location permission (WhenInUse or Always)
    public var isAuthorized: Bool {
        status.hasAnyAuthorization
    }

    /// Whether the app can monitor geofences in the background
    public var canMonitorGeofences: Bool {
        status.canMonitorGeofences
    }

    public static func success(_ status: LocationAuthorizationStatus) -> LocationPermissionOutcome {
        LocationPermissionOutcome(status: status, error: nil)
    }

    public static func failure(_ error: Error, fallbackStatus: LocationAuthorizationStatus) -> LocationPermissionOutcome {
        LocationPermissionOutcome(status: fallbackStatus, error: error)
    }
}

/// Protocol for permission coordination
public protocol PermissionCoordinatorProtocol: Sendable {
    /// Request notification permission and schedule notifications if granted
    func requestNotificationPermission() async -> NotificationPermissionOutcome

    /// Request location permission and restore geofences if granted
    func requestLocationPermission(requestAlways: Bool) async -> LocationPermissionOutcome

    /// Check current notification permission status
    func checkNotificationStatus() async -> Bool

    /// Check current location permission status
    func checkLocationStatus() async -> LocationAuthorizationStatus

    /// Check both notification and location status in parallel
    func checkAllPermissions() async -> (notifications: Bool, location: LocationAuthorizationStatus)

    /// Schedule notifications for all habits (call after import or when permission changes)
    func scheduleAllNotifications() async throws

    /// Restore geofences for all habits (call after import or when permission changes)
    func restoreAllGeofences() async throws
}

/// Centralized coordinator for permission requests and post-grant actions
@MainActor
public final class PermissionCoordinator: PermissionCoordinatorProtocol {
    // MARK: - Dependencies

    private let requestNotificationPermissionUseCase: RequestNotificationPermissionUseCase
    private let checkNotificationStatusUseCase: CheckNotificationStatusUseCase
    private let requestLocationPermissionsUseCase: RequestLocationPermissionsUseCase
    private let getLocationAuthStatusUseCase: GetLocationAuthStatusUseCase
    private let dailyNotificationScheduler: DailyNotificationSchedulerService
    private let restoreGeofenceMonitoring: RestoreGeofenceMonitoringUseCase
    private let logger: DebugLogger

    // MARK: - Init

    public init(
        requestNotificationPermission: RequestNotificationPermissionUseCase,
        checkNotificationStatus: CheckNotificationStatusUseCase,
        requestLocationPermissions: RequestLocationPermissionsUseCase,
        getLocationAuthStatus: GetLocationAuthStatusUseCase,
        dailyNotificationScheduler: DailyNotificationSchedulerService,
        restoreGeofenceMonitoring: RestoreGeofenceMonitoringUseCase,
        logger: DebugLogger
    ) {
        self.requestNotificationPermissionUseCase = requestNotificationPermission
        self.checkNotificationStatusUseCase = checkNotificationStatus
        self.requestLocationPermissionsUseCase = requestLocationPermissions
        self.getLocationAuthStatusUseCase = getLocationAuthStatus
        self.dailyNotificationScheduler = dailyNotificationScheduler
        self.restoreGeofenceMonitoring = restoreGeofenceMonitoring
        self.logger = logger
    }

    // MARK: - Notification Permission

    public func requestNotificationPermission() async -> NotificationPermissionOutcome {
        do {
            let granted = try await requestNotificationPermissionUseCase.execute()

            if granted {
                logger.log(
                    "📅 Scheduling notifications after permission granted",
                    level: .info,
                    category: .notifications
                )
                try await dailyNotificationScheduler.rescheduleAllHabitNotifications()
            }

            return .success(granted)
        } catch {
            logger.log(
                "Failed to request notification permission",
                level: .error,
                category: .notifications,
                metadata: ["error": error.localizedDescription]
            )
            return .failure(error)
        }
    }

    public func checkNotificationStatus() async -> Bool {
        await checkNotificationStatusUseCase.execute()
    }

    public func scheduleAllNotifications() async throws {
        logger.log(
            "📅 Scheduling all habit notifications",
            level: .info,
            category: .notifications
        )
        try await dailyNotificationScheduler.rescheduleAllHabitNotifications()
    }

    // MARK: - Location Permission

    public func requestLocationPermission(requestAlways: Bool) async -> LocationPermissionOutcome {
        let result = await requestLocationPermissionsUseCase.execute(requestAlways: requestAlways)

        switch result {
        case .granted(let status):
            // Restore geofences if we have sufficient permission
            if status == .authorizedAlways || status == .authorizedWhenInUse {
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
                }
            }
            return .success(status)

        case .denied:
            return .success(.denied)

        case .failed(let error):
            let fallbackStatus = await getLocationAuthStatusUseCase.execute()
            return .failure(error, fallbackStatus: fallbackStatus)
        }
    }

    public func checkLocationStatus() async -> LocationAuthorizationStatus {
        await getLocationAuthStatusUseCase.execute()
    }

    public func checkAllPermissions() async -> (notifications: Bool, location: LocationAuthorizationStatus) {
        async let notificationStatus = checkNotificationStatusUseCase.execute()
        async let locationStatus = getLocationAuthStatusUseCase.execute()
        return await (notificationStatus, locationStatus)
    }

    public func restoreAllGeofences() async throws {
        logger.log(
            "🌍 Restoring all geofences",
            level: .info,
            category: .location
        )
        try await restoreGeofenceMonitoring.execute()
    }
}
