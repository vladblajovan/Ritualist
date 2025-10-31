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
    public var date: Date  // Always stored as UTC timestamp
    public var value: Double?
    public var timezone: String  // IANA timezone identifier (e.g., "America/New_York")
    
    public init(id: UUID = UUID(), habitID: UUID, date: Date, value: Double? = nil, timezone: String? = nil) {
        self.id = id
        self.habitID = habitID
        self.date = date
        self.value = value
        self.timezone = timezone ?? TimeZone.current.identifier
    }
    
    /// Convenience initializer that automatically captures current timezone context
    public static func withCurrentTimezone(id: UUID = UUID(), habitID: UUID, date: Date, value: Double? = nil) -> HabitLog {
        let (utcTimestamp, timezoneId) = CalendarUtils.createTimestampedEntry()
        return HabitLog(id: id, habitID: habitID, date: utcTimestamp, value: value, timezone: timezoneId)
    }
}
