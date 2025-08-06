//
//  NotificationAction.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 06.08.2025.
//

import Foundation

public enum NotificationAction: String, CaseIterable, Codable {
    case log = "LOG_HABIT"
    case remindLater = "SNOOZE_20MIN"
    case dismiss = "DISMISS"
    
    public var title: String {
        switch self {
        case .log:
            return "Log Habit"
        case .remindLater:
            return "Remind me in 20min"
        case .dismiss:
            return "Dismiss"
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