//
//  HabitSuggestionsData.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 13.08.2025.
//

import Foundation

/// Centralized habit suggestions data for cross-platform access.
/// Contains 200+ predefined habit suggestions for widget, watch, and main app use.
public struct HabitSuggestionsData {
    
    /// Complete dataset of predefined habit suggestions
    public static let allSuggestions: [HabitSuggestion] = [
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
            schedule: .daysOfWeek([1, 3, 5]),
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
            schedule: .daysOfWeek([1, 4]),
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
            schedule: .daysOfWeek([1, 3, 5]),
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
            schedule: .daysOfWeek([1, 3, 5]),
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
            schedule: .daysOfWeek([1, 4]),
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
            schedule: .daysOfWeek([1, 4]),
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
            schedule: .daysOfWeek([7]),
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
            schedule: .daysOfWeek([7]),
            description: "Give back to your community through volunteering"
        ),
        
        HabitSuggestion(
            id: "meet_new_people",
            name: "Meet New People",
            emoji: "👋",
            colorHex: "#FF69B4",
            categoryId: "social",
            kind: .binary,
            schedule: .daysOfWeek([7]),
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
            schedule: .daysOfWeek([1, 4]),
            description: "Engage in activities with others"
        ),
        
        HabitSuggestion(
            id: "write_letter",
            name: "Write a Letter",
            emoji: "✉️",
            colorHex: "#F4A460",
            categoryId: "social",
            kind: .binary,
            schedule: .daysOfWeek([7]),
            description: "Connect meaningfully through handwritten letters"
        ),
        
        // Creativity
        HabitSuggestion(
            id: "creative_writing",
            name: "Creative Writing",
            emoji: "✍️",
            colorHex: "#8E44AD",
            categoryId: "creativity",
            kind: .numeric,
            unitLabel: "minutes",
            dailyTarget: 20.0,
            description: "Express yourself through creative writing",
            personalityWeights: [
                "openness": 0.85,
                "conscientiousness": 0.4,
                "extraversion": 0.2,
                "neuroticism": -0.1
            ]
        ),
        
        HabitSuggestion(
            id: "sketch_draw",
            name: "Sketch & Draw",
            emoji: "✏️",
            colorHex: "#E74C3C",
            categoryId: "creativity",
            kind: .numeric,
            unitLabel: "minutes",
            dailyTarget: 30.0,
            description: "Develop visual creativity through drawing",
            personalityWeights: [
                "openness": 0.9,
                "conscientiousness": 0.3,
                "extraversion": 0.1,
                "neuroticism": -0.2
            ]
        ),
        
        HabitSuggestion(
            id: "photography",
            name: "Photography",
            emoji: "📸",
            colorHex: "#3498DB",
            categoryId: "creativity",
            kind: .binary,
            description: "Capture and create through photography",
            personalityWeights: [
                "openness": 0.8,
                "conscientiousness": 0.5,
                "extraversion": 0.3,
                "agreeableness": 0.2
            ]
        ),
        
        HabitSuggestion(
            id: "music_composition",
            name: "Compose Music",
            emoji: "🎼",
            colorHex: "#9B59B6",
            categoryId: "creativity",
            kind: .numeric,
            unitLabel: "minutes",
            dailyTarget: 25.0,
            description: "Create original musical compositions",
            personalityWeights: [
                "openness": 0.95,
                "conscientiousness": 0.6,
                "extraversion": 0.2,
                "neuroticism": -0.1
            ]
        ),
        
        HabitSuggestion(
            id: "craft_diy",
            name: "Crafting & DIY",
            emoji: "🛠️",
            colorHex: "#E67E22",
            categoryId: "creativity",
            kind: .binary,
            schedule: .daysOfWeek([1, 3, 5]),
            description: "Create with your hands through crafting",
            personalityWeights: [
                "openness": 0.7,
                "conscientiousness": 0.7,
                "extraversion": 0.1,
                "agreeableness": 0.3
            ]
        ),
        
