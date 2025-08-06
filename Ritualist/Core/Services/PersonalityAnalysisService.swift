//
//  PersonalityAnalysisService.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import Foundation

/// Service responsible for analyzing user behavior and calculating personality traits
public protocol PersonalityAnalysisService {
    /// Perform comprehensive personality analysis for a user
    func analyzePersonality(for userId: UUID) async throws -> PersonalityProfile
    
    /// Calculate personality scores from habit analysis input
    func calculatePersonalityScores(from input: HabitAnalysisInput) -> [PersonalityTrait: Double]
    
    /// Determine dominant trait from scores
    func determineDominantTrait(from scores: [PersonalityTrait: Double]) -> PersonalityTrait
    
    /// Calculate confidence level for analysis
    func calculateConfidence(from metadata: AnalysisMetadata) -> ConfidenceLevel
}

public final class DefaultPersonalityAnalysisService: PersonalityAnalysisService {
    
    private let repository: PersonalityAnalysisRepositoryProtocol
    
    public init(repository: PersonalityAnalysisRepositoryProtocol) {
        self.repository = repository
    }
    
    public func analyzePersonality(for userId: UUID) async throws -> PersonalityProfile {
        // Get input data for analysis
        let input = try await repository.getHabitAnalysisInput(for: userId)
        
        // Calculate personality scores
        let traitScores = calculatePersonalityScores(from: input)
        
        // Determine dominant trait
        let dominantTrait = determineDominantTrait(from: traitScores)
        
        // Create metadata
        let metadata = AnalysisMetadata(
            analysisDate: Date(),
            dataPointsAnalyzed: input.totalDataPoints,
            timeRangeAnalyzed: input.analysisTimeRange,
            version: "1.0"
        )
        
        // Calculate confidence
        let confidence = calculateConfidence(from: metadata)
        
        // Create profile
        let profile = PersonalityProfile(
            id: UUID(),
            userId: userId,
            traitScores: traitScores,
            dominantTrait: dominantTrait,
            confidence: confidence,
            analysisMetadata: metadata
        )
        
        return profile
    }
    
    public func calculatePersonalityScores(from input: HabitAnalysisInput) -> [PersonalityTrait: Double] {
        var traitAccumulators: [PersonalityTrait: Double] = [
            .openness: 0.0,
            .conscientiousness: 0.0,
            .extraversion: 0.0,
            .agreeableness: 0.0,
            .neuroticism: 0.0
        ]
        
        var totalWeights: [PersonalityTrait: Double] = [
            .openness: 0.0,
            .conscientiousness: 0.0,
            .extraversion: 0.0,
            .agreeableness: 0.0,
            .neuroticism: 0.0
        ]
        
        // Analyze habit selections from suggestions
        for suggestion in input.selectedSuggestions {
            guard let weights = suggestion.personalityWeights else { continue }
            
            for (traitKey, weight) in weights {
                if let trait = PersonalityTrait(rawValue: traitKey) {
                    traitAccumulators[trait, default: 0.0] += weight
                    totalWeights[trait, default: 0.0] += abs(weight)
                }
            }
        }
        
        // Analyze custom habit categories
        for category in input.customCategories {
            guard let weights = category.personalityWeights else { continue }
            
            let categoryHabits = input.customHabits.filter { $0.categoryId == category.id }
            let categoryWeight = Double(categoryHabits.count) / Double(max(input.customHabits.count, 1))
            
            for (traitKey, weight) in weights {
                if let trait = PersonalityTrait(rawValue: traitKey) {
                    traitAccumulators[trait, default: 0.0] += weight * categoryWeight
                    totalWeights[trait, default: 0.0] += abs(weight * categoryWeight)
                }
            }
        }
        
        // Analyze completion rates (high conscientiousness for consistent tracking)
        let avgCompletionRate = input.completionRates.reduce(0.0, +) / Double(max(input.completionRates.count, 1))
        let conscientiousnessBonus = (avgCompletionRate - 0.5) * 0.3 // Scale to -0.15 to 0.15
        traitAccumulators[.conscientiousness, default: 0.0] += conscientiousnessBonus
        totalWeights[.conscientiousness, default: 0.0] += 0.3
        
        // Analyze habit diversity (openness to experience)
        let diversityScore = Double(input.habitCategories.count) / 10.0 // Normalize to 0-1+ range
        let opennessBonus = min(diversityScore, 1.0) * 0.2
        traitAccumulators[.openness, default: 0.0] += opennessBonus
        totalWeights[.openness, default: 0.0] += 0.2
        
        // Analyze scheduling patterns (extraversion for social/evening habits)
        let socialHabits = input.customHabits.filter { habit in
            habit.name.localizedCaseInsensitiveContains("social") ||
            habit.name.localizedCaseInsensitiveContains("meet") ||
            habit.name.localizedCaseInsensitiveContains("friend")
        }
        
        if !input.customHabits.isEmpty {
            let socialRatio = Double(socialHabits.count) / Double(input.customHabits.count)
            let extraversionBonus = socialRatio * 0.25
            traitAccumulators[.extraversion, default: 0.0] += extraversionBonus
            totalWeights[.extraversion, default: 0.0] += 0.25
        }
        
        // Normalize scores to 0.0-1.0 range
        var normalizedScores: [PersonalityTrait: Double] = [:]
        for trait in PersonalityTrait.allCases {
            let accumulator = traitAccumulators[trait, default: 0.0]
            let totalWeight = totalWeights[trait, default: 0.0]
            
            if totalWeight > 0 {
                // Convert from -1 to 1 range to 0 to 1 range
                let normalizedScore = (accumulator / totalWeight + 1.0) / 2.0
                normalizedScores[trait] = max(0.0, min(1.0, normalizedScore))
            } else {
                // Default to neutral (0.5) if no data
                normalizedScores[trait] = 0.5
            }
        }
        
        return normalizedScores
    }
    
    public func determineDominantTrait(from scores: [PersonalityTrait: Double]) -> PersonalityTrait {
        return scores.max(by: { $0.value < $1.value })?.key ?? .conscientiousness
    }
    
    public func calculateConfidence(from metadata: AnalysisMetadata) -> ConfidenceLevel {
        let dataPoints = Double(metadata.dataPointsAnalyzed)
        
        // Confidence based on amount of data analyzed
        switch dataPoints {
        case 0..<50:
            return .low
        case 50..<150:
            return .medium
        case 150..<300:
            return .high
        default:
            return .high
        }
    }
}