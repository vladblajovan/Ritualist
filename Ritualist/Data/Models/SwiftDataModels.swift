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
    public init(id: UUID, name: String, colorHex: String, emoji: String?, kindRaw: Int,
                unitLabel: String?, dailyTarget: Double?, scheduleData: Data,
                remindersData: Data, startDate: Date, endDate: Date?, isActive: Bool) {
        self.id = id; self.name = name; self.colorHex = colorHex; self.emoji = emoji
        self.kindRaw = kindRaw; self.unitLabel = unitLabel; self.dailyTarget = dailyTarget
        self.scheduleData = scheduleData; self.remindersData = remindersData
        self.startDate = startDate; self.endDate = endDate; self.isActive = isActive
    }
}

@Model public final class SDHabitLog: @unchecked Sendable {
    @Attribute(.unique) public var id: UUID
    public var habitID: UUID
    public var date: Date
    public var value: Double?
    public init(id: UUID, habitID: UUID, date: Date, value: Double?) {
        self.id = id; self.habitID = habitID; self.date = date; self.value = value
    }
}

@Model public final class SDUserProfile: @unchecked Sendable {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var avatarImageData: Data?
    public var firstDayOfWeek: Int
    public var appearance: Int
    public init(id: UUID, name: String, avatarImageData: Data?, firstDayOfWeek: Int, appearance: Int) {
        self.id = id; self.name = name; self.avatarImageData = avatarImageData
        self.firstDayOfWeek = firstDayOfWeek; self.appearance = appearance
    }
}

@Model public final class SDOnboardingState: @unchecked Sendable {
    @Attribute(.unique) public var id: UUID
    public var isCompleted: Bool
    public var completedDate: Date?
    public var userName: String?
    public var hasGrantedNotifications: Bool
    
    public init(id: UUID = UUID(), isCompleted: Bool = false, completedDate: Date? = nil,
                userName: String? = nil, hasGrantedNotifications: Bool = false) {
        self.id = id
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.userName = userName
        self.hasGrantedNotifications = hasGrantedNotifications
    }
}
