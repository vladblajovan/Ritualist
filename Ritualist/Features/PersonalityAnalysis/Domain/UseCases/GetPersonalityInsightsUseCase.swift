//
//  GetPersonalityInsightsUseCase.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import Foundation
import RitualistCore

/// Use case for generating personalized insights based on personality analysis
public protocol GetPersonalityInsightsUseCase {
    /// Get personalized habit recommendations based on personality traits
    func getHabitRecommendations(for profile: PersonalityProfile) -> [PersonalityInsight]
    
    /// Get insights about user's current habit patterns
    func getPatternInsights(for profile: PersonalityProfile) -> [PersonalityInsight]
    
    /// Get motivational insights based on personality traits
    func getMotivationalInsights(for profile: PersonalityProfile) -> [PersonalityInsight]
    
    /// Get all insights for a personality profile
    func getAllInsights(for profile: PersonalityProfile) -> PersonalityInsightCollection
}

public final class DefaultGetPersonalityInsightsUseCase: GetPersonalityInsightsUseCase {
    
    public init() {}
    
    public func getHabitRecommendations(for profile: PersonalityProfile) -> [PersonalityInsight] {
        var insights: [PersonalityInsight] = []
        
        let topTraits = profile.traitsByScore.prefix(3)
        
        for (trait, score) in topTraits where score > 0.6 {
            switch trait {
            case .openness:
                insights.append(PersonalityInsight(
                    id: UUID().uuidString,
                    category: .habitRecommendation,
                    trait: trait,
                    title: "Explore Creative Habits",
                    description: "Your high openness suggests you'd enjoy creative pursuits like art, music, or learning new skills.",
                    actionable: "Try adding habits like 'Practice drawing', 'Learn a new language', or 'Read diverse genres'",
                    confidence: profile.confidence
                ))
                
            case .conscientiousness:
                insights.append(PersonalityInsight(
                    id: UUID().uuidString,
                    category: .habitRecommendation,
                    trait: trait,
                    title: "Structure Your Routine",
                    description: "Your conscientiousness means you thrive with organized, goal-oriented habits.",
                    actionable: "Set specific targets, use detailed tracking, and create morning/evening routines",
                    confidence: profile.confidence
                ))
                
            case .extraversion:
                insights.append(PersonalityInsight(
                    id: UUID().uuidString,
                    category: .habitRecommendation,
                    trait: trait,
                    title: "Add Social Elements",
                    description: "Your extraversion suggests social and energetic activities align with your nature.",
                    actionable: "Try habits like 'Meet friends weekly', 'Join group fitness', or 'Call family daily'",
                    confidence: profile.confidence
                ))
                
            case .agreeableness:
                insights.append(PersonalityInsight(
                    id: UUID().uuidString,
                    category: .habitRecommendation,
                    trait: trait,
                    title: "Focus on Connection",
                    description: "Your agreeableness indicates you value helping others and maintaining relationships.",
                    actionable: "Consider habits like 'Random acts of kindness', 'Check in with loved ones', or 'Volunteer weekly'",
                    confidence: profile.confidence
                ))
                
            case .neuroticism:
                insights.append(PersonalityInsight(
                    id: UUID().uuidString,
                    category: .habitRecommendation,
                    trait: trait,
                    title: "Prioritize Stress Management",
                    description: "Higher emotional sensitivity suggests stress-reduction habits would be particularly beneficial.",
                    actionable: "Try meditation, deep breathing exercises, journaling, or regular nature walks",
                    confidence: profile.confidence
                ))
            }
        }
        
        return insights
    }
    
    public func getPatternInsights(for profile: PersonalityProfile) -> [PersonalityInsight] {
        var insights: [PersonalityInsight] = []
        
        // Analyze dominant trait patterns
        let dominantScore = profile.traitScores[profile.dominantTrait] ?? 0.0
        
        if dominantScore > 0.8 {
            insights.append(PersonalityInsight(
                id: UUID().uuidString,
                category: .patternAnalysis,
                trait: profile.dominantTrait,
                title: "Strong \(profile.dominantTrait.displayName) Pattern",
                description: "Your habits strongly reflect \(profile.dominantTrait.displayName.lowercased()) tendencies.",
                actionable: "Continue leveraging this strength while exploring habits that develop other traits",
                confidence: profile.confidence
            ))
        }
        
        // Look for balanced traits
        let balancedTraits = profile.traitScores.filter { abs($0.value - 0.5) < 0.15 }
        if balancedTraits.count >= 3 {
            insights.append(PersonalityInsight(
                id: UUID().uuidString,
                category: .patternAnalysis,
                trait: nil,
                title: "Balanced Personality Profile",
                description: "Your habits show a well-rounded approach across multiple personality dimensions.",
                actionable: "This flexibility allows you to adapt your habits to different life situations and goals",
                confidence: profile.confidence
            ))
        }
        
        return insights
    }
    
    public func getMotivationalInsights(for profile: PersonalityProfile) -> [PersonalityInsight] {
        var insights: [PersonalityInsight] = []
        
        // Motivational strategies based on dominant trait
        switch profile.dominantTrait {
        case .openness:
            insights.append(PersonalityInsight(
                id: UUID().uuidString,
                category: .motivation,
                trait: .openness,
                title: "Variety Keeps You Engaged",
                description: "Your openness means routine can become boring. Keep habits fresh with variation.",
                actionable: "Rotate activities, try new approaches, or set creative challenges within existing habits",
                confidence: profile.confidence
            ))
            
        case .conscientiousness:
            insights.append(PersonalityInsight(
                id: UUID().uuidString,
                category: .motivation,
                trait: .conscientiousness,
                title: "Progress Tracking Motivates You",
                description: "Your conscientiousness is fueled by seeing concrete progress and achievement.",
                actionable: "Use detailed metrics, celebrate milestones, and track long-term improvements",
                confidence: profile.confidence
            ))
            
        case .extraversion:
            insights.append(PersonalityInsight(
                id: UUID().uuidString,
                category: .motivation,
                trait: .extraversion,
                title: "Social Accountability Works",
                description: "Your extraversion suggests you're motivated by social connection and external energy.",
                actionable: "Share your goals, find habit buddies, or join community challenges",
                confidence: profile.confidence
            ))
            
        case .agreeableness:
            insights.append(PersonalityInsight(
                id: UUID().uuidString,
                category: .motivation,
                trait: .agreeableness,
                title: "Purpose-Driven Habits Stick",
                description: "Your agreeableness means habits connected to helping others will be most sustainable.",
                actionable: "Frame personal habits in terms of how they help you better serve family, friends, or community",
                confidence: profile.confidence
            ))
            
        case .neuroticism:
            insights.append(PersonalityInsight(
                id: UUID().uuidString,
                category: .motivation,
                trait: .neuroticism,
                title: "Gentle Consistency Over Intensity",
                description: "Your sensitivity suggests steady, manageable habits work better than aggressive goals.",
                actionable: "Start small, be kind to yourself on off days, and focus on stress-reducing habits first",
                confidence: profile.confidence
            ))
        }
        
        return insights
    }
    
    public func getAllInsights(for profile: PersonalityProfile) -> PersonalityInsightCollection {
        let recommendations = getHabitRecommendations(for: profile)
        let patterns = getPatternInsights(for: profile)
        let motivational = getMotivationalInsights(for: profile)
        
        return PersonalityInsightCollection(
            habitRecommendations: recommendations,
            patternInsights: patterns,
            motivationalInsights: motivational,
            generatedDate: Date(),
            profileId: profile.id.uuidString
        )
    }
}

