//
//  HabitModel.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation
import SwiftData

@Model public final class HabitModel: @unchecked Sendable {
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
    // Note: categoryId removed to eliminate dual source of truth with SwiftData relationship
    
    // MARK: - SwiftData Relationships
    @Relationship(deleteRule: .cascade, inverse: \HabitLogModel.habit) 
    var logs = [HabitLogModel]()
    
    var category: HabitCategoryModel?
    public init(id: UUID, name: String, colorHex: String, emoji: String?, kindRaw: Int,
                unitLabel: String?, dailyTarget: Double?, scheduleData: Data,
                remindersData: Data, startDate: Date, endDate: Date?, isActive: Bool, displayOrder: Int,
                category: HabitCategoryModel? = nil, suggestionId: String?) {
        self.id = id; self.name = name; self.colorHex = colorHex; self.emoji = emoji
        self.kindRaw = kindRaw; self.unitLabel = unitLabel; self.dailyTarget = dailyTarget
        self.scheduleData = scheduleData; self.remindersData = remindersData
        self.startDate = startDate; self.endDate = endDate; self.isActive = isActive
        self.displayOrder = displayOrder; self.suggestionId = suggestionId
        self.category = category
    }
    
    /// Convert SwiftData model to domain entity
    public func toEntity() throws -> Habit {
        let schedule = try JSONDecoder().decode(HabitSchedule.self, from: scheduleData)
        let reminders = try JSONDecoder().decode([ReminderTime].self, from: remindersData)
        let kind: HabitKind = (kindRaw == 0) ? .binary : .numeric
        
        return Habit(
            id: id, 
            name: name, 
            colorHex: colorHex, 
            emoji: emoji, 
            kind: kind,
            unitLabel: unitLabel, 
            dailyTarget: dailyTarget, 
            schedule: schedule,
            reminders: reminders, 
            startDate: startDate, 
            endDate: endDate, 
            isActive: isActive,
            displayOrder: displayOrder, 
            categoryId: category?.id, 
            suggestionId: suggestionId
        )
    }
    
    /// Create SwiftData model from domain entity
    public static func fromEntity(_ habit: Habit, context: ModelContext? = nil) throws -> HabitModel {
        let schedule = try JSONEncoder().encode(habit.schedule)
        let reminders = try JSONEncoder().encode(habit.reminders)
        let kindRaw = (habit.kind == .binary) ? 0 : 1
        
        // Set relationship from domain entity categoryId
        var category: HabitCategoryModel?
        if let categoryId = habit.categoryId, let context = context {
            let descriptor = FetchDescriptor<HabitCategoryModel>(predicate: #Predicate { $0.id == categoryId })
            category = try? context.fetch(descriptor).first
        }
        
        return HabitModel(
            id: habit.id, 
            name: habit.name, 
            colorHex: habit.colorHex, 
            emoji: habit.emoji,
            kindRaw: kindRaw, 
            unitLabel: habit.unitLabel, 
            dailyTarget: habit.dailyTarget,
            scheduleData: schedule, 
            remindersData: reminders, 
            startDate: habit.startDate,
            endDate: habit.endDate, 
            isActive: habit.isActive, 
            displayOrder: habit.displayOrder,
 
            category: category, 
            suggestionId: habit.suggestionId
        )
    }
}
