//
//  BusinessRules.swift
//  RitualistCore
//
//  Created by Claude on 13.08.2025.
//

import Foundation

/// Centralized business rules and constants for the Ritualist application.
/// This ensures consistent behavior across all platforms (iOS, widgets, watch app).
public struct BusinessRules {
    
    // MARK: - Habit Limits
    
    /// Maximum number of habits allowed for free users
    public static let freeMaxHabits = 5
    
    /// Maximum number of habits allowed for premium users (unlimited)
    public static let premiumMaxHabits = Int.max
    
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
    
    // MARK: - Error Handling & Analytics
    
    /// Error log retention period in days
    public static let errorLogRetentionDays = 7
    
    /// Maximum number of errors to keep in memory
    public static let maxErrorLogSize = 100
    
    /// Time window for error rate calculations (24 hours)
    public static let errorRateTimeWindow: TimeInterval = 24 * 60 * 60
    
    /// Time window for recent error analysis (1 hour)
    public static let recentErrorTimeWindow: TimeInterval = 60 * 60
    
    // MARK: - Streak Calculation Rules
    
    /// Minimum streak length to display (1 day)
    public static let minDisplayableStreak = 1
    
    /// Streak length threshold for special highlighting (14 days)
    public static let streakHighlightThreshold = 14
    
    /// Perfect completion rate threshold (100%)
    public static let perfectCompletionRate = 1.0
    
    /// Struggling completion rate threshold (60%)
    public static let strugglingCompletionRate = 0.6
    
    // MARK: - Motivation & Engagement
    
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