//
//  HabitSuggestion.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public struct HabitSuggestion: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let emoji: String
    public let colorHex: String
    public let categoryId: String
    public let kind: HabitKind
    public let unitLabel: String?
    public let dailyTarget: Double?
    public let schedule: HabitSchedule
    public let description: String

    /// Personality trait weights for this habit suggestion
    /// Used for personality analysis when user selects this habit
    public let personalityWeights: [String: Double]?

    /// Age groups this suggestion is visible to. `nil` means visible to all.
    public let visibleToAgeGroups: [UserAgeGroup]?

    /// Genders this suggestion is visible to. `nil` means visible to all.
    public let visibleToGenders: [UserGender]?

    public init(id: String, name: String, emoji: String, colorHex: String,
                categoryId: String, kind: HabitKind,
                unitLabel: String? = nil, dailyTarget: Double? = nil,
                schedule: HabitSchedule = .daily, description: String,
                personalityWeights: [String: Double]? = nil,
                visibleToAgeGroups: [UserAgeGroup]? = nil,
                visibleToGenders: [UserGender]? = nil) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.categoryId = categoryId
        self.kind = kind
        self.unitLabel = unitLabel
        self.dailyTarget = dailyTarget
        self.schedule = schedule
        self.description = description
        self.personalityWeights = personalityWeights
        self.visibleToAgeGroups = visibleToAgeGroups
        self.visibleToGenders = visibleToGenders
    }

    // MARK: - Visibility Filtering

    /// Check if this suggestion should be visible for a given user demographic
    /// - Parameters:
    ///   - gender: User's gender (nil or preferNotToSay shows all suggestions)
    ///   - ageGroup: User's age group (nil or preferNotToSay shows all suggestions)
    /// - Returns: true if the suggestion should be shown to this user
    public func isVisible(for gender: UserGender?, ageGroup: UserAgeGroup?) -> Bool {
        // Check gender visibility
        let genderVisible: Bool
        if let allowedGenders = visibleToGenders {
            // If user prefers not to say or didn't specify, show all
            if gender == nil || gender == .preferNotToSay {
                genderVisible = true
            } else {
                genderVisible = allowedGenders.contains(gender!)
            }
        } else {
            // nil means visible to all genders
            genderVisible = true
        }

        // Check age group visibility
        let ageVisible: Bool
        if let allowedAges = visibleToAgeGroups {
            // If user prefers not to say or didn't specify, show all
            if ageGroup == nil || ageGroup == .preferNotToSay {
                ageVisible = true
            } else {
                ageVisible = allowedAges.contains(ageGroup!)
            }
        } else {
            // nil means visible to all age groups
            ageVisible = true
        }

        return genderVisible && ageVisible
    }
    
    /// Convert suggestion to a habit entity
    public func toHabit() -> Habit {
        Habit(
            name: name,
            colorHex: colorHex,
            emoji: emoji,
            kind: kind,
            unitLabel: unitLabel,
            dailyTarget: dailyTarget,
            schedule: schedule,
            reminders: [],
            startDate: Date(),
            endDate: nil,
            isActive: true,
            categoryId: categoryId,  // Use actual category ID for proper duplicate detection
            suggestionId: id         // Store suggestion ID for tracking which suggestion was used
        )
    }
}
