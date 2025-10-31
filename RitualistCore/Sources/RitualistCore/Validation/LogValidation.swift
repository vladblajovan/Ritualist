//
//  LogValidation.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//


import Foundation

/// Centralized validation for habit log operations
public struct LogValidation {
    
    /// Validates a habit log value
    /// - Parameters:
    ///   - value: The log value to validate
    ///   - habit: The habit this log belongs to
    /// - Returns: Validation result with specific error message if invalid
    public static func validateLogValue(_ value: Double?, for habit: Habit) -> ValidationResult {
        switch habit.kind {
        case .binary:
            // Binary habits should have value 0 or 1
            if let value = value {
                if value < 0 {
                    return .invalid(reason: "Binary habit value cannot be negative")
                }
                if value > 1 {
                    return .invalid(reason: "Binary habit value cannot exceed 1")
                }
            }
            return .valid
            
        case .numeric:
            // Numeric habits should have positive values
            if let value = value {
                if value < 0 {
                    return .invalid(reason: "Numeric habit value cannot be negative")
                }
                if value > BusinessConstants.maxDailyTarget {
                    return .invalid(reason: "Habit value cannot exceed \(BusinessConstants.maxDailyTarget)")
                }
            } else {
                return .invalid(reason: "Numeric habit must have a value")
            }
            return .valid
        }
    }
    
    /// Validates a habit log date
    /// - Parameter date: The log date to validate
    /// - Returns: Validation result with specific error message if invalid
    public static func validateLogDate(_ date: Date) -> ValidationResult {
        let now = Date()
        
        // Don't allow future dates beyond today
        let todayUTC = CalendarUtils.startOfDayUTC(for: now)
        let logDateUTC = CalendarUtils.startOfDayUTC(for: date)
        if logDateUTC > todayUTC {
            return .invalid(reason: "Cannot log habits for future dates")
        }
        
        // Don't allow dates too far in the past (1 year)
        let oneYearAgo = CalendarUtils.addYears(-1, to: now)
        if date < oneYearAgo {
            return .invalid(reason: "Cannot log habits more than one year in the past")
        }
        
        return .valid
    }
    
    /// Validates a complete habit log
    /// - Parameters:
    ///   - log: The habit log to validate
    ///   - habit: The habit this log belongs to
    /// - Returns: Validation result with specific error message if invalid
    public static func validateLog(_ log: HabitLog, for habit: Habit) -> ValidationResult {
        // Validate date
        let dateResult = validateLogDate(log.date)
        if !dateResult.isValid {
            return dateResult
        }
        
        // Validate value
        let valueResult = validateLogValue(log.value, for: habit)
        if !valueResult.isValid {
            return valueResult
        }
        
        return .valid
    }
}
