//
//  HabitScheduleTests.swift
//  RitualistTests
//
//  Created by Claude on 16.08.2025.
//

import Testing
import Foundation
@testable import Ritualist
import RitualistCore

struct HabitScheduleTests {
    
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
    
    // MARK: - HabitSchedule.isActiveOn() Tests
    
    @Test("Daily schedule is active on all days")
    func dailyScheduleActiveAllDays() {
        let schedule = HabitSchedule.daily
        let testDates = [Self.monday, Self.tuesday, Self.wednesday, Self.thursday, Self.friday, Self.saturday, Self.sunday]
        
        for date in testDates {
            let isActive = schedule.isActiveOn(date: date)
            #expect(isActive == true, "Daily schedule should be active on \(date)")
        }
    }
    
    @Test("DaysOfWeek schedule is active only on specified days")
    func daysOfWeekScheduleOnlySpecifiedDays() {
        // Monday, Wednesday, Friday (1, 3, 5 in habit weekday format)
        let schedule = HabitSchedule.daysOfWeek([1, 3, 5])
        
        #expect(schedule.isActiveOn(date: Self.monday) == true, "Should be active on Monday")
        #expect(schedule.isActiveOn(date: Self.tuesday) == false, "Should NOT be active on Tuesday")
        #expect(schedule.isActiveOn(date: Self.wednesday) == true, "Should be active on Wednesday")
        #expect(schedule.isActiveOn(date: Self.thursday) == false, "Should NOT be active on Thursday")
        #expect(schedule.isActiveOn(date: Self.friday) == true, "Should be active on Friday")
        #expect(schedule.isActiveOn(date: Self.saturday) == false, "Should NOT be active on Saturday")
        #expect(schedule.isActiveOn(date: Self.sunday) == false, "Should NOT be active on Sunday")
    }
    
    @Test("TimesPerWeek schedule current behavior")
    func timesPerWeekCurrentBehavior() {
        let schedules = [
            HabitSchedule.timesPerWeek(1),
            HabitSchedule.timesPerWeek(3),
            HabitSchedule.timesPerWeek(7)
        ]
        
        let testDates = [Self.monday, Self.tuesday, Self.wednesday, Self.thursday, Self.friday, Self.saturday, Self.sunday]
        
        for schedule in schedules {
            for date in testDates {
                let isActive = schedule.isActiveOn(date: date)
                // Document current behavior - what does it actually return?
                print("TimesPerWeek schedule \(schedule) on \(date): \(isActive)")
                
                // The question is: should this be true for all days (flexible scheduling) 
                // or should it somehow limit which days are active?
                // Based on examination, it should be true (flexible scheduling)
                #expect(isActive == true, "TimesPerWeek should allow logging any day (flexible scheduling)")
            }
        }
    }
    
    // MARK: - Integration Tests with UseCases
    
    // Note: IsHabitActiveOnDate UseCase test removed - checking directly with HabitSchedule.isActiveOn() instead
    
    @Test("CheckWeeklyTarget UseCase behavior")
    func checkWeeklyTargetUseCase() {
        let useCase = CheckWeeklyTarget()
        let habit = createTestHabit(schedule: .timesPerWeek(3))
        
        // Test with 2 logs in the week (should not meet target of 3)
        let logs2 = [
            Self.monday: 1.0,
            Self.wednesday: 1.0
        ]
        let result2 = useCase.execute(date: Self.friday, habit: habit, habitLogValues: logs2, userProfile: nil)
        #expect(result2 == false, "Should not meet weekly target with 2/3 logs")
        
        // Test with 3 logs in the week (should meet target of 3)
        let logs3 = [
            Self.monday: 1.0,
            Self.wednesday: 1.0,
            Self.friday: 1.0
        ]
        let result3 = useCase.execute(date: Self.friday, habit: habit, habitLogValues: logs3, userProfile: nil)
        #expect(result3 == true, "Should meet weekly target with 3/3 logs")
        
        // Test with 4 logs in the week (should exceed target)
        let logs4 = [
            Self.monday: 1.0,
            Self.tuesday: 1.0,
            Self.wednesday: 1.0,
            Self.friday: 1.0
        ]
        let result4 = useCase.execute(date: Self.friday, habit: habit, habitLogValues: logs4, userProfile: nil)
        #expect(result4 == true, "Should exceed weekly target with 4/3 logs")
    }
    
    // MARK: - Helper Methods
    
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