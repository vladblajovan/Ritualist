//
//  LogUseCasesTests.swift
//  RitualistTests
//
//  Tests for log use cases: GetLogs, GetBatchLogs, GetSingleHabitLogs, DeleteLog, GetLogForDate
//  Timezone-specific tests are in LogUseCasesTimezoneTests.swift
//  Start date validation tests are in LogValidationTests.swift
//

import Testing
import Foundation
@testable import RitualistCore

// MARK: - GetLogs UseCase Tests

@Suite("GetLogs UseCase", .tags(.habits, .useCase, .businessLogic))
@MainActor
struct GetLogsUseCaseTests {

    @Test("Returns all logs for habit when no date filters specified")
    func returnsAllLogsWhenNoFilters() async throws {
        // Arrange
        let habitId = UUID()
        let logs: [UUID: [HabitLog]] = [
            habitId: [
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.daysAgo(5)),
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.daysAgo(3)),
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.today)
            ]
        ]
        let repo = MockLogRepository(logs: logs)
        let useCase = GetLogs(repo: repo)

        // Act
        let result = try await useCase.execute(for: habitId, since: nil, until: nil)

        // Assert
        #expect(result.count == 3, "Should return all logs")
    }

    @Test("Filters logs by since date")
    func filtersLogsBySinceDate() async throws {
        // Arrange
        let habitId = UUID()
        let logs: [UUID: [HabitLog]] = [
            habitId: [
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.daysAgo(10)),
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.daysAgo(5)),
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.today)
            ]
        ]
        let repo = MockLogRepository(logs: logs)
        let useCase = GetLogs(repo: repo)

        // Act - only logs from 6 days ago and later
        let result = try await useCase.execute(for: habitId, since: TestDates.daysAgo(6), until: nil)

        // Assert
        #expect(result.count == 2, "Should exclude log from 10 days ago")
    }

    @Test("Filters logs by until date")
    func filtersLogsByUntilDate() async throws {
        // Arrange
        let habitId = UUID()
        let logs: [UUID: [HabitLog]] = [
            habitId: [
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.daysAgo(10)),
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.daysAgo(5)),
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.today)
            ]
        ]
        let repo = MockLogRepository(logs: logs)
        let useCase = GetLogs(repo: repo)

        // Act - only logs up to 4 days ago
        let result = try await useCase.execute(for: habitId, since: nil, until: TestDates.daysAgo(4))

        // Assert
        #expect(result.count == 2, "Should exclude today's log")
    }

    @Test("Filters logs by both since and until dates")
    func filtersLogsByBothDates() async throws {
        // Arrange
        let habitId = UUID()
        let logs: [UUID: [HabitLog]] = [
            habitId: [
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.daysAgo(10)),
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.daysAgo(5)),
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.daysAgo(3)),
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.today)
            ]
        ]
        let repo = MockLogRepository(logs: logs)
        let useCase = GetLogs(repo: repo)

        // Act - logs between 7 and 2 days ago
        let result = try await useCase.execute(for: habitId, since: TestDates.daysAgo(7), until: TestDates.daysAgo(2))

        // Assert
        #expect(result.count == 2, "Should return logs at 5 and 3 days ago only")
    }

    @Test("Returns empty array when no logs exist for habit")
    func returnsEmptyArrayWhenNoLogs() async throws {
        // Arrange
        let habitId = UUID()
        let repo = MockLogRepository(logs: [:])
        let useCase = GetLogs(repo: repo)

        // Act
        let result = try await useCase.execute(for: habitId, since: nil, until: nil)

        // Assert
        #expect(result.isEmpty, "Should return empty array")
    }

    @Test("Includes log on since date boundary")
    func includesLogOnSinceBoundary() async throws {
        // Arrange
        let habitId = UUID()
        let boundaryDate = TestDates.daysAgo(3)
        let logs: [UUID: [HabitLog]] = [
            habitId: [
                HabitLogBuilder.binary(habitId: habitId, date: boundaryDate)
            ]
        ]
        let repo = MockLogRepository(logs: logs)
        let useCase = GetLogs(repo: repo)

        // Act
        let result = try await useCase.execute(for: habitId, since: boundaryDate, until: nil)

        // Assert
        #expect(result.count == 1, "Should include log on since boundary")
    }

    @Test("Includes log on until date boundary")
    func includesLogOnUntilBoundary() async throws {
        // Arrange
        let habitId = UUID()
        let boundaryDate = TestDates.daysAgo(3)
        let logs: [UUID: [HabitLog]] = [
            habitId: [
                HabitLogBuilder.binary(habitId: habitId, date: boundaryDate)
            ]
        ]
        let repo = MockLogRepository(logs: logs)
        let useCase = GetLogs(repo: repo)

        // Act
        let result = try await useCase.execute(for: habitId, since: nil, until: boundaryDate)

        // Assert
        #expect(result.count == 1, "Should include log on until boundary")
    }
}

