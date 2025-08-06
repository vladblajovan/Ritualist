//
//  DataThresholdValidator.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import Foundation

/// Service for validating data thresholds required for personality analysis
public protocol DataThresholdValidator {
    /// Check if user meets minimum data requirements
    func validateEligibility(for userId: UUID) async throws -> AnalysisEligibility
    
    /// Get detailed progress for each requirement
    func getThresholdProgress(for userId: UUID) async throws -> [ThresholdRequirement]
    
    /// Check specific requirement
    func checkRequirement(_ requirement: RequirementCategory, for userId: UUID) async throws -> Bool
}

public final class DefaultDataThresholdValidator: DataThresholdValidator {
    
    private let repository: PersonalityAnalysisRepositoryProtocol
    
    // Minimum data thresholds
    private struct Thresholds {
        static let minActiveHabits = 5
        static let minTrackingDays = 7
        static let minCustomCategories = 3
        static let minCustomHabits = 3
        static let minCompletionRate = 0.3 // 30%
    }
    
    public init(repository: PersonalityAnalysisRepositoryProtocol) {
        self.repository = repository
    }
    
    public func validateEligibility(for userId: UUID) async throws -> AnalysisEligibility {
        let requirements = try await getThresholdProgress(for: userId)
        let unmetRequirements = requirements.filter { !$0.isMet }
        
        if unmetRequirements.isEmpty {
            return AnalysisEligibility(
                isEligible: true,
                missingRequirements: [],
                overallProgress: 1.0,
                estimatedDaysToEligibility: nil
            )
        } else {
            return AnalysisEligibility(
                isEligible: false,
                missingRequirements: unmetRequirements,
                overallProgress: 0.5,
                estimatedDaysToEligibility: calculateEstimatedDays(from: unmetRequirements)
            )
        }
    }
    
    public func getThresholdProgress(for userId: UUID) async throws -> [ThresholdRequirement] {
        let input = try await repository.getHabitAnalysisInput(for: userId)
        
        var requirements: [ThresholdRequirement] = []
        
        // Active habits requirement
        let activeHabitsCount = input.activeHabits.count
        requirements.append(ThresholdRequirement(
            name: "Active Habits",
            description: "Track at least \(Thresholds.minActiveHabits) active habits consistently",
            currentValue: activeHabitsCount,
            requiredValue: Thresholds.minActiveHabits,
            category: .habits
        ))
        
        // Tracking consistency requirement
        let trackingDays = input.trackingDays
        requirements.append(ThresholdRequirement(
            name: "Consistent Tracking",
            description: "Log habits for at least \(Thresholds.minTrackingDays) consecutive days",
            currentValue: trackingDays,
            requiredValue: Thresholds.minTrackingDays,
            category: .tracking
        ))
        
        // Custom categories requirement
        let customCategoriesCount = input.customCategories.count
        requirements.append(ThresholdRequirement(
            name: "Custom Categories",
            description: "Create at least \(Thresholds.minCustomCategories) custom habit categories",
            currentValue: customCategoriesCount,
            requiredValue: Thresholds.minCustomCategories,
            category: .customization
        ))
        
        // Custom habits requirement
        let customHabitsCount = input.customHabits.count
        requirements.append(ThresholdRequirement(
            name: "Custom Habits",
            description: "Create at least \(Thresholds.minCustomHabits) custom habits",
            currentValue: customHabitsCount,
            requiredValue: Thresholds.minCustomHabits,
            category: .customization
        ))
        
        // Completion rate requirement (overall engagement)
        let avgCompletionRate = input.completionRates.reduce(0.0, +) / Double(max(input.completionRates.count, 1))
        let completionRatePercent = Int(avgCompletionRate * 100)
        let requiredCompletionRatePercent = Int(Thresholds.minCompletionRate * 100)
        
        requirements.append(ThresholdRequirement(
            name: "Habit Completion Rate",
            description: "Maintain at least \(requiredCompletionRatePercent)% completion rate across all habits",
            currentValue: completionRatePercent,
            requiredValue: requiredCompletionRatePercent,
            category: .tracking
        ))
        
        // Habit diversity requirement (different categories)
        let diversityCount = input.habitCategories.count
        let minDiversity = 3 // At least 3 different categories
        requirements.append(ThresholdRequirement(
            name: "Habit Diversity",
            description: "Track habits across at least \(minDiversity) different categories",
            currentValue: diversityCount,
            requiredValue: minDiversity,
            category: .diversity
        ))
        
        return requirements
    }
    
    public func checkRequirement(_ requirement: RequirementCategory, for userId: UUID) async throws -> Bool {
        let requirements = try await getThresholdProgress(for: userId)
        return requirements.filter { $0.category == requirement }.allSatisfy { $0.isMet }
    }
    
    private func calculateEstimatedDays(from unmetRequirements: [ThresholdRequirement]) -> Int? {
        var maxDaysNeeded = 0
        
        for requirement in unmetRequirements {
            switch requirement.category {
            case .tracking:
                // For tracking requirements, user needs to track for remaining days
                let daysNeeded = requirement.requiredValue - requirement.currentValue
                maxDaysNeeded = max(maxDaysNeeded, max(0, daysNeeded))
                
            case .habits, .customization:
                // User can create habits/categories immediately but needs tracking time
                maxDaysNeeded = max(maxDaysNeeded, 1)
                
            case .diversity:
                // Diversity improvements might take a few days to establish
                maxDaysNeeded = max(maxDaysNeeded, 3)
            }
        }
        
        return maxDaysNeeded > 0 ? maxDaysNeeded : nil
    }
}