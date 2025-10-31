//
//  HabitScheduleValidationError.swift
//  RitualistCore
//
//  Created by Claude on 16.08.2025.
//

import Foundation

/// Errors related to habit schedule validation during logging
public enum HabitScheduleValidationError: Error, LocalizedError, Equatable {
    /// The habit is not scheduled to be logged on the specified date
    case notScheduledForDate(habitName: String, reason: String)
    
    /// The habit schedule is invalid or corrupted
    case invalidSchedule(habitName: String)
    
    /// Habit not found or is inactive
    case habitUnavailable(habitName: String)
    
    /// User has already logged this habit today
    case alreadyLoggedToday(habitName: String)
    
    // MARK: - LocalizedError Conformance
    
    public var errorDescription: String? {
        switch self {
        case .notScheduledForDate(let habitName, let reason):
            return "Cannot log '\(habitName)': \(reason)"
        case .invalidSchedule(let habitName):
            return "Cannot log '\(habitName)': Invalid schedule configuration"
        case .habitUnavailable(let habitName):
            return "Cannot log '\(habitName)': Habit is not available for logging"
        case .alreadyLoggedToday(let habitName):
            return "'\(habitName)' already completed today"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .notScheduledForDate(_, let reason):
            return reason
        case .invalidSchedule:
            return "The habit's schedule configuration is invalid"
        case .habitUnavailable:
            return "The habit is either inactive or does not exist"
        case .alreadyLoggedToday:
            return "You have already completed this habit today"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .notScheduledForDate:
            return "Check your habit's schedule settings or try logging on a different day."
        case .invalidSchedule:
            return "Edit the habit's schedule settings to fix the configuration."
        case .habitUnavailable:
            return "Ensure the habit exists and is active before attempting to log."
        case .alreadyLoggedToday:
            return "You can only complete this habit once per day. Try again tomorrow!"
        }
    }
}

// MARK: - Convenience Factory Methods

public extension HabitScheduleValidationError {
    /// Creates a notScheduledForDate error from a validation result
    static func fromValidationResult(_ result: HabitScheduleValidationResult, habitName: String) -> HabitScheduleValidationError {
        let reason = result.reason ?? "Not scheduled for this date"
        return .notScheduledForDate(habitName: habitName, reason: reason)
    }
}