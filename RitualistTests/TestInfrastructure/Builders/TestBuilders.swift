//
//  TestBuilders.swift
//  RitualistTests
//
//  Created by Claude on 21.08.2025.
//

import Foundation
@testable import RitualistCore

// MARK: - Convenience Exports

/// Convenience typealias for HabitBuilder
public typealias TestHabit = HabitBuilder

/// Convenience typealias for HabitLogBuilder  
public typealias TestHabitLog = HabitLogBuilder

/// Convenience typealias for CategoryBuilder
public typealias TestCategory = CategoryBuilder

/// Convenience typealias for UserProfileBuilder
public typealias TestUserProfile = UserProfileBuilder

// MARK: - Quick Access Methods

/// Quick access to all test builders for easy imports
public enum TestBuilders {
    public static func habit() -> HabitBuilder {
        return HabitBuilder()
    }
    
    public static func habitLog() -> HabitLogBuilder {
        return HabitLogBuilder()
    }
    
    public static func category() -> CategoryBuilder {
        return CategoryBuilder()
    }
    
    public static func userProfile() -> UserProfileBuilder {
        return UserProfileBuilder()
    }
}

// MARK: - Common Test Scenarios

/// Pre-configured test scenarios for common testing needs
public struct TestScenarios {
    
    // MARK: - Complete User Scenarios
    
    /// Creates a complete new user scenario with habits and logs
    public static func newUserWithHabits() -> (user: UserProfile, habits: [Habit], logs: [HabitLog]) {
        let user = TestUserProfile.newFreeUser().build()
        
        let readingHabit = TestHabit.readingHabit().build()
        let workoutHabit = TestHabit.workoutHabit().build()
        
        let readingLogs = TestHabitLog.createWeeklyLogs(for: readingHabit, completionRate: 0.8)
        let workoutLogs = TestHabitLog.createWeeklyLogs(for: workoutHabit, completionRate: 0.6)
        
        return (
            user: user,
            habits: [readingHabit, workoutHabit],
            logs: readingLogs + workoutLogs
        )
    }
    
    /// Creates a premium user with advanced habits and comprehensive logs
    public static func premiumUserWithAdvancedHabits() -> (user: UserProfile, habits: [Habit], categories: [HabitCategory], logs: [HabitLog]) {
        let user = TestUserProfile.premiumAnnualUser().build()
        let categories = TestCategory.createPredefinedCategories()
        
        let habits = [
            TestHabit.readingHabit()
                .withCategory(categories.first { $0.id == "learning" })
                .build(),
            TestHabit.workoutHabit()
                .withCategory(categories.first { $0.id == "health" })
                .build(),
            TestHabit.waterIntakeHabit()
                .withCategory(categories.first { $0.id == "health" })
                .build(),
            TestHabit.meditationHabit()
                .withCategory(categories.first { $0.id == "mindfulness" })
                .build()
        ]
        
        let logs = habits.flatMap { habit in
            TestHabitLog.createMonthlyLogs(for: habit, pattern: .consistent)
        }
        
        return (
            user: user,
            habits: habits,
            categories: categories,
            logs: logs
        )
    }
    
    /// Creates a user with declining motivation (for testing coaching features)
    public static func decliningMotivationUser() -> (user: UserProfile, habits: [Habit], logs: [HabitLog]) {
        let user = TestUserProfile.establishedFreeUser().build()
        
        let habits = [
            TestHabit.workoutHabit().build(),
            TestHabit.readingHabit().build()
        ]
        
        let logs = habits.flatMap { habit in
            TestHabitLog.createMonthlyLogs(for: habit, pattern: .declining)
        }
        
        return (
            user: user,
            habits: habits,
            logs: logs
        )
    }
    
    /// Creates a user showing improvement over time
    public static func improvingUser() -> (user: UserProfile, habits: [Habit], logs: [HabitLog]) {
        let user = TestUserProfile.veteranFreeUser().build()
        
        let habits = [
            TestHabit.simpleBinaryHabit().withName("Daily Walk").build(),
            TestHabit.waterIntakeHabit().build()
        ]
        
        let logs = habits.flatMap { habit in
            TestHabitLog.createMonthlyLogs(for: habit, pattern: .improving)
        }
        
        return (
            user: user,
            habits: habits,
            logs: logs
        )
    }
    
    // MARK: - Specific Feature Testing
    
    /// Creates data for testing streak calculations
    public static func streakTestingData() -> (habits: [Habit], logs: [HabitLog]) {
        let perfectHabit = TestHabit.simpleBinaryHabit()
            .withName("Perfect Habit")
            .build()
        
        let sporadicHabit = TestHabit.simpleBinaryHabit()
            .withName("Sporadic Habit")
            .build()
        
        let perfectLogs = TestHabitLog.createMonthlyLogs(for: perfectHabit, pattern: .perfect)
        let sporadicLogs = TestHabitLog.createMonthlyLogs(for: sporadicHabit, pattern: .sporadic)
        
        return (
            habits: [perfectHabit, sporadicHabit],
            logs: perfectLogs + sporadicLogs
        )
    }
    
