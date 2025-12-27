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
@Suite(
    "DailyNotificationSchedulerService Tests",
    .tags(.notifications, .scheduling, .orchestration, .high, .database, .integration, .errorHandling)
)
@MainActor
struct DailyNotificationSchedulerServiceTests {

    // MARK: - Test Helpers

    /// Create service with REAL dependencies
    func createService(
        container: ModelContainer,
        scheduleHabitReminders: ScheduleHabitRemindersUseCase,
        subscriptionService: SecureSubscriptionService? = nil,
        notificationService: TestNotificationService? = nil
    ) -> (scheduler: DefaultDailyNotificationScheduler, notificationService: TestNotificationService) {
        // Create REAL data source and repository
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)

        // Use test implementations for NotificationService (system dependency)
        let testNotificationService = notificationService ?? TestNotificationService()
        let logger = DebugLogger(subsystem: "test", category: "scheduler")

        // Default to premium user for existing tests
        let subscription = subscriptionService ?? TestSubscriptionService(isPremium: true)

        let scheduler = DefaultDailyNotificationScheduler(
            habitRepository: habitRepository,
            scheduleHabitReminders: scheduleHabitReminders,
            notificationService: testNotificationService,
            subscriptionService: subscription,
            logger: logger
        )

        return (scheduler, testNotificationService)
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

        let (service, _) = createService(container: container, scheduleHabitReminders: scheduleHabitReminders)

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

        let (service, _) = createService(container: container, scheduleHabitReminders: scheduleHabitReminders)

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

        let (service, _) = createService(container: container, scheduleHabitReminders: scheduleHabitReminders)

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

        let (service, _) = createService(container: container, scheduleHabitReminders: scheduleHabitReminders)

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

        let (service, _) = createService(container: container, scheduleHabitReminders: scheduleHabitReminders)

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

        let (service, _) = createService(container: container, scheduleHabitReminders: scheduleHabitReminders)

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
            subscriptionService: TestSubscriptionService(isPremium: true),
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

        let (service, _) = createService(container: container, scheduleHabitReminders: scheduleHabitReminders)

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

        let (service, _) = createService(container: container, scheduleHabitReminders: scheduleHabitReminders)

        // Should not throw
        try await service.rescheduleAllHabitNotifications()

