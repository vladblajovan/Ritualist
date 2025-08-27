//
//  StreakUseCasesTests.swift
//  RitualistTests
//
//  Created by Claude on 08.08.2025.
//

import Testing
import Foundation
@testable import Ritualist
import RitualistCore

struct StreakUseCasesTests {
    
    // MARK: - Test Data Setup
    
    static let testCalendar = DateUtils.userCalendar()
    
    // Create service instances for testing
    let habitCompletionService = DefaultHabitCompletionService(calendar: Self.testCalendar)
    
    func createStreakCalculationService() -> StreakCalculationService {
        return DefaultStreakCalculationService(habitCompletionService: habitCompletionService, calendar: Self.testCalendar)
    }
    
    func createCurrentStreakUseCase() -> CalculateCurrentStreak {
        return CalculateCurrentStreak(streakCalculationService: createStreakCalculationService())
    }
    
    
    // Create fixed test dates - Aug 4, 2025 is a Monday
    let monday = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 4))!
    let tuesday = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 5))!
    let wednesday = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 6))!
    let thursday = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 7))!
    let friday = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 8))!
    let saturday = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 9))!
    let sunday = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 10))!
    
    // Next week
    let nextMonday = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 11))!
    let nextTuesday = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 12))!
    
    func createHabit(schedule: HabitSchedule, kind: HabitKind = .binary, startDate: Date? = nil) -> Habit {
        let habitStartDate = startDate ?? Self.testCalendar.date(byAdding: .weekOfYear, value: -2, to: Date())!
        return Habit(
            id: UUID(),
            name: "Test Habit",
            emoji: "🎯",
            kind: kind,
            dailyTarget: kind == .numeric ? 10.0 : nil,
            schedule: schedule,
            reminders: [],
            startDate: habitStartDate
        )
    }
    
    func createLog(date: Date, value: Double = 1.0, habitID: UUID) -> HabitLog {
        HabitLog(
            id: UUID(),
            habitID: habitID,
            date: date,
            value: value
        )
    }
    
    func createLog(for habit: Habit, date: Date, value: Double = 1.0) -> HabitLog {
        createLog(date: date, value: value, habitID: habit.id)
    }
    
    // MARK: - CalculateCurrentStreakUseCase Tests
    
    @Test("Daily habit with consecutive days returns correct streak")
    func dailyHabitConsecutiveDays() {
        let useCase = createCurrentStreakUseCase()
        // Fix: Set habit start date to before our test logs to ensure all count
        let habit = createHabit(schedule: .daily, startDate: monday) // Start from Monday, logs are Wed-Fri
        let logs = [
            createLog(for: habit, date: friday),     // Day 3
            createLog(for: habit, date: thursday),   // Day 2
            createLog(for: habit, date: wednesday)   // Day 1
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 3)
    }
    
    @Test("Daily habit with gap breaks streak")
    func dailyHabitWithGap() {
        let useCase = createCurrentStreakUseCase()
        let habit = createHabit(schedule: .daily)
        let logs = [
            createLog(for: habit, date: friday),     // Today
            createLog(for: habit, date: wednesday),  // Gap on Thursday
            createLog(for: habit, date: tuesday),
            createLog(for: habit, date: monday)
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 1) // Only Friday counts
    }
    
    @Test("DaysOfWeek habit respects schedule")
    func daysOfWeekHabitSchedule() {
        let useCase = createCurrentStreakUseCase()
        // Ensure habit start date predates all logs (1 week before Monday)
        let earlierStartDate = Self.testCalendar.date(byAdding: .weekOfYear, value: -1, to: monday)!
        // Monday, Wednesday, Friday habit (1, 3, 5 in habit format)
        let habit = createHabit(schedule: .daysOfWeek([1, 3, 5]), startDate: earlierStartDate)
        let logs = [
            createLog(for: habit, date: friday),     // Friday (scheduled)
            createLog(for: habit, date: thursday),   // Thursday (not scheduled - should be ignored)
            createLog(for: habit, date: wednesday),  // Wednesday (scheduled)
            createLog(for: habit, date: tuesday),    // Tuesday (not scheduled - should be ignored)
            createLog(for: habit, date: monday)      // Monday (scheduled)
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 3) // Monday, Wednesday, Friday
    }
    
    @Test("DaysOfWeek habit missing scheduled day breaks streak")
    func daysOfWeekHabitMissedDay() {
        let useCase = createCurrentStreakUseCase()
        let habit = createHabit(schedule: .daysOfWeek([1, 3, 5])) // Mon, Wed, Fri
        let logs = [
            createLog(for: habit, date: friday),     // Friday (scheduled)
            // Missing Wednesday (scheduled day)
            createLog(for: habit, date: monday)      // Monday (scheduled)
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 1) // Only Friday counts, streak broken by missing Wednesday
    }
    
    @Test("TimesPerWeek habit tracks weekly completion")
    func timesPerWeekHabit() {
        let useCase = createCurrentStreakUseCase()
        // Ensure habit start date predates all logs (3 weeks before Friday)
        let earlierStartDate = Self.testCalendar.date(byAdding: .weekOfYear, value: -3, to: friday)!
        let habit = createHabit(schedule: .timesPerWeek(3), startDate: earlierStartDate)
        let logs = [
            // This week (3 logs - meets target)
            createLog(for: habit, date: friday),
            createLog(for: habit, date: wednesday),
            createLog(for: habit, date: monday),
            // Previous week (3 logs - meets target)
            createLog(for: habit, date: Self.testCalendar.date(byAdding: .day, value: -7, to: friday)!),
            createLog(for: habit, date: Self.testCalendar.date(byAdding: .day, value: -7, to: wednesday)!),
            createLog(for: habit, date: Self.testCalendar.date(byAdding: .day, value: -7, to: monday)!)
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 2) // Two weeks meeting target
    }
    
    @Test("TimesPerWeek habit insufficient logs breaks streak")
    func timesPerWeekInsufficientLogs() {
        let useCase = createCurrentStreakUseCase()
        // Ensure habit start date predates all logs (3 weeks before Friday)
        let earlierStartDate = Self.testCalendar.date(byAdding: .weekOfYear, value: -3, to: friday)!
        let habit = createHabit(schedule: .timesPerWeek(3), startDate: earlierStartDate)
        let logs = [
            // This week (only 2 logs - doesn't meet target of 3)
            createLog(for: habit, date: friday),
            createLog(for: habit, date: wednesday),
            // Previous week (3 logs - meets target)
            createLog(for: habit, date: Self.testCalendar.date(byAdding: .day, value: -7, to: friday)!),
            createLog(for: habit, date: Self.testCalendar.date(byAdding: .day, value: -7, to: wednesday)!),
            createLog(for: habit, date: Self.testCalendar.date(byAdding: .day, value: -7, to: monday)!)
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 0) // Current week doesn't meet target, so no streak
    }
    
    @Test("Numeric habit requires meeting daily target")
    func numericHabitDailyTarget() {
        let useCase = createCurrentStreakUseCase()
        let habit = createHabit(schedule: .daily, kind: .numeric)
        let logs = [
            createLog(for: habit, date: friday, value: 12.0),     // Meets target (10)
            createLog(for: habit, date: thursday, value: 8.0),    // Doesn't meet target
            createLog(for: habit, date: wednesday, value: 15.0)   // Meets target
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 1) // Only Friday meets target
    }
    
    @Test("Empty logs returns zero streak")
    func emptyLogsZeroStreak() {
        let useCase = createCurrentStreakUseCase()
        let habit = createHabit(schedule: .daily)
        let logs: [HabitLog] = []
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 0)
    }
    
    // MARK: - First Weekday Testing
    
    @Test("TimesPerWeek habit respects system first weekday - Sunday start")
    func timesPerWeekSundayFirstWeekday() {
        let useCase = createCurrentStreakUseCase()
        // Ensure habit start date predates all logs (3 weeks before Sunday)
        let earlierStartDate = Self.testCalendar.date(byAdding: .weekOfYear, value: -3, to: sunday)!
        let habit = createHabit(schedule: .timesPerWeek(2), startDate: earlierStartDate)
        
        // Create logs spanning Sunday-Saturday week
        let logs = [
            createLog(for: habit, date: sunday),     // End of week
            createLog(for: habit, date: saturday),   // Second log of week
            // Previous week (Sunday start)
            createLog(for: habit, date: Self.testCalendar.date(byAdding: .day, value: -7, to: sunday)!),
            createLog(for: habit, date: Self.testCalendar.date(byAdding: .day, value: -7, to: friday)!)
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: sunday)
        #expect(streak == 2) // Both weeks should meet target regardless of first weekday
    }
    
    @Test("TimesPerWeek habit respects system first weekday - Monday start")
    func timesPerWeekMondayFirstWeekday() {
        let useCase = createCurrentStreakUseCase()
        // Ensure habit start date predates all logs (3 weeks before Sunday)
        let earlierStartDate = Self.testCalendar.date(byAdding: .weekOfYear, value: -3, to: sunday)!
        let habit = createHabit(schedule: .timesPerWeek(2), startDate: earlierStartDate)
        
        // Create logs spanning Monday-Sunday week
        let logs = [
            createLog(for: habit, date: sunday),     // End of week
            createLog(for: habit, date: wednesday),  // Second log of week
            // Previous week (Monday start)
            createLog(for: habit, date: Self.testCalendar.date(byAdding: .day, value: -7, to: sunday)!),
            createLog(for: habit, date: Self.testCalendar.date(byAdding: .day, value: -7, to: wednesday)!)
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: sunday)
        #expect(streak == 2) // Both weeks should meet target
    }
    
    // MARK: - Week Boundary Edge Cases
    
    @Test("Week boundary transition maintains streak accuracy")
    func weekBoundaryTransition() {
        let useCase = createCurrentStreakUseCase()
        // Ensure habit start date predates all logs (3 weeks before nextMonday)
        let earlierStartDate = Self.testCalendar.date(byAdding: .weekOfYear, value: -3, to: nextMonday)!
        let habit = createHabit(schedule: .timesPerWeek(1), startDate: earlierStartDate)
        
        // Test transition from one week to next
        let lastDayOfWeek = sunday
        let firstDayOfNextWeek = nextMonday
        
        let logs = [
            createLog(for: habit, date: firstDayOfNextWeek), // New week
            createLog(for: habit, date: lastDayOfWeek)       // Previous week
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: firstDayOfNextWeek)
        #expect(streak == 2) // Both weeks meet target of 1
    }
    
    @Test("DaysOfWeek habit handles week transitions correctly")
    func daysOfWeekWeekTransition() {
        let useCase = createCurrentStreakUseCase()
        // Ensure habit start date predates all logs (2 weeks before Monday)
        let earlierStartDate = DateUtils.userCalendar().date(byAdding: .weekOfYear, value: -2, to: monday)!
        let habit = createHabit(schedule: .daysOfWeek([1, 7]), startDate: earlierStartDate) // Monday and Sunday
        
        let logs = [
            createLog(for: habit, date: nextMonday),  // Monday of new week
            createLog(for: habit, date: sunday),      // Sunday of previous week  
            createLog(for: habit, date: monday)       // Monday of previous week
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: nextMonday)
        #expect(streak == 3) // All scheduled days completed
    }
    
    // MARK: - Edge Cases
    
    @Test("Weekday conversion handles Sunday correctly")
    func weekdayConversionSunday() {
        let useCase = createCurrentStreakUseCase()
        let habit = createHabit(schedule: .daysOfWeek([7])) // Sunday in habit format
        let logs = [createLog(for: habit, date: sunday)]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: sunday)
        #expect(streak == 1) // Sunday should be recognized correctly
    }
    
    @Test("Weekday conversion handles Monday correctly")
    func weekdayConversionMonday() {
        let useCase = createCurrentStreakUseCase()
        // Ensure habit start date predates the test log (1 week before Monday)
        let earlierStartDate = DateUtils.userCalendar().date(byAdding: .weekOfYear, value: -1, to: monday)!
        let habit = createHabit(schedule: .daysOfWeek([1]), startDate: earlierStartDate) // Monday in habit format
        let logs = [createLog(for: habit, date: monday)]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: monday)
        #expect(streak == 1) // Monday should be recognized correctly
    }
    
    @Test("Binary habit with zero value is not compliant")
    func binaryHabitZeroValue() {
        let useCase = createCurrentStreakUseCase()
        let habit = createHabit(schedule: .daily, kind: .binary)
        let logs = [
            createLog(for: habit, date: friday, value: 1.0),  // Compliant
            createLog(for: habit, date: thursday, value: 0.0) // Not compliant
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 1) // Only Friday is compliant
    }
    
    @Test("Numeric habit with nil value defaults to zero")
    func numericHabitNilValue() {
        let useCase = createCurrentStreakUseCase()
        let habit = createHabit(schedule: .daily, kind: .numeric)
        var log = createLog(for: habit, date: friday)
        log.value = nil // Explicitly set to nil
        let logs = [log]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 0) // nil defaults to 0, which doesn't meet target of 10
    }
}