// MARK: - GetBatchLogs UseCase Tests

@Suite("GetBatchLogs UseCase", .tags(.habits, .useCase, .businessLogic))
@MainActor
struct GetBatchLogsUseCaseTests {

    @Test("Returns logs grouped by habit ID")
    func returnsLogsGroupedByHabitId() async throws {
        // Arrange
        let habitId1 = UUID()
        let habitId2 = UUID()
        let logs: [UUID: [HabitLog]] = [
            habitId1: [
                HabitLogBuilder.binary(habitId: habitId1, date: TestDates.today),
                HabitLogBuilder.binary(habitId: habitId1, date: TestDates.yesterday)
            ],
            habitId2: [
                HabitLogBuilder.binary(habitId: habitId2, date: TestDates.today)
            ]
        ]
        let repo = MockLogRepository(logs: logs)
        let useCase = GetBatchLogs(repo: repo)

        // Act
        let result = try await useCase.execute(for: [habitId1, habitId2], since: nil, until: nil)

        // Assert
        #expect(result[habitId1]?.count == 2, "Habit 1 should have 2 logs")
        #expect(result[habitId2]?.count == 1, "Habit 2 should have 1 log")
    }

    @Test("Initializes empty arrays for all requested habit IDs")
    func initializesEmptyArraysForAllHabitIds() async throws {
        // Arrange
        let habitId1 = UUID()
        let habitId2 = UUID()
        let logs: [UUID: [HabitLog]] = [
            habitId1: [
                HabitLogBuilder.binary(habitId: habitId1, date: TestDates.today)
            ]
        ]
        let repo = MockLogRepository(logs: logs)
        let useCase = GetBatchLogs(repo: repo)

        // Act
        let result = try await useCase.execute(for: [habitId1, habitId2], since: nil, until: nil)

        // Assert
        #expect(result.keys.count == 2, "Should have entries for both habit IDs")
        #expect(result[habitId2]?.isEmpty == true, "Habit 2 should have empty array")
    }

    @Test("Applies date filtering to batch results")
    func appliesDateFilteringToBatchResults() async throws {
        // Arrange
        let habitId1 = UUID()
        let habitId2 = UUID()
        let logs: [UUID: [HabitLog]] = [
            habitId1: [
                HabitLogBuilder.binary(habitId: habitId1, date: TestDates.daysAgo(10)),
                HabitLogBuilder.binary(habitId: habitId1, date: TestDates.today)
            ],
            habitId2: [
                HabitLogBuilder.binary(habitId: habitId2, date: TestDates.daysAgo(10)),
                HabitLogBuilder.binary(habitId: habitId2, date: TestDates.today)
            ]
        ]
        let repo = MockLogRepository(logs: logs)
        let useCase = GetBatchLogs(repo: repo)

        // Act - only last 5 days
        let result = try await useCase.execute(for: [habitId1, habitId2], since: TestDates.daysAgo(5), until: nil)

        // Assert
        #expect(result[habitId1]?.count == 1, "Habit 1 should have 1 recent log")
        #expect(result[habitId2]?.count == 1, "Habit 2 should have 1 recent log")
    }

    @Test("Returns empty dictionary for empty habit ID list")
    func returnsEmptyDictionaryForEmptyHabitIdList() async throws {
        // Arrange
        let repo = MockLogRepository(logs: [:])
        let useCase = GetBatchLogs(repo: repo)

        // Act
        let result = try await useCase.execute(for: [], since: nil, until: nil)

        // Assert
        #expect(result.isEmpty, "Should return empty dictionary")
    }
}

// MARK: - GetSingleHabitLogs UseCase Tests

@Suite("GetSingleHabitLogs UseCase", .tags(.habits, .useCase, .businessLogic))
@MainActor
struct GetSingleHabitLogsUseCaseTests {

