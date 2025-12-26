//
//  HabitLog.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public struct HabitLog: Identifiable, Codable, Hashable, Sendable {
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
    
    /// Convenience initializer that captures current device timezone for the given date
    /// IMPORTANT: This uses the provided date (not current time) with current device timezone
    public static func withCurrentTimezone(id: UUID = UUID(), habitID: UUID, date: Date, value: Double? = nil) -> HabitLog {
        // Use the provided date, not Date() - this allows retroactive logging
        return HabitLog(id: id, habitID: habitID, date: date, value: value, timezone: TimeZone.current.identifier)
    }

    /// Resolve the stored timezone identifier to a TimeZone, with fallback for invalid identifiers
    /// - Parameter fallback: Timezone to use if the stored identifier is invalid
    /// - Returns: The resolved TimeZone
    public func resolvedTimezone(fallback: TimeZone) -> TimeZone {
        TimeZone(identifier: timezone) ?? fallback
    }
}
