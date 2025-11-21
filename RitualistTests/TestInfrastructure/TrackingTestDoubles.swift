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
