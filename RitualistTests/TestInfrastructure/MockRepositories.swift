import Foundation
@testable import RitualistCore

/// Reusable mock repository implementations for testing
///
/// These provide simple in-memory implementations that return predictable data.
/// Use these for testing use case logic without SwiftData dependencies.

// MARK: - Mock Habit Repository

/// Simple in-memory HabitRepository for testing use cases
public final class MockHabitRepository: HabitRepository, @unchecked Sendable {
    public var habits: [Habit] = []

    public init(habits: [Habit] = []) {
        self.habits = habits
    }

    public func fetchAllHabits() async throws -> [Habit] {
        habits
    }

    public func fetchHabit(by id: UUID) async throws -> Habit? {
        habits.first { $0.id == id }
    }

    public func update(_ habit: Habit) async throws {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
        } else {
            habits.append(habit)
        }
    }

    public func delete(id: UUID) async throws {
        habits.removeAll { $0.id == id }
    }

    public func cleanupOrphanedHabits() async throws -> Int {
        0
    }
}

// MARK: - Mock Log Repository

/// Simple in-memory LogRepository for testing use cases
public final class MockLogRepository: LogRepository, @unchecked Sendable {
    public var logs: [UUID: [HabitLog]] = [:]
    public var upsertedLogs: [HabitLog] = []

    public init(logs: [UUID: [HabitLog]] = [:]) {
        self.logs = logs
    }

    public func logs(for habitID: UUID) async throws -> [HabitLog] {
        logs[habitID] ?? []
    }

    public func logs(for habitIDs: [UUID]) async throws -> [HabitLog] {
        habitIDs.flatMap { logs[$0] ?? [] }
    }

    public func upsert(_ log: HabitLog) async throws {
        upsertedLogs.append(log)
        if logs[log.habitID] == nil {
            logs[log.habitID] = []
        }
        logs[log.habitID]?.append(log)
    }

    public func deleteLog(id: UUID) async throws {
        for habitID in logs.keys {
            logs[habitID]?.removeAll { $0.id == id }
        }
    }
}

// MARK: - Mock Validate Habit Schedule Use Case

/// Simple mock for ValidateHabitScheduleUseCase that returns configurable results
public final class MockValidateHabitScheduleUseCase: ValidateHabitScheduleUseCase, @unchecked Sendable {
    public var isValid: Bool
    public var reason: String?

    public init(isValid: Bool = true, reason: String? = nil) {
        self.isValid = isValid
        self.reason = reason
    }

    public func execute(habit: Habit, date: Date) async throws -> HabitScheduleValidationResult {
        HabitScheduleValidationResult(isValid: isValid, reason: isValid ? nil : (reason ?? "Validation failed"))
    }
}
