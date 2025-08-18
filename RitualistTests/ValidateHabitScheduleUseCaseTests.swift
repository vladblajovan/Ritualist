//
//  ValidateHabitScheduleUseCaseTests.swift
//  RitualistTests
//
//  Created by Claude on 16.08.2025.
//

import Testing
import Foundation
@testable import Ritualist
import RitualistCore

struct ValidateHabitScheduleUseCaseTests {
    
    // MARK: - Test Data Setup
    
    static let testCalendar = Calendar(identifier: .gregorian)
    
    // Create test dates for a full week (Monday = Aug 4, 2025)
    static let monday = testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 4))! // Monday
    static let tuesday = testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 5))! // Tuesday
    static let wednesday = testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 6))! // Wednesday
    static let thursday = testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 7))! // Thursday
    static let friday = testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 8))! // Friday
    static let saturday = testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 9))! // Saturday
    static let sunday = testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 10))! // Sunday
    
    // MARK: - Daily Schedule Tests
    
    @Test("Daily habit validation - should always be valid")
    func dailyHabitAlwaysValid() async throws {
        let useCase = createUseCase()
        let habit = createTestHabit(schedule: .daily)
        let testDates = [Self.monday, Self.tuesday, Self.wednesday, Self.thursday, Self.friday, Self.saturday, Self.sunday]
        
        for date in testDates {
            let result = try await useCase.execute(habit: habit, date: date)
            #expect(result.isValid == true, "Daily habit should be valid on \(date)")
            #expect(result.reason == nil, "Daily habit should not have a reason when valid")
            #expect(result.shouldDisableLogging == false, "Daily habit should not disable logging")
            #expect(result.userMessage == "", "Daily habit should have empty user message when valid")
        }
    }
    
    // MARK: - DaysOfWeek Schedule Tests
    
    @Test("DaysOfWeek habit validation - valid on scheduled days")
    func daysOfWeekHabitValidOnScheduledDays() async throws {
        let useCase = createUseCase()
        // Monday, Wednesday, Friday (1, 3, 5 in habit weekday format)
        let habit = createTestHabit(schedule: .daysOfWeek([1, 3, 5]))
        
        // Test valid days
        let validDays = [Self.monday, Self.wednesday, Self.friday]
        for date in validDays {
            let result = try await useCase.execute(habit: habit, date: date)
            #expect(result.isValid == true, "DaysOfWeek habit should be valid on \(date)")
            #expect(result.reason == nil, "Valid day should not have a reason")
            #expect(result.shouldDisableLogging == false, "Valid day should not disable logging")
            #expect(result.userMessage == "", "Valid day should have empty user message")
        }
    }
    
    @Test("DaysOfWeek habit validation - invalid on non-scheduled days")
    func daysOfWeekHabitInvalidOnNonScheduledDays() async throws {
        let useCase = createUseCase()
        // Monday, Wednesday, Friday (1, 3, 5 in habit weekday format)
        let habit = createTestHabit(schedule: .daysOfWeek([1, 3, 5]))
        
        // Test invalid days
        let invalidDays = [Self.tuesday, Self.thursday, Self.saturday, Self.sunday]
        for date in invalidDays {
            let result = try await useCase.execute(habit: habit, date: date)
            #expect(result.isValid == false, "DaysOfWeek habit should be invalid on \(date)")
            #expect(result.reason != nil, "Invalid day should have a reason")
            #expect(result.shouldDisableLogging == true, "Invalid day should disable logging")
            #expect(result.userMessage != "", "Invalid day should have a user message")
            
            // Check that the reason mentions the scheduled days
            let reason = result.reason!
            #expect(reason.contains("Monday") && reason.contains("Wednesday") && reason.contains("Friday"), 
                   "Reason should mention scheduled days: \(reason)")
        }
    }
    
    @Test("DaysOfWeek habit validation - single day schedule")
    func daysOfWeekHabitSingleDay() async throws {
        let useCase = createUseCase()
        // Only Monday (1 in habit weekday format)
        let habit = createTestHabit(schedule: .daysOfWeek([1]))
        
        // Valid day
        let result = try await useCase.execute(habit: habit, date: Self.monday)
        #expect(result.isValid == true, "Should be valid on Monday")
        
        // Invalid day
        let invalidResult = try await useCase.execute(habit: habit, date: Self.tuesday)
        #expect(invalidResult.isValid == false, "Should be invalid on Tuesday")
        #expect(invalidResult.reason?.contains("Monday") == true, "Should mention Monday in reason")
    }
    
    @Test("DaysOfWeek habit validation - two day schedule")
    func daysOfWeekHabitTwoDays() async throws {
        let useCase = createUseCase()
        // Monday and Friday (1, 5 in habit weekday format)
        let habit = createTestHabit(schedule: .daysOfWeek([1, 5]))
        
        // Valid days
        let mondayResult = try await useCase.execute(habit: habit, date: Self.monday)
        #expect(mondayResult.isValid == true, "Should be valid on Monday")
        
        let fridayResult = try await useCase.execute(habit: habit, date: Self.friday)
        #expect(fridayResult.isValid == true, "Should be valid on Friday")
        
        // Invalid day
        let invalidResult = try await useCase.execute(habit: habit, date: Self.wednesday)
        #expect(invalidResult.isValid == false, "Should be invalid on Wednesday")
        #expect(invalidResult.reason?.contains("Monday") == true && invalidResult.reason?.contains("Friday") == true, 
               "Should mention both Monday and Friday in reason")
    }
    
    // MARK: - TimesPerWeek Schedule Tests
    
    @Test("TimesPerWeek habit validation - should always be valid")
    func timesPerWeekHabitAlwaysValid() async throws {
        let useCase = createUseCase()
        let schedules = [
            HabitSchedule.timesPerWeek(1),
            HabitSchedule.timesPerWeek(3),
            HabitSchedule.timesPerWeek(7)
        ]
        let testDates = [Self.monday, Self.tuesday, Self.wednesday, Self.thursday, Self.friday, Self.saturday, Self.sunday]
        
        for schedule in schedules {
            let habit = createTestHabit(schedule: schedule)
            for date in testDates {
                let result = try await useCase.execute(habit: habit, date: date)
                #expect(result.isValid == true, "TimesPerWeek habit should be valid on \(date) with schedule \(schedule)")
                #expect(result.reason == nil, "TimesPerWeek habit should not have a reason when valid")
                #expect(result.shouldDisableLogging == false, "TimesPerWeek habit should not disable logging")
                #expect(result.userMessage == "", "TimesPerWeek habit should have empty user message when valid")
            }
        }
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test("Validation with different habit kinds")
    func validationWithDifferentHabitKinds() async throws {
        let useCase = createUseCase()
        let schedule = HabitSchedule.daysOfWeek([1]) // Monday only
        
        // Binary habit
        let binaryHabit = createTestHabit(schedule: schedule, kind: .binary)
        let binaryResult = try await useCase.execute(habit: binaryHabit, date: Self.monday)
        #expect(binaryResult.isValid == true, "Binary habit should be valid on scheduled day")
        
        // Numeric habit
        let numericHabit = createTestHabit(schedule: schedule, kind: .numeric)
        let numericResult = try await useCase.execute(habit: numericHabit, date: Self.monday)
        #expect(numericResult.isValid == true, "Numeric habit should be valid on scheduled day")
        
        // Both should be invalid on non-scheduled days
        let binaryInvalidResult = try await useCase.execute(habit: binaryHabit, date: Self.tuesday)
        #expect(binaryInvalidResult.isValid == false, "Binary habit should be invalid on non-scheduled day")
        
        let numericInvalidResult = try await useCase.execute(habit: numericHabit, date: Self.tuesday)
        #expect(numericInvalidResult.isValid == false, "Numeric habit should be invalid on non-scheduled day")
    }
    
    @Test("Validation with weekend edge cases")
    func validationWithWeekendEdgeCases() async throws {
        let useCase = createUseCase()
        
        // Weekend only habit (Saturday = 6, Sunday = 7 in habit weekday format)
        let weekendHabit = createTestHabit(schedule: .daysOfWeek([6, 7]))
        
        // Should be valid on weekends
        let saturdayResult = try await useCase.execute(habit: weekendHabit, date: Self.saturday)
        #expect(saturdayResult.isValid == true, "Should be valid on Saturday")
        
        let sundayResult = try await useCase.execute(habit: weekendHabit, date: Self.sunday)
        #expect(sundayResult.isValid == true, "Should be valid on Sunday")
        
        // Should be invalid on weekdays
        let mondayResult = try await useCase.execute(habit: weekendHabit, date: Self.monday)
        #expect(mondayResult.isValid == false, "Should be invalid on Monday")
        #expect(mondayResult.reason?.contains("Saturday") == true && mondayResult.reason?.contains("Sunday") == true,
               "Should mention both weekend days in reason")
    }
    
    @Test("Validation with all weekdays schedule")
    func validationWithAllWeekdaysSchedule() async throws {
        let useCase = createUseCase()
        
        // All weekdays habit (1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun)
        let allDaysHabit = createTestHabit(schedule: .daysOfWeek([1, 2, 3, 4, 5, 6, 7]))
        let testDates = [Self.monday, Self.tuesday, Self.wednesday, Self.thursday, Self.friday, Self.saturday, Self.sunday]
        
        for date in testDates {
            let result = try await useCase.execute(habit: allDaysHabit, date: date)
            #expect(result.isValid == true, "All-days habit should be valid on \(date)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createUseCase() -> ValidateHabitSchedule {
        let habitCompletionService = DefaultHabitCompletionService()
        return ValidateHabitSchedule(habitCompletionService: habitCompletionService)
    }
    
    private func createTestHabit(schedule: HabitSchedule, kind: HabitKind = .binary) -> Habit {
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
}