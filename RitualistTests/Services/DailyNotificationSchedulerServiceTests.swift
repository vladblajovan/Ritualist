import Testing
import Foundation
import SwiftData
@testable import RitualistCore

/// Tests for DailyNotificationSchedulerService (Phase 2)
///
/// **Service Purpose:** Daily re-scheduling of habit notifications to ensure only incomplete habits receive notifications
/// **Why Critical:** Ensures notification reliability and prevents notification spam for completed habits
/// **Test Strategy:** Test orchestration logic with REAL dependencies where possible
///
/// **Testing Limitations:**
/// - UNUserNotificationCenter is used directly in the implementation (lines 58-119)
/// - Cannot fully test notification clearing/querying without system integration tests
/// - Focus on: habit filtering, error handling, and use case orchestration
///
/// **Test Coverage:**
/// - Habit Filtering (3 tests): Active habits with reminders, skip inactive, skip without reminders
/// - Use Case Orchestration (3 tests): Calls ScheduleHabitReminders for each habit
/// - Error Handling (3 tests): Continues on individual failures, handles repository errors
/// - Edge Cases (3 tests): Empty habits, all inactive, all without reminders
#if swift(>=6.1)
@Suite(
    "DailyNotificationSchedulerService Tests",
    .tags(.notifications, .scheduling, .orchestration, .high, .database, .integration, .errorHandling)
)
#else
@Suite("DailyNotificationSchedulerService Tests")
#endif
struct DailyNotificationSchedulerServiceTests {

    // MARK: - Test Helpers

    /// Create service with REAL dependencies
    func createService(
        container: ModelContainer,
        scheduleHabitReminders: ScheduleHabitRemindersUseCase
    ) -> DefaultDailyNotificationScheduler {
        // Create REAL data source and repository
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)

        // Use test implementations for NotificationService (system dependency)
        let notificationService = TestNotificationService()
        let logger = DebugLogger(subsystem: "test", category: "scheduler")

