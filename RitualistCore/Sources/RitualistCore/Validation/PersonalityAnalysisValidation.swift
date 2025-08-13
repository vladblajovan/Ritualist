//
//  PersonalityAnalysisValidation.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//


import Foundation

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
        
        if activeHabitsCount < BusinessConstants.minActiveHabitsForAnalysis {
            missingRequirements.append("Need \(BusinessConstants.minActiveHabitsForAnalysis - activeHabitsCount) more active habits")
        }
        
        if trackingDays < BusinessConstants.minTrackingDaysForAnalysis {
            missingRequirements.append("Need \(BusinessConstants.minTrackingDaysForAnalysis - trackingDays) more tracking days")
        }
        
        if customCategoriesCount < BusinessConstants.minCustomCategoriesForAnalysis {
            missingRequirements.append("Need \(BusinessConstants.minCustomCategoriesForAnalysis - customCategoriesCount) more custom categories")
        }
        
        if customHabitsCount < BusinessConstants.minCustomHabitsForAnalysis {
            missingRequirements.append("Need \(BusinessConstants.minCustomHabitsForAnalysis - customHabitsCount) more custom habits")
        }
        
        if completionRate < BusinessConstants.minCompletionRateForAnalysis {
            let neededRate = Int((BusinessConstants.minCompletionRateForAnalysis - completionRate) * 100)
            missingRequirements.append("Need \(neededRate)% higher completion rate")
        }
        
        if habitDiversity < BusinessConstants.minHabitDiversityForAnalysis {
            missingRequirements.append("Need habits in \(BusinessConstants.minHabitDiversityForAnalysis - habitDiversity) more categories")
        }
        
        if missingRequirements.isEmpty {
            return .valid
        } else {
            let message = "Personality analysis requirements not met: " + missingRequirements.joined(separator: ", ")
            return .invalid(reason: message)
        }
    }
}
