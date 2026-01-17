import Foundation

// MARK: - Notification Use Case Implementations

/// Schedules notifications for a habit by triggering a full reschedule of all habit notifications.
///
/// This ensures consistent badge numbering across all habits by routing through
/// `DailyNotificationSchedulerService`, which assigns badges based on time-sorted delivery order.
public final class ScheduleHabitReminders: ScheduleHabitRemindersUseCase {
    private let dailyNotificationScheduler: DailyNotificationSchedulerService
    private let notificationService: NotificationService
    private let logger: DebugLogger

    public init(
        dailyNotificationScheduler: DailyNotificationSchedulerService,
        notificationService: NotificationService,
        logger: DebugLogger
    ) {
        self.dailyNotificationScheduler = dailyNotificationScheduler
        self.notificationService = notificationService
        self.logger = logger
    }

    public func execute(habit: Habit) async throws {
        logger.logNotification(
            event: "Habit saved - triggering full notification reschedule",
            habitId: habit.id.uuidString,
            metadata: [
                "habit_name": habit.name,
                "is_active": habit.isActive,
                "reminder_count": habit.reminders.count
            ]
        )

        // Cancel this habit's notifications immediately (handles deleted reminders)
        await notificationService.cancel(for: habit.id)

        // Trigger full reschedule for correct badge ordering across all habits
        // The bulk scheduler handles: active check, completion check, time sorting, badge assignment
        try await dailyNotificationScheduler.rescheduleAllHabitNotifications()
    }
}

public final class LogHabitFromNotification: LogHabitFromNotificationUseCase {
    private let habitRepository: HabitRepository
    private let logRepository: LogRepository
    private let getLogForDate: GetLogForDateUseCase
    private let logHabit: LogHabitUseCase
    private let timezoneService: TimezoneService

    public init(
        habitRepository: HabitRepository,
        logRepository: LogRepository,
        getLogForDate: GetLogForDateUseCase,
        logHabit: LogHabitUseCase,
        timezoneService: TimezoneService
    ) {
        self.habitRepository = habitRepository
        self.logRepository = logRepository
        self.getLogForDate = getLogForDate
        self.logHabit = logHabit
        self.timezoneService = timezoneService
    }

    public func execute(habitId: UUID, date: Date, value: Double?) async throws {
        // Fetch habit to determine logging behavior
        guard let habit = try await habitRepository.fetchHabit(by: habitId) else {
            throw NotificationError.habitNotFound(id: habitId)
        }

        // CRITICAL: Use display timezone (not device timezone) to match the user's view of "today"
        // This ensures notification-triggered completions go to the same day the user sees in the app
        let displayTimezone = (try? await timezoneService.getDisplayTimezone()) ?? .current

        // Check if there's already a log for today
        let existingLog = try await getLogForDate.execute(habitID: habitId, date: date)

        if habit.kind == .binary {
            // Binary habit: log as complete if not already logged
            if existingLog == nil {
                // Use start of day in display timezone and store the display timezone identifier
                let logDate = CalendarUtils.startOfDayLocal(for: date, timezone: displayTimezone)
                let log = HabitLog(habitID: habitId, date: logDate, value: 1.0, timezone: displayTimezone.identifier)
                try await logHabit.execute(log)
            }
        } else {
            // Count habit: increment by 1 or use provided value
            let currentValue = existingLog?.value ?? 0.0
            let newValue = value ?? (currentValue + 1.0)

            if let existingLog = existingLog {
                let updatedLog = HabitLog(id: existingLog.id, habitID: habitId, date: existingLog.date, value: newValue, timezone: existingLog.timezone)
                try await logHabit.execute(updatedLog)
            } else {
                // Use start of day in display timezone and store the display timezone identifier
                let logDate = CalendarUtils.startOfDayLocal(for: date, timezone: displayTimezone)
                let newLog = HabitLog(habitID: habitId, date: logDate, value: newValue, timezone: displayTimezone.identifier)
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
        // Include habitId so completion status can be checked when notification fires
        let title = "Reminder: \(habitName)"
        let body = "You asked to be reminded about your \(habitName) habit!"

        try await notificationService.sendImmediate(title: title, body: body, habitId: habitId)
    }
}

public final class HandleNotificationAction: HandleNotificationActionUseCase {
    private let logHabitFromNotification: LogHabitFromNotificationUseCase
    private let snoozeHabitReminder: SnoozeHabitReminderUseCase
    private let notificationService: NotificationService
    private let habitCompletionCheckService: HabitCompletionCheckService
    private let cancelHabitReminders: CancelHabitRemindersUseCase
    private let logger: DebugLogger

    public init(
        logHabitFromNotification: LogHabitFromNotificationUseCase,
        snoozeHabitReminder: SnoozeHabitReminderUseCase,
        notificationService: NotificationService,
        habitCompletionCheckService: HabitCompletionCheckService,
        cancelHabitReminders: CancelHabitRemindersUseCase,
        logger: DebugLogger
    ) {
        self.logHabitFromNotification = logHabitFromNotification
        self.snoozeHabitReminder = snoozeHabitReminder
        self.notificationService = notificationService
        self.habitCompletionCheckService = habitCompletionCheckService
        self.cancelHabitReminders = cancelHabitReminders
        self.logger = logger
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
                logger.logNotification(
                    event: "Skipping action - habit already completed",
                    habitId: habitId.uuidString,
                    metadata: ["habit_name": habitName ?? "Unknown"]
                )
                return
            }

            // Proceed with logging since habit is not completed
            try await logHabitFromNotification.execute(habitId: habitId, date: currentDate, value: nil)

            // CRITICAL: Cancel all remaining notifications for this habit today
            // This prevents duplicate notifications from firing after completion
            logger.logNotification(
                event: "Habit completed - cancelling remaining notifications",
                habitId: habitId.uuidString
            )
            await cancelHabitReminders.execute(habitId: habitId)
            
        case .remindLater:
            guard let habitName = habitName, let reminderTime = reminderTime else {
                throw NotificationError.missingRequiredData(field: "habit name or reminder time for snooze")
            }
            try await snoozeHabitReminder.execute(habitId: habitId, habitName: habitName, originalTime: reminderTime)
            
        case .dismiss:
            // Nothing to do - user dismissed the notification
            break

        case .openApp:
            // Default tap on notification - app opens in foreground
            // Navigation to Overview is handled by the action handler in Container+Services
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