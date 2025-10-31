import Foundation

// MARK: - Notification Use Case Implementations

public final class ScheduleHabitReminders: ScheduleHabitRemindersUseCase {
    private let habitRepository: HabitRepository
    private let notificationService: NotificationService
    private let habitCompletionCheckService: HabitCompletionCheckService
    
    public init(
        habitRepository: HabitRepository, 
        notificationService: NotificationService,
        habitCompletionCheckService: HabitCompletionCheckService
    ) {
        self.habitRepository = habitRepository
        self.notificationService = notificationService
        self.habitCompletionCheckService = habitCompletionCheckService
    }
    
    public func execute(habit: Habit) async throws {
        // Cancel existing notifications for this habit
        await notificationService.cancel(for: habit.id)
        
        // Schedule new notifications only for active habits with reminders
        guard habit.isActive && !habit.reminders.isEmpty else { return }
        
        // Check if habit is already completed for today
        let today = Date()
        let shouldShow = await habitCompletionCheckService.shouldShowNotification(habitId: habit.id, date: today)
        
        // Only schedule notifications if the habit is not completed today
        guard shouldShow else { 
            print("🚫 [ScheduleHabitReminders] Habit \(habit.name) is already completed today, not scheduling notifications")
            return 
        }
        
        print("✅ [ScheduleHabitReminders] Habit \(habit.name) not completed today, scheduling notifications")
        try await notificationService.scheduleWithActions(for: habit.id, habitName: habit.name, habitKind: habit.kind, times: habit.reminders)
    }
}

public final class LogHabitFromNotification: LogHabitFromNotificationUseCase {
    private let habitRepository: HabitRepository
    private let logRepository: LogRepository
    private let getLogForDate: GetLogForDateUseCase
    private let logHabit: LogHabitUseCase
    
    public init(
        habitRepository: HabitRepository,
        logRepository: LogRepository,
        getLogForDate: GetLogForDateUseCase,
        logHabit: LogHabitUseCase
    ) {
        self.habitRepository = habitRepository
        self.logRepository = logRepository
        self.getLogForDate = getLogForDate
        self.logHabit = logHabit
    }
    
    public func execute(habitId: UUID, date: Date, value: Double?) async throws {
        // Fetch habit to determine logging behavior
        guard let habit = try await habitRepository.fetchHabit(by: habitId) else {
            throw NotificationError.habitNotFound(id: habitId)
        }
        
        // Check if there's already a log for today
        let existingLog = try await getLogForDate.execute(habitID: habitId, date: date)
        
        if habit.kind == .binary {
            // Binary habit: log as complete if not already logged
            if existingLog == nil {
                let log = HabitLog.withCurrentTimezone(habitID: habitId, date: date, value: 1.0)
                try await logHabit.execute(log)
            }
        } else {
            // Count habit: increment by 1 or use provided value
            let currentValue = existingLog?.value ?? 0.0
            let newValue = value ?? (currentValue + 1.0)
            
            if let existingLog = existingLog {
                let updatedLog = HabitLog(id: existingLog.id, habitID: habitId, date: date, value: newValue, timezone: existingLog.timezone)
                try await logHabit.execute(updatedLog)
            } else {
                let newLog = HabitLog.withCurrentTimezone(habitID: habitId, date: date, value: newValue)
                try await logHabit.execute(newLog)
            }
        }
    }
}

public final class SnoozeHabitReminder: SnoozeHabitReminderUseCase {
    private let notificationService: NotificationService
    
    public init(notificationService: NotificationService) {
        self.notificationService = notificationService
    }
    
    public func execute(habitId: UUID, habitName: String, originalTime: ReminderTime) async throws {
        // Schedule a one-time notification 20 minutes from now
        let title = "Reminder: \(habitName)"
        let body = "You asked to be reminded about your \(habitName) habit!"
        
        try await notificationService.sendImmediate(title: title, body: body)
    }
}

public final class HandleNotificationAction: HandleNotificationActionUseCase {
    private let logHabitFromNotification: LogHabitFromNotificationUseCase
    private let snoozeHabitReminder: SnoozeHabitReminderUseCase
    private let notificationService: NotificationService
    private let habitCompletionCheckService: HabitCompletionCheckService
    private let cancelHabitReminders: CancelHabitRemindersUseCase
    
    public init(
        logHabitFromNotification: LogHabitFromNotificationUseCase,
        snoozeHabitReminder: SnoozeHabitReminderUseCase,
        notificationService: NotificationService,
        habitCompletionCheckService: HabitCompletionCheckService,
        cancelHabitReminders: CancelHabitRemindersUseCase
    ) {
        self.logHabitFromNotification = logHabitFromNotification
        self.snoozeHabitReminder = snoozeHabitReminder
        self.notificationService = notificationService
        self.habitCompletionCheckService = habitCompletionCheckService
        self.cancelHabitReminders = cancelHabitReminders
    }
    
    public func execute(
        action: NotificationAction,
        habitId: UUID,
        habitName: String?,
        habitKind: HabitKind,
        reminderTime: ReminderTime?
    ) async throws {
        let currentDate = Date()
        
        switch action {
        case .log:
            // For log actions, check if habit is already completed to provide better UX
            let shouldShow = await habitCompletionCheckService.shouldShowNotification(habitId: habitId, date: currentDate)
            
            if !shouldShow {
                // Habit is already completed today, skip action
                print("Habit \(habitName ?? "Unknown") is already completed today, skipping action")
                return
            }
            
            // Proceed with logging since habit is not completed
            try await logHabitFromNotification.execute(habitId: habitId, date: currentDate, value: nil)
            
            // CRITICAL: Cancel all remaining notifications for this habit today
            // This prevents duplicate notifications from firing after completion
            print("🚫 [HandleNotificationAction] Habit completed - cancelling remaining notifications for habit: \(habitId)")
            await cancelHabitReminders.execute(habitId: habitId)
            
            // Send confirmation notification for binary habits (background completion)
            if habitKind == .binary, let habitName = habitName {
                let title = "✅ \(habitName) completed!"
                let body = "Great job! Keep up the streak."
                try await notificationService.sendImmediate(title: title, body: body)
            }
            // For numeric habits, the foreground app will open and show the UI
            
        case .remindLater:
            guard let habitName = habitName, let reminderTime = reminderTime else {
                throw NotificationError.missingRequiredData(field: "habit name or reminder time for snooze")
            }
            try await snoozeHabitReminder.execute(habitId: habitId, habitName: habitName, originalTime: reminderTime)
            
        case .dismiss:
            // Nothing to do - user dismissed the notification
            break
        }
    }
}

public final class CancelHabitReminders: CancelHabitRemindersUseCase {
    private let notificationService: NotificationService
    
    public init(notificationService: NotificationService) {
        self.notificationService = notificationService
    }
    
    public func execute(habitId: UUID) async {
        await notificationService.cancel(for: habitId)
    }
}