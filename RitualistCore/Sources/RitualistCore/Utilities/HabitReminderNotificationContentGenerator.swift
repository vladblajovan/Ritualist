//
//  HabitReminderNotificationContentGenerator.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 11.08.2025.
//

import Foundation
import UserNotifications

/// Service for generating rich, persistent notification content for habit reminders
public struct HabitReminderNotificationContentGenerator {
    
    // MARK: - Public Methods
    
    /// Generates rich notification content for habit reminders
    public static func generateContent(
        for habitID: UUID,
        habitName: String,
        reminderTime: ReminderTime,
        habitCategory: String? = nil,
        currentStreak: Int = 0,
        isWeekend: Bool = false
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        let (title, body) = generateTitleAndBody(
            habitName: habitName,
            reminderTime: reminderTime,
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
        
        // Store habit information in userInfo for action handling
        content.userInfo = [
            "type": "habit_reminder",
            "habitId": habitID.uuidString,
            "habitName": habitName,
            "reminderHour": reminderTime.hour,
            "reminderMinute": reminderTime.minute,
            "habitCategory": habitCategory ?? "General",
            "currentStreak": currentStreak
        ]
        
        return content
    }
    
    /// Generates motivational notification for streak milestones
    public static func generateStreakMilestoneContent(
        for habitID: UUID,
        habitName: String,
        streakDays: Int
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        let milestone = getStreakMilestone(streakDays)
        content.title = "\(milestone.emoji) \(streakDays)-Day Streak!"
        content.body = "Amazing work on your \(habitName) habit! \(milestone.message)"
        content.sound = .default
        content.badge = 1
        
        // Rich content for notification center persistence
        content.categoryIdentifier = "HABIT_STREAK_MILESTONE"
        content.threadIdentifier = "habit_streaks_\(habitID.uuidString)"
        content.relevanceScore = 1.0
        
        content.userInfo = [
            "type": "habit_streak_milestone",
            "habitId": habitID.uuidString,
            "habitName": habitName,
            "streakDays": streakDays
        ]
        
        return content
    }
    
    // MARK: - Private Helpers
    
    private static func generateTitleAndBody(
        habitName: String,
        reminderTime: ReminderTime,
        habitCategory: String?,
        currentStreak: Int,
        isWeekend: Bool
    ) -> (String, String) {
        
        let timeString = String(format: "%02d:%02d", reminderTime.hour, reminderTime.minute)
        let streakText = currentStreak > 0 ? " (Day \(currentStreak + 1))" : ""
        
        // Generate contextual titles based on time and streak
        let title: String
        let body: String
        
        if isWeekend {
            title = "🌟 Weekend \(habitName) Time!"
            body = "It's \(timeString) - perfect time for your \(habitName) habit\(streakText). Keep the momentum going!"
        } else if reminderTime.hour < 9 {
            title = "🌅 Morning \(habitName)"
            body = "Good morning! Start your day strong with \(habitName) at \(timeString)\(streakText)."
        } else if reminderTime.hour < 17 {
            title = "☀️ Midday \(habitName)"
            body = "It's \(timeString) - time for your \(habitName) habit\(streakText). You've got this!"
        } else {
            title = "🌙 Evening \(habitName)"
            body = "Wind down with your \(habitName) habit at \(timeString)\(streakText). End the day right!"
        }
        
        return (title, body)
    }
    
    private static func getStreakMilestone(_ days: Int) -> (emoji: String, message: String) {
        switch days {
        case 3:
            return ("🔥", "You're building momentum!")
        case 7:
            return ("🚀", "One week strong - you're on fire!")
        case 14:
            return ("💎", "Two weeks of dedication - you're a diamond!")
        case 21:
            return ("👑", "Three weeks! You're forming a lasting habit!")
        case 30:
            return ("🏆", "30 days! You're a habit champion!")
        case 50:
            return ("⭐", "50 days of excellence!")
        case 75:
            return ("🎯", "75 days - you're unstoppable!")
        case 100:
            return ("🌟", "100 days! You've mastered this habit!")
        default:
            if days >= 365 {
                return ("🏅", "Over a year of consistency - you're a legend!")
            } else if days >= 200 {
                return ("🎖️", "\(days) days of dedication!")
            } else {
                return ("🔥", "Keep the streak alive!")
            }
        }
    }
}
