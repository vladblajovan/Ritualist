import XCTest
@testable import Ritualist
import RitualistCore
import Testing

// MARK: - Mock Services for Testing

class MockHabitCompletionCheckService: HabitCompletionCheckService {
    var shouldShowResponses: [UUID: Bool] = [:]
    var callLog: [(habitId: UUID, date: Date)] = []
    
    func shouldShowNotification(habitId: UUID, date: Date) async -> Bool {
        callLog.append((habitId: habitId, date: date))
        return shouldShowResponses[habitId] ?? true // Default to show notification
    }
    
    func reset() {
        shouldShowResponses.removeAll()
        callLog.removeAll()
    }
}

class MockCancelHabitRemindersUseCase: CancelHabitRemindersUseCase {
    var cancelledHabits: [UUID] = []
    
    func execute(habitId: UUID) async {
        cancelledHabits.append(habitId)
    }
    
    func reset() {
        cancelledHabits.removeAll()
    }
}

class MockNotificationService: NotificationService {
    var requestAuthorizationCalled = false
    var checkAuthorizationStatusCalled = false
    var scheduledHabits: [(UUID, [ReminderTime])] = []
    var scheduledWithActionsHabits: [(UUID, String, [ReminderTime])] = []  // Track rich notifications separately
    var cancelledHabits: [UUID] = []
    var immediateNotifications: [(String, String)] = []
    var categoriesSetup = false
    
    func requestAuthorizationIfNeeded() async throws -> Bool {
        requestAuthorizationCalled = true
        return true
    }
    
    func checkAuthorizationStatus() async -> Bool {
        checkAuthorizationStatusCalled = true
        return true
    }
    
    func schedule(for habitID: UUID, times: [ReminderTime]) async throws {
        scheduledHabits.append((habitID, times))
    }
    
    func scheduleWithActions(for habitID: UUID, habitName: String, habitKind: HabitKind, times: [ReminderTime]) async throws {
        scheduledWithActionsHabits.append((habitID, habitName, times))
    }
    
    func cancel(for habitID: UUID) async {
        cancelledHabits.append(habitID)
    }
    
    func sendImmediate(title: String, body: String) async throws {
        immediateNotifications.append((title, body))
    }
    
    func setupNotificationCategories() async {
        categoriesSetup = true
    }
    
    func scheduleRichReminders(for habitID: UUID, habitName: String, habitCategory: String?, currentStreak: Int, times: [ReminderTime]) async throws {
        // Mock implementation
    }
    
    func schedulePersonalityTailoredReminders(for habitID: UUID, habitName: String, habitCategory: String?, currentStreak: Int, personalityProfile: PersonalityProfile, times: [ReminderTime]) async throws {
        // Mock implementation
    }
    
    func sendStreakMilestone(for habitID: UUID, habitName: String, streakDays: Int) async throws {
        // Mock implementation
    }
    
    func reset() {
        requestAuthorizationCalled = false
        checkAuthorizationStatusCalled = false
        scheduledHabits.removeAll()
        scheduledWithActionsHabits.removeAll()
        cancelledHabits.removeAll()
        immediateNotifications.removeAll()
        categoriesSetup = false
    }
}

// MARK: - Mock Repositories for Testing

class MockHabitRepository: HabitRepository {
    var habits: [Habit] = []
    
    func fetchAllHabits() async throws -> [Habit] {
        return habits
    }
    
    func fetchHabit(by id: UUID) async throws -> Habit? {
        return habits.first { $0.id == id }
    }
    
    func create(_ habit: Habit) async throws {
        habits.append(habit)
    }
    
    func update(_ habit: Habit) async throws {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
        }
    }
    
    func delete(id: UUID) async throws {
        habits.removeAll { $0.id == id }
    }
    
    func cleanupOrphanedHabits() async throws -> Int {
        return 0 // Mock implementation
    }
    
    func reset() {
        habits.removeAll()
    }
}

class MockLogRepository: LogRepository {
    var logs: [HabitLog] = []
    
    func logs(for habitID: UUID) async throws -> [HabitLog] {
        return logs.filter { $0.habitID == habitID }
    }
    
    func logs(for habitIDs: [UUID]) async throws -> [HabitLog] {
        return logs.filter { habitIDs.contains($0.habitID) }
    }
    
    func upsert(_ log: HabitLog) async throws {
        if let index = logs.firstIndex(where: { $0.id == log.id }) {
            logs[index] = log
        } else {
            logs.append(log)
        }
    }
    
    func deleteLog(id: UUID) async throws {
        logs.removeAll { $0.id == id }
    }
    
    func reset() {
        logs.removeAll()
    }
}

// MARK: - Notification Use Cases Tests

class NotificationUseCaseTests: XCTestCase {
    
    var mockNotificationService: MockNotificationService!
    var mockHabitRepository: MockHabitRepository!
    var mockLogRepository: MockLogRepository!
    var mockHabitCompletionCheckService: MockHabitCompletionCheckService!
    
    override func setUp() {
        super.setUp()
        mockNotificationService = MockNotificationService()
        mockHabitRepository = MockHabitRepository()
        mockLogRepository = MockLogRepository()
        mockHabitCompletionCheckService = MockHabitCompletionCheckService()
    }
    
    override func tearDown() {
        mockNotificationService?.reset()
        mockHabitRepository?.reset()
        mockLogRepository?.reset()
        mockHabitCompletionCheckService?.reset()
        mockNotificationService = nil
        mockHabitRepository = nil
        mockLogRepository = nil
        mockHabitCompletionCheckService = nil
        super.tearDown()
    }
    
    // MARK: - ScheduleHabitReminders Tests
    
