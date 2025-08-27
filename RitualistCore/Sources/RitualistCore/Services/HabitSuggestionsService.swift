//
//  HabitSuggestionsService.swift
//  RitualistCore
//
//  Created by Claude on 16.08.2025.
//

import Foundation

/// Service for retrieving habit suggestions and recommendations
public protocol HabitSuggestionsService {
    /// Get all available habit suggestions
    func getSuggestions() -> [HabitSuggestion]
    
    /// Get habit suggestions filtered by category
    func getSuggestions(for categoryId: String) -> [HabitSuggestion]
    
    /// Get a specific habit suggestion by ID
    func getSuggestion(by id: String) -> HabitSuggestion?
}

// MARK: - Implementation

/// Default implementation using static habit suggestions data
public final class DefaultHabitSuggestionsService: HabitSuggestionsService {
    
    public init() {}
    
    public func getSuggestions() -> [HabitSuggestion] {
        return HabitSuggestionsData.getAllSuggestions()
    }
    
    public func getSuggestions(for categoryId: String) -> [HabitSuggestion] {
        return HabitSuggestionsData.getSuggestions(for: categoryId)
    }
    
    public func getSuggestion(by id: String) -> HabitSuggestion? {
        return HabitSuggestionsData.getSuggestion(by: id)
    }
}