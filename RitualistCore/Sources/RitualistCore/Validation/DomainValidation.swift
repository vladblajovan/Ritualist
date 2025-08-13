//
//  DomainValidation.swift
//  RitualistCore
//
//  Created by Claude on 13.08.2025.
//

import Foundation

// MARK: - Validation Result

/// Result of a domain validation operation
public enum ValidationResult {
    case valid
    case invalid(reason: String)
    
    /// Whether the validation passed
    public var isValid: Bool {
        switch self {
        case .valid: return true
        case .invalid: return false
        }
    }
    
    /// The validation error message, if any
    public var errorMessage: String? {
        switch self {
        case .valid: return nil
        case .invalid(let reason): return reason
        }
    }
}

// MARK: - Habit Validation

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
        
        if name.count > BusinessRules.habitNameMaxLength {
            return .invalid(reason: "Habit name cannot exceed \(BusinessRules.habitNameMaxLength) characters")
        }
        
        return .valid
    }
    
    /// Validates a daily target value for numeric habits
    /// - Parameter target: The daily target to validate
    /// - Returns: Validation result with specific error message if invalid
    public static func validateDailyTarget(_ target: Double) -> ValidationResult {
        if target < BusinessRules.minDailyTarget {
            return .invalid(reason: "Daily target must be at least \(BusinessRules.minDailyTarget)")
        }
        
        if target > BusinessRules.maxDailyTarget {
            return .invalid(reason: "Daily target cannot exceed \(BusinessRules.maxDailyTarget)")
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
            
        case .timesPerWeek(let times):
            if times <= 0 {
                return .invalid(reason: "Times per week must be greater than 0")
            }
            
            if times > 7 {
                return .invalid(reason: "Times per week cannot exceed 7")
            }
            
            return .valid
        }
    }
    
    /// Validates a unit label for numeric habits
    /// - Parameter label: The unit label to validate
    /// - Returns: Validation result with specific error message if invalid
    public static func validateUnitLabel(_ label: String) -> ValidationResult {
        if label.count > BusinessRules.habitUnitLabelMaxLength {
            return .invalid(reason: "Unit label cannot exceed \(BusinessRules.habitUnitLabelMaxLength) characters")
        }
        
        return .valid
    }
    
    /// Validates an emoji field
    /// - Parameter emoji: The emoji string to validate
    /// - Returns: Validation result with specific error message if invalid
    public static func validateEmoji(_ emoji: String) -> ValidationResult {
        if emoji.count > BusinessRules.maxEmojiLength {
            return .invalid(reason: "Emoji field cannot exceed \(BusinessRules.maxEmojiLength) characters")
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

// MARK: - Category Validation

/// Centralized validation for category-related operations  
public struct CategoryValidation {
    
    /// Maximum length for category names
    public static let maxCategoryNameLength = 30
    
    /// Validates a category name
    /// - Parameter name: The category name to validate
    /// - Returns: Validation result with specific error message if invalid
    public static func validateName(_ name: String) -> ValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return .invalid(reason: "Category name cannot be empty")
        }
        
        if name.count > maxCategoryNameLength {
            return .invalid(reason: "Category name cannot exceed \(maxCategoryNameLength) characters")
        }
        
        return .valid
    }
    
    /// Validates category emoji
    /// - Parameter emoji: The category emoji to validate
    /// - Returns: Validation result with specific error message if invalid
    public static func validateEmoji(_ emoji: String) -> ValidationResult {
        return HabitValidation.validateEmoji(emoji)
    }
    
    /// Validates a complete category configuration
    /// - Parameter category: The category to validate
    /// - Returns: Validation result with specific error message if invalid
    public static func validateCategory(_ category: Category) -> ValidationResult {
        // Validate name
        let nameResult = validateName(category.name)
        if !nameResult.isValid {
            return nameResult
        }
        
        // Validate emoji
        let emojiResult = validateEmoji(category.emoji)
        if !emojiResult.isValid {
            return emojiResult
        }
        
        return .valid
    }
}

