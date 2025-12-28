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
        subscriptionService: SecureSubscriptionService? = nil,
        notificationService: TrackingNotificationService? = nil,
        habitCompletionCheckService: HabitCompletionCheckService? = nil
    ) -> (scheduler: DefaultDailyNotificationScheduler, notificationService: TrackingNotificationService) {
        // Create REAL data source and repository
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        let logRepository = LogRepositoryImpl(local: logDataSource)

        // Use test implementations for NotificationService (system dependency)
        let testNotificationService = notificationService ?? TrackingNotificationService()
        let logger = DebugLogger(subsystem: "test", category: "scheduler")

        // Default to premium user for existing tests
        let subscription = subscriptionService ?? TestSubscriptionService(isPremium: true)

        // Create completion check service if not provided
        let habitCompletionService = DefaultHabitCompletionService()
        let timezoneService = MockTimezoneService()
        let completionCheck = habitCompletionCheckService ?? DefaultHabitCompletionCheckService(
            habitRepository: habitRepository,
            logRepository: logRepository,
            habitCompletionService: habitCompletionService,
            timezoneService: timezoneService
        )

        let scheduler = DefaultDailyNotificationScheduler(
            habitRepository: habitRepository,
            habitCompletionCheckService: completionCheck,
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

        // Create habits: 2 active with reminders, 1 active without, 1 inactive with reminders
        // Use future times to ensure notifications are scheduled (not catch-up)
        let activeWithReminders1 = HabitBuilder.binary(
            name: "Active With Reminders 1",
            isActive: true,
            reminders: [ReminderTime(hour: 23, minute: 55)]
        )

        let activeWithReminders2 = HabitBuilder.binary(
            name: "Active With Reminders 2",
            isActive: true,
            reminders: [ReminderTime(hour: 23, minute: 56)]
        )

        let activeWithoutReminders = HabitBuilder.binary(
            name: "Active Without Reminders",
            isActive: true
        )

        let inactiveWithReminders = HabitBuilder.binary(
            name: "Inactive With Reminders",
            isActive: false,
            reminders: [ReminderTime(hour: 23, minute: 57)]
        )

        try await saveHabits([
            activeWithReminders1,
            activeWithReminders2,
            activeWithoutReminders,
            inactiveWithReminders
        ], to: container)

        let (service, notificationService) = createService(container: container)

        // Execute
        try await service.rescheduleAllHabitNotifications()

        // Verify: Should only schedule for 2 active habits with reminders
        let scheduledNotifications = await notificationService.getScheduledNotifications()
        #expect(scheduledNotifications.count == 2)
        #expect(scheduledNotifications.contains { $0.habitName == "Active With Reminders 1" })
        #expect(scheduledNotifications.contains { $0.habitName == "Active With Reminders 2" })
    }

    @Test("Skips inactive habits even if they have reminders")
    func skipsInactiveHabitsEvenIfTheyHaveReminders() async throws {
        let container = try TestModelContainer.create()

        // Create only inactive habits with reminders
        let inactive1 = HabitBuilder.binary(
            name: "Inactive 1",
            isActive: false,
            reminders: [ReminderTime(hour: 23, minute: 55)]
        )

        let inactive2 = HabitBuilder.binary(
            name: "Inactive 2",
            isActive: false,
            reminders: [ReminderTime(hour: 23, minute: 56)]
        )

        try await saveHabits([inactive1, inactive2], to: container)

        let (service, notificationService) = createService(container: container)

        // Execute
        try await service.rescheduleAllHabitNotifications()

        // Verify: Should not schedule any
        let scheduledNotifications = await notificationService.getScheduledNotifications()
        #expect(scheduledNotifications.count == 0)
    }

    @Test("Skips active habits without reminders")
    func skipsActiveHabitsWithoutReminders() async throws {
        let container = try TestModelContainer.create()

        // Create only active habits without reminders
        let active1 = HabitBuilder.binary(name: "Active 1", isActive: true)
        let active2 = HabitBuilder.binary(name: "Active 2", isActive: true)

        try await saveHabits([active1, active2], to: container)

        let (service, notificationService) = createService(container: container)

        // Execute
        try await service.rescheduleAllHabitNotifications()

        // Verify: Should not schedule any
        let scheduledNotifications = await notificationService.getScheduledNotifications()
        #expect(scheduledNotifications.count == 0)
    }

    // MARK: - Use Case Orchestration Tests

    @Test("Schedules notifications for each eligible habit")
    func schedulesNotificationsForEachEligibleHabit() async throws {
        let container = try TestModelContainer.create()

        // Create 3 active habits with reminders (use future times)
        let habit1 = HabitBuilder.binary(
            name: "Habit 1",
            isActive: true,
            reminders: [ReminderTime(hour: 23, minute: 55)]
        )

        let habit2 = HabitBuilder.binary(
            name: "Habit 2",
            isActive: true,
            reminders: [ReminderTime(hour: 23, minute: 56)]
        )

        let habit3 = HabitBuilder.binary(
            name: "Habit 3",
            isActive: true,
            reminders: [ReminderTime(hour: 23, minute: 57)]
        )

        try await saveHabits([habit1, habit2, habit3], to: container)

        let (service, notificationService) = createService(container: container)

        // Execute
        try await service.rescheduleAllHabitNotifications()

        // Verify: All 3 should be scheduled
        let scheduledNotifications = await notificationService.getScheduledNotifications()
        #expect(scheduledNotifications.count == 3)
    }

    @Test("Schedules notifications with correct badge numbers in time order")
    func schedulesNotificationsWithCorrectBadgeNumbersInTimeOrder() async throws {
        let container = try TestModelContainer.create()

        // Create habits with different times to verify badge ordering
        let habit1 = HabitBuilder.binary(
            name: "Late Habit",
            isActive: true,
            reminders: [ReminderTime(hour: 23, minute: 59)]
        )

        let habit2 = HabitBuilder.binary(
            name: "Early Habit",
            isActive: true,
            reminders: [ReminderTime(hour: 23, minute: 55)]
        )

        let habit3 = HabitBuilder.binary(
            name: "Middle Habit",
            isActive: true,
            reminders: [ReminderTime(hour: 23, minute: 57)]
        )

        try await saveHabits([habit1, habit2, habit3], to: container)

        let (service, notificationService) = createService(container: container)

        // Execute
        try await service.rescheduleAllHabitNotifications()

        // Verify: Badge numbers should be in chronological order
        let scheduledNotifications = await notificationService.getScheduledNotifications()
        #expect(scheduledNotifications.count == 3)

        // Find notifications by name and check badge numbers
        let earlyNotification = scheduledNotifications.first { $0.habitName == "Early Habit" }
        let middleNotification = scheduledNotifications.first { $0.habitName == "Middle Habit" }
        let lateNotification = scheduledNotifications.first { $0.habitName == "Late Habit" }

        #expect(earlyNotification?.badgeNumber == 1)
        #expect(middleNotification?.badgeNumber == 2)
        #expect(lateNotification?.badgeNumber == 3)
    }

    // MARK: - Error Handling Tests

    @Test("Propagates repository errors")
    func propagatesRepositoryErrors() async throws {
        let container = try TestModelContainer.create()

        // Create failing repository
        let failingRepo = FailingHabitRepository()
        await failingRepo.setShouldFailFetchAll(true)

        let notificationService = TrackingNotificationService()
        let logger = DebugLogger(subsystem: "test", category: "scheduler")

        // Create a mock completion check service
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        let habitCompletionService = DefaultHabitCompletionService()
        let timezoneService = MockTimezoneService()
        let completionCheck = DefaultHabitCompletionCheckService(
            habitRepository: habitRepository,
            logRepository: logRepository,
            habitCompletionService: habitCompletionService,
            timezoneService: timezoneService
        )

        let service = DefaultDailyNotificationScheduler(
            habitRepository: failingRepo,
            habitCompletionCheckService: completionCheck,
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
        // Don't save any habits

        let (service, notificationService) = createService(container: container)

        // Should not throw
        try await service.rescheduleAllHabitNotifications()

        // Verify: No notifications scheduled
        let scheduledNotifications = await notificationService.getScheduledNotifications()
        #expect(scheduledNotifications.count == 0)
    }

    @Test("Handles all habits filtered out gracefully")
    func handlesAllHabitsFilteredOutGracefully() async throws {
        let container = try TestModelContainer.create()

        // Create habits that should all be filtered out
        let inactiveWithReminders = HabitBuilder.binary(
            name: "Inactive",
            isActive: false,
            reminders: [ReminderTime(hour: 23, minute: 55)]
        )

        let activeWithoutReminders = HabitBuilder.binary(name: "No Reminders", isActive: true)

        try await saveHabits([inactiveWithReminders, activeWithoutReminders], to: container)

        let (service, notificationService) = createService(container: container)

        // Should not throw
        try await service.rescheduleAllHabitNotifications()

        // Verify: No notifications scheduled
        let scheduledNotifications = await notificationService.getScheduledNotifications()
        #expect(scheduledNotifications.count == 0)
    }

    // MARK: - Premium Gating Tests

    @Test("Skips scheduling notifications for non-premium users")
    func skipsSchedulingNotificationsForNonPremiumUsers() async throws {
        let container = try TestModelContainer.create()

        // Create active habits with reminders that WOULD be scheduled for premium users
        let habit1 = HabitBuilder.binary(
            name: "Active With Reminders 1",
            isActive: true,
            reminders: [ReminderTime(hour: 23, minute: 55)]
        )

        let habit2 = HabitBuilder.binary(
            name: "Active With Reminders 2",
            isActive: true,
            reminders: [ReminderTime(hour: 23, minute: 56)]
        )

        try await saveHabits([habit1, habit2], to: container)

        // Use non-premium subscription service
        let (service, notificationService) = createService(
            container: container,
            subscriptionService: TestSubscriptionService(isPremium: false)
        )

        // Execute
        try await service.rescheduleAllHabitNotifications()

        // Verify: Should NOT schedule any notifications for non-premium users
        let scheduledNotifications = await notificationService.getScheduledNotifications()
        #expect(scheduledNotifications.count == 0, "Non-premium users should not have notifications scheduled")
    }

    @Test("Premium users get notifications scheduled normally")
    func premiumUsersGetNotificationsScheduledNormally() async throws {
        let container = try TestModelContainer.create()

        // Create active habits with reminders
        let habit1 = HabitBuilder.binary(
            name: "Active With Reminders 1",
            isActive: true,
            reminders: [ReminderTime(hour: 23, minute: 55)]
        )

        let habit2 = HabitBuilder.binary(
            name: "Active With Reminders 2",
            isActive: true,
            reminders: [ReminderTime(hour: 23, minute: 56)]
        )

        try await saveHabits([habit1, habit2], to: container)

        // Explicitly use premium subscription service
        let (service, notificationService) = createService(
            container: container,
            subscriptionService: TestSubscriptionService(isPremium: true)
        )

        // Execute
        try await service.rescheduleAllHabitNotifications()

        // Verify: Premium users should have notifications scheduled
        let scheduledNotifications = await notificationService.getScheduledNotifications()
        #expect(scheduledNotifications.count == 2, "Premium users should have notifications scheduled")
    }

    // MARK: - Non-Premium Notification Clearing Tests

    @Test("Non-premium user with existing notifications gets them cleared")
    func nonPremiumUserWithExistingNotificationsGetsThemCleared() async throws {
        let container = try TestModelContainer.create()
        let notificationService = TrackingNotificationService()

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
        let scheduledNotifications = await notificationService.getScheduledNotifications()
        #expect(scheduledNotifications.count == 0, "Non-premium users should not have new notifications scheduled")
    }

    @Test("Non-premium user with no existing notifications completes without error")
    func nonPremiumUserWithNoExistingNotificationsCompletesWithoutError() async throws {
        let container = try TestModelContainer.create()
        let notificationService = TrackingNotificationService()

        // No existing notifications
        await notificationService.setPendingNotificationIds([])

        // Create service with non-premium subscription
        let (service, _) = createService(
            container: container,
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
        let notificationService = TrackingNotificationService()

        // Create habits
        let habit1 = HabitBuilder.binary(
            name: "Morning Routine",
            isActive: true,
            reminders: [ReminderTime(hour: 23, minute: 55)]
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
private actor TestSubscriptionService: SecureSubscriptionService {
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

    func isPremiumUser() async -> Bool {
        isPremium
    }

    func getValidPurchases() async -> [String] {
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

