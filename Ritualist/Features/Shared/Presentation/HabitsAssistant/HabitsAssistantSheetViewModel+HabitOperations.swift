//
//  HabitsAssistantSheetViewModel+HabitOperations.swift
//  Ritualist
//

import Foundation
import RitualistCore
import TipKit

// MARK: - Immediate Habit Operations

extension HabitsAssistantSheetViewModel {

    /// Add a habit immediately (creates in database)
    /// Returns true if successful, false if blocked by limit or error
    @discardableResult
    func addHabit(_ suggestion: HabitSuggestion) async -> Bool {
        // Check limit before adding
        let currentCount = addedSuggestionIds.count
        let canCreate = await checkHabitCreationLimit.execute(currentCount: currentCount)
        if !canCreate {
            onShowPaywall?()
            return false
        }

        // Create the habit immediately
        let result = await createHabitFromSuggestionUseCase.execute(suggestion)

        switch result {
        case .success(let habitId):
            addedSuggestionIds.insert(suggestion.id)
            suggestionToHabitMappings[suggestion.id] = habitId
            trackHabitAdded(habitId: suggestion.id, habitName: suggestion.name, category: suggestion.categoryId)
            await TapHabitTip.firstHabitAdded.donate()
            // Notify other views (Overview) that habits data changed
            NotificationCenter.default.post(name: .habitsDataDidChange, object: nil)
            logger.log(
                "Habit added successfully",
                level: .info,
                category: .ui,
                metadata: ["suggestionId": suggestion.id, "habitId": habitId.uuidString]
            )
            await refreshLimitStatus()
            return true

        case .alreadyExists(let habitId):
            // Habit already exists, just update our tracking state
            addedSuggestionIds.insert(suggestion.id)
            suggestionToHabitMappings[suggestion.id] = habitId
            logger.log(
                "Habit already existed (idempotent)",
                level: .info,
                category: .ui,
                metadata: ["suggestionId": suggestion.id, "habitId": habitId.uuidString]
            )
            return true

        case .error(let errorMessage):
            trackHabitAddFailed(habitId: suggestion.id, error: errorMessage)
            logger.log(
                "Failed to add habit",
                level: .error,
                category: .ui,
                metadata: ["suggestionId": suggestion.id, "error": errorMessage]
            )
            return false
        }
    }

    /// Remove a habit immediately (deletes from database)
    /// Returns true if successful, false if error
    @discardableResult
    func removeHabit(_ suggestionId: String) async -> Bool {
        // Find the habitId to delete
        guard let habitId = suggestionToHabitMappings[suggestionId] else {
            logger.log(
                "Cannot remove habit - no habitId found in mappings",
                level: .warning,
                category: .ui,
                metadata: ["suggestionId": suggestionId]
            )
            return false
        }

        // Delete the habit immediately
        let success = await removeHabitFromSuggestionUseCase.execute(suggestionId: suggestionId, habitId: habitId)

        if success {
            addedSuggestionIds.remove(suggestionId)
            suggestionToHabitMappings.removeValue(forKey: suggestionId)
            // Notify other views (Overview) that habits data changed
            NotificationCenter.default.post(name: .habitsDataDidChange, object: nil)
            logger.log(
                "Habit removed successfully",
                level: .info,
                category: .ui,
                metadata: ["suggestionId": suggestionId, "habitId": habitId.uuidString]
            )
            await refreshLimitStatus()
            return true
        } else {
            trackHabitRemoveFailed(habitId: suggestionId, error: "Delete operation failed")
            logger.log(
                "Failed to remove habit",
                level: .error,
                category: .ui,
                metadata: ["suggestionId": suggestionId, "habitId": habitId.uuidString]
            )
            return false
        }
    }

    /// Refresh the limit status
    func refreshLimitStatus() async {
        canCreateMoreHabits = await checkHabitCreationLimit.execute(currentCount: addedSuggestionIds.count)
    }

    /// Find suggestionId for a given habitId (used when removing habits)
    func suggestionId(for habitId: UUID) -> String? {
        suggestionToHabitMappings.first(where: { $0.value == habitId })?.key
    }
}
