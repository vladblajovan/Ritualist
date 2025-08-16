//
//  DomainValidation.swift
//  RitualistCore
//
//  Created by Claude on 13.08.2025.
//

import Foundation

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
        categories: [HabitCategory],
        userHabitCount: Int,
        isPremiumUser: Bool
    ) -> ValidationResult {
        
        var issues: [String] = []
        
        // Validate habit limit
        let habitLimit = isPremiumUser ? BusinessConstants.premiumMaxHabits : BusinessConstants.freeMaxHabits
        if userHabitCount > habitLimit {
            if !isPremiumUser {
                issues.append("Exceeded free habit limit of \(BusinessConstants.freeMaxHabits)")
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
