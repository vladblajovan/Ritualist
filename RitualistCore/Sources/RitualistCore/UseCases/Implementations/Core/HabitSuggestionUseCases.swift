import Foundation

// MARK: - Habit Suggestion Use Case Implementations

public final class CreateHabitFromSuggestion: CreateHabitFromSuggestionUseCase {
    private let createHabit: CreateHabitUseCase
    private let getAllHabits: GetAllHabitsUseCase
    private let logger: DebugLogger

    public init(
        createHabit: CreateHabitUseCase,
        getAllHabits: GetAllHabitsUseCase,
        logger: DebugLogger = DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "habit-suggestion")
    ) {
        self.createHabit = createHabit
        self.getAllHabits = getAllHabits
        self.logger = logger
    }

    /// Creates a habit from a suggestion.
    /// NOTE: Limit checking is handled at the UI layer (HabitsAssistantSheet, HabitsViewModel).
    /// This use case is pure business logic - it just creates the habit.
    /// SAFETY: If habit with same suggestionId already exists, returns `.alreadyExists` (idempotent).
    public func execute(_ suggestion: HabitSuggestion) async -> CreateHabitFromSuggestionResult {
        do {
            // IDEMPOTENT CHECK: If habit already exists for this suggestion, return its ID
            // This handles cases where existingHabits in the ViewModel was stale
            let existingHabits = try await getAllHabits.execute()
            if let existingHabit = existingHabits.first(where: { $0.suggestionId == suggestion.id }) {
                logger.log(
                    "Idempotent hit: Habit already exists for suggestion",
                    level: .warning,
                    category: .dataIntegrity,
                    metadata: [
                        "suggestionId": suggestion.id,
                        "suggestionName": suggestion.name,
                        "existingHabitId": existingHabit.id.uuidString
                    ]
                )
                return .alreadyExists(habitId: existingHabit.id)
            }

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