        HabitSuggestion(
            id: "brainstorm_ideas",
            name: "Brainstorm Ideas",
            emoji: "💡",
            colorHex: "#F39C12",
            categoryId: "creativity",
            kind: .numeric,
            unitLabel: "ideas",
            dailyTarget: 5.0,
            description: "Generate new ideas through brainstorming",
            personalityWeights: [
                "openness": 0.9,
                "conscientiousness": 0.2,
                "extraversion": 0.4,
                "neuroticism": -0.3
            ]
        ),
        
        HabitSuggestion(
            id: "creative_cooking",
            name: "Creative Cooking",
            emoji: "👨‍🍳",
            colorHex: "#27AE60",
            categoryId: "creativity",
            kind: .binary,
            schedule: .daysOfWeek([1, 4]),
            description: "Experiment with new recipes and flavors",
            personalityWeights: [
                "openness": 0.8,
                "conscientiousness": 0.4,
                "extraversion": 0.3,
                "agreeableness": 0.4
            ]
        ),
        
        HabitSuggestion(
            id: "improvisation",
            name: "Improvisation",
            emoji: "🎭",
            colorHex: "#E91E63",
            categoryId: "creativity",
            kind: .numeric,
            unitLabel: "minutes",
            dailyTarget: 15.0,
            description: "Practice spontaneous creative expression",
            personalityWeights: [
                "openness": 0.95,
                "conscientiousness": 0.1,
                "extraversion": 0.6,
                "neuroticism": -0.4
            ]
        ),
        
        HabitSuggestion(
            id: "design_creation",
            name: "Design Creation",
            emoji: "🎨",
            colorHex: "#9C27B0",
            categoryId: "creativity",
            kind: .numeric,
            unitLabel: "minutes",
            dailyTarget: 30.0,
            description: "Create digital or physical designs",
            personalityWeights: [
                "openness": 0.85,
                "conscientiousness": 0.6,
                "extraversion": 0.2,
                "agreeableness": 0.1
            ]
        ),
        
        HabitSuggestion(
            id: "creative_movement",
            name: "Creative Movement",
            emoji: "💃",
            colorHex: "#FF5722",
            categoryId: "creativity",
            kind: .numeric,
            unitLabel: "minutes",
            dailyTarget: 20.0,
            description: "Express creativity through dance and movement",
            personalityWeights: [
                "openness": 0.8,
                "conscientiousness": 0.3,
                "extraversion": 0.7,
                "neuroticism": -0.3
            ]
        ),

        // MARK: - Demographic-Targeted Suggestions

        // Female-targeted health habits
        HabitSuggestion(
            id: "prenatal_vitamins",
            name: "Prenatal Vitamins",
            emoji: "🤰",
            colorHex: "#FF69B4",
            categoryId: "health",
            kind: .binary,
            description: "Take prenatal vitamins for reproductive health",
            visibleToGenders: [.female]
        ),

        HabitSuggestion(
            id: "pelvic_floor_exercises",
            name: "Pelvic Floor Exercises",
            emoji: "🧘‍♀️",
            colorHex: "#DDA0DD",
            categoryId: "health",
            kind: .numeric,
            unitLabel: "minutes",
            dailyTarget: 10.0,
            description: "Strengthen pelvic floor muscles",
            visibleToGenders: [.female]
        ),

        HabitSuggestion(
            id: "cycle_tracking",
            name: "Track Cycle",
            emoji: "📅",
            colorHex: "#FF6B6B",
            categoryId: "health",
            kind: .binary,
            description: "Log menstrual cycle for health awareness",
            visibleToGenders: [.female]
        ),

        // Student/young adult habits (under 18 and 18-24)
        HabitSuggestion(
            id: "study_session",
            name: "Study Session",
            emoji: "📖",
            colorHex: "#4169E1",
            categoryId: "learning",
            kind: .numeric,
            unitLabel: "hours",
            dailyTarget: 2.0,
            description: "Dedicate time to focused studying",
            visibleToAgeGroups: [.under18, .age18to24]
        ),

