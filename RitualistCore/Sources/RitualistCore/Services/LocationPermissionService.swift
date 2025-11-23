//
//  LocationPermissionService.swift
//  RitualistCore
//
//  Created by Claude on 03.11.2025.
//
//  Service for requesting and managing location permissions.
//  Handles the two-step permission flow: "When In Use" → "Always".
//

import Foundation
import CoreLocation
#if canImport(UIKit)
import UIKit
#endif

/// Result of a permission request
public enum LocationPermissionResult {
    /// Permission granted
    case granted(LocationAuthorizationStatus)

    /// Permission denied by user
    case denied

    /// Permission request failed
    case failed(LocationError)
}

/// Protocol for location permission operations
public protocol LocationPermissionService {
    /// Request "When In Use" location permission
    func requestWhenInUsePermission() async -> LocationPermissionResult

    /// Request "Always" location permission (for background monitoring)
    func requestAlwaysPermission() async -> LocationPermissionResult

    /// Check current authorization status
    func getAuthorizationStatus() async -> LocationAuthorizationStatus

    /// Check if location services are enabled on the device
    func areLocationServicesEnabled() async -> Bool

    /// Open app settings for user to manually grant permission
    func openAppSettings() async
}

/// Implementation of LocationPermissionService
@MainActor
public final class DefaultLocationPermissionService: NSObject, LocationPermissionService {
    // MARK: - Properties

    private let locationManager: CLLocationManager
    private var permissionContinuations: [UUID: CheckedContinuation<CLAuthorizationStatus, Never>] = [:]

    // MARK: - Initialization

    public override init() {
        self.locationManager = CLLocationManager()
        super.init()
        self.locationManager.delegate = self
    }

    // MARK: - LocationPermissionService Implementation

    public func requestWhenInUsePermission() async -> LocationPermissionResult {
        // Check current status using iOS 14+ static method
        let currentStatus = CLLocationManager.authorizationStatus()

        // If already determined, return current status
        switch currentStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return .granted(convertAuthorizationStatus(currentStatus))
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            break // Continue to request
        @unknown default:
            return .failed(.unknown("Unknown authorization status"))
        }

        // Request permission and wait for delegate callback
        let requestId = UUID()
        let result = await withCheckedContinuation { continuation in
            self.permissionContinuations[requestId] = continuation
            self.locationManager.requestWhenInUseAuthorization()
        }

        // Clean up the continuation
        permissionContinuations.removeValue(forKey: requestId)

        // Convert result
        let status = convertAuthorizationStatus(result)
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            return .granted(status)
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .failed(.permissionNotDetermined)
        }
    }

    public func requestAlwaysPermission() async -> LocationPermissionResult {
        // Check current status using iOS 14+ static method
        let currentStatus = CLLocationManager.authorizationStatus()

        // If already authorized always, return success
        if currentStatus == .authorizedAlways {
            return .granted(.authorizedAlways)
        }

        // If restricted or denied, can't request
        if currentStatus == .denied || currentStatus == .restricted {
            return .denied
        }

        // If not even "When In Use", request that first
        if currentStatus == .notDetermined {
            let whenInUseResult = await requestWhenInUsePermission()
            switch whenInUseResult {
            case .granted:
                break // Continue to request "Always"
            case .denied:
                return .denied
            case .failed(let error):
                return .failed(error)
            }
        }

        // Now request "Always" permission and wait for delegate callback
        let requestId = UUID()
        let result = await withCheckedContinuation { continuation in
            self.permissionContinuations[requestId] = continuation
            self.locationManager.requestAlwaysAuthorization()
        }

        // Clean up the continuation
        permissionContinuations.removeValue(forKey: requestId)

        // Convert result
        let status = convertAuthorizationStatus(result)
        switch status {
        case .authorizedAlways:
            return .granted(status)
        case .authorizedWhenInUse:
            // User granted "When In Use" but not "Always"
            return .granted(status)
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .failed(.permissionNotDetermined)
        }
    }

    public func getAuthorizationStatus() async -> LocationAuthorizationStatus {
        let status = CLLocationManager.authorizationStatus()
        return convertAuthorizationStatus(status)
    }

    public func areLocationServicesEnabled() async -> Bool {
        // Check if authorization status indicates location services are available
        // If services are disabled system-wide, status will be .denied or .restricted
        let status = CLLocationManager.authorizationStatus()
        return status != .restricted
    }

    public func openAppSettings() async {
        #if canImport(UIKit)
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        await MainActor.run {
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
        #endif
    }

    // MARK: - Private Helpers

    private func convertAuthorizationStatus(_ status: CLAuthorizationStatus) -> LocationAuthorizationStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorizedWhenInUse:
            return .authorizedWhenInUse
        case .authorizedAlways:
            return .authorizedAlways
        @unknown default:
            return .notDetermined
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension DefaultLocationPermissionService: CLLocationManagerDelegate {
    nonisolated public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task {
            await handleAuthorizationChange(manager.authorizationStatus)
        }
    }

    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        // Resume all waiting continuations
        for (_, continuation) in permissionContinuations {
            continuation.resume(returning: status)
        }
        permissionContinuations.removeAll()
    }
}
