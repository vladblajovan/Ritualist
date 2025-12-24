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

/// Test implementation of NotificationService that tracks notification operations
/// Allows configuring pending notifications and verifying clearing behavior
public actor TestNotificationService: NotificationService {

    // MARK: - Tracking State

    /// Simulated pending notification IDs (set these to simulate existing notifications)
    private var pendingNotificationIds: [String] = []

    /// IDs of notifications that were cleared (for verification)
    private var clearedNotificationIds: [String] = []

    /// Number of times clearHabitNotifications was called
    private var clearCallCount: Int = 0

    public init() {}

    // MARK: - Test Configuration

    /// Set the notification IDs that should be returned by getPendingHabitNotificationIds
    public func setPendingNotificationIds(_ ids: [String]) {
        self.pendingNotificationIds = ids
    }

    /// Get the IDs that were cleared (for test verification)
    public func getClearedNotificationIds() -> [String] {
        return clearedNotificationIds
    }

    /// Get the number of times clearHabitNotifications was called
    public func getClearCallCount() -> Int {
        return clearCallCount
    }

    /// Reset tracking state between tests
    public func reset() {
        pendingNotificationIds = []
        clearedNotificationIds = []
        clearCallCount = 0
    }

    // MARK: - NotificationService Protocol

    nonisolated public func requestAuthorizationIfNeeded() async throws -> Bool { return true }
    nonisolated public func checkAuthorizationStatus() async -> Bool { return true }
    nonisolated public func schedule(for habitID: UUID, times: [ReminderTime]) async throws {}
    nonisolated public func scheduleWithActions(for habitID: UUID, habitName: String, habitKind: HabitKind, times: [ReminderTime]) async throws {}
    nonisolated public func scheduleRichReminders(for habitID: UUID, habitName: String, habitCategory: String?, currentStreak: Int, times: [ReminderTime]) async throws {}
    nonisolated public func schedulePersonalityTailoredReminders(for habitID: UUID, habitName: String, habitCategory: String?, currentStreak: Int, personalityProfile: PersonalityProfile, times: [ReminderTime]) async throws {}
    nonisolated public func sendStreakMilestone(for habitID: UUID, habitName: String, streakDays: Int) async throws {}
    nonisolated public func cancel(for habitID: UUID) async {}
    nonisolated public func sendImmediate(title: String, body: String, habitId: UUID?) async throws {}
    nonisolated public func setupNotificationCategories() async {}
    nonisolated public func schedulePersonalityAnalysis(userId: UUID, at date: Date, frequency: AnalysisFrequency) async throws {}
    nonisolated public func sendPersonalityAnalysisCompleted(userId: UUID, profile: PersonalityProfile) async throws {}
    nonisolated public func cancelPersonalityAnalysis(userId: UUID) {}
    nonisolated public func getNotificationSettings() async -> NotificationAuthorizationStatus { return .authorized }
    nonisolated public func sendLocationTriggeredNotification(for habitID: UUID, habitName: String, event: GeofenceEvent) async throws {}

    // MARK: - Pending Notification Management (Trackable)

    public func getPendingHabitNotificationIds() async -> [String] {
        return pendingNotificationIds
    }

    public func clearHabitNotifications(ids: [String]) async {
        clearCallCount += 1
        clearedNotificationIds.append(contentsOf: ids)
        // Also remove from pending (simulating actual clearing)
        pendingNotificationIds.removeAll { ids.contains($0) }
    }
}
