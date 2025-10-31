//
//  HabitValidation.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//

import Foundation

/// Centralized validation for habit-related operations
public struct HabitValidation {
    
    /// Validates a habit name
    /// - Parameter name: The habit name to validate
    /// - Returns: Validation result with specific error message if invalid
    public static func validateName(_ name: String) -> ValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return .invalid(reason: "Habit name cannot be empty")
        }
        
        if name.count > BusinessConstants.habitNameMaxLength {
            return .invalid(reason: "Habit name cannot exceed \(BusinessConstants.habitNameMaxLength) characters")
        }
        
        return .valid
    }
    
    /// Validates a daily target value for numeric habits
    /// - Parameter target: The daily target to validate
    /// - Returns: Validation result with specific error message if invalid
    public static func validateDailyTarget(_ target: Double) -> ValidationResult {
        if target < BusinessConstants.minDailyTarget {
            return .invalid(reason: "Daily target must be at least \(BusinessConstants.minDailyTarget)")
        }
        
        if target > BusinessConstants.maxDailyTarget {
            return .invalid(reason: "Daily target cannot exceed \(BusinessConstants.maxDailyTarget)")
        }
        
        return .valid
    }
    
    /// Validates a habit schedule
    /// - Parameter schedule: The habit schedule to validate
    /// - Returns: Validation result with specific error message if invalid
    public static func validateSchedule(_ schedule: HabitSchedule) -> ValidationResult {
        switch schedule {
        case .daily:
            return .valid
            
        case .daysOfWeek(let days):
            if days.isEmpty {
                return .invalid(reason: "At least one day must be selected for weekly schedule")
            }
            
            let validDays = Set(1...7)
            let invalidDays = Set(days).subtracting(validDays)
            if !invalidDays.isEmpty {
                return .invalid(reason: "Invalid weekday values: \(invalidDays.sorted())")
            }
            
            return .valid
            
        }
    }
    
    /// Validates a unit label for numeric habits
    /// - Parameter label: The unit label to validate
    /// - Returns: Validation result with specific error message if invalid
    public static func validateUnitLabel(_ label: String) -> ValidationResult {
        if label.count > BusinessConstants.habitUnitLabelMaxLength {
            return .invalid(reason: "Unit label cannot exceed \(BusinessConstants.habitUnitLabelMaxLength) characters")
        }
        
        return .valid
    }
    
    /// Validates an emoji field
    /// - Parameter emoji: The emoji string to validate
    /// - Returns: Validation result with specific error message if invalid
    public static func validateEmoji(_ emoji: String) -> ValidationResult {
        if emoji.count > BusinessConstants.maxEmojiLength {
            return .invalid(reason: "Emoji field cannot exceed \(BusinessConstants.maxEmojiLength) characters")
        }
        
        return .valid
    }
    
    /// Validates a complete habit configuration
    /// - Parameter habit: The habit to validate
    /// - Returns: Validation result with specific error message if invalid
    public static func validateHabit(_ habit: Habit) -> ValidationResult {
        // Validate name
        let nameResult = validateName(habit.name)
        if !nameResult.isValid {
            return nameResult
        }
        
        // Validate emoji (if present)
        if let emoji = habit.emoji {
            let emojiResult = validateEmoji(emoji)
            if !emojiResult.isValid {
                return emojiResult
            }
        }
        
        // Validate schedule
        let scheduleResult = validateSchedule(habit.schedule)
        if !scheduleResult.isValid {
            return scheduleResult
        }
        
        // Validate daily target for numeric habits
        if case .numeric = habit.kind, let target = habit.dailyTarget {
            let targetResult = validateDailyTarget(target)
            if !targetResult.isValid {
                return targetResult
            }
        }
        
        // Validate unit label for numeric habits
        if case .numeric = habit.kind, let label = habit.unitLabel {
            let labelResult = validateUnitLabel(label)
            if !labelResult.isValid {
                return labelResult
            }
        }
        
        return .valid
    }
}
