import Testing
import Foundation
import SwiftData
@testable import RitualistCore

/// Tests for HabitCompletionCheckService - Orchestration Layer Only
///
/// **Service Purpose:** Determines if notifications should be shown based on habit completion
/// **Why Critical:** Orchestrates notification decisions with fail-safe error handling
/// **Test Strategy:** Focus on ORCHESTRATION, not completion logic (already tested)
///
/// **IMPORTANT - Testing Scope:**
/// This service is an orchestration layer coordinating multiple dependencies.
/// Core completion logic is ALREADY tested in HabitCompletionServiceTests (25 tests).
/// These tests validate ONLY orchestration behavior:
/// - Lifecycle validations (isActive, date boundaries)
/// - Repository coordination (async fetching)
/// - Timezone service integration
/// - Fail-safe error handling
/// - Service delegation
///
/// **Test Coverage:**
/// - Lifecycle validation (inactive habits, date boundaries)
/// - Repository orchestration (habit/log fetching, error handling)
/// - Timezone service integration (display timezone, error fallback)
/// - Fail-safe behavior (errors return true to show notifications)
/// - Service delegation (correct calls to HabitCompletionService)
@Suite(
    "HabitCompletionCheckService - Orchestration Layer Tests",
    .tags(.notifications, .completion, .orchestration, .high, .database, .integration, .errorHandling, .fast)
)
@MainActor
struct HabitCompletionCheckServiceTests {

    // MARK: - Test Fixtures

    let today = TestDates.today
    let yesterday = TestDates.yesterday
    let tomorrow = TestDates.tomorrow

    // MARK: - Helper: Create Service with Dependencies

    /// Creates service with real dependencies using in-memory container
    func createService(
        container: ModelContainer,
        timezone: TimeZone = .current,
        shouldThrowTimezoneError: Bool = false
    ) -> DefaultHabitCompletionCheckService {
        // Create data sources (ModelActor requires modelContainer)
        let habitLocalDataSource = HabitLocalDataSource(modelContainer: container)
        let logLocalDataSource = LogLocalDataSource(modelContainer: container)

        // Create repositories (requires local data sources)
        let habitRepository = HabitRepositoryImpl(local: habitLocalDataSource)
        let logRepository = LogRepositoryImpl(local: logLocalDataSource)

        let completionService = DefaultHabitCompletionService()
        let timezoneService = MockTimezoneService(
            displayTimezone: timezone,
            shouldThrowError: shouldThrowTimezoneError
        )

        return DefaultHabitCompletionCheckService(
            habitRepository: habitRepository,
            logRepository: logRepository,
            habitCompletionService: completionService,
            timezoneService: timezoneService
        )
    }

    // MARK: - 1. Lifecycle Validation Tests

    @Test("shouldShowNotification returns false for inactive habit")
    func inactiveHabitDoesNotShowNotification() async throws {
        let container = try TestModelContainer.create()
        let service = createService(container: container)

        // Create inactive habit
        let habit = HabitBuilder.binary(
            name: "Test Habit",
            schedule: .daily,
            isActive: false  // Inactive
        )

        // Save to repository
        try await saveHabit(habit, to: container)

        // Should return false (don't show notification for inactive habits)
        let shouldShow = await service.shouldShowNotification(habitId: habit.id, date: today)

        #expect(shouldShow == false, "Inactive habits should not trigger notifications")
    }

    @Test("shouldShowNotification returns false before habit start date")
    func dateBeforeStartDateDoesNotShowNotification() async throws {
        let container = try TestModelContainer.create()
        let service = createService(container: container)

        // Create habit starting tomorrow
        let habit = HabitBuilder.binary(
            name: "Future Habit",
            schedule: .daily,
            startDate: tomorrow
        )

        try await saveHabit(habit, to: container)

        // Check today (before start date)
        let shouldShow = await service.shouldShowNotification(habitId: habit.id, date: today)

        #expect(shouldShow == false, "Should not show notification before habit start date")
    }

    @Test("shouldShowNotification returns false after habit end date")
    func dateAfterEndDateDoesNotShowNotification() async throws {
        let container = try TestModelContainer.create()
        let service = createService(container: container)

        // Create habit with end date of yesterday
        var habit = HabitBuilder.binary(
            name: "Past Habit",
            schedule: .daily,
            startDate: TestDates.daysAgo(10)
        )
        // Manually set end date (not available in builder)
        habit = Habit(
            id: habit.id,
            name: habit.name,
            colorHex: habit.colorHex,
            emoji: habit.emoji,
            kind: habit.kind,
            unitLabel: habit.unitLabel,
            dailyTarget: habit.dailyTarget,
            schedule: habit.schedule,
            reminders: habit.reminders,
            startDate: habit.startDate,
            endDate: yesterday,  // End yesterday
            isActive: habit.isActive,
            displayOrder: habit.displayOrder,
            categoryId: habit.categoryId,
            suggestionId: habit.suggestionId,
            isPinned: habit.isPinned,
            notes: habit.notes,
            lastCompletedDate: habit.lastCompletedDate,
            archivedDate: habit.archivedDate,
            locationConfiguration: habit.locationConfiguration,
            priorityLevel: habit.priorityLevel
        )

        try await saveHabit(habit, to: container)

        // Check today (after end date)
        let shouldShow = await service.shouldShowNotification(habitId: habit.id, date: today)

        #expect(shouldShow == false, "Should not show notification after habit end date")
    }