    @Test("Returns logs for single habit via batch mechanism")
    func returnsLogsForSingleHabit() async throws {
        // Arrange
        let habitId = UUID()
        let logs: [UUID: [HabitLog]] = [
            habitId: [
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.daysAgo(3)),
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.daysAgo(2)),
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.today)
            ]
        ]
        let repo = MockLogRepository(logs: logs)
        let getBatchLogs = GetBatchLogs(repo: repo)
        let useCase = GetSingleHabitLogs(getBatchLogs: getBatchLogs)

        // Act
        let result = try await useCase.execute(
            for: habitId,
            from: TestDates.daysAgo(5),
            to: TestDates.today
        )

        // Assert
        #expect(result.count == 3, "Should return all 3 logs")
    }

    @Test("Returns empty array when habit has no logs")
    func returnsEmptyArrayWhenNoLogs() async throws {
        // Arrange
        let habitId = UUID()
        let repo = MockLogRepository(logs: [:])
        let getBatchLogs = GetBatchLogs(repo: repo)
        let useCase = GetSingleHabitLogs(getBatchLogs: getBatchLogs)

        // Act
        let result = try await useCase.execute(
            for: habitId,
            from: TestDates.daysAgo(5),
            to: TestDates.today
        )

        // Assert
        #expect(result.isEmpty, "Should return empty array")
    }

    @Test("Filters logs within date range")
    func filtersLogsWithinDateRange() async throws {
        // Arrange
        let habitId = UUID()
        let logs: [UUID: [HabitLog]] = [
            habitId: [
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.daysAgo(10)),
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.daysAgo(3)),
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.today)
            ]
        ]
        let repo = MockLogRepository(logs: logs)
        let getBatchLogs = GetBatchLogs(repo: repo)
        let useCase = GetSingleHabitLogs(getBatchLogs: getBatchLogs)

        // Act - only 5 days ago to 1 day ago
        let result = try await useCase.execute(
            for: habitId,
            from: TestDates.daysAgo(5),
            to: TestDates.daysAgo(1)
        )

        // Assert
        #expect(result.count == 1, "Should return only the log from 3 days ago")
    }
}

// MARK: - DeleteLog UseCase Tests

@Suite("DeleteLog UseCase", .tags(.habits, .useCase, .businessLogic))
@MainActor
struct DeleteLogUseCaseTests {

    @Test("Deletes log from repository")
    func deletesLogFromRepository() async throws {
        // Arrange
        let logId = UUID()
        let habitId = UUID()
        let log = HabitLogBuilder.binary(id: logId, habitId: habitId, date: TestDates.today)
        let repo = MockLogRepository(logs: [habitId: [log]])
        let useCase = DeleteLog(repo: repo)

        // Act
        try await useCase.execute(id: logId)

        // Assert - log should be removed from repository
        let remainingLogs = try await repo.logs(for: habitId)
        #expect(remainingLogs.isEmpty, "Log should be deleted from repository")
    }

    @Test("Delete does not throw when log ID not found")
    func deleteDoesNotThrowWhenLogNotFound() async throws {
        // Arrange
        let repo = MockLogRepository(logs: [:])
        let useCase = DeleteLog(repo: repo)

        // Act & Assert - should not throw
        try await useCase.execute(id: UUID())
    }
}

// MARK: - GetLogForDate UseCase Tests

@Suite("GetLogForDate UseCase", .tags(.habits, .useCase, .businessLogic))
@MainActor
struct GetLogForDateUseCaseTests {

