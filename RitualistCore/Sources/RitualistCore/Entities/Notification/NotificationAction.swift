//
//  NotificationAction.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 06.08.2025.
//

import Foundation
import UserNotifications

public enum NotificationAction: String, CaseIterable, Codable {
    case log = "LOG_HABIT"
    case remindLater = "SNOOZE_20MIN"
    case dismiss = "DISMISS"
    
    public func title(for habitKind: HabitKind?) -> String {
        switch self {
        case .log:
            guard let habitKind = habitKind else { return "Log Habit" }
            switch habitKind {
            case .binary:
                return "Mark Complete"
            case .numeric:
                return "Log Progress"
            }
        case .remindLater:
            return "Remind me in 20min"
        case .dismiss:
            return "Dismiss"
        }
    }
    
    public var title: String {
        return title(for: nil)
    }
    
    public func options(for habitKind: HabitKind?) -> UNNotificationActionOptions {
        switch self {
        case .log:
            guard let habitKind = habitKind else { return [.foreground] }
            switch habitKind {
            case .binary:
                return [] // Background execution for binary habits
            case .numeric:
                return [.foreground] // Foreground for numeric habits (need UI)
            }
        case .remindLater, .dismiss:
            return [] // Background execution
        }
    }
    
    public var systemImage: String {
        switch self {
        case .log:
            return "checkmark.circle.fill"
        case .remindLater:
            return "clock.fill"
        case .dismiss:
            return "xmark.circle.fill"
        }
    }
    
    public var isDestructive: Bool {
        switch self {
        case .dismiss:
            return false
        default:
            return false
        }
    }
}