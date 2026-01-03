//
//  NotificationError.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 27.08.2025.
//

import Foundation

/// Errors related to notification operations
public enum NotificationError: Error, LocalizedError, Equatable {
    case habitNotFound(id: UUID)
    case permissionDenied
    case schedulingFailed(reason: String)
    case missingRequiredData(field: String)
    case invalidActionData(reason: String)
    
    public var errorDescription: String? {
        switch self {
        case .habitNotFound(let id):
            return "Habit with ID \(id.uuidString) not found for notification"
        case .permissionDenied:
            return "Notification permission denied"
        case .schedulingFailed(let reason):
            return "Failed to schedule notification: \(reason)"
        case .missingRequiredData(let field):
            return "Missing required data for notification: \(field)"
        case .invalidActionData(let reason):
            return "Invalid notification action data: \(reason)"
        }
    }
    
    public var failureReason: String? {
        return errorDescription
    }
}
