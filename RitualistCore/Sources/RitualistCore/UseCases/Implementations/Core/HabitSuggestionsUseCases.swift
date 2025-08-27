import Foundation

// MARK: - Habit Suggestions Use Case Implementations

public protocol GetHabitsFromSuggestionsUseCase {
    func execute(existingHabits: [Habit], suggestionIds: [String]) -> (addedSuggestions: Set<String>, habitMappings: [String: UUID])
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