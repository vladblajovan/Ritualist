//
//  StreakCalculationServiceTests.swift
//  RitualistTests
//
//  Created by Claude on 16.08.2025.
//

import Testing
import Foundation
@testable import Ritualist
@testable import RitualistCore

struct StreakCalculationServiceTests {
    
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
    let nextWednesday = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 13))!
    
    // Previous week
    let prevMonday = Self.testCalendar.date(from: DateComponents(year: 2025, month: 7, day: 28))!
    let prevWednesday = Self.testCalendar.date(from: DateComponents(year: 2025, month: 7, day: 30))!
    let prevFriday = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 1))!
    
    func createService() -> StreakCalculationService {
        let habitCompletionService = DefaultHabitCompletionService()
        return DefaultStreakCalculationService(
            habitCompletionService: habitCompletionService,
            calendar: Self.testCalendar
        )
    }
    
    func createHabit(schedule: HabitSchedule, kind: HabitKind = .binary, startDate: Date? = nil) -> Habit {
        Habit(
            id: UUID(),
            name: "Test Habit",
            emoji: "🎯",
            kind: kind,
            dailyTarget: kind == .numeric ? 10.0 : nil,
            schedule: schedule,
            reminders: [],
            startDate: startDate ?? Self.testCalendar.date(from: DateComponents(year: 2025, month: 7, day: 1))!
        )
    }
    
    func createLog(date: Date, value: Double = 1.0, habitID: UUID = UUID()) -> HabitLog {
        HabitLog(
            id: UUID(),
            habitID: habitID,
            date: date,
            value: value
        )
    }
    
    // MARK: - Daily Schedule Tests
    
    @Test("Daily habit current streak - consecutive days")
    func dailyHabitCurrentStreakConsecutive() {
        let service = createService()
        let habit = createHabit(schedule: .daily)
        let logs = [
            createLog(date: friday, habitID: habit.id),     // Day 3
            createLog(date: thursday, habitID: habit.id),   // Day 2
            createLog(date: wednesday, habitID: habit.id)   // Day 1
        ]
        
        let streak = service.calculateCurrentStreak(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 3)
    }
    
    @Test("Daily habit current streak - gap breaks streak")
    func dailyHabitCurrentStreakWithGap() {
        let service = createService()
        let habit = createHabit(schedule: .daily)
        let logs = [
            createLog(date: friday, habitID: habit.id),     // Today
            createLog(date: wednesday, habitID: habit.id),  // Gap on Thursday
            createLog(date: tuesday, habitID: habit.id),
            createLog(date: monday, habitID: habit.id)
        ]
        
        let streak = service.calculateCurrentStreak(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 1) // Only Friday counts
    }
    
    @Test("Daily habit longest streak - finds maximum consecutive")
    func dailyHabitLongestStreak() {
        let service = createService()
        let habit = createHabit(schedule: .daily)
        let logs = [
            createLog(date: nextTuesday, habitID: habit.id),  // Isolated day
            createLog(date: friday, habitID: habit.id),       // End of 3-day streak
            createLog(date: thursday, habitID: habit.id),     // Middle of 3-day streak  
            createLog(date: wednesday, habitID: habit.id),    // Start of 3-day streak
            createLog(date: monday, habitID: habit.id)        // Isolated day
        ]
        
        let longestStreak = service.calculateLongestStreak(habit: habit, logs: logs)
        #expect(longestStreak == 3) // Wed-Thu-Fri streak
    }
    
    // MARK: - DaysOfWeek Schedule Tests
    
    @Test("DaysOfWeek habit current streak - respects schedule")
    func daysOfWeekHabitCurrentStreakRespectSchedule() {
        let service = createService()
        // Monday, Wednesday, Friday habit (1, 3, 5 in habit format)
        let habit = createHabit(schedule: .daysOfWeek([1, 3, 5]))
        let logs = [
            createLog(date: friday, habitID: habit.id),     // Friday (scheduled)
            createLog(date: thursday, habitID: habit.id),   // Thursday (not scheduled - should be ignored)
            createLog(date: wednesday, habitID: habit.id),  // Wednesday (scheduled)
            createLog(date: tuesday, habitID: habit.id),    // Tuesday (not scheduled - should be ignored)
            createLog(date: monday, habitID: habit.id)      // Monday (scheduled)
        ]
        
        let streak = service.calculateCurrentStreak(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 3) // Monday, Wednesday, Friday
    }
    
    @Test("DaysOfWeek habit current streak - missing scheduled day breaks streak")
    func daysOfWeekHabitCurrentStreakMissedDay() {
        let service = createService()
        let habit = createHabit(schedule: .daysOfWeek([1, 3, 5])) // Mon, Wed, Fri
        let logs = [
            createLog(date: friday, habitID: habit.id),     // Friday (scheduled)
            // Missing Wednesday (scheduled day)
            createLog(date: monday, habitID: habit.id)      // Monday (scheduled)
        ]
        
        let streak = service.calculateCurrentStreak(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 1) // Only Friday counts, streak broken by missing Wednesday
    }
    
    @Test("DaysOfWeek habit longest streak - considers only scheduled days")
    func daysOfWeekHabitLongestStreak() {
        let service = createService()
        let habit = createHabit(schedule: .daysOfWeek([1, 3, 5])) // Mon, Wed, Fri
        let logs = [
            // Week 2: Complete week
            createLog(date: nextMonday, habitID: habit.id),
            createLog(date: nextWednesday, habitID: habit.id),
            createLog(date: Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 15))!, habitID: habit.id), // Next Friday
            // Week 1: Complete week  
            createLog(date: monday, habitID: habit.id),
            createLog(date: wednesday, habitID: habit.id),
            createLog(date: friday, habitID: habit.id),
            // Previous week: Complete week
            createLog(date: prevMonday, habitID: habit.id),
            createLog(date: prevWednesday, habitID: habit.id),
            createLog(date: prevFriday, habitID: habit.id),
            // Non-scheduled days (should be ignored)
            createLog(date: tuesday, habitID: habit.id),
            createLog(date: thursday, habitID: habit.id)
        ]
        
        let longestStreak = service.calculateLongestStreak(habit: habit, logs: logs)
        #expect(longestStreak == 9) // 3 weeks × 3 days each = 9 consecutive scheduled days
    }
    
    // MARK: - TimesPerWeek Schedule Tests
    
    @Test("TimesPerWeek habit current streak - tracks weekly completion")
    func timesPerWeekHabitCurrentStreakWeekly() {
        let service = createService()
        let habit = createHabit(schedule: .timesPerWeek(3))
        let logs = [
            // This week (3 logs - meets target)
            createLog(date: friday, habitID: habit.id),
            createLog(date: wednesday, habitID: habit.id),
            createLog(date: monday, habitID: habit.id),
            // Previous week (3 logs - meets target)
            createLog(date: Self.testCalendar.date(byAdding: .day, value: -7, to: friday)!, habitID: habit.id),
            createLog(date: Self.testCalendar.date(byAdding: .day, value: -7, to: wednesday)!, habitID: habit.id),
            createLog(date: Self.testCalendar.date(byAdding: .day, value: -7, to: monday)!, habitID: habit.id)
        ]
        
        let streak = service.calculateCurrentStreak(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 2) // Two weeks meeting target
    }
    
    @Test("TimesPerWeek habit current streak - insufficient logs breaks streak")
    func timesPerWeekHabitCurrentStreakInsufficient() {
        let service = createService()
        let habit = createHabit(schedule: .timesPerWeek(3))
        let logs = [
            // This week (only 2 logs - doesn't meet target of 3)
            createLog(date: friday, habitID: habit.id),
            createLog(date: wednesday, habitID: habit.id),
            // Previous week (3 logs - meets target)
            createLog(date: Self.testCalendar.date(byAdding: .day, value: -7, to: friday)!, habitID: habit.id),
            createLog(date: Self.testCalendar.date(byAdding: .day, value: -7, to: wednesday)!, habitID: habit.id),
            createLog(date: Self.testCalendar.date(byAdding: .day, value: -7, to: monday)!, habitID: habit.id)
        ]
        
        let streak = service.calculateCurrentStreak(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 0) // Current week doesn't meet target, so no streak
    }
    
    @Test("TimesPerWeek habit longest streak - finds maximum consecutive weeks")
    func timesPerWeekHabitLongestStreak() {
        let service = createService()
        let habit = createHabit(schedule: .timesPerWeek(2))
        
        // Create logs spanning multiple weeks with varying completion rates
        var logs: [HabitLog] = []
        
        // Week 1: 3 completions (meets target)
        logs.append(createLog(date: Self.testCalendar.date(from: DateComponents(year: 2025, month: 7, day: 7))!, habitID: habit.id))
        logs.append(createLog(date: Self.testCalendar.date(from: DateComponents(year: 2025, month: 7, day: 9))!, habitID: habit.id))
        logs.append(createLog(date: Self.testCalendar.date(from: DateComponents(year: 2025, month: 7, day: 11))!, habitID: habit.id))
        
        // Week 2: 2 completions (meets target)
        logs.append(createLog(date: Self.testCalendar.date(from: DateComponents(year: 2025, month: 7, day: 14))!, habitID: habit.id))
        logs.append(createLog(date: Self.testCalendar.date(from: DateComponents(year: 2025, month: 7, day: 16))!, habitID: habit.id))
        
        // Week 3: 2 completions (meets target)
        logs.append(createLog(date: Self.testCalendar.date(from: DateComponents(year: 2025, month: 7, day: 21))!, habitID: habit.id))
        logs.append(createLog(date: Self.testCalendar.date(from: DateComponents(year: 2025, month: 7, day: 23))!, habitID: habit.id))
        
        // Week 4: 1 completion (doesn't meet target)
        logs.append(createLog(date: Self.testCalendar.date(from: DateComponents(year: 2025, month: 7, day: 28))!, habitID: habit.id))
        
        // Week 5: 2 completions (meets target) 
        logs.append(createLog(date: monday, habitID: habit.id))
        logs.append(createLog(date: wednesday, habitID: habit.id))
        
        let longestStreak = service.calculateLongestStreak(habit: habit, logs: logs)
        #expect(longestStreak == 3) // Weeks 1, 2, 3 consecutive
    }
    
    // MARK: - Numeric Habit Tests
    
    @Test("Numeric habit current streak - requires meeting daily target")
    func numericHabitCurrentStreakDailyTarget() {
        let service = createService()
        let habit = createHabit(schedule: .daily, kind: .numeric)
        let logs = [
            createLog(date: friday, value: 12.0, habitID: habit.id),     // Meets target (10)
            createLog(date: thursday, value: 8.0, habitID: habit.id),    // Doesn't meet target
            createLog(date: wednesday, value: 15.0, habitID: habit.id)   // Meets target
        ]
        
        let streak = service.calculateCurrentStreak(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 1) // Only Friday meets target
    }
    
    @Test("Numeric habit longest streak - ignores non-compliant logs")
    func numericHabitLongestStreakCompliance() {
        let service = createService()
        let habit = createHabit(schedule: .daily, kind: .numeric)
        let logs = [
            createLog(date: friday, value: 12.0, habitID: habit.id),     // Compliant
            createLog(date: thursday, value: 5.0, habitID: habit.id),    // Non-compliant (< 10)
            createLog(date: wednesday, value: 15.0, habitID: habit.id),  // Compliant
            createLog(date: tuesday, value: 10.0, habitID: habit.id),    // Compliant (meets exactly)
            createLog(date: monday, value: 8.0, habitID: habit.id)       // Non-compliant
        ]
        
        let longestStreak = service.calculateLongestStreak(habit: habit, logs: logs)
        #expect(longestStreak == 2) // Wed-Tue consecutive compliant days
    }
    
    // MARK: - Edge Cases
    
    @Test("Empty logs returns zero streak")
    func emptyLogsZeroStreak() {
        let service = createService()
        let habit = createHabit(schedule: .daily)
        let logs: [HabitLog] = []
        
        let currentStreak = service.calculateCurrentStreak(habit: habit, logs: logs, asOf: friday)
        let longestStreak = service.calculateLongestStreak(habit: habit, logs: logs)
        
        #expect(currentStreak == 0)
        #expect(longestStreak == 0)
    }
    
    @Test("Single day returns streak of one")
    func singleDayStreakOfOne() {
        let service = createService()
        let habit = createHabit(schedule: .daily)
        let logs = [createLog(date: friday, habitID: habit.id)]
        
        let currentStreak = service.calculateCurrentStreak(habit: habit, logs: logs, asOf: friday)
        let longestStreak = service.calculateLongestStreak(habit: habit, logs: logs)
        
        #expect(currentStreak == 1)
        #expect(longestStreak == 1)
    }
    
    @Test("Binary habit with zero value is not compliant")
    func binaryHabitZeroValueNotCompliant() {
        let service = createService()
        let habit = createHabit(schedule: .daily, kind: .binary)
        let logs = [
            createLog(date: friday, value: 1.0, habitID: habit.id),  // Compliant
            createLog(date: thursday, value: 0.0, habitID: habit.id) // Not compliant
        ]
        
        let streak = service.calculateCurrentStreak(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 1) // Only Friday is compliant
    }
    
    @Test("Numeric habit with nil value defaults to zero")
    func numericHabitNilValueDefaultsZero() {
        let service = createService()
        let habit = createHabit(schedule: .daily, kind: .numeric)
        var log = createLog(date: friday, habitID: habit.id)
        log.value = nil // Explicitly set to nil
        let logs = [log]
        
        let streak = service.calculateCurrentStreak(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 0) // nil defaults to 0, which doesn't meet target of 10
    }
    
    @Test("Habit start date limits streak calculation")
    func habitStartDateLimitsStreak() {
        let service = createService()
        let habit = createHabit(schedule: .daily, startDate: wednesday)
        let logs = [
            createLog(date: friday, habitID: habit.id),     // Day 3 of habit
            createLog(date: thursday, habitID: habit.id),   // Day 2 of habit
            createLog(date: wednesday, habitID: habit.id),  // Day 1 of habit (start date)
            createLog(date: tuesday, habitID: habit.id),    // Before habit start (should be ignored)
            createLog(date: monday, habitID: habit.id)      // Before habit start (should be ignored)
        ]
        
        let streak = service.calculateCurrentStreak(habit: habit, logs: logs, asOf: friday)
        #expect(streak == 3) // Only count from Wednesday onwards
    }
    
    // MARK: - Next Scheduled Date Tests
    
    @Test("Daily habit next scheduled date is next day")
    func dailyHabitNextScheduledDate() {
        let service = createService()
        let habit = createHabit(schedule: .daily)
        
        let nextDate = service.getNextScheduledDate(habit: habit, after: friday)
        #expect(nextDate == saturday)
    }
    
    @Test("DaysOfWeek habit next scheduled date respects schedule")
    func daysOfWeekHabitNextScheduledDate() {
        let service = createService()
        let habit = createHabit(schedule: .daysOfWeek([1, 3])) // Monday and Wednesday
        
        // After Friday, next scheduled day should be Monday
        let nextDate = service.getNextScheduledDate(habit: habit, after: friday)
        #expect(nextDate == nextMonday)
    }
    
    @Test("TimesPerWeek habit next scheduled date is next day")
    func timesPerWeekHabitNextScheduledDate() {
        let service = createService()
        let habit = createHabit(schedule: .timesPerWeek(3))
        
        // For timesPerWeek, any day is scheduled
        let nextDate = service.getNextScheduledDate(habit: habit, after: friday)
        #expect(nextDate == saturday)
    }
    
    @Test("Habit with end date returns nil after end")
    func habitWithEndDateReturnsNilAfterEnd() {
        let service = createService()
        var habit = createHabit(schedule: .daily)
        habit.endDate = thursday // End before Friday
        
        let nextDate = service.getNextScheduledDate(habit: habit, after: friday)
        #expect(nextDate == nil)
    }
    
    // MARK: - Streak Break Dates Tests
    
    @Test("Daily habit streak break dates identifies missed days")
    func dailyHabitStreakBreakDates() {
        let service = createService()
        let habit = createHabit(schedule: .daily, startDate: monday)
        let logs = [
            createLog(date: friday, habitID: habit.id),
            createLog(date: wednesday, habitID: habit.id),
            createLog(date: monday, habitID: habit.id)
            // Missing Tuesday and Thursday
        ]
        
        let breakDates = service.getStreakBreakDates(habit: habit, logs: logs, asOf: friday)
        let expectedBreaks = [tuesday, thursday]
        
        #expect(breakDates.count == 2)
        #expect(breakDates.contains(tuesday))
        #expect(breakDates.contains(thursday))
    }
    
    @Test("DaysOfWeek habit streak break dates respects schedule")
    func daysOfWeekHabitStreakBreakDates() {
        let service = createService()
        let habit = createHabit(schedule: .daysOfWeek([1, 3, 5]), startDate: monday) // Mon, Wed, Fri
        let logs = [
            createLog(date: friday, habitID: habit.id),
            createLog(date: monday, habitID: habit.id)
            // Missing Wednesday (scheduled), but Tuesday and Thursday are not scheduled
        ]
        
        let breakDates = service.getStreakBreakDates(habit: habit, logs: logs, asOf: friday)
        
        #expect(breakDates.count == 1)
        #expect(breakDates.contains(wednesday))
        #expect(!breakDates.contains(tuesday)) // Not scheduled
        #expect(!breakDates.contains(thursday)) // Not scheduled
    }
    
    @Test("TimesPerWeek habit streak break tracking")
    func timesPerWeekHabitStreakBreakDates() {
        let service = createService()
        let habit = createHabit(schedule: .timesPerWeek(3), startDate: monday)
        let logs = [
            createLog(date: friday, habitID: habit.id),
            createLog(date: wednesday, habitID: habit.id)
            // Only 2 logs this week, but timesPerWeek habits track differently
        ]
        
        // For timesPerWeek habits, break dates concept is different:
        // If weekly target isn't met (2 logs < 3 target), ALL days in that week are considered "breaks"
        // because the habit uses weekly completion logic, not daily
        let breakDates = service.getStreakBreakDates(habit: habit, logs: logs, asOf: friday)
        
        // Since weekly target (3) isn't met with only 2 logs, all days in the week are break dates
        // This is the current behavior - timesPerWeek habits track weekly success, not daily
        #expect(breakDates.contains(monday))
        #expect(breakDates.contains(tuesday))
        #expect(breakDates.contains(wednesday)) // Even with log, week target not met
        #expect(breakDates.contains(thursday))
        #expect(breakDates.contains(friday)) // Even with log, week target not met
    }
}