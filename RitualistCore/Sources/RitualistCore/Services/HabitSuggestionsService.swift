//
//  HabitSuggestionsService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import Foundation

/// Service for retrieving habit suggestions and recommendations.
/// This is a pure data service - demographics filtering is handled by the use case layer.
public protocol HabitSuggestionsService: Sendable {
    /// Get all available habit suggestions (optionally filtered by demographics)
    func getSuggestions(gender: UserGender?, ageGroup: UserAgeGroup?) -> [HabitSuggestion]

    /// Get habit suggestions filtered by category (and optionally demographics)
    func getSuggestions(for categoryId: String, gender: UserGender?, ageGroup: UserAgeGroup?) -> [HabitSuggestion]

    /// Get a specific habit suggestion by ID
    func getSuggestion(by id: String) -> HabitSuggestion?
}

// MARK: - Implementation

/// Default implementation using static habit suggestions data
public final class DefaultHabitSuggestionsService: HabitSuggestionsService, Sendable {

    public init() {}

    public func getSuggestions(gender: UserGender?, ageGroup: UserAgeGroup?) -> [HabitSuggestion] {
        return HabitSuggestionsData.getSuggestions(for: gender, ageGroup: ageGroup)
    }

    public func getSuggestions(for categoryId: String, gender: UserGender?, ageGroup: UserAgeGroup?) -> [HabitSuggestion] {
        return HabitSuggestionsData.getSuggestions(for: categoryId, gender: gender, ageGroup: ageGroup)
    }

    public func getSuggestion(by id: String) -> HabitSuggestion? {
        return HabitSuggestionsData.getSuggestion(by: id)
    }
}