// MARK: - Batch Query Integration Tests

@Suite("GetBatchLogs UseCase Tests")
struct GetBatchLogsUseCaseTests {
    
    @Test("GetBatchLogs UseCase returns grouped logs by habit ID with date filtering")
    func testGetBatchLogsWithDateFiltering() async throws {
        // Arrange: Repository with test data
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        let useCase = GetBatchLogs(repo: logRepository)
        
        // Create test habits
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        
        let habit1 = HabitBuilder().withName("Habit1").build()
        let habit2 = HabitBuilder().withName("Habit2").build()
        
        try await habitRepository.create(habit1)
        try await habitRepository.create(habit2)
        
        // Create logs with various dates
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: today)!
        
        let logs = [
            HabitLogBuilder().withHabit(habit1).withDate(today).withValue(1.0).build(),
            HabitLogBuilder().withHabit(habit1).withDate(yesterday).withValue(2.0).build(),
            HabitLogBuilder().withHabit(habit1).withDate(twoDaysAgo).withValue(3.0).build(),
            HabitLogBuilder().withHabit(habit1).withDate(threeDaysAgo).withValue(4.0).build(),
            
            HabitLogBuilder().withHabit(habit2).withDate(today).withValue(10.0).build(),
            HabitLogBuilder().withHabit(habit2).withDate(yesterday).withValue(20.0).build(),
            HabitLogBuilder().withHabit(habit2).withDate(threeDaysAgo).withValue(40.0).build(),
        ]
        
