//
//  NotificationUseCaseCleanTests.swift  
//  RitualistTests
//
//  Created by Claude on 27.08.2025.
//

import Testing
import Foundation
import SwiftData
@testable import Ritualist
@testable import RitualistCore

/// Clean tests for Notification UseCases using real implementations
/// This demonstrates the CORRECT testing approach:
/// - Use real Repository implementations with TestModelContainer
/// - Set up test data in the database instead of mocks
/// - Test actual business logic flow
@Suite("Notification UseCases Clean Tests")
@MainActor  
final class NotificationUseCaseCleanTests {
    
    // MARK: - Test Infrastructure
    
    private var testContainer: ModelContainer!
    private var testContext: ModelContext!
    
    init() async throws {
        // Set up test infrastructure with real database
        let (container, context) = try TestModelContainer.createContainerAndContext()
        testContainer = container
        testContext = context
    }
    
    // MARK: - Helper Methods
    
    private func setupTestHabit() async throws -> HabitModel {
        let habit = HabitModelBuilder()
            .with(name: "Test Habit")
            .with(schedule: .daily)
            .with(isActive: true)
            .build()
        
        testContext.insert(habit)
        try testContext.save()
        return habit
    }
    
    private func setupTestLog(for habitId: UUID, on date: Date, value: Double = 1.0) async throws -> LogModel {
        let log = LogModelBuilder()
            .with(habitID: habitId)
            .with(date: date)
            .with(value: value)
            .build()
            
        testContext.insert(log)
        try testContext.save()
        return log
    }
    
    // MARK: - Test Cases
    
    @Test("LogHabitFromNotificationUseCase creates real log in database")
    func testLogHabitFromNotification() async throws {
        // Arrange: Create real test habit
        let testHabit = try await setupTestHabit()
        let logHabitUseCase = LogHabit(repo: LogRepositoryImpl(context: testContext))
        
        let logHabitFromNotificationUseCase = LogHabitFromNotification(
            logHabit: logHabitUseCase
        )
        
        // Act: Log habit from notification
        let testDate = Date()
        try await logHabitFromNotificationUseCase.execute(
            habitId: testHabit.id,
            date: testDate,
            value: 1.0
        )
        
        // Assert: Verify real log was created in database
        let descriptor = FetchDescriptor<LogModel>(
            predicate: #Predicate<LogModel> { log in
                log.habitID == testHabit.id
            }
        )
        let logs = try testContext.fetch(descriptor)
        