        return DefaultDailyNotificationScheduler(
            habitRepository: habitRepository,
            scheduleHabitReminders: scheduleHabitReminders,
            notificationService: notificationService,
            logger: logger
        )
    }

    /// Save habits to test container
    func saveHabits(_ habits: [Habit], to container: ModelContainer) async throws {
        let context = ModelContext(container)
        for habit in habits {
            let habitModel = habit.toModel()
            context.insert(habitModel)
        }
        try context.save()
    }

    // MARK: - Habit Filtering Tests

    @Test("Reschedules notifications for active habits with reminders")
    func reschedulesNotificationsForActiveHabitsWithReminders() async throws {
        let container = try TestModelContainer.create()
        let scheduleHabitReminders = TrackingScheduleHabitReminders()

        // Create habits: 2 active with reminders, 1 active without, 1 inactive with reminders
        let activeWithReminders1 = HabitBuilder.binary(
            name: "Active With Reminders 1",
            isActive: true,
            reminders: [ReminderTime(hour: 9, minute: 0)]
        )

        let activeWithReminders2 = HabitBuilder.binary(
            name: "Active With Reminders 2",
            isActive: true,
            reminders: [ReminderTime(hour: 10, minute: 0)]
        )

        let activeWithoutReminders = HabitBuilder.binary(
            name: "Active Without Reminders",
            isActive: true
        )

        let inactiveWithReminders = HabitBuilder.binary(
            name: "Inactive With Reminders",
            isActive: false,
            reminders: [ReminderTime(hour: 11, minute: 0)]
        )

        try await saveHabits([
            activeWithReminders1,
            activeWithReminders2,
            activeWithoutReminders,
            inactiveWithReminders
        ], to: container)

        let service = createService(container: container, scheduleHabitReminders: scheduleHabitReminders)

        // Execute
        try await service.rescheduleAllHabitNotifications()

        // Verify: Should only schedule for 2 active habits with reminders
        let scheduledHabits = await scheduleHabitReminders.getScheduledHabits()
        #expect(scheduledHabits.count == 2)
        #expect(scheduledHabits.contains { $0.name == "Active With Reminders 1" })
        #expect(scheduledHabits.contains { $0.name == "Active With Reminders 2" })
    }

    @Test("Skips inactive habits even if they have reminders")
    func skipsInactiveHabitsEvenIfTheyHaveReminders() async throws {
        let container = try TestModelContainer.create()
        let scheduleHabitReminders = TrackingScheduleHabitReminders()

        // Create only inactive habits with reminders
        let inactive1 = HabitBuilder.binary(
            name: "Inactive 1",
            isActive: false,
            reminders: [ReminderTime(hour: 9, minute: 0)]
        )

        let inactive2 = HabitBuilder.binary(
            name: "Inactive 2",
            isActive: false,
            reminders: [ReminderTime(hour: 10, minute: 0)]
        )

        try await saveHabits([inactive1, inactive2], to: container)

        let service = createService(container: container, scheduleHabitReminders: scheduleHabitReminders)

        // Execute
        try await service.rescheduleAllHabitNotifications()

        // Verify: Should not schedule any
        let scheduledHabits = await scheduleHabitReminders.getScheduledHabits()
        #expect(scheduledHabits.count == 0)
    }

    @Test("Skips active habits without reminders")
    func skipsActiveHabitsWithoutReminders() async throws {
        let container = try TestModelContainer.create()
        let scheduleHabitReminders = TrackingScheduleHabitReminders()

        // Create only active habits without reminders
        let active1 = HabitBuilder.binary(name: "Active 1", isActive: true)
        let active2 = HabitBuilder.binary(name: "Active 2", isActive: true)

        try await saveHabits([active1, active2], to: container)

        let service = createService(container: container, scheduleHabitReminders: scheduleHabitReminders)

        // Execute
        try await service.rescheduleAllHabitNotifications()

        // Verify: Should not schedule any
        let scheduledHabits = await scheduleHabitReminders.getScheduledHabits()
        #expect(scheduledHabits.count == 0)
    }

    // MARK: - Use Case Orchestration Tests

    @Test("Calls ScheduleHabitReminders for each eligible habit")
    func callsScheduleHabitRemindersForEachEligibleHabit() async throws {
        let container = try TestModelContainer.create()
        let scheduleHabitReminders = TrackingScheduleHabitReminders()

        // Create 3 active habits with reminders
        let habit1 = HabitBuilder.binary(
            name: "Habit 1",
            isActive: true,
            reminders: [ReminderTime(hour: 9, minute: 0)]
        )

        let habit2 = HabitBuilder.binary(
            name: "Habit 2",
            isActive: true,
            reminders: [ReminderTime(hour: 10, minute: 0)]
        )

        let habit3 = HabitBuilder.binary(
            name: "Habit 3",
            isActive: true,
            reminders: [ReminderTime(hour: 11, minute: 0)]
        )

        try await saveHabits([habit1, habit2, habit3], to: container)

        let service = createService(container: container, scheduleHabitReminders: scheduleHabitReminders)

        // Execute
        try await service.rescheduleAllHabitNotifications()

        // Verify: All 3 should be scheduled
        let scheduledHabits = await scheduleHabitReminders.getScheduledHabits()
        #expect(scheduledHabits.count == 3)
    }

    /// Note: This test assumes sequential habit processing. If scheduler changes to
    /// parallel processing, verification logic may need adjustment.
    @Test("Continues processing if one habit fails to schedule")
    func continuesProcessingIfOneHabitFailsToSchedule() async throws {
        let container = try TestModelContainer.create()
        let scheduleHabitReminders = TrackingScheduleHabitReminders()

        // Create 3 active habits with reminders
        let habit1 = HabitBuilder.binary(
            name: "Habit 1",
            isActive: true,
            reminders: [ReminderTime(hour: 9, minute: 0)]
        )

        let habit2 = HabitBuilder.binary(
            name: "Habit 2",
            isActive: true,
            reminders: [ReminderTime(hour: 10, minute: 0)]
        )

        let habit3 = HabitBuilder.binary(
            name: "Habit 3",
            isActive: true,
            reminders: [ReminderTime(hour: 11, minute: 0)]
        )

        try await saveHabits([habit1, habit2, habit3], to: container)

        // Configure to fail for habit2
        await scheduleHabitReminders.setHabitsToFailFor([habit2.id])

        let service = createService(container: container, scheduleHabitReminders: scheduleHabitReminders)

        // Execute - should not throw
        try await service.rescheduleAllHabitNotifications()

        // Verify: Should have scheduled habit1 and habit3, but not habit2
        let scheduledHabits = await scheduleHabitReminders.getScheduledHabits()
        #expect(scheduledHabits.count == 2)
        #expect(scheduledHabits.contains { $0.name == "Habit 1" })
        #expect(scheduledHabits.contains { $0.name == "Habit 3" })
        #expect(!scheduledHabits.contains { $0.name == "Habit 2" })
    }

    @Test("Processes all habits even if multiple fail to schedule")
    func processesAllHabitsEvenIfMultipleFailToSchedule() async throws {
        let container = try TestModelContainer.create()
        let scheduleHabitReminders = TrackingScheduleHabitReminders()

        // Create 5 active habits with reminders
        let habits = (1...5).map { index in
            HabitBuilder.binary(
                name: "Habit \(index)",
                isActive: true,
                reminders: [ReminderTime(hour: 8 + index, minute: 0)]
            )
        }

        try await saveHabits(habits, to: container)

        // Configure to fail for habits 2 and 4 (indices 1 and 3)
        await scheduleHabitReminders.setHabitsToFailFor([habits[1].id, habits[3].id])

        let service = createService(container: container, scheduleHabitReminders: scheduleHabitReminders)

        // Execute - should not throw despite multiple failures
        try await service.rescheduleAllHabitNotifications()

        // Verify: Should have scheduled 3 habits (1, 3, and 5 - skipping 2 and 4)
        let scheduledHabits = await scheduleHabitReminders.getScheduledHabits()
        #expect(scheduledHabits.count == 3)
        #expect(scheduledHabits.contains { $0.name == "Habit 1" })
        #expect(scheduledHabits.contains { $0.name == "Habit 3" })
        #expect(scheduledHabits.contains { $0.name == "Habit 5" })
        #expect(!scheduledHabits.contains { $0.name == "Habit 2" })
        #expect(!scheduledHabits.contains { $0.name == "Habit 4" })
    }

    // MARK: - Error Handling Tests

    @Test("Propagates repository errors")
    func propagatesRepositoryErrors() async throws {
        let container = try TestModelContainer.create()
        let scheduleHabitReminders = TrackingScheduleHabitReminders()

        // Create failing repository
        let failingRepo = FailingHabitRepository()
        await failingRepo.setShouldFailFetchAll(true)

        let notificationService = TestNotificationService()
        let logger = DebugLogger(subsystem: "test", category: "scheduler")

        let service = DefaultDailyNotificationScheduler(
            habitRepository: failingRepo,
            scheduleHabitReminders: scheduleHabitReminders,
            notificationService: notificationService,
            logger: logger
        )

        // Should throw repository error
        do {
            try await service.rescheduleAllHabitNotifications()
            Issue.record("Expected error to be thrown")
        } catch {
            // Verify error was propagated
            #expect(error.localizedDescription.contains("Fetch failed"))
        }
    }

    @Test("Handles empty habit list gracefully")
    func handlesEmptyHabitListGracefully() async throws {
        let container = try TestModelContainer.create()
        let scheduleHabitReminders = TrackingScheduleHabitReminders()
        // Don't save any habits

        let service = createService(container: container, scheduleHabitReminders: scheduleHabitReminders)

        // Should not throw
        try await service.rescheduleAllHabitNotifications()

        // Verify: No habits scheduled
        let scheduledHabits = await scheduleHabitReminders.getScheduledHabits()
        #expect(scheduledHabits.count == 0)
    }

    @Test("Handles all habits filtered out gracefully")
    func handlesAllHabitsFilteredOutGracefully() async throws {
        let container = try TestModelContainer.create()
        let scheduleHabitReminders = TrackingScheduleHabitReminders()

        // Create habits that should all be filtered out
        let inactiveWithReminders = HabitBuilder.binary(
            name: "Inactive",
            isActive: false,
            reminders: [ReminderTime(hour: 9, minute: 0)]
        )

        let activeWithoutReminders = HabitBuilder.binary(name: "No Reminders", isActive: true)

        try await saveHabits([inactiveWithReminders, activeWithoutReminders], to: container)

        let service = createService(container: container, scheduleHabitReminders: scheduleHabitReminders)

        // Should not throw
        try await service.rescheduleAllHabitNotifications()

        // Verify: No habits scheduled
        let scheduledHabits = await scheduleHabitReminders.getScheduledHabits()
        #expect(scheduledHabits.count == 0)
    }

}

