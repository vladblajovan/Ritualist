//
//  AnalyzePersonalityUseCase.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import Foundation

/// Use case for performing personality analysis
public protocol AnalyzePersonalityUseCase {
    /// Perform personality analysis for a user
    func execute(for userId: UUID) async throws -> PersonalityProfile
    
    /// Check if analysis can be performed (meets thresholds)
    func canPerformAnalysis(for userId: UUID) async throws -> Bool
}

public final class DefaultAnalyzePersonalityUseCase: AnalyzePersonalityUseCase {
    
    private let personalityService: PersonalityAnalysisService
    private let thresholdValidator: DataThresholdValidator
    
    public init(
        personalityService: PersonalityAnalysisService,
        thresholdValidator: DataThresholdValidator
    ) {
        self.personalityService = personalityService
        self.thresholdValidator = thresholdValidator
    }
    
    public func execute(for userId: UUID) async throws -> PersonalityProfile {
        // First validate that analysis can be performed
        let canAnalyze = try await canPerformAnalysis(for: userId)
        guard canAnalyze else {
            throw PersonalityAnalysisError.insufficientData
        }
        
        // Perform the analysis using the service
        let profile = try await personalityService.analyzePersonality(for: userId)
        
        return profile
    }
    
    public func canPerformAnalysis(for userId: UUID) async throws -> Bool {
        let eligibility = try await thresholdValidator.validateEligibility(for: userId)
        return eligibility.isEligible
    }
}

