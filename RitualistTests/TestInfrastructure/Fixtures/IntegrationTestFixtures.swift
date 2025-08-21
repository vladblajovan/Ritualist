//
//  IntegrationTestFixtures.swift
//  RitualistTests
//
//  Created by Claude on 21.08.2025.
//

import Foundation
@testable import RitualistCore

/// Specialized fixtures for testing cross-service integration scenarios.
/// These fixtures create complex multi-entity scenarios that require
/// coordination between multiple services and components.
public struct IntegrationTestFixtures {
    
    // MARK: - Habit Creation and Logging Integration
    
    /// Creates a scenario testing the full habit creation → logging → analytics pipeline.
    /// Tests end-to-end data flow from habit creation through analysis.
    public static func habitCreationToAnalyticsPipeline() -> IntegrationScenario {
        let category = TestCategory()
            .withNameAndDisplay("Health")
            .build()
        
        let habit = TestHabit.workoutHabit()
            .withName("Morning Workout")
            .withCategory(category)
            .build()
        
        // Create logs over 30 days with improvement pattern
        var logs: [HabitLog] = []
        for dayOffset in -29...0 {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
            let weekday = Calendar.current.component(.weekday, from: date)
            
            // Workout habit is weekdays only, with improving completion rate
            if weekday >= 2 && weekday <= 6 { // Monday-Friday
                let progressFactor = 1.0 + Double(dayOffset + 29) / 29.0 * 0.3 // 70% to 100% completion rate
                if Double.random(in: 0...1) <= progressFactor {
                    logs.append(TestHabitLog().withHabit(habit).withDate(date).build())
                }
            }
        }
        
        return IntegrationScenario(
            habits: [habit],
            logs: logs,
            categories: [category],
            testCases: [
                IntegrationTestCase(
                    name: "Habit Creation",
                    description: "Verify habit is properly created with category relationship"
                ),
                IntegrationTestCase(
                    name: "Logging Integration",
                    description: "Verify logs are properly associated with habit"
                ),
                IntegrationTestCase(
                    name: "Schedule Compliance",
                    description: "Verify schedule-based completion tracking works correctly"
                ),
                IntegrationTestCase(
                    name: "Analytics Generation",
                    description: "Verify completion analytics reflect improvement trend"
                )
            ],
            expectedOutcomes: [
                "Habit exists with proper category association",
                "Logs are linked to correct habit ID",
                "Weekend logs are ignored for weekday-only habit",
                "Completion rate shows improvement over time"
            ],
            description: "Full pipeline from habit creation to analytics generation"
        )
    }
    
    /// Creates a scenario testing batch habit operations.
    /// Tests bulk operations across multiple habits and their related data.
    public static func batchHabitOperations() -> IntegrationScenario {
        let categories = TestCategory.createPredefinedCategories()
        
        let habits = [
            TestHabit.readingHabit().withCategory(categories[0]).build(),
            TestHabit.workoutHabit().withCategory(categories[1]).build(),
            TestHabit.waterIntakeHabit().withCategory(categories[1]).build(),
            TestHabit.meditationHabit().withCategory(categories[2]).build(),
            TestHabit.simpleBinaryHabit().withName("Journaling").withCategory(categories[0]).build()
        ]
        
        // Generate logs for all habits over past week
        var logs: [HabitLog] = []
        for habit in habits {
            logs.append(contentsOf: TestHabitLog.createWeeklyLogs(for: habit, completionRate: 0.8))
        }
        
        return IntegrationScenario(
            habits: habits,
            logs: logs,
            categories: categories,
            testCases: [
                IntegrationTestCase(
                    name: "Batch Load Performance",
                    description: "Verify efficient loading of multiple habits with logs"
                ),
                IntegrationTestCase(
                    name: "Category Grouping",
                    description: "Verify habits are properly grouped by categories"
                ),
                IntegrationTestCase(
                    name: "Cross-Habit Analytics",
                    description: "Verify analytics work across multiple habit types"
                ),
                IntegrationTestCase(
                    name: "Bulk Updates",
                    description: "Verify bulk operations don't break data integrity"
                )
            ],
            expectedOutcomes: [
                "All habits load with their category associations",
                "Logs are properly distributed across habits",
                "Category-based analytics are accurate",
                "No N+1 query issues in batch operations"
            ],
            description: "Batch operations testing across multiple habits and categories"
        )
    }
    
    // MARK: - Streak Calculation Integration
    
