//
//  PersonalityProfileModel.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import Foundation
import SwiftData

/// SwiftData model for storing personality profiles
@Model
public final class PersonalityProfileModel {
    @Attribute(.unique) public var id: String
    public var userId: String
    public var analysisDate: Date
    public var dominantTraitRawValue: String
    public var confidenceRawValue: String
    public var version: String
    public var dataPointsAnalyzed: Int
    public var timeRangeAnalyzed: Int
    
    // Trait scores stored as separate properties for SwiftData compatibility
    public var opennessScore: Double
    public var conscientiousnessScore: Double
    public var extraversionScore: Double
    public var agreeablenessScore: Double
    public var neuroticismScore: Double
    
    public init(
        id: String,
        userId: String,
        analysisDate: Date,
        dominantTraitRawValue: String,
        confidenceRawValue: String,
        version: String,
        dataPointsAnalyzed: Int,
        timeRangeAnalyzed: Int,
        opennessScore: Double,
        conscientiousnessScore: Double,
        extraversionScore: Double,
        agreeablenessScore: Double,
        neuroticismScore: Double
    ) {
        self.id = id
        self.userId = userId
        self.analysisDate = analysisDate
        self.dominantTraitRawValue = dominantTraitRawValue
        self.confidenceRawValue = confidenceRawValue
        self.version = version
        self.dataPointsAnalyzed = dataPointsAnalyzed
        self.timeRangeAnalyzed = timeRangeAnalyzed
        self.opennessScore = opennessScore
        self.conscientiousnessScore = conscientiousnessScore
        self.extraversionScore = extraversionScore
        self.agreeablenessScore = agreeablenessScore
        self.neuroticismScore = neuroticismScore
    }
    
    /// Convert SwiftData model to domain entity
    public func toEntity() -> PersonalityProfile? {
        guard let dominantTrait = PersonalityTrait(rawValue: dominantTraitRawValue),
              let confidence = ConfidenceLevel(rawValue: confidenceRawValue) else {
            return nil
        }
        
        let traitScores: [PersonalityTrait: Double] = [
            .openness: opennessScore,
            .conscientiousness: conscientiousnessScore,
            .extraversion: extraversionScore,
            .agreeableness: agreeablenessScore,
            .neuroticism: neuroticismScore
        ]
        
        let metadata = AnalysisMetadata(
            analysisDate: analysisDate,
            dataPointsAnalyzed: dataPointsAnalyzed,
            timeRangeAnalyzed: timeRangeAnalyzed,
            version: version
        )
        
        return PersonalityProfile(
            id: UUID(uuidString: id) ?? UUID(),
            userId: UUID(uuidString: userId) ?? UUID(),
            traitScores: traitScores,
            dominantTrait: dominantTrait,
            confidence: confidence,
            analysisMetadata: metadata
        )
    }
    
    /// Create SwiftData model from domain entity
    public static func fromEntity(_ entity: PersonalityProfile) -> PersonalityProfileModel {
        return PersonalityProfileModel(
            id: entity.id.uuidString,
            userId: entity.userId.uuidString,
            analysisDate: entity.analysisMetadata.analysisDate,
            dominantTraitRawValue: entity.dominantTrait.rawValue,
            confidenceRawValue: entity.confidence.rawValue,
            version: entity.analysisMetadata.version,
            dataPointsAnalyzed: entity.analysisMetadata.dataPointsAnalyzed,
            timeRangeAnalyzed: entity.analysisMetadata.timeRangeAnalyzed,
            opennessScore: entity.traitScores[.openness] ?? 0.5,
            conscientiousnessScore: entity.traitScores[.conscientiousness] ?? 0.5,
            extraversionScore: entity.traitScores[.extraversion] ?? 0.5,
            agreeablenessScore: entity.traitScores[.agreeableness] ?? 0.5,
            neuroticismScore: entity.traitScores[.neuroticism] ?? 0.5
        )
    }
}