    /// Creates data for testing schedule-based habits
    public static func scheduleTestingData() -> (habits: [Habit], logs: [HabitLog]) {
        let dailyHabit = TestHabit.simpleBinaryHabit()
            .withName("Daily Task")
            .asDaily()
            .build()
        
        let weekdayHabit = TestHabit.workoutHabit()
            .forDaysOfWeek([1, 2, 3, 4, 5]) // Weekdays
            .build()
        
        let flexibleHabit = TestHabit.flexibleHabit()
            .withName("3x per Week")
            .forTimesPerWeek(3)
            .build()
        
        let habits = [dailyHabit, weekdayHabit, flexibleHabit]
        
        let logs = habits.flatMap { habit in
            TestHabitLog.createWeeklyLogs(for: habit)
        }
        
        return (
            habits: habits,
            logs: logs
        )
    }
    
    /// Creates data for testing numeric vs binary habits
    public static func habitTypesTestingData() -> (habits: [Habit], logs: [HabitLog]) {
        let binaryHabits = [
            TestHabit.simpleBinaryHabit().withName("Binary Task 1").build(),
            TestHabit.simpleBinaryHabit().withName("Binary Task 2").build()
        ]
        
        let numericHabits = [
            TestHabit.waterIntakeHabit().build(),
            TestHabit.readingHabit().build(),
            TestHabit.meditationHabit().build()
        ]
        
        let allHabits = binaryHabits + numericHabits
        
        let logs = allHabits.flatMap { habit in
            TestHabitLog.createWeeklyLogs(for: habit, completionRate: 0.8)
        }
        
        return (
            habits: allHabits,
            logs: logs
        )
    }
    
    // MARK: - Subscription Testing
    
    /// Creates scenarios for testing subscription-based features
    public static func subscriptionTestingData() -> [UserProfile] {
        return TestUserProfile.createSubscriptionTestUsers()
    }
    
    // MARK: - Edge Cases
    
    /// Creates edge case data for robust testing
    public static func edgeCaseData() -> (habits: [Habit], logs: [HabitLog], categories: [HabitCategory]) {
        let categories = TestCategory.createMixedCategories()
        
        // Edge case habits
        let habits = [
            // Very old habit
            TestHabit.simpleBinaryHabit()
                .withName("Ancient Habit")
                .startingDaysAgo(365)
                .build(),
            
            // Future habit
            TestHabit.simpleBinaryHabit()
                .withName("Future Habit")
                .startingDaysFromNow(7)
                .build(),
            
            // Inactive habit
            TestHabit.simpleBinaryHabit()
                .withName("Inactive Habit")
                .asInactive()
                .build(),
            
            // Habit with many reminders
            TestHabit.simpleBinaryHabit()
                .withName("Multi-Reminder Habit")
                .withReminder(hour: 7, minute: 0)
                .withReminder(hour: 12, minute: 30)
                .withReminder(hour: 18, minute: 0)
                .build()
        ]
        
        // Create some logs for active habits only
        let activeLogs = habits.filter(\.isActive).flatMap { habit in
            TestHabitLog.createWeeklyLogs(for: habit, completionRate: 0.5)
        }
        
        return (
            habits: habits,
            logs: activeLogs,
            categories: categories
        )
    }
}

// MARK: - Quick Builder Functions

/// Quick functions for the most common test entities
public extension TestBuilders {
    
    /// Creates a simple habit for basic testing
    static func simpleHabit(name: String = "Test Habit") -> Habit {
        return TestHabit()
            .withName(name)
            .build()
    }
    
    /// Creates a simple log for basic testing
    static func simpleLog(for habit: Habit, daysAgo: Int = 0) -> HabitLog {
        return TestHabitLog()
            .withHabit(habit)
            .forDaysAgo(daysAgo)
            .build()
    }
    
    /// Creates a simple category for basic testing
    static func simpleCategory(name: String = "Test Category") -> HabitCategory {
        return TestCategory()
            .withNameAndDisplay(name)
            .build()
    }
    
    /// Creates a simple user profile for basic testing
    static func simpleUser(name: String = "Test User") -> UserProfile {
        return TestUserProfile()
            .withName(name)
            .build()
    }
}

// MARK: - Validation Utilities

public extension TestBuilders {
    /// Validates that all builders can create valid entities
    static func validateAllBuilders() -> Bool {
        let habit = TestBuilders.simpleHabit()
        let log = TestBuilders.simpleLog(for: habit)
        let category = TestBuilders.simpleCategory()
        let user = TestBuilders.simpleUser()
        
        return !habit.name.isEmpty &&
               log.habitID == habit.id &&
               !category.name.isEmpty &&
               !user.name.isEmpty
    }
}