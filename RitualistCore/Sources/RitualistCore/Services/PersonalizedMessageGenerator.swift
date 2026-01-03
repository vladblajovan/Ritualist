//
//  PersonalizedMessageGenerator.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on ML-Powered Personalized Messages Implementation
//

import Foundation
#if canImport(NaturalLanguage)
import NaturalLanguage
#endif

// MARK: - Supporting Types

/// Context information needed to generate a personalized message
public struct MessageContext: Sendable {
    public let trigger: InspirationTrigger
    public let personality: PersonalityProfile?
    public let completionPercentage: Double
    public let timeOfDay: TimeOfDay
    public let userName: String?
    public let currentStreak: Int
    public let recentPattern: CompletionPattern

    public init(
        trigger: InspirationTrigger,
        personality: PersonalityProfile?,
        completionPercentage: Double,
        timeOfDay: TimeOfDay,
        userName: String?,
        currentStreak: Int,
        recentPattern: CompletionPattern
    ) {
        self.trigger = trigger
        self.personality = personality
        self.completionPercentage = completionPercentage
        self.timeOfDay = timeOfDay
        self.userName = userName
        self.currentStreak = currentStreak
        self.recentPattern = recentPattern
    }
}

/// Recent completion pattern analysis
public enum CompletionPattern: Sendable {
    case consistent      // Stable completion rates
    case improving       // Upward trend
    case declining       // Downward trend
    case erratic        // High variability
    case insufficient   // Not enough data
}

/// Message tone that reflects personality and context
public enum MessageTone {
    case enthusiastic    // High energy, exciting
    case focused        // Achievement-oriented, precise
    case energetic      // Social, momentum-building
    case warm           // Caring, supportive
    case gentle         // Reassuring, patient
}

/// Method used to generate the message
public enum GenerationMethod {
    case template       // Pre-written variant selected
    case semanticML     // Future: ML-enhanced phrase selection
    case generated      // Future: LLM-generated
}

/// The generated personalized message
public struct PersonalizedMessage {
    public let content: String
    public let tone: MessageTone
    public let generationMethod: GenerationMethod

    public init(content: String, tone: MessageTone, generationMethod: GenerationMethod) {
        self.content = content
        self.tone = tone
        self.generationMethod = generationMethod
    }
}

// MARK: - Protocol

public protocol PersonalizedMessageGeneratorProtocol: Sendable {
    /// Generate personalized message based on context
    func generateMessage(for context: MessageContext) async -> PersonalizedMessage

    /// Check if ML-enhanced generation is available
    var isMLAvailable: Bool { get }
}

// MARK: - Implementation

/// Generates personality-aware motivational messages
/// Phase 1: Template-based personality variant selection
/// Phase 2 (Future): ML semantic phrase selection
/// Phase 3 (Future): On-device LLM generation
public final class PersonalizedMessageGenerator: PersonalizedMessageGeneratorProtocol {

    public init() {}

