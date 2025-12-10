//
//  ICloudSyncPreferenceService.swift
//  RitualistCore
//
//  Manages user's iCloud sync preference.
//  This is a premium feature - only premium users can toggle sync on/off.
//

import Foundation

// MARK: - Protocol

public protocol ICloudSyncPreferenceServiceProtocol: Sendable {
    /// Whether user has enabled iCloud sync (user preference)
    /// Default: true (opt-out model - sync enabled by default for premium users)
    var isICloudSyncEnabled: Bool { get }

    /// Set iCloud sync preference (requires app restart to take effect)
    func setICloudSyncEnabled(_ enabled: Bool)

    /// Whether sync should actually be active (premium + user preference)
    /// - Parameter isPremium: Whether the user has premium subscription
    /// - Returns: true if sync should be active (premium AND not explicitly disabled)
    func shouldSyncBeActive(isPremium: Bool) -> Bool
}

// MARK: - Implementation

public final class ICloudSyncPreferenceService: ICloudSyncPreferenceServiceProtocol, Sendable {
    public static let shared = ICloudSyncPreferenceService()

    private init() {
        // Register default value (opt-out model - sync enabled by default)
        // Premium users get sync automatically; they can disable in Settings if desired
        UserDefaults.standard.register(defaults: [
            UserDefaultsKeys.iCloudSyncEnabled: true
        ])
    }

    public var isICloudSyncEnabled: Bool {
        // Using bool(forKey:) after registering defaults ensures we always get a sensible value
        UserDefaults.standard.bool(forKey: UserDefaultsKeys.iCloudSyncEnabled)
    }

    public func setICloudSyncEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: UserDefaultsKeys.iCloudSyncEnabled)
    }

    public func shouldSyncBeActive(isPremium: Bool) -> Bool {
        isPremium && isICloudSyncEnabled
    }
}

// MARK: - Mock Implementation

/// Mock implementation for testing - always returns sync enabled
public final class MockICloudSyncPreferenceService: ICloudSyncPreferenceServiceProtocol, Sendable {
    public init() {}

    public var isICloudSyncEnabled: Bool { true }

    public func setICloudSyncEnabled(_ enabled: Bool) {
        // No-op in mock
    }

    public func shouldSyncBeActive(isPremium: Bool) -> Bool {
        isPremium
    }
}
