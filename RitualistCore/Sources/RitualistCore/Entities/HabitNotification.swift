//
//  HabitNotification.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 06.08.2025.
//

import Foundation

public struct HabitNotification: Identifiable, Codable, Hashable {
    public let id: String
    public let habitId: UUID
    public let habitName: String
    public let reminderTime: ReminderTime
    public let scheduledDate: Date
    public let actions: [NotificationAction]
    
    public init(
        id: String = UUID().uuidString,
        habitId: UUID,
        habitName: String,
        reminderTime: ReminderTime,
        scheduledDate: Date = Date(),
        actions: [NotificationAction] = [.log, .remindLater, .dismiss]
    ) {
        self.id = id
        self.habitId = habitId
        self.habitName = habitName
        self.reminderTime = reminderTime
        self.scheduledDate = scheduledDate
        self.actions = actions
    }
    
    public var notificationIdentifier: String {
        return "\(habitId.uuidString)-\(reminderTime.hour)-\(reminderTime.minute)"
    }
    
    public var title: String {
        return "Time for \(habitName)"
    }
    
    public var body: String {
        let timeString = String(format: "%02d:%02d", reminderTime.hour, reminderTime.minute)
        return "It's \(timeString) - time to work on your \(habitName) habit!"
    }
}