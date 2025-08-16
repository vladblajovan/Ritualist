//
//  ValidateAnalysisDataUseCase.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import Foundation
import RitualistCore

/// Use case for validating if user has sufficient data for personality analysis
public protocol ValidateAnalysisDataUseCase {
    /// Check if user meets all requirements for personality analysis
    func execute(for userId: UUID) async throws -> AnalysisEligibility
    
    /// Get detailed progress towards meeting requirements
    func getProgressDetails(for userId: UUID) async throws -> [ThresholdRequirement]
    
    /// Get estimated days until analysis becomes available
    func getEstimatedDaysToEligibility(for userId: UUID) async throws -> Int?
}

public final class DefaultValidateAnalysisDataUseCase: ValidateAnalysisDataUseCase {
    
    private let repository: PersonalityAnalysisRepositoryProtocol
    private let thresholdValidator: DataThresholdValidator
    
    public init(
        repository: PersonalityAnalysisRepositoryProtocol,
        thresholdValidator: DataThresholdValidator
    ) {
        self.repository = repository
        self.thresholdValidator = thresholdValidator
    }
    
    public func execute(for userId: UUID) async throws -> AnalysisEligibility {
        return try await repository.validateAnalysisEligibility(for: userId)
    }
    
    public func getProgressDetails(for userId: UUID) async throws -> [ThresholdRequirement] {
        return try await repository.getThresholdProgress(for: userId)
    }
    
    public func getEstimatedDaysToEligibility(for userId: UUID) async throws -> Int? {
        let requirements = try await getProgressDetails(for: userId)
        
        // Calculate based on missing tracking days and creation needs
        var maxDaysNeeded = 0
        
        for requirement in requirements where !requirement.isMet {
            switch requirement.category {
            case .tracking:
                // Assume user needs to track consistently for remaining days
                let daysNeeded = requirement.requiredValue - requirement.currentValue
                maxDaysNeeded = max(maxDaysNeeded, daysNeeded)
                
            case .habits, .customization:
                // Assume user can create habits/categories immediately but needs tracking time
                maxDaysNeeded = max(maxDaysNeeded, 1)
                
            case .diversity:
                // Diversity improvements might take a few days to establish
                maxDaysNeeded = max(maxDaysNeeded, 3)
            }
        }
        
        return maxDaysNeeded > 0 ? maxDaysNeeded : nil
    }
}