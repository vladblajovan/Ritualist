import Foundation

// MARK: - Streak Use Case Implementations

public final class CalculateCurrentStreak: CalculateCurrentStreakUseCase {
    private let streakCalculationService: StreakCalculationService

    public init(streakCalculationService: StreakCalculationService) {
        self.streakCalculationService = streakCalculationService
    }

    /// Calculate current streak with explicit timezone
    public func execute(habit: Habit, logs: [HabitLog], asOf: Date, timezone: TimeZone) -> Int {
        return streakCalculationService.calculateCurrentStreak(habit: habit, logs: logs, asOf: asOf, timezone: timezone)
    }

    /// Convenience method defaulting to device timezone (backward compatibility)
    public func execute(habit: Habit, logs: [HabitLog], asOf: Date) -> Int {
        return streakCalculationService.calculateCurrentStreak(habit: habit, logs: logs, asOf: asOf)
    }
}

public final class GetStreakStatus: GetStreakStatusUseCase {
    private let streakCalculationService: StreakCalculationService

    public init(streakCalculationService: StreakCalculationService) {
        self.streakCalculationService = streakCalculationService
    }

    /// Get streak status with explicit timezone
    public func execute(habit: Habit, logs: [HabitLog], asOf: Date, timezone: TimeZone) -> HabitStreakStatus {
        return streakCalculationService.getStreakStatus(habit: habit, logs: logs, asOf: asOf, timezone: timezone)
    }

    /// Convenience method defaulting to device timezone (backward compatibility)
    public func execute(habit: Habit, logs: [HabitLog], asOf: Date) -> HabitStreakStatus {
        return streakCalculationService.getStreakStatus(habit: habit, logs: logs, asOf: asOf)
    }
}