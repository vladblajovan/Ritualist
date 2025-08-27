//
//  AnalyzePersonalityUseCase.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import Foundation
import RitualistCore

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
    private let repository: PersonalityAnalysisRepositoryProtocol
    
    public init(
        personalityService: PersonalityAnalysisService,
        thresholdValidator: DataThresholdValidator,
        repository: PersonalityAnalysisRepositoryProtocol
    ) {
        self.personalityService = personalityService
        self.thresholdValidator = thresholdValidator
        self.repository = repository
    }
    
    public func execute(for userId: UUID) async throws -> PersonalityProfile {
        // First validate that analysis can be performed
        let canAnalyze = try await canPerformAnalysis(for: userId)
        guard canAnalyze else {
            throw PersonalityAnalysisError.insufficientData
        }
        
        // Business workflow: Get input data for analysis
        let input = try await repository.getHabitAnalysisInput(for: userId)
        
        // Get enhanced completion statistics with schedule-aware calculations
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        let completionStats = try await repository.getHabitCompletionStats(for: userId, from: startDate, to: endDate)
        
        // Calculate personality scores using Service as utility
        let traitScores = personalityService.calculatePersonalityScores(from: input)
        
        // Determine dominant trait using Service as utility
        let dominantTrait = personalityService.determineDominantTrait(from: traitScores)
        
        // Create metadata (business logic)
        let enhancedDataPoints = input.totalDataPoints + (completionStats.totalHabits > 0 ? 10 : 0)
        let metadata = AnalysisMetadata(
            analysisDate: Date(),
            dataPointsAnalyzed: enhancedDataPoints,
            timeRangeAnalyzed: input.analysisTimeRange,
            version: "1.6"
        )
        
        // Calculate confidence using Service as utility
        let confidence = personalityService.calculateConfidence(from: metadata)
        
        // Create the profile (business logic)
        let profile = PersonalityProfile(
            id: UUID(),
            userId: userId,
            traitScores: traitScores,
            dominantTrait: dominantTrait,
            confidence: confidence,
            analysisMetadata: metadata
        )
        
        // Save the profile to the database
        try await repository.savePersonalityProfile(profile)
        
        return profile
    }
    
    public func canPerformAnalysis(for userId: UUID) async throws -> Bool {
        let eligibility = try await thresholdValidator.validateEligibility(for: userId)
        return eligibility.isEligible
    }
}

