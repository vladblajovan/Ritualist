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

    // MARK: - iCloud Sync

    /// Key for storing the last iCloud sync date
    public static let lastSyncDate = "com.ritualist.lastSyncDate"

    /// Key for tracking if we've shown the first iCloud sync toast
    public static let hasShownFirstSyncToast = "com.ritualist.hasShownFirstSyncToast"

    // MARK: - Schema Migration

    /// Key for storing the last schema version for migration tracking
    public static let lastSchemaVersion = "com.ritualist.lastSchemaVersion"

    // MARK: - Personality Analysis

    /// Key for storing scheduled user IDs for personality analysis
    public static let personalitySchedulerUsers = "personality_scheduler_users"

    /// Key for storing scheduled dates for personality analysis
    public static let personalitySchedulerDates = "personality_scheduler_dates"

    /// Key for storing data hashes for personality analysis change detection
    public static let personalitySchedulerHashes = "personality_scheduler_hashes"

    // MARK: - Inspiration/Motivation

    /// Key for storing the last date inspiration triggers were reset
    public static let lastInspirationResetDate = "lastInspirationResetDate"

    /// Key for storing dismissed triggers for the current day
    public static let dismissedTriggersToday = "dismissedTriggersToday"
}

// MARK: - Notification Names

public extension Notification.Name {
    /// Posted when iCloud syncs data from another device.
    /// Used to trigger the sync toast in RootTabView.
    static let iCloudDidSyncRemoteChanges = Notification.Name("iCloudDidSyncRemoteChanges")
}