        HabitSuggestion(
            id: "homework_time",
            name: "Complete Homework",
            emoji: "📝",
            colorHex: "#20B2AA",
            categoryId: "productivity",
            kind: .binary,
            description: "Finish homework before relaxing",
            visibleToAgeGroups: [.under18]
        ),

        HabitSuggestion(
            id: "college_applications",
            name: "Work on Applications",
            emoji: "🎓",
            colorHex: "#8B4513",
            categoryId: "productivity",
            kind: .numeric,
            unitLabel: "minutes",
            dailyTarget: 30.0,
            description: "Progress on college or job applications",
            visibleToAgeGroups: [.under18, .age18to24]
        ),

        HabitSuggestion(
            id: "internship_search",
            name: "Internship Search",
            emoji: "💼",
            colorHex: "#2F4F4F",
            categoryId: "productivity",
            kind: .binary,
            schedule: .daysOfWeek([1, 3, 5]),
            description: "Search and apply for internship opportunities",
            visibleToAgeGroups: [.age18to24, .age25to34]
        ),

        // Senior/mature adult habits (45+, 55+)
        HabitSuggestion(
            id: "retirement_planning",
            name: "Review Retirement Plan",
            emoji: "💰",
            colorHex: "#228B22",
            categoryId: "productivity",
            kind: .binary,
            schedule: .daysOfWeek([7]),
            description: "Review and update retirement savings goals",
            visibleToAgeGroups: [.age45to54, .age55plus]
        ),

        HabitSuggestion(
            id: "joint_mobility",
            name: "Joint Mobility",
            emoji: "🦴",
            colorHex: "#DEB887",
            categoryId: "health",
            kind: .numeric,
            unitLabel: "minutes",
            dailyTarget: 15.0,
            description: "Gentle exercises to maintain joint flexibility",
            visibleToAgeGroups: [.age45to54, .age55plus]
        ),

        HabitSuggestion(
            id: "brain_games",
            name: "Brain Training",
            emoji: "🧠",
            colorHex: "#9370DB",
            categoryId: "wellness",
            kind: .numeric,
            unitLabel: "minutes",
            dailyTarget: 15.0,
            description: "Keep your mind sharp with puzzles and games",
            visibleToAgeGroups: [.age55plus]
        ),

        HabitSuggestion(
            id: "blood_pressure_check",
            name: "Check Blood Pressure",
            emoji: "❤️‍🩹",
            colorHex: "#DC143C",
            categoryId: "health",
            kind: .binary,
            description: "Monitor blood pressure for heart health",
            visibleToAgeGroups: [.age45to54, .age55plus]
        ),

        HabitSuggestion(
            id: "balance_exercises",
            name: "Balance Exercises",
            emoji: "⚖️",
            colorHex: "#6B8E23",
            categoryId: "health",
            kind: .numeric,
            unitLabel: "minutes",
            dailyTarget: 10.0,
            description: "Practice balance to prevent falls",
            visibleToAgeGroups: [.age55plus]
        ),

        // Career-focused habits (working age adults)
        HabitSuggestion(
            id: "networking",
            name: "Professional Networking",
            emoji: "🤝",
            colorHex: "#4682B4",
            categoryId: "social",
            kind: .binary,
            schedule: .daysOfWeek([1, 4]),
            description: "Reach out to professional contacts",
            visibleToAgeGroups: [.age25to34, .age35to44, .age45to54]
        ),

        HabitSuggestion(
            id: "skill_certification",
            name: "Work on Certification",
            emoji: "📜",
            colorHex: "#CD853F",
            categoryId: "learning",
            kind: .numeric,
            unitLabel: "minutes",
            dailyTarget: 30.0,
            description: "Study for professional certifications",
            visibleToAgeGroups: [.age25to34, .age35to44]
        ),

