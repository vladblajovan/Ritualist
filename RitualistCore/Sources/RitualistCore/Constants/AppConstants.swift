//
//  AppConstants.swift
//  RitualistCore
//
//  Centralized app-wide constants for the Ritualist application.
//  This is the single source of truth for all configuration values,
//  ensuring consistency across iOS app, widgets, and watch app.
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

    // MARK: - Notifications

    /// Key for storing habit IDs that received catch-up notifications today
    /// Used to prevent duplicate "Don't forget" reminders on repeated foreground events
    public static let catchUpDeliveredHabitIds = "com.ritualist.catchUpDeliveredHabitIds"

    /// Key for storing the date when catch-up notifications were last tracked
    /// Resets daily to allow fresh catch-ups each day
    public static let catchUpDeliveryDate = "com.ritualist.catchUpDeliveryDate"

    /// Key for storing notification IDs that have fired today
    /// Used to prevent duplicate notifications on app restart within the same time window
    public static let firedNotificationIds = "com.ritualist.firedNotificationIds"

    /// Key for storing the date when fired notifications were last tracked
    /// Resets daily to allow fresh notifications each day
    public static let firedNotificationDate = "com.ritualist.firedNotificationDate"
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

// MARK: - App URLs

/// Centralized URLs for external links.
/// Using static let ensures fail-fast at app startup if URLs are malformed.
public enum AppURLs {
    /// Support email address
    public static let supportEmail = URL(string: "mailto:ritualist-support@gmail.com")!

    /// Help & FAQ page
    public static let helpAndFAQ = URL(string: "https://vladblajovan.github.io/ritualist-legal/support.html")!

    /// Privacy Policy page
    public static let privacyPolicy = URL(string: "https://vladblajovan.github.io/ritualist-legal/privacy.html")!

    /// Terms of Service page
    public static let termsOfService = URL(string: "https://vladblajovan.github.io/ritualist-legal/terms.html")!
}

// MARK: - Notification Names

public extension Notification.Name {
    /// Posted when iCloud syncs data from another device.
    /// Used to trigger the sync toast in RootTabView.
    static let iCloudDidSyncRemoteChanges = Notification.Name("iCloudDidSyncRemoteChanges")

    /// Posted when habits data changes locally (create, update, delete).
    /// Used to trigger immediate refresh in other tabs (e.g., Overview).
    static let habitsDataDidChange = Notification.Name("habitsDataDidChange")
}

// MARK: - iCloud Configuration

/// CloudKit and iCloud container identifiers.
public enum iCloudConstants {
    /// CloudKit container identifier for iCloud sync
    public static let containerIdentifier = "iCloud.com.vladblajovan.Ritualist"
}

// MARK: - Persistence Store Names

/// Store names for SwiftData persistence configurations.
/// Used by PersistenceConfiguration to define storage locations.
public enum PersistenceStoreNames {
    /// CloudKit-synced store name (habits, logs, categories, profile, onboarding)
    /// This store syncs to iCloud when available, or operates locally when offline
    public static let cloudKit = "CloudKit"

    /// Local-only store name (privacy-sensitive data like PersonalityAnalysis)
    /// This store NEVER syncs to iCloud regardless of availability
    public static let local = "Local"
}

// MARK: - Sync Configuration

/// Configuration constants for iCloud sync retry behavior.
/// Used when waiting for CloudKit data to become available after detecting a returning user.
public enum SyncConstants {
    /// Maximum number of retry attempts when waiting for sync data (30 × 2s = 60 seconds)
    public static let maxRetries = 30

    /// Interval between retry attempts in seconds
    public static let retryIntervalSeconds: UInt64 = 2

    /// Total timeout duration in seconds (convenience for documentation)
    public static let totalTimeoutSeconds: TimeInterval = 60
}

// MARK: - Business Rules

/// Centralized business rules and constants for the Ritualist application.
/// This ensures consistent behavior across all platforms (iOS, widgets, watch app).
public struct BusinessConstants {

    // MARK: - Habit Limits

    /// Maximum number of habits allowed for free users
    public static let freeMaxHabits = 5

    /// Maximum number of habits allowed for premium users (unlimited)
    public static let premiumMaxHabits = Int.max

    // MARK: - Category Limits

    /// Maximum number of categories for all users (unlimited)
    /// Rationale: Categories are lightweight organization tools. The 5-habit limit
    /// naturally constrains category usage, making an explicit limit unnecessary.
    /// Organization features should remain free to avoid user frustration.
    public static let maxCategories = Int.max

    /// Maximum length for habit names
    public static let habitNameMaxLength = 50

    /// Maximum length for habit unit labels (e.g., "glasses", "pages")
    public static let habitUnitLabelMaxLength = 20

    // MARK: - Personality Analysis Thresholds

    /// Minimum number of active habits required for personality analysis
    public static let minActiveHabitsForAnalysis = 5

    /// Minimum number of tracking days required for personality analysis
    public static let minTrackingDaysForAnalysis = 7

    /// Minimum completion rate required for personality analysis (10% - low completion is valid data)
    public static let minCompletionRateForAnalysis = 0.1

    /// Minimum data change threshold to trigger new personality analysis (10%)
    public static let personalityDataChangeThreshold = 0.1

    /// Personality analysis validity period in seconds (7 * 24 * 60 * 60)
    public static let personalityAnalysisValidityPeriod: TimeInterval = 604800

    /// Minimum habit diversity (different categories) for analysis
    public static let minHabitDiversityForAnalysis = 2

