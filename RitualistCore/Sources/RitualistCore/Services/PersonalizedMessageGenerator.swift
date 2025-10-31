//
//  PersonalizedMessageGenerator.swift
//  RitualistCore
//
//  Created by Claude on ML-Powered Personalized Messages Implementation
//

import Foundation
#if canImport(NaturalLanguage)
import NaturalLanguage
#endif

// MARK: - Supporting Types

/// Context information needed to generate a personalized message
public struct MessageContext {
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
public enum CompletionPattern {
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

public protocol PersonalizedMessageGeneratorProtocol {
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
        return [
            // Session Start Messages
            .sessionStart: [
                .openness: "What new possibilities will today bring? 🌟",
                .conscientiousness: "Time to execute your daily plan with precision. 🎯",
                .extraversion: "Let's bring the energy today! You've got this! ⚡",
                .agreeableness: "Ready to make a positive difference today? 🌸",
                .neuroticism: "One step at a time. You've got this. 💪"
            ],

            // Morning Motivation Messages
            .morningMotivation: [
                .openness: "Morning is full of possibilities! What will you discover today? 🌅",
                .conscientiousness: "Morning routine activated. Time to execute with discipline. 🌅",
                .extraversion: "Rise and shine! Let's make today amazing with high energy! 🌅",
                .agreeableness: "Good morning! Your caring actions will brighten someone's day. 🌅",
                .neuroticism: "Take a deep breath. Start with one small habit. You've got this. 🌅"
            ],

            // First Habit Complete Messages
            .firstHabitComplete: [
                .openness: "Fantastic start! You're building momentum in your unique way. ⚡",
                .conscientiousness: "First habit complete. Executing the plan perfectly. ⚡",
                .extraversion: "Yes! First win of the day! Feel that energy building? ⚡",
                .agreeableness: "Beautiful start! Your first positive action is complete. ⚡",
                .neuroticism: "One down! You're doing it. Keep going at your own pace. ⚡"
            ],

            // Halfway Point Messages
            .halfwayPoint: [
                .openness: "You're discovering your rhythm! Halfway through with steady progress. 🎨",
                .conscientiousness: "Systematic progress! 50% completion rate maintained. On track. ✅",
                .extraversion: "You're building momentum! Halfway through with solid energy! 🔥",
                .agreeableness: "Beautiful progress! Your caring actions are creating positive change. 🌸",
                .neuroticism: "You're making real progress! Halfway there—one step at a time. 💪"
            ],

            // Struggling Mid-Day Messages
            .strugglingMidDay: [
                .openness: "Midday is a chance to try something different! What works for you? 🌿",
                .conscientiousness: "Recalibrating. Break down the next habit into smaller steps. 📋",
                .extraversion: "Energy dip is temporary! Let's find your second wind together. 💫",
                .agreeableness: "Be kind to yourself. Every small effort counts. 🤗",
                .neuroticism: "You're not alone in this. One tiny step forward is enough. 🕊️"
            ],

            // Afternoon Push Messages
            .afternoonPush: [
                .openness: "Afternoon adventure time! Let's explore what you can accomplish. 🚀",
                .conscientiousness: "Afternoon execution phase. Time to hit remaining targets. 🎯",
                .extraversion: "Afternoon energy boost! This is your time to shine! 🔥",
                .agreeableness: "You're doing great! Let's finish strong for yourself and others. 🌟",
                .neuroticism: "You've made it this far. That's already success. Keep breathing. 🌊"
            ],

            // Strong Finish Messages
            .strongFinish: [
                .openness: "Incredible variety today! You're so close to exploring it all! 🎨",
                .conscientiousness: "75%+ achieved. Excellence within reach. Execute the finish. 🏆",
                .extraversion: "You're absolutely on fire! Let's finish with maximum energy! ⚡",
                .agreeableness: "You're making such a positive impact! Almost there! 💝",
                .neuroticism: "You're doing amazing! You've come so far. Breathe and finish strong. 🌈"
            ],

            // Perfect Day Messages
            .perfectDay: [
                .openness: "Perfect day achieved! You explored every possibility today! 🌟✨",
                .conscientiousness: "100% completion. Perfect execution. Goals achieved. 🎯✅",
                .extraversion: "YES! Perfect day! Your energy made this happen! 🎉🔥",
                .agreeableness: "Perfect day! Your caring actions made a real difference! 💝🌸",
                .neuroticism: "You did it! All habits complete. You showed real strength today. 💪🌈"
            ],

            // Evening Reflection Messages
            .eveningReflection: [
                .openness: "What a journey today! You explored new patterns and grew. 🌙",
                .conscientiousness: "End of day review: Strong performance. Consistent execution. 🌙",
                .extraversion: "What energy you brought today! Rest and recharge! 🌙",
                .agreeableness: "You made today matter. Your kindness created ripples. 🌙",
                .neuroticism: "You made it through today. That's worthy of recognition. Rest now. 🌙"
            ],

            // Weekend Motivation Messages
            .weekendMotivation: [
                .openness: "Weekend freedom! Perfect time to explore habits in new ways! 🏆",
                .conscientiousness: "Weekend discipline sets you apart. Consistency knows no calendar. 🏆",
                .extraversion: "Weekend energy! Your commitment even now is inspiring! 🏆",
                .agreeableness: "Weekend dedication shows true care for your growth! 🏆",
                .neuroticism: "Weekends can be tough. You're here anyway. That's strength. 🏆"
            ],

            // Comeback Story Messages
            .comebackStory: [
                .openness: "What a comeback! You adapted and found your way back! 🚀",
                .conscientiousness: "Recovery complete. You've recalibrated and returned to form. 🚀",
                .extraversion: "Incredible comeback energy! You bounced back stronger! 🚀",
                .agreeableness: "Beautiful resilience! You showed up for yourself again! 🚀",
                .neuroticism: "You came back. After a hard day, you're here. That's real courage. 🚀"
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
        // Generic fallback if no template found
        switch trigger {
        case .sessionStart:
            return "Welcome back! Ready to make progress today?"
        case .morningMotivation:
            return "Good morning! Let's start the day strong."
        case .firstHabitComplete:
            return "Great start! First habit complete."
        case .halfwayPoint:
            return "Excellent progress! You're halfway there."
        case .strugglingMidDay:
            return "Keep going! Every step counts."
        case .afternoonPush:
            return "Afternoon momentum! Let's finish strong."
        case .strongFinish:
            return "Almost there! Finish with strength."
        case .perfectDay:
            return "Perfect day achieved! Outstanding work!"
        case .eveningReflection:
            return "Well done today! Rest and recharge."
        case .weekendMotivation:
            return "Weekend dedication! Keep it up."
        case .comebackStory:
            return "Great comeback! You're back on track."
        }
    }
}