    func testScheduleHabitReminders_ActiveHabitWithReminders_SchedulesNotifications() async {
        // Arrange
        let habit = Habit(
            id: UUID(),
            name: "Test Habit",
            reminders: [ReminderTime(hour: 9, minute: 0), ReminderTime(hour: 18, minute: 30)],
            isActive: true
        )
        mockHabitRepository.habits = [habit]
        
        let useCase = ScheduleHabitReminders(
            habitRepository: mockHabitRepository,
            notificationService: mockNotificationService,
            habitCompletionCheckService: mockHabitCompletionCheckService
        )
        
        // Act
        do {
            try await useCase.execute(habit: habit)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert
        XCTAssertEqual(mockNotificationService.cancelledHabits.count, 1)
        XCTAssertEqual(mockNotificationService.cancelledHabits.first, habit.id)
        
        // Verify that scheduleWithActions was called (not the basic schedule method)
        XCTAssertEqual(mockNotificationService.scheduledWithActionsHabits.count, 1)
        XCTAssertEqual(mockNotificationService.scheduledWithActionsHabits.first?.0, habit.id)
        XCTAssertEqual(mockNotificationService.scheduledWithActionsHabits.first?.1, "Test Habit")
        XCTAssertEqual(mockNotificationService.scheduledWithActionsHabits.first?.2.count, 2)
        
        // Verify basic schedule was NOT called
        XCTAssertEqual(mockNotificationService.scheduledHabits.count, 0)
    }
    
    func testScheduleHabitReminders_InactiveHabit_DoesNotSchedule() async {
        // Arrange
        let habit = Habit(
            id: UUID(),
            name: "Test Habit",
            reminders: [ReminderTime(hour: 9, minute: 0)],
            isActive: false
        )
        
        let useCase = ScheduleHabitReminders(
            habitRepository: mockHabitRepository,
            notificationService: mockNotificationService,
            habitCompletionCheckService: mockHabitCompletionCheckService
        )
        
        // Act
        do {
            try await useCase.execute(habit: habit)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert
        XCTAssertEqual(mockNotificationService.cancelledHabits.count, 1)
        XCTAssertTrue(mockNotificationService.scheduledHabits.isEmpty)
        XCTAssertTrue(mockNotificationService.scheduledWithActionsHabits.isEmpty)
    }
    
    func testScheduleHabitReminders_HabitWithoutReminders_DoesNotSchedule() async {
        // Arrange
        let habit = Habit(
            id: UUID(),
            name: "Test Habit",
            reminders: [],
            isActive: true
        )
        
        let useCase = ScheduleHabitReminders(
            habitRepository: mockHabitRepository,
            notificationService: mockNotificationService,
            habitCompletionCheckService: mockHabitCompletionCheckService
        )
        
        // Act
        do {
            try await useCase.execute(habit: habit)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert
        XCTAssertEqual(mockNotificationService.cancelledHabits.count, 1)
        XCTAssertTrue(mockNotificationService.scheduledHabits.isEmpty)
        XCTAssertTrue(mockNotificationService.scheduledWithActionsHabits.isEmpty)
    }
    
    // MARK: - LogHabitFromNotification Tests
    
    func testLogHabitFromNotification_BinaryHabit_CreatesLog() async {
        // Arrange
        let habitId = UUID()
        let habit = Habit(id: habitId, name: "Test Habit", kind: .binary, isActive: true)
        mockHabitRepository.habits = [habit]
        
        let getLogForDate = GetLogForDate(repo: mockLogRepository)
        let logHabit = LogHabit(
            repo: mockLogRepository,
            habitRepo: mockHabitRepository,
            validateSchedule: ValidateHabitSchedule()
        )
        
        let useCase = LogHabitFromNotification(
            habitRepository: mockHabitRepository,
            logRepository: mockLogRepository,
            getLogForDate: getLogForDate,
            logHabit: logHabit
        )
        
        // Act
        do {
            try await useCase.execute(habitId: habitId, date: Date(), value: nil)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert
        XCTAssertEqual(mockLogRepository.logs.count, 1)
        XCTAssertEqual(mockLogRepository.logs.first?.habitID, habitId)
        XCTAssertEqual(mockLogRepository.logs.first?.value, 1.0)
    }
    
    func testLogHabitFromNotification_NumericHabit_IncrementsValue() async {
        // Arrange
        let habitId = UUID()
        let habit = Habit(id: habitId, name: "Test Habit", kind: .numeric, isActive: true)
        mockHabitRepository.habits = [habit]
        
        // Add existing log
        let existingLog = HabitLog(habitID: habitId, date: Date(), value: 2.0)
        mockLogRepository.logs = [existingLog]
        
        let getLogForDate = GetLogForDate(repo: mockLogRepository)
        let logHabit = LogHabit(
            repo: mockLogRepository,
            habitRepo: mockHabitRepository,
            validateSchedule: ValidateHabitSchedule()
        )
        
        let useCase = LogHabitFromNotification(
            habitRepository: mockHabitRepository,
            logRepository: mockLogRepository,
            getLogForDate: getLogForDate,
            logHabit: logHabit
        )
        
        // Act
        do {
            try await useCase.execute(habitId: habitId, date: Date(), value: nil)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert
        XCTAssertEqual(mockLogRepository.logs.count, 1)
        XCTAssertEqual(mockLogRepository.logs.first?.value, 3.0)
    }
    
    // MARK: - SnoozeHabitReminder Tests
    
    func testSnoozeHabitReminder_SendsImmediateNotification() async {
        // Arrange
        let habitId = UUID()
        let habitName = "Test Habit"
        let reminderTime = ReminderTime(hour: 9, minute: 0)
        
        let useCase = SnoozeHabitReminder(notificationService: mockNotificationService)
        
        // Act
        do {
            try await useCase.execute(habitId: habitId, habitName: habitName, originalTime: reminderTime)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert
        XCTAssertEqual(mockNotificationService.immediateNotifications.count, 1)
        XCTAssertEqual(mockNotificationService.immediateNotifications.first?.0, "Reminder: Test Habit")
        XCTAssertTrue(mockNotificationService.immediateNotifications.first?.1.contains("Test Habit") ?? false)
    }
    
    // MARK: - HandleNotificationAction Tests
    
    func testHandleNotificationAction_LogAction_LogsHabit() async {
        // Arrange
        let habitId = UUID()
        let habit = Habit(id: habitId, name: "Test Habit", kind: .binary, isActive: true)
        mockHabitRepository.habits = [habit]
        
        let getLogForDate = GetLogForDate(repo: mockLogRepository)
        let logHabit = LogHabit(
            repo: mockLogRepository,
            habitRepo: mockHabitRepository,
            validateSchedule: ValidateHabitSchedule()
        )
        
        let logHabitFromNotification = LogHabitFromNotification(
            habitRepository: mockHabitRepository,
            logRepository: mockLogRepository,
            getLogForDate: getLogForDate,
            logHabit: logHabit
        )
        
        let snoozeHabitReminder = SnoozeHabitReminder(notificationService: mockNotificationService)
        
        let useCase = HandleNotificationAction(
            logHabitFromNotification: logHabitFromNotification,
            snoozeHabitReminder: snoozeHabitReminder,
            notificationService: mockNotificationService,
            habitCompletionCheckService: mockHabitCompletionCheckService,
            cancelHabitReminders: MockCancelHabitRemindersUseCase()
        )
        
        // Act
        do {
            try await useCase.execute(
                action: NotificationAction.log,
                habitId: habitId,
                habitName: "Test Habit",
                habitKind: HabitKind.binary,
                reminderTime: ReminderTime(hour: 9, minute: 0)
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert
        XCTAssertEqual(mockLogRepository.logs.count, 1)
        XCTAssertEqual(mockLogRepository.logs.first?.habitID, habitId)
    }
    
    func testHandleNotificationAction_RemindLaterAction_SendsSnoozeNotification() async {
        // Arrange
        let habitId = UUID()
        let habitName = "Test Habit"
        let reminderTime = ReminderTime(hour: 9, minute: 0)
        
        let logHabitFromNotification = LogHabitFromNotification(
            habitRepository: mockHabitRepository,
            logRepository: mockLogRepository,
            getLogForDate: GetLogForDate(repo: mockLogRepository),
            logHabit: LogHabit(
                repo: mockLogRepository,
                habitRepo: mockHabitRepository,
                validateSchedule: ValidateHabitSchedule()
            )
        )
        
        let snoozeHabitReminder = SnoozeHabitReminder(notificationService: mockNotificationService)
        
        let useCase = HandleNotificationAction(
            logHabitFromNotification: logHabitFromNotification,
            snoozeHabitReminder: snoozeHabitReminder,
            notificationService: mockNotificationService,
            habitCompletionCheckService: mockHabitCompletionCheckService,
            cancelHabitReminders: MockCancelHabitRemindersUseCase()
        )
        
        // Act
        do {
            try await useCase.execute(
                action: NotificationAction.remindLater,
                habitId: habitId,
                habitName: habitName,
                habitKind: HabitKind.binary,
                reminderTime: reminderTime
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert
        XCTAssertEqual(mockNotificationService.immediateNotifications.count, 1)
        XCTAssertEqual(mockNotificationService.immediateNotifications.first?.0, "Reminder: Test Habit")
    }
    
    func testHandleNotificationAction_DismissAction_DoesNothing() async {
        // Arrange
        let useCase = HandleNotificationAction(
            logHabitFromNotification: LogHabitFromNotification(
                habitRepository: mockHabitRepository,
                logRepository: mockLogRepository,
                getLogForDate: GetLogForDate(repo: mockLogRepository),
                logHabit: LogHabit(
                    repo: mockLogRepository,
                    habitRepo: mockHabitRepository,
                    validateSchedule: ValidateHabitSchedule()
                )
            ),
            snoozeHabitReminder: SnoozeHabitReminder(notificationService: mockNotificationService),
            notificationService: mockNotificationService,
            habitCompletionCheckService: mockHabitCompletionCheckService,
            cancelHabitReminders: MockCancelHabitRemindersUseCase()
        )
        
        // Act
        do {
            try await useCase.execute(
                action: NotificationAction.dismiss,
                habitId: UUID(),
                habitName: "Test Habit",
                habitKind: HabitKind.binary,
                reminderTime: ReminderTime(hour: 9, minute: 0)
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert
        XCTAssertTrue(mockLogRepository.logs.isEmpty)
        XCTAssertTrue(mockNotificationService.immediateNotifications.isEmpty)
    }
    
    // MARK: - Edge Cases and Error Scenarios
    
    func testLogHabitFromNotification_HabitNotFound_ThrowsError() async {
        // Arrange
        let habitId = UUID()
        mockHabitRepository.habits = [] // No habits
        
        let useCase = LogHabitFromNotification(
            habitRepository: mockHabitRepository,
            logRepository: mockLogRepository,
            getLogForDate: GetLogForDate(repo: mockLogRepository),
            logHabit: LogHabit(
                repo: mockLogRepository,
                habitRepo: mockHabitRepository,
                validateSchedule: ValidateHabitSchedule()
            )
        )
        
        // Act & Assert
        do {
            try await useCase.execute(habitId: habitId, date: Date(), value: nil)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Habit not found"))
        }
        
        XCTAssertTrue(mockLogRepository.logs.isEmpty)
    }
    
    func testLogHabitFromNotification_BinaryHabitAlreadyLoggedToday_DoesNotDuplicateLog() async {
        // Arrange
        let habitId = UUID()
        let habit = Habit(id: habitId, name: "Test Habit", kind: .binary, isActive: true)
        mockHabitRepository.habits = [habit]
        
        // Add existing log for today
        let today = Date()
        let existingLog = HabitLog(habitID: habitId, date: today, value: 1.0)
        mockLogRepository.logs = [existingLog]
        
        let getLogForDate = GetLogForDate(repo: mockLogRepository)
        let logHabit = LogHabit(
            repo: mockLogRepository,
            habitRepo: mockHabitRepository,
            validateSchedule: ValidateHabitSchedule()
        )
        
        let useCase = LogHabitFromNotification(
            habitRepository: mockHabitRepository,
            logRepository: mockLogRepository,
            getLogForDate: getLogForDate,
            logHabit: logHabit
        )
        
        // Act
        do {
            try await useCase.execute(habitId: habitId, date: today, value: nil)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert - should still have only 1 log (no duplicate)
        XCTAssertEqual(mockLogRepository.logs.count, 1)
        XCTAssertEqual(mockLogRepository.logs.first?.value, 1.0)
    }
    
    func testHandleNotificationAction_LogActionWithMissingHabitName_StillSucceeds() async {
        // Arrange
        let habitId = UUID()
        let habit = Habit(id: habitId, name: "Test Habit", kind: .binary, isActive: true)
        mockHabitRepository.habits = [habit]
        
        let logHabitFromNotification = LogHabitFromNotification(
            habitRepository: mockHabitRepository,
            logRepository: mockLogRepository,
            getLogForDate: GetLogForDate(repo: mockLogRepository),
            logHabit: LogHabit(
                repo: mockLogRepository,
                habitRepo: mockHabitRepository,
                validateSchedule: ValidateHabitSchedule()
            )
        )
        
        let snoozeHabitReminder = SnoozeHabitReminder(notificationService: mockNotificationService)
        
        let useCase = HandleNotificationAction(
            logHabitFromNotification: logHabitFromNotification,
            snoozeHabitReminder: snoozeHabitReminder,
            notificationService: mockNotificationService,
            habitCompletionCheckService: mockHabitCompletionCheckService,
            cancelHabitReminders: MockCancelHabitRemindersUseCase()
        )
        
        // Act - passing nil habitName
        do {
            try await useCase.execute(
                action: NotificationAction.log,
                habitId: habitId,
                habitName: nil,
                habitKind: HabitKind.binary,
                reminderTime: ReminderTime(hour: 9, minute: 0)
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert
        XCTAssertEqual(mockLogRepository.logs.count, 1)
        XCTAssertEqual(mockLogRepository.logs.first?.habitID, habitId)
    }
    
    func testHandleNotificationAction_RemindLaterActionWithMissingData_ThrowsError() async {
        // Arrange
        let useCase = HandleNotificationAction(
            logHabitFromNotification: LogHabitFromNotification(
                habitRepository: mockHabitRepository,
                logRepository: mockLogRepository,
                getLogForDate: GetLogForDate(repo: mockLogRepository),
                logHabit: LogHabit(
                    repo: mockLogRepository,
                    habitRepo: mockHabitRepository,
                    validateSchedule: ValidateHabitSchedule()
                )
            ),
            snoozeHabitReminder: SnoozeHabitReminder(notificationService: mockNotificationService),
            notificationService: mockNotificationService,
            habitCompletionCheckService: mockHabitCompletionCheckService,
            cancelHabitReminders: MockCancelHabitRemindersUseCase()
        )
        
        // Act & Assert - missing habitName
        do {
            try await useCase.execute(
                action: NotificationAction.remindLater,
                habitId: UUID(),
                habitName: nil as String?, // Missing
                habitKind: HabitKind.binary,
                reminderTime: ReminderTime(hour: 9, minute: 0)
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Missing habit name"))
        }
        
        // Act & Assert - missing reminderTime
        do {
            try await useCase.execute(
                action: NotificationAction.remindLater,
                habitId: UUID(),
                habitName: "Test Habit",
                habitKind: HabitKind.binary,
                reminderTime: nil as ReminderTime? // Missing
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Missing habit name or reminder time"))
        }
        
        XCTAssertTrue(mockNotificationService.immediateNotifications.isEmpty)
    }
    
    func testScheduleHabitReminders_CancelsExistingBeforeSchedulingNew() async {
        // Arrange
        let habit = Habit(
            id: UUID(),
            name: "Test Habit",
            reminders: [ReminderTime(hour: 9, minute: 0)],
            isActive: true
        )
        
        let useCase = ScheduleHabitReminders(
            habitRepository: mockHabitRepository,
            notificationService: mockNotificationService,
            habitCompletionCheckService: mockHabitCompletionCheckService
        )
        
        // Act
        do {
            try await useCase.execute(habit: habit)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert
        XCTAssertEqual(mockNotificationService.cancelledHabits.count, 1)
        XCTAssertEqual(mockNotificationService.cancelledHabits.first, habit.id)
        XCTAssertEqual(mockNotificationService.scheduledWithActionsHabits.count, 1)
        
        // Act - schedule again (should cancel existing first)
        do {
            try await useCase.execute(habit: habit)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert - should have cancelled twice
        XCTAssertEqual(mockNotificationService.cancelledHabits.count, 2)
        XCTAssertEqual(mockNotificationService.scheduledWithActionsHabits.count, 2)
    }
    
    func testMultipleRemindersForSameHabit() async {
        // Arrange
        let habit = Habit(
            id: UUID(),
            name: "Multi Reminder Habit",
            reminders: [
                ReminderTime(hour: 8, minute: 0),
                ReminderTime(hour: 12, minute: 30),
                ReminderTime(hour: 18, minute: 0)
            ],
            isActive: true
        )
        
        let useCase = ScheduleHabitReminders(
            habitRepository: mockHabitRepository,
            notificationService: mockNotificationService,
            habitCompletionCheckService: mockHabitCompletionCheckService
        )
        
        // Act
        do {
            try await useCase.execute(habit: habit)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert
        XCTAssertEqual(mockNotificationService.scheduledWithActionsHabits.count, 1)
        let scheduledHabit = mockNotificationService.scheduledWithActionsHabits.first
        XCTAssertEqual(scheduledHabit?.0, habit.id)
        XCTAssertEqual(scheduledHabit?.1, habit.name)
        XCTAssertEqual(scheduledHabit?.2.count, 3)
    }
    
    // MARK: - Notification Suppression Tests
    
    func testHandleNotificationAction_LogAction_CompletedHabit_SkipsAction() async {
        // Arrange
        let habitId = UUID()
        let habit = Habit(id: habitId, name: "Test Habit", kind: .binary, isActive: true)
        mockHabitRepository.habits = [habit]
        
        // Mock completion check service to return false (don't show notification = already completed)
        mockHabitCompletionCheckService.shouldShowResponses[habitId] = false
        
        let logHabitFromNotification = LogHabitFromNotification(
            habitRepository: mockHabitRepository,
            logRepository: mockLogRepository,
            getLogForDate: GetLogForDate(repo: mockLogRepository),
            logHabit: LogHabit(
                repo: mockLogRepository,
                habitRepo: mockHabitRepository,
                validateSchedule: ValidateHabitSchedule()
            )
        )
        
        let snoozeHabitReminder = SnoozeHabitReminder(notificationService: mockNotificationService)
        
        let useCase = HandleNotificationAction(
            logHabitFromNotification: logHabitFromNotification,
            snoozeHabitReminder: snoozeHabitReminder,
            notificationService: mockNotificationService,
            habitCompletionCheckService: mockHabitCompletionCheckService,
            cancelHabitReminders: MockCancelHabitRemindersUseCase()
        )
        
        // Act
        do {
            try await useCase.execute(
                action: NotificationAction.log,
                habitId: habitId,
                habitName: "Test Habit",
                habitKind: HabitKind.binary,
                reminderTime: ReminderTime(hour: 9, minute: 0)
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert - No logs should be created since habit is already completed
        XCTAssertTrue(mockLogRepository.logs.isEmpty, "No logs should be created for already completed habit")
        XCTAssertTrue(mockNotificationService.immediateNotifications.isEmpty, "No confirmation notifications should be sent")
    }
    
    func testHandleNotificationAction_LogAction_IncompleteHabit_ProceedsWithAction() async {
        // Arrange
        let habitId = UUID()
        let habit = Habit(id: habitId, name: "Test Habit", kind: .binary, isActive: true)
        mockHabitRepository.habits = [habit]
        
        // Mock completion check service to return true (show notification = not completed)
        mockHabitCompletionCheckService.shouldShowResponses[habitId] = true
        
        let logHabitFromNotification = LogHabitFromNotification(
            habitRepository: mockHabitRepository,
            logRepository: mockLogRepository,
            getLogForDate: GetLogForDate(repo: mockLogRepository),
            logHabit: LogHabit(
                repo: mockLogRepository,
                habitRepo: mockHabitRepository,
                validateSchedule: ValidateHabitSchedule()
            )
        )
        
        let snoozeHabitReminder = SnoozeHabitReminder(notificationService: mockNotificationService)
        
        let useCase = HandleNotificationAction(
            logHabitFromNotification: logHabitFromNotification,
            snoozeHabitReminder: snoozeHabitReminder,
            notificationService: mockNotificationService,
            habitCompletionCheckService: mockHabitCompletionCheckService,
            cancelHabitReminders: MockCancelHabitRemindersUseCase()
        )
        
        // Act
        do {
            try await useCase.execute(
                action: NotificationAction.log,
                habitId: habitId,
                habitName: "Test Habit",
                habitKind: HabitKind.binary,
                reminderTime: ReminderTime(hour: 9, minute: 0)
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert - Log should be created since habit is not completed
        XCTAssertEqual(mockLogRepository.logs.count, 1, "Log should be created for incomplete habit")
        XCTAssertEqual(mockLogRepository.logs.first?.habitID, habitId)
        XCTAssertEqual(mockLogRepository.logs.first?.value, 1.0)
        
        // Binary habit should get confirmation notification
        XCTAssertEqual(mockNotificationService.immediateNotifications.count, 1)
        XCTAssertTrue(mockNotificationService.immediateNotifications.first?.0.contains("✅ Test Habit completed!") ?? false)
    }
    
    func testHandleNotificationAction_LogAction_NumericHabit_CompletedHabit_SkipsAction() async {
        // Arrange
        let habitId = UUID()
        let habit = Habit(id: habitId, name: "Workout Reps", kind: .numeric, isActive: true)
        mockHabitRepository.habits = [habit]
        
        // Add existing log showing habit has some progress already
        let existingLog = HabitLog(habitID: habitId, date: Date(), value: 5.0)
        mockLogRepository.logs = [existingLog]
        
        // Mock completion check service to return false (don't show notification = already completed)
        mockHabitCompletionCheckService.shouldShowResponses[habitId] = false
        
        let logHabitFromNotification = LogHabitFromNotification(
            habitRepository: mockHabitRepository,
            logRepository: mockLogRepository,
            getLogForDate: GetLogForDate(repo: mockLogRepository),
            logHabit: LogHabit(
                repo: mockLogRepository,
                habitRepo: mockHabitRepository,
                validateSchedule: ValidateHabitSchedule()
            )
        )
        
        let snoozeHabitReminder = SnoozeHabitReminder(notificationService: mockNotificationService)
        
        let useCase = HandleNotificationAction(
            logHabitFromNotification: logHabitFromNotification,
            snoozeHabitReminder: snoozeHabitReminder,
            notificationService: mockNotificationService,
            habitCompletionCheckService: mockHabitCompletionCheckService,
            cancelHabitReminders: MockCancelHabitRemindersUseCase()
        )
        
        // Act
        do {
            try await useCase.execute(
                action: NotificationAction.log,
                habitId: habitId,
                habitName: "Workout Reps",
                habitKind: HabitKind.numeric,
                reminderTime: ReminderTime(hour: 9, minute: 0)
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert - No additional logs should be created since habit is already completed
        XCTAssertEqual(mockLogRepository.logs.count, 1, "Should still have only the original log")
        XCTAssertEqual(mockLogRepository.logs.first?.value, 5.0, "Log value should remain unchanged")
        XCTAssertTrue(mockNotificationService.immediateNotifications.isEmpty, "No confirmation notifications for numeric habits")
    }
    
    func testHandleNotificationAction_LogAction_NumericHabit_IncompleteHabit_ProceedsWithAction() async {
        // Arrange
        let habitId = UUID()
        let habit = Habit(id: habitId, name: "Workout Reps", kind: .numeric, isActive: true)
        mockHabitRepository.habits = [habit]
        
        // Add existing log showing partial progress
        let existingLog = HabitLog(habitID: habitId, date: Date(), value: 2.0)
        mockLogRepository.logs = [existingLog]
        
        // Mock completion check service to return true (show notification = not completed)
        mockHabitCompletionCheckService.shouldShowResponses[habitId] = true
        
        let logHabitFromNotification = LogHabitFromNotification(
            habitRepository: mockHabitRepository,
            logRepository: mockLogRepository,
            getLogForDate: GetLogForDate(repo: mockLogRepository),
            logHabit: LogHabit(
                repo: mockLogRepository,
                habitRepo: mockHabitRepository,
                validateSchedule: ValidateHabitSchedule()
            )
        )
        
        let snoozeHabitReminder = SnoozeHabitReminder(notificationService: mockNotificationService)
        
        let useCase = HandleNotificationAction(
            logHabitFromNotification: logHabitFromNotification,
            snoozeHabitReminder: snoozeHabitReminder,
            notificationService: mockNotificationService,
            habitCompletionCheckService: mockHabitCompletionCheckService,
            cancelHabitReminders: MockCancelHabitRemindersUseCase()
        )
        
        // Act
        do {
            try await useCase.execute(
                action: NotificationAction.log,
                habitId: habitId,
                habitName: "Workout Reps",
                habitKind: HabitKind.numeric,
                reminderTime: ReminderTime(hour: 9, minute: 0)
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert - Log should be incremented since habit is not completed
        XCTAssertEqual(mockLogRepository.logs.count, 1, "Should still have one log entry")
        XCTAssertEqual(mockLogRepository.logs.first?.value, 3.0, "Log value should be incremented from 2.0 to 3.0")
        XCTAssertTrue(mockNotificationService.immediateNotifications.isEmpty, "Numeric habits don't get confirmation notifications")
    }
    
    func testHandleNotificationAction_NonLogActions_AlwaysProceed() async {
        // Arrange
        let habitId = UUID()
        let habitName = "Test Habit"
        
        // Mock completion check service to return false (habit is completed)
        mockHabitCompletionCheckService.shouldShowResponses[habitId] = false
        
        let logHabitFromNotification = LogHabitFromNotification(
            habitRepository: mockHabitRepository,
            logRepository: mockLogRepository,
            getLogForDate: GetLogForDate(repo: mockLogRepository),
            logHabit: LogHabit(
                repo: mockLogRepository,
                habitRepo: mockHabitRepository,
                validateSchedule: ValidateHabitSchedule()
            )
        )
        
        let snoozeHabitReminder = SnoozeHabitReminder(notificationService: mockNotificationService)
        
        let useCase = HandleNotificationAction(
            logHabitFromNotification: logHabitFromNotification,
            snoozeHabitReminder: snoozeHabitReminder,
            notificationService: mockNotificationService,
            habitCompletionCheckService: mockHabitCompletionCheckService,
            cancelHabitReminders: MockCancelHabitRemindersUseCase()
        )
        
        // Act & Assert - Test remindLater action (should always proceed)
        do {
            try await useCase.execute(
                action: NotificationAction.remindLater,
                habitId: habitId,
                habitName: habitName,
                habitKind: HabitKind.binary,
                reminderTime: ReminderTime(hour: 9, minute: 0)
            )
        } catch {
            XCTFail("Unexpected error for remindLater: \(error)")
        }
        
        // Assert - Snooze notification should be sent regardless of completion status
        XCTAssertEqual(mockNotificationService.immediateNotifications.count, 1)
        XCTAssertEqual(mockNotificationService.immediateNotifications.first?.0, "Reminder: Test Habit")
        
        // Reset for next test
        mockNotificationService.reset()
        
        // Act & Assert - Test dismiss action (should always proceed)
        do {
            try await useCase.execute(
                action: NotificationAction.dismiss,
                habitId: habitId,
                habitName: habitName,
                habitKind: HabitKind.binary,
                reminderTime: ReminderTime(hour: 9, minute: 0)
            )
        } catch {
            XCTFail("Unexpected error for dismiss: \(error)")
        }
        
        // Assert - Dismiss action should do nothing (no error)
        XCTAssertTrue(mockNotificationService.immediateNotifications.isEmpty)
        XCTAssertTrue(mockLogRepository.logs.isEmpty)
    }
    
    func testHabitCompletionCheckService_Integration() async {
        // Arrange
        let habitId = UUID()
        let habitName = "Integration Test Habit"
        
        // Mock completion check service to simulate different completion states
        mockHabitCompletionCheckService.shouldShowResponses[habitId] = false // Start as completed
        
        let logHabitFromNotification = LogHabitFromNotification(
            habitRepository: mockHabitRepository,
            logRepository: mockLogRepository,
            getLogForDate: GetLogForDate(repo: mockLogRepository),
            logHabit: LogHabit(
                repo: mockLogRepository,
                habitRepo: mockHabitRepository,
                validateSchedule: ValidateHabitSchedule()
            )
        )
        
        let snoozeHabitReminder = SnoozeHabitReminder(notificationService: mockNotificationService)
        
        let useCase = HandleNotificationAction(
            logHabitFromNotification: logHabitFromNotification,
            snoozeHabitReminder: snoozeHabitReminder,
            notificationService: mockNotificationService,
            habitCompletionCheckService: mockHabitCompletionCheckService,
            cancelHabitReminders: MockCancelHabitRemindersUseCase()
        )
        
        // Act 1 - Try to log when habit is completed
        do {
            try await useCase.execute(
                action: NotificationAction.log,
                habitId: habitId,
                habitName: habitName,
                habitKind: HabitKind.binary,
                reminderTime: ReminderTime(hour: 9, minute: 0)
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert 1 - Service should have been called and action should be skipped
        XCTAssertEqual(mockHabitCompletionCheckService.callLog.count, 1)
        XCTAssertEqual(mockHabitCompletionCheckService.callLog.first?.habitId, habitId)
        XCTAssertTrue(mockLogRepository.logs.isEmpty, "No logs should be created when habit is completed")
        
        // Arrange 2 - Change completion state to incomplete
        mockHabitCompletionCheckService.shouldShowResponses[habitId] = true
        let habit = Habit(id: habitId, name: habitName, kind: .binary, isActive: true)
        mockHabitRepository.habits = [habit]
        
        // Act 2 - Try to log when habit is not completed
        do {
            try await useCase.execute(
                action: NotificationAction.log,
                habitId: habitId,
                habitName: habitName,
                habitKind: HabitKind.binary,
                reminderTime: ReminderTime(hour: 9, minute: 0)
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert 2 - Service should be called again and action should proceed
        XCTAssertEqual(mockHabitCompletionCheckService.callLog.count, 2)
        XCTAssertEqual(mockLogRepository.logs.count, 1, "Log should be created when habit is not completed")
        XCTAssertEqual(mockLogRepository.logs.first?.habitID, habitId)
    }
    
    func testHabitCompletionCheckService_UsesCurrentDate() async {
        // Arrange
        let habitId = UUID()
        let today = Date()
        
        // Add the habit to the mock repository so LogHabitFromNotification can find it
        let testHabit = Habit(id: habitId, name: "Date Test Habit", emoji: "🧪", kind: .binary, schedule: .daily, reminders: [])
        mockHabitRepository.habits = [testHabit]
        
        // Mock the service to track date calls
        mockHabitCompletionCheckService.shouldShowResponses[habitId] = true
        
        let logHabitFromNotification = LogHabitFromNotification(
            habitRepository: mockHabitRepository,
            logRepository: mockLogRepository,
            getLogForDate: GetLogForDate(repo: mockLogRepository),
            logHabit: LogHabit(
                repo: mockLogRepository,
                habitRepo: mockHabitRepository,
                validateSchedule: ValidateHabitSchedule()
            )
        )
        
        let snoozeHabitReminder = SnoozeHabitReminder(notificationService: mockNotificationService)
        
        let useCase = HandleNotificationAction(
            logHabitFromNotification: logHabitFromNotification,
            snoozeHabitReminder: snoozeHabitReminder,
            notificationService: mockNotificationService,
            habitCompletionCheckService: mockHabitCompletionCheckService,
            cancelHabitReminders: MockCancelHabitRemindersUseCase()
        )
        
        // Act
        do {
            try await useCase.execute(
                action: NotificationAction.log,
                habitId: habitId,
                habitName: "Date Test Habit",
                habitKind: HabitKind.binary,
                reminderTime: ReminderTime(hour: 9, minute: 0)
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert - Service should be called with today's date (within reasonable time window)
        XCTAssertEqual(mockHabitCompletionCheckService.callLog.count, 1)
        let calledDate = mockHabitCompletionCheckService.callLog.first?.date
        XCTAssertNotNil(calledDate)
        
        // Verify the date is close to current time (within 5 seconds to account for execution time)
        let timeDifference = abs(calledDate!.timeIntervalSince(today))
        XCTAssertLessThan(timeDifference, 5.0, "Should use current date")
    }
    
    func testHabitCompletionCheckService_FailSafeOnError() async {
        // Arrange
        let habitId = UUID()
        
        // Don't set any response in mock service - this will cause default behavior (return true)
        // This simulates the service failing and falling back to showing notification
        
        let habit = Habit(id: habitId, name: "Fail Safe Test", kind: .binary, isActive: true)
        mockHabitRepository.habits = [habit]
        
        let logHabitFromNotification = LogHabitFromNotification(
            habitRepository: mockHabitRepository,
            logRepository: mockLogRepository,
            getLogForDate: GetLogForDate(repo: mockLogRepository),
            logHabit: LogHabit(
                repo: mockLogRepository,
                habitRepo: mockHabitRepository,
                validateSchedule: ValidateHabitSchedule()
            )
        )
        
        let snoozeHabitReminder = SnoozeHabitReminder(notificationService: mockNotificationService)
        
        let useCase = HandleNotificationAction(
            logHabitFromNotification: logHabitFromNotification,
            snoozeHabitReminder: snoozeHabitReminder,
            notificationService: mockNotificationService,
            habitCompletionCheckService: mockHabitCompletionCheckService,
            cancelHabitReminders: MockCancelHabitRemindersUseCase()
        )
        
        // Act
        do {
            try await useCase.execute(
                action: NotificationAction.log,
                habitId: habitId,
                habitName: "Fail Safe Test",
                habitKind: HabitKind.binary,
                reminderTime: ReminderTime(hour: 9, minute: 0)
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert - Should proceed with action when service returns default (true)
        XCTAssertEqual(mockHabitCompletionCheckService.callLog.count, 1)
        XCTAssertEqual(mockLogRepository.logs.count, 1, "Should create log when service fails/returns true")
        XCTAssertEqual(mockLogRepository.logs.first?.habitID, habitId)
    }
    
    func testHabitCompletionCheckService_CalledOnlyForLogActions() async {
        // Arrange
        let habitId = UUID()
        let habitName = "Service Call Test"
        
        let logHabitFromNotification = LogHabitFromNotification(
            habitRepository: mockHabitRepository,
            logRepository: mockLogRepository,
            getLogForDate: GetLogForDate(repo: mockLogRepository),
            logHabit: LogHabit(
                repo: mockLogRepository,
                habitRepo: mockHabitRepository,
                validateSchedule: ValidateHabitSchedule()
            )
        )
        
        let snoozeHabitReminder = SnoozeHabitReminder(notificationService: mockNotificationService)
        
        let useCase = HandleNotificationAction(
            logHabitFromNotification: logHabitFromNotification,
            snoozeHabitReminder: snoozeHabitReminder,
            notificationService: mockNotificationService,
            habitCompletionCheckService: mockHabitCompletionCheckService,
            cancelHabitReminders: MockCancelHabitRemindersUseCase()
        )
        
        // Act 1 - Test dismiss action (should NOT call completion check)
        do {
            try await useCase.execute(
                action: NotificationAction.dismiss,
                habitId: habitId,
                habitName: habitName,
                habitKind: HabitKind.binary,
                reminderTime: ReminderTime(hour: 9, minute: 0)
            )
        } catch {
            XCTFail("Unexpected error for dismiss: \(error)")
        }
        
        // Assert 1 - No calls to completion check service
        XCTAssertTrue(mockHabitCompletionCheckService.callLog.isEmpty, "Dismiss action should not check completion")
        
        // Act 2 - Test remindLater action (should NOT call completion check)
        do {
            try await useCase.execute(
                action: NotificationAction.remindLater,
                habitId: habitId,
                habitName: habitName,
                habitKind: HabitKind.binary,
                reminderTime: ReminderTime(hour: 9, minute: 0)
            )
        } catch {
            XCTFail("Unexpected error for remindLater: \(error)")
        }
        
        // Assert 2 - Still no calls to completion check service
        XCTAssertTrue(mockHabitCompletionCheckService.callLog.isEmpty, "RemindLater action should not check completion")
        
        // Act 3 - Test log action (SHOULD call completion check)
        mockHabitCompletionCheckService.shouldShowResponses[habitId] = true
        let habit = Habit(id: habitId, name: habitName, kind: .binary, isActive: true)
        mockHabitRepository.habits = [habit]
        
        do {
            try await useCase.execute(
                action: NotificationAction.log,
                habitId: habitId,
                habitName: habitName,
                habitKind: HabitKind.binary,
                reminderTime: ReminderTime(hour: 9, minute: 0)
            )
        } catch {
            XCTFail("Unexpected error for log: \(error)")
        }
        
        // Assert 3 - Now should have one call to completion check service
        XCTAssertEqual(mockHabitCompletionCheckService.callLog.count, 1, "Log action should check completion")
        XCTAssertEqual(mockHabitCompletionCheckService.callLog.first?.habitId, habitId)
    }
    
    // MARK: - Edge Cases for Notification Suppression
    
    func testHandleNotificationAction_LogAction_CompletedHabit_BinaryVsNumeric() async {
        // Test that both binary and numeric habits are handled consistently when completed
        
        // Arrange - Binary habit
        let binaryHabitId = UUID()
        let binaryHabit = Habit(id: binaryHabitId, name: "Binary Habit", kind: .binary, isActive: true)
        mockHabitRepository.habits = [binaryHabit]
        
        // Mock as completed
        mockHabitCompletionCheckService.shouldShowResponses[binaryHabitId] = false
        
        let logHabitFromNotification = LogHabitFromNotification(
            habitRepository: mockHabitRepository,
            logRepository: mockLogRepository,
            getLogForDate: GetLogForDate(repo: mockLogRepository),
            logHabit: LogHabit(
                repo: mockLogRepository,
                habitRepo: mockHabitRepository,
                validateSchedule: ValidateHabitSchedule()
            )
        )
        
        let snoozeHabitReminder = SnoozeHabitReminder(notificationService: mockNotificationService)
        
        let useCase = HandleNotificationAction(
            logHabitFromNotification: logHabitFromNotification,
            snoozeHabitReminder: snoozeHabitReminder,
            notificationService: mockNotificationService,
            habitCompletionCheckService: mockHabitCompletionCheckService,
            cancelHabitReminders: MockCancelHabitRemindersUseCase()
        )
        
        // Act & Assert - Binary habit
        do {
            try await useCase.execute(
                action: NotificationAction.log,
                habitId: binaryHabitId,
                habitName: "Binary Habit",
                habitKind: HabitKind.binary,
                reminderTime: ReminderTime(hour: 9, minute: 0)
            )
        } catch {
            XCTFail("Unexpected error for binary habit: \(error)")
        }
        
        let binaryCallCount = mockHabitCompletionCheckService.callLog.count
        let binaryLogCount = mockLogRepository.logs.count
        
        // Arrange - Numeric habit
        let numericHabitId = UUID()
        let numericHabit = Habit(id: numericHabitId, name: "Numeric Habit", kind: .numeric, isActive: true)
        mockHabitRepository.habits = [numericHabit]
        
        // Mock as completed
        mockHabitCompletionCheckService.shouldShowResponses[numericHabitId] = false
        
        // Act & Assert - Numeric habit
        do {
            try await useCase.execute(
                action: NotificationAction.log,
                habitId: numericHabitId,
                habitName: "Numeric Habit",
                habitKind: HabitKind.numeric,
                reminderTime: ReminderTime(hour: 9, minute: 0)
            )
        } catch {
            XCTFail("Unexpected error for numeric habit: \(error)")
        }
        
        // Assert - Both habit types should behave identically
        XCTAssertEqual(mockHabitCompletionCheckService.callLog.count, binaryCallCount + 1, "Both habit types should check completion")
        XCTAssertEqual(mockLogRepository.logs.count, binaryLogCount, "Neither habit type should create logs when completed")
        
        // Verify both habits were checked
        let habitIds = Set(mockHabitCompletionCheckService.callLog.map { $0.habitId })
        XCTAssertTrue(habitIds.contains(binaryHabitId), "Binary habit should be checked")
        XCTAssertTrue(habitIds.contains(numericHabitId), "Numeric habit should be checked")
    }
    
    func testHandleNotificationAction_LogAction_CalendarBoundaryConditions() async {
        // Test that completion checking works correctly across different calendar contexts
        
        let habitId = UUID()
        let habit = Habit(id: habitId, name: "Calendar Test", kind: .binary, isActive: true)
        mockHabitRepository.habits = [habit]
        
        // Mock as incomplete
        mockHabitCompletionCheckService.shouldShowResponses[habitId] = true
        
        let logHabitFromNotification = LogHabitFromNotification(
            habitRepository: mockHabitRepository,
            logRepository: mockLogRepository,
            getLogForDate: GetLogForDate(repo: mockLogRepository),
            logHabit: LogHabit(
                repo: mockLogRepository,
                habitRepo: mockHabitRepository,
                validateSchedule: ValidateHabitSchedule()
            )
        )
        
        let snoozeHabitReminder = SnoozeHabitReminder(notificationService: mockNotificationService)
        
        let useCase = HandleNotificationAction(
            logHabitFromNotification: logHabitFromNotification,
            snoozeHabitReminder: snoozeHabitReminder,
            notificationService: mockNotificationService,
            habitCompletionCheckService: mockHabitCompletionCheckService,
            cancelHabitReminders: MockCancelHabitRemindersUseCase()
        )
        
        // Act - Execute action with current date/time
        do {
            try await useCase.execute(
                action: NotificationAction.log,
                habitId: habitId,
                habitName: "Calendar Test",
                habitKind: HabitKind.binary,
                reminderTime: ReminderTime(hour: 9, minute: 0)
            )
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Assert - Service should be called with current date context
        XCTAssertEqual(mockHabitCompletionCheckService.callLog.count, 1)
        
        let calledDate = mockHabitCompletionCheckService.callLog.first?.date
        XCTAssertNotNil(calledDate, "Service should be called with a date")
        
        // Verify the date is within a reasonable range of current time
        let now = Date()
        let timeDifference = abs(calledDate!.timeIntervalSince(now))
        XCTAssertLessThan(timeDifference, 10.0, "Should use current date within reasonable time window")
        
        // Verify action proceeded since habit was incomplete
        XCTAssertEqual(mockLogRepository.logs.count, 1)
        XCTAssertEqual(mockLogRepository.logs.first?.habitID, habitId)
    }
}
