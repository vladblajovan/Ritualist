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
    public var locationConfiguration: LocationConfiguration?  // Added in SchemaV7
    public var priorityLevel: Int?  // Added in SchemaV8 (1=Low, 2=Medium, 3=High)

    public init(id: UUID = UUID(), name: String, colorHex: String = "#2DA9E3", emoji: String? = nil,
                kind: HabitKind = .binary, unitLabel: String? = nil, dailyTarget: Double? = nil,
                schedule: HabitSchedule = .daily, reminders: [ReminderTime] = [],
                startDate: Date = Date(), endDate: Date? = nil, isActive: Bool = true, displayOrder: Int = 0,
                categoryId: String? = nil, suggestionId: String? = nil, isPinned: Bool = false,
                notes: String? = nil, lastCompletedDate: Date? = nil, archivedDate: Date? = nil,
                locationConfiguration: LocationConfiguration? = nil, priorityLevel: Int? = nil) {
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
        self.locationConfiguration = locationConfiguration
        self.priorityLevel = priorityLevel
    }
}

// MARK: - Schedule Convenience Methods

public extension Habit {
    /// Checks if this habit is scheduled on the given date.
    /// A habit is scheduled if:
    /// 1. The date is on or after the habit's start date
    /// 2. The schedule pattern matches the date (daily or specific days of week)
    ///
    /// - Parameters:
    ///   - date: The date to check
    ///   - timezone: The timezone to use for date calculations (defaults to current)
    /// - Returns: `true` if the habit is scheduled on this date
    func isScheduledOn(date: Date, timezone: TimeZone = .current) -> Bool {
        let dateStart = CalendarUtils.startOfDayLocal(for: date, timezone: timezone)
        let habitStartDay = CalendarUtils.startOfDayLocal(for: startDate, timezone: timezone)
        return dateStart >= habitStartDay && schedule.isActiveOn(date: date)
    }
}
