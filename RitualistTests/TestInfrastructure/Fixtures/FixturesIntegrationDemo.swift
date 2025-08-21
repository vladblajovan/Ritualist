//
//  FixturesIntegrationDemo.swift
//  RitualistTests
//
//  Created by Claude on 21.08.2025.
//

import Testing
import Foundation
@testable import Ritualist
@testable import RitualistCore

/// Demonstration tests showing how to use the specialized test fixtures.
/// These tests validate that fixtures work correctly and demonstrate proper usage patterns.
struct FixturesIntegrationDemo {
    
    // MARK: - Streak Fixtures Demo
    
    @Test("StreakTestFixtures - Perfect Current Streak")
    func streakFixturesPerfectStreakDemo() {
        let scenario = StreakTestFixtures.perfectCurrentStreak(days: 15)
        
        // Validate scenario structure
        #expect(scenario.habit.name.contains("Perfect Streak"))
        #expect(scenario.logs.count == 15)
        #expect(scenario.expectedCurrentStreak == 15)
        #expect(scenario.expectedLongestStreak == 15)
        
        // Validate logs are consecutive and ordered
        let sortedLogs = scenario.logs.sorted { $0.date < $1.date }
        for i in 0..<(sortedLogs.count - 1) {
            let daysDiff = Calendar.current.dateComponents([.day], from: sortedLogs[i].date, to: sortedLogs[i + 1].date).day ?? 0
            #expect(daysDiff == 1, "Logs should be consecutive days")
        }
    }
    
    @Test("StreakTestFixtures - Complex Multi-Schedule Comparison")
    func streakFixturesMultiScheduleDemo() {
        let scenario = StreakTestFixtures.multiScheduleComparison()
        
        // Validate we have different schedule types
        #expect(scenario.habits.count == 4)
        
        let scheduleTypes = Set(scenario.habits.map { 
            switch $0.schedule {
            case .daily: return "daily"
            case .daysOfWeek: return "daysOfWeek"
            case .timesPerWeek: return "timesPerWeek"
            }
        })
        
        #expect(scheduleTypes.count >= 3, "Should have multiple schedule types")
        #expect(!scenario.logs.isEmpty, "Should have logs for analysis")
    }
    
    // MARK: - Notification Fixtures Demo
    
    @Test("NotificationTestFixtures - Multiple Reminders")
    func notificationFixturesMultipleRemindersDemo() {
        let scenario = NotificationTestFixtures.multipleReminderHabit()
        
        #expect(scenario.habits.count == 1)
        #expect(scenario.expectedNotificationCount == 3)
        
        let habit = scenario.habits[0]
        #expect(habit.reminders.count == 3)
        
        // Validate reminder times are properly ordered
        let sortedReminders = habit.reminders.sorted { lhs, rhs in
            if lhs.hour == rhs.hour {
                return lhs.minute < rhs.minute
            }
            return lhs.hour < rhs.hour
        }
        
        #expect(sortedReminders[0].hour == 7)
        #expect(sortedReminders[1].hour == 12)
        #expect(sortedReminders[2].hour == 19)
    }
    
    @Test("NotificationTestFixtures - Schedule Aware Notifications")
    func notificationFixturesScheduleAwareDemo() {
        let scenario = NotificationTestFixtures.scheduleAwareReminders()
        
        #expect(scenario.testFocus == .scheduleAware)
        #expect(scenario.expectedNotificationCount == 5) // Weekdays only
        
        let habit = scenario.habits[0]
        if case .daysOfWeek(let days) = habit.schedule {
            #expect(days.count == 5, "Should be weekdays only")
        } else {
            Issue.record("Expected daysOfWeek schedule")
        }
    }
    
    // MARK: - Performance Fixtures Demo
    
    @Test("PerformanceTestFixtures - Heavy User Scenario")
    func performanceFixturesHeavyUserDemo() {
        let scenario = PerformanceTestFixtures.heavyUserScenario(habitCount: 10, daysOfHistory: 30)
        
        #expect(scenario.habits.count == 10)
        #expect(!scenario.logs.isEmpty)
        #expect(!scenario.categories.isEmpty)
        
        let stats = scenario.statistics
        #expect(stats.habitCount == 10)
        #expect(stats.logCount > 0)
        #expect(stats.avgLogsPerHabit > 0)
        
        // Validate date range
        #expect(stats.dateRange.start != nil)
        #expect(stats.dateRange.end != nil)
    }
    
