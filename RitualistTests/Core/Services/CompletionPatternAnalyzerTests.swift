//
//  CompletionPatternAnalyzerTests.swift
//  RitualistTests
//
//  Tests for CompletionPatternAnalyzer service.
//

import Testing
import Foundation
@testable import RitualistCore

// MARK: - Mock Use Cases

private final class MockGetActiveHabitsUseCase: GetActiveHabitsUseCase {
    var habits: [Habit] = []
    var shouldThrow = false

    func execute() async throws -> [Habit] {
        if shouldThrow {
            throw NSError(domain: "test", code: 1)
        }
        return habits
    }
}

private final class MockGetLogsUseCase: GetLogsUseCase {
    var logsByHabit: [UUID: [HabitLog]] = [:]
    var shouldThrow = false

    func execute(for habitID: UUID, since: Date?, until: Date?, timezone: TimeZone) async throws -> [HabitLog] {
        if shouldThrow {
            throw NSError(domain: "test", code: 1)
        }
        return logsByHabit[habitID] ?? []
    }

    func execute(for habitID: UUID, since: Date?, until: Date?) async throws -> [HabitLog] {
        try await execute(for: habitID, since: since, until: until, timezone: .current)
    }
}


// MARK: - Analyze Pattern Tests

@Suite("CompletionPatternAnalyzer - Pattern Analysis")
struct CompletionPatternAnalyzerPatternTests {

    @Test("Returns consistent for 80%+ completion")
    func consistentPatternAt80Percent() {
        let analyzer = CompletionPatternAnalyzer(
            getActiveHabits: MockGetActiveHabitsUseCase(),
            getLogs: MockGetLogsUseCase(),
            logger: DebugLogger(subsystem: "test", category: "test")
        )

        let pattern = analyzer.analyzePattern(completionPercentage: 0.85)

        #expect(pattern == .consistent, "80%+ should be consistent")
    }

    @Test("Returns improving for 50-79% completion")
    func improvingPatternAt60Percent() {
        let analyzer = CompletionPatternAnalyzer(
            getActiveHabits: MockGetActiveHabitsUseCase(),
            getLogs: MockGetLogsUseCase(),
            logger: DebugLogger(subsystem: "test", category: "test")
        )

        let pattern = analyzer.analyzePattern(completionPercentage: 0.6)

        #expect(pattern == .improving, "50-79% should be improving")
    }

    @Test("Returns declining for 1-49% completion")
    func decliningPatternAt30Percent() {
        let analyzer = CompletionPatternAnalyzer(
            getActiveHabits: MockGetActiveHabitsUseCase(),
            getLogs: MockGetLogsUseCase(),
            logger: DebugLogger(subsystem: "test", category: "test")
        )

        let pattern = analyzer.analyzePattern(completionPercentage: 0.3)

        #expect(pattern == .declining, "1-49% should be declining")
    }

    @Test("Returns insufficient for 0% completion")
    func insufficientPatternAt0Percent() {
        let analyzer = CompletionPatternAnalyzer(
            getActiveHabits: MockGetActiveHabitsUseCase(),
            getLogs: MockGetLogsUseCase(),
            logger: DebugLogger(subsystem: "test", category: "test")
        )

        let pattern = analyzer.analyzePattern(completionPercentage: 0.0)

        #expect(pattern == .insufficient, "0% should be insufficient")
    }

    @Test("Returns insufficient for nil completion")
    func insufficientPatternForNil() {
        let analyzer = CompletionPatternAnalyzer(
            getActiveHabits: MockGetActiveHabitsUseCase(),
            getLogs: MockGetLogsUseCase(),
            logger: DebugLogger(subsystem: "test", category: "test")
        )

        let pattern = analyzer.analyzePattern(completionPercentage: nil)

        #expect(pattern == .insufficient, "nil should be insufficient")
    }

    @Test("Boundary: 80% is consistent")
    func boundaryAt80Percent() {
        let analyzer = CompletionPatternAnalyzer(
            getActiveHabits: MockGetActiveHabitsUseCase(),
            getLogs: MockGetLogsUseCase(),
            logger: DebugLogger(subsystem: "test", category: "test")
        )

        let pattern = analyzer.analyzePattern(completionPercentage: 0.8)

        #expect(pattern == .consistent, "Exactly 80% should be consistent")
    }

    @Test("Boundary: 50% is improving")
    func boundaryAt50Percent() {
        let analyzer = CompletionPatternAnalyzer(
            getActiveHabits: MockGetActiveHabitsUseCase(),
            getLogs: MockGetLogsUseCase(),
            logger: DebugLogger(subsystem: "test", category: "test")
        )

        let pattern = analyzer.analyzePattern(completionPercentage: 0.5)

        #expect(pattern == .improving, "Exactly 50% should be improving")
    }
}

// MARK: - Comeback Story Tests

@Suite("CompletionPatternAnalyzer - Comeback Story Detection")
struct CompletionPatternAnalyzerComebackTests {

    @Test("No comeback when no habits")
    func noComebackWithNoHabits() async {
        let mockHabits = MockGetActiveHabitsUseCase()
        mockHabits.habits = []

        let analyzer = CompletionPatternAnalyzer(
            getActiveHabits: mockHabits,
            getLogs: MockGetLogsUseCase(),
            logger: DebugLogger(subsystem: "test", category: "test")
        )

        let isComebackStory = await analyzer.checkComebackStory(
            currentCompletion: 0.8,
            timezone: .current
        )

        #expect(!isComebackStory, "No comeback with no habits")
    }

    @Test("Returns false on error")
    func returnsFalseOnError() async {
        let mockHabits = MockGetActiveHabitsUseCase()
        mockHabits.shouldThrow = true

        let analyzer = CompletionPatternAnalyzer(
            getActiveHabits: mockHabits,
            getLogs: MockGetLogsUseCase(),
            logger: DebugLogger(subsystem: "test", category: "test")
        )

        let isComebackStory = await analyzer.checkComebackStory(
            currentCompletion: 0.8,
            timezone: .current
        )

        #expect(!isComebackStory, "Should return false on error")
    }
}