    @Test("Returns log for specific date")
    func returnsLogForSpecificDate() async throws {
        // Arrange
        let habitId = UUID()
        let targetLog = HabitLogBuilder.binary(habitId: habitId, date: TestDates.today)
        let logs: [UUID: [HabitLog]] = [
            habitId: [
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.yesterday),
                targetLog,
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.daysAgo(2))
            ]
        ]
        let repo = MockLogRepository(logs: logs)
        let useCase = GetLogForDate(repo: repo)

        // Act
        let result = try await useCase.execute(habitID: habitId, date: TestDates.today)

        // Assert
        #expect(result != nil, "Should find log for today")
        #expect(CalendarUtils.isSameDay(result!.date, TestDates.today), "Should return today's log")
    }

    @Test("Returns nil when no log exists for date")
    func returnsNilWhenNoLogForDate() async throws {
        // Arrange
        let habitId = UUID()
        let logs: [UUID: [HabitLog]] = [
            habitId: [
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.yesterday)
            ]
        ]
        let repo = MockLogRepository(logs: logs)
        let useCase = GetLogForDate(repo: repo)

        // Act
        let result = try await useCase.execute(habitID: habitId, date: TestDates.today)

        // Assert
        #expect(result == nil, "Should return nil for date without log")
    }

    @Test("Returns nil when habit has no logs")
    func returnsNilWhenHabitHasNoLogs() async throws {
        // Arrange
        let habitId = UUID()
        let repo = MockLogRepository(logs: [:])
        let useCase = GetLogForDate(repo: repo)

        // Act
        let result = try await useCase.execute(habitID: habitId, date: TestDates.today)

        // Assert
        #expect(result == nil, "Should return nil when no logs exist")
    }

    @Test("Finds log regardless of time of day")
    func findsLogRegardlessOfTimeOfDay() async throws {
        // Arrange
        let habitId = UUID()
        let calendar = Calendar.current
        let morningLog = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: TestDates.today)!
        let eveningQuery = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: TestDates.today)!

        let logs: [UUID: [HabitLog]] = [
            habitId: [
                HabitLogBuilder.binary(habitId: habitId, date: morningLog)
            ]
        ]
        let repo = MockLogRepository(logs: logs)
        let useCase = GetLogForDate(repo: repo)

        // Act - query with evening time for morning log
        let result = try await useCase.execute(habitID: habitId, date: eveningQuery)

        // Assert
        #expect(result != nil, "Should find log regardless of time of day")
    }
}

// MARK: - GetEarliestLogDate UseCase Tests

@Suite("GetEarliestLogDate UseCase", .tags(.habits, .useCase, .businessLogic))
@MainActor
struct GetEarliestLogDateUseCaseTests {

    @Test("Returns earliest log date for habit")
    func returnsEarliestLogDate() async throws {
        // Arrange
        let habitId = UUID()
        let earliestDate = TestDates.daysAgo(30)
        let logs: [UUID: [HabitLog]] = [
            habitId: [
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.today),
                HabitLogBuilder.binary(habitId: habitId, date: TestDates.yesterday),
                HabitLogBuilder.binary(habitId: habitId, date: earliestDate)
            ]
        ]
        let repo = MockLogRepository(logs: logs)
        let useCase = GetEarliestLogDate(repo: repo)

        // Act
        let result = try await useCase.execute(for: habitId)

        // Assert
        let expectedStart = CalendarUtils.startOfDayLocal(for: earliestDate)
        #expect(result == expectedStart, "Should return start of earliest log date")
    }

    @Test("Returns nil when habit has no logs")
    func returnsNilWhenNoLogs() async throws {
        // Arrange
        let habitId = UUID()
        let repo = MockLogRepository(logs: [:])
        let useCase = GetEarliestLogDate(repo: repo)

        // Act
        let result = try await useCase.execute(for: habitId)

        // Assert
        #expect(result == nil, "Should return nil when no logs exist")
    }

    @Test("Returns correct date when single log exists")
    func returnsCorrectDateForSingleLog() async throws {
        // Arrange
        let habitId = UUID()
        let logDate = TestDates.daysAgo(5)
        let logs: [UUID: [HabitLog]] = [
            habitId: [
                HabitLogBuilder.binary(habitId: habitId, date: logDate)
            ]
        ]
        let repo = MockLogRepository(logs: logs)
        let useCase = GetEarliestLogDate(repo: repo)

        // Act
        let result = try await useCase.execute(for: habitId)

        // Assert
        let expectedStart = CalendarUtils.startOfDayLocal(for: logDate)
        #expect(result == expectedStart, "Should return start of day for single log")
    }
}

// MARK: - LogHabit UseCase Tests (Additional)

@Suite("LogHabit UseCase - Additional Tests", .tags(.habits, .useCase, .businessLogic))
@MainActor
struct LogHabitAdditionalTests {

