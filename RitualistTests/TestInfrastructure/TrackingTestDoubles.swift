import Foundation
@testable import RitualistCore

/// Reusable tracking test doubles for verifying interactions
///
/// These test doubles record calls and allow verification of behavior.
/// Use these instead of defining tracking implementations locally in each test file.

// MARK: - Tracking Schedule Habit Reminders

/// Test implementation of ScheduleHabitRemindersUseCase that tracks scheduled habits
public actor TrackingScheduleHabitReminders: ScheduleHabitRemindersUseCase {
    public var scheduledHabits: [Habit] = []
    public var shouldThrowError: Bool = false
    public var habitsToFailFor: Set<UUID> = []

    public init() {}

    public func execute(habit: Habit) async throws {
        if shouldThrowError {
            throw NSError(domain: "TrackingScheduleHabitReminders", code: 1, userInfo: [NSLocalizedDescriptionKey: "Schedule failed"])
        }

        if habitsToFailFor.contains(habit.id) {
            throw NSError(domain: "TrackingScheduleHabitReminders", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed for specific habit"])
        }

        scheduledHabits.append(habit)
    }

    public func getScheduledHabits() -> [Habit] {
        return scheduledHabits
    }

    public func setHabitsToFailFor(_ habitIds: Set<UUID>) {
        self.habitsToFailFor = habitIds
    }

    public func setShouldThrowError(_ value: Bool) {
        self.shouldThrowError = value
    }
}

// MARK: - Test Notification Service

/// Minimal test implementation of NotificationService (all methods are no-ops)
public final class TestNotificationService: NotificationService {
    public init() {}

    public func requestAuthorizationIfNeeded() async throws -> Bool { return true }
    public func checkAuthorizationStatus() async -> Bool { return true }
    public func schedule(for habitID: UUID, times: [ReminderTime]) async throws {}
    public func scheduleWithActions(for habitID: UUID, habitName: String, habitKind: HabitKind, times: [ReminderTime]) async throws {}
    public func scheduleRichReminders(for habitID: UUID, habitName: String, habitCategory: String?, currentStreak: Int, times: [ReminderTime]) async throws {}
    public func schedulePersonalityTailoredReminders(for habitID: UUID, habitName: String, habitCategory: String?, currentStreak: Int, personalityProfile: PersonalityProfile, times: [ReminderTime]) async throws {}
    public func sendStreakMilestone(for habitID: UUID, habitName: String, streakDays: Int) async throws {}
    public func cancel(for habitID: UUID) async {}
    public func sendImmediate(title: String, body: String, habitId: UUID?) async throws {}
    public func setupNotificationCategories() async {}
    public func schedulePersonalityAnalysis(userId: UUID, at date: Date, frequency: AnalysisFrequency) async throws {}
    public func sendPersonalityAnalysisCompleted(userId: UUID, profile: PersonalityProfile) async throws {}
    public func cancelPersonalityAnalysis(userId: UUID) {}
    public func getNotificationSettings() async -> NotificationAuthorizationStatus { return .authorized }
    public func sendLocationTriggeredNotification(for habitID: UUID, habitName: String, event: GeofenceEvent) async throws {}
}
