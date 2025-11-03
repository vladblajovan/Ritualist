//
//  LocationConfiguration.swift
//  RitualistCore
//
//  Created by Claude on 03.11.2025.
//
//  Location configuration for geofence-based habit reminders.
//  Allows habits to trigger notifications when entering or exiting specified areas.
//

import Foundation
import CoreLocation

/// Defines how a geofence should trigger notifications
public enum GeofenceTrigger: String, Codable, Equatable, Hashable {
    /// Trigger notification when entering the geofenced area
    case entry

    /// Trigger notification when exiting the geofenced area
    case exit

    /// Trigger notification on both entry and exit
    case both

    public var displayName: String {
        switch self {
        case .entry: return "When Arriving"
        case .exit: return "When Leaving"
        case .both: return "Arriving & Leaving"
        }
    }
}

/// Defines how frequently location-based notifications should be sent
public enum NotificationFrequency: Codable, Equatable, Hashable {
    /// Send notification only once per day, regardless of how many times user enters/exits
    case oncePerDay

    /// Send notification every time user enters/exits, with minimum cooldown period in minutes
    case everyEntry(cooldownMinutes: Int)

    public var displayName: String {
        switch self {
        case .oncePerDay: return "Once Per Day"
        case .everyEntry(let minutes): return "Every Entry (\(minutes)m cooldown)"
        }
    }

    /// Default cooldown: 30 minutes
    public static let defaultCooldown = 30
}

/// Location-based configuration for habit reminders
public struct LocationConfiguration: Codable, Equatable, Hashable {
    /// Geographic coordinate of the geofence center
    public var latitude: Double
    public var longitude: Double

    /// Radius of the geofence in meters (50m - 500m)
    public var radius: Double

    /// Type of geofence trigger (entry, exit, or both)
    public var triggerType: GeofenceTrigger

    /// How frequently notifications should be sent
    public var frequency: NotificationFrequency

    /// Whether location monitoring is currently enabled for this habit
    public var isEnabled: Bool

    /// Optional descriptive label for the location (e.g., "Home", "Gym", "Office")
    public var locationLabel: String?

    /// Last time a geofence event triggered a notification (for frequency tracking)
    public var lastTriggerDate: Date?

    /// Last time an entry event triggered a notification (for separate entry/exit frequency tracking)
    public var lastEntryTriggerDate: Date?

    /// Last time an exit event triggered a notification (for separate entry/exit frequency tracking)
    public var lastExitTriggerDate: Date?

    public init(
        latitude: Double,
        longitude: Double,
        radius: Double = 100.0,
        triggerType: GeofenceTrigger = .entry,
        frequency: NotificationFrequency = .oncePerDay,
        isEnabled: Bool = true,
        locationLabel: String? = nil,
        lastTriggerDate: Date? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.triggerType = triggerType
        self.frequency = frequency
        self.isEnabled = isEnabled
        self.locationLabel = locationLabel
        self.lastTriggerDate = lastTriggerDate
    }

    /// Convert to CLLocationCoordinate2D for CoreLocation usage
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Create from CLLocationCoordinate2D
    public static func create(
        from coordinate: CLLocationCoordinate2D,
        radius: Double = 100.0,
        triggerType: GeofenceTrigger = .entry,
        frequency: NotificationFrequency = .oncePerDay,
        isEnabled: Bool = true,
        locationLabel: String? = nil
    ) -> LocationConfiguration {
        LocationConfiguration(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            radius: radius,
            triggerType: triggerType,
            frequency: frequency,
            isEnabled: isEnabled,
            locationLabel: locationLabel
        )
    }

    /// Check if a notification should be sent based on frequency settings
    public func shouldTriggerNotification(for eventType: GeofenceEventType, now: Date = Date()) -> Bool {
        guard isEnabled else { return false }

        // Get the appropriate last trigger date for this event type
        let lastTrigger: Date?
        switch eventType {
        case .entry:
            lastTrigger = lastEntryTriggerDate
        case .exit:
            lastTrigger = lastExitTriggerDate
        }

        switch frequency {
        case .oncePerDay:
            // Check if we already triggered this event type today
            guard let lastTrigger = lastTrigger else { return true }
            return !Calendar.current.isDate(lastTrigger, inSameDayAs: now)

        case .everyEntry(let cooldownMinutes):
            // Check if cooldown period has passed for this event type
            guard let lastTrigger = lastTrigger else { return true }
            let cooldownSeconds = TimeInterval(cooldownMinutes * 60)
            return now.timeIntervalSince(lastTrigger) >= cooldownSeconds
        }
    }
}

// MARK: - Validation

public extension LocationConfiguration {
    /// Minimum allowed radius in meters
    static let minimumRadius: Double = 50.0

    /// Maximum allowed radius in meters
    static let maximumRadius: Double = 500.0

    /// Default radius in meters
    static let defaultRadius: Double = 100.0

    /// Validate that the configuration is valid
    var isValid: Bool {
        // Validate coordinates are valid
        guard coordinate.latitude >= -90 && coordinate.latitude <= 90 else { return false }
        guard coordinate.longitude >= -180 && coordinate.longitude <= 180 else { return false }

        // Validate radius is within allowed range
        guard radius >= Self.minimumRadius && radius <= Self.maximumRadius else { return false }

        return true
    }
}