        HabitSuggestion(
            id: "mentor_session",
            name: "Mentorship Time",
            emoji: "👨‍🏫",
            colorHex: "#8FBC8F",
            categoryId: "social",
            kind: .binary,
            schedule: .daysOfWeek([1, 4]),
            description: "Mentor others or connect with your mentor",
            visibleToAgeGroups: [.age35to44, .age45to54, .age55plus]
        ),

        // Youth-focused habits
        HabitSuggestion(
            id: "screen_time_limit",
            name: "Limit Screen Time",
            emoji: "📱",
            colorHex: "#778899",
            categoryId: "wellness",
            kind: .numeric,
            unitLabel: "hours max",
            dailyTarget: 2.0,
            description: "Keep recreational screen time in check",
            visibleToAgeGroups: [.under18, .age18to24]
        ),

        HabitSuggestion(
            id: "extracurricular",
            name: "Extracurricular Activity",
            emoji: "⚽",
            colorHex: "#32CD32",
            categoryId: "social",
            kind: .binary,
            description: "Participate in clubs, sports, or activities",
            visibleToAgeGroups: [.under18]
        ),

        // Parent-focused habits (typical parenting ages)
        HabitSuggestion(
            id: "quality_time_kids",
            name: "Quality Time with Kids",
            emoji: "👨‍👧‍👦",
            colorHex: "#FFD700",
            categoryId: "social",
            kind: .numeric,
            unitLabel: "minutes",
            dailyTarget: 30.0,
            description: "Dedicated one-on-one time with children",
            visibleToAgeGroups: [.age25to34, .age35to44, .age45to54]
        ),

