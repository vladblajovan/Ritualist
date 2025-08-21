//
//  EdgeCaseFixtures.swift
//  RitualistTests
//
//  Created by Claude on 21.08.2025.
//

import Foundation
@testable import RitualistCore

/// Specialized fixtures for testing boundary conditions, error scenarios,
/// and edge cases that might cause app failures or unexpected behavior.
public struct EdgeCaseFixtures {
    
    // MARK: - Date and Time Edge Cases
    
    /// Creates habits and logs spanning leap year boundaries.
    /// Tests date calculations across February 29th transitions.
    public static func leapYearBoundaries() -> EdgeCaseScenario {
        // February 29, 2024 was a leap year
        let leapYearFeb29 = Calendar.current.date(from: DateComponents(year: 2024, month: 2, day: 29))!
        let nonLeapYearFeb28 = Calendar.current.date(from: DateComponents(year: 2023, month: 2, day: 28))!
        let marchFirst = Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 1))!
        
        let habit = TestHabit.simpleBinaryHabit()
            .withName("Leap Year Test Habit")
            .withStartDate(nonLeapYearFeb28)
            .build()
        
        let logs = [
            TestHabitLog().withHabit(habit).withDate(nonLeapYearFeb28).build(),
            TestHabitLog().withHabit(habit).withDate(leapYearFeb29).build(),
            TestHabitLog().withHabit(habit).withDate(marchFirst).build()
        ]
        
        return EdgeCaseScenario(
            habits: [habit],
            logs: logs,
            categories: [],
            expectedIssues: [],
            description: "Leap year boundary testing with February 29th",
            testCategory: .dateTimeEdgeCases
        )
    }
    
    /// Creates habits with daylight saving time transitions.
    /// Tests time-sensitive operations during DST changes.
    public static func daylightSavingTransitions() -> EdgeCaseScenario {
        // These dates represent typical DST transitions (varies by timezone)
        let springForward = Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 9))! // Spring DST
        let fallBack = Calendar.current.date(from: DateComponents(year: 2025, month: 11, day: 2))! // Fall DST
        
        let morningHabit = TestHabit.simpleBinaryHabit()
            .withName("Early Morning Habit")
            .withReminder(hour: 2, minute: 30) // During DST transition hour
            .build()
        
        let logs = [
            // Log on spring forward day (loses an hour)
            TestHabitLog().withHabit(morningHabit).withDate(springForward).build(),
            // Log on fall back day (gains an hour)
            TestHabitLog().withHabit(morningHabit).withDate(fallBack).build()
        ]
        
        return EdgeCaseScenario(
            habits: [morningHabit],
            logs: logs,
            categories: [],
            expectedIssues: [.daylightSavingTime],
            description: "Daylight saving time transitions with early morning reminders",
            testCategory: .dateTimeEdgeCases
        )
    }
    
    /// Creates habits with year boundary crossings (December 31/January 1).
    /// Tests year rollover calculations and streak continuity.
    public static func yearBoundaryCrossing() -> EdgeCaseScenario {
        let dec31 = Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 31))!
        let jan1 = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let jan2 = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 2))!
        
        let habit = TestHabit.simpleBinaryHabit()
            .withName("Year Crossing Habit")
            .withStartDate(Calendar.current.date(byAdding: .day, value: -5, to: dec31)!)
            .build()
        
        // Create a streak across year boundary
        var logs: [HabitLog] = []
        for dayOffset in -3...3 {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: jan1)!
            logs.append(TestHabitLog().withHabit(habit).withDate(date).build())
        }
        
        return EdgeCaseScenario(
            habits: [habit],
            logs: logs,
            categories: [],
            expectedIssues: [],
            description: "Year boundary crossing with continuous streak",
            testCategory: .dateTimeEdgeCases
        )
    }
    
    // MARK: - Data Corruption and Invalid States
    
    /// Creates scenarios with invalid or corrupted data.
    /// Tests resilience against malformed data states.
    public static func corruptedDataScenarios() -> EdgeCaseScenario {
        let validHabit = TestHabit.simpleBinaryHabit()
            .withName("Valid Habit")
            .build()
        
        // Habit with corrupted data
        var corruptedHabit = TestHabit.simpleBinaryHabit()
            .withName("") // Empty name (invalid)
            .withColor("invalid-color") // Invalid color format
            .build()
        
        // Force invalid schedule (if possible to construct)
        var invalidScheduleHabit = TestHabit.simpleBinaryHabit()
            .withName("Invalid Schedule Habit")
            .build()
        // Note: In real scenario, this might be corrupted in database
        
        // Logs with mismatched habit IDs
        let orphanedLog = HabitLog(
            id: UUID(),
            habitID: UUID(), // Random UUID not matching any habit
            date: Date(),
            value: nil
        )
        
        // Log with future date (suspicious)
        let futureLog = TestHabitLog()
            .withHabit(validHabit)
            .withDate(Calendar.current.date(byAdding: .year, value: 1, to: Date())!)
            .build()
        
        // Log with extreme past date
        let ancientLog = TestHabitLog()
            .withHabit(validHabit)
            .withDate(Calendar.current.date(from: DateComponents(year: 1900, month: 1, day: 1))!)
            .build()
        
        return EdgeCaseScenario(
            habits: [validHabit, corruptedHabit, invalidScheduleHabit],
            logs: [orphanedLog, futureLog, ancientLog],
            categories: [],
            expectedIssues: [.corruptedData, .orphanedRecords, .invalidDates],
            description: "Corrupted and invalid data states testing",
            testCategory: .dataIntegrity
        )
    }
    
    /// Creates scenarios with extreme numeric values.
    /// Tests handling of boundary values and numeric overflow.
    public static func extremeNumericValues() -> EdgeCaseScenario {
        let numericHabit = TestHabit()
            .withName("Extreme Values Habit")
            .asNumeric(target: Double.greatestFiniteMagnitude, unit: "units") // Extreme target
            .build()
        
        let logs = [
            // Extreme positive value
            TestHabitLog().withHabit(numericHabit).withValue(Double.greatestFiniteMagnitude).forToday().build(),
            // Extreme negative value
            TestHabitLog().withHabit(numericHabit).withValue(-Double.greatestFiniteMagnitude).forYesterday().build(),
            // Infinity (if somehow created)
            TestHabitLog().withHabit(numericHabit).withValue(Double.infinity).forDaysAgo(2).build(),
            // NaN (if somehow created)
            TestHabitLog().withHabit(numericHabit).withValue(Double.nan).forDaysAgo(3).build(),
            // Zero
            TestHabitLog().withHabit(numericHabit).withValue(0.0).forDaysAgo(4).build(),
            // Very small positive
            TestHabitLog().withHabit(numericHabit).withValue(Double.leastNormalMagnitude).forDaysAgo(5).build()
        ]
        
        return EdgeCaseScenario(
            habits: [numericHabit],
            logs: logs,
            categories: [],
            expectedIssues: [.extremeValues, .numericOverflow],
            description: "Extreme numeric values and edge cases",
            testCategory: .numericBoundaries
        )
    }
    
    // MARK: - Unicode and Text Edge Cases
    
    /// Creates habits with challenging Unicode text.
    /// Tests text handling with emojis, special characters, and encoding issues.
    public static func unicodeTextChallenges() -> EdgeCaseScenario {
        let unicodeHabits = [
            // Emoji-heavy name
            TestHabit().withName("🏃‍♀️💪🌟⭐️🎯🔥💯🚀✨").withEmoji("🌈").build(),
            
            // Mixed scripts (Latin, Cyrillic, CJK)
            TestHabit().withName("Habit привычка 習慣 عادة").build(),
            
            // Right-to-left text
            TestHabit().withName("عادة يومية مفيدة").build(),
            
            // Very long name
            TestHabit().withName(String(repeating: "Very Long Habit Name ", count: 50)).build(),
            
            // Empty string and whitespace only
            TestHabit().withName("   ").build(),
            
            // Special characters and symbols
            TestHabit().withName("Habit@#$%^&*(){}[]|\\:;\"'<>?,.~/`").build(),
            
            // Zero-width characters and invisible Unicode
            TestHabit().withName("Invisible\u{200B}Characters\u{FEFF}Here").build()
        ]
        
        let category = TestCategory()
            .withNameAndDisplay("Unicode🌍Category")
            .build()
        
        return EdgeCaseScenario(
            habits: unicodeHabits,
            logs: [],
            categories: [category],
            expectedIssues: [.unicodeHandling, .textEncoding],
            description: "Unicode text challenges and special character handling",
            testCategory: .textHandling
        )
    }
    
    // MARK: - Concurrency and Race Conditions
    
    /// Creates scenarios that might trigger race conditions.
    /// Tests thread safety and concurrent access patterns.
    public static func concurrencyStressTest() -> EdgeCaseScenario {
        let sharedHabit = TestHabit.simpleBinaryHabit()
            .withName("Concurrent Access Habit")
            .build()
        
        var logs: [HabitLog] = []
        let today = Date()
        
        // Create many logs with identical timestamps (race condition scenario)
        for i in 0..<100 {
            logs.append(
                HabitLog(
                    id: UUID(),
                    habitID: sharedHabit.id,
                    date: today, // Same timestamp
                    value: Double(i)
                )
            )
        }
        
        return EdgeCaseScenario(
            habits: [sharedHabit],
            logs: logs,
            categories: [],
            expectedIssues: [.concurrencyIssues],
            description: "Concurrent access and race condition testing",
            testCategory: .concurrency
        )
    }
    
    // MARK: - Memory and Resource Limits
    
    /// Creates scenarios that push memory and resource limits.
    /// Tests behavior under resource constraints.
    public static func resourceExhaustionTest() -> EdgeCaseScenario {
        // Create habit with extremely long fields
        let longDescription = String(repeating: "A", count: 10000)
        let resourceHabit = TestHabit()
            .withName(longDescription)
            .build()
        
        // Create many habits to test memory limits
        var habits: [Habit] = [resourceHabit]
        for i in 0..<1000 {
            habits.append(
                TestHabit().withName("Resource Test Habit \(i)").build()
            )
        }
        
        return EdgeCaseScenario(
            habits: habits,
            logs: [],
            categories: [],
            expectedIssues: [.memoryPressure],
            description: "Resource exhaustion and memory pressure testing",
            testCategory: .resourceLimits
        )
    }
    
    // MARK: - Network and Connectivity Edge Cases
    
    /// Creates scenarios simulating network issues.
    /// Tests behavior during connectivity problems.
    public static func networkConnectivityIssues() -> EdgeCaseScenario {
        let networkHabit = TestHabit.simpleBinaryHabit()
            .withName("Network Test Habit")
            .build()
        
        // Simulate logs that might be created during offline periods
        let offlineLogs = [
            TestHabitLog().withHabit(networkHabit).forToday().build(),
            TestHabitLog().withHabit(networkHabit).forYesterday().build()
        ]
        
        return EdgeCaseScenario(
            habits: [networkHabit],
            logs: offlineLogs,
            categories: [],
            expectedIssues: [.networkConnectivity],
            description: "Network connectivity and offline behavior testing",
            testCategory: .networkIssues
        )
    }
    
    // MARK: - Locale and Internationalization
    
    /// Creates scenarios testing different locale settings.
    /// Tests behavior across different regional settings.
    public static func localeVariations() -> EdgeCaseScenario {
        let habit = TestHabit.simpleBinaryHabit()
            .withName("Locale Test Habit")
            .build()
        
        // Create logs that would be interpreted differently in different locales
        let ambiguousDate = DateComponents(year: 2025, month: 1, day: 12) // Could be Jan 12 or Dec 1 depending on locale
        let testDate = Calendar.current.date(from: ambiguousDate)!
        
        let logs = [
            TestHabitLog().withHabit(habit).withDate(testDate).build()
        ]
        
        return EdgeCaseScenario(
            habits: [habit],
            logs: logs,
            categories: [],
            expectedIssues: [.localeHandling],
            description: "Locale variations and internationalization testing",
            testCategory: .localization
        )
    }
    
    // MARK: - Version Migration Edge Cases
    
    /// Creates scenarios simulating data from older app versions.
    /// Tests backward compatibility and migration robustness.
    public static func legacyDataMigration() -> EdgeCaseScenario {
        // Simulate habit that might have been created with old data structure
        var legacyHabit = TestHabit.simpleBinaryHabit()
            .withName("Legacy Habit")
            .build()
        
        // Simulate fields that might be missing or have old formats
        legacyHabit.colorHex = "#FF0000" // Old color format
        
        // Legacy logs without proper validation
        let legacyLogs = [
            HabitLog(
                id: UUID(),
                habitID: legacyHabit.id,
                date: Date(),
                value: -1.0 // Negative value that might have been allowed in old versions
            )
        ]
        
        return EdgeCaseScenario(
            habits: [legacyHabit],
            logs: legacyLogs,
            categories: [],
            expectedIssues: [.migrationIssues],
            description: "Legacy data migration and backward compatibility",
            testCategory: .dataMigration
        )
    }
}

