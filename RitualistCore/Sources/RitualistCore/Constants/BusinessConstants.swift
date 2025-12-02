//
//  BusinessRules.swift
//  RitualistCore
//
//  Created by Claude on 13.08.2025.
//

import Foundation

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
    
    /// Minimum number of custom categories required for personality analysis
    public static let minCustomCategoriesForAnalysis = 3
    
    /// Minimum number of custom habits required for personality analysis
    public static let minCustomHabitsForAnalysis = 3
    
    /// Minimum completion rate required for personality analysis (30%)
    public static let minCompletionRateForAnalysis = 0.3
    
    /// Minimum data change threshold to trigger new personality analysis (10%)
    public static let personalityDataChangeThreshold = 0.1
    
    /// Personality analysis validity period in seconds (7 days)
    public static let personalityAnalysisValidityPeriod: TimeInterval = 7 * 24 * 60 * 60
    
    /// Minimum habit diversity (different categories) for analysis
    public static let minHabitDiversityForAnalysis = 3
    
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
    
    /// Widget update interval in seconds (15 minutes)
    public static let widgetUpdateInterval: TimeInterval = 15 * 60
    
    /// Watch app sync interval in seconds (30 minutes) 
    public static let watchSyncInterval: TimeInterval = 30 * 60
    
    /// Notification delay for immediate triggers (5 seconds)
    public static let immediateNotificationDelay: TimeInterval = 5
    
    /// Background notification delay (20 minutes)
    public static let backgroundNotificationDelay: TimeInterval = 20 * 60

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

    /// Time interval for 1 day in seconds
    public static let oneDayInterval: TimeInterval = 24 * 60 * 60

    /// Time interval for 1 hour in seconds
    public static let oneHourInterval: TimeInterval = 60 * 60

    /// Time interval for 30 days in seconds
    public static let thirtyDaysInterval: TimeInterval = 30 * 24 * 60 * 60

    /// Time interval for 60 days in seconds
    public static let sixtyDaysInterval: TimeInterval = 60 * 24 * 60 * 60

    /// Time interval for 90 days in seconds
    public static let ninetyDaysInterval: TimeInterval = 90 * 24 * 60 * 60

    /// Time interval for 365 days (1 year) in seconds
    public static let oneYearInterval: TimeInterval = 365 * 24 * 60 * 60

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
    
    // MARK: - Utility Methods
    
    /// Validates if a habit name meets business rules
    /// - Parameter name: The habit name to validate
    /// - Returns: True if valid, false otherwise
    public static func isValidHabitName(_ name: String) -> Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
               name.count <= habitNameMaxLength
    }
    
    /// Validates if a unit label meets business rules
    /// - Parameter label: The unit label to validate
    /// - Returns: True if valid, false otherwise
    public static func isValidUnitLabel(_ label: String) -> Bool {
        return label.count <= habitUnitLabelMaxLength
    }
    
    /// Validates if a daily target meets business rules
    /// - Parameter target: The daily target to validate
    /// - Returns: True if valid, false otherwise
    public static func isValidDailyTarget(_ target: Double) -> Bool {
        return target >= minDailyTarget && target <= maxDailyTarget
    }
    
    /// Checks if a completion rate indicates perfect performance
    /// - Parameter rate: The completion rate (0.0 to 1.0)
    /// - Returns: True if perfect completion, false otherwise
    public static func isPerfectCompletion(_ rate: Double) -> Bool {
        return rate >= perfectCompletionRate
    }
    
    /// Checks if a completion rate indicates struggling performance
    /// - Parameter rate: The completion rate (0.0 to 1.0)
    /// - Returns: True if struggling, false otherwise
    public static func isStrugglingPerformance(_ rate: Double) -> Bool {
        return rate < strugglingCompletionRate
    }
    
    /// Checks if a streak length should be highlighted
    /// - Parameter streak: The streak length in days
    /// - Returns: True if should be highlighted, false otherwise
    public static func shouldHighlightStreak(_ streak: Int) -> Bool {
        return streak >= streakHighlightThreshold
    }
}