    /// Creates a scenario testing streak calculations across different habit types.
    /// Tests streak service integration with various habit schedules.
    public static func streakCalculationIntegration() -> IntegrationScenario {
        let dailyHabit = TestHabit.simpleBinaryHabit()
            .withName("Daily Task")
            .asDaily()
            .build()
        
        let weekdayHabit = TestHabit.workoutHabit()
            .withName("Weekday Exercise")
            .forDaysOfWeek([1, 2, 3, 4, 5])
            .build()
        
        let flexibleHabit = TestHabit.flexibleHabit()
            .withName("3x Per Week")
            .forTimesPerWeek(3)
            .build()
        
        let numericHabit = TestHabit.readingHabit()
            .withName("Reading Minutes")
            .asNumeric(target: 30.0, unit: "minutes")
            .build()
        
        let habits = [dailyHabit, weekdayHabit, flexibleHabit, numericHabit]
        
        // Create complex logging patterns for streak testing
        var logs: [HabitLog] = []
        
        // Daily habit: Perfect 10-day streak
        for dayOffset in -9...0 {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
            logs.append(TestHabitLog().withHabit(dailyHabit).withDate(date).build())
        }
        
        // Weekday habit: 2 full weeks
        for dayOffset in -13...0 {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
            let weekday = Calendar.current.component(.weekday, from: date)
            if weekday >= 2 && weekday <= 6 { // Monday-Friday
                logs.append(TestHabitLog().withHabit(weekdayHabit).withDate(date).build())
            }
        }
        
        // Flexible habit: Meeting 3x per week target
        for weekOffset in -2...0 {
            let weekStart = Calendar.current.date(byAdding: .weekOfYear, value: weekOffset, to: Date())!
            let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: weekStart)!
            
            // 3 logs per week (Tuesday, Thursday, Saturday)
            for dayOffset in [2, 4, 6] {
                if let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: weekInterval.start),
                   date <= Date() {
                    logs.append(TestHabitLog().withHabit(flexibleHabit).withDate(date).build())
                }
            }
        }
        
        // Numeric habit: Mix of compliant and non-compliant values
        let targetValues = [35.0, 30.0, 25.0, 40.0, 32.0, 28.0, 35.0] // Last 4 meet target
        for (index, value) in targetValues.enumerated() {
            let date = Calendar.current.date(byAdding: .day, value: -6 + index, to: Date())!
            logs.append(TestHabitLog().withHabit(numericHabit).withDate(date).withValue(value).build())
        }
        
        return IntegrationScenario(
            habits: habits,
            logs: logs,
            categories: [],
            testCases: [
                IntegrationTestCase(
                    name: "Daily Habit Streak",
                    description: "Verify daily habit shows 10-day current streak"
                ),
                IntegrationTestCase(
                    name: "Weekday Habit Streak",
                    description: "Verify weekday habit correctly counts only scheduled days"
                ),
                IntegrationTestCase(
                    name: "Flexible Habit Streak",
                    description: "Verify times-per-week habit tracks weekly completion"
                ),
                IntegrationTestCase(
                    name: "Numeric Habit Compliance",
                    description: "Verify numeric habit only counts target-meeting logs"
                ),
                IntegrationTestCase(
                    name: "Cross-Type Comparison",
                    description: "Verify streak calculations work consistently across habit types"
                )
            ],
            expectedOutcomes: [
                "Daily habit shows current streak of 10",
                "Weekday habit shows current streak of 10 (2 weeks × 5 days)",
                "Flexible habit shows current streak of 3 weeks",
                "Numeric habit shows current streak of 4 (last 4 days meet target)",
                "All calculations respect habit-specific schedule rules"
            ],
            description: "Comprehensive streak calculation testing across habit types"
        )
    }
    
    // MARK: - Notification System Integration
    
    /// Creates a scenario testing notification scheduling with habit management.
    /// Tests integration between habit reminders and notification service.
    public static func notificationSchedulingIntegration() -> IntegrationScenario {
        let morningHabit = TestHabit.simpleBinaryHabit()
            .withName("Morning Routine")
            .withReminder(hour: 7, minute: 30)
            .build()
        
        let workoutHabit = TestHabit.workoutHabit()
            .withName("Weekday Workout")
            .forDaysOfWeek([1, 2, 3, 4, 5])
            .withReminder(hour: 18, minute: 0)
            .build()
        
        let multiReminderHabit = TestHabit.waterIntakeHabit()
            .withName("Water Intake")
            .withReminders([
                ReminderTime(hour: 9, minute: 0),
                ReminderTime(hour: 13, minute: 0),
                ReminderTime(hour: 17, minute: 0)
            ])
            .build()
        
        let inactiveHabit = TestHabit.simpleBinaryHabit()
            .withName("Inactive Habit")
            .withReminder(hour: 12, minute: 0)
            .asInactive()
            .build()
        
        let habits = [morningHabit, workoutHabit, multiReminderHabit, inactiveHabit]
        
        return IntegrationScenario(
            habits: habits,
            logs: [],
            categories: [],
            testCases: [
                IntegrationTestCase(
                    name: "Active Habit Notifications",
                    description: "Verify only active habits generate notifications"
                ),
                IntegrationTestCase(
                    name: "Schedule-Aware Notifications",
                    description: "Verify weekday-only habit generates 5 notifications per week"
                ),
                IntegrationTestCase(
                    name: "Multiple Reminders",
                    description: "Verify habit with multiple reminders creates all notifications"
                ),
                IntegrationTestCase(
                    name: "Notification Consolidation",
                    description: "Verify overlapping reminder times are handled properly"
                ),
                IntegrationTestCase(
                    name: "Habit State Changes",
                    description: "Verify notifications update when habit becomes inactive"
                )
            ],
            expectedOutcomes: [
                "Morning habit generates daily notifications",
                "Workout habit generates weekday-only notifications", 
                "Water habit generates 3 daily notifications",
                "Inactive habit generates no notifications",
                "Total expected notifications match active reminder count"
            ],
            description: "Notification system integration with habit management"
        )
    }
    
    // MARK: - Data Migration and Sync Integration
    
    /// Creates a scenario testing data migration and synchronization.
    /// Tests integration during data format changes and cloud sync.
    public static func dataMigrationSyncIntegration() -> IntegrationScenario {
        // Simulate mixed data from different app versions
        let v1Habit = TestHabit.simpleBinaryHabit()
            .withName("V1 Habit")
            .build()
        
        let v2Habit = TestHabit.readingHabit()
            .withName("V2 Numeric Habit")
            .build()
        
        let v3Habit = TestHabit.flexibleHabit()
            .withName("V3 Flexible Habit")
            .build()
        
        // Simulate logs from different periods and formats
        let mixedLogs = [
            // Old format logs
            TestHabitLog().withHabit(v1Habit).forDaysAgo(100).build(),
            TestHabitLog().withHabit(v1Habit).forDaysAgo(99).build(),
            
            // Newer format logs
            TestHabitLog().withHabit(v2Habit).withValue(25.0).forDaysAgo(30).build(),
            TestHabitLog().withHabit(v2Habit).withValue(30.0).forDaysAgo(29).build(),
            
            // Latest format logs
            TestHabitLog().withHabit(v3Habit).forToday().build(),
            TestHabitLog().withHabit(v3Habit).forYesterday().build()
        ]
        
        let legacyCategory = TestCategory()
            .withId("legacy-health")
            .withNameAndDisplay("Health (Legacy)")
            .build()
        
        return IntegrationScenario(
            habits: [v1Habit, v2Habit, v3Habit],
            logs: mixedLogs,
            categories: [legacyCategory],
            testCases: [
                IntegrationTestCase(
                    name: "Version Compatibility",
                    description: "Verify data from different app versions loads correctly"
                ),
                IntegrationTestCase(
                    name: "Format Migration",
                    description: "Verify old data formats are converted to current format"
                ),
                IntegrationTestCase(
                    name: "Data Integrity",
                    description: "Verify no data is lost during migration process"
                ),
                IntegrationTestCase(
                    name: "Sync Conflict Resolution",
                    description: "Verify conflicts between local and synced data are resolved"
                ),
                IntegrationTestCase(
                    name: "Relationship Preservation",
                    description: "Verify habit-log-category relationships remain intact"
                )
            ],
            expectedOutcomes: [
                "All habits load regardless of creation version",
                "Old logs maintain association with correct habits",
                "Numeric values are preserved correctly",
                "Category relationships are maintained",
                "No orphaned data after migration"
            ],
            description: "Data migration and synchronization integration testing"
        )
    }
    
    // MARK: - User Profile and Preferences Integration
    
    /// Creates a scenario testing user profile integration with habits and settings.
    /// Tests how user preferences affect habit behavior across the system.
    public static func userProfileHabitIntegration() -> IntegrationScenario {
        _ = TestUserProfile.premiumAnnualUser()
            .withName("Integration Test User")
            .build()
        
        // Create habits that depend on user preferences
        let weekStartHabit = TestHabit.workoutHabit()
            .withName("Weekly Workout")
            .forDaysOfWeek([1, 2, 3]) // Mon, Tue, Wed (depends on week start preference)
            .build()
        
        let premiumHabit = TestHabit.readingHabit()
            .withName("Advanced Reading Analytics")
            // This habit would have premium features enabled
            .build()
        
        let localizedHabit = TestHabit.waterIntakeHabit()
            .withName("Water Intake")
            .asNumeric(target: 2.0, unit: "liters") // Metric units based on user locale
            .build()
        
        let habits = [weekStartHabit, premiumHabit, localizedHabit]
        
        // Create logs that respect user preferences
        var logs: [HabitLog] = []
        for habit in habits {
            logs.append(contentsOf: TestHabitLog.createWeeklyLogs(for: habit, completionRate: 0.85))
        }
        
        return IntegrationScenario(
            habits: habits,
            logs: logs,
            categories: [],
            testCases: [
                IntegrationTestCase(
                    name: "Week Start Preference",
                    description: "Verify weekly habits respect user's week start preference"
                ),
                IntegrationTestCase(
                    name: "Premium Feature Access",
                    description: "Verify premium users have access to advanced features"
                ),
                IntegrationTestCase(
                    name: "Localization Integration",
                    description: "Verify units and formats respect user locale settings"
                ),
                IntegrationTestCase(
                    name: "Theme Integration",
                    description: "Verify habit colors work with user's theme preference"
                ),
                IntegrationTestCase(
                    name: "Profile Updates",
                    description: "Verify habit behavior updates when profile changes"
                )
            ],
            expectedOutcomes: [
                "Weekly calculations use correct week start day",
                "Premium analytics are available for premium user",
                "Numeric values display in user's preferred units",
                "Habit colors render correctly in user's theme",
                "Real-time updates when preferences change"
            ],
            description: "User profile and preferences integration with habit system"
        )
    }
    
    // MARK: - Performance and Scalability Integration
    
    /// Creates a scenario testing system performance under realistic load.
    /// Tests integration performance with substantial but realistic data volumes.
    public static func performanceScalabilityIntegration() -> IntegrationScenario {
        let categories = TestCategory.createPredefinedCategories()
        
        // Create realistic user load: 25 active habits
        var habits: [Habit] = []
        for i in 0..<25 {
            let category = categories[i % categories.count]
            let isNumeric = i % 3 == 0 // Every 3rd habit is numeric
            
            let habit = if isNumeric {
                TestHabit()
                    .withName("Habit \(i + 1)")
                    .withCategory(category)
                    .asNumeric(target: Double.random(in: 1...30), unit: "units")
                    .build()
            } else {
                TestHabit.simpleBinaryHabit()
                    .withName("Habit \(i + 1)")
                    .withCategory(category)
                    .build()
            }
            
            habits.append(habit)
        }
        
        // Create 90 days of realistic logging data
        var logs: [HabitLog] = []
        for habit in habits {
            // Different completion rates for different habits
            let completionRate = Double.random(in: 0.5...0.95)
            logs.append(contentsOf: generateRealisticLogs(for: habit, days: 90, completionRate: completionRate))
        }
        
        return IntegrationScenario(
            habits: habits,
            logs: logs,
            categories: categories,
            testCases: [
                IntegrationTestCase(
                    name: "Bulk Data Loading",
                    description: "Verify efficient loading of large datasets"
                ),
                IntegrationTestCase(
                    name: "Query Performance",
                    description: "Verify database queries remain fast with substantial data"
                ),
                IntegrationTestCase(
                    name: "Memory Management",
                    description: "Verify memory usage stays reasonable with large datasets"
                ),
                IntegrationTestCase(
                    name: "UI Responsiveness",
                    description: "Verify UI remains responsive during data operations"
                ),
                IntegrationTestCase(
                    name: "Concurrent Access",
                    description: "Verify system handles multiple simultaneous operations"
                )
            ],
            expectedOutcomes: [
                "All habits and logs load within acceptable time limits",
                "No N+1 query performance issues",
                "Memory usage remains stable during operations",
                "UI updates smoothly without blocking",
                "Concurrent operations don't cause data corruption"
            ],
            description: "Performance and scalability integration testing with realistic load"
        )
    }
}

