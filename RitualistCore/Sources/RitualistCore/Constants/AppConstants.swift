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

    /// Key for user's iCloud sync preference (premium feature)
    /// Default: true (opt-out model - sync enabled by default for premium users)
    /// Premium users can disable in Settings if they prefer local-only storage
    /// Change takes effect on next app launch (requires restart)
    public static let iCloudSyncEnabled = "com.ritualist.iCloudSyncEnabled"

    // MARK: - Premium Status Cache

    /// Key for caching premium status from StoreKit2 at startup
    /// Set by transaction observer on app launch before DI initialization
    /// Used by PersistenceContainer to determine sync mode synchronously
    ///
    /// StoreKit2 Implementation:
    /// 1. On app launch, check `Transaction.currentEntitlements`
    /// 2. Set this key to true/false based on active subscriptions
    /// 3. Listen for transaction updates and update the cache
    ///
    /// Note: Currently unused - will be needed when migrating from mock to real StoreKit2
    public static let premiumStatusCache = "com.ritualist.premiumStatusCache"

    /// Key for tracking if we've shown the "Premium activated, restart for sync" toast
    /// Prevents showing the toast repeatedly if user doesn't restart immediately
    /// Reset when cache is updated (so toast shows again if premium status changes)
    public static let hasShownPremiumRestartToast = "com.ritualist.hasShownPremiumRestartToast"

    // MARK: - Schema Migration

    /// Key for storing the last schema version for migration tracking
    public static let lastSchemaVersion = "com.ritualist.lastSchemaVersion"

    // MARK: - Personality Analysis

    /// Key for storing scheduled user IDs for personality analysis
    public static let personalitySchedulerUsers = "com.ritualist.personalitySchedulerUsers"

    /// Key for storing scheduled dates for personality analysis
    public static let personalitySchedulerDates = "com.ritualist.personalitySchedulerDates"

    /// Key for storing data hashes for personality analysis change detection
    public static let personalitySchedulerHashes = "com.ritualist.personalitySchedulerHashes"

    // MARK: - Inspiration/Motivation

    /// Key for storing the last date inspiration triggers were reset
    public static let lastInspirationResetDate = "com.ritualist.lastInspirationResetDate"

    /// Key for storing dismissed triggers for the current day
    public static let dismissedTriggersToday = "com.ritualist.dismissedTriggersToday"

    // MARK: - Widget

    /// Key for storing the selected date in widget navigation
    public static let widgetSelectedDate = "com.ritualist.widgetSelectedDate"

    // MARK: - Migration & Backup

    /// Key for storing migration history entries
    public static let migrationHistory = "com.ritualist.migrationHistory"

    /// Key for tracking pending restore operations
    public static let pendingRestore = "com.ritualist.pendingRestore"

    // MARK: - Personality Preferences

    /// Key for storing personality preferences for the main user
    public static let personalityPreferencesMainUser = "com.ritualist.personalityPreferencesMainUser"

    // MARK: - Category Seeding

    /// Key for tracking if predefined categories have been seeded
    /// Must be cleared when user deletes all data to allow re-seeding on next launch
    public static let categorySeedingCompleted = "com.ritualist.categories.seedingCompleted"

    // MARK: - Mock/Debug

    /// Key for storing mock purchases (used by MockSecureSubscriptionService)
    /// Also used by PersistenceContainer to determine premium status at startup
    public static let mockPurchases = "secure_mock_purchases"

    // MARK: - Build Configuration

    /// Key for caching build configuration from main app target
    /// Set by main app at launch BEFORE DI initialization
    /// This bridges the compile-time ALL_FEATURES_ENABLED flag to RitualistCore (Swift Package)
    /// which cannot see the flag directly due to Swift Package compilation isolation
    public static let allFeaturesEnabledCache = "com.ritualist.allFeaturesEnabled"
}

// MARK: - Logger Constants

/// Centralized constants for logging configuration.
public enum LoggerConstants {
    /// Main app logger subsystem identifier
    /// Used by DebugLogger for consistent os_log output
    public static let appSubsystem = "com.ritualist.app"

    /// Widget logger subsystem identifier
    /// Note: Widgets use WidgetConstants.loggerSubsystem in RitualistWidget target
    public static let widgetSubsystem = "com.ritualist.widget"
}

// MARK: - Timezone Constants

/// Centralized constants for timezone handling.
public enum TimezoneConstants {
    /// Maximum number of timezone changes to retain in history.
    /// Older entries are trimmed to prevent unbounded storage growth.
    /// For analytics requiring full history, consider exporting changes to external analytics
    /// before truncation, or implement a separate analytics event stream.
    public static let maxTimezoneHistoryEntries = 100
}

// MARK: - Notification Names

public extension Notification.Name {
    /// Posted when iCloud syncs data from another device.
    /// Used to trigger the sync toast in RootTabView.
    static let iCloudDidSyncRemoteChanges = Notification.Name("iCloudDidSyncRemoteChanges")
}
