import Foundation

// MARK: - Streak Use Case Implementations

public final class CalculateCurrentStreak: CalculateCurrentStreakUseCase {
    private let streakCalculationService: StreakCalculationService

    public init(streakCalculationService: StreakCalculationService) {
        self.streakCalculationService = streakCalculationService
    }

    public func execute(habit: Habit, logs: [HabitLog], asOf: Date) -> Int {
        return streakCalculationService.calculateCurrentStreak(habit: habit, logs: logs, asOf: asOf)
    }
}

public final class GetStreakStatus: GetStreakStatusUseCase {
    private let streakCalculationService: StreakCalculationService

    public init(streakCalculationService: StreakCalculationService) {
        self.streakCalculationService = streakCalculationService
    }

    public func execute(habit: Habit, logs: [HabitLog], asOf: Date) -> HabitStreakStatus {
        return streakCalculationService.getStreakStatus(habit: habit, logs: logs, asOf: asOf)
    }
}