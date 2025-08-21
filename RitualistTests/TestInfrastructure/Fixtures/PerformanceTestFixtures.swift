//
//  PerformanceTestFixtures.swift
//  RitualistTests
//
//  Created by Claude on 21.08.2025.
//

import Foundation
@testable import RitualistCore

/// Specialized fixtures for performance testing with large datasets.
/// These fixtures create realistic high-volume scenarios to validate
/// app performance under heavy data loads and complex operations.
public struct PerformanceTestFixtures {
    
    // MARK: - Large Dataset Generation
    
    /// Creates a large number of habits with comprehensive logging.
    /// Perfect for testing database query performance and UI rendering.
    public static func heavyUserScenario(habitCount: Int = 100, daysOfHistory: Int = 365) -> HeavyDataScenario {
        var habits: [Habit] = []
        var logs: [HabitLog] = []
        var categories: [HabitCategory] = []
        
        // Create realistic categories with unique IDs to avoid conflicts
        let categoryData = [
            ("perf-health", "Health & Fitness", "#FF6B35"),
            ("perf-learning", "Learning & Growth", "#4A90E2"),
            ("perf-mindfulness", "Mindfulness", "#9B59B6"),
            ("perf-productivity", "Productivity", "#2ECC71"),
            ("perf-social", "Social & Family", "#E74C3C"),
            ("perf-hobbies", "Hobbies & Fun", "#F39C12"),
            ("perf-finance", "Finance & Career", "#34495E"),
            ("perf-environment", "Environment & Home", "#16A085")
        ]
        
        for (id, name, _) in categoryData {
            categories.append(
                TestCategory()
                    .withId(id)
                    .withNameAndDisplay(name)
                    .build()
            )
        }
        
        // Create habits with realistic distribution
        for i in 0..<habitCount {
            let category = categories.randomElement()
            let isNumeric = Double.random(in: 0...1) < 0.4 // 40% numeric habits
            let startDaysAgo = Int.random(in: min(30, daysOfHistory)...daysOfHistory)
            
            var habit: Habit
            
            if isNumeric {
                let targets = [1.0, 2.0, 5.0, 8.0, 10.0, 15.0, 20.0, 30.0, 60.0]
                let units = ["minutes", "glasses", "pages", "reps", "miles", "hours"]
                
                habit = TestHabit()
                    .withName("Habit \(i + 1)")
                    .withCategory(category)
                    .asNumeric(target: targets.randomElement() ?? 10.0, unit: units.randomElement() ?? "units")
                    .startingDaysAgo(startDaysAgo)
                    .build()
            } else {
                habit = TestHabit.simpleBinaryHabit()
                    .withName("Habit \(i + 1)")
                    .withCategory(category)
                    .startingDaysAgo(startDaysAgo)
                    .build()
            }
            
            // Assign random schedule
            let scheduleType = Int.random(in: 0...2)
            switch scheduleType {
            case 0:
                habit.schedule = .daily
            case 1:
                let days = Set((1...7).shuffled().prefix(Int.random(in: 2...5)))
                habit.schedule = .daysOfWeek(days)
            case 2:
                habit.schedule = .timesPerWeek(Int.random(in: 2...6))
            default:
                habit.schedule = .daily
            }
            
            habits.append(habit)
            
            // Generate logs with realistic patterns
            let completionRate = Double.random(in: 0.3...0.95)
            logs.append(contentsOf: generateRealisticLogs(for: habit, days: min(startDaysAgo, daysOfHistory), completionRate: completionRate))
        }
        
        return HeavyDataScenario(
            habits: habits,
            logs: logs,
            categories: categories,
            description: "Heavy user with \(habitCount) habits and \(daysOfHistory) days of history"
        )
    }
    
