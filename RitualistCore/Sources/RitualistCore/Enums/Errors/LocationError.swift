//
//  LocationError.swift
//  RitualistCore
//
//  Created by Claude on 03.11.2025.
//
//  Errors related to location-based habit features.
//

import Foundation

public enum LocationError: Error, Equatable, Sendable {
    /// Location services are disabled on the device
    case locationServicesDisabled

    /// User denied location permission
    case permissionDenied

    /// User has not yet granted location permission
    case permissionNotDetermined

    /// Location permission is restricted (parental controls, etc.)
    case permissionRestricted

    /// Invalid location configuration (e.g., invalid coordinates or radius)
    case invalidConfiguration(String)

    /// Failed to register geofence with CoreLocation
    case geofenceRegistrationFailed(String)

    /// Maximum number of geofences reached (iOS limit: 20)
    case geofenceLimitReached

    /// Failed to start monitoring location
    case monitoringFailed(String)

    /// Unknown location error
    case unknown(String)
}

extension LocationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .locationServicesDisabled:
            return "Location services are disabled. Please enable them in Settings."
        case .permissionDenied:
            return "Location permission denied. Please grant permission in Settings to use location-based reminders."
        case .permissionNotDetermined:
            return "Location permission not yet granted. Please allow location access to enable location-based reminders."
        case .permissionRestricted:
            return "Location access is restricted. This may be due to parental controls or device restrictions."
        case .invalidConfiguration(let message):
            return "Invalid location configuration: \(message)"
        case .geofenceRegistrationFailed(let message):
            return "Failed to register geofence: \(message)"
        case .geofenceLimitReached:
            return "Maximum number of location reminders reached. Please disable location monitoring for other habits to add more."
        case .monitoringFailed(let message):
            return "Failed to start location monitoring: \(message)"
        case .unknown(let message):
            return "Location error: \(message)"
        }
    }
}