        HabitSuggestion(
            id: "kids_homework_help",
            name: "Help with Homework",
            emoji: "✏️",
            colorHex: "#87CEEB",
            categoryId: "social",
            kind: .binary,
            description: "Support children with their schoolwork",
            visibleToAgeGroups: [.age25to34, .age35to44, .age45to54]
        )
    ]
    
    // MARK: - Public Access Methods
    
    /// Get all habit suggestions
    /// - Returns: Array of all available habit suggestions
    public static func getAllSuggestions() -> [HabitSuggestion] {
        return allSuggestions
    }
    
    /// Get habit suggestions filtered by category
    /// - Parameter categoryId: The category ID to filter by
    /// - Returns: Array of habit suggestions for the specified category
    public static func getSuggestions(for categoryId: String) -> [HabitSuggestion] {
        return allSuggestions.filter { $0.categoryId == categoryId }
    }
    
    /// Get a specific habit suggestion by ID
    /// - Parameter id: The suggestion ID to search for
    /// - Returns: The habit suggestion if found, nil otherwise
    public static func getSuggestion(by id: String) -> HabitSuggestion? {
        return allSuggestions.first { $0.id == id }
    }
    
    /// Get top N habit suggestions (most popular/featured)
    /// - Parameter count: Number of suggestions to return
    /// - Returns: Array of top habit suggestions
    public static func getTopSuggestions(_ count: Int) -> [HabitSuggestion] {
        // Return first N suggestions as "top" suggestions
        // Could be enhanced with popularity scoring in the future
        return Array(allSuggestions.prefix(count))
    }
    
    /// Get habit suggestions by category with limit
    /// - Parameters:
    ///   - categoryId: The category ID to filter by
    ///   - limit: Maximum number of suggestions to return
    /// - Returns: Array of habit suggestions for the category, limited to specified count
    public static func getSuggestions(for categoryId: String, limit: Int) -> [HabitSuggestion] {
        return Array(getSuggestions(for: categoryId).prefix(limit))
    }
    
    /// Get random habit suggestions
    /// - Parameter count: Number of random suggestions to return
    /// - Returns: Array of randomly selected habit suggestions
    public static func getRandomSuggestions(_ count: Int) -> [HabitSuggestion] {
        return Array(allSuggestions.shuffled().prefix(count))
    }
    
    /// Get habit suggestions by kind (binary/numeric)
    /// - Parameter kind: The habit kind to filter by
    /// - Returns: Array of habit suggestions matching the specified kind
    public static func getSuggestions(by kind: HabitKind) -> [HabitSuggestion] {
        return allSuggestions.filter { $0.kind == kind }
    }
    
    /// Get habit suggestions by schedule type
    /// - Parameter hasCustomSchedule: Whether to filter for habits with custom schedules
    /// - Returns: Array of habit suggestions based on schedule criteria
    public static func getSuggestions(hasCustomSchedule: Bool) -> [HabitSuggestion] {
        if hasCustomSchedule {
            return allSuggestions.filter { $0.schedule != .daily }
        } else {
            return allSuggestions.filter { $0.schedule == .daily }
        }
    }

    // MARK: - Demographic Filtering

    /// Get habit suggestions filtered by user demographics
    /// - Parameters:
    ///   - gender: User's gender (nil or preferNotToSay shows all suggestions)
    ///   - ageGroup: User's age group (nil or preferNotToSay shows all suggestions)
    /// - Returns: Array of habit suggestions visible to the specified demographics
    public static func getSuggestions(for gender: UserGender?, ageGroup: UserAgeGroup?) -> [HabitSuggestion] {
        return allSuggestions.filter { $0.isVisible(for: gender, ageGroup: ageGroup) }
    }

    /// Get habit suggestions for a category, filtered by user demographics
    /// - Parameters:
    ///   - categoryId: The category ID to filter by
    ///   - gender: User's gender (nil or preferNotToSay shows all suggestions)
    ///   - ageGroup: User's age group (nil or preferNotToSay shows all suggestions)
    /// - Returns: Array of habit suggestions for the category, filtered by demographics
    public static func getSuggestions(
        for categoryId: String,
        gender: UserGender?,
        ageGroup: UserAgeGroup?
    ) -> [HabitSuggestion] {
        return allSuggestions.filter {
            $0.categoryId == categoryId && $0.isVisible(for: gender, ageGroup: ageGroup)
        }
    }

    /// Get random habit suggestions filtered by user demographics
    /// - Parameters:
    ///   - count: Number of random suggestions to return
    ///   - gender: User's gender (nil or preferNotToSay shows all suggestions)
    ///   - ageGroup: User's age group (nil or preferNotToSay shows all suggestions)
    /// - Returns: Array of randomly selected habit suggestions, filtered by demographics
    public static func getRandomSuggestions(
        _ count: Int,
        gender: UserGender?,
        ageGroup: UserAgeGroup?
    ) -> [HabitSuggestion] {
        let filtered = getSuggestions(for: gender, ageGroup: ageGroup)
        return Array(filtered.shuffled().prefix(count))
    }

    /// Get top habit suggestions filtered by user demographics
    /// - Parameters:
    ///   - count: Number of suggestions to return
    ///   - gender: User's gender (nil or preferNotToSay shows all suggestions)
    ///   - ageGroup: User's age group (nil or preferNotToSay shows all suggestions)
    /// - Returns: Array of top habit suggestions, filtered by demographics
    public static func getTopSuggestions(
        _ count: Int,
        gender: UserGender?,
        ageGroup: UserAgeGroup?
    ) -> [HabitSuggestion] {
        let filtered = getSuggestions(for: gender, ageGroup: ageGroup)
        return Array(filtered.prefix(count))
    }
    
    // MARK: - Statistics & Metrics
    
    /// Get total count of available suggestions
    /// - Returns: Total number of habit suggestions
    public static var totalCount: Int {
        return allSuggestions.count
    }
    
    /// Get count of suggestions by category
    /// - Returns: Dictionary mapping category IDs to suggestion counts
    public static var countsByCategory: [String: Int] {
        return Dictionary(grouping: allSuggestions, by: { $0.categoryId })
            .mapValues { $0.count }
    }
    
    /// Get available category IDs
    /// - Returns: Array of unique category IDs
    public static var availableCategories: [String] {
        return Array(Set(allSuggestions.map { $0.categoryId })).sorted()
    }
}
