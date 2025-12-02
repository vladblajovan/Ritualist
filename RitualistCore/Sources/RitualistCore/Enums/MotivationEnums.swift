//
//  MotivationEnums.swift
//  RitualistCore
//
//  Created by Claude on 13.08.2025.
//

import Foundation

/// Centralized motivation and inspiration logic for cross-platform use.
/// Supports widgets, watch complications, and main app motivation systems.

// MARK: - Inspiration Triggers

/// Defines when and why to show motivational content to users
public enum InspirationTrigger: CaseIterable, Hashable {
    case sessionStart          // First app open of the day
    case morningMotivation     // 0% completion in morning
    case firstHabitComplete    // Just completed first habit
    case halfwayPoint         // Hit 50% completion
    case strugglingMidDay     // <40% completion at noon
    case afternoonPush        // <60% completion in afternoon (3-4:59pm)
    case strongFinish         // Hit 75%+ completion
    case perfectDay           // 100% completion
    case eveningReflection    // Evening with good progress (>60%)
    case weekendMotivation    // Weekend-specific encouragement
    case comebackStory        // Improved from yesterday
    case emptyDay             // No habits scheduled for today (but user has habits on other days)
    
    /// Cooldown period in minutes before this trigger can fire again
    public var cooldownMinutes: Int {
        switch self {
        case .sessionStart, .perfectDay, .emptyDay:
            return 0  // No cooldown
        case .firstHabitComplete, .halfwayPoint, .strongFinish:
            return 60 // 1 hour cooldown
        case .morningMotivation, .strugglingMidDay, .afternoonPush:
            return 120 // 2 hour cooldown
        case .eveningReflection, .weekendMotivation, .comebackStory:
            return 180 // 3 hour cooldown
        }
    }
    
    /// Display name for debugging/analytics
    public var displayName: String {
        switch self {
        case .sessionStart: return "Session Start"
        case .morningMotivation: return "Morning Motivation"
        case .firstHabitComplete: return "First Habit Complete"
        case .halfwayPoint: return "Halfway Point"
        case .strugglingMidDay: return "Struggling Mid-Day"
        case .afternoonPush: return "Afternoon Push"
        case .strongFinish: return "Strong Finish"
        case .perfectDay: return "Perfect Day"
        case .eveningReflection: return "Evening Reflection"
        case .weekendMotivation: return "Weekend Motivation"
        case .comebackStory: return "Comeback Story"
        case .emptyDay: return "Empty Day"
        }
    }
    
    /// Priority level for trigger selection (higher = more important)
    public var priority: Int {
        switch self {
        case .perfectDay: return 100
        case .emptyDay: return 95  // High priority - takes precedence when no habits scheduled
        case .strongFinish: return 90
        case .comebackStory: return 80
        case .firstHabitComplete: return 70
        case .halfwayPoint: return 60
        case .afternoonPush: return 50
        case .strugglingMidDay: return 40
        case .morningMotivation: return 30
        case .eveningReflection: return 25
        case .weekendMotivation: return 20
        case .sessionStart: return 10
        }
    }
}

// MARK: - Inspiration Item