// MARK: - Supporting Data Structures

/// Container for integration testing scenarios.
public struct IntegrationScenario {
    public let habits: [Habit]
    public let logs: [HabitLog]
    public let categories: [HabitCategory]
    public let testCases: [IntegrationTestCase]
    public let expectedOutcomes: [String]
    public let description: String
    
    public init(habits: [Habit], logs: [HabitLog], categories: [HabitCategory], testCases: [IntegrationTestCase], expectedOutcomes: [String], description: String) {
        self.habits = habits
        self.logs = logs
        self.categories = categories
        self.testCases = testCases
        self.expectedOutcomes = expectedOutcomes
        self.description = description
    }
    
    /// Summary of the integration scenario for reporting.
    public var summary: IntegrationSummary {
        return IntegrationSummary(
            scenarioDescription: description,
            habitCount: habits.count,
            logCount: logs.count,
            categoryCount: categories.count,
            testCaseCount: testCases.count,
            coverageAreas: Set(testCases.map { $0.category })
        )
    }
    
    /// Validates scenario completeness.
    public func validate() -> [String] {
        var issues: [String] = []
        
        if habits.isEmpty {
            issues.append("No habits defined for integration testing")
        }
        
        if testCases.isEmpty {
            issues.append("No test cases defined")
        }
        
        if expectedOutcomes.count != testCases.count {
            issues.append("Mismatch between test cases (\(testCases.count)) and expected outcomes (\(expectedOutcomes.count))")
        }
        
        // Check for orphaned logs
        let habitIDs = Set(habits.map { $0.id })
        let orphanedLogs = logs.filter { !habitIDs.contains($0.habitID) }
        if !orphanedLogs.isEmpty {
            issues.append("\(orphanedLogs.count) orphaned logs reference non-existent habits")
        }
        
        return issues
    }
}

