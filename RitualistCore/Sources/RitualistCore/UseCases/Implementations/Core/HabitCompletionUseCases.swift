import Foundation

// MARK: - Habit Completion Use Case Implementations (Phase 0)

public final class IsHabitCompleted: IsHabitCompletedUseCase {
    private let habitCompletionService: HabitCompletionService
    
    public init(habitCompletionService: HabitCompletionService) {
        self.habitCompletionService = habitCompletionService
    }
    
    public func execute(habit: Habit, on date: Date, logs: [HabitLog]) -> Bool {
        habitCompletionService.isCompleted(habit: habit, on: date, logs: logs)
    }
}

public final class CalculateDailyProgress: CalculateDailyProgressUseCase {
    private let habitCompletionService: HabitCompletionService
    
    public init(habitCompletionService: HabitCompletionService) {
        self.habitCompletionService = habitCompletionService
    }
    
    public func execute(habit: Habit, logs: [HabitLog], for date: Date) -> Double {
        habitCompletionService.calculateDailyProgress(habit: habit, logs: logs, for: date)
    }
}

public final class IsScheduledDay: IsScheduledDayUseCase {
    private let habitCompletionService: HabitCompletionService
    
    public init(habitCompletionService: HabitCompletionService) {
        self.habitCompletionService = habitCompletionService
    }
    
    public func execute(habit: Habit, date: Date) -> Bool {
        habitCompletionService.isScheduledDay(habit: habit, date: date)
    }
}

public final class ClearPurchases: ClearPurchasesUseCase {
    private let paywallService: PaywallService
    
    public init(paywallService: PaywallService) {
        self.paywallService = paywallService
    }
    
    public func execute() {
        paywallService.clearPurchases()
    }
}