        // Verify: No habits scheduled
        let scheduledHabits = await scheduleHabitReminders.getScheduledHabits()
        #expect(scheduledHabits.count == 0)
    }

    // MARK: - Premium Gating Tests

    @Test("Skips scheduling notifications for non-premium users")
    func skipsSchedulingNotificationsForNonPremiumUsers() async throws {
        let container = try TestModelContainer.create()
        let scheduleHabitReminders = TrackingScheduleHabitReminders()

        // Create active habits with reminders that WOULD be scheduled for premium users
        let habit1 = HabitBuilder.binary(
            name: "Active With Reminders 1",
            isActive: true,
            reminders: [ReminderTime(hour: 9, minute: 0)]
        )

        let habit2 = HabitBuilder.binary(
            name: "Active With Reminders 2",
            isActive: true,
            reminders: [ReminderTime(hour: 10, minute: 0)]
        )

        try await saveHabits([habit1, habit2], to: container)

        // Use non-premium subscription service
        let (service, _) = createService(
            container: container,
            scheduleHabitReminders: scheduleHabitReminders,
            subscriptionService: TestSubscriptionService(isPremium: false)
        )

        // Execute
        try await service.rescheduleAllHabitNotifications()

        // Verify: Should NOT schedule any notifications for non-premium users
        let scheduledHabits = await scheduleHabitReminders.getScheduledHabits()
        #expect(scheduledHabits.count == 0, "Non-premium users should not have notifications scheduled")
    }

    @Test("Premium users get notifications scheduled normally")
    func premiumUsersGetNotificationsScheduledNormally() async throws {
        let container = try TestModelContainer.create()
        let scheduleHabitReminders = TrackingScheduleHabitReminders()

        // Create active habits with reminders
        let habit1 = HabitBuilder.binary(
            name: "Active With Reminders 1",
            isActive: true,
            reminders: [ReminderTime(hour: 9, minute: 0)]
        )

        let habit2 = HabitBuilder.binary(
            name: "Active With Reminders 2",
            isActive: true,
            reminders: [ReminderTime(hour: 10, minute: 0)]
        )

        try await saveHabits([habit1, habit2], to: container)

        // Explicitly use premium subscription service
        let (service, _) = createService(
            container: container,
            scheduleHabitReminders: scheduleHabitReminders,
            subscriptionService: TestSubscriptionService(isPremium: true)
        )

        // Execute
        try await service.rescheduleAllHabitNotifications()

        // Verify: Premium users should have notifications scheduled
        let scheduledHabits = await scheduleHabitReminders.getScheduledHabits()
        #expect(scheduledHabits.count == 2, "Premium users should have notifications scheduled")
    }

    // MARK: - Non-Premium Notification Clearing Tests

    @Test("Non-premium user with existing notifications gets them cleared")
    func nonPremiumUserWithExistingNotificationsGetsThemCleared() async throws {
        let container = try TestModelContainer.create()
        let scheduleHabitReminders = TrackingScheduleHabitReminders()
        let notificationService = TestNotificationService()

        // Simulate existing notifications from when user was premium
        let existingNotificationIds = [
            "today_\(UUID().uuidString)-09:00",
            "rich_\(UUID().uuidString)-10:00",
            "tailored_\(UUID().uuidString)-11:00"
        ]
        await notificationService.setPendingNotificationIds(existingNotificationIds)

        // Create service with non-premium subscription
        let (service, _) = createService(
            container: container,
            scheduleHabitReminders: scheduleHabitReminders,
            subscriptionService: TestSubscriptionService(isPremium: false),
            notificationService: notificationService
        )

        // Execute
        try await service.rescheduleAllHabitNotifications()

        // Verify: All existing notifications should be cleared
        let clearedIds = await notificationService.getClearedNotificationIds()
        #expect(clearedIds.count == 3, "All existing habit notifications should be cleared for non-premium user")
        #expect(Set(clearedIds) == Set(existingNotificationIds), "Cleared IDs should match existing notification IDs")

        // Verify: No new notifications scheduled
        let scheduledHabits = await scheduleHabitReminders.getScheduledHabits()
        #expect(scheduledHabits.count == 0, "Non-premium users should not have new notifications scheduled")
    }

    @Test("Non-premium user with no existing notifications completes without error")
    func nonPremiumUserWithNoExistingNotificationsCompletesWithoutError() async throws {
        let container = try TestModelContainer.create()
        let scheduleHabitReminders = TrackingScheduleHabitReminders()
        let notificationService = TestNotificationService()

        // No existing notifications
        await notificationService.setPendingNotificationIds([])

        // Create service with non-premium subscription
        let (service, _) = createService(
            container: container,
            scheduleHabitReminders: scheduleHabitReminders,
            subscriptionService: TestSubscriptionService(isPremium: false),
            notificationService: notificationService
        )

        // Execute - should not throw
        try await service.rescheduleAllHabitNotifications()

        // Verify: clearHabitNotifications should not be called when there's nothing to clear
        let clearCount = await notificationService.getClearCallCount()
        #expect(clearCount == 0, "Should not call clearHabitNotifications when no notifications exist")
    }

    @Test("Premium to non-premium downgrade clears all habit notifications")
    func premiumToNonPremiumDowngradeClearsAllHabitNotifications() async throws {
        let container = try TestModelContainer.create()
        let scheduleHabitReminders = TrackingScheduleHabitReminders()
        let notificationService = TestNotificationService()

        // Create habits
        let habit1 = HabitBuilder.binary(
            name: "Morning Routine",
            isActive: true,
            reminders: [ReminderTime(hour: 9, minute: 0)]
        )
        try await saveHabits([habit1], to: container)

        // Simulate notifications that were scheduled when user was premium
        let habitNotificationIds = [
            "today_\(habit1.id.uuidString)-09:00",
            "catchup_\(habit1.id.uuidString)"
        ]
        await notificationService.setPendingNotificationIds(habitNotificationIds)

        // Now user is non-premium (subscription expired)
        let (service, _) = createService(
            container: container,
            scheduleHabitReminders: scheduleHabitReminders,
            subscriptionService: TestSubscriptionService(isPremium: false),
            notificationService: notificationService
        )

        // Execute reschedule (triggered by app launch or background refresh)
        try await service.rescheduleAllHabitNotifications()

        // Verify: All habit notifications cleared
        let clearedIds = await notificationService.getClearedNotificationIds()
        #expect(clearedIds.count == 2, "All habit notifications should be cleared after downgrade")

        // Verify: Pending notifications should be empty now
        let remainingIds = await notificationService.getPendingHabitNotificationIds()
        #expect(remainingIds.isEmpty, "No habit notifications should remain after downgrade")
    }

}

// MARK: - Test Subscription Service

/// Simple test implementation of SecureSubscriptionService
private final class TestSubscriptionService: SecureSubscriptionService {
    private let isPremium: Bool

    init(isPremium: Bool = true) {
        self.isPremium = isPremium
    }

    func validatePurchase(_ productId: String) async -> Bool {
        isPremium
    }

    func restorePurchases() async -> [String] {
        isPremium ? ["premium_subscription"] : []
    }

    func isPremiumUser() -> Bool {
        isPremium
    }

    func getValidPurchases() -> [String] {
        isPremium ? ["premium_subscription"] : []
    }

    func registerPurchase(_ productId: String) async throws {
        // No-op for tests
    }

    func clearPurchases() async throws {
        // No-op for tests
    }

    func getCurrentSubscriptionPlan() async -> SubscriptionPlan {
        isPremium ? .annual : .free
    }

    func getSubscriptionExpiryDate() async -> Date? {
        isPremium ? Date().addingTimeInterval(365 * 24 * 60 * 60) : nil
    }
}