    @Test("PerformanceTestFixtures - Batch Processing Test Data")
    func performanceFixturesBatchProcessingDemo() {
        let scenario = PerformanceTestFixtures.batchProcessingTestData(habitCount: 5)
        
        #expect(scenario.habits.count == 5)
        #expect(scenario.categories.count > 0)
        
        // Validate consistent logging pattern (30 days per habit)
        for habit in scenario.habits {
            let habitLogs = scenario.logs.filter { $0.habitID == habit.id }
            #expect(habitLogs.count == 30, "Each habit should have 30 days of logs for batch testing")
        }
    }
    
    // MARK: - Edge Case Fixtures Demo
    
    @Test("EdgeCaseFixtures - Leap Year Boundaries")
    func edgeCaseFixturesLeapYearDemo() {
        let scenario = EdgeCaseFixtures.leapYearBoundaries()
        
        #expect(scenario.testCategory == .dateTimeEdgeCases)
        #expect(!scenario.logs.isEmpty)
        
        // Check that we have February 29th in the test data
        let feb29Logs = scenario.logs.filter { log in
            let components = Calendar.current.dateComponents([.month, .day], from: log.date)
            return components.month == 2 && components.day == 29
        }
        
        #expect(!feb29Logs.isEmpty, "Should include February 29th logs")
    }
    
    @Test("EdgeCaseFixtures - Unicode Text Challenges")
    func edgeCaseFixturesUnicodeDemo() {
        let scenario = EdgeCaseFixtures.unicodeTextChallenges()
        
        #expect(scenario.testCategory == .textHandling)
        #expect(scenario.expectedIssues.contains(.unicodeHandling))
        #expect(scenario.habits.count > 1)
        
        // Validate we have diverse text challenges
        let names = scenario.habits.map { $0.name }
        let hasEmoji = names.contains { $0.contains("🏃‍♀️") }
        let hasMixedScript = names.contains { $0.contains("привычка") }
        
        #expect(hasEmoji, "Should include emoji-heavy names")
        #expect(hasMixedScript, "Should include mixed script text")
    }
    
    @Test("EdgeCaseFixtures - Data Integrity Validation")
    func edgeCaseFixturesDataIntegrityDemo() {
        let scenario = EdgeCaseFixtures.corruptedDataScenarios()
        
        let report = EdgeCaseFixtures.validateDataIntegrity(scenario)
        
        // Should detect issues in the corrupted scenario
        #expect(report.hasIssues || report.hasWarnings)
        #expect(!report.issues.isEmpty || !report.warnings.isEmpty)
    }
    
    // MARK: - Integration Fixtures Demo
    
    @Test("IntegrationTestFixtures - Habit Creation Pipeline")
    func integrationFixturesHabitPipelineDemo() {
        let scenario = IntegrationTestFixtures.habitCreationToAnalyticsPipeline()
        
        #expect(scenario.habits.count == 1)
        #expect(scenario.categories.count == 1)
        #expect(!scenario.logs.isEmpty)
        #expect(scenario.testCases.count == 4)
        #expect(scenario.expectedOutcomes.count == scenario.testCases.count)
        
        let validation = scenario.validate()
        #expect(validation.isEmpty, "Scenario should be valid: \(validation)")
        
        // Validate habit-category relationship
        let habit = scenario.habits[0]
        let category = scenario.categories[0]
        #expect(habit.categoryId == category.id, "Habit should be linked to category")
    }
    
    @Test("IntegrationTestFixtures - Streak Calculation Integration")
    func integrationFixturesStreakCalculationDemo() {
        let scenario = IntegrationTestFixtures.streakCalculationIntegration()
        
        #expect(scenario.habits.count == 4)
        #expect(scenario.testCases.count == 5)
        
        // Validate different habit types are included
        let scheduleTypes = scenario.habits.map { habit in
            switch habit.schedule {
            case .daily: return "daily"
            case .daysOfWeek: return "daysOfWeek" 
            case .timesPerWeek: return "timesPerWeek"
            }
        }
        
        #expect(Set(scheduleTypes).count >= 3, "Should include multiple schedule types")
        
        // Validate numeric and binary habits are included
        let kindTypes = Set(scenario.habits.map { $0.kind })
        #expect(kindTypes.contains(.binary))
        #expect(kindTypes.contains(.numeric))
    }
    
    // MARK: - Fixture Interoperability Demo
    
