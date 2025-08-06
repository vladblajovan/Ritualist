//
//  PersonalityTrait.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import Foundation

/// The Big Five personality traits (OCEAN model)
public enum PersonalityTrait: String, CaseIterable, Codable, Hashable {
    case openness = "openness"
    case conscientiousness = "conscientiousness" 
    case extraversion = "extraversion"
    case agreeableness = "agreeableness"
    case neuroticism = "neuroticism"
    
    /// Human-readable display name for the trait
    public var displayName: String {
        switch self {
        case .openness:
            return "Openness to Experience"
        case .conscientiousness:
            return "Conscientiousness"
        case .extraversion:
            return "Extraversion"
        case .agreeableness:
            return "Agreeableness"
        case .neuroticism:
            return "Neuroticism"
        }
    }
    
    /// Short description of the trait
    public var shortDescription: String {
        switch self {
        case .openness:
            return "Curiosity, creativity, and openness to new experiences"
        case .conscientiousness:
            return "Organization, discipline, and goal-oriented behavior"
        case .extraversion:
            return "Social energy, assertiveness, and external stimulation"
        case .agreeableness:
            return "Cooperation, trust, and consideration for others"
        case .neuroticism:
            return "Emotional sensitivity and stress reactivity"
        }
    }
    
    /// Detailed description for high scorers
    public var highScoreDescription: String {
        switch self {
        case .openness:
            return "You love trying new things, learning, creating, and exploring. You're intellectually curious and appreciate art and beauty."
        case .conscientiousness:
            return "You're organized, reliable, and excellent at following through on commitments. You set clear goals and work systematically to achieve them."
        case .extraversion:
            return "You thrive in social settings and enjoy active, engaging activities. You're energetic and draw energy from interacting with others."
        case .agreeableness:
            return "You value harmony, enjoy helping others, and work well in teams. You're considerate, trusting, and optimistic about people."
        case .neuroticism:
            return "You're more sensitive to stress and emotional changes. You may experience emotions more intensely and take longer to recover from setbacks."
        }
    }
    
    /// Detailed description for low scorers
    public var lowScoreDescription: String {
        switch self {
        case .openness:
            return "You prefer familiar routines and practical approaches. You're grounded, realistic, and focused on what works."
        case .conscientiousness:
            return "You're flexible, spontaneous, and adaptable. You prefer to go with the flow rather than stick to rigid plans."
        case .extraversion:
            return "You prefer quieter activities and recharge through solitude. You're thoughtful, independent, and enjoy deeper conversations."
        case .agreeableness:
            return "You're competitive, direct, and focused on your own goals. You're willing to challenge others and stand up for your beliefs."
        case .neuroticism:
            return "You're emotionally stable and resilient. You stay calm under pressure and bounce back quickly from challenges."
        }
    }
    
    /// Associated emoji for visual representation
    public var emoji: String {
        switch self {
        case .openness:
            return "🎨"
        case .conscientiousness:
            return "📋"
        case .extraversion:
            return "🤝"
        case .agreeableness:
            return "❤️"
        case .neuroticism:
            return "🧘"
        }
    }
    
    /// Associated color for visual representation
    public var colorHex: String {
        switch self {
        case .openness:
            return "#FF6B35" // Orange - creativity, enthusiasm
        case .conscientiousness:
            return "#2E8B57" // Green - growth, reliability
        case .extraversion:
            return "#4A90E2" // Blue - communication, openness
        case .agreeableness:
            return "#E74C3C" // Red - warmth, connection
        case .neuroticism:
            return "#9B59B6" // Purple - sensitivity, depth
        }
    }
}

/// Confidence level for personality analysis
public enum ConfidenceLevel: String, CaseIterable, Codable {
    case insufficient = "insufficient"
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    /// Numeric confidence score (0.0 - 1.0)
    public var score: Double {
        switch self {
        case .insufficient:
            return 0.0
        case .low:
            return 0.6
        case .medium:
            return 0.8
        case .high:
            return 0.95
        }
    }
    
    /// User-friendly description
    public var description: String {
        switch self {
        case .insufficient:
            return "Not enough data for reliable analysis"
        case .low:
            return "Initial insights - more data will improve accuracy"
        case .medium:
            return "Good confidence - reliable insights with room for improvement"
        case .high:
            return "High confidence - very reliable insights based on rich data"
        }
    }
    
    /// Associated color for UI
    public var colorHex: String {
        switch self {
        case .insufficient:
            return "#95A5A6" // Gray
        case .low:
            return "#F39C12" // Orange
        case .medium:
            return "#3498DB" // Blue
        case .high:
            return "#27AE60" // Green
        }
    }
}