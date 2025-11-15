//
//  DisplayTimezoneMode.swift
//  RitualistCore
//
//  Created by Claude on 15.11.2025.
//
//  Defines how the user wants to view their habit data in terms of timezone.
//  Part of the "Three-Timezone Model" for comprehensive timezone handling.
//

import Foundation

/// Display timezone mode controls how habit data (Today, streaks, statistics) is calculated and displayed.
///
/// ## The Three-Timezone Model
/// - **Current Timezone**: Auto-detected from device (informational - "Where am I?")
/// - **Home Timezone**: User-defined semantic location (stable - "Where do I live?")
/// - **Display Mode**: User chooses viewing perspective (functional - "How to view data?")
///
/// ## Example Scenarios
/// - `.current`: When traveling, see habits in your current timezone (adapts automatically)
/// - `.home`: When traveling, see habits in your home timezone (stable reference point)
/// - `.custom("America/New_York")`: View habits as if you were in a specific timezone
///
/// ## Migration from Legacy Mode
/// - Legacy mode "original" (show logs in their recorded timezone) is intentionally removed
/// - All calculations now use a single consistent timezone (Display mode)
/// - Original timezone is preserved in HabitLog.timezone for historical context
public enum DisplayTimezoneMode: Codable, Equatable, Hashable {
    /// Follow the device's current timezone (auto-updates when user travels)
    /// Best for: Users who want their habit tracking to adapt to travel
    case current

    /// Use the user's designated home timezone (stable, doesn't change with travel)
    /// Best for: Users who want a consistent reference point regardless of location
    case home

    /// Use a specific custom timezone identifier (e.g., "America/New_York")
    /// Best for: Advanced users who want to view habits from a specific timezone perspective
    case custom(String)

    // MARK: - Codable Implementation

    private enum CodingKeys: String, CodingKey {
        case type
        case timezoneIdentifier
    }

    private enum ModeType: String, Codable {
        case current
        case home
        case custom
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ModeType.self, forKey: .type)

        switch type {
        case .current:
            self = .current
        case .home:
            self = .home
        case .custom:
            let identifier = try container.decode(String.self, forKey: .timezoneIdentifier)
            self = .custom(identifier)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .current:
            try container.encode(ModeType.current, forKey: .type)
        case .home:
            try container.encode(ModeType.home, forKey: .type)
        case .custom(let identifier):
            try container.encode(ModeType.custom, forKey: .type)
            try container.encode(identifier, forKey: .timezoneIdentifier)
        }
    }

    // MARK: - Helper Methods

    /// Returns the actual TimeZone to use for calculations, given the current and home timezone identifiers
    /// - Parameters:
    ///   - currentTimezoneIdentifier: The device's current timezone identifier
    ///   - homeTimezoneIdentifier: The user's home timezone identifier
    /// - Returns: The TimeZone to use for all habit calculations, or nil if invalid
    public func resolveTimezone(
        currentTimezoneIdentifier: String,
        homeTimezoneIdentifier: String
    ) -> TimeZone? {
        switch self {
        case .current:
            return TimeZone(identifier: currentTimezoneIdentifier)
        case .home:
            return TimeZone(identifier: homeTimezoneIdentifier)
        case .custom(let identifier):
            return TimeZone(identifier: identifier)
        }
    }

    /// Human-readable description for UI display
    public var displayName: String {
        switch self {
        case .current:
            return "Current Location"
        case .home:
            return "Home Timezone"
        case .custom(let identifier):
            if let timezone = TimeZone(identifier: identifier) {
                return "\(timezone.localizedName(for: .standard, locale: .current) ?? identifier)"
            }
            return identifier
        }
    }

    /// User-friendly description with more context
    public var description: String {
        switch self {
        case .current:
            return "Follow device timezone (adapts when you travel)"
        case .home:
            return "Use home timezone (stable reference point)"
        case .custom(let identifier):
            return "Custom timezone: \(identifier)"
        }
    }
}

// MARK: - Timezone Change Tracking

/// Represents a historical timezone change event for analytics and debugging
public struct TimezoneChange: Codable, Equatable, Hashable {
    /// When the timezone change occurred
    public let timestamp: Date

    /// Previous timezone identifier
    public let fromTimezone: String

    /// New timezone identifier
    public let toTimezone: String

    /// How the change was triggered
    public let trigger: ChangeTriggger

    public init(timestamp: Date, fromTimezone: String, toTimezone: String, trigger: ChangeTriggger) {
        self.timestamp = timestamp
        self.fromTimezone = fromTimezone
        self.toTimezone = toTimezone
        self.trigger = trigger
    }

    /// What triggered this timezone change
    public enum ChangeTriggger: String, Codable {
        /// Device timezone changed (user traveled or changed system settings)
        case deviceChange = "device_change"

        /// User manually changed their home timezone in settings
        case userUpdate = "user_update"

        /// User changed display mode
        case displayModeChange = "display_mode_change"

        /// Initial app installation
        case appInstall = "app_install"
    }
}

// MARK: - String-based Migration Helper

extension DisplayTimezoneMode {
    /// Converts legacy string-based timezone mode to modern DisplayTimezoneMode enum
    /// Used during migration from SchemaV8 to SchemaV9
    ///
    /// - Parameter legacyMode: The old string-based mode ("original", "current", "home", or timezone identifier)
    /// - Returns: The equivalent DisplayTimezoneMode, defaulting to .current if unrecognized
    public static func fromLegacyString(_ legacyMode: String) -> DisplayTimezoneMode {
        switch legacyMode {
        case "original":
            // Legacy "original" mode (show each log in its recorded timezone) is deprecated
            // Default to "current" for migration safety
            return .current
        case "current":
            return .current
        case "home":
            return .home
        default:
            // Assume it's a timezone identifier for custom mode
            if TimeZone(identifier: legacyMode) != nil {
                return .custom(legacyMode)
            }
            // Fallback to current if invalid
            return .current
        }
    }

    /// Converts DisplayTimezoneMode to a string representation for SchemaV9 storage
    /// - Returns: String representation suitable for SwiftData storage
    public func toLegacyString() -> String {
        switch self {
        case .current:
            return "current"
        case .home:
            return "home"
        case .custom(let identifier):
            return identifier
        }
    }
}
