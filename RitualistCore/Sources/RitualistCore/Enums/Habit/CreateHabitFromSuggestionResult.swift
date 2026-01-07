//
//  CreateHabitFromSuggestionResult.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//


import Foundation

/// Result of creating a habit from a suggestion.
/// NOTE: Limit checking is handled at the UI layer (HabitsAssistantSheetViewModel, HabitsViewModel),
/// not in the use case. The UI should check `canCreateMoreHabits` BEFORE calling the use case.
public enum CreateHabitFromSuggestionResult {
    /// Habit was successfully created
    case success(habitId: UUID)
    /// Habit already existed for this suggestion (idempotent - returned existing ID)
    /// This can indicate stale ViewModel state - the calling code may want to log this for debugging.
    case alreadyExists(habitId: UUID)
    /// Creation failed with an error message
    case error(String)

    /// Returns the habit ID for both success and alreadyExists cases
    public var habitId: UUID? {
        switch self {
        case .success(let id), .alreadyExists(let id):
            return id
        case .error:
            return nil
        }
    }

    /// Whether the operation resulted in a usable habit (created or existing)
    public var isSuccessful: Bool {
        switch self {
        case .success, .alreadyExists:
            return true
        case .error:
            return false
        }
    }
}