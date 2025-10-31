import Foundation

// MARK: - Habit Suggestions Use Case Implementations

/// UseCase for retrieving habit suggestions
public protocol GetSuggestionsUseCase {
    /// Get all available habit suggestions
    func execute() -> [HabitSuggestion]

    /// Get habit suggestions filtered by category
    func execute(categoryId: String) -> [HabitSuggestion]

    /// Get a specific habit suggestion by ID
    func execute(suggestionId: String) -> HabitSuggestion?
}

public protocol GetHabitsFromSuggestionsUseCase {
    func execute(existingHabits: [Habit], suggestionIds: [String]) -> (addedSuggestions: Set<String>, habitMappings: [String: UUID])
}

// MARK: - Implementations

public final class GetSuggestions: GetSuggestionsUseCase {
    private let suggestionsService: HabitSuggestionsService

    public init(suggestionsService: HabitSuggestionsService) {
        self.suggestionsService = suggestionsService
    }

    public func execute() -> [HabitSuggestion] {
        return suggestionsService.getSuggestions()
    }

    public func execute(categoryId: String) -> [HabitSuggestion] {
        return suggestionsService.getSuggestions(for: categoryId)
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