    @Test("Successfully logs binary habit completion")
    func successfullyLogsBinaryHabit() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(7))
        let habitRepo = MockHabitRepository(habits: [habit])
        let logRepo = MockLogRepository()
        let validateSchedule = MockValidateHabitScheduleUseCase(isValid: true)
        let useCase = LogHabit(repo: logRepo, habitRepo: habitRepo, validateSchedule: validateSchedule)

        let log = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)

        // Act
        try await useCase.execute(log)

        // Assert
        #expect(logRepo.upsertedLogs.count == 1, "Log should be saved")
        #expect(logRepo.upsertedLogs.first?.id == log.id, "Correct log should be saved")
    }

    @Test("Successfully logs numeric habit value")
    func successfullyLogsNumericHabit() async throws {
        // Arrange
        let habit = HabitBuilder.numeric(
            name: "Water",
            schedule: .daily,
            startDate: TestDates.daysAgo(7)
        )
        let habitRepo = MockHabitRepository(habits: [habit])
        let logRepo = MockLogRepository()
        let validateSchedule = MockValidateHabitScheduleUseCase(isValid: true)
        let useCase = LogHabit(repo: logRepo, habitRepo: habitRepo, validateSchedule: validateSchedule)

        let log = HabitLogBuilder.numeric(habitId: habit.id, value: 5.0, date: TestDates.today)

        // Act
        try await useCase.execute(log)

        // Assert
        #expect(logRepo.upsertedLogs.count == 1, "Log should be saved")
        #expect(logRepo.upsertedLogs.first?.value == 5.0, "Numeric value should be preserved")
    }

    @Test("Throws error when habit not found")
    func throwsErrorWhenHabitNotFound() async throws {
        // Arrange
        let habitRepo = MockHabitRepository(habits: [])
        let logRepo = MockLogRepository()
        let validateSchedule = MockValidateHabitScheduleUseCase(isValid: true)
        let useCase = LogHabit(repo: logRepo, habitRepo: habitRepo, validateSchedule: validateSchedule)

        let log = HabitLogBuilder.binary(habitId: UUID(), date: TestDates.today)

        // Act & Assert
        do {
            try await useCase.execute(log)
            Issue.record("Should throw habitUnavailable error")
        } catch let error as HabitScheduleValidationError {
            if case .habitUnavailable = error {
                // Expected
            } else {
                Issue.record("Wrong error type: \(error)")
            }
        }
    }

    @Test("Throws error when habit is inactive")
    func throwsErrorWhenHabitIsInactive() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily, isActive: false, startDate: TestDates.daysAgo(7))
        let habitRepo = MockHabitRepository(habits: [habit])
        let logRepo = MockLogRepository()
        let validateSchedule = MockValidateHabitScheduleUseCase(isValid: true)
        let useCase = LogHabit(repo: logRepo, habitRepo: habitRepo, validateSchedule: validateSchedule)

        let log = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)

        // Act & Assert
        do {
            try await useCase.execute(log)
            Issue.record("Should throw habitUnavailable error")
        } catch let error as HabitScheduleValidationError {
            if case .habitUnavailable(let name) = error {
                #expect(name == habit.name, "Error should include habit name")
            } else {
                Issue.record("Wrong error type: \(error)")
            }
        }
    }

    @Test("Throws error when schedule validation fails")
    func throwsErrorWhenScheduleValidationFails() async throws {
        // Arrange - daysOfWeek uses Set<Int> where 1=Mon, 7=Sun
        let habit = HabitBuilder.binary(schedule: .daysOfWeek([1]), startDate: TestDates.daysAgo(7))
        let habitRepo = MockHabitRepository(habits: [habit])
        let logRepo = MockLogRepository()

        // Configure mock to return invalid schedule
        let validateSchedule = MockValidateHabitScheduleUseCase(isValid: false)
        let useCase = LogHabit(repo: logRepo, habitRepo: habitRepo, validateSchedule: validateSchedule)

        let log = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)

        // Act & Assert
        do {
            try await useCase.execute(log)
            Issue.record("Should throw schedule validation error")
        } catch is HabitScheduleValidationError {
            // Expected - any schedule validation error
        }
    }

    @Test("Upserts log when logging same habit for same date")
    func upsertsLogForSameDate() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(7))
        let habitRepo = MockHabitRepository(habits: [habit])
        let logRepo = MockLogRepository()
        let validateSchedule = MockValidateHabitScheduleUseCase(isValid: true)
        let useCase = LogHabit(repo: logRepo, habitRepo: habitRepo, validateSchedule: validateSchedule)

        let log1 = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)
        let log2 = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)

        // Act - log twice
        try await useCase.execute(log1)
        try await useCase.execute(log2)

        // Assert - both calls should go through (upsert behavior)
        #expect(logRepo.upsertedLogs.count == 2, "Both logs should be upserted")
    }
}
