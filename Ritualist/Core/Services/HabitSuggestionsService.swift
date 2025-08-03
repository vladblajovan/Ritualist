//
//  HabitSuggestionsService.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 30.07.2025.
//

import Foundation

public protocol HabitSuggestionsService {
    func getSuggestions() -> [HabitSuggestion]
    func getSuggestions(for categoryId: String) -> [HabitSuggestion]
}

// swiftlint:disable type_body_length
public final class DefaultHabitSuggestionsService: HabitSuggestionsService {
    private let suggestions: [HabitSuggestion] = [
        // Health
        HabitSuggestion(
            id: "drink_water",
            name: "Drink Water",
            emoji: "💧",
            colorHex: "#2DA9E3",
            categoryId: "health",
            kind: .numeric,
            unitLabel: "glasses",
            dailyTarget: 8.0,
            description: "Stay hydrated throughout the day"
        ),
        
        HabitSuggestion(
            id: "exercise",
            name: "Exercise",
            emoji: "🏋️‍♂️",
            colorHex: "#E36414",
            categoryId: "health",
            kind: .binary,
            schedule: .timesPerWeek(3),
            description: "Get your body moving with regular workouts"
        ),
        
        HabitSuggestion(
            id: "walk_steps",
            name: "Walk",
            emoji: "🚶‍♀️",
            colorHex: "#28A745",
            categoryId: "health",
            kind: .numeric,
            unitLabel: "steps",
            dailyTarget: 10000.0,
            description: "Take daily steps for better health"
        ),
        
        HabitSuggestion(
            id: "eat_fruits",
            name: "Eat Fruits",
            emoji: "🍎",
            colorHex: "#DC3545",
            categoryId: "health",
            kind: .numeric,
            unitLabel: "servings",
            dailyTarget: 2.0,
            description: "Include fresh fruits in your diet"
        ),
        
        // Wellness
        HabitSuggestion(
            id: "meditate",
            name: "Meditate",
            emoji: "🧘‍♀️",
            colorHex: "#6A994E",
            categoryId: "wellness",
            kind: .binary,
            description: "Practice mindfulness and inner peace"
        ),
        
        HabitSuggestion(
            id: "sleep_early",
            name: "Sleep Early",
            emoji: "😴",
            colorHex: "#6F42C1",
            categoryId: "wellness",
            kind: .binary,
            description: "Get quality rest by sleeping early"
        ),
        
        HabitSuggestion(
            id: "deep_breathing",
            name: "Deep Breathing",
            emoji: "🫁",
            colorHex: "#20C997",
            categoryId: "wellness",
            kind: .numeric,
            unitLabel: "minutes",
            dailyTarget: 5.0,
            description: "Practice breathing exercises for relaxation"
        ),
        
        HabitSuggestion(
            id: "gratitude",
            name: "Gratitude Journal",
            emoji: "📝",
            colorHex: "#FD7E14",
            categoryId: "wellness",
            kind: .binary,
            description: "Write down things you're grateful for"
        ),
        
        // Productivity
        HabitSuggestion(
            id: "no_phone_morning",
            name: "No Phone Morning",
            emoji: "📵",
            colorHex: "#6C757D",
            categoryId: "productivity",
            kind: .binary,
            description: "Start your day phone-free for better focus"
        ),
        
        HabitSuggestion(
            id: "plan_day",
            name: "Plan Your Day",
            emoji: "📋",
            colorHex: "#0D6EFD",
            categoryId: "productivity",
            kind: .binary,
            description: "Create a daily plan to stay organized"
        ),
        
        HabitSuggestion(
            id: "clean_workspace",
            name: "Clean Workspace",
            emoji: "🧹",
            colorHex: "#198754",
            categoryId: "productivity",
            kind: .binary,
            schedule: .daysOfWeek([1, 3, 5]), // Mon, Wed, Fri
            description: "Keep your workspace tidy and organized"
        ),
        
        // Learning
        HabitSuggestion(
            id: "read_book",
            name: "Read",
            emoji: "📚",
            colorHex: "#795548",
            categoryId: "learning",
            kind: .numeric,
            unitLabel: "pages",
            dailyTarget: 10.0,
            description: "Read books to expand your knowledge"
        ),
        
        HabitSuggestion(
            id: "practice_language",
            name: "Language Practice",
            emoji: "🗣️",
            colorHex: "#E91E63",
            categoryId: "learning",
            kind: .numeric,
            unitLabel: "minutes",
            dailyTarget: 15.0,
            description: "Practice a new language daily"
        ),
        
        HabitSuggestion(
            id: "learn_skill",
            name: "Learn New Skill",
            emoji: "🎯",
            colorHex: "#FF9800",
            categoryId: "learning",
            kind: .numeric,
            unitLabel: "minutes",
            dailyTarget: 30.0,
            schedule: .daysOfWeek([1, 2, 3, 4, 5]), // Weekdays
            description: "Dedicate time to learning a new skill"
        ),
        
        // Social
        HabitSuggestion(
            id: "call_family",
            name: "Call Family",
            emoji: "📞",
            colorHex: "#9C27B0",
            categoryId: "social",
            kind: .binary,
            schedule: .timesPerWeek(2),
            description: "Stay connected with family members"
        ),
        
        HabitSuggestion(
            id: "compliment_someone",
            name: "Give Compliment",
            emoji: "😊",
            colorHex: "#FFEB3B",
            categoryId: "social",
            kind: .binary,
            description: "Brighten someone's day with a genuine compliment"
        ),
        
        HabitSuggestion(
            id: "help_others",
            name: "Help Someone",
            emoji: "🤝",
            colorHex: "#607D8B",
            categoryId: "social",
            kind: .binary,
            schedule: .timesPerWeek(3),
            description: "Look for opportunities to help others"
        ),
        
        // Additional Health habits
        HabitSuggestion(
            id: "stretch",
            name: "Stretch",
            emoji: "🤸‍♀️",
            colorHex: "#FF6B6B",
            categoryId: "health",
            kind: .numeric,
            unitLabel: "minutes",
            dailyTarget: 10.0,
            description: "Improve flexibility with daily stretching"
        ),
        
        HabitSuggestion(
            id: "take_vitamins",
            name: "Take Vitamins",
            emoji: "💊",
            colorHex: "#4ECDC4",
            categoryId: "health",
            kind: .binary,
            description: "Take your daily vitamins and supplements"
        ),
        
        HabitSuggestion(
            id: "eat_vegetables",
            name: "Eat Vegetables",
            emoji: "🥬",
            colorHex: "#A8E6CF",
            categoryId: "health",
            kind: .numeric,
            unitLabel: "servings",
            dailyTarget: 3.0,
            description: "Include healthy vegetables in your meals"
        ),
        
        HabitSuggestion(
            id: "limit_sugar",
            name: "Limit Sugar",
            emoji: "🚫",
            colorHex: "#FFB6C1",
            categoryId: "health",
            kind: .binary,
            description: "Avoid excessive sugar consumption"
        ),
        
        HabitSuggestion(
            id: "drink_tea",
            name: "Drink Herbal Tea",
            emoji: "🍵",
            colorHex: "#DEB887",
            categoryId: "health",
            kind: .numeric,
            unitLabel: "cups",
            dailyTarget: 2.0,
            description: "Enjoy the benefits of herbal tea"
        ),
        
        HabitSuggestion(
            id: "posture_check",
            name: "Check Posture",
            emoji: "🧍‍♀️",
            colorHex: "#D2691E",
            categoryId: "health",
            kind: .numeric,
            unitLabel: "times",
            dailyTarget: 5.0,
            description: "Maintain good posture throughout the day"
        ),
        
        // Additional Wellness habits
        HabitSuggestion(
            id: "cold_shower",
            name: "Cold Shower",
            emoji: "🚿",
            colorHex: "#87CEEB",
            categoryId: "wellness",
            kind: .binary,
            schedule: .timesPerWeek(3),
            description: "Boost energy and resilience with cold showers"
        ),
        
        HabitSuggestion(
            id: "nature_time",
            name: "Time in Nature",
            emoji: "🌲",
            colorHex: "#228B22",
            categoryId: "wellness",
            kind: .numeric,
            unitLabel: "minutes",
            dailyTarget: 30.0,
            description: "Spend time outdoors for mental wellness"
        ),
        
        HabitSuggestion(
            id: "digital_detox",
            name: "Digital Detox",
            emoji: "📱",
            colorHex: "#696969",
            categoryId: "wellness",
            kind: .numeric,
            unitLabel: "hours",
            dailyTarget: 2.0,
            description: "Take breaks from digital devices"
        ),
        
        HabitSuggestion(
            id: "listen_music",
            name: "Listen to Music",
            emoji: "🎵",
            colorHex: "#DA70D6",
            categoryId: "wellness",
            kind: .numeric,
            unitLabel: "minutes",
            dailyTarget: 20.0,
            description: "Relax and enjoy music for mental well-being"
        ),
        
        HabitSuggestion(
            id: "skincare_routine",
            name: "Skincare Routine",
            emoji: "🧴",
            colorHex: "#F0E68C",
            categoryId: "wellness",
            kind: .binary,
            description: "Take care of your skin with a daily routine"
        ),
        
        HabitSuggestion(
            id: "affirmations",
            name: "Positive Affirmations",
            emoji: "💭",
            colorHex: "#FFD700",
            categoryId: "wellness",
            kind: .binary,
            description: "Start your day with positive self-talk"
        ),
        
        // Additional Productivity habits
        HabitSuggestion(
            id: "make_bed",
            name: "Make Bed",
            emoji: "🛏️",
            colorHex: "#8FBC8F",
            categoryId: "productivity",
            kind: .binary,
            description: "Start your day with a simple accomplished task"
        ),
        
        HabitSuggestion(
            id: "review_goals",
            name: "Review Goals",
            emoji: "🎯",
            colorHex: "#FF4500",
            categoryId: "productivity",
            kind: .binary,
            schedule: .daysOfWeek([7]), // Sunday
            description: "Weekly review of your goals and progress"
        ),
        
        HabitSuggestion(
            id: "time_block",
            name: "Time Blocking",
            emoji: "⏰",
            colorHex: "#4169E1",
            categoryId: "productivity",
            kind: .binary,
            description: "Plan your day using time blocking technique"
        ),
        
        HabitSuggestion(
            id: "inbox_zero",
            name: "Clear Email Inbox",
            emoji: "📧",
            colorHex: "#1E90FF",
            categoryId: "productivity",
            kind: .binary,
            description: "Process and organize your email inbox"
        ),
        
        HabitSuggestion(
            id: "single_task",
            name: "Single-Tasking",
            emoji: "🎯",
            colorHex: "#FF6347",
            categoryId: "productivity",
            kind: .binary,
            description: "Focus on one task at a time"
        ),
        
        HabitSuggestion(
            id: "declutter",
            name: "Declutter Space",
            emoji: "📦",
            colorHex: "#CD853F",
            categoryId: "productivity",
            kind: .binary,
            schedule: .timesPerWeek(2),
            description: "Remove unnecessary items from your space"
        ),
        
        // Additional Learning habits
        HabitSuggestion(
            id: "watch_documentary",
            name: "Watch Documentary",
            emoji: "🎬",
            colorHex: "#8B4513",
            categoryId: "learning",
            kind: .binary,
            schedule: .timesPerWeek(2),
            description: "Learn something new through documentaries"
        ),
        
        HabitSuggestion(
            id: "practice_instrument",
            name: "Practice Instrument",
            emoji: "🎸",
            colorHex: "#B8860B",
            categoryId: "learning",
            kind: .numeric,
            unitLabel: "minutes",
            dailyTarget: 20.0,
            description: "Practice playing a musical instrument"
        ),
        
        HabitSuggestion(
            id: "write_journal",
            name: "Write Journal",
            emoji: "📖",
            colorHex: "#8B0000",
            categoryId: "learning",
            kind: .binary,
            description: "Reflect and document your thoughts daily"
        ),
        
        HabitSuggestion(
            id: "listen_podcast",
            name: "Listen to Podcast",
            emoji: "🎧",
            colorHex: "#2F4F4F",
            categoryId: "learning",
            kind: .numeric,
            unitLabel: "episodes",
            dailyTarget: 1.0,
            description: "Learn while commuting or exercising"
        ),
        
        HabitSuggestion(
            id: "practice_coding",
            name: "Practice Coding",
            emoji: "💻",
            colorHex: "#000080",
            categoryId: "learning",
            kind: .numeric,
            unitLabel: "minutes",
            dailyTarget: 45.0,
            description: "Improve programming skills with daily practice"
        ),
        
        HabitSuggestion(
            id: "learn_recipe",
            name: "Learn New Recipe",
            emoji: "👨‍🍳",
            colorHex: "#FF8C00",
            categoryId: "learning",
            kind: .binary,
            schedule: .timesPerWeek(1),
            description: "Expand culinary skills with new recipes"
        ),
        
        // Additional Social habits
        HabitSuggestion(
            id: "text_friends",
            name: "Text Friends",
            emoji: "💬",
            colorHex: "#32CD32",
            categoryId: "social",
            kind: .binary,
            description: "Stay in touch with friends regularly"
        ),
        
        HabitSuggestion(
            id: "volunteer",
            name: "Volunteer",
            emoji: "❤️",
            colorHex: "#DC143C",
            categoryId: "social",
            kind: .binary,
            schedule: .timesPerWeek(1),
            description: "Give back to your community through volunteering"
        ),
        
        HabitSuggestion(
            id: "meet_new_people",
            name: "Meet New People",
            emoji: "👋",
            colorHex: "#FF69B4",
            categoryId: "social",
            kind: .binary,
            schedule: .timesPerWeek(1),
            description: "Expand your social circle and network"
        ),
        
        HabitSuggestion(
            id: "practice_gratitude_others",
            name: "Thank Someone",
            emoji: "🙏",
            colorHex: "#DDA0DD",
            categoryId: "social",
            kind: .binary,
            description: "Express gratitude to people around you"
        ),
        
        HabitSuggestion(
            id: "social_activity",
            name: "Social Activity",
            emoji: "🎲",
            colorHex: "#20B2AA",
            categoryId: "social",
            kind: .binary,
            schedule: .timesPerWeek(2),
            description: "Engage in activities with others"
        ),
        
        HabitSuggestion(
            id: "write_letter",
            name: "Write a Letter",
            emoji: "✉️",
            colorHex: "#F4A460",
            categoryId: "social",
            kind: .binary,
            schedule: .timesPerWeek(1),
            description: "Connect meaningfully through handwritten letters"
        )
    ]
    
    public init() {}
    
    public func getSuggestions() -> [HabitSuggestion] {
        suggestions
    }
    
    public func getSuggestions(for categoryId: String) -> [HabitSuggestion] {
        suggestions.filter { $0.categoryId == categoryId }
    }
}
