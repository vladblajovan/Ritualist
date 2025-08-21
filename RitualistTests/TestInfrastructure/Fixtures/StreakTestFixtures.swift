//
//  StreakTestFixtures.swift
//  RitualistTests
//
//  Created by Claude on 21.08.2025.
//

import Foundation
@testable import RitualistCore

/// Specialized fixtures for testing complex streak calculation patterns.
/// These fixtures complement the TestBuilders by providing pre-configured
/// multi-entity scenarios focused on streak testing edge cases.
public struct StreakTestFixtures {
    
    // MARK: - Complex Streak Patterns
    
    /// Creates a scenario with intermittent streaks across multiple months.
    /// Perfect for testing longest streak calculation across time gaps.
    public static func intermittentLongStreaks() -> StreakScenario {
        let habit = TestHabit.simpleBinaryHabit()
            .withName("Long Streak Test Habit")
            .startingDaysAgo(90)
            .build()
        
        var logs: [HabitLog] = []
        let baseDate = Calendar.current.date(byAdding: .day, value: -89, to: Date())!
        
        // First streak: 15 consecutive days (days 1-15)
        for day in 0..<15 {
            let date = Calendar.current.date(byAdding: .day, value: day, to: baseDate)!
            logs.append(TestHabitLog().withHabit(habit).withDate(date).build())
        }
        
        // Gap: 5 days (days 16-20)
        
        // Second streak: 21 consecutive days (days 21-41) - longest streak
        for day in 20..<41 {
            let date = Calendar.current.date(byAdding: .day, value: day, to: baseDate)!
            logs.append(TestHabitLog().withHabit(habit).withDate(date).build())
        }
        
        // Gap: 10 days (days 42-51)
        
        // Third streak: 12 consecutive days (days 52-63)
        for day in 51..<63 {
            let date = Calendar.current.date(byAdding: .day, value: day, to: baseDate)!
            logs.append(TestHabitLog().withHabit(habit).withDate(date).build())
        }
        
        // Recent streak: 8 consecutive days leading to today
        for day in 82..<90 {
            let date = Calendar.current.date(byAdding: .day, value: day, to: baseDate)!
            logs.append(TestHabitLog().withHabit(habit).withDate(date).build())
        }
        
        return StreakScenario(
            habit: habit,
            logs: logs,
            expectedCurrentStreak: 8,
            expectedLongestStreak: 21,
            description: "Multiple streaks with varying lengths and gaps"
        )
    }
    
    /// Creates a scenario with perfect streak leading to today.
    /// Tests current streak calculation accuracy.
    public static func perfectCurrentStreak(days: Int = 30) -> StreakScenario {
        let habit = TestHabit.simpleBinaryHabit()
            .withName("Perfect Streak Habit")
            .startingDaysAgo(days + 5)
            .build()
        
        var logs: [HabitLog] = []
        
        // Create perfect consecutive logs for specified days leading to today
        for dayOffset in (-days + 1)...0 {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
            logs.append(TestHabitLog().withHabit(habit).withDate(date).build())
        }
        
        return StreakScenario(
            habit: habit,
            logs: logs,
            expectedCurrentStreak: days,
            expectedLongestStreak: days,
            description: "Perfect \(days)-day current streak"
        )
    }
    
    /// Creates a scenario testing weekend-only habit streak calculation.
    /// Tests schedule-aware streak logic for daysOfWeek habits.
    public static func weekendOnlyStreaks() -> StreakScenario {
        let habit = TestHabit.simpleBinaryHabit()
            .withName("Weekend Activity")
            .forDaysOfWeek([1, 7]) // Sunday and Saturday (ISO weekday format)
            .startingDaysAgo(35)
            .build()
        
        var logs: [HabitLog] = []
        let today = Date()
        
        // Create logs for weekends only across 5 weeks
        for weekOffset in (-4)...0 {
            let weekStart = Calendar.current.date(byAdding: .weekOfYear, value: weekOffset, to: today)!
            let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: weekStart)!
            
            // Saturday (day 7 of week)
            if let saturday = Calendar.current.date(byAdding: .day, value: 6, to: weekInterval.start) {
                logs.append(TestHabitLog().withHabit(habit).withDate(saturday).build())
            }
            
            // Sunday (day 1 of week) 
            if let sunday = Calendar.current.date(byAdding: .day, value: 0, to: weekInterval.start) {
                // Skip one Sunday to create a streak break
                if weekOffset != -2 {
                    logs.append(TestHabitLog().withHabit(habit).withDate(sunday).build())
                }
            }
        }
        
