//
//  SDHabitLog.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation
import SwiftData

@Model public final class SDHabitLog: @unchecked Sendable {
    @Attribute(.unique) public var id: UUID // TODO: Remove .unique when enabling CloudKit
    @Relationship(deleteRule: .nullify)
    var habit: SDHabit?
    public var date: Date = Date() // CloudKit requires default values
    public var value: Double?
    public init(id: UUID, habit: SDHabit?, date: Date, value: Double?) {
        self.id = id; self.date = date; self.value = value
        self.habit = habit
    }
}
