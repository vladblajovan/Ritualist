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
    private let suggestionsService: HabitSuggestionsService
    private let userActionTracker: UserActionTrackerService?
    
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
        suggestionsService: HabitSuggestionsService,
        userActionTracker: UserActionTrackerService? = nil
    ) {
        self.getPredefinedCategoriesUseCase = getPredefinedCategoriesUseCase
        self.getHabitsFromSuggestionsUseCase = getHabitsFromSuggestionsUseCase
        self.suggestionsService = suggestionsService
        self.userActionTracker = userActionTracker
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
        userActionTracker?.track(.habitsAssistantCategorySelected(category: category.name))
    }
    
    public func clearCategorySelection() {
        selectedCategory = nil
        userActionTracker?.track(.habitsAssistantCategoryCleared)
    }
    
    public func getSuggestions() -> [HabitSuggestion] {
        if let selectedCategory = selectedCategory {
            return suggestionsService.getSuggestions(for: selectedCategory.id)
        } else {
            // Show all suggestions when no category is selected
            return suggestionsService.getSuggestions()
        }
    }
    
    public func getAllSuggestions() -> [HabitSuggestion] {
        // Always return all suggestions regardless of category filter
        return suggestionsService.getSuggestions()
    }
    
    public func initializeWithExistingHabits(_ existingHabits: [Habit]) {
        // Get all suggestion IDs from all categories
        let allSuggestions = suggestionsService.getSuggestions()
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
        userActionTracker?.track(.habitsAssistantHabitSuggestionViewed(
            habitId: habitId,
            category: category
        ))
    }
    
    public func trackHabitAdded(habitId: String, habitName: String, category: String) {
        userActionTracker?.track(.habitsAssistantHabitAdded(
            habitId: habitId,
            habitName: habitName,
            category: category
        ))
    }
    
    public func trackHabitAddFailed(habitId: String, error: String) {
        userActionTracker?.track(.habitsAssistantHabitAddFailed(
            habitId: habitId,
            error: error
        ))
    }
    
    public func trackHabitRemoved(habitId: String, habitName: String, category: String) {
        userActionTracker?.track(.habitsAssistantHabitRemoved(
            habitId: habitId,
            habitName: habitName,
            category: category
        ))
    }
    
    public func trackHabitRemoveFailed(habitId: String, error: String) {
        userActionTracker?.track(.habitsAssistantHabitRemoveFailed(
            habitId: habitId,
            error: error
        ))
    }
    
    // MARK: - Private Methods
}