        return StreakScenario(
            habit: habit,
            logs: logs,
            expectedCurrentStreak: 4, // 2 weekends = 4 scheduled days
            expectedLongestStreak: 6, // 3 consecutive weekends before the gap
            description: "Weekend-only habit with streak break"
        )
    }
    
    /// Creates a scenario testing timesPerWeek habit with varying weekly performance.
    /// Tests weekly completion threshold logic.
    public static func timesPerWeekVariablePerformance() -> StreakScenario {
        let habit = TestHabit.flexibleHabit()
            .withName("3x Per Week Activity")
            .forTimesPerWeek(3)
            .startingDaysAgo(35)
            .build()
        
        var logs: [HabitLog] = []
        let today = Date()
        
        // Week 1: 4 completions (exceeds target)
        let week1Start = Calendar.current.date(byAdding: .weekOfYear, value: -4, to: today)!
        let week1Interval = Calendar.current.dateInterval(of: .weekOfYear, for: week1Start)!
        for dayOffset in [1, 2, 4, 6] { // Monday, Tuesday, Thursday, Saturday
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: week1Interval.start)!
            logs.append(TestHabitLog().withHabit(habit).withDate(date).build())
        }
        
        // Week 2: 3 completions (meets target exactly)
        let week2Start = Calendar.current.date(byAdding: .weekOfYear, value: -3, to: today)!
        let week2Interval = Calendar.current.dateInterval(of: .weekOfYear, for: week2Start)!
        for dayOffset in [0, 3, 5] { // Sunday, Wednesday, Friday
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: week2Interval.start)!
            logs.append(TestHabitLog().withHabit(habit).withDate(date).build())
        }
        
        // Week 3: 2 completions (below target - breaks streak)
        let week3Start = Calendar.current.date(byAdding: .weekOfYear, value: -2, to: today)!
        let week3Interval = Calendar.current.dateInterval(of: .weekOfYear, for: week3Start)!
        for dayOffset in [1, 4] { // Monday, Thursday
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: week3Interval.start)!
            logs.append(TestHabitLog().withHabit(habit).withDate(date).build())
        }
        
        // Week 4: 5 completions (exceeds target)
        let week4Start = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: today)!
        let week4Interval = Calendar.current.dateInterval(of: .weekOfYear, for: week4Start)!
        for dayOffset in [0, 1, 3, 5, 6] { // Sun, Mon, Wed, Fri, Sat
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: week4Interval.start)!
            logs.append(TestHabitLog().withHabit(habit).withDate(date).build())
        }
        
        // Week 5 (current): 3 completions so far
        let week5Start = Calendar.current.date(byAdding: .weekOfYear, value: 0, to: today)!
        let week5Interval = Calendar.current.dateInterval(of: .weekOfYear, for: week5Start)!
        for dayOffset in [1, 2, 4] { // Mon, Tue, Thu (assuming today is later in week)
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: week5Interval.start)!
            if date <= today {
                logs.append(TestHabitLog().withHabit(habit).withDate(date).build())
            }
        }
        
        return StreakScenario(
            habit: habit,
            logs: logs,
            expectedCurrentStreak: 2, // Week 4 and current week both meet/exceed target
            expectedLongestStreak: 2, // Week 1 and Week 2 both met target before Week 3 break
            description: "TimesPerWeek habit with variable weekly performance"
        )
    }
    
    // MARK: - Numeric Habit Streak Patterns
    
    /// Creates a scenario with numeric habit having partial compliance patterns.
    /// Tests target-based streak calculation for numeric habits.
    public static func numericHabitPartialCompliance() -> StreakScenario {
        let habit = TestHabit.readingHabit()
            .withName("Reading Minutes")
            .asNumeric(target: 30.0, unit: "minutes")
            .startingDaysAgo(20)
            .build()
        
        var logs: [HabitLog] = []
        let today = Date()
        
        // Create a mix of compliant and non-compliant logs
        let patterns: [Double] = [
            35.0,  // Day 1: Above target
            30.0,  // Day 2: Meets target exactly
            25.0,  // Day 3: Below target (breaks streak)
            40.0,  // Day 4: Above target (new streak start)
            32.0,  // Day 5: Above target
            28.0,  // Day 6: Below target (breaks streak)
            33.0,  // Day 7: Above target (new streak start)
            31.0,  // Day 8: Above target
            30.0,  // Day 9: Meets target
            35.0   // Day 10: Above target (current streak = 4)
        ]
        
        for (index, value) in patterns.enumerated() {
            let date = Calendar.current.date(byAdding: .day, value: -19 + index, to: today)!
            logs.append(TestHabitLog().withHabit(habit).withDate(date).withValue(value).build())
        }
        
        return StreakScenario(
            habit: habit,
            logs: logs,
            expectedCurrentStreak: 4, // Days 7-10 all meet/exceed target
            expectedLongestStreak: 4, // Longest consecutive compliant period
            description: "Numeric habit with target compliance patterns"
        )
    }
    
    /// Creates a scenario testing numeric habit with zero and nil values.
    /// Tests edge cases in numeric habit streak calculation.
    public static func numericHabitEdgeCases() -> StreakScenario {
        let habit = TestHabit.waterIntakeHabit()
            .withName("Water Glasses")
            .asNumeric(target: 8.0, unit: "glasses")
            .startingDaysAgo(15)
            .build()
        
        var logs: [HabitLog] = []
        let today = Date()
        
        // Mix of edge case values
        let logData: [(Double?, String)] = [
            (10.0, "Above target"),      // Day 1: Compliant
            (8.0, "Meets target"),       // Day 2: Compliant
            (0.0, "Zero value"),         // Day 3: Non-compliant
            (nil, "Nil value"),          // Day 4: Non-compliant (defaults to 0)
            (12.0, "High value"),        // Day 5: Compliant (new streak start)
            (-2.0, "Negative value"),    // Day 6: Non-compliant (unusual but possible)
            (9.0, "Above target"),       // Day 7: Compliant (new streak start)
            (8.5, "Above target")        // Day 8: Compliant (current streak = 2)
        ]
        
        for (index, (value, _)) in logData.enumerated() {
            let date = Calendar.current.date(byAdding: .day, value: -14 + index, to: today)!
            logs.append(TestHabitLog().withHabit(habit).withDate(date).withValue(value).build())
        }
        
        return StreakScenario(
            habit: habit,
            logs: logs,
            expectedCurrentStreak: 2, // Days 7-8 both meet target
            expectedLongestStreak: 2, // Both Day 1-2 and Day 7-8 have 2-day streaks
            description: "Numeric habit with zero, nil, and negative value edge cases"
        )
    }
    
    // MARK: - Cross-Schedule Type Testing
    
    /// Creates multiple habits with different schedules for comparative testing.
    /// Perfect for testing service behavior across different habit types.
    public static func multiScheduleComparison() -> MultiHabitStreakScenario {
        let dailyHabit = TestHabit.simpleBinaryHabit()
            .withName("Daily Task")
            .asDaily()
            .startingDaysAgo(21)
            .build()
        
        let weekdayHabit = TestHabit.workoutHabit()
            .withName("Weekday Workout")
            .forDaysOfWeek([1, 2, 3, 4, 5]) // Monday-Friday
            .startingDaysAgo(21)
            .build()
        
        let flexibleHabit = TestHabit.flexibleHabit()
            .withName("2x Per Week")
            .forTimesPerWeek(2)
            .startingDaysAgo(21)
            .build()
        
        let numericHabit = TestHabit.meditationHabit()
            .withName("Daily Meditation")
            .asNumeric(target: 10.0, unit: "minutes")
            .startingDaysAgo(21)
            .build()
        
        var allLogs: [HabitLog] = []
        let today = Date()
        
        // Generate logs for past 3 weeks with different completion patterns
        for weekOffset in (-2)...0 {
            let weekStart = Calendar.current.date(byAdding: .weekOfYear, value: weekOffset, to: today)!
            let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: weekStart)!
            
            for dayOfWeek in 0..<7 {
                let date = Calendar.current.date(byAdding: .day, value: dayOfWeek, to: weekInterval.start)!
                guard date <= today else { continue }
                
                let weekdayNumber = Calendar.current.component(.weekday, from: date)
                let isWeekday = weekdayNumber >= 2 && weekdayNumber <= 6
                
                // Daily habit: 85% completion rate
                if Double.random(in: 0...1) <= 0.85 {
                    allLogs.append(TestHabitLog().withHabit(dailyHabit).withDate(date).build())
                }
                
                // Weekday habit: Only on weekdays, 90% completion rate
                if isWeekday && Double.random(in: 0...1) <= 0.90 {
                    allLogs.append(TestHabitLog().withHabit(weekdayHabit).withDate(date).build())
                }
                
                // Flexible habit: Variable, ensuring ~2 per week
                if dayOfWeek == 1 || dayOfWeek == 4 { // Tue and Fri typically
                    if Double.random(in: 0...1) <= 0.85 {
                        allLogs.append(TestHabitLog().withHabit(flexibleHabit).withDate(date).build())
                    }
                }
                
                // Numeric habit: 80% meet target
                if Double.random(in: 0...1) <= 0.80 {
                    let value = Double.random(in: 10.0...20.0)
                    allLogs.append(TestHabitLog().withHabit(numericHabit).withDate(date).withValue(value).build())
                }
            }
        }
        
        return MultiHabitStreakScenario(
            habits: [dailyHabit, weekdayHabit, flexibleHabit, numericHabit],
            logs: allLogs,
            description: "Comparative testing across all habit schedule types"
        )
    }
    
    // MARK: - Boundary Testing
    
    /// Creates a scenario testing habit start/end date boundaries.
    /// Tests streak calculation respects habit lifecycle dates.
    public static func habitLifecycleBoundaries() -> StreakScenario {
        let startDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let endDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        
        var habit = TestHabit.simpleBinaryHabit()
            .withName("Limited Duration Habit")
            .withStartDate(startDate)
            .build()
        habit.endDate = endDate
        
        var logs: [HabitLog] = []
        
        // Logs before start date (should be ignored)
        for dayOffset in -15...(-11) {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
            logs.append(TestHabitLog().withHabit(habit).withDate(date).build())
        }
        
        // Logs within habit duration (should count)
        for dayOffset in -10...(-3) {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
            logs.append(TestHabitLog().withHabit(habit).withDate(date).build())
        }
        
        // Logs after end date (should be ignored)
        for dayOffset in -2...0 {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
            logs.append(TestHabitLog().withHabit(habit).withDate(date).build())
        }
        
        return StreakScenario(
            habit: habit,
            logs: logs,
            expectedCurrentStreak: 0, // Habit ended, so current streak is 0
            expectedLongestStreak: 8, // 8 days within the valid duration
            description: "Habit with start and end date boundaries"
        )
    }
}