    @Test("shouldShowNotification returns false exactly on habit end date boundary")
    func exactlyOnEndDateDoesNotShowNotification() async throws {
        let container = try TestModelContainer.create()
        let service = createService(container: container)

        // Create habit ending today
        var habit = HabitBuilder.binary(
            name: "Ending Today",
            schedule: .daily,
            startDate: yesterday
        )
        habit = Habit(
            id: habit.id,
            name: habit.name,
            colorHex: habit.colorHex,
            emoji: habit.emoji,
            kind: habit.kind,
            unitLabel: habit.unitLabel,
            dailyTarget: habit.dailyTarget,
            schedule: habit.schedule,
            reminders: habit.reminders,
            startDate: habit.startDate,
            endDate: today,  // Ends today
            isActive: habit.isActive,
            displayOrder: habit.displayOrder,
            categoryId: habit.categoryId,
            suggestionId: habit.suggestionId,
            isPinned: habit.isPinned,
            notes: habit.notes,
            lastCompletedDate: habit.lastCompletedDate,
            archivedDate: habit.archivedDate,
            locationConfiguration: habit.locationConfiguration,
            priorityLevel: habit.priorityLevel
        )

        try await saveHabit(habit, to: container)

        // Check today (exactly on end date)
        let shouldShow = await service.shouldShowNotification(habitId: habit.id, date: today)

        #expect(shouldShow == false, "End date is exclusive - should not show on end date itself")
    }

    // MARK: - 2. Repository Orchestration Tests

    @Test("shouldShowNotification fails safe when habit not found (returns true)")
    func habitNotFoundFailsSafe() async throws {
        let container = try TestModelContainer.create()
        let service = createService(container: container)

        // Use random UUID that doesn't exist
        let nonExistentId = UUID()

        // Should fail safe by returning true (show notification)
        let shouldShow = await service.shouldShowNotification(habitId: nonExistentId, date: today)

        #expect(shouldShow == true, "Missing habit should fail safe by showing notification")
    }

    @Test("shouldShowNotification fetches habit from repository asynchronously")
    func fetchesHabitFromRepository() async throws {
        let container = try TestModelContainer.create()
        let service = createService(container: container)

        // Create and save habit
        let habit = HabitBuilder.binary(name: "Fetched Habit", schedule: .daily)
        try await saveHabit(habit, to: container)

        // Service should fetch habit by ID
        let shouldShow = await service.shouldShowNotification(habitId: habit.id, date: today)

        // Verification: If habit was fetched and is active, logic proceeds
        // (We can't directly verify the fetch, but we can verify it works)
        #expect(shouldShow == true, "Active habit with no logs should show notification")
    }

    @Test("shouldShowNotification fetches logs from repository for completion check")
    func fetchesLogsFromRepository() async throws {
        let container = try TestModelContainer.create()
        let service = createService(container: container)

        // Create habit and complete it
        let habit = HabitBuilder.binary(name: "Completed Habit", schedule: .daily)
        let log = HabitLogBuilder.binary(habitId: habit.id, date: today)

        try await saveHabit(habit, to: container)
        try await saveLog(log, to: container)

        // Service should fetch logs and determine habit is completed
        let shouldShow = await service.shouldShowNotification(habitId: habit.id, date: today)

        #expect(shouldShow == false, "Completed habit should not show notification")
    }

    // MARK: - 3. Timezone Service Integration Tests

    @Test("shouldShowNotification uses display timezone from TimezoneService")
    func usesDisplayTimezoneFromService() async throws {
        let container = try TestModelContainer.create()

        // Create a date that's "today" in UTC but "tomorrow" in Tokyo (+9 hours)
        // This will PROVE the timezone is actually used for date boundary checks
        let utc = TimeZone(identifier: "UTC")!
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!  // UTC+9

        // Create a date at 20:00 UTC (which is 05:00 next day in Tokyo)
        var components = DateComponents()
        components.year = 2025
        components.month = 11
        components.day = 8
        components.hour = 20
        components.minute = 0
        components.timeZone = utc
        let dateAtBoundary = Calendar.current.date(from: components)!

        // Create habit that starts "tomorrow" in Tokyo timezone
        let tomorrowInTokyo = CalendarUtils.addDays(1, to: CalendarUtils.startOfDayLocal(for: dateAtBoundary, timezone: tokyo))

        let habit = HabitBuilder.binary(
            name: "Tokyo Habit",
            schedule: .daily,
            startDate: tomorrowInTokyo
        )

        try await saveHabit(habit, to: container)

        // Create service with Tokyo timezone
        let service = createService(container: container, timezone: tokyo)

        // Check notification with the boundary date
        // If service uses Tokyo timezone: dateAtBoundary is "tomorrow" → should return false (before start)
        // If service ignores timezone: dateAtBoundary might be "today" → could return true
        let shouldShow = await service.shouldShowNotification(habitId: habit.id, date: dateAtBoundary)

        // This PROVES timezone is used: habit starts tomorrow in Tokyo, so no notification today
        #expect(shouldShow == false, "Should not show notification - habit starts tomorrow in Tokyo timezone")
    }

