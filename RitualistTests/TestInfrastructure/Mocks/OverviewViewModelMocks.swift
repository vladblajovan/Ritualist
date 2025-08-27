//
//  SimplifiedOverviewMocks.swift
//  RitualistTests
//
//  Created by Claude on 22.08.2025.
//

import Foundation
import FactoryKit
@testable import Ritualist
@testable import RitualistCore

// MARK: - Essential UseCase Mocks

/// Mock implementation of GetActiveHabitsUseCase for testing
class MockGetActiveHabitsUseCase: GetActiveHabitsUseCase {
    var mockHabits: [Habit] = []
    var shouldFail = false
    var shouldDelay = false
    var delayInNanoseconds: UInt64 = 0
    var errorToThrow: Error = NSError(domain: "Test", code: 1, userInfo: nil)
    var executeCallCount = 0
    
    func execute() async throws -> [Habit] {
        executeCallCount += 1
        
        if shouldDelay {
            try await Task.sleep(nanoseconds: delayInNanoseconds)
        }
        
        if shouldFail {
            throw errorToThrow
        }
        
        return mockHabits
    }
}

/// Mock implementation of GetLogsUseCase for testing
class MockGetLogsUseCase: GetLogsUseCase {
    var mockLogs: [HabitLog] = []
    var shouldFail = false
    var errorToThrow: Error = NSError(domain: "Test", code: 1, userInfo: nil)
    var executeCallCount = 0
    
    func execute(for habitID: UUID, since: Date?, until: Date?) async throws -> [HabitLog] {
        executeCallCount += 1
        
        if shouldFail {
            throw errorToThrow
        }
        
        // Filter logs by habit ID and date range
        let startDate = since ?? Date.distantPast
        let endDate = until ?? Date.distantFuture
        return mockLogs.filter { log in
            log.habitID == habitID && log.date >= startDate && log.date <= endDate
        }
    }
}

/// Mock implementation of GetBatchLogsUseCase for testing
class MockGetBatchLogsUseCase: GetBatchLogsUseCase {
    var mockLogs: [UUID: [HabitLog]] = [:]
    var shouldFail = false
    var errorToThrow: Error = NSError(domain: "Test", code: 1, userInfo: nil)
    var executeCallCount = 0
    
    func execute(for habitIDs: [UUID], since: Date?, until: Date?) async throws -> [UUID: [HabitLog]] {
        executeCallCount += 1
        
        if shouldFail {
            throw errorToThrow
        }
        
        // Filter logs by habit IDs and date range
        let startDate = since ?? Date.distantPast
        let endDate = until ?? Date.distantFuture
        var result: [UUID: [HabitLog]] = [:]
        for habitID in habitIDs {
            let logs = mockLogs[habitID] ?? []
            result[habitID] = logs.filter { log in
                log.date >= startDate && log.date <= endDate
            }
        }
        
        return result
    }
}

/// Mock implementation of LogHabitUseCase for testing
class MockLogHabitUseCase: LogHabitUseCase {
    var shouldSucceed = true
    var errorToThrow: Error = NSError(domain: "Test", code: 1, userInfo: nil)
    var executeCallCount = 0
    var lastLoggedHabit: HabitLog?
    
    func execute(_ log: HabitLog) async throws {
        executeCallCount += 1
        lastLoggedHabit = log
        
        if !shouldSucceed {
            throw errorToThrow
        }
    }
}

/// Mock implementation of DeleteLogUseCase for testing
class MockDeleteLogUseCase: DeleteLogUseCase {
    var shouldSucceed = true
    var errorToThrow: Error = NSError(domain: "Test", code: 1, userInfo: nil)
    var deleteCallCount = 0
    var deletedLogIds: Set<UUID> = []
    
    func execute(id: UUID) async throws {
        deleteCallCount += 1
        deletedLogIds.insert(id)
        
        if !shouldSucceed {
            throw errorToThrow
        }
    }
}

/// Mock implementation of CalculateCurrentStreakUseCase for testing
class MockCalculateCurrentStreakUseCase: CalculateCurrentStreakUseCase {
    var defaultStreakValue: Int = 0
    var customStreakValues: [UUID: Int] = [:]
    var executeCallCount = 0
    
    func execute(habit: Habit, logs: [HabitLog], asOf date: Date) -> Int {
        executeCallCount += 1
        return customStreakValues[habit.id] ?? defaultStreakValue
    }
}

// MARK: - Service Mocks

/// Mock implementation of SlogansService for testing
class MockSlogansService: SlogansServiceProtocol {
    var currentSlogan = "Test Slogan"
    
    func getSlogan(for timeOfDay: TimeOfDay) -> String {
        return currentSlogan
    }
    
    func getCurrentSlogan() -> String {
        return currentSlogan
    }
}

/// Mock implementation of UserService for testing
class MockUserService: UserService {
    var mockProfile = UserProfile(
        id: UUID(),
        name: "Test User",
        avatarImageData: nil,
        appearance: 0, // followSystem
        subscriptionPlan: SubscriptionPlan.free,
        subscriptionExpiryDate: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
    
    var isPremiumUser: Bool = false
    
    var currentProfile: UserProfile {
        return mockProfile
    }
    
    func updateProfile(_ profile: UserProfile) async throws {
        mockProfile = profile
    }
    
    func loadProfile() async throws -> UserProfile {
        return mockProfile
    }
    
    func updateSubscription(plan: SubscriptionPlan, expiryDate: Date?) async throws {
        // Mock implementation
    }
    
    func syncWithiCloud() async throws {
        // Mock implementation
    }
}

/// Mock implementation of HabitCompletionService for testing
class MockHabitCompletionService: HabitCompletionServiceProtocol {
    var defaultCompletionResult = false
    var customCompletionResults: [UUID: Bool] = [:]
    var isCompletedCallCount = 0
    