        for log in logs {
            try await logRepository.upsert(log)
        }
        
        // Act: Query with date filtering (last 2 days)
        let result = try await useCase.execute(for: [habit1.id, habit2.id], since: twoDaysAgo, until: nil)
        
        // Assert: Should get filtered results grouped by habit
        #expect(result.keys.count == 2)
        #expect(result[habit1.id]?.count == 3) // today, yesterday, twoDaysAgo
        #expect(result[habit2.id]?.count == 2) // today, yesterday (threeDaysAgo filtered out)
        
        // Verify exact values for habit1 (should exclude threeDaysAgo)
        let habit1Values = result[habit1.id]?.compactMap { $0.value } ?? []
        #expect(Set(habit1Values) == Set([1.0, 2.0, 3.0])) // 4.0 from threeDaysAgo should be filtered
        
        // Verify exact values for habit2 (should exclude threeDaysAgo)
        let habit2Values = result[habit2.id]?.compactMap { $0.value } ?? []
        #expect(Set(habit2Values) == Set([10.0, 20.0])) // 40.0 from threeDaysAgo should be filtered
    }
    
    @Test("GetBatchLogs UseCase handles empty result gracefully")
    func testGetBatchLogsWithNoLogs() async throws {
        // Arrange: Repository with habits but no logs
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        let useCase = GetBatchLogs(repo: logRepository)
        
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        
        let habit1 = HabitBuilder().withName("Empty Habit 1").build()
        let habit2 = HabitBuilder().withName("Empty Habit 2").build()
        
        try await habitRepository.create(habit1)
        try await habitRepository.create(habit2)
        
        // Act: Query habits with no logs
        let result = try await useCase.execute(for: [habit1.id, habit2.id], since: nil, until: nil)
        
        // Assert: Should return empty arrays for each habit
        #expect(result.keys.count == 2)
        #expect(result[habit1.id]?.isEmpty == true)
        #expect(result[habit2.id]?.isEmpty == true)
    }
}