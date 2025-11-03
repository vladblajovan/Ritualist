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
    public var displayOrder: Int
    public var categoryId: String?
    public var suggestionId: String?
    public var isPinned: Bool
    public var notes: String?  // Added in SchemaV4
    public var lastCompletedDate: Date?  // Added in SchemaV5
    public var archivedDate: Date?  // Added in SchemaV6

    public init(id: UUID = UUID(), name: String, colorHex: String = "#2DA9E3", emoji: String? = nil,
                kind: HabitKind = .binary, unitLabel: String? = nil, dailyTarget: Double? = nil,
                schedule: HabitSchedule = .daily, reminders: [ReminderTime] = [],
                startDate: Date = Date(), endDate: Date? = nil, isActive: Bool = true, displayOrder: Int = 0,
                categoryId: String? = nil, suggestionId: String? = nil, isPinned: Bool = false,
                notes: String? = nil, lastCompletedDate: Date? = nil, archivedDate: Date? = nil) {
        self.id = id; self.name = name; self.colorHex = colorHex; self.emoji = emoji
        self.kind = kind; self.unitLabel = unitLabel; self.dailyTarget = dailyTarget
        self.schedule = schedule; self.reminders = reminders
        self.startDate = startDate; self.endDate = endDate; self.isActive = isActive
        self.displayOrder = displayOrder
        self.categoryId = categoryId; self.suggestionId = suggestionId
        self.isPinned = isPinned
        self.notes = notes
        self.lastCompletedDate = lastCompletedDate
        self.archivedDate = archivedDate
    }
}
