//
//  PersonalityTailoredNotificationContentGenerator.swift
//  Ritualist
//
//  Created by Claude on 11.08.2025.
//

import Foundation
import UserNotifications

/// Service for generating personality-tailored habit reminder notifications
public struct PersonalityTailoredNotificationContentGenerator {
    
    // MARK: - Public Methods
    
    /// Generates personality-tailored notification content for habit reminders
    public static func generateTailoredContent(
        for habitID: UUID,
        habitName: String,
        reminderTime: ReminderTime,
        personalityProfile: PersonalityProfile,
        habitCategory: String? = nil,
        currentStreak: Int = 0,
        isWeekend: Bool = false
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        let dominantTrait = personalityProfile.dominantTrait
        let (title, body) = generatePersonalityTailoredContent(
            habitName: habitName,
            reminderTime: reminderTime,
            dominantTrait: dominantTrait,
            traitScores: personalityProfile.traitScores,
            habitCategory: habitCategory,
            currentStreak: currentStreak,
            isWeekend: isWeekend
        )
        
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        // Rich content for notification center persistence
        content.categoryIdentifier = "HABIT_REMINDER"
        content.threadIdentifier = "habit_reminders_\(habitID.uuidString)"
        content.relevanceScore = 1.0
        
        // Store habit and personality information in userInfo
        content.userInfo = [
            "type": "personality_tailored_habit_reminder",
            "habitId": habitID.uuidString,
            "habitName": habitName,
            "reminderHour": reminderTime.hour,
            "reminderMinute": reminderTime.minute,
            "habitCategory": habitCategory ?? "General",
            "currentStreak": currentStreak,
            "dominantTrait": dominantTrait.rawValue,
            "confidence": personalityProfile.confidence.rawValue
        ]
        
        return content
    }
    
    /// Check if user has a recent personality analysis (within 30 days)
    public static func hasRecentAnalysis(_ profile: PersonalityProfile?) -> Bool {
        guard let profile = profile else { return false }
        
        let daysSinceAnalysis = Calendar.current.dateComponents(
            [.day],
            from: profile.analysisMetadata.analysisDate,
            to: Date()
        ).day ?? 0
        
        return daysSinceAnalysis <= 30
    }
    
    // MARK: - Private Helpers
    
    private static func generatePersonalityTailoredContent(
        habitName: String,
        reminderTime: ReminderTime,
        dominantTrait: PersonalityTrait,
        traitScores: [PersonalityTrait: Double],
        habitCategory: String?,
        currentStreak: Int,
        isWeekend: Bool
    ) -> (String, String) {
        
        let timeString = String(format: "%02d:%02d", reminderTime.hour, reminderTime.minute)
        let streakText = currentStreak > 0 ? " (Day \(currentStreak + 1))" : ""
        
        // Get secondary traits for nuanced messaging
        let conscientiousnessScore = traitScores[.conscientiousness] ?? 0.0
        let opennessScore = traitScores[.openness] ?? 0.0
        let extraversionScore = traitScores[.extraversion] ?? 0.0
        let agreeablenessScore = traitScores[.agreeableness] ?? 0.0
        let neuroticismScore = traitScores[.neuroticism] ?? 0.0
        
        let title: String
        let body: String
        
        switch dominantTrait {
        case .conscientiousness:
            title = generateConscientiousTitle(habitName: habitName, isWeekend: isWeekend, reminderTime: reminderTime)
            body = generateConscientiousBody(
                habitName: habitName,
                timeString: timeString,
                streakText: streakText,
                currentStreak: currentStreak,
                opennessScore: opennessScore
            )
            
        case .openness:
            title = generateOpennessTitle(habitName: habitName, isWeekend: isWeekend, reminderTime: reminderTime)
            body = generateOpennessBody(
                habitName: habitName,
                timeString: timeString,
                streakText: streakText,
                conscientiousnessScore: conscientiousnessScore
            )
            
        case .extraversion:
            title = generateExtraversionTitle(habitName: habitName, isWeekend: isWeekend, reminderTime: reminderTime)
            body = generateExtraversionBody(
                habitName: habitName,
                timeString: timeString,
                streakText: streakText,
                agreeablenessScore: agreeablenessScore
            )
            
        case .agreeableness:
            title = generateAgreeablenessTitle(habitName: habitName, isWeekend: isWeekend, reminderTime: reminderTime)
            body = generateAgreeablenessBody(
                habitName: habitName,
                timeString: timeString,
                streakText: streakText,
                habitCategory: habitCategory
            )
            
        case .neuroticism:
            title = generateNeuroticismTitle(habitName: habitName, isWeekend: isWeekend, reminderTime: reminderTime)
            body = generateNeuroticismBody(
                habitName: habitName,
                timeString: timeString,
                streakText: streakText,
                conscientiousnessScore: conscientiousnessScore
            )
        }
        
        return (title, body)
    }
    
    // MARK: - Conscientiousness-Tailored Messages
    
    private static func generateConscientiousTitle(habitName: String, isWeekend: Bool, reminderTime: ReminderTime) -> String {
        if isWeekend {
            return "📅 Structured Weekend: \(habitName)"
        } else if reminderTime.hour < 9 {
            return "🎯 Disciplined Start: \(habitName)"
        } else if reminderTime.hour < 17 {
            return "⚡ Focused Time: \(habitName)"
        } else {
            return "✅ Complete Your Day: \(habitName)"
        }
    }
    
