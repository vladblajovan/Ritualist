//
//  AppConstants.swift
//  RitualistCore
//
//  Centralized app-wide constants for UserDefaults keys and Notification names.
//  Ensures consistency and prevents typos in string literals across the codebase.
//

import Foundation

// MARK: - UserDefaults Keys

/// Centralized UserDefaults keys used across the app.
/// Using an enum with static properties prevents instantiation and provides a clear namespace.
public enum UserDefaultsKeys {
    /// Key for storing the last iCloud sync date
    public static let lastSyncDate = "com.ritualist.lastSyncDate"
}

// MARK: - Notification Names

public extension Notification.Name {
    /// Posted when iCloud syncs data from another device.
    /// Used to trigger the sync toast in RootTabView.
    static let iCloudDidSyncRemoteChanges = Notification.Name("iCloudDidSyncRemoteChanges")
}
