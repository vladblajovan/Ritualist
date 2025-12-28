//
//  DailyNotificationScheduler.swift
//  RitualistCore
//
//  Created by Claude on 21.08.2025.
//

import Foundation

/// Service responsible for daily re-scheduling of habit notifications
/// to ensure only incomplete habits receive notifications
public protocol DailyNotificationSchedulerService: Sendable {
    /// Re-schedules notifications for all active habits, checking completion status
    func rescheduleAllHabitNotifications() async throws
}

public final class DefaultDailyNotificationScheduler: DailyNotificationSchedulerService {

    // MARK: - Constants

    /// iOS enforces a hard limit of 64 pending local notifications per app
    /// Beyond this limit, iOS silently drops the oldest notifications
    private static let iOSNotificationLimit = 64

    /// Reserve some slots for system notifications (snooze, personality analysis, etc.)
    private static let reservedSlots = 10

    /// Maximum notification slots available for habit reminders
    private static var maxHabitNotificationSlots: Int {
        iOSNotificationLimit - reservedSlots
    }

    // MARK: - Dependencies

    private let habitRepository: HabitRepository
    private let habitCompletionCheckService: HabitCompletionCheckService
    private let notificationService: NotificationService
    private let subscriptionService: SecureSubscriptionService
    private let logger: DebugLogger

    // MARK: - Initialization

    public init(
        habitRepository: HabitRepository,
        habitCompletionCheckService: HabitCompletionCheckService,
        notificationService: NotificationService,
        subscriptionService: SecureSubscriptionService,
        logger: DebugLogger
    ) {
        self.habitRepository = habitRepository
        self.habitCompletionCheckService = habitCompletionCheckService
        self.notificationService = notificationService
        self.subscriptionService = subscriptionService
        self.logger = logger
    }

    // MARK: - Public Methods

    public func rescheduleAllHabitNotifications() async throws {
        logger.logNotification(event: "Starting daily notification rescheduling")

        // Premium check: Only premium users get habit notifications
        guard await subscriptionService.isPremiumUser() else {
            logger.logNotification(event: "Non-premium user - skipping habit notifications")

            // Clear any existing habit notifications for non-premium users
            let habitNotificationIds = await notificationService.getPendingHabitNotificationIds()
            if !habitNotificationIds.isEmpty {
                await notificationService.clearHabitNotifications(ids: habitNotificationIds)
                logger.logNotification(
                    event: "Cleared habit notifications for non-premium user",
                    metadata: ["count": habitNotificationIds.count]
                )
            }
            return
        }

        // Fetch all active habits
        let allHabits = try await habitRepository.fetchAllHabits()
        let activeHabitsWithReminders = allHabits.filter { habit in
            habit.isActive && !habit.reminders.isEmpty
        }

        // Build list of all (habit, reminderTime) pairs
        var allNotifications: [(habit: Habit, time: ReminderTime)] = []
        for habit in activeHabitsWithReminders {
            for time in habit.reminders {
                allNotifications.append((habit: habit, time: time))
            }
        }

        // Sort by time so badge numbers are assigned in chronological order
        allNotifications.sort { lhs, rhs in
            if lhs.time.hour != rhs.time.hour {
                return lhs.time.hour < rhs.time.hour
            }
            return lhs.time.minute < rhs.time.minute
        }

        logger.logNotification(
            event: "Found active habits with reminders",
            metadata: [
                "habits_count": activeHabitsWithReminders.count,
                "notifications_needed": allNotifications.count,
                "ios_limit": Self.maxHabitNotificationSlots
            ]
        )

        // Limit to iOS notification cap (prioritize earlier times)
        let notificationsToSchedule = Array(allNotifications.prefix(Self.maxHabitNotificationSlots))

        // Log warning if we hit the limit
        if allNotifications.count > Self.maxHabitNotificationSlots {
            logger.log(
                "⚠️ iOS notification limit reached",
                level: .warning,
                category: .notifications,
                metadata: [
                    "needed": allNotifications.count,
                    "limit": Self.maxHabitNotificationSlots,
                    "dropped": allNotifications.count - notificationsToSchedule.count
                ]
            )
        }

        // Clear all existing pending habit notifications first
        let existingNotificationIds = await notificationService.getPendingHabitNotificationIds()
        if !existingNotificationIds.isEmpty {
            await notificationService.clearHabitNotifications(ids: existingNotificationIds)
            logger.logNotification(
                event: "Cleared existing habit notifications",
                metadata: ["count": existingNotificationIds.count]
            )
        }

        // Cancel all habit notifications to ensure clean slate
        for habit in activeHabitsWithReminders {
            await notificationService.cancel(for: habit.id)
        }

        // Schedule notifications in time order with incrementing badge numbers
        var scheduledCount = 0
        var skippedCount = 0
        let today = Date()

        for (index, notification) in notificationsToSchedule.enumerated() {
            let habit = notification.habit
            let time = notification.time

            // Check if habit is already completed for today
            let shouldShow = await habitCompletionCheckService.shouldShowNotification(habitId: habit.id, date: today)

            guard shouldShow else {
                logger.logNotification(
                    event: "Habit already completed, skipping notification",
                    habitId: habit.id.uuidString,
                    metadata: ["habit_name": habit.name, "time": "\(time.hour):\(String(format: "%02d", time.minute))"]
                )
                skippedCount += 1
                continue
            }

            do {
                // Badge number is position in chronological order (1-based)
                let badgeNumber = index + 1 - skippedCount

                try await notificationService.scheduleSingleNotification(
                    for: habit.id,
                    habitName: habit.name,
                    habitKind: habit.kind,
                    time: time,
                    badgeNumber: badgeNumber
                )
                scheduledCount += 1
            } catch {
                logger.logNotification(
                    event: "Failed to schedule notification",
                    habitId: habit.id.uuidString,
                    metadata: ["habit_name": habit.name, "error": error.localizedDescription]
                )
                skippedCount += 1
            }
        }

        logger.logNotification(
            event: "Rescheduling complete",
            metadata: [
                "scheduled": scheduledCount,
                "skipped": skippedCount,
                "dropped_due_to_limit": max(0, allNotifications.count - Self.maxHabitNotificationSlots)
            ]
        )

        // Log final state for debugging
        let finalPendingCount = await notificationService.getPendingHabitNotificationIds().count
        logger.logNotification(
            event: "Final notification state",
            metadata: ["pending_count": finalPendingCount]
        )

        // Update badge to reflect delivered notifications count
        await notificationService.updateBadgeCount()
    }
}