    // MARK: - Validation Rules

    /// Minimum daily target value for numeric habits
    public static let minDailyTarget = 1.0

    /// Maximum daily target value for numeric habits
    public static let maxDailyTarget = 999.0

    /// Maximum length for emoji fields
    public static let maxEmojiLength = 2

    /// Minimum value for binary habit completion
    public static let minBinaryCompletionValue = 1.0

    // MARK: - Platform Integration Intervals

    /// Widget update interval in seconds (15 * 60)
    public static let widgetUpdateInterval: TimeInterval = 900

    /// Watch app sync interval in seconds (30 * 60)
    public static let watchSyncInterval: TimeInterval = 1800

    /// Notification delay for immediate triggers (5 seconds)
    public static let immediateNotificationDelay: TimeInterval = 5

    /// Background notification delay in seconds (20 * 60)
    public static let backgroundNotificationDelay: TimeInterval = 1200

    /// Delay before reading data after NSPersistentStoreRemoteChange notification (in seconds).
    ///
    /// SwiftData/CloudKit fires NSPersistentStoreRemoteChange when the persistent store receives
    /// remote changes, but the merge into the view context happens asynchronously afterward.
    /// Unfortunately, SwiftData doesn't provide a "merge complete" notification, so we use a
    /// brief delay to ensure data is fully available before reading.
    ///
    /// This is a standard iOS pattern - 500ms provides reliable merge completion on most devices
    /// while keeping the UI responsive.
    public static let remoteChangeMergeDelay: TimeInterval = 0.5

    /// Debounce interval for UI refresh notifications (in seconds).
    ///
    /// When iCloud changes arrive (local saves, remote sync), we debounce the UI refresh notification.
    /// This ensures that rapid changes (e.g., user editing multiple profile fields, bulk sync from another
    /// device) result in ONE UI refresh after activity settles, rather than multiple refreshes causing flashing.
    /// 3 seconds provides resilience against bulk syncs (observed: 16+ notifications over several seconds).
    public static let uiRefreshDebounceInterval: TimeInterval = 3.0

    // MARK: - Time Intervals

    /// Time interval for 1 day in seconds (24 * 60 * 60)
    public static let oneDayInterval: TimeInterval = 86400

    /// Time interval for 1 hour in seconds (60 * 60)
    public static let oneHourInterval: TimeInterval = 3600

    /// Time interval for 30 days in seconds (30 * 24 * 60 * 60)
    public static let thirtyDaysInterval: TimeInterval = 2592000

    /// Time interval for 60 days in seconds (60 * 24 * 60 * 60)
    public static let sixtyDaysInterval: TimeInterval = 5184000

    /// Time interval for 90 days in seconds (90 * 24 * 60 * 60)
    public static let ninetyDaysInterval: TimeInterval = 7776000

    /// Time interval for 365 days (1 year) in seconds (365 * 24 * 60 * 60)
    public static let oneYearInterval: TimeInterval = 31536000

    // MARK: - Error Handling & Analytics

    /// Error log retention period in days
    public static let errorLogRetentionDays = 7

    /// Maximum number of errors to keep in memory
    public static let maxErrorLogSize = 100

    /// Time window for error rate calculations (24 hours)
    public static let errorRateTimeWindow: TimeInterval = oneDayInterval

    /// Time window for recent error analysis (1 hour)
    public static let recentErrorTimeWindow: TimeInterval = oneHourInterval

    // MARK: - Streak Calculation Rules

    /// Minimum streak length to display (1 day)
    public static let minDisplayableStreak = 1

    /// Streak length threshold for special highlighting (14 days)
    public static let streakHighlightThreshold = 14

    /// Perfect completion rate threshold (100%)
    public static let perfectCompletionRate = 1.0

    /// Good completion rate threshold (50%) - habit considered "completed" for stats
    public static let goodCompletionRate = 0.5

    /// Struggling completion rate threshold (60%)
    public static let strugglingCompletionRate = 0.6

    // MARK: - Motivation & Engagement

    /// Maximum number of inspiration items to show in the carousel
    /// Limited to 3 to prevent overwhelming users with too many cards
    public static let maxInspirationCarouselItems = 3

    /// Completion rate for "strong finish" motivation (100%)
    public static let strongFinishCompletionRate = 1.0

    /// Time threshold for afternoon motivation (3 PM)
    public static let afternoonMotivationHour = 15

    /// Time threshold for afternoon motivation end (5 PM)
    public static let afternoonMotivationEndHour = 17

    /// Completion rate threshold for struggling motivation (60%)
    public static let strugglingMotivationThreshold = 0.6

    // MARK: - Testing & Simulation

    /// Default purchase simulation delay for testing (2 seconds)
    public static let defaultPurchaseSimulationDelay: TimeInterval = 2.0

    /// Default testing failure rate (20%)
    public static let defaultTestingFailureRate = 0.2

    // MARK: - TodaysSummaryCard Layout

    /// iPhone layout: default visible remaining habits when collapsed
    public static let iPhoneDefaultVisibleRemaining = 3

    /// iPhone layout: default visible completed habits when collapsed
    public static let iPhoneDefaultVisibleCompleted = 2

    /// iPad layout: number of columns in grid
    public static let iPadHabitGridColumns = 3

    /// iPad layout: number of rows to show for remaining habits when collapsed
    public static let iPadDefaultVisibleRemainingRows = 2

    /// iPad layout: number of rows to show for completed habits when collapsed
    public static let iPadDefaultVisibleCompletedRows = 1
}

