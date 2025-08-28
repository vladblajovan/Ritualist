//
//  HabitLogModel.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation
import SwiftData

@Model public final class HabitLogModel: @unchecked Sendable {
    @Attribute(.unique) public var id: UUID // TODO: Remove .unique when enabling CloudKit
    public var habitID: UUID = UUID() // CloudKit requires default values
    @Relationship var habit: HabitModel?
    public var date: Date = Date() // CloudKit requires default values
    public var value: Double?
    public init(id: UUID, habitID: UUID, habit: HabitModel?, date: Date, value: Double?) {
        self.id = id
        self.habitID = habitID
        self.date = date
        self.value = value
        self.habit = habit
    }
    
    /// Convert SwiftData model to domain entity
    public func toEntity() -> HabitLog {
        return HabitLog(id: id, habitID: habitID, date: date, value: value)
    }
    
    /// Create SwiftData model from domain entity
    public static func fromEntity(_ log: HabitLog, context: ModelContext? = nil) -> HabitLogModel {
        // Store both habitID (for CloudKit) and relationship (for local queries)
        var habit: HabitModel?
        if let context = context {
            let descriptor = FetchDescriptor<HabitModel>(predicate: #Predicate { $0.id == log.habitID })
            habit = try? context.fetch(descriptor).first
        }
        return HabitLogModel(id: log.id, habitID: log.habitID, habit: habit, date: log.date, value: log.value)
    }
}
