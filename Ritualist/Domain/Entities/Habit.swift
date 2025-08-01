//
//  Habit.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public struct Habit: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var colorHex: String
    public var emoji: String?
    public var kind: HabitKind
    public var unitLabel: String?
    public var dailyTarget: Double?
    public var schedule: HabitSchedule
    public var reminders: [ReminderTime]
    public var startDate: Date
    public var endDate: Date?
    public var isActive: Bool
    public init(id: UUID = UUID(), name: String, colorHex: String = "#2DA9E3", emoji: String? = nil,
                kind: HabitKind = .binary, unitLabel: String? = nil, dailyTarget: Double? = nil,
                schedule: HabitSchedule = .daily, reminders: [ReminderTime] = [],
                startDate: Date = Date(), endDate: Date? = nil, isActive: Bool = true) {
        self.id = id; self.name = name; self.colorHex = colorHex; self.emoji = emoji
        self.kind = kind; self.unitLabel = unitLabel; self.dailyTarget = dailyTarget
        self.schedule = schedule; self.reminders = reminders
        self.startDate = startDate; self.endDate = endDate; self.isActive = isActive
    }
}
