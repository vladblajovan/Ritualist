//
//  HabitScheduleValidationResult.swift
//  RitualistCore
//
//  Created by Claude on 16.08.2025.
//

import Foundation

/// Result of habit schedule validation for a specific date
public struct HabitScheduleValidationResult {
    /// Whether the habit can be logged on the specified date
    public let isValid: Bool
    
    /// User-facing error message if validation fails
    public let reason: String?
    
    public init(isValid: Bool, reason: String? = nil) {
        self.isValid = isValid
        self.reason = reason
    }
}

// MARK: - Convenience Factory Methods

public extension HabitScheduleValidationResult {
    /// Creates a valid result (habit can be logged)
    static func valid() -> HabitScheduleValidationResult {
        return HabitScheduleValidationResult(isValid: true, reason: nil)
    }
    
    /// Creates an invalid result with a user-facing error message
    static func invalid(reason: String) -> HabitScheduleValidationResult {
        return HabitScheduleValidationResult(isValid: false, reason: reason)
    }
}

// MARK: - UI Helper Properties

public extension HabitScheduleValidationResult {
    /// Whether logging should be disabled in the UI
    var shouldDisableLogging: Bool {
        return !isValid
    }
    
    /// User-friendly message for display in UI (empty string if valid)
    var userMessage: String {
        return reason ?? ""
    }
}