    /// Creates a scenario with extreme logging density.
    /// Tests performance with very active logging patterns.
    public static func extremeLoggingScenario(habitCount: Int = 20, daysOfHistory: Int = 180) -> HeavyDataScenario {
        var habits: [Habit] = []
        var logs: [HabitLog] = []
        
        // Create habits that log multiple times per day
        for i in 0..<habitCount {
            let habit = TestHabit()
                .withName("Extreme Habit \(i + 1)")
                .asNumeric(target: 1.0, unit: "times")
                .startingDaysAgo(daysOfHistory)
                .build()
            
            habits.append(habit)
            
            // Generate multiple logs per day
            for dayOffset in -daysOfHistory...0 {
                let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
                
                // 2-5 logs per day for extreme scenarios
                let logsPerDay = Int.random(in: 2...5)
                for logIndex in 0..<logsPerDay {
                    let value = Double.random(in: 0.5...2.0)
                    var logDate = date
                    
                    // Spread logs throughout the day
                    if logIndex > 0 {
                        let hourOffset = logIndex * (24 / logsPerDay)
                        logDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: date) ?? date
                    }
                    
                    logs.append(
                        TestHabitLog()
                            .withHabit(habit)
                            .withDate(logDate)
                            .withValue(value)
                            .build()
                    )
                }
            }
        }
        
        return HeavyDataScenario(
            habits: habits,
            logs: logs,
            categories: [],
            description: "Extreme logging: \(habitCount) habits with multiple daily entries over \(daysOfHistory) days"
        )
    }
    
    /// Creates a scenario with complex streak patterns for performance testing.
    /// Tests streak calculation performance with intricate logging patterns.
    public static func complexStreakPerformanceScenario() -> HeavyDataScenario {
        var habits: [Habit] = []
        var logs: [HabitLog] = []
        
        // Create habits with different schedule types
        let scheduleTypes: [HabitSchedule] = [
            .daily,
            .daysOfWeek([1, 2, 3, 4, 5]), // Weekdays
            .daysOfWeek([6, 7]), // Weekends
            .daysOfWeek([1, 3, 5]), // Mon, Wed, Fri
            .timesPerWeek(2),
            .timesPerWeek(3),
            .timesPerWeek(4)
        ]
        
        for (index, schedule) in scheduleTypes.enumerated() {
            let habit = TestHabit()
                .withName("Complex Streak Habit \(index + 1)")
                .withSchedule(schedule)
                .startingDaysAgo(730) // 2 years of history
                .build()
            
            habits.append(habit)
            
            // Generate complex logging patterns with multiple streaks and breaks
            logs.append(contentsOf: generateComplexStreakPattern(for: habit, days: 730))
        }
        
        return HeavyDataScenario(
            habits: habits,
            logs: logs,
            categories: [],
            description: "Complex streak patterns for performance testing"
        )
    }
    
    // MARK: - Memory Stress Testing
    
    /// Creates a scenario designed to stress test memory usage.
    /// Large amounts of data that must be held in memory simultaneously.
    public static func memoryStressScenario() -> HeavyDataScenario {
        let habitCount = 500
        let daysOfHistory = 90
        
        var habits: [Habit] = []
        var logs: [HabitLog] = []
        
        // Create many habits with shorter but dense history
        for i in 0..<habitCount {
            let habit = TestHabit.simpleBinaryHabit()
                .withName("Memory Stress Habit \(i + 1)")
                .startingDaysAgo(daysOfHistory)
                .build()
            
            habits.append(habit)
            
            // Dense logging with 90% completion rate
            logs.append(contentsOf: generateRealisticLogs(for: habit, days: daysOfHistory, completionRate: 0.9))
        }
        
        return HeavyDataScenario(
            habits: habits,
            logs: logs,
            categories: [],
            description: "Memory stress: \(habitCount) habits with dense \(daysOfHistory)-day history"
        )
    }
    
    // MARK: - Batch Processing Test Data
    
    /// Creates data specifically for testing batch operations and N+1 query prevention.
    /// Designed to validate database query optimization.
    public static func batchProcessingTestData(habitCount: Int = 50) -> HeavyDataScenario {
        var habits: [Habit] = []
        var logs: [HabitLog] = []
        let categories = TestCategory.createPredefinedCategories()
        
        // Create habits with consistent logging patterns
        for i in 0..<habitCount {
            let category = categories.randomElement()
            let habit = TestHabit()
                .withName("Batch Test Habit \(i + 1)")
                .withCategory(category)
                .startingDaysAgo(30)
                .build()
            
            habits.append(habit)
            
            // Consistent daily logging for predictable batch testing
            for dayOffset in -29...0 {
                let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
                logs.append(
                    TestHabitLog()
                        .withHabit(habit)
                        .withDate(date)
                        .build()
                )
            }
        }
        
        return HeavyDataScenario(
            habits: habits,
            logs: logs,
            categories: categories,
            description: "Batch processing test: \(habitCount) habits with 30 days of consistent logs"
        )
    }
    
    // MARK: - Real-World Simulation
    
    /// Creates a realistic long-term user scenario.
    /// Simulates a user who has been using the app for years with varying engagement.
    public static func longTermUserSimulation() -> HeavyDataScenario {
        var habits: [Habit] = []
        var logs: [HabitLog] = []
        let categories = TestCategory.createPredefinedCategories()
        
        // Simulate habit evolution over time
        let timePhases = [
            (daysAgo: 1095, habitCount: 5, completionRate: 0.8), // Year 1-3: High motivation, few habits
            (daysAgo: 730, habitCount: 12, completionRate: 0.65), // Year 2: Adding more habits, slight decline
            (daysAgo: 365, habitCount: 8, completionRate: 0.75), // Year 3: Refocusing, better consistency
            (daysAgo: 180, habitCount: 15, completionRate: 0.6), // Recent: Experimenting with many habits
            (daysAgo: 30, habitCount: 10, completionRate: 0.85)  // Current: Finding balance
        ]
        
        for (phaseIndex, phase) in timePhases.enumerated() {
            for habitIndex in 0..<phase.habitCount {
                let habit = TestHabit()
                    .withName("Phase \(phaseIndex + 1) Habit \(habitIndex + 1)")
                    .withCategory(categories.randomElement())
                    .startingDaysAgo(phase.daysAgo)
                    .build()
                
                habits.append(habit)
                
                // Some habits end when phases change (simulating habit evolution)
                if phaseIndex < timePhases.count - 1 && Double.random(in: 0...1) < 0.3 {
                    // Create a modified copy of the habit with end date and inactive status
                    let modifiedHabit = TestHabit()
                        .withId(habit.id)
                        .withName(habit.name)
                        .withColor(habit.colorHex)
                        .withEmoji(habit.emoji)
                        .withKind(habit.kind)
                        .withUnitLabel(habit.unitLabel)
                        .withDailyTarget(habit.dailyTarget)
                        .withSchedule(habit.schedule)
                        .withReminders(habit.reminders)
                        .withStartDate(habit.startDate)
                        .withEndDate(Calendar.current.date(byAdding: .day, value: -timePhases[phaseIndex + 1].daysAgo, to: Date()))
                        .withIsActive(false)
                        .withDisplayOrder(habit.displayOrder)
                        .withCategoryId(habit.categoryId)
                        .withSuggestionId(habit.suggestionId)
                        .build()
                    
                    // Replace the habit in the array
                    habits[habits.count - 1] = modifiedHabit
                }
                
                
                // Generate logs with phase-specific completion rate
                let currentHabit = habits.last!
                let daysActive = currentHabit.endDate != nil ? 
                    phase.daysAgo - timePhases[phaseIndex + 1].daysAgo : phase.daysAgo
                logs.append(contentsOf: generateRealisticLogs(for: currentHabit, days: daysActive, completionRate: phase.completionRate))
            }
        }
        
        return HeavyDataScenario(
            habits: habits,
            logs: logs,
            categories: categories,
            description: "Long-term user simulation with habit evolution over 3 years"
        )
    }
}

