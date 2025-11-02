//
//  HabitsAssistantViewModel.swift
//  Ritualist
//
//  Created by Claude on 03.08.2025.
//

import Foundation
import Observation
import RitualistCore

@MainActor @Observable
public final class HabitsAssistantViewModel {
    
    // MARK: - Dependencies
    private let getPredefinedCategoriesUseCase: GetPredefinedCategoriesUseCase
    private let getHabitsFromSuggestionsUseCase: GetHabitsFromSuggestionsUseCase
    private let getSuggestionsUseCase: GetSuggestionsUseCase
    private let trackUserAction: TrackUserActionUseCase?
    
    // MARK: - State
    public private(set) var categories: [HabitCategory] = []
    public var selectedCategory: HabitCategory?
    public private(set) var isLoadingCategories = false
    public private(set) var categoriesError: Error?
    public private(set) var addedSuggestionIds: Set<String> = []
    public private(set) var suggestionToHabitMappings: [String: UUID] = [:]
    
    // MARK: - Initialization
    public init(
        getPredefinedCategoriesUseCase: GetPredefinedCategoriesUseCase,
        getHabitsFromSuggestionsUseCase: GetHabitsFromSuggestionsUseCase,
        getSuggestionsUseCase: GetSuggestionsUseCase,
        trackUserAction: TrackUserActionUseCase? = nil
    ) {
        self.getPredefinedCategoriesUseCase = getPredefinedCategoriesUseCase
        self.getHabitsFromSuggestionsUseCase = getHabitsFromSuggestionsUseCase
        self.getSuggestionsUseCase = getSuggestionsUseCase
        self.trackUserAction = trackUserAction
    }
    
    // MARK: - Public Methods
    public func loadCategories() async {
        isLoadingCategories = true
        categoriesError = nil
        
        do {
            categories = try await getPredefinedCategoriesUseCase.execute()
            // Start with no category selected to show all habits
        } catch {
            categoriesError = error
            categories = []
        }
        
        isLoadingCategories = false
    }
    
    public func selectCategory(_ category: HabitCategory) {
        selectedCategory = category
        trackUserAction?.execute(action: .habitsAssistantCategorySelected(category: category.name), context: [:])
    }

    public func clearCategorySelection() {
        selectedCategory = nil
        trackUserAction?.execute(action: .habitsAssistantCategoryCleared, context: [:])
    }
    
    public func getSuggestions() -> [HabitSuggestion] {
        if let selectedCategory = selectedCategory {
            return getSuggestionsUseCase.execute(categoryId: selectedCategory.id)
        } else {
            // Show all suggestions when no category is selected
            return getSuggestionsUseCase.execute()
        }
    }

    public func getAllSuggestions() -> [HabitSuggestion] {
        // Always return all suggestions regardless of category filter
        getSuggestionsUseCase.execute()
    }

    public func initializeWithExistingHabits(_ existingHabits: [Habit]) {
        // Get all suggestion IDs from all categories
        let allSuggestions = getSuggestionsUseCase.execute()
        let allSuggestionIds = allSuggestions.map { $0.id }
        
        // Use simplified logic with addedFromSuggestion field
        let (addedSuggestions, habitMappings) = getHabitsFromSuggestionsUseCase.execute(
            existingHabits: existingHabits, 
            suggestionIds: allSuggestionIds
        )
        addedSuggestionIds = addedSuggestions
        suggestionToHabitMappings = habitMappings
    }
    
    public func markSuggestionAsAdded(_ suggestionId: String, habitId: UUID) {
        addedSuggestionIds.insert(suggestionId)
        suggestionToHabitMappings[suggestionId] = habitId
    }
    
    public func markSuggestionAsRemoved(_ suggestionId: String) {
        addedSuggestionIds.remove(suggestionId)
        suggestionToHabitMappings.removeValue(forKey: suggestionId)
    }
    
    // MARK: - Tracking Methods
    public func trackHabitSuggestionViewed(habitId: String, category: String) {
        trackUserAction?.execute(action: .habitsAssistantHabitSuggestionViewed(
            habitId: habitId,
            category: category
        ), context: [:])
    }

    public func trackHabitAdded(habitId: String, habitName: String, category: String) {
        trackUserAction?.execute(action: .habitsAssistantHabitAdded(
            habitId: habitId,
            habitName: habitName,
            category: category
        ), context: [:])
    }

    public func trackHabitAddFailed(habitId: String, error: String) {
        trackUserAction?.execute(action: .habitsAssistantHabitAddFailed(
            habitId: habitId,
            error: error
        ), context: [:])
    }

    public func trackHabitRemoved(habitId: String, habitName: String, category: String) {
        trackUserAction?.execute(action: .habitsAssistantHabitRemoved(
            habitId: habitId,
            habitName: habitName,
            category: category
        ), context: [:])
    }

    public func trackHabitRemoveFailed(habitId: String, error: String) {
        trackUserAction?.execute(action: .habitsAssistantHabitRemoveFailed(
            habitId: habitId,
            error: error
        ), context: [:])
    }
    
    // MARK: - Private Methods
}