        #expect(logs.count == 1)
        #expect(logs.first?.habitID == testHabit.id)
        #expect(logs.first?.value == 1.0)
    }
    
    @Test("ScheduleHabitRemindersUseCase works with real habit data")
    func testScheduleHabitReminders() async throws {
        // Arrange: Create real test habit with reminder times
        let habit = HabitModelBuilder()
            .with(name: "Morning Exercise")
            .with(schedule: .daily)
            .with(reminderTimes: [
                ReminderTime(hour: 8, minute: 0),
                ReminderTime(hour: 18, minute: 30)
            ])
            .with(isActive: true)
            .build()
        
        testContext.insert(habit)
        try testContext.save()
        
        // Create a mock notification service only for testing notifications
        // (NotificationService is a system boundary, mocking is acceptable here)
        let mockNotificationService = TestNotificationService()
        
        let scheduleHabitRemindersUseCase = ScheduleHabitReminders(
            notificationService: mockNotificationService
        )
        
        // Act: Schedule reminders for real habit
        try await scheduleHabitRemindersUseCase.execute(habit: habit.toDomain())
        
        // Assert: Verify reminders were scheduled
        #expect(mockNotificationService.scheduledNotifications.count == 2)
        #expect(mockNotificationService.scheduledNotifications.contains { $0.habitId == habit.id })
    }
    
    @Test("CancelHabitRemindersUseCase works with real habit data")
    func testCancelHabitReminders() async throws {
        // Arrange: Create real test habit
        let testHabit = try await setupTestHabit()
        let mockNotificationService = TestNotificationService()
        
        let cancelHabitRemindersUseCase = CancelHabitReminders(
            notificationService: mockNotificationService
        )
        
        // Act: Cancel reminders for real habit
        await cancelHabitRemindersUseCase.execute(habitId: testHabit.id)
        
        // Assert: Verify reminders were cancelled
        #expect(mockNotificationService.cancelledHabits.contains(testHabit.id))
    }
    
    @Test("HandleNotificationActionUseCase processes real habit data")
    func testHandleNotificationAction() async throws {
        // Arrange: Create real test habit and log UseCase
        let testHabit = try await setupTestHabit()
        let logHabitUseCase = LogHabit(repo: LogRepositoryImpl(context: testContext))
        let mockNotificationService = TestNotificationService()
        
        let handleNotificationActionUseCase = HandleNotificationAction(
            logHabitFromNotification: LogHabitFromNotification(logHabit: logHabitUseCase),
            snoozeHabitReminder: SnoozeHabitReminder(notificationService: mockNotificationService)
        )
        
        // Act: Handle complete action
        let reminderTime = ReminderTime(hour: 8, minute: 0)
        try await handleNotificationActionUseCase.execute(
            action: .complete,
            habitId: testHabit.id,
            habitName: testHabit.name,
            habitKind: .binary,
            reminderTime: reminderTime
        )
        
        // Assert: Verify log was created in real database
        let descriptor = FetchDescriptor<LogModel>(
            predicate: #Predicate<LogModel> { log in
                log.habitID == testHabit.id
            }
        )
        let logs = try testContext.fetch(descriptor)
        #expect(logs.count == 1)
        #expect(logs.first?.habitID == testHabit.id)
    }
}

// MARK: - Test Notification Service

/// Simple test double for NotificationService (system boundary)
/// Unlike business logic, system boundaries can be mocked for testing
class TestNotificationService: NotificationService {
    var scheduledNotifications: [(habitId: UUID, reminderTimes: [ReminderTime])] = []
    var cancelledHabits: [UUID] = []
    var immediateNotifications: [(title: String, body: String)] = []
    
    func requestAuthorizationIfNeeded() async throws -> Bool { return true }
    func checkAuthorizationStatus() async -> Bool { return true }
    
    func scheduleHabitReminders(habitId: UUID, habitName: String, reminderTimes: [ReminderTime]) async throws {
        scheduledNotifications.append((habitId: habitId, reminderTimes: reminderTimes))
    }
    
    func scheduleHabitRemindersWithActions(habitId: UUID, habitName: String, habitKind: HabitKind, reminderTimes: [ReminderTime]) async throws {
        scheduledNotifications.append((habitId: habitId, reminderTimes: reminderTimes))
    }
    
    func cancelHabitReminders(habitId: UUID) async {
        cancelledHabits.append(habitId)
    }
    
    func sendImmediate(title: String, body: String) async throws {
        immediateNotifications.append((title: title, body: body))
    }
    
    func setupNotificationCategories() {
        // No-op for testing
    }
    
    func scheduleSnoozeReminder(habitId: UUID, habitName: String, originalTime: ReminderTime) async throws {
        // No-op for testing  
    }
}

// MARK: - Domain Conversion Extensions

extension HabitModel {
    func toDomain() -> Habit {
        return Habit(
            id: self.id,
            name: self.name,
            emoji: self.emoji,
            dailyTarget: self.dailyTarget,
            kind: HabitKind(rawValue: self.kind) ?? .binary,
            schedule: HabitSchedule.daily, // Simplified for testing
            categoryId: self.categoryId,
            position: Int(self.position),
            reminderTimes: self.reminderTimes.map { ReminderTime(hour: $0.hour, minute: $0.minute) },
            isActive: self.isActive,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
    }
}