// MARK: - Supporting Data Structures

/// Container for heavy data testing scenarios.
public struct HeavyDataScenario {
    public let habits: [Habit]
    public let logs: [HabitLog]
    public let categories: [HabitCategory]
    public let description: String
    
    public init(habits: [Habit], logs: [HabitLog], categories: [HabitCategory], description: String) {
        self.habits = habits
        self.logs = logs
        self.categories = categories
        self.description = description
    }
    
    /// Statistics about the dataset size.
    public var statistics: DatasetStatistics {
        return DatasetStatistics(
            habitCount: habits.count,
            logCount: logs.count,
            categoryCount: categories.count,
            activeHabitCount: habits.filter { $0.isActive }.count,
            avgLogsPerHabit: logs.count / max(habits.count, 1),
            dateRange: calculateDateRange()
        )
    }
    
    private func calculateDateRange() -> (start: Date?, end: Date?) {
        guard !logs.isEmpty else { return (nil, nil) }
        let sortedDates = logs.map { $0.date }.sorted()
        return (start: sortedDates.first, end: sortedDates.last)
    }
}

/// Statistics container for analyzing dataset characteristics.
public struct DatasetStatistics {
    public let habitCount: Int
    public let logCount: Int
    public let categoryCount: Int
    public let activeHabitCount: Int
    public let avgLogsPerHabit: Int
    public let dateRange: (start: Date?, end: Date?)
    
