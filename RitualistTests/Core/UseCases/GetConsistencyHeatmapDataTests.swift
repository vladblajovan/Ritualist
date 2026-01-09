//
//  GetConsistencyHeatmapDataTests.swift
//  RitualistTests
//
//  Tests for GetConsistencyHeatmapData use case - completion calculations
//  for different habit types and edge cases.
//

import Foundation
import Testing
@testable import RitualistCore

@Suite("GetConsistencyHeatmapData Tests")
@MainActor
struct GetConsistencyHeatmapDataTests {

    let timezone = TimeZone(identifier: "America/New_York")!
    let habitId = UUID()

    // MARK: - Binary Habit Tests

    @Test("Binary habit with positive value returns 100% completion")
    func binaryHabitPositiveValue() async throws {
        let habit = createHabit(kind: .binary)
        let log = createLog(habitId: habitId, value: 1.0)

        let useCase = createUseCase(habits: [habit], logs: [habitId: [log]])

        let result = try await useCase.execute(
            habitId: habitId,
            period: .thisWeek,
            timezone: timezone
        )

        // Find the completion for the log date
        let logDateStart = CalendarUtils.startOfDayLocal(for: log.date, timezone: timezone)
        let completion = result.dailyCompletions[logDateStart]

        #expect(completion == 1.0, "Binary habit with positive value should be 100% complete")
    }

    @Test("Binary habit with zero value returns 0% completion")
    func binaryHabitZeroValue() async throws {
        let habit = createHabit(kind: .binary)
        let log = createLog(habitId: habitId, value: 0.0)

        let useCase = createUseCase(habits: [habit], logs: [habitId: [log]])

        let result = try await useCase.execute(
            habitId: habitId,
            period: .thisWeek,
            timezone: timezone
        )

        let logDateStart = CalendarUtils.startOfDayLocal(for: log.date, timezone: timezone)
        let completion = result.dailyCompletions[logDateStart]

        #expect(completion == 0.0, "Binary habit with zero value should be 0% complete")
    }

    // MARK: - Numeric Habit Tests

    @Test("Numeric habit calculates completion as value/target")
    func numericHabitCompletionCalculation() async throws {
        let habit = createHabit(kind: .numeric, dailyTarget: 10.0)
        let log = createLog(habitId: habitId, value: 5.0)

        let useCase = createUseCase(habits: [habit], logs: [habitId: [log]])

        let result = try await useCase.execute(
            habitId: habitId,
            period: .thisWeek,
            timezone: timezone
        )

        let logDateStart = CalendarUtils.startOfDayLocal(for: log.date, timezone: timezone)
        let completion = result.dailyCompletions[logDateStart]

        #expect(completion == 0.5, "Numeric habit should be 50% complete (5/10)")
    }

    @Test("Numeric habit caps completion at 100%")
    func numericHabitCapsAt100Percent() async throws {
        let habit = createHabit(kind: .numeric, dailyTarget: 10.0)
        let log = createLog(habitId: habitId, value: 15.0) // Over target

        let useCase = createUseCase(habits: [habit], logs: [habitId: [log]])

        let result = try await useCase.execute(
            habitId: habitId,
            period: .thisWeek,
            timezone: timezone
        )

        let logDateStart = CalendarUtils.startOfDayLocal(for: log.date, timezone: timezone)
        let completion = result.dailyCompletions[logDateStart]

        #expect(completion == 1.0, "Numeric habit should cap at 100% even when exceeding target")
    }

    @Test("Numeric habit with nil target uses 1.0 as default")
    func numericHabitNilTargetUsesDefault() async throws {
        let habit = createHabit(kind: .numeric, dailyTarget: nil)
        let log = createLog(habitId: habitId, value: 0.5)

        let useCase = createUseCase(habits: [habit], logs: [habitId: [log]])

        let result = try await useCase.execute(
            habitId: habitId,
            period: .thisWeek,
            timezone: timezone
        )

        let logDateStart = CalendarUtils.startOfDayLocal(for: log.date, timezone: timezone)
        let completion = result.dailyCompletions[logDateStart]

        #expect(completion == 0.5, "Numeric habit with nil target should use 1.0 as default (0.5/1.0 = 0.5)")
    }

    // MARK: - Missing Data Tests

    @Test("Missing logs return 0% completion")
    func missingLogsReturnZero() async throws {
        let habit = createHabit(kind: .binary)
        // No logs provided

        let useCase = createUseCase(habits: [habit], logs: [:])

        let result = try await useCase.execute(
            habitId: habitId,
            period: .thisWeek,
            timezone: timezone
        )

        // All completions should be 0.0
        let nonZeroCompletions = result.dailyCompletions.values.filter { $0 > 0 }
        #expect(nonZeroCompletions.isEmpty, "Days without logs should have 0% completion")
    }

