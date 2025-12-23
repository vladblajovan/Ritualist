//
//  DailyNotificationScheduler.swift
//  RitualistCore
//
//  Created by Claude on 21.08.2025.
//

import Foundation
import UserNotifications

/// Service responsible for daily re-scheduling of habit notifications
/// to ensure only incomplete habits receive notifications
public protocol DailyNotificationSchedulerService {
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
    private let scheduleHabitReminders: ScheduleHabitRemindersUseCase
    private let notificationService: NotificationService
    private let subscriptionService: SecureSubscriptionService
    private let logger: DebugLogger

    // MARK: - Initialization

    public init(
        habitRepository: HabitRepository,
        scheduleHabitReminders: ScheduleHabitRemindersUseCase,
        notificationService: NotificationService,
        subscriptionService: SecureSubscriptionService,
        logger: DebugLogger
    ) {
        self.habitRepository = habitRepository
        self.scheduleHabitReminders = scheduleHabitReminders
        self.notificationService = notificationService
        self.subscriptionService = subscriptionService
        self.logger = logger
    }

    // MARK: - Public Methods

    public func rescheduleAllHabitNotifications() async throws {
        logger.logNotification(event: "Starting daily notification rescheduling")

        // Premium check: Only premium users get habit notifications
        guard subscriptionService.isPremiumUser() else {
            logger.logNotification(event: "Non-premium user - skipping habit notifications")

            // Clear any existing habit notifications for non-premium users
            let center = UNUserNotificationCenter.current()
            let pendingRequests = await center.pendingNotificationRequests()
            let habitNotificationIds = pendingRequests.compactMap { request in
                let id = request.identifier
                if id.contains("-") && (
                    id.hasPrefix("today_") ||
                    id.hasPrefix("rich_") ||
                    id.hasPrefix("tailored_") ||
                    UUID(uuidString: id.components(separatedBy: "-").first ?? "") != nil
                ) {
                    return id
                }
                return nil
            }

            if !habitNotificationIds.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: habitNotificationIds)
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

        // Calculate total notifications needed
        let totalNotificationsNeeded = activeHabitsWithReminders.reduce(0) { $0 + $1.reminders.count }

        logger.logNotification(
            event: "Found active habits with reminders",
            metadata: [
                "habits_count": activeHabitsWithReminders.count,
                "notifications_needed": totalNotificationsNeeded,
                "ios_limit": Self.maxHabitNotificationSlots
            ]
        )

        // Prioritize habits if we exceed the limit
        // Sort by displayOrder (user's priority) and limit notifications
        let habitsToSchedule = prioritizeHabitsForNotifications(
            habits: activeHabitsWithReminders,
            maxNotifications: Self.maxHabitNotificationSlots
        )

        // Log warning if we hit the limit
        if totalNotificationsNeeded > Self.maxHabitNotificationSlots {
            logger.log(
                "⚠️ iOS notification limit reached",
                level: .warning,
                category: .notifications,
                metadata: [
                    "needed": totalNotificationsNeeded,
                    "limit": Self.maxHabitNotificationSlots,
                    "habits_with_reminders": activeHabitsWithReminders.count,
                    "habits_scheduled": habitsToSchedule.count
                ]
            )
        }

        // Clear all existing pending notifications first
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()
        let habitNotificationIds = pendingRequests.compactMap { request in
            let id = request.identifier
            // Only remove habit-related notifications (those with habit IDs or specific prefixes)
            if id.contains("-") && (
                id.hasPrefix("today_") ||
                id.hasPrefix("rich_") ||
                id.hasPrefix("tailored_") ||
                UUID(uuidString: id.components(separatedBy: "-").first ?? "") != nil
            ) {
                return id
            }
            return nil
        }

        if !habitNotificationIds.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: habitNotificationIds)
            logger.logNotification(
                event: "Cleared existing habit notifications",
                metadata: ["count": habitNotificationIds.count]
            )
        }

        // Re-schedule notifications for prioritized habits
        var scheduledCount = 0
        var skippedCount = 0

        for habit in habitsToSchedule {
            do {
                // The ScheduleHabitReminders UseCase will check completion status and only schedule if needed
                try await scheduleHabitReminders.execute(habit: habit)
                scheduledCount += 1
            } catch {
                logger.logNotification(
                    event: "Failed to schedule notifications",
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
                "dropped_due_to_limit": activeHabitsWithReminders.count - habitsToSchedule.count
            ]
        )

        // Log final state for debugging
        let finalPendingRequests = await center.pendingNotificationRequests()
        let habitNotifications = finalPendingRequests.filter { request in
            let id = request.identifier
            return id.hasPrefix("today_") || id.hasPrefix("rich_") || id.hasPrefix("tailored_")
        }
        logger.logNotification(
            event: "Final notification state",
            metadata: ["pending_count": habitNotifications.count]
        )
    }

    // MARK: - Private Methods

    /// Prioritizes habits for notification scheduling when iOS limit would be exceeded
    /// - Parameters:
    ///   - habits: All habits with reminders
    ///   - maxNotifications: Maximum notifications allowed
    /// - Returns: Array of habits to schedule, prioritized by displayOrder
    private func prioritizeHabitsForNotifications(habits: [Habit], maxNotifications: Int) -> [Habit] {
        // Sort by displayOrder (lower = higher priority, user's arrangement)
        let sortedHabits = habits.sorted { $0.displayOrder < $1.displayOrder }

        var selectedHabits: [Habit] = []
        var totalNotifications = 0

        for habit in sortedHabits {
            let habitNotifications = habit.reminders.count
            if totalNotifications + habitNotifications <= maxNotifications {
                selectedHabits.append(habit)
                totalNotifications += habitNotifications
            } else {
                // Can't fit this habit's notifications, stop adding
                // Future improvement: could partially schedule reminders for this habit
                break
            }
        }

        return selectedHabits
    }
}