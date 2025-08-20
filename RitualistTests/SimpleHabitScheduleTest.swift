//
//  SimpleHabitScheduleTest.swift
//  RitualistTests
//
//  Created by Claude on 16.08.2025.
//

import Testing
import Foundation
@testable import Ritualist
import RitualistCore

struct SimpleHabitScheduleTest {
    
    @Test("TimesPerWeek schedule behavior verification")
    func timesPerWeekScheduleBehavior() {
        let calendar = DateUtils.userCalendar()
        let testDate = calendar.date(from: DateComponents(year: 2025, month: 8, day: 16))! // Today
        
        // Test different timesPerWeek values
        let schedules = [
            HabitSchedule.timesPerWeek(1),
            HabitSchedule.timesPerWeek(3),
            HabitSchedule.timesPerWeek(7)
        ]
        
        for schedule in schedules {
            let isActive = schedule.isActiveOn(date: testDate)
            print("Schedule \(schedule) on \(testDate): isActive = \(isActive)")
            
            // CURRENT EXPECTATION: TimesPerWeek should return true (flexible scheduling)
            // This allows users to log the habit on any day of the week
            #expect(isActive == true, "TimesPerWeek schedule should allow logging on any day")
        }
    }
    
    @Test("Daily schedule comparison")
    func dailyScheduleComparison() {
        let calendar = DateUtils.userCalendar()
        let testDate = calendar.date(from: DateComponents(year: 2025, month: 8, day: 16))!
        
        let dailySchedule = HabitSchedule.daily
        let timesPerWeekSchedule = HabitSchedule.timesPerWeek(7)
        
        let dailyActive = dailySchedule.isActiveOn(date: testDate)
        let timesPerWeekActive = timesPerWeekSchedule.isActiveOn(date: testDate)
        
        print("Daily schedule active: \(dailyActive)")
        print("TimesPerWeek(7) schedule active: \(timesPerWeekActive)")
        
        // Both should return true for any given day
        #expect(dailyActive == true)
        #expect(timesPerWeekActive == true)
        
        // They should behave the same for isActiveOn() - the difference is in completion logic
        #expect(dailyActive == timesPerWeekActive, "Daily and TimesPerWeek(7) should have same isActiveOn behavior")
    }
    
    @Test("DaysOfWeek schedule comparison")
    func daysOfWeekScheduleComparison() {
        let calendar = DateUtils.userCalendar()
        let friday = calendar.date(from: DateComponents(year: 2025, month: 8, day: 15))! // Friday, August 15, 2025
        
        // Friday only schedule (5 in habit weekday format)
        let fridayOnlySchedule = HabitSchedule.daysOfWeek([5])
        let timesPerWeekSchedule = HabitSchedule.timesPerWeek(1)
        
        let fridayOnlyActive = fridayOnlySchedule.isActiveOn(date: friday)
        let timesPerWeekActive = timesPerWeekSchedule.isActiveOn(date: friday)
        
        print("Friday-only schedule active on Friday: \(fridayOnlyActive)")
        print("TimesPerWeek(1) schedule active on Friday: \(timesPerWeekActive)")
        
        // Friday-only should be true on Friday
        #expect(fridayOnlyActive == true)
        // TimesPerWeek should be true on any day (flexible)
        #expect(timesPerWeekActive == true)
    }
}
