//
//  GeofenceEvent.swift
//  RitualistCore
//
//  Created by Claude on 03.11.2025.
//
//  Represents a geofence event (entry or exit) for location-based habit reminders.
//

import Foundation
import CoreLocation

/// Type of geofence event that occurred
public enum GeofenceEventType: String, Codable, Equatable {
    /// User entered the geofenced region
    case entry

    /// User exited the geofenced region
    case exit
}

/// Represents a geofence boundary crossing event
///
/// This is a thin data transfer object from the location monitoring service.
/// The configuration is optional because the service should be a pass-through layer -
/// all business logic (frequency checks, etc.) should use the authoritative
/// configuration from the database via the UseCase layer.
public struct GeofenceEvent {
    /// The habit ID associated with this geofence
    public let habitId: UUID

    /// Type of event (entry or exit)
    public let eventType: GeofenceEventType

    /// Timestamp when the event occurred
    public let timestamp: Date

    /// The location configuration (optional - UseCase fetches from database for authoritative data)
    /// When nil, the event handler must fetch configuration from database
    public let configuration: LocationConfiguration?

    /// Actual location where the event was detected (optional)
    public let detectedLocation: CLLocationCoordinate2D?

    public init(
        habitId: UUID,
        eventType: GeofenceEventType,
        timestamp: Date = Date(),
        configuration: LocationConfiguration? = nil,
        detectedLocation: CLLocationCoordinate2D? = nil
    ) {
        self.habitId = habitId
        self.eventType = eventType
        self.timestamp = timestamp
        self.configuration = configuration
        self.detectedLocation = detectedLocation
    }

    /// Check if this event should trigger a notification based on provided configuration
    /// Returns true if no configuration provided (caller should fetch from database)
    public func shouldTriggerNotification() -> Bool {
        guard let configuration = configuration else {
            // No config provided - let the UseCase decide using database
            return true
        }

        // Check if the trigger type matches the event type
        let triggerMatches: Bool
        switch configuration.triggerType {
        case .entry:
            triggerMatches = eventType == .entry
        case .exit:
            triggerMatches = eventType == .exit
        case .both:
            triggerMatches = true
        }

        guard triggerMatches else { return false }

        // Check frequency rules for this specific event type
        return configuration.shouldTriggerNotification(for: eventType, now: timestamp)
    }

    /// Human-readable description of the event
    public var description: String {
        let action = eventType == .entry ? "entered" : "exited"
        let label = configuration?.locationLabel ?? "location"
        return "User \(action) \(label)"
    }
}

/// Authorization status for location services
public enum LocationAuthorizationStatus: Equatable {
    /// User has not yet been asked for location permission
    case notDetermined

    /// User denied location permission
    case denied

    /// Location services are restricted (e.g., parental controls)
    case restricted

    /// Location permission granted for "When In Use" only
    case authorizedWhenInUse

    /// Location permission granted for "Always" (background monitoring)
    case authorizedAlways

    /// Whether the app can monitor geofences in the background
    public var canMonitorGeofences: Bool {
        self == .authorizedAlways
    }

    /// Whether the app has any location permission
    public var hasAnyAuthorization: Bool {
        self == .authorizedWhenInUse || self == .authorizedAlways
    }

    /// User-friendly display text for Settings UI
    public var displayText: String {
        switch self {
        case .notDetermined:
            return "Tap to enable location access"
        case .denied:
            return "Denied - open Settings to enable"
        case .restricted:
            return "Restricted by device settings"
        case .authorizedWhenInUse:
            return "Enabled while using app"
        case .authorizedAlways:
            return "Always enabled"
        }
    }
}
