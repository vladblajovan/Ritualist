//
//  PersonalityNotificationContentGenerator.swift
//  RitualistCore
//
//  Migrated from app layer following Clean Architecture
//

import Foundation
import UserNotifications

/// Service for generating engaging notification content based on personality analysis results
public struct PersonalityNotificationContentGenerator {
    
    // MARK: - Public Methods
    
    /// Generates notification content based on personality analysis results
    public static func generateContent(for profile: PersonalityProfile) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        let dominantTrait = profile.dominantTrait
        let confidence = profile.confidence
        
        // Generate title and body based on dominant trait
        let (title, body) = generateTitleAndBody(for: dominantTrait, confidence: confidence)
        
        content.title = title
        content.body = body
        content.sound = .default
        // Badge is managed by updateBadgeCount() on app activation, not set per-notification
        // This prevents stale badges after app reinstall (iOS doesn't clear pending notifications)

        // Add deep link data
        content.userInfo = [
            "type": "personality_analysis",
            "action": "open_analysis",
            "dominant_trait": dominantTrait.rawValue,
            "confidence": confidence.rawValue
        ]
        
        // Add rich content for notification center persistence
        content.categoryIdentifier = getCategoryIdentifier(for: dominantTrait)
        content.threadIdentifier = "personality_analysis"
        content.relevanceScore = 1.0
        
        return content
    }
    
    /// Generates content for insufficient data scenario
    public static func generateInsufficientDataContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        content.title = "🌱 Keep Building Your Habits!"
        content.body = "You're making progress! A few more days of consistent tracking will unlock your personality insights."
        content.sound = .default
        
        content.userInfo = [
            "type": "personality_analysis",
            "action": "open_requirements"
        ]
        
        // Add persistence settings
        content.categoryIdentifier = "PERSONALITY_ANALYSIS_INSUFFICIENT_DATA"
        content.threadIdentifier = "personality_analysis"
        content.relevanceScore = 0.8
        
        return content
    }
    
    /// Generates content when analysis is triggered but user needs to enable it
    public static func generateAnalysisAvailableContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        content.title = "✨ Your Personality Insights Are Ready!"
        content.body = "Tap to discover what your habits reveal about your personality traits and get personalized recommendations."
        content.sound = .default
        
        content.userInfo = [
            "type": "personality_analysis",
            "action": "open_analysis"
        ]
        
        return content
    }
    
    // MARK: - Private Helpers
    
    private static func generateTitleAndBody(for trait: PersonalityTrait, confidence: ConfidenceLevel) -> (String, String) {
        let confidenceEmoji = getConfidenceEmoji(for: confidence)
        
        switch trait {
        case .openness:
            return (
                "\(confidenceEmoji) Creative Mind Detected!",
                "Your habits reveal strong openness to new experiences. Discover what this means for your habit-building journey!"
            )
            
        case .conscientiousness:
            return (
                "\(confidenceEmoji) Disciplined Achiever!",
                "Your consistent tracking shows high conscientiousness. See how this superpower can unlock even better habits!"
            )
            
        case .extraversion:
            return (
                "\(confidenceEmoji) Social Energy Identified!",
                "Your habits reflect an extraverted personality. Learn how to leverage your social nature for habit success!"
            )
            
        case .agreeableness:
            return (
                "\(confidenceEmoji) Compassionate Builder!",
                "Your habit patterns show high agreeableness. Discover personalized strategies that match your caring nature!"
            )
            
        case .neuroticism:
            return (
                "\(confidenceEmoji) Sensitive Insights Available!",
                "Your habits reveal important patterns about stress and emotions. Get tailored advice for mindful habit building!"
            )
        }
    }
    
    private static func getConfidenceEmoji(for confidence: ConfidenceLevel) -> String {
        switch confidence {
        case .veryHigh:
            return "🎯"
        case .high:
            return "🎯"
        case .medium:
            return "📊"
        case .low:
            return "🔍"
        case .insufficient:
            return "🌱"
        }
    }
    
    private static func getCategoryIdentifier(for trait: PersonalityTrait) -> String {
        return "PERSONALITY_ANALYSIS_\(trait.rawValue.uppercased())"
    }
}

// MARK: - Trait-Specific Content Extensions

private extension PersonalityTrait {
    var displayEmoji: String {
        switch self {
        case .openness: return "🎨"
        case .conscientiousness: return "🎯"
        case .extraversion: return "🌟"
        case .agreeableness: return "💝"
        case .neuroticism: return "🧘"
        }
    }
    
    var insightPreview: String {
        switch self {
        case .openness:
            return "Creative and curious approaches work best for you"
        case .conscientiousness:
            return "Structure and planning are your habit-building superpowers"
        case .extraversion:
            return "Social accountability and group activities energize you"
        case .agreeableness:
            return "Helping others while building habits multiplies your motivation"
        case .neuroticism:
            return "Gentle, stress-aware approaches suit your sensitive nature"
        }
    }
}