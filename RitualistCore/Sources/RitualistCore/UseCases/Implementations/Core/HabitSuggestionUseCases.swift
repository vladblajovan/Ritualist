import Foundation

// MARK: - Habit Suggestion Use Case Implementations

public final class CreateHabitFromSuggestion: CreateHabitFromSuggestionUseCase {
    private let createHabit: CreateHabitUseCase

    public init(createHabit: CreateHabitUseCase) {
        self.createHabit = createHabit
    }

    /// Creates a habit from a suggestion.
    /// NOTE: Limit checking is handled at the UI layer (HabitsAssistantSheet, HabitsViewModel).
    /// This use case is pure business logic - it just creates the habit.
    public func execute(_ suggestion: HabitSuggestion) async -> CreateHabitFromSuggestionResult {
        do {
            let habit = suggestion.toHabit()
            let createdHabit = try await createHabit.execute(habit)
            return .success(habitId: createdHabit.id)
        } catch {
            return .error("Failed to create habit: \(error.localizedDescription)")
        }
    }
}

public final class RemoveHabitFromSuggestion: RemoveHabitFromSuggestionUseCase {
    private let deleteHabit: DeleteHabitUseCase
    
    public init(deleteHabit: DeleteHabitUseCase) {
        self.deleteHabit = deleteHabit
    }
    
    public func execute(suggestionId: String, habitId: UUID) async -> Bool {
        do {
            try await deleteHabit.execute(id: habitId)
            return true
        } catch {
            return false
        }
    }
}