    public var isMLAvailable: Bool {
        #if canImport(NaturalLanguage)
        if #available(iOS 17.0, *) {
            return NLEmbedding.wordEmbedding(for: .english) != nil
        }
        #endif
        return false
    }

    // MARK: - Public API

    public func generateMessage(for context: MessageContext) async -> PersonalizedMessage {
        // Phase 1: Template-based generation
        return generateTemplateMessage(for: context)
    }

    // MARK: - Template-Based Generation (Phase 1)

    private func generateTemplateMessage(for context: MessageContext) -> PersonalizedMessage {
        // Determine dominant personality trait
        let trait = determineDominantTrait(from: context.personality)

        // Select base template
        let template = selectTemplate(trigger: context.trigger, trait: trait)

        // Adapt message based on completion percentage
        let adaptedMessage = adaptMessageForCompletion(
            template: template,
            completionPercentage: context.completionPercentage,
            trait: trait
        )

        // Personalize with user name if available
        let finalMessage = personalizeWithName(message: adaptedMessage, userName: context.userName)

        // Determine tone
        let tone = determineTone(for: trait)

        return PersonalizedMessage(
            content: finalMessage,
            tone: tone,
            generationMethod: .template
        )
    }

    private func determineDominantTrait(from profile: PersonalityProfile?) -> PersonalityTrait {
        guard let profile = profile else {
            // Fallback to conscientiousness (balanced, achievement-focused)
            return .conscientiousness
        }

        // Use the profile's dominant trait (already computed during analysis)
        return profile.dominantTrait
    }

    private func determineTone(for trait: PersonalityTrait) -> MessageTone {
        switch trait {
        case .openness:
            return .enthusiastic
        case .conscientiousness:
            return .focused
        case .extraversion:
            return .energetic
        case .agreeableness:
            return .warm
        case .neuroticism:
            return .gentle
        }
    }

    // MARK: - Message Templates

    private func selectTemplate(trigger: InspirationTrigger, trait: PersonalityTrait) -> String {
        // All templates organized by trigger → personality trait
        let templates = getMessageTemplates()

        guard let traitTemplates = templates[trigger],
              let template = traitTemplates[trait] else {
            return getFallbackMessage(for: trigger)
        }

        return template
    }

    private func getMessageTemplates() -> [InspirationTrigger: [PersonalityTrait: String]] {
        // Messages optimized for 2-line display (~60 chars max)
        return [
            // Session Start Messages (shown when user has no habits yet)
            .sessionStart: [
                .openness: "Ready to explore new habits?",
                .conscientiousness: "Start building your routine.",
                .extraversion: "Let's create your first habit!",
                .agreeableness: "Begin your wellness journey.",
                .neuroticism: "Start small. One habit at a time."
            ],

            // Morning Motivation Messages
            .morningMotivation: [
                .openness: "Morning possibilities await!",
                .conscientiousness: "Morning routine activated.",
                .extraversion: "Rise and shine! Let's go!",
                .agreeableness: "Good morning! Spread some joy.",
                .neuroticism: "Deep breath. One habit at a time."
            ],

            // First Habit Complete Messages
            .firstHabitComplete: [
                .openness: "Great start! Building momentum.",
                .conscientiousness: "First habit done. On track.",
                .extraversion: "First win! Feel that energy?",
                .agreeableness: "Beautiful start! Keep going.",
                .neuroticism: "One down! You're doing it."
            ],

            // Halfway Point Messages
            .halfwayPoint: [
                .openness: "Finding your rhythm! Halfway there.",
                .conscientiousness: "50% complete. Steady progress.",
                .extraversion: "Halfway! Momentum building!",
                .agreeableness: "Beautiful progress! Keep it up.",
                .neuroticism: "Real progress! One step at a time."
            ],

            // Struggling Mid-Day Messages
            .strugglingMidDay: [
                .openness: "Try something different!",
                .conscientiousness: "Break it into smaller steps.",
                .extraversion: "Find your second wind!",
                .agreeableness: "Be kind to yourself today.",
                .neuroticism: "One tiny step is enough."
            ],

            // Afternoon Push Messages
            .afternoonPush: [
                .openness: "Afternoon adventure awaits!",
                .conscientiousness: "Time to hit remaining targets.",
                .extraversion: "This is your time to shine!",
                .agreeableness: "Finish strong for yourself!",
                .neuroticism: "You've made it this far. Breathe."
            ],

            // Strong Finish Messages
            .strongFinish: [
                .openness: "So close to the finish line!",
                .conscientiousness: "75%+ done. Execute the finish.",
                .extraversion: "On fire! Maximum energy!",
                .agreeableness: "Making an impact! Almost there!",
                .neuroticism: "Amazing progress. Finish strong."
            ],

            // Perfect Day Messages
            .perfectDay: [
                .openness: "Perfect day! Every goal explored!",
                .conscientiousness: "100% complete. Goals achieved.",
                .extraversion: "YES! Perfect day achieved!",
                .agreeableness: "Perfect! You made a difference!",
                .neuroticism: "You did it! Real strength shown."
            ],

            // Evening Reflection Messages
            .eveningReflection: [
                .openness: "What a journey today!",
                .conscientiousness: "Strong day. Consistent execution.",
                .extraversion: "Great energy today! Rest well.",
                .agreeableness: "Your kindness created ripples.",
                .neuroticism: "You made it through. Rest now."
            ],

            // Weekend Motivation Messages
            .weekendMotivation: [
                .openness: "Weekend freedom! Explore away.",
                .conscientiousness: "Weekend discipline. Stay consistent.",
                .extraversion: "Weekend energy! You're inspiring!",
                .agreeableness: "Weekend care for your growth!",
                .neuroticism: "You're here anyway. That's strength."
            ],

            // Comeback Story Messages
            .comebackStory: [
                .openness: "What a comeback! Well done!",
                .conscientiousness: "Back on track. Well recovered.",
                .extraversion: "Bounced back stronger!",
                .agreeableness: "Beautiful resilience! Welcome back.",
                .neuroticism: "You came back. That's courage."
            ],

            // Empty Day Messages (no habits scheduled today)
            .emptyDay: [
                .openness: "Blank canvas. What will you try?",
                .conscientiousness: "No habits today. Plan ahead.",
                .extraversion: "Free day! Add something fun.",
                .agreeableness: "Rest day? That's self-care.",
                .neuroticism: "Nothing today. Rest is progress."
            ]
        ]
    }

    // MARK: - Message Adaptation

    private func adaptMessageForCompletion(
        template: String,
        completionPercentage: Double,
        trait: PersonalityTrait
    ) -> String {
        // For Phase 1, we use the base template as-is
        // Phase 2 will add completion-rate-specific adaptations
        return template
    }

    private func personalizeWithName(message: String, userName: String?) -> String {
        guard let name = userName, !name.isEmpty else {
            return message
        }

        // Insert name at the beginning if appropriate
        // For now, prepend name to message
        // More sophisticated insertion in Phase 2
        if message.starts(with: "You") {
            return message.replacingOccurrences(of: "You", with: "\(name), you", options: .anchored)
        } else if message.starts(with: "What") || message.starts(with: "Morning") ||
                  message.starts(with: "Midday") || message.starts(with: "Weekend") ||
                  message.starts(with: "Incredible") || message.starts(with: "Perfect") ||
                  message.starts(with: "Beautiful") {
            return "\(name), \(message.prefix(1).lowercased())\(message.dropFirst())"
        }

        return message
    }

    private func getFallbackMessage(for trigger: InspirationTrigger) -> String {
        // Generic fallback if no template found (~40 chars max)
        switch trigger {
        case .sessionStart:
            return "Create your first habit!"
        case .morningMotivation:
            return "Good morning! Start strong."
        case .firstHabitComplete:
            return "First habit complete!"
        case .halfwayPoint:
            return "Halfway there! Keep going."
        case .strugglingMidDay:
            return "Every step counts."
        case .afternoonPush:
            return "Finish strong!"
        case .strongFinish:
            return "Almost there!"
        case .perfectDay:
            return "Perfect day achieved!"
        case .eveningReflection:
            return "Well done! Rest up."
        case .weekendMotivation:
            return "Weekend dedication!"
        case .comebackStory:
            return "Great comeback!"
        case .emptyDay:
            return "No habits today. Enjoy!"
        }
    }
}
