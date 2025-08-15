//
//  PersonalityInsight.swift
//  RitualistCore
//
//  Created by Claude on 15.08.2025.
//

import Foundation

/// A single personality insight with actionable recommendations
public struct PersonalityInsight: Identifiable, Codable {
    public let id: String
    public let category: InsightCategory
    public let trait: PersonalityTrait?
    public let title: String
    public let description: String
    public let actionable: String
    public let confidence: ConfidenceLevel
    
    public init(
        id: String,
        category: InsightCategory,
        trait: PersonalityTrait?,
        title: String,
        description: String,
        actionable: String,
        confidence: ConfidenceLevel
    ) {
        self.id = id
        self.category = category
        self.trait = trait
        self.title = title
        self.description = description
        self.actionable = actionable
        self.confidence = confidence
    }
    
    /// Categories for personality insights
    public enum InsightCategory: String, CaseIterable, Codable {
        case habitRecommendation = "habit_recommendation"
        case patternAnalysis = "pattern_analysis"
        case motivation = "motivation"
        case warning = "warning"
        case celebration = "celebration"
        
        public var displayName: String {
            switch self {
            case .habitRecommendation:
                return "Habit Recommendation"
            case .patternAnalysis:
                return "Pattern Analysis"
            case .motivation:
                return "Motivation"
            case .warning:
                return "Warning"
            case .celebration:
                return "Celebration"
            }
        }
        
        public var emoji: String {
            switch self {
            case .habitRecommendation:
                return "💡"
            case .patternAnalysis:
                return "🧠"
            case .motivation:
                return "🚀"
            case .warning:
                return "⚠️"
            case .celebration:
                return "🎉"
            }
        }
    }
}

/// Collection of personality insights organized by category
public struct PersonalityInsightCollection: Codable {
    public let habitRecommendations: [PersonalityInsight]
    public let patternInsights: [PersonalityInsight]
    public let motivationalInsights: [PersonalityInsight]
    public let generatedDate: Date
    public let profileId: String
    
    public init(
        habitRecommendations: [PersonalityInsight],
        patternInsights: [PersonalityInsight],
        motivationalInsights: [PersonalityInsight],
        generatedDate: Date,
        profileId: String
    ) {
        self.habitRecommendations = habitRecommendations
        self.patternInsights = patternInsights
        self.motivationalInsights = motivationalInsights
        self.generatedDate = generatedDate
        self.profileId = profileId
    }
    
    /// All insights combined into a single array
    public var allInsights: [PersonalityInsight] {
        return habitRecommendations + patternInsights + motivationalInsights
    }
    
    /// Total number of insights across all categories
    public var insightCount: Int {
        return allInsights.count
    }
    
    /// Get insights for a specific category
    public func insights(for category: PersonalityInsight.InsightCategory) -> [PersonalityInsight] {
        switch category {
        case .habitRecommendation:
            return habitRecommendations
        case .patternAnalysis:
            return patternInsights
        case .motivation:
            return motivationalInsights
        case .warning, .celebration:
            return allInsights.filter { $0.category == category }
        }
    }
    
    /// Check if the collection has insights for a specific trait
    public func hasInsights(for trait: PersonalityTrait) -> Bool {
        return allInsights.contains { $0.trait == trait }
    }
    
    /// Get insights related to a specific trait
    public func insights(for trait: PersonalityTrait) -> [PersonalityInsight] {
        return allInsights.filter { $0.trait == trait }
    }
}