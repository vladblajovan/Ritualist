import XCTest
@testable import Ritualist

// MARK: - Mock Notification Service for Testing

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
}

// MARK: - Mock Repositories for Testing

class MockHabitRepository: HabitRepository {
    var habits: [Habit] = []
    
    func fetchAllHabits() async throws -> [Habit] {
        return habits
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
}

class MockLogRepository: LogRepository {
    var logs: [HabitLog] = []
    
    func logs(for habitID: UUID) async throws -> [HabitLog] {
        return logs.filter { $0.habitID == habitID }
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
}

// MARK: - Notification Use Cases Tests

class NotificationUseCaseTests: XCTestCase {
    
    var mockNotificationService: MockNotificationService!
    var mockHabitRepository: MockHabitRepository!
    var mockLogRepository: MockLogRepository!
    
    override func setUp() {
        super.setUp()
        mockNotificationService = MockNotificationService()
        mockHabitRepository = MockHabitRepository()
        mockLogRepository = MockLogRepository()
    }
    
    override func tearDown() {
        mockNotificationService = nil
        mockHabitRepository = nil
        mockLogRepository = nil
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
            notificationService: mockNotificationService
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
            notificationService: mockNotificationService
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
            notificationService: mockNotificationService
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
        let logHabit = LogHabit(repo: mockLogRepository)
        
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
        let logHabit = LogHabit(repo: mockLogRepository)
        
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
        let logHabit = LogHabit(repo: mockLogRepository)
        
        let logHabitFromNotification = LogHabitFromNotification(
            habitRepository: mockHabitRepository,
            logRepository: mockLogRepository,
            getLogForDate: getLogForDate,
            logHabit: logHabit
        )
        
        let snoozeHabitReminder = SnoozeHabitReminder(notificationService: mockNotificationService)
        
        let useCase = HandleNotificationAction(
            logHabitFromNotification: logHabitFromNotification,
            snoozeHabitReminder: snoozeHabitReminder
        )
        
        // Act
        do {
            try await useCase.execute(
                action: .log,
                habitId: habitId,
                habitName: "Test Habit",
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
            logHabit: LogHabit(repo: mockLogRepository)
        )
        
        let snoozeHabitReminder = SnoozeHabitReminder(notificationService: mockNotificationService)
        
        let useCase = HandleNotificationAction(
            logHabitFromNotification: logHabitFromNotification,
            snoozeHabitReminder: snoozeHabitReminder
        )
        
        // Act
        do {
            try await useCase.execute(
                action: .remindLater,
                habitId: habitId,
                habitName: habitName,
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
                logHabit: LogHabit(repo: mockLogRepository)
            ),
            snoozeHabitReminder: SnoozeHabitReminder(notificationService: mockNotificationService)
        )
        
        // Act
        do {
            try await useCase.execute(
                action: .dismiss,
                habitId: UUID(),
                habitName: "Test Habit",
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
            logHabit: LogHabit(repo: mockLogRepository)
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
        let logHabit = LogHabit(repo: mockLogRepository)
        
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
            logHabit: LogHabit(repo: mockLogRepository)
        )
        
        let snoozeHabitReminder = SnoozeHabitReminder(notificationService: mockNotificationService)
        
        let useCase = HandleNotificationAction(
            logHabitFromNotification: logHabitFromNotification,
            snoozeHabitReminder: snoozeHabitReminder
        )
        
        // Act - passing nil habitName
        do {
            try await useCase.execute(
                action: .log,
                habitId: habitId,
                habitName: nil,
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
                logHabit: LogHabit(repo: mockLogRepository)
            ),
            snoozeHabitReminder: SnoozeHabitReminder(notificationService: mockNotificationService)
        )
        
        // Act & Assert - missing habitName
        do {
            try await useCase.execute(
                action: .remindLater,
                habitId: UUID(),
                habitName: nil, // Missing
                reminderTime: ReminderTime(hour: 9, minute: 0)
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Missing habit name"))
        }
        
        // Act & Assert - missing reminderTime
        do {
            try await useCase.execute(
                action: .remindLater,
                habitId: UUID(),
                habitName: "Test Habit",
                reminderTime: nil // Missing
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
            notificationService: mockNotificationService
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
            notificationService: mockNotificationService
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
}