    @Test("Fixtures Interoperability - Combined Usage")
    func fixturesInteroperabilityDemo() {
        // Demonstrate using multiple fixture types together
        
        // 1. Create base scenario from integration fixtures
        let baseScenario = IntegrationTestFixtures.batchHabitOperations()
        
        // 2. Add edge case data
        let edgeCase = EdgeCaseFixtures.unicodeTextChallenges()
        
        // 3. Add performance test data
        let perfData = PerformanceTestFixtures.heavyUserScenario(habitCount: 5, daysOfHistory: 7)
        
        // 4. Combine data for comprehensive testing
        let allHabits = baseScenario.habits + edgeCase.habits + perfData.habits
        let allLogs = baseScenario.logs + edgeCase.logs + perfData.logs
        let allCategories = baseScenario.categories + edgeCase.categories + perfData.categories
        
        #expect(allHabits.count > 10, "Combined fixtures should provide substantial test data")
        #expect(allCategories.count > 3, "Should have diverse category data")
        #expect(!allLogs.isEmpty, "Should have comprehensive log data")
        
        // Validate no duplicate IDs (each fixture should generate unique data)
        let habitIDs = Set(allHabits.map { $0.id })
        let categoryIDs = Set(allCategories.map { $0.id })
        let logIDs = Set(allLogs.map { $0.id })
        
        #expect(habitIDs.count == allHabits.count, "All habit IDs should be unique")
        #expect(categoryIDs.count == allCategories.count, "All category IDs should be unique")
        #expect(logIDs.count == allLogs.count, "All log IDs should be unique")
    }
    
    // MARK: - Performance Validation
    
    @Test("Fixture Performance - Creation Time")
    func fixturePerformanceValidation() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create multiple scenarios to test creation performance
        _ = StreakTestFixtures.perfectCurrentStreak(days: 30)
        _ = NotificationTestFixtures.comprehensiveDailySchedule()
        _ = PerformanceTestFixtures.heavyUserScenario(habitCount: 20, daysOfHistory: 30)
        _ = EdgeCaseFixtures.unicodeTextChallenges()
        _ = IntegrationTestFixtures.habitCreationToAnalyticsPipeline()
        
        let creationTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Fixture creation should be fast (under 1 second for this set)
        #expect(creationTime < 1.0, "Fixture creation should be fast, took \(creationTime) seconds")
    }
}

// MARK: - Usage Examples in Comments

/*
 USAGE EXAMPLES:
 
 1. Testing Streak Calculations:
 ```swift
 @Test func testComplexStreakCalculation() {
     let scenario = StreakTestFixtures.intermittentLongStreaks()
     let service = StreakCalculationService()
     
     let currentStreak = service.calculateCurrentStreak(
         habit: scenario.habit, 
         logs: scenario.logs, 
         asOf: Date()
     )
     
     #expect(currentStreak == scenario.expectedCurrentStreak)
 }
 ```
 
 2. Testing Notification Scheduling:
 ```swift
 @Test func testNotificationScheduling() {
     let scenario = NotificationTestFixtures.overlappingReminders()
     let scheduler = NotificationScheduler()
     
     let notifications = scheduler.schedule(habits: scenario.habits)
     
     #expect(notifications.count == scenario.expectedNotificationCount)
 }
 ```
 
 3. Testing Performance with Large Datasets:
 ```swift
 @Test func testDatabasePerformanceWithLargeDataset() {
     let scenario = PerformanceTestFixtures.heavyUserScenario(
         habitCount: 100, 
         daysOfHistory: 365
     )
     
     let (result, timeInterval) = PerformanceTestFixtures.measure {
         return repository.loadAllHabitsWithLogs()
     }
     
     #expect(timeInterval < 0.5) // Should complete within 500ms
     #expect(result.count == scenario.habits.count)
 }
 ```
 
 4. Testing Edge Cases:
 ```swift
 @Test func testUnicodeHandling() {
     let scenario = EdgeCaseFixtures.unicodeTextChallenges()
     
     for habit in scenario.habits {
         let result = habitService.createHabit(habit)
         #expect(result.isSuccess) // Should handle Unicode correctly
     }
 }
 ```
 
 5. Testing Cross-Service Integration:
 ```swift
 @Test func testEndToEndHabitFlow() {
     let scenario = IntegrationTestFixtures.habitCreationToAnalyticsPipeline()
     
     // Test full pipeline
     let habit = habitService.createHabit(scenario.habits[0])
     let logs = loggingService.bulkCreateLogs(scenario.logs)
     let analytics = analyticsService.generateInsights(habit: habit)
     
     #expect(analytics.streakData.isValid)
 }
 ```
 */