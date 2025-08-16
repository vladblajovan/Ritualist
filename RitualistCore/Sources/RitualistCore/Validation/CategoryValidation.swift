//
//  CategoryValidation.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//


import Foundation

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
    public static func validateCategory(_ category: HabitCategory) -> ValidationResult {
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