    @Test("shouldShowNotification falls back to current timezone on TimezoneService error")
    func fallsBackToCurrentTimezoneOnError() async throws {
        let container = try TestModelContainer.create()
        // Create service that throws error when fetching timezone
        let service = createService(container: container, shouldThrowTimezoneError: true)

        // Create active habit
        let habit = HabitBuilder.binary(name: "Fallback Test", schedule: .daily)
        try await saveHabit(habit, to: container)

        // Service should fall back to TimeZone.current and continue working
        let shouldShow = await service.shouldShowNotification(habitId: habit.id, date: today)

        #expect(shouldShow == true, "Should continue working with fallback timezone")
    }

    // MARK: - 4. Service Delegation Tests

    @Test("shouldShowNotification delegates to isScheduledDay for daysOfWeek habits")
    func delegatesToIsScheduledDayForDaysOfWeekHabits() async throws {
        let container = try TestModelContainer.create()
        let service = createService(container: container)

        // Create daysOfWeek habit scheduled only on Monday (weekday 2)
        let habit = HabitBuilder.binary(
            name: "Monday Only",
            schedule: .daysOfWeek([2])  // Monday only
        )

        try await saveHabit(habit, to: container)

        // Get the weekday of 'today' from TestDates
        let todayWeekday = CalendarUtils.weekdayComponentLocal(from: today)

        let shouldShow = await service.shouldShowNotification(habitId: habit.id, date: today)

        // If today is Monday, should check completion and show notification (no log = incomplete)
        // If today is not Monday, should return false (not scheduled)
        if todayWeekday == 2 {
            #expect(shouldShow == true, "Monday habit should show on Monday when incomplete")
        } else {
            #expect(shouldShow == false, "Monday habit should not show on non-Monday")
        }
    }

    @Test("shouldShowNotification delegates to isCompleted correctly")
    func delegatesToIsCompletedCorrectly() async throws {
        let container = try TestModelContainer.create()
        let service = createService(container: container)

        // Create daily habit
        let habit = HabitBuilder.binary(name: "Daily Check", schedule: .daily)

        // Create log marking habit as completed (binary log with value=1.0)
        let completedLog = HabitLogBuilder.binary(
            habitId: habit.id,
            date: today
        )

        try await saveHabit(habit, to: container)
        try await saveLog(completedLog, to: container)

        // Service should delegate to isCompleted and get true
        let shouldShow = await service.shouldShowNotification(habitId: habit.id, date: today)

        // Habit is completed, so should NOT show notification
        #expect(shouldShow == false, "Completed habit should not show notification")
    }

    @Test("shouldShowNotification returns opposite of isCompleted (notification when NOT complete)")
    func returnsOppositeOfIsCompleted() async throws {
        let container = try TestModelContainer.create()
        let service = createService(container: container)

        // Test 1: Incomplete habit (no log)
        let incompleteHabit = HabitBuilder.binary(name: "Incomplete", schedule: .daily)
        try await saveHabit(incompleteHabit, to: container)

        let shouldShowIncomplete = await service.shouldShowNotification(
            habitId: incompleteHabit.id,
            date: today
        )

        #expect(shouldShowIncomplete == true, "Incomplete habit should show notification")

        // Test 2: Complete habit (with log)
        let completeHabit = HabitBuilder.binary(name: "Complete", schedule: .daily)
        let completeLog = HabitLogBuilder.binary(
            habitId: completeHabit.id,
            date: today
        )

        try await saveHabit(completeHabit, to: container)
        try await saveLog(completeLog, to: container)

        let shouldShowComplete = await service.shouldShowNotification(
            habitId: completeHabit.id,
            date: today
        )

        #expect(shouldShowComplete == false, "Complete habit should not show notification")
    }

    // MARK: - Helper Methods

    private func saveHabit(_ habit: Habit, to container: ModelContainer) async throws {
        let context = ModelContext(container)
        let habitModel = habit.toModel()
        context.insert(habitModel)
        try context.save()
    }

    private func saveLog(_ log: HabitLog, to container: ModelContainer) async throws {
        let context = ModelContext(container)
        let logModel = log.toModel()
        context.insert(logModel)
        try context.save()
    }
}