// MARK: - Supporting Data Structures

/// Container for edge case testing scenarios.
public struct EdgeCaseScenario {
    public let habits: [Habit]
    public let logs: [HabitLog]
    public let categories: [HabitCategory]
    public let expectedIssues: [EdgeCaseIssue]
    public let description: String
    public let testCategory: EdgeCaseCategory
    
    public init(habits: [Habit], logs: [HabitLog], categories: [HabitCategory], expectedIssues: [EdgeCaseIssue], description: String, testCategory: EdgeCaseCategory) {
        self.habits = habits
        self.logs = logs
        self.categories = categories
        self.expectedIssues = expectedIssues
        self.description = description
        self.testCategory = testCategory
    }
    
    /// Validates that the scenario contains expected problematic conditions.
    public func validateExpectedIssues() -> [EdgeCaseIssue] {
        var foundIssues: [EdgeCaseIssue] = []
        
        // Check for empty names
        if habits.contains(where: { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            foundIssues.append(.corruptedData)
        }
        
        // Check for orphaned logs
        let habitIDs = Set(habits.map { $0.id })
        if logs.contains(where: { !habitIDs.contains($0.habitID) }) {
            foundIssues.append(.orphanedRecords)
        }
        
        // Check for extreme dates
        let now = Date()
        let veryOld = Calendar.current.date(byAdding: .year, value: -100, to: now)!
        let veryFuture = Calendar.current.date(byAdding: .year, value: 10, to: now)!
        
        if logs.contains(where: { $0.date < veryOld || $0.date > veryFuture }) {
            foundIssues.append(.invalidDates)
        }
        
        // Check for extreme numeric values
        if logs.contains(where: { log in
            guard let value = log.value else { return false }
            return value.isInfinite || value.isNaN || abs(value) > Double.greatestFiniteMagnitude / 2
        }) {
            foundIssues.append(.extremeValues)
        }
        
        return foundIssues
    }
}

/// Categories of edge case testing.
public enum EdgeCaseCategory {
    case dateTimeEdgeCases
    case dataIntegrity
    case numericBoundaries
    case textHandling
    case concurrency
    case resourceLimits
    case networkIssues
    case localization
    case dataMigration
}

/// Types of issues that edge case scenarios might reveal.
public enum EdgeCaseIssue {
    case daylightSavingTime
    case corruptedData
    case orphanedRecords
    case invalidDates
    case extremeValues
    case numericOverflow
    case unicodeHandling
    case textEncoding
    case concurrencyIssues
    case memoryPressure
    case networkConnectivity
    case localeHandling
    case migrationIssues
}

// MARK: - Validation Utilities

public extension EdgeCaseFixtures {
    
