//
//  HabitSuggestionsService.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 30.07.2025.
//

import Foundation

public protocol HabitSuggestionsService {
    func getSuggestions() -> [HabitSuggestion]
    func getSuggestions(for category: HabitSuggestionCategory) -> [HabitSuggestion]
}

public final class DefaultHabitSuggestionsService: HabitSuggestionsService {
    
    private let suggestions: [HabitSuggestion] = [
        // Health
        HabitSuggestion(
            id: "drink_water",
            name: "Drink Water",
            emoji: "💧",
            colorHex: "#2DA9E3",
            category: .health,
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
            category: .health,
            kind: .binary,
            schedule: .timesPerWeek(3),
            description: "Get your body moving with regular workouts"
        ),
        
        HabitSuggestion(
            id: "walk_steps",
            name: "Walk",
            emoji: "🚶‍♀️",
            colorHex: "#28A745",
            category: .health,
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
            category: .health,
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
            category: .wellness,
            kind: .binary,
            description: "Practice mindfulness and inner peace"
        ),
        
        HabitSuggestion(
            id: "sleep_early",
            name: "Sleep Early",
            emoji: "😴",
            colorHex: "#6F42C1",
            category: .wellness,
            kind: .binary,
            description: "Get quality rest by sleeping early"
        ),
        
        HabitSuggestion(
            id: "deep_breathing",
            name: "Deep Breathing",
            emoji: "🫁",
            colorHex: "#20C997",
            category: .wellness,
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
            category: .wellness,
            kind: .binary,
            description: "Write down things you're grateful for"
        ),
        
        // Productivity
        HabitSuggestion(
            id: "no_phone_morning",
            name: "No Phone Morning",
            emoji: "📵",
            colorHex: "#6C757D",
            category: .productivity,
            kind: .binary,
            description: "Start your day phone-free for better focus"
        ),
        
        HabitSuggestion(
            id: "plan_day",
            name: "Plan Your Day",
            emoji: "📋",
            colorHex: "#0D6EFD",
            category: .productivity,
            kind: .binary,
            description: "Create a daily plan to stay organized"
        ),
        
        HabitSuggestion(
            id: "clean_workspace",
            name: "Clean Workspace",
            emoji: "🧹",
            colorHex: "#198754",
            category: .productivity,
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
            category: .learning,
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
            category: .learning,
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
            category: .learning,
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
            category: .social,
            kind: .binary,
            schedule: .timesPerWeek(2),
            description: "Stay connected with family members"
        ),
        
        HabitSuggestion(
            id: "compliment_someone",
            name: "Give Compliment",
            emoji: "😊",
            colorHex: "#FFEB3B",
            category: .social,
            kind: .binary,
            description: "Brighten someone's day with a genuine compliment"
        ),
        
        HabitSuggestion(
            id: "help_others",
            name: "Help Someone",
            emoji: "🤝",
            colorHex: "#607D8B",
            category: .social,
            kind: .binary,
            schedule: .timesPerWeek(3),
            description: "Look for opportunities to help others"
        )
    ]
    
    public init() {}
    
    public func getSuggestions() -> [HabitSuggestion] {
        suggestions
    }
    
    public func getSuggestions(for category: HabitSuggestionCategory) -> [HabitSuggestion] {
        suggestions.filter { $0.category == category }
    }
}