// MARK: - Supporting Data Structures

/// Container for single-habit streak testing scenarios.
public struct StreakScenario {
    public let habit: Habit
    public let logs: [HabitLog]
    public let expectedCurrentStreak: Int
    public let expectedLongestStreak: Int
    public let description: String
    
    public init(habit: Habit, logs: [HabitLog], expectedCurrentStreak: Int, expectedLongestStreak: Int, description: String) {
        self.habit = habit
        self.logs = logs
        self.expectedCurrentStreak = expectedCurrentStreak
        self.expectedLongestStreak = expectedLongestStreak
        self.description = description
    }
}

/// Container for multi-habit streak testing scenarios.
public struct MultiHabitStreakScenario {
    public let habits: [Habit]
    public let logs: [HabitLog]
    public let description: String
    
    public init(habits: [Habit], logs: [HabitLog], description: String) {
        self.habits = habits
        self.logs = logs
        self.description = description
    }
    
    /// Returns logs filtered for a specific habit.
    public func logs(for habit: Habit) -> [HabitLog] {
        return logs.filter { $0.habitID == habit.id }
    }
}

// MARK: - Calendar Utilities

public extension StreakTestFixtures {
    /// Creates deterministic dates for consistent testing.
    static func createTestDate(year: Int = 2025, month: Int = 8, day: Int) -> Date {
        let components = DateComponents(year: year, month: month, day: day)
        return Calendar.current.date(from: components) ?? Date()
    }
    
    /// Creates a range of dates for testing.
    static func createDateRange(from startDate: Date, days: Int) -> [Date] {
        return (0..<days).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: offset, to: startDate)
        }
    }
}