//
//  PersonalityProfile.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import Foundation

/// Represents a user's personality analysis profile
public struct PersonalityProfile: Identifiable, Codable, Hashable {
    public let id: UUID
    public let userId: UUID
    
    /// Trait scores (0.0 to 1.0) for each personality trait
    public let traitScores: [PersonalityTrait: Double]
    
    /// The dominant (highest scoring) personality trait
    public let dominantTrait: PersonalityTrait
    
    /// Overall confidence in the analysis
    public let confidence: ConfidenceLevel
    
    /// Analysis metadata for transparency
    public let analysisMetadata: AnalysisMetadata
    
    public init(
        id: UUID = UUID(),
        userId: UUID,
        traitScores: [PersonalityTrait: Double],
        dominantTrait: PersonalityTrait,
        confidence: ConfidenceLevel,
        analysisMetadata: AnalysisMetadata
    ) {
        self.id = id
        self.userId = userId
        
        // Normalize trait scores to 0.0-1.0 range
        self.traitScores = traitScores.mapValues { score in
            min(max(score, 0.0), 1.0)
        }
        
        self.dominantTrait = dominantTrait
        self.confidence = confidence
        self.analysisMetadata = analysisMetadata
    }
    
    /// Get score for a specific trait
    public func score(for trait: PersonalityTrait) -> Double {
        return traitScores[trait] ?? 0.0
    }
    
    /// Get confidence for a specific trait
    public func confidence(for trait: PersonalityTrait) -> ConfidenceLevel {
        return confidence
    }
    
    /// Get all traits sorted by score (highest first)
    public var traitsByScore: [(trait: PersonalityTrait, score: Double)] {
        return traitScores.sorted { $0.value > $1.value }
            .map { (trait: $0.key, score: $0.value) }
    }
    
    /// Get traits that score above a threshold
    public func traits(above threshold: Double) -> [PersonalityTrait] {
        return traitScores.compactMap { (trait, score) in
            score > threshold ? trait : nil
        }
    }
    
    /// Get the secondary (second highest) trait
    public var secondaryTrait: PersonalityTrait? {
        return traitsByScore.count > 1 ? traitsByScore[1].trait : nil
    }
    
    /// Check if the analysis is recent (within specified days)
    public func isRecent(within days: Int) -> Bool {
        let daysSinceAnalysis = Calendar.current.dateComponents([.day], from: analysisMetadata.analysisDate, to: Date()).day ?? 0
        return daysSinceAnalysis <= days
    }
    
    /// Get a summary description of the personality profile
    public var summary: String {
        let dominantScore = score(for: dominantTrait)
        let scorePercentage = Int(dominantScore * 100)
        
        return "Your dominant trait is \(dominantTrait.displayName) (\(scorePercentage)%) with \(confidence.description.lowercased())"
    }
}

/// Metadata about how the personality analysis was performed
public struct AnalysisMetadata: Codable, Hashable {
    /// Date when this analysis was performed
    public let analysisDate: Date
    
    /// Number of data points used in the analysis
    public let dataPointsAnalyzed: Int
    
    /// Days of data included in analysis
    public let timeRangeAnalyzed: Int
    
    /// Version of the analysis algorithm used
    public let version: String
    
    public init(
        analysisDate: Date,
        dataPointsAnalyzed: Int,
        timeRangeAnalyzed: Int,
        version: String = "1.0"
    ) {
        self.analysisDate = analysisDate
        self.dataPointsAnalyzed = dataPointsAnalyzed
        self.timeRangeAnalyzed = timeRangeAnalyzed
        self.version = version
    }
}

/// Threshold requirements for personality analysis
public struct ThresholdRequirement: Identifiable, Codable, Hashable {
    public let id: UUID
    public let name: String
    public let description: String
    public let currentValue: Int
    public let requiredValue: Int
    public let category: RequirementCategory
    
    /// Whether this requirement is met
    public var isMet: Bool {
        return currentValue >= requiredValue
    }
    
    /// Progress towards meeting this requirement (0.0-1.0)
    public var progress: Double {
        guard requiredValue > 0 else { return 1.0 }
        return min(1.0, Double(currentValue) / Double(requiredValue))
    }
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        currentValue: Int,
        requiredValue: Int,
        category: RequirementCategory
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.currentValue = currentValue
        self.requiredValue = requiredValue
        self.category = category
    }
}

