import Foundation

// MARK: - Habit Suggestion Use Case Implementations

public final class CreateHabitFromSuggestion: CreateHabitFromSuggestionUseCase {
    private let createHabit: CreateHabitUseCase
    private let getHabitCount: GetHabitCountUseCase
    private let checkHabitCreationLimit: CheckHabitCreationLimitUseCase
    private let featureGatingService: FeatureGatingService
    
    public init(createHabit: CreateHabitUseCase,
                getHabitCount: GetHabitCountUseCase,
                checkHabitCreationLimit: CheckHabitCreationLimitUseCase,
                featureGatingService: FeatureGatingService) {
        self.createHabit = createHabit
        self.getHabitCount = getHabitCount
        self.checkHabitCreationLimit = checkHabitCreationLimit
        self.featureGatingService = featureGatingService
    }
    
    public func execute(_ suggestion: HabitSuggestion) async -> CreateHabitFromSuggestionResult {
        // First get current habit count
        let currentCount = await getHabitCount.execute()
        
        // Check if user can create more habits
        let canCreate = await checkHabitCreationLimit.execute(currentCount: currentCount)
        
        if !canCreate {
            let message = featureGatingService.getFeatureBlockedMessage(for: .unlimitedHabits)
            return .limitReached(message: message)
        }
        
        // If they can create, proceed with habit creation using CreateHabit use case
        // This ensures proper displayOrder is set (habit will be added to the end of the list)
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