    private static func generateConscientiousBody(
        habitName: String,
        timeString: String,
        streakText: String,
        currentStreak: Int,
        opennessScore: Double
    ) -> String {
        let baseMessage = "Your disciplined nature thrives on consistency. Time for \(habitName) at \(timeString)\(streakText)."
        
        if currentStreak >= 7 {
            return "\(baseMessage) Your systematic approach is paying off - \(currentStreak) days strong!"
        } else if opennessScore > 0.6 {
            return "\(baseMessage) Stay organized while exploring new approaches to make it even better."
        } else {
            return "\(baseMessage) Stick to your proven routine - discipline creates freedom."
        }
    }
    
    // MARK: - Openness-Tailored Messages
    
    private static func generateOpennessTitle(habitName: String, isWeekend: Bool, reminderTime: ReminderTime) -> String {
        if isWeekend {
            return "🎨 Creative Weekend: \(habitName)"
        } else if reminderTime.hour < 9 {
            return "🌅 Fresh Perspective: \(habitName)"
        } else if reminderTime.hour < 17 {
            return "💡 Innovative Time: \(habitName)"
        } else {
            return "🔍 Explore & Reflect: \(habitName)"
        }
    }
    
    private static func generateOpennessBody(
        habitName: String,
        timeString: String,
        streakText: String,
        conscientiousnessScore: Double
    ) -> String {
        let creativity = ["Try a new approach", "Experiment with different methods", "Add a creative twist", "Explore new possibilities"]
        let randomCreativity = creativity.randomElement() ?? creativity[0]
        
        if conscientiousnessScore > 0.6 {
            return "\(randomCreativity) to your \(habitName) routine at \(timeString)\(streakText). Your structured creativity is powerful!"
        } else {
            return "Time for \(habitName) at \(timeString)\(streakText). \(randomCreativity) - let curiosity guide you!"
        }
    }
    
    // MARK: - Extraversion-Tailored Messages
    
    private static func generateExtraversionTitle(habitName: String, isWeekend: Bool, reminderTime: ReminderTime) -> String {
        if isWeekend {
            return "🌟 Social Energy: \(habitName)"
        } else if reminderTime.hour < 9 {
            return "🚀 Energized Start: \(habitName)"
        } else if reminderTime.hour < 17 {
            return "⚡ High Energy: \(habitName)"
        } else {
            return "🎉 Evening Power: \(habitName)"
        }
    }
    
    private static func generateExtraversionBody(
        habitName: String,
        timeString: String,
        streakText: String,
        agreeablenessScore: Double
    ) -> String {
        if agreeablenessScore > 0.6 {
            return "Share your \(habitName) energy at \(timeString)\(streakText)! Your enthusiasm can inspire others too."
        } else {
            return "Channel your social energy into \(habitName) at \(timeString)\(streakText). You perform best with external motivation!"
        }
    }
    
    // MARK: - Agreeableness-Tailored Messages
    
    private static func generateAgreeablenessTitle(habitName: String, isWeekend: Bool, reminderTime: ReminderTime) -> String {
        if isWeekend {
            return "💝 Caring Weekend: \(habitName)"
        } else if reminderTime.hour < 9 {
            return "🤗 Thoughtful Start: \(habitName)"
        } else if reminderTime.hour < 17 {
            return "💖 Compassionate Time: \(habitName)"
        } else {
            return "🌸 Gentle Evening: \(habitName)"
        }
    }
    
    private static func generateAgreeablenessBody(
        habitName: String,
        timeString: String,
        streakText: String,
        habitCategory: String?
    ) -> String {
        let category = habitCategory?.lowercased() ?? "general"
        
        if category.contains("health") || category.contains("wellness") {
            return "Taking care of yourself helps you care for others. Time for \(habitName) at \(timeString)\(streakText)."
        } else if category.contains("learning") || category.contains("skill") {
            return "Growing yourself grows your ability to help others. \(habitName) time at \(timeString)\(streakText)."
        } else {
            return "Your caring nature deserves self-care too. Time for \(habitName) at \(timeString)\(streakText). You matter!"
        }
    }
    
    // MARK: - Neuroticism-Tailored Messages
    
    private static func generateNeuroticismTitle(habitName: String, isWeekend: Bool, reminderTime: ReminderTime) -> String {
        if isWeekend {
            return "🧘 Peaceful Weekend: \(habitName)"
        } else if reminderTime.hour < 9 {
            return "🌱 Gentle Start: \(habitName)"
        } else if reminderTime.hour < 17 {
            return "💆 Mindful Moment: \(habitName)"
        } else {
            return "🕯️ Calming Evening: \(habitName)"
        }
    }
    
    private static func generateNeuroticismBody(
        habitName: String,
        timeString: String,
        streakText: String,
        conscientiousnessScore: Double
    ) -> String {
        let gentle = ["Take it one step at a time", "Be gentle with yourself", "Progress, not perfection", "You're doing great"]
        let randomGentleness = gentle.randomElement() ?? gentle[0]
        
        if conscientiousnessScore > 0.6 {
            return "Time for your grounding \(habitName) routine at \(timeString)\(streakText). Structure brings you peace."
        } else {
            return "\(randomGentleness) with \(habitName) at \(timeString)\(streakText). This habit supports your wellbeing."
        }
    }
}