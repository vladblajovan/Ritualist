//
//  HabitError.swift
//  RitualistCore
//
//  Created by Claude on 27.08.2025.
//

import Foundation

/// Errors related to habit operations
public enum HabitError: Error, LocalizedError, Equatable {
    case habitNotFound(id: UUID)
    case habitCreationFailed(reason: String)
    case habitUpdateFailed(reason: String)
    case habitDeletionFailed(reason: String)
    case invalidHabitData(field: String, reason: String)
    
    public var errorDescription: String? {
        switch self {
        case .habitNotFound(let id):
            return "Habit with ID \(id.uuidString) not found"
        case .habitCreationFailed(let reason):
            return "Failed to create habit: \(reason)"
        case .habitUpdateFailed(let reason):
            return "Failed to update habit: \(reason)"
        case .habitDeletionFailed(let reason):
            return "Failed to delete habit: \(reason)"
        case .invalidHabitData(let field, let reason):
            return "Invalid habit data for field '\(field)': \(reason)"
        }
    }
    
    public var failureReason: String? {
        return errorDescription
    }
}