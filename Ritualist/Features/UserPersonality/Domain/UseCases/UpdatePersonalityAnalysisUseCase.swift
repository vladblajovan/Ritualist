//
//  UpdatePersonalityAnalysisUseCase.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import Foundation
import RitualistCore

/// Use case for updating/refreshing personality analysis
public protocol UpdatePersonalityAnalysisUseCase {
    /// Refresh personality analysis and save new profile
    func execute(for userId: UUID) async throws -> PersonalityProfile
    
    /// Delete existing profile and generate new one
    func regenerateAnalysis(for userId: UUID) async throws -> PersonalityProfile
    
    /// Check if analysis needs to be updated (e.g., based on age of last analysis)
    func shouldUpdateAnalysis(for userId: UUID) async throws -> Bool
}

public final class DefaultUpdatePersonalityAnalysisUseCase: UpdatePersonalityAnalysisUseCase {
    
    private let repository: PersonalityAnalysisRepositoryProtocol
    private let analysisService: PersonalityAnalysisService
    
    // Update analysis if it's older than 7 days
    private let analysisValidityPeriod: TimeInterval = 7 * 24 * 60 * 60
    
    public init(
        repository: PersonalityAnalysisRepositoryProtocol,
        analysisService: PersonalityAnalysisService
    ) {
        self.repository = repository
        self.analysisService = analysisService
    }
    
    public func execute(for userId: UUID) async throws -> PersonalityProfile {
        // Generate new analysis
        let newProfile = try await analysisService.analyzePersonality(for: userId)
        
        // Save the new profile
        try await repository.savePersonalityProfile(newProfile)
        
        return newProfile
    }
    
    public func regenerateAnalysis(for userId: UUID) async throws -> PersonalityProfile {
        // Get existing profile to delete it
        if let existingProfile = try await repository.getPersonalityProfile(for: userId) {
            try await repository.deletePersonalityProfile(id: existingProfile.id)
        }
        
        // Generate and save new analysis
        return try await execute(for: userId)
    }
    
    public func shouldUpdateAnalysis(for userId: UUID) async throws -> Bool {
        guard let existingProfile = try await repository.getPersonalityProfile(for: userId) else {
            // No existing profile, should create one
            return true
        }
        
        let timeSinceAnalysis = Date().timeIntervalSince(existingProfile.analysisMetadata.analysisDate)
        
        // Update if analysis is older than validity period
        return timeSinceAnalysis > analysisValidityPeriod
    }
}