    @Test("Log with nil value treated as 0")
    func logWithNilValueTreatedAsZero() async throws {
        let habit = createHabit(kind: .binary)
        let log = createLog(habitId: habitId, value: nil)

        let useCase = createUseCase(habits: [habit], logs: [habitId: [log]])

        let result = try await useCase.execute(
            habitId: habitId,
            period: .thisWeek,
            timezone: timezone
        )

        let logDateStart = CalendarUtils.startOfDayLocal(for: log.date, timezone: timezone)
        let completion = result.dailyCompletions[logDateStart]

        #expect(completion == 0.0, "Log with nil value should be treated as 0")
    }

    // MARK: - Error Cases

    @Test("Throws error for non-existent habit")
    func habitNotFoundError() async throws {
        let nonExistentId = UUID()
        let useCase = createUseCase(habits: [], logs: [:])

        await #expect(throws: HeatmapError.habitNotFound) {
            _ = try await useCase.execute(
                habitId: nonExistentId,
                period: .thisWeek,
                timezone: timezone
            )
        }
    }

    // MARK: - Result Structure Tests

    @Test("Result includes correct habit metadata")
    func resultIncludesHabitMetadata() async throws {
        let habit = Habit(
            id: habitId,
            name: "Exercise",
            emoji: "🏃",
            kind: .binary
        )

        let useCase = createUseCase(habits: [habit], logs: [:])

        let result = try await useCase.execute(
            habitId: habitId,
            period: .thisWeek,
            timezone: timezone
        )

        #expect(result.habitId == habitId)
        #expect(result.habitName == "Exercise")
        #expect(result.habitEmoji == "🏃")
    }

    @Test("Result uses default emoji when habit has none")
    func resultUsesDefaultEmojiWhenNone() async throws {
        let habit = Habit(
            id: habitId,
            name: "Test",
            emoji: nil,
            kind: .binary
        )

        let useCase = createUseCase(habits: [habit], logs: [:])

        let result = try await useCase.execute(
            habitId: habitId,
            period: .thisWeek,
            timezone: timezone
        )

        #expect(result.habitEmoji == "📊", "Should use default chart emoji when habit has no emoji")
    }

    // MARK: - Multiple Logs Per Day

    @Test("Multiple logs on same day uses latest log")
    func multipleLogsSameDayUsesLatest() async throws {
        let habit = createHabit(kind: .binary)

        let baseDate = Date()
        let earlyLog = HabitLog(
            id: UUID(),
            habitID: habitId,
            date: baseDate,
            value: 0.0
        )
        let laterLog = HabitLog(
            id: UUID(),
            habitID: habitId,
            date: baseDate.addingTimeInterval(3600), // 1 hour later
            value: 1.0
        )

        let useCase = createUseCase(habits: [habit], logs: [habitId: [earlyLog, laterLog]])

        let result = try await useCase.execute(
            habitId: habitId,
            period: .thisWeek,
            timezone: timezone
        )

        let dayStart = CalendarUtils.startOfDayLocal(for: baseDate, timezone: timezone)
        let completion = result.dailyCompletions[dayStart]

        #expect(completion == 1.0, "Should use the later log's value (1.0), not the early one (0.0)")
    }

    // MARK: - Helpers

    private func createHabit(kind: HabitKind, dailyTarget: Double? = nil) -> Habit {
        Habit(
            id: habitId,
            name: "Test Habit",
            emoji: "✅",
            kind: kind,
            dailyTarget: dailyTarget
        )
    }

    private func createLog(habitId: UUID, value: Double?) -> HabitLog {
        HabitLog(
            id: UUID(),
            habitID: habitId,
            date: Date(),
            value: value
        )
    }

    private func createUseCase(habits: [Habit], logs: [UUID: [HabitLog]]) -> GetConsistencyHeatmapData {
        let habitRepo = MockHabitRepository(habits: habits)
        let logsUseCase = MockGetLogsUseCase(logs: logs)
        return GetConsistencyHeatmapData(habitRepository: habitRepo, getLogsUseCase: logsUseCase)
    }
}

// MARK: - Mock GetLogsUseCase

private final class MockGetLogsUseCase: GetLogsUseCase, @unchecked Sendable {
    private let logs: [UUID: [HabitLog]]

    init(logs: [UUID: [HabitLog]]) {
        self.logs = logs
    }

    func execute(for habitID: UUID, since: Date?, until: Date?, timezone: TimeZone) async throws -> [HabitLog] {
        logs[habitID] ?? []
    }

    func execute(for habitID: UUID, since: Date?, until: Date?) async throws -> [HabitLog] {
        logs[habitID] ?? []
    }
}
