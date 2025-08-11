//
//  SDHabit.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//ioen

import Foundation
import SwiftData

@Model public final class SDHabit: @unchecked Sendable {
    @Attribute(.unique) public var id: UUID // TODO: Remove .unique when enabling CloudKit
    public var name: String = "" // CloudKit requires default values
    public var colorHex: String = "#007AFF" // CloudKit requires default values
    public var emoji: String?
    public var kindRaw: Int = 0 // CloudKit requires default values (0 = binary)
    public var unitLabel: String?
    public var dailyTarget: Double?
    public var scheduleData: Data = Data() // CloudKit requires default values
    public var remindersData: Data = Data() // CloudKit requires default values
    public var startDate: Date = Date() // CloudKit requires default values
    public var endDate: Date?
    public var isActive: Bool = true // CloudKit requires default values
    public var displayOrder: Int = 0 // CloudKit requires default values
    public var suggestionId: String?
    public var categoryId: String? // CloudKit requires default values - explicit foreign key
    
    // MARK: - SwiftData Relationships
    @Relationship(deleteRule: .cascade, inverse: \SDHabitLog.habit) 
    var logs = [SDHabitLog]()
    
    var category: SDCategory?
    public init(id: UUID, name: String, colorHex: String, emoji: String?, kindRaw: Int,
                unitLabel: String?, dailyTarget: Double?, scheduleData: Data,
                remindersData: Data, startDate: Date, endDate: Date?, isActive: Bool, displayOrder: Int,
                categoryId: String? = nil, category: SDCategory? = nil, suggestionId: String?) {
        self.id = id; self.name = name; self.colorHex = colorHex; self.emoji = emoji
        self.kindRaw = kindRaw; self.unitLabel = unitLabel; self.dailyTarget = dailyTarget
        self.scheduleData = scheduleData; self.remindersData = remindersData
        self.startDate = startDate; self.endDate = endDate; self.isActive = isActive
        self.displayOrder = displayOrder; self.categoryId = categoryId; self.suggestionId = suggestionId
        self.category = category
    }
}
