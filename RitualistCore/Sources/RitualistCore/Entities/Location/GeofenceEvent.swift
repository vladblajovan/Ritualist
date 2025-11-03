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
public struct GeofenceEvent: Equatable {
    /// The habit ID associated with this geofence
    public let habitId: UUID

    /// Type of event (entry or exit)
    public let eventType: GeofenceEventType

    /// Timestamp when the event occurred
    public let timestamp: Date

    /// The location configuration that triggered this event
    public let configuration: LocationConfiguration

    /// Actual location where the event was detected (optional)
    public let detectedLocation: CLLocationCoordinate2D?

    public init(
        habitId: UUID,
        eventType: GeofenceEventType,
        timestamp: Date = Date(),
        configuration: LocationConfiguration,
        detectedLocation: CLLocationCoordinate2D? = nil
    ) {
        self.habitId = habitId
        self.eventType = eventType
        self.timestamp = timestamp
        self.configuration = configuration
        self.detectedLocation = detectedLocation
    }

    /// Check if this event should trigger a notification based on configuration
    public func shouldTriggerNotification() -> Bool {
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

        // Check frequency rules
        return configuration.shouldTriggerNotification(now: timestamp)
    }

    /// Human-readable description of the event
    public var description: String {
        let action = eventType == .entry ? "entered" : "exited"
        let label = configuration.locationLabel ?? "location"
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
}