/// Categories of threshold requirements
public enum RequirementCategory: String, CaseIterable, Codable {
    case habits = "habits"
    case tracking = "tracking"
    case customization = "customization"
    case diversity = "diversity"
    
    public var displayName: String {
        switch self {
        case .habits:
            return "Active Habits"
        case .tracking:
            return "Tracking History"
        case .customization:
            return "Personalization"
        case .diversity:
            return "Habit Variety"
        }
    }
    
    public var emoji: String {
        switch self {
        case .habits:
            return "📝"
        case .tracking:
            return "📊"
        case .customization:
            return "🎨"
        case .diversity:
            return "🌈"
        }
    }
}

/// Progress status for threshold requirements
public struct ProgressStatus: Codable, Hashable {
    public let current: Int
    public let required: Int
    public let isMet: Bool
    public let progress: Double
    
    public init(current: Int, required: Int) {
        self.current = current
        self.required = required
        self.isMet = current >= required
        self.progress = required > 0 ? min(1.0, Double(current) / Double(required)) : 1.0
    }
    
    /// Display string like "3/5"
    public var displayString: String {
        return "\(current)/\(required)"
    }
}

/// Overall analysis eligibility status
public struct AnalysisEligibility: Codable, Hashable {
    public let isEligible: Bool
    public let missingRequirements: [ThresholdRequirement]
    public let overallProgress: Double
    public let estimatedDaysToEligibility: Int?
    
    public init(
        isEligible: Bool,
        missingRequirements: [ThresholdRequirement],
        overallProgress: Double,
        estimatedDaysToEligibility: Int? = nil
    ) {
        self.isEligible = isEligible
        self.missingRequirements = missingRequirements
        self.overallProgress = max(0.0, min(1.0, overallProgress))
        self.estimatedDaysToEligibility = estimatedDaysToEligibility
    }
    
    /// Number of requirements that are met
    public var metRequirementsCount: Int {
        return missingRequirements.filter { $0.isMet }.count
    }
    
    /// Total number of requirements
    public var totalRequirementsCount: Int {
        return missingRequirements.count
    }
}

/// Input data structure for personality analysis
public struct HabitAnalysisInput {
    public let activeHabits: [Habit]
    public let completionRates: [Double]
    public let customHabits: [Habit]
    public let customCategories: [Category]
    public let habitCategories: [Category]
    public let selectedSuggestions: [HabitSuggestion]
    public let trackingDays: Int
    public let analysisTimeRange: Int
    public let totalDataPoints: Int
    
    public init(
        activeHabits: [Habit],
        completionRates: [Double],
        customHabits: [Habit],
        customCategories: [Category],
        habitCategories: [Category],
        selectedSuggestions: [HabitSuggestion],
        trackingDays: Int,
        analysisTimeRange: Int,
        totalDataPoints: Int
    ) {
        self.activeHabits = activeHabits
        self.completionRates = completionRates
        self.customHabits = customHabits
        self.customCategories = customCategories
        self.habitCategories = habitCategories
        self.selectedSuggestions = selectedSuggestions
        self.trackingDays = trackingDays
        self.analysisTimeRange = analysisTimeRange
        self.totalDataPoints = totalDataPoints
    }
}

/// Habit completion statistics
public struct HabitCompletionStats: Codable {
    public let totalHabits: Int
    public let completedHabits: Int  
    public let completionRate: Double
    
    public init(totalHabits: Int, completedHabits: Int, completionRate: Double) {
        self.totalHabits = totalHabits
        self.completedHabits = completedHabits
        self.completionRate = completionRate
    }
}

/// User preferences for personality analysis
public struct PersonalityAnalysisPreferences: Codable {
    public let userId: UUID
    public let isEnabled: Bool
    public let shareInsights: Bool
    public let analysisFrequency: AnalysisFrequency
    
    public init(userId: UUID, isEnabled: Bool = true, shareInsights: Bool = false, analysisFrequency: AnalysisFrequency = .weekly) {
        self.userId = userId
        self.isEnabled = isEnabled
        self.shareInsights = shareInsights
        self.analysisFrequency = analysisFrequency
    }
}

/// How often to run personality analysis
public enum AnalysisFrequency: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case manual = "manual"
}