    /// Validates data integrity across all scenarios.
    static func validateDataIntegrity(_ scenario: EdgeCaseScenario) -> DataIntegrityReport {
        var issues: [String] = []
        var warnings: [String] = []
        
        // Validate habits
        for habit in scenario.habits {
            if habit.name.isEmpty {
                issues.append("Habit \(habit.id) has empty name")
            }
            
            if !habit.colorHex.hasPrefix("#") || habit.colorHex.count != 7 {
                warnings.append("Habit \(habit.name) has invalid color format: \(habit.colorHex)")
            }
            
            if habit.kind == .numeric && habit.dailyTarget == nil {
                warnings.append("Numeric habit \(habit.name) has no daily target")
            }
        }
        
        // Validate logs
        let habitIDs = Set(scenario.habits.map { $0.id })
        for log in scenario.logs {
            if !habitIDs.contains(log.habitID) {
                issues.append("Log \(log.id) references non-existent habit \(log.habitID)")
            }
            
            if let value = log.value, value < 0 {
                warnings.append("Log \(log.id) has negative value: \(value)")
            }
        }
        
        return DataIntegrityReport(issues: issues, warnings: warnings)
    }
    
    /// Creates a comprehensive edge case test suite.
    static func comprehensiveEdgeCaseTestSuite() -> [EdgeCaseScenario] {
        return [
            leapYearBoundaries(),
            daylightSavingTransitions(),
            yearBoundaryCrossing(),
            corruptedDataScenarios(),
            extremeNumericValues(),
            unicodeTextChallenges(),
            concurrencyStressTest(),
            resourceExhaustionTest(),
            networkConnectivityIssues(),
            localeVariations(),
            legacyDataMigration()
        ]
    }
}

/// Report of data integrity validation results.
public struct DataIntegrityReport {
    public let issues: [String] // Critical problems that must be fixed
    public let warnings: [String] // Potential problems that should be reviewed
    
    public var hasIssues: Bool {
        return !issues.isEmpty
    }
    
    public var hasWarnings: Bool {
        return !warnings.isEmpty
    }
    
    public var summary: String {
        return """
        Data Integrity Report:
        - Critical Issues: \(issues.count)
        - Warnings: \(warnings.count)
        
        Issues:
        \(issues.isEmpty ? "None" : issues.map { "• \($0)" }.joined(separator: "\n"))
        
        Warnings:
        \(warnings.isEmpty ? "None" : warnings.map { "• \($0)" }.joined(separator: "\n"))
        """
    }
}