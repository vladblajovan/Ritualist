import Foundation

// MARK: - Habit Completion Use Case Implementations (Phase 0)

public final class IsHabitCompleted: IsHabitCompletedUseCase {
    private let habitCompletionService: HabitCompletionService

    public init(habitCompletionService: HabitCompletionService) {
        self.habitCompletionService = habitCompletionService
    }

    /// Check if habit is completed with explicit timezone
    public func execute(habit: Habit, on date: Date, logs: [HabitLog], timezone: TimeZone) -> Bool {
        habitCompletionService.isCompleted(habit: habit, on: date, logs: logs, timezone: timezone)
    }

    /// Convenience method defaulting to device timezone (backward compatibility)
    public func execute(habit: Habit, on date: Date, logs: [HabitLog]) -> Bool {
        habitCompletionService.isCompleted(habit: habit, on: date, logs: logs)
    }
}

public final class CalculateDailyProgress: CalculateDailyProgressUseCase {
    private let habitCompletionService: HabitCompletionService

    public init(habitCompletionService: HabitCompletionService) {
        self.habitCompletionService = habitCompletionService
    }

    /// Calculate daily progress with explicit timezone
    public func execute(habit: Habit, logs: [HabitLog], for date: Date, timezone: TimeZone) -> Double {
        habitCompletionService.calculateDailyProgress(habit: habit, logs: logs, for: date, timezone: timezone)
    }

    /// Convenience method defaulting to device timezone (backward compatibility)
    public func execute(habit: Habit, logs: [HabitLog], for date: Date) -> Double {
        habitCompletionService.calculateDailyProgress(habit: habit, logs: logs, for: date)
    }
}

public final class IsScheduledDay: IsScheduledDayUseCase {
    private let habitCompletionService: HabitCompletionService

    public init(habitCompletionService: HabitCompletionService) {
        self.habitCompletionService = habitCompletionService
    }

    /// Check if day is scheduled with explicit timezone
    public func execute(habit: Habit, date: Date, timezone: TimeZone) -> Bool {
        habitCompletionService.isScheduledDay(habit: habit, date: date, timezone: timezone)
    }

    /// Convenience method defaulting to device timezone (backward compatibility)
    public func execute(habit: Habit, date: Date) -> Bool {
        habitCompletionService.isScheduledDay(habit: habit, date: date)
    }
}

public final class ClearPurchases: ClearPurchasesUseCase, Sendable {
    private let subscriptionService: SecureSubscriptionService

    public init(subscriptionService: SecureSubscriptionService) {
        self.subscriptionService = subscriptionService
    }

    public func execute() async throws {
        try await subscriptionService.clearPurchases()
    }
}