// MARK: - Log Validation

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
                if value > BusinessRules.maxDailyTarget {
                    return .invalid(reason: "Habit value cannot exceed \(BusinessRules.maxDailyTarget)")
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
        let calendar = Calendar.current
        
        // Don't allow future dates beyond today
        if calendar.compare(date, to: now, toGranularity: .day) == .orderedDescending {
            return .invalid(reason: "Cannot log habits for future dates")
        }
        
        // Don't allow dates too far in the past (1 year)
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
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

// MARK: - Personality Analysis Validation

/// Centralized validation for personality analysis requirements
public struct PersonalityAnalysisValidation {
    
    /// Validates if user meets minimum requirements for personality analysis
    /// - Parameters:
    ///   - activeHabitsCount: Number of active habits
    ///   - trackingDays: Number of consecutive tracking days
    ///   - customCategoriesCount: Number of custom categories
    ///   - customHabitsCount: Number of custom habits
    ///   - completionRate: Overall completion rate (0.0 to 1.0)
    ///   - habitDiversity: Number of different categories used
    /// - Returns: Validation result with specific error message if invalid
    public static func validateAnalysisEligibility(
        activeHabitsCount: Int,
        trackingDays: Int,
        customCategoriesCount: Int,
        customHabitsCount: Int,
        completionRate: Double,
        habitDiversity: Int
    ) -> ValidationResult {
        
        var missingRequirements: [String] = []
        
        if activeHabitsCount < BusinessRules.minActiveHabitsForAnalysis {
            missingRequirements.append("Need \(BusinessRules.minActiveHabitsForAnalysis - activeHabitsCount) more active habits")
        }
        
        if trackingDays < BusinessRules.minTrackingDaysForAnalysis {
            missingRequirements.append("Need \(BusinessRules.minTrackingDaysForAnalysis - trackingDays) more tracking days")
        }
        
        if customCategoriesCount < BusinessRules.minCustomCategoriesForAnalysis {
            missingRequirements.append("Need \(BusinessRules.minCustomCategoriesForAnalysis - customCategoriesCount) more custom categories")
        }
        
        if customHabitsCount < BusinessRules.minCustomHabitsForAnalysis {
            missingRequirements.append("Need \(BusinessRules.minCustomHabitsForAnalysis - customHabitsCount) more custom habits")
        }
        
        if completionRate < BusinessRules.minCompletionRateForAnalysis {
            let neededRate = Int((BusinessRules.minCompletionRateForAnalysis - completionRate) * 100)
            missingRequirements.append("Need \(neededRate)% higher completion rate")
        }
        
        if habitDiversity < BusinessRules.minHabitDiversityForAnalysis {
            missingRequirements.append("Need habits in \(BusinessRules.minHabitDiversityForAnalysis - habitDiversity) more categories")
        }
        
        if missingRequirements.isEmpty {
            return .valid
        } else {
            let message = "Personality analysis requirements not met: " + missingRequirements.joined(separator: ", ")
            return .invalid(reason: message)
        }
    }
}

// MARK: - Composite Validation

/// High-level validation coordinator for complex operations
public struct DomainValidation {
    
    /// Validates multiple aspects of domain state
    /// - Parameters:
    ///   - habits: Array of habits to validate
    ///   - categories: Array of categories to validate
    ///   - userHabitCount: Current number of user habits
    ///   - isPremiumUser: Whether user has premium access
    /// - Returns: Validation result with comprehensive error message if invalid
    public static func validateDomainState(
        habits: [Habit],
        categories: [Category],
        userHabitCount: Int,
        isPremiumUser: Bool
    ) -> ValidationResult {
        
        var issues: [String] = []
        
        // Validate habit limit
        let habitLimit = isPremiumUser ? BusinessRules.premiumMaxHabits : BusinessRules.freeMaxHabits
        if userHabitCount > habitLimit {
            if !isPremiumUser {
                issues.append("Exceeded free habit limit of \(BusinessRules.freeMaxHabits)")
            }
        }
        
        // Validate each habit
        for (index, habit) in habits.enumerated() {
            let habitResult = HabitValidation.validateHabit(habit)
            if !habitResult.isValid {
                issues.append("Habit \(index + 1): \(habitResult.errorMessage ?? "Invalid")")
            }
        }
        
        // Validate each category
        for (index, category) in categories.enumerated() {
            let categoryResult = CategoryValidation.validateCategory(category)
            if !categoryResult.isValid {
                issues.append("Category \(index + 1): \(categoryResult.errorMessage ?? "Invalid")")
            }
        }
        
        if issues.isEmpty {
            return .valid
        } else {
            return .invalid(reason: issues.joined(separator: "; "))
        }
    }
}