//
//  HabitSuggestion.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public struct HabitSuggestion: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let emoji: String
    public let colorHex: String
    public let category: HabitSuggestionCategory
    public let kind: HabitKind
    public let unitLabel: String?
    public let dailyTarget: Double?
    public let schedule: HabitSchedule
    public let description: String
    
    public init(id: String, name: String, emoji: String, colorHex: String,
                category: HabitSuggestionCategory, kind: HabitKind,
                unitLabel: String? = nil, dailyTarget: Double? = nil,
                schedule: HabitSchedule = .daily, description: String) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.category = category
        self.kind = kind
        self.unitLabel = unitLabel
        self.dailyTarget = dailyTarget
        self.schedule = schedule
        self.description = description
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
            isActive: true
        )
    }
}
