//
//  HabitLog.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public struct HabitLog: Identifiable, Codable, Hashable {
    public var id: UUID
    public var habitID: UUID
    public var date: Date
    public var value: Double?
    public init(id: UUID = UUID(), habitID: UUID, date: Date, value: Double? = nil) {
        self.id = id; self.habitID = habitID; self.date = date; self.value = value
    }
}