/// Model representing an inspiration item in the carousel
/// Each item has a unique message and slogan based on its trigger type
public struct InspirationItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let trigger: InspirationTrigger
    public let message: String
    public let slogan: String

    /// Creates an inspiration item with validated content
    /// Returns nil if message or slogan is empty after trimming whitespace
    public init?(id: UUID = UUID(), trigger: InspirationTrigger, message: String, slogan: String) {
        guard Self.isValid(message: message, slogan: slogan) else {
            return nil
        }
        self.id = id
        self.trigger = trigger
        self.message = message
        self.slogan = slogan
    }

    /// Validates that message and slogan are non-empty
    public static func isValid(message: String, slogan: String) -> Bool {
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !slogan.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Equality based on ID only - message/slogan changes don't change identity
    /// This aligns with SwiftUI's identity-based diffing for carousel animations
    public static func == (lhs: InspirationItem, rhs: InspirationItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Completion States

/// Represents different states of habit completion progress
public enum CompletionState {
    case notStarted        // 0% completion
    case minimal          // 1-25% completion
    case gettingStarted   // 26-50% completion
    case makingProgress   // 51-75% completion
    case almostThere      // 76-99% completion
    case completed        // 100% completion
    
    /// Create completion state from percentage
    /// - Parameter percentage: Completion percentage (0.0 to 1.0)
    /// - Returns: Corresponding completion state
    public static func from(percentage: Double) -> CompletionState {
        switch percentage {
        case 0.0:
            return .notStarted
        case 0.01...0.25:
            return .minimal
        case 0.26...0.50:
            return .gettingStarted
        case 0.51...0.75:
            return .makingProgress
        case 0.76...0.99:
            return .almostThere
        case 1.0...:
            return .completed
        default:
            return .notStarted
        }
    }
    
    /// User-friendly description
    public var description: String {
        switch self {
        case .notStarted: return "Not Started"
        case .minimal: return "Getting Started"
        case .gettingStarted: return "Building Momentum"
        case .makingProgress: return "Making Progress"
        case .almostThere: return "Almost There"
        case .completed: return "Completed"
        }
    }
    
    /// Color suggestion for UI representation
    public var colorHex: String {
        switch self {
        case .notStarted: return "#6C757D"      // Gray
        case .minimal: return "#FFC107"         // Yellow
        case .gettingStarted: return "#FD7E14"  // Orange
        case .makingProgress: return "#20C997"  // Teal
        case .almostThere: return "#0D6EFD"     // Blue
        case .completed: return "#28A745"       // Green
        }
    }
}

// MARK: - Time of Day Context

/// Defines time-based contexts for motivation
public enum TimeOfDayContext {
    case earlyMorning    // 5:00 - 8:00
    case morning         // 8:00 - 12:00
    case afternoon       // 12:00 - 17:00
    case evening         // 17:00 - 21:00
    case night           // 21:00 - 5:00
    
    /// Create context from current hour
    /// - Parameter hour: Hour in 24-hour format (0-23)
    /// - Returns: Corresponding time context
    public static func from(hour: Int) -> TimeOfDayContext {
        switch hour {
        case 5..<8:
            return .earlyMorning
        case 8..<12:
            return .morning
        case 12..<17:
            return .afternoon
        case 17..<21:
            return .evening
        default:
            return .night
        }
    }
    
    /// Typical motivation messages for this time
    public var motivationTone: String {
        switch self {
        case .earlyMorning: return "energizing"
        case .morning: return "productive"
        case .afternoon: return "encouraging"
        case .evening: return "reflective"
        case .night: return "restful"
        }
    }
}

// MARK: - Streak Milestone

/// Defines streak milestone achievements
public enum StreakMilestone {
    case started        // 1 day
    case weekStrong     // 7 days
    case twoWeeks       // 14 days
    case month          // 30 days
    case quarter        // 90 days
    case halfYear       // 180 days
    case year           // 365 days
    case legend         // 500+ days
    
    /// Create milestone from streak count
    /// - Parameter streak: Number of consecutive days
    /// - Returns: Highest achieved milestone
    public static func from(streak: Int) -> StreakMilestone? {
        guard streak >= 1 else { return nil }
        
        switch streak {
        case 500...:
            return .legend
        case 365...499:
            return .year
        case 180...364:
            return .halfYear
        case 90...179:
            return .quarter
        case 30...89:
            return .month
        case 14...29:
            return .twoWeeks
        case 7...13:
            return .weekStrong
        default:
            return .started
        }
    }
    
    /// Celebration message for achieving this milestone
    public var celebrationMessage: String {
        switch self {
        case .started: return "Great start! First day complete! 🎉"
        case .weekStrong: return "One week strong! You're building momentum! 💪"
        case .twoWeeks: return "Two weeks of consistency! Keep it up! 🔥"
        case .month: return "30 days! You've built a real habit! 🌟"
        case .quarter: return "3 months! This is becoming who you are! 🚀"
        case .halfYear: return "Half a year! Incredible dedication! 👑"
        case .year: return "365 days! You're a habit master! 🏆"
        case .legend: return "500+ days! You're a legend! 🎖️"
        }
    }
    
    /// Emoji representation
    public var emoji: String {
        switch self {
        case .started: return "🌱"
        case .weekStrong: return "💪"
        case .twoWeeks: return "🔥"
        case .month: return "⭐"
        case .quarter: return "🚀"
        case .halfYear: return "👑"
        case .year: return "🏆"
        case .legend: return "🎖️"
        }
    }
    
    /// Required streak count to achieve this milestone
    public var requiredStreak: Int {
        switch self {
        case .started: return 1
        case .weekStrong: return 7
        case .twoWeeks: return 14
        case .month: return 30
        case .quarter: return 90
        case .halfYear: return 180
        case .year: return 365
        case .legend: return 500
        }
    }
}

// MARK: - Motivation Utilities

/// Utility functions for motivation logic
public struct MotivationUtils {
    
    /// Determine appropriate inspiration trigger based on context
    /// - Parameters:
    ///   - completionRate: Current completion rate (0.0 to 1.0)
    ///   - timeContext: Time of day context
    ///   - isFirstOpen: Whether this is first app open today
    ///   - improvementFromYesterday: Whether completion improved from yesterday
    /// - Returns: Most appropriate inspiration trigger
    public static func selectTrigger(
        completionRate: Double,
        timeContext: TimeOfDayContext,
        isFirstOpen: Bool,
        improvementFromYesterday: Bool
    ) -> InspirationTrigger {
        
        // Priority order based on context
        if isFirstOpen {
            return .sessionStart
        }
        
        if completionRate >= 1.0 {
            return .perfectDay
        }
        
        if improvementFromYesterday && completionRate > 0.3 {
            return .comebackStory
        }
        
        if completionRate >= 0.75 {
            return .strongFinish
        }
        
        if completionRate >= 0.5 {
            return .halfwayPoint
        }
        
        // Time-based triggers
        switch timeContext {
        case .morning:
            return completionRate == 0 ? .morningMotivation : .firstHabitComplete
        case .afternoon:
            return completionRate < 0.6 ? .afternoonPush : .halfwayPoint
        case .evening:
            return completionRate > 0.6 ? .eveningReflection : .strugglingMidDay
        default:
            return .sessionStart
        }
    }
    
    /// Get motivational color based on completion rate
    /// - Parameter rate: Completion rate (0.0 to 1.0)
    /// - Returns: Hex color string for motivation UI
    public static func motivationColor(for rate: Double) -> String {
        return CompletionState.from(percentage: rate).colorHex
    }
    
    /// Check if streak deserves celebration
    /// - Parameter streak: Current streak count
    /// - Returns: True if this streak count is a milestone
    public static func isStreakMilestone(_ streak: Int) -> Bool {
        let milestones = [1, 7, 14, 30, 90, 180, 365, 500]
        return milestones.contains(streak)
    }
    
    /// Get next milestone target for a given streak
    /// - Parameter currentStreak: Current streak count
    /// - Returns: Next milestone to achieve, if any
    public static func nextMilestone(for currentStreak: Int) -> StreakMilestone? {
        let allMilestones: [StreakMilestone] = [.started, .weekStrong, .twoWeeks, .month, .quarter, .halfYear, .year, .legend]
        
        return allMilestones.first { milestone in
            milestone.requiredStreak > currentStreak
        }
    }
}

