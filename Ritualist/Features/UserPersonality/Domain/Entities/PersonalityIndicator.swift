//
//  PersonalityIndicator.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import Foundation

/// Represents personality trait coefficients for habits, categories, or behaviors
public struct PersonalityIndicator: Codable, Hashable {
    /// Trait weights mapping (-1.0 to 1.0)
    /// Positive values indicate the behavior increases the trait
    /// Negative values indicate the behavior decreases the trait
    public let traitWeights: [PersonalityTrait: Double]
    
    /// Category of indicator for grouping and analysis
    public let category: IndicatorCategory
    
    /// Human-readable description of what this indicator represents
    public let description: String
    
    /// Additional context or notes about this indicator
    public let notes: String?
    
    public init(
        traitWeights: [PersonalityTrait: Double],
        category: IndicatorCategory,
        description: String,
        notes: String? = nil
    ) {
        // Validate trait weights are within acceptable range
        let validatedWeights = traitWeights.mapValues { weight in
            min(max(weight, -1.0), 1.0)
        }
        
        self.traitWeights = validatedWeights
        self.category = category
        self.description = description
        self.notes = notes
    }
    
    /// Get the weight for a specific trait, returns 0.0 if not present
    public func weight(for trait: PersonalityTrait) -> Double {
        return traitWeights[trait] ?? 0.0
    }
    
    /// Get the strongest trait influence (highest absolute value)
    public var dominantTrait: PersonalityTrait? {
        return traitWeights.max { abs($0.value) < abs($1.value) }?.key
    }
    
    /// Get the strength of influence (sum of absolute values)
    public var influenceStrength: Double {
        return traitWeights.values.map(abs).reduce(0, +)
    }
}

/// Category of personality indicator for organization and analysis
public enum IndicatorCategory: String, CaseIterable, Codable {
    case habitType = "habit_type"
    case habitSchedule = "habit_schedule"
    case categoryPreference = "category_preference"
    case engagementPattern = "engagement_pattern"
    case customizationBehavior = "customization_behavior"
    case goalComplexity = "goal_complexity"
    case socialAspect = "social_aspect"
    case consistencyPattern = "consistency_pattern"
    
    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .habitType:
            return "Habit Type"
        case .habitSchedule:
            return "Habit Schedule"
        case .categoryPreference:
            return "Category Preference"
        case .engagementPattern:
            return "Engagement Pattern"
        case .customizationBehavior:
            return "Customization Behavior"
        case .goalComplexity:
            return "Goal Complexity"
        case .socialAspect:
            return "Social Aspect"
        case .consistencyPattern:
            return "Consistency Pattern"
        }
    }
    
    /// Description of what this category measures
    public var description: String {
        switch self {
        case .habitType:
            return "The types and themes of habits chosen"
        case .habitSchedule:
            return "How habits are scheduled and structured"
        case .categoryPreference:
            return "Preferences for different habit categories"
        case .engagementPattern:
            return "Patterns of user engagement and commitment"
        case .customizationBehavior:
            return "How users customize and personalize their habits"
        case .goalComplexity:
            return "The complexity and specificity of goals set"
        case .socialAspect:
            return "Social elements and community aspects of habits"
        case .consistencyPattern:
            return "Patterns of consistency and persistence"
        }
    }
}

// MARK: - Predefined Personality Indicators

public extension PersonalityIndicator {
    
    /// Indicators for different habit types
    static let habitTypeIndicators: [String: PersonalityIndicator] = [
        "creative_habit": PersonalityIndicator(
            traitWeights: [
                .openness: 0.8,
                .conscientiousness: 0.3,
                .neuroticism: -0.2
            ],
            category: .habitType,
            description: "Creative and artistic habits"
        ),
        
        "learning_habit": PersonalityIndicator(
            traitWeights: [
                .openness: 0.9,
                .conscientiousness: 0.6,
                .extraversion: -0.1
            ],
            category: .habitType,
            description: "Learning and educational habits"
        ),
        
        "social_habit": PersonalityIndicator(
            traitWeights: [
                .extraversion: 0.8,
                .agreeableness: 0.6,
                .openness: 0.3
            ],
            category: .habitType,
            description: "Social and community-oriented habits"
        ),
        
        "fitness_habit": PersonalityIndicator(
            traitWeights: [
                .conscientiousness: 0.7,
                .extraversion: 0.4,
                .neuroticism: -0.3
            ],
            category: .habitType,
            description: "Physical fitness and health habits"
        ),
        
        "mindfulness_habit": PersonalityIndicator(
            traitWeights: [
                .openness: 0.5,
                .conscientiousness: 0.6,
                .neuroticism: -0.7
            ],
            category: .habitType,
            description: "Mindfulness and meditation habits"
        )
    ]
    
    /// Indicators for engagement patterns
    static let engagementIndicators: [String: PersonalityIndicator] = [
        "high_consistency": PersonalityIndicator(
            traitWeights: [
                .conscientiousness: 0.8,
                .neuroticism: -0.3
            ],
            category: .engagementPattern,
            description: "Highly consistent habit logging"
        ),
        
        "habit_variety": PersonalityIndicator(
            traitWeights: [
                .openness: 0.7,
                .extraversion: 0.4
            ],
            category: .engagementPattern,
            description: "Tracking diverse types of habits"
        ),
        
        "detailed_tracking": PersonalityIndicator(
            traitWeights: [
                .conscientiousness: 0.8,
                .openness: 0.2
            ],
            category: .goalComplexity,
            description: "Setting specific targets and detailed tracking"
        ),
        
        "custom_creation": PersonalityIndicator(
            traitWeights: [
                .openness: 0.9,
                .conscientiousness: 0.3
            ],
            category: .customizationBehavior,
            description: "Creating custom habits and categories"
        )
    ]
}