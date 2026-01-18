//
//  HabitsAssistantSheetViewModel+Tracking.swift
//  Ritualist
//

import Foundation

// MARK: - Tracking Methods

extension HabitsAssistantSheetViewModel {

    func trackHabitSuggestionViewed(habitId: String, category: String) {
        trackUserAction?.execute(action: .habitsAssistantHabitSuggestionViewed(
            habitId: habitId,
            category: category
        ), context: [:])
    }

    func trackHabitAdded(habitId: String, habitName: String, category: String) {
        trackUserAction?.execute(action: .habitsAssistantHabitAdded(
            habitId: habitId,
            habitName: habitName,
            category: category
        ), context: [:])
    }

    func trackHabitAddFailed(habitId: String, error: String) {
        trackUserAction?.execute(action: .habitsAssistantHabitAddFailed(
            habitId: habitId,
            error: error
        ), context: [:])
    }

    func trackHabitRemoved(habitId: String, habitName: String, category: String) {
        trackUserAction?.execute(action: .habitsAssistantHabitRemoved(
            habitId: habitId,
            habitName: habitName,
            category: category
        ), context: [:])
    }

    func trackHabitRemoveFailed(habitId: String, error: String) {
        trackUserAction?.execute(action: .habitsAssistantHabitRemoveFailed(
            habitId: habitId,
            error: error
        ), context: [:])
    }
}