/// Individual test case within an integration scenario.
public struct IntegrationTestCase {
    public let name: String
    public let description: String
    public let category: IntegrationCategory
    
    public init(name: String, description: String, category: IntegrationCategory = .general) {
        self.name = name
        self.description = description
        self.category = category
    }
}

/// Categories of integration testing.
public enum IntegrationCategory {
    case general
    case dataFlow
    case serviceCoordination
    case userInterface
    case performance
    case synchronization
    case businessLogic
}

/// Summary of an integration testing scenario.
public struct IntegrationSummary {
    public let scenarioDescription: String
    public let habitCount: Int
    public let logCount: Int
    public let categoryCount: Int
    public let testCaseCount: Int
    public let coverageAreas: Set<IntegrationCategory>
    
    public var coverageReport: String {
        let areas = coverageAreas.map { "\($0)" }.sorted().joined(separator: ", ")
        return """
        Integration Test Summary:
        - Scenario: \(scenarioDescription)
        - Data: \(habitCount) habits, \(logCount) logs, \(categoryCount) categories
        - Test Cases: \(testCaseCount)
        - Coverage Areas: \(areas)
        """
    }
}

// MARK: - Private Helpers

private extension IntegrationTestFixtures {
    /// Generates realistic logging patterns for integration testing.
    static func generateRealisticLogs(for habit: Habit, days: Int, completionRate: Double) -> [HabitLog] {
        var logs: [HabitLog] = []
        let today = Date()
        
        for dayOffset in -days...0 {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: today)!
            
            // Add weekly variation
            let weekday = Calendar.current.component(.weekday, from: date)
            let isWeekend = weekday == 1 || weekday == 7
            let adjustedRate = isWeekend ? completionRate * 0.7 : completionRate
            
            if Double.random(in: 0...1) <= adjustedRate {
                let value: Double?
                if habit.kind == .numeric {
                    let target = habit.dailyTarget ?? 1.0
                    // Realistic variation around target
                    value = Double.random(in: target * 0.8...target * 1.2)
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
}

// MARK: - Test Suite Factory

public extension IntegrationTestFixtures {
    /// Creates a comprehensive integration test suite.
    static func createComprehensiveTestSuite() -> [IntegrationScenario] {
        return [
            habitCreationToAnalyticsPipeline(),
            batchHabitOperations(),
            streakCalculationIntegration(),
            notificationSchedulingIntegration(),
            dataMigrationSyncIntegration(),
            userProfileHabitIntegration(),
            performanceScalabilityIntegration()
        ]
    }
    
    /// Creates a lightweight integration test suite for quick validation.
    static func createQuickTestSuite() -> [IntegrationScenario] {
        return [
            habitCreationToAnalyticsPipeline(),
            streakCalculationIntegration(),
            notificationSchedulingIntegration()
        ]
    }
}