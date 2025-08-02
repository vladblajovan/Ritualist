//
//  SDHabit.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation
import SwiftData

@Model public final class SDHabit: @unchecked Sendable {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var colorHex: String
    public var emoji: String?
    public var kindRaw: Int // 0 binary, 1 numeric
    public var unitLabel: String?
    public var dailyTarget: Double?
    public var scheduleData: Data // encoded HabitSchedule
    public var remindersData: Data // encoded [ReminderTime]
    public var startDate: Date
    public var endDate: Date?
    public var isActive: Bool
    public var displayOrder: Int
    public init(id: UUID, name: String, colorHex: String, emoji: String?, kindRaw: Int,
                unitLabel: String?, dailyTarget: Double?, scheduleData: Data,
                remindersData: Data, startDate: Date, endDate: Date?, isActive: Bool, displayOrder: Int) {
        self.id = id; self.name = name; self.colorHex = colorHex; self.emoji = emoji
        self.kindRaw = kindRaw; self.unitLabel = unitLabel; self.dailyTarget = dailyTarget
        self.scheduleData = scheduleData; self.remindersData = remindersData
        self.startDate = startDate; self.endDate = endDate; self.isActive = isActive
        self.displayOrder = displayOrder
    }
}
