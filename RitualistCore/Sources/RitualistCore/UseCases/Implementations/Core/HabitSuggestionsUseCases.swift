import Foundation

// MARK: - Habit Suggestions Use Case Implementations

/// UseCase for retrieving habit suggestions.
/// Demographics are passed as parameters - the caller (ViewModel) fetches them from UserService.
public protocol GetSuggestionsUseCase {
    /// Get all available habit suggestions (filtered by demographics if provided)
    func execute(gender: UserGender?, ageGroup: UserAgeGroup?) -> [HabitSuggestion]

    /// Get habit suggestions filtered by category (and demographics if provided)
    func execute(categoryId: String, gender: UserGender?, ageGroup: UserAgeGroup?) -> [HabitSuggestion]

    /// Get a specific habit suggestion by ID
    func execute(suggestionId: String) -> HabitSuggestion?
}

public protocol GetHabitsFromSuggestionsUseCase {
    func execute(existingHabits: [Habit], suggestionIds: [String]) -> (addedSuggestions: Set<String>, habitMappings: [String: UUID])
}

// MARK: - Implementations

/// Pure use case that delegates to the suggestions service.
/// No actor isolation needed - demographics are passed as parameters.
public final class GetSuggestions: GetSuggestionsUseCase {
    private let suggestionsService: HabitSuggestionsService

    public init(suggestionsService: HabitSuggestionsService) {
        self.suggestionsService = suggestionsService
    }

    public func execute(gender: UserGender?, ageGroup: UserAgeGroup?) -> [HabitSuggestion] {
        return suggestionsService.getSuggestions(gender: gender, ageGroup: ageGroup)
    }

    public func execute(categoryId: String, gender: UserGender?, ageGroup: UserAgeGroup?) -> [HabitSuggestion] {
        return suggestionsService.getSuggestions(for: categoryId, gender: gender, ageGroup: ageGroup)
    }

    public func execute(suggestionId: String) -> HabitSuggestion? {
        return suggestionsService.getSuggestion(by: suggestionId)
    }
}

public final class GetHabitsFromSuggestions: GetHabitsFromSuggestionsUseCase {
    public init() {}

    public func execute(existingHabits: [Habit], suggestionIds: [String]) -> (addedSuggestions: Set<String>, habitMappings: [String: UUID]) {
        var mappedSuggestions: Set<String> = []
        var habitMappings: [String: UUID] = [:]

        let suggestionIdSet = Set(suggestionIds)

        // SIMPLE LOGIC: Filter habits that were added from suggestions
        let habitsFromSuggestions = existingHabits.filter { habit in
            habit.suggestionId != nil &&
            (habit.suggestionId.map { suggestionIdSet.contains($0) } ?? false)
        }

        for habit in habitsFromSuggestions {
            if let suggestionId = habit.suggestionId {
                mappedSuggestions.insert(suggestionId)
                habitMappings[suggestionId] = habit.id
            }
        }

        return (addedSuggestions: mappedSuggestions, habitMappings: habitMappings)
    }
}