    /// Human-readable summary of the dataset.
    public var summary: String {
        let dateRangeStr: String
        if let start = dateRange.start, let end = dateRange.end {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            dateRangeStr = "\(formatter.string(from: start)) to \(formatter.string(from: end))"
        } else {
            dateRangeStr = "No date range"
        }
        
        return """
        Dataset Statistics:
        - Habits: \(habitCount) (\(activeHabitCount) active)
        - Logs: \(logCount) (\(avgLogsPerHabit) avg per habit)
        - Categories: \(categoryCount)
        - Date Range: \(dateRangeStr)
        """
    }
}

// MARK: - Private Helpers

private extension PerformanceTestFixtures {
    
    /// Generates realistic logging patterns with varying completion rates.
    static func generateRealisticLogs(for habit: Habit, days: Int, completionRate: Double) -> [HabitLog] {
        var logs: [HabitLog] = []
        let today = Date()
        
        for dayOffset in -days...0 {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: today)!
            
            // Apply weekly variation (weekends might be different)
            let weekday = Calendar.current.component(.weekday, from: date)
            let isWeekend = weekday == 1 || weekday == 7
            let adjustedRate = isWeekend ? completionRate * 0.8 : completionRate
            
            if Double.random(in: 0...1) <= adjustedRate {
                let value: Double?
                if habit.kind == .numeric {
                    let target = habit.dailyTarget ?? 1.0
                    // Add realistic variation around target
                    value = Double.random(in: target * 0.7...target * 1.3)
                } else {
                    value = nil
                }
                
                logs.append(
                    TestHabitLog()
                        .withHabit(habit)
                        .withDate(date)
                        .withValue(value)
                        .build()
                )
            }
        }
        
        return logs
    }
    
    /// Generates complex streak patterns with multiple breaks and recoveries.
    static func generateComplexStreakPattern(for habit: Habit, days: Int) -> [HabitLog] {
        var logs: [HabitLog] = []
        let today = Date()
        
        // Create alternating patterns of streaks and breaks
        var currentDay = -days
        while currentDay <= 0 {
            // Random streak length (5-30 days)
            let streakLength = Int.random(in: 5...30)
            
            // Create streak
            for streakDay in 0..<streakLength {
                guard currentDay + streakDay <= 0 else { break }
                
                let date = Calendar.current.date(byAdding: .day, value: currentDay + streakDay, to: today)!
                
                // Check if this day is scheduled for the habit
                if isScheduledDay(date: date, for: habit) {
                    logs.append(
                        TestHabitLog()
                            .withHabit(habit)
                            .withDate(date)
                            .build()
                    )
                }
            }
            
            currentDay += streakLength
            
            // Random break length (2-14 days)
            let breakLength = Int.random(in: 2...14)
            currentDay += breakLength
        }
        
        return logs
    }
    
    /// Checks if a date is scheduled for a given habit.
    static func isScheduledDay(date: Date, for habit: Habit) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        
        switch habit.schedule {
        case .daily:
            return true
        case .daysOfWeek(let days):
            return days.contains(weekday)
        case .timesPerWeek:
            // For times per week, any day could be scheduled
            return true
        }
    }
}

// MARK: - Performance Measurement Utilities

public extension PerformanceTestFixtures {
    
    /// Measures execution time of a block and returns the result with timing.
    static func measure<T>(_ operation: () throws -> T) rethrows -> (result: T, timeInterval: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return (result: result, timeInterval: timeElapsed)
    }
    
    /// Creates a performance benchmark scenario for comparison testing.
    static func createBenchmarkScenario(name: String, habitCount: Int, daysOfHistory: Int) -> HeavyDataScenario {
        let startTime = CFAbsoluteTimeGetCurrent()
        let scenario = heavyUserScenario(habitCount: habitCount, daysOfHistory: daysOfHistory)
        let creationTime = CFAbsoluteTimeGetCurrent() - startTime
        
        let description = """
        \(name) Benchmark:
        - Creation Time: \(String(format: "%.3f", creationTime))s
        - \(scenario.description)
        """
        
        return HeavyDataScenario(
            habits: scenario.habits,
            logs: scenario.logs,
            categories: scenario.categories,
            description: description
        )
    }
}