    func isCompleted(habit: Habit, on date: Date, logs: [HabitLog]) -> Bool {
        isCompletedCallCount += 1
        return customCompletionResults[habit.id] ?? defaultCompletionResult
    }
    
    func getProgress(habit: Habit, on date: Date, logs: [HabitLog]) -> Double {
        if isCompleted(habit: habit, on: date, logs: logs) {
            return habit.dailyTarget ?? 1.0
        } else {
            return logs.reduce(0.0) { $0 + ($1.value ?? 0.0) }
        }
    }
    
    func getWeeklyProgress(habit: Habit, for date: Date, logs: [HabitLog]) -> (completed: Int, target: Int) {
        guard case .timesPerWeek(let target) = habit.schedule else {
            return (0, 0)
        }
        
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) ?? date
        
        let weekLogs = logs.filter { log in
            log.date >= weekStart && log.date < weekEnd && (log.value ?? 0) > 0
        }
        
        let uniqueDays = Set(weekLogs.map { log in
            calendar.startOfDay(for: log.date)
        })
        
        return (uniqueDays.count, target)
    }
    
    // Required methods from HabitCompletionServiceProtocol
    func calculateProgress(habit: Habit, logs: [HabitLog], from startDate: Date, to endDate: Date) -> Double {
        return getProgress(habit: habit, on: startDate, logs: logs)
    }
    
    func calculateDailyProgress(habit: Habit, logs: [HabitLog], for date: Date) -> Double {
        return getProgress(habit: habit, on: date, logs: logs)
    }
    
    func isScheduledDay(habit: Habit, date: Date) -> Bool {
        return habit.schedule.isActiveOn(date: date)
    }
    
    func getExpectedCompletions(habit: Habit, from startDate: Date, to endDate: Date) -> Int {
        let calendar = Calendar.current
        var count = 0
        var currentDate = startDate
        
        while currentDate <= endDate {
            if isScheduledDay(habit: habit, date: currentDate) {
                count += 1
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return count
    }
}

// Note: WidgetRefreshService uses production implementation in tests
// Widget refresh is a side effect that doesn't require mocking for business logic verification

// MARK: - Simple Personality Analysis Mocks

/// Simple mock for personality components - returns basic responses
class MockPersonalityComponents {
    var shouldSucceed = true
    var callCount = 0
    
    func mockPersonalityMethod() async throws {
        callCount += 1
        if !shouldSucceed {
            throw NSError(domain: "Test", code: 1, userInfo: nil)
        }
    }
}

// MARK: - Factory Container Extensions for Testing

extension Container {
    var getActiveHabits: Factory<GetActiveHabitsUseCase> {
        self { MockGetActiveHabitsUseCase() }
            .scope(.singleton) // Ensure same instance throughout test
    }
    
    var getLogs: Factory<GetLogsUseCase> {
        self { MockGetLogsUseCase() }
            .scope(.singleton) // Ensure same instance throughout test
    }
    
    var getBatchLogs: Factory<GetBatchLogsUseCase> {
        self { MockGetBatchLogsUseCase() }
            .scope(.singleton) // Ensure same instance throughout test
    }
    
    var logHabit: Factory<LogHabitUseCase> {
        self { MockLogHabitUseCase() }
            .scope(.singleton) // Ensure same instance throughout test
    }
    
    var deleteLog: Factory<DeleteLogUseCase> {
        self { MockDeleteLogUseCase() }
            .scope(.singleton) // Ensure same instance throughout test
    }
    
    var slogansService: Factory<SlogansServiceProtocol> {
        self { MockSlogansService() }
            .scope(.singleton) // Ensure same instance throughout test
    }
    
    var userService: Factory<UserService> {
        self { MockUserService() }
            .scope(.singleton) // Ensure same instance throughout test
    }
    
    var calculateCurrentStreak: Factory<CalculateCurrentStreakUseCase> {
        self { MockCalculateCurrentStreakUseCase() }
            .scope(.singleton) // Ensure same instance throughout test
    }
    
    var habitCompletionService: Factory<HabitCompletionServiceProtocol> {
        self { MockHabitCompletionService() }
            .scope(.singleton) // Ensure same instance throughout test
    }
    
    // Note: WidgetRefreshService uses production implementation in tests
    // Widget refresh is a side effect and doesn't need mocking for business logic tests
    
    // Additional dependencies required by OverviewViewModel
    var getPersonalityProfileUseCase: Factory<AnyObject> {
        self { MockPersonalityComponents() }
            .scope(.singleton) // Ensure same instance throughout test
    }
    
    var getPersonalityInsightsUseCase: Factory<AnyObject> {
        self { MockPersonalityComponents() }
            .scope(.singleton) // Ensure same instance throughout test
    }
    
    var updatePersonalityAnalysisUseCase: Factory<AnyObject> {
        self { MockPersonalityComponents() }
            .scope(.singleton) // Ensure same instance throughout test
    }
    
    var validateAnalysisDataUseCase: Factory<AnyObject> {
        self { MockPersonalityComponents() }
            .scope(.singleton) // Ensure same instance throughout test
    }
    
    var personalityAnalysisRepository: Factory<AnyObject> {
        self { MockPersonalityComponents() }
            .scope(.singleton) // Ensure same instance throughout test
    }
    
    var personalityDeepLinkCoordinator: Factory<AnyObject> {
        self { MockPersonalityComponents() }
            .scope(.singleton) // Ensure same instance throughout test
    }
    
    var validateHabitSchedule: Factory<AnyObject> {
        self { MockPersonalityComponents() }
            .scope(.singleton) // Ensure same instance throughout test
    }
}