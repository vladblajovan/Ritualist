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
    
    // MARK: - Dependencies
    
    private let habitRepository: HabitRepository
    private let scheduleHabitReminders: ScheduleHabitRemindersUseCase
    private let notificationService: NotificationService
    
    // MARK: - Initialization
    
    public init(
        habitRepository: HabitRepository,
        scheduleHabitReminders: ScheduleHabitRemindersUseCase,
        notificationService: NotificationService
    ) {
        self.habitRepository = habitRepository
        self.scheduleHabitReminders = scheduleHabitReminders
        self.notificationService = notificationService
    }
    
    // MARK: - Public Methods
    
    public func rescheduleAllHabitNotifications() async throws {
        print("🔄 [DailyNotificationScheduler] Starting daily notification rescheduling")
        
        // Fetch all active habits
        let allHabits = try await habitRepository.fetchAllHabits()
        let activeHabitsWithReminders = allHabits.filter { habit in
            habit.isActive && !habit.reminders.isEmpty
        }
        
        print("📊 [DailyNotificationScheduler] Found \(activeHabitsWithReminders.count) active habits with reminders")
        
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
            print("🗑️ [DailyNotificationScheduler] Cleared \(habitNotificationIds.count) existing habit notifications")
        }
        
        // Re-schedule notifications for each active habit (completion check happens in ScheduleHabitReminders)
        var scheduledCount = 0
        var skippedCount = 0
        
        for habit in activeHabitsWithReminders {
            do {
                // The ScheduleHabitReminders UseCase will check completion status and only schedule if needed
                try await scheduleHabitReminders.execute(habit: habit)
                scheduledCount += 1
            } catch {
                print("⚠️ [DailyNotificationScheduler] Failed to schedule notifications for habit \(habit.name): \(error)")
                skippedCount += 1
            }
        }
        
        print("✅ [DailyNotificationScheduler] Rescheduling complete - scheduled: \(scheduledCount), skipped: \(skippedCount)")
        
        // Log final state for debugging
        let finalPendingRequests = await center.pendingNotificationRequests()
        let habitNotifications = finalPendingRequests.filter { request in
            let id = request.identifier
            return id.hasPrefix("today_") || id.hasPrefix("rich_") || id.hasPrefix("tailored_")
        }
        print("📱 [DailyNotificationScheduler] Final notification count: \(habitNotifications.count) habit notifications pending")
    }
}