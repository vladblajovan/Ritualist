//
//  DataThresholdValidator.swift
//  RitualistCore
//
//  Created by Claude on 16.08.2025.
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