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
    case success(habitId: UUID)
    case error(String)
}