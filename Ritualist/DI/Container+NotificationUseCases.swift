import Foundation
import FactoryKit
import RitualistCore

// MARK: - Notification Use Cases Container Extensions

extension Container {
    
    // MARK: - Notification Use Cases
    
    var scheduleHabitReminders: Factory<ScheduleHabitRemindersUseCase> {
        self { ScheduleHabitReminders(
            habitRepository: self.habitRepository(),
            notificationService: self.notificationService()
        )}
    }
    
    var logHabitFromNotification: Factory<LogHabitFromNotificationUseCase> {
        self { LogHabitFromNotification(
            habitRepository: self.habitRepository(),
            logRepository: self.logRepository(),
            getLogForDate: self.getLogForDate(),
            logHabit: self.logHabit()
        )}
    }
    
    var snoozeHabitReminder: Factory<SnoozeHabitReminderUseCase> {
        self { SnoozeHabitReminder(
            notificationService: self.notificationService()
        )}
    }
    
    var handleNotificationAction: Factory<HandleNotificationActionUseCase> {
        self { HandleNotificationAction(
            logHabitFromNotification: self.logHabitFromNotification(),
            snoozeHabitReminder: self.snoozeHabitReminder(),
            notificationService: self.notificationService()
        )}
    }
    
    var cancelHabitReminders: Factory<CancelHabitRemindersUseCase> {
        self { CancelHabitReminders(
            notificationService: self.notificationService()
        )}
    }
}