//
//  StreakUseCasesTests.swift
//  RitualistTests
//
//  Created by Claude on 08.08.2025.
//

import Testing
import Foundation
@testable import Ritualist

struct StreakUseCasesTests {
    
    // MARK: - Test Data Setup
    
    static let testCalendar = Calendar(identifier: .gregorian)
    
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
    
    func createHabit(schedule: HabitSchedule, kind: HabitKind = .binary) -> Habit {
        Habit(
            id: UUID(),
            name: "Test Habit",
            emoji: "🎯",
            kind: kind,
            dailyTarget: kind == .numeric ? 10.0 : nil,
            schedule: schedule,
            reminders: []
        )
    }
    
    func createLog(date: Date, value: Double = 1.0) -> HabitLog {
        HabitLog(
            id: UUID(),
            habitID: UUID(),
            date: date,
            value: value
        )
    }
    
    // MARK: - CalculateCurrentStreakUseCase Tests
    
    @Test("Daily habit with consecutive days returns correct streak")
    func dailyHabitConsecutiveDays() {
        let useCase = CalculateCurrentStreak()
        let habit = createHabit(schedule: .daily)
        let logs = [
            createLog(date: friday),     // Day 3
            createLog(date: thursday),   // Day 2
            createLog(date: wednesday)   // Day 1
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 3)
    }
    
    @Test("Daily habit with gap breaks streak")
    func dailyHabitWithGap() {
        let useCase = CalculateCurrentStreak()
        let habit = createHabit(schedule: .daily)
        let logs = [
            createLog(date: friday),     // Today
            createLog(date: wednesday),  // Gap on Thursday
            createLog(date: tuesday),
            createLog(date: monday)
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 1) // Only Friday counts
    }
    
    @Test("DaysOfWeek habit respects schedule")
    func daysOfWeekHabitSchedule() {
        let useCase = CalculateCurrentStreak()
        // Monday, Wednesday, Friday habit (1, 3, 5 in habit format)
        let habit = createHabit(schedule: .daysOfWeek([1, 3, 5]))
        let logs = [
            createLog(date: friday),     // Friday (scheduled)
            createLog(date: thursday),   // Thursday (not scheduled - should be ignored)
            createLog(date: wednesday),  // Wednesday (scheduled)
            createLog(date: tuesday),    // Tuesday (not scheduled - should be ignored)
            createLog(date: monday)      // Monday (scheduled)
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 3) // Monday, Wednesday, Friday
    }
    
    @Test("DaysOfWeek habit missing scheduled day breaks streak")
    func daysOfWeekHabitMissedDay() {
        let useCase = CalculateCurrentStreak()
        let habit = createHabit(schedule: .daysOfWeek([1, 3, 5])) // Mon, Wed, Fri
        let logs = [
            createLog(date: friday),     // Friday (scheduled)
            // Missing Wednesday (scheduled day)
            createLog(date: monday)      // Monday (scheduled)
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 1) // Only Friday counts, streak broken by missing Wednesday
    }
    
    @Test("TimesPerWeek habit tracks weekly completion")
    func timesPerWeekHabit() {
        let useCase = CalculateCurrentStreak()
        let habit = createHabit(schedule: .timesPerWeek(3))
        let logs = [
            // This week (3 logs - meets target)
            createLog(date: friday),
            createLog(date: wednesday),
            createLog(date: monday),
            // Previous week (3 logs - meets target)
            createLog(date: Self.testCalendar.date(byAdding: .day, value: -7, to: friday)!),
            createLog(date: Self.testCalendar.date(byAdding: .day, value: -7, to: wednesday)!),
            createLog(date: Self.testCalendar.date(byAdding: .day, value: -7, to: monday)!)
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 2) // Two weeks meeting target
    }
    
    @Test("TimesPerWeek habit insufficient logs breaks streak")
    func timesPerWeekInsufficientLogs() {
        let useCase = CalculateCurrentStreak()
        let habit = createHabit(schedule: .timesPerWeek(3))
        let logs = [
            // This week (only 2 logs - doesn't meet target of 3)
            createLog(date: friday),
            createLog(date: wednesday),
            // Previous week (3 logs - meets target)
            createLog(date: Self.testCalendar.date(byAdding: .day, value: -7, to: friday)!),
            createLog(date: Self.testCalendar.date(byAdding: .day, value: -7, to: wednesday)!),
            createLog(date: Self.testCalendar.date(byAdding: .day, value: -7, to: monday)!)
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 0) // Current week doesn't meet target, so no streak
    }
    
    @Test("Numeric habit requires meeting daily target")
    func numericHabitDailyTarget() {
        let useCase = CalculateCurrentStreak()
        let habit = createHabit(schedule: .daily, kind: .numeric)
        let logs = [
            createLog(date: friday, value: 12.0),     // Meets target (10)
            createLog(date: thursday, value: 8.0),    // Doesn't meet target
            createLog(date: wednesday, value: 15.0)   // Meets target
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 1) // Only Friday meets target
    }
    
    @Test("Empty logs returns zero streak")
    func emptyLogsZeroStreak() {
        let useCase = CalculateCurrentStreak()
        let habit = createHabit(schedule: .daily)
        let logs: [HabitLog] = []
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 0)
    }
    
    // MARK: - First Weekday Testing
    
    @Test("TimesPerWeek habit respects system first weekday - Sunday start")
    func timesPerWeekSundayFirstWeekday() {
        let useCase = CalculateCurrentStreak()
        let habit = createHabit(schedule: .timesPerWeek(2))
        
        // Create logs spanning Sunday-Saturday week
        let logs = [
            createLog(date: sunday),     // End of week
            createLog(date: saturday),   // Second log of week
            // Previous week (Sunday start)
            createLog(date: Self.testCalendar.date(byAdding: .day, value: -7, to: sunday)!),
            createLog(date: Self.testCalendar.date(byAdding: .day, value: -7, to: friday)!)
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: sunday)
        #expect(streak == 2) // Both weeks should meet target regardless of first weekday
    }
    
    @Test("TimesPerWeek habit respects system first weekday - Monday start")
    func timesPerWeekMondayFirstWeekday() {
        let useCase = CalculateCurrentStreak()
        let habit = createHabit(schedule: .timesPerWeek(2))
        
        // Create logs spanning Monday-Sunday week
        let logs = [
            createLog(date: sunday),     // End of week
            createLog(date: wednesday),  // Second log of week
            // Previous week (Monday start)
            createLog(date: Self.testCalendar.date(byAdding: .day, value: -7, to: sunday)!),
            createLog(date: Self.testCalendar.date(byAdding: .day, value: -7, to: wednesday)!)
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: sunday)
        #expect(streak == 2) // Both weeks should meet target
    }
    
    // MARK: - Week Boundary Edge Cases
    
    @Test("Week boundary transition maintains streak accuracy")
    func weekBoundaryTransition() {
        let useCase = CalculateCurrentStreak()
        let habit = createHabit(schedule: .timesPerWeek(1))
        
        // Test transition from one week to next
        let lastDayOfWeek = sunday
        let firstDayOfNextWeek = nextMonday
        
        let logs = [
            createLog(date: firstDayOfNextWeek), // New week
            createLog(date: lastDayOfWeek)       // Previous week
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: firstDayOfNextWeek)
        #expect(streak == 2) // Both weeks meet target of 1
    }
    
    @Test("DaysOfWeek habit handles week transitions correctly")
    func daysOfWeekWeekTransition() {
        let useCase = CalculateCurrentStreak()
        let habit = createHabit(schedule: .daysOfWeek([1, 7])) // Monday and Sunday
        
        let logs = [
            createLog(date: nextMonday),  // Monday of new week
            createLog(date: sunday),      // Sunday of previous week  
            createLog(date: monday)       // Monday of previous week
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: nextMonday)
        #expect(streak == 3) // All scheduled days completed
    }
    
    // MARK: - CalculateBestStreakUseCase Tests
    
    @Test("Best streak finds longest consecutive sequence")
    func bestStreakConsecutiveSequence() {
        let useCase = CalculateBestStreak()
        let habit = createHabit(schedule: .daily)
        let logs = [
            createLog(date: nextTuesday),  // Isolated day
            createLog(date: friday),       // End of 3-day streak
            createLog(date: thursday),     // Middle of 3-day streak  
            createLog(date: wednesday),    // Start of 3-day streak
            createLog(date: monday)        // Isolated day
        ]
        
        let bestStreak = useCase.execute(habit: habit, logs: logs)
        #expect(bestStreak == 3) // Wed-Thu-Fri streak
    }
    
    @Test("Best streak handles single day")
    func bestStreakSingleDay() {
        let useCase = CalculateBestStreak()
        let habit = createHabit(schedule: .daily)
        let logs = [createLog(date: monday)]
        
        let bestStreak = useCase.execute(habit: habit, logs: logs)
        #expect(bestStreak == 1)
    }
    
    @Test("Best streak handles no logs")
    func bestStreakNoLogs() {
        let useCase = CalculateBestStreak()
        let habit = createHabit(schedule: .daily)
        let logs: [HabitLog] = []
        
        let bestStreak = useCase.execute(habit: habit, logs: logs)
        #expect(bestStreak == 0)
    }
    
    @Test("Best streak ignores non-compliant logs for numeric habit")
    func bestStreakNumericHabitCompliance() {
        let useCase = CalculateBestStreak()
        let habit = createHabit(schedule: .daily, kind: .numeric)
        let logs = [
            createLog(date: friday, value: 12.0),     // Compliant
            createLog(date: thursday, value: 5.0),    // Non-compliant (< 10)
            createLog(date: wednesday, value: 15.0),  // Compliant
            createLog(date: tuesday, value: 10.0),    // Compliant (meets exactly)
            createLog(date: monday, value: 8.0)       // Non-compliant
        ]
        
        let bestStreak = useCase.execute(habit: habit, logs: logs)
        #expect(bestStreak == 2) // Wed-Tue consecutive compliant days
    }
    
    @Test("Best streak handles duplicate dates correctly")
    func bestStreakDuplicateDates() {
        let useCase = CalculateBestStreak()
        let habit = createHabit(schedule: .daily)
        let logs = [
            createLog(date: friday, value: 1.0),
            createLog(date: friday, value: 1.0),    // Duplicate date
            createLog(date: thursday, value: 1.0),
            createLog(date: wednesday, value: 1.0)
        ]
        
        let bestStreak = useCase.execute(habit: habit, logs: logs)
        #expect(bestStreak == 3) // Wed-Thu-Fri (duplicates handled)
    }
    
    // MARK: - Edge Cases
    
    @Test("Weekday conversion handles Sunday correctly")
    func weekdayConversionSunday() {
        let useCase = CalculateCurrentStreak()
        let habit = createHabit(schedule: .daysOfWeek([7])) // Sunday in habit format
        let logs = [createLog(date: sunday)]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: sunday)
        #expect(streak == 1) // Sunday should be recognized correctly
    }
    
    @Test("Weekday conversion handles Monday correctly")
    func weekdayConversionMonday() {
        let useCase = CalculateCurrentStreak()
        let habit = createHabit(schedule: .daysOfWeek([1])) // Monday in habit format
        let logs = [createLog(date: monday)]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: monday)
        #expect(streak == 1) // Monday should be recognized correctly
    }
    
    @Test("Binary habit with zero value is not compliant")
    func binaryHabitZeroValue() {
        let useCase = CalculateCurrentStreak()
        let habit = createHabit(schedule: .daily, kind: .binary)
        let logs = [
            createLog(date: friday, value: 1.0),  // Compliant
            createLog(date: thursday, value: 0.0) // Not compliant
        ]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 1) // Only Friday is compliant
    }
    
    @Test("Numeric habit with nil value defaults to zero")
    func numericHabitNilValue() {
        let useCase = CalculateCurrentStreak()
        let habit = createHabit(schedule: .daily, kind: .numeric)
        var log = createLog(date: friday)
        log.value = nil // Explicitly set to nil
        let logs = [log]
        
        let streak = useCase.execute(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 0) // nil defaults to 0, which doesn't meet target of 10
    }
}