//
//  NotificationTestFixtures.swift
//  RitualistTests
//
//  Created by Claude on 21.08.2025.
//

import Foundation
@testable import RitualistCore

/// Specialized fixtures for testing habit notification scenarios.
/// These fixtures provide complex multi-habit notification configurations
/// for testing reminder scheduling, timezone handling, and notification batching.
public struct NotificationTestFixtures {
    
    // MARK: - Single Habit Notification Patterns
    
    /// Creates a habit with multiple daily reminders at different times.
    /// Perfect for testing notification scheduling and conflict resolution.
    public static func multipleReminderHabit() -> NotificationScenario {
        let morningReminder = ReminderTime(hour: 7, minute: 30)
        let lunchReminder = ReminderTime(hour: 12, minute: 0)
        let eveningReminder = ReminderTime(hour: 19, minute: 15)
        
        let habit = TestHabit.readingHabit()
            .withName("Multi-Reminder Habit")
            .withReminders([morningReminder, lunchReminder, eveningReminder])
            .build()
        
        return NotificationScenario(
            habits: [habit],
            expectedNotificationCount: 3,
            description: "Single habit with multiple daily reminders",
            testFocus: .multipleReminders
        )
    }
    
    /// Creates a habit with reminders that only apply on scheduled days.
    /// Tests schedule-aware notification logic.
    public static func scheduleAwareReminders() -> NotificationScenario {
        let workoutReminder = ReminderTime(hour: 6, minute: 30)
        
        let habit = TestHabit.workoutHabit()
            .withName("Weekday Workout")
            .forDaysOfWeek([1, 2, 3, 4, 5]) // Monday-Friday only
            .withReminders([workoutReminder])
            .build()
        
        return NotificationScenario(
            habits: [habit],
            expectedNotificationCount: 5, // Only weekdays
            description: "Habit reminders only on scheduled days",
            testFocus: .scheduleAware
        )
    }
    
    /// Creates a habit with early morning and late evening reminders.
    /// Tests boundary time handling (e.g., 6 AM and 11 PM).
    public static func boundaryTimeReminders() -> NotificationScenario {
        let earlyMorning = ReminderTime(hour: 6, minute: 0)
        let lateEvening = ReminderTime(hour: 23, minute: 0)
        
        let habit = TestHabit.simpleBinaryHabit()
            .withName("Boundary Time Habit")
            .withReminders([earlyMorning, lateEvening])
            .build()
        
        return NotificationScenario(
            habits: [habit],
            expectedNotificationCount: 2,
            description: "Reminders at day boundary times",
            testFocus: .boundaryTimes
        )
    }
    
    // MARK: - Multi-Habit Notification Scenarios
    
    /// Creates overlapping reminder times across multiple habits.
    /// Tests notification batching and priority handling.
    public static func overlappingReminders() -> NotificationScenario {
        let reminder8AM = ReminderTime(hour: 8, minute: 0)
        let reminder8_15AM = ReminderTime(hour: 8, minute: 15)
        let reminder8_30AM = ReminderTime(hour: 8, minute: 30)
        
        let habit1 = TestHabit.readingHabit()
            .withName("Morning Reading")
            .withReminders([reminder8AM])
            .build()
        
        let habit2 = TestHabit.meditationHabit()
            .withName("Morning Meditation")
            .withReminders([reminder8_15AM])
            .build()
        
        let habit3 = TestHabit.waterIntakeHabit()
            .withName("Water Reminder")
            .withReminders([reminder8_30AM])
            .build()
        
        return NotificationScenario(
            habits: [habit1, habit2, habit3],
            expectedNotificationCount: 3,
            description: "Multiple habits with overlapping morning reminders",
            testFocus: .overlappingTimes
        )
    }
    
    /// Creates habits with identical reminder times.
    /// Tests notification consolidation logic.
    public static func identicalReminderTimes() -> NotificationScenario {
        let reminderTime = ReminderTime(hour: 9, minute: 0)
        
        let habits = [
            TestHabit.simpleBinaryHabit()
                .withName("Task 1")
                .withReminders([reminderTime])
                .build(),
            TestHabit.simpleBinaryHabit()
                .withName("Task 2")
                .withReminders([reminderTime])
                .build(),
            TestHabit.simpleBinaryHabit()
                .withName("Task 3")
                .withReminders([reminderTime])
                .build()
        ]
        
        return NotificationScenario(
            habits: habits,
            expectedNotificationCount: 1, // Should be consolidated
            description: "Multiple habits with identical reminder times",
            testFocus: .consolidation
        )
    }
    
    /// Creates a comprehensive daily notification schedule.
    /// Tests full-day notification distribution and spacing.
    public static func comprehensiveDailySchedule() -> NotificationScenario {
        let habits = [
            // Early morning
            TestHabit.simpleBinaryHabit()
                .withName("Wake Up Stretch")
                .withReminders([ReminderTime(hour: 6, minute: 30)])
                .build(),
            
            // Morning
            TestHabit.waterIntakeHabit()
                .withName("Morning Water")
                .withReminders([ReminderTime(hour: 8, minute: 0)])
                .build(),
            
            // Mid-morning
            TestHabit.workoutHabit()
                .withName("Exercise")
                .forDaysOfWeek([1, 2, 3, 4, 5])
                .withReminders([ReminderTime(hour: 10, minute: 30)])
                .build(),
            
            // Lunch
            TestHabit.simpleBinaryHabit()
                .withName("Healthy Lunch")
                .withReminders([ReminderTime(hour: 12, minute: 30)])
                .build(),
            
            // Afternoon
            TestHabit.readingHabit()
                .withName("Learning Time")
                .withReminders([ReminderTime(hour: 15, minute: 0)])
                .build(),
            
            // Evening
            TestHabit.meditationHabit()
                .withName("Evening Meditation")
                .withReminders([ReminderTime(hour: 18, minute: 45)])
                .build(),
            
            // Night
            TestHabit.simpleBinaryHabit()
                .withName("Bedtime Routine")
                .withReminders([ReminderTime(hour: 21, minute: 30)])
                .build()
        ]
        
        return NotificationScenario(
            habits: habits,
            expectedNotificationCount: 7, // One per habit (workout has 5 per week)
            description: "Comprehensive daily notification schedule from morning to night",
            testFocus: .fullDayDistribution
        )
    }
    
    // MARK: - Edge Case Notification Scenarios
    
    /// Creates habits with no reminders.
    /// Tests handling of habits without notification requirements.
    public static func noReminders() -> NotificationScenario {
        let habits = [
            TestHabit.simpleBinaryHabit()
                .withName("No Reminder Habit 1")
                .build(),
            TestHabit.waterIntakeHabit()
                .withName("No Reminder Habit 2")
                .build()
        ]
        
        return NotificationScenario(
            habits: habits,
            expectedNotificationCount: 0,
            description: "Habits without any reminder notifications",
            testFocus: .noReminders
        )
    }
    
    /// Creates inactive habits with reminders.
    /// Tests that inactive habits don't generate notifications.
    public static func inactiveHabitsWithReminders() -> NotificationScenario {
        let reminder = ReminderTime(hour: 10, minute: 0)
        
        let habits = [
            TestHabit.simpleBinaryHabit()
                .withName("Active Habit")
                .withReminders([reminder])
                .build(),
            TestHabit.simpleBinaryHabit()
                .withName("Inactive Habit")
                .withReminders([reminder])
                .asInactive()
                .build()
        ]
        
        return NotificationScenario(
            habits: habits,
            expectedNotificationCount: 1, // Only active habit
            description: "Mix of active and inactive habits with reminders",
            testFocus: .activeOnly
        )
    }
    
    /// Creates habits with future start dates.
    /// Tests that future habits don't generate immediate notifications.
    public static func futureHabitsWithReminders() -> NotificationScenario {
        let reminder = ReminderTime(hour: 9, minute: 0)
        
        let habits = [
            TestHabit.simpleBinaryHabit()
                .withName("Current Habit")
                .withReminders([reminder])
                .build(),
            TestHabit.simpleBinaryHabit()
                .withName("Future Habit")
                .withReminders([reminder])
                .startingDaysFromNow(7)
                .build()
        ]
        
        return NotificationScenario(
            habits: habits,
            expectedNotificationCount: 1, // Only current habit
            description: "Mix of current and future-starting habits",
            testFocus: .currentOnly
        )
    }
    
    // MARK: - Weekly Pattern Testing
    
    /// Creates habits with different weekly reminder patterns.
    /// Tests complex weekly notification scheduling.
    public static func weeklyPatternReminders() -> NotificationScenario {
        let habits = [
            // Every day
            TestHabit.simpleBinaryHabit()
                .withName("Daily Habit")
                .asDaily()
                .withReminders([ReminderTime(hour: 8, minute: 0)])
                .build(),
            
            // Weekdays only
            TestHabit.workoutHabit()
                .withName("Weekday Habit")
                .forDaysOfWeek([1, 2, 3, 4, 5])
                .withReminders([ReminderTime(hour: 7, minute: 0)])
                .build(),
            
            // Weekends only
            TestHabit.simpleBinaryHabit()
                .withName("Weekend Habit")
                .forDaysOfWeek([6, 7])
                .withReminders([ReminderTime(hour: 10, minute: 0)])
                .build(),
            
            // Specific days (M, W, F)
            TestHabit.flexibleHabit()
                .withName("MWF Habit")
                .forDaysOfWeek([1, 3, 5])
                .withReminders([ReminderTime(hour: 18, minute: 0)])
                .build(),
            
            // Times per week (any 3 days)
            TestHabit.flexibleHabit()
                .withName("3x Per Week")
                .forTimesPerWeek(3)
                .withReminders([ReminderTime(hour: 12, minute: 0)])
                .build()
        ]
        
        return NotificationScenario(
            habits: habits,
            expectedNotificationCount: 5, // All habits active
            description: "Various weekly reminder patterns",
            testFocus: .weeklyPatterns
        )
    }
    
    // MARK: - Performance Testing Scenarios
    
    /// Creates a large number of habits with various reminder patterns.
    /// Tests notification system performance with high habit counts.
    public static func highVolumeNotifications(habitCount: Int = 50) -> NotificationScenario {
        var habits: [Habit] = []
        let reminderTimes = [
            ReminderTime(hour: 6, minute: 0),
            ReminderTime(hour: 9, minute: 0),
            ReminderTime(hour: 12, minute: 0),
            ReminderTime(hour: 15, minute: 0),
            ReminderTime(hour: 18, minute: 0),
            ReminderTime(hour: 21, minute: 0)
        ]
        
        for i in 0..<habitCount {
            let reminderIndex = i % reminderTimes.count
            let habit = TestHabit.simpleBinaryHabit()
                .withName("Habit \(i + 1)")
                .withReminders([reminderTimes[reminderIndex]])
                .build()
            habits.append(habit)
        }
        
        return NotificationScenario(
            habits: habits,
            expectedNotificationCount: 6, // Should be consolidated by time
            description: "High volume notification testing with \(habitCount) habits",
            testFocus: .performance
        )
    }
}

// MARK: - Supporting Data Structures

/// Container for notification testing scenarios.
public struct NotificationScenario {
    public let habits: [Habit]
    public let expectedNotificationCount: Int
    public let description: String
    public let testFocus: NotificationTestFocus
    
    public init(habits: [Habit], expectedNotificationCount: Int, description: String, testFocus: NotificationTestFocus) {
        self.habits = habits
        self.expectedNotificationCount = expectedNotificationCount
        self.description = description
        self.testFocus = testFocus
    }
    
    /// Returns all unique reminder times across all habits.
    public var allReminderTimes: [ReminderTime] {
        let allReminders = habits.flatMap { $0.reminders }
        return Array(Set(allReminders)).sorted { lhs, rhs in
            if lhs.hour == rhs.hour {
                return lhs.minute < rhs.minute
            }
            return lhs.hour < rhs.hour
        }
    }
    
    /// Returns habits filtered by active status.
    public var activeHabits: [Habit] {
        return habits.filter { $0.isActive }
    }
    
    /// Returns habits that have reminders configured.
    public var habitsWithReminders: [Habit] {
        return habits.filter { !$0.reminders.isEmpty }
    }
}

/// Categories of notification testing focus areas.
public enum NotificationTestFocus {
    case multipleReminders
    case scheduleAware
    case boundaryTimes
    case overlappingTimes
    case consolidation
    case fullDayDistribution
    case noReminders
    case activeOnly
    case currentOnly
    case weeklyPatterns
    case performance
}

// MARK: - Notification Validation Utilities

public extension NotificationTestFixtures {
    
    /// Validates that reminder times are properly formatted.
    static func validateReminderTimes(_ reminders: [ReminderTime]) -> Bool {
        return reminders.allSatisfy { reminder in
            reminder.hour >= 0 && reminder.hour <= 23 &&
            reminder.minute >= 0 && reminder.minute <= 59
        }
    }
    
    /// Creates deterministic reminder times for testing.
    static func createTestReminders(count: Int, startHour: Int = 8) -> [ReminderTime] {
        return (0..<count).map { index in
            let hour = (startHour + index * 2) % 24
            let minute = (index * 15) % 60
            return ReminderTime(hour: hour, minute: minute)
        }
    }
    
    /// Groups habits by their reminder times for batching tests.
    static func groupHabitsByReminderTime(_ habits: [Habit]) -> [ReminderTime: [Habit]] {
        var grouped: [ReminderTime: [Habit]] = [:]
        
        for habit in habits {
            for reminder in habit.reminders {
                if grouped[reminder] == nil {
                    grouped[reminder] = []
                }
                grouped[reminder]?.append(habit)
            }
        }
        
        return grouped
    }
}

// MARK: - Time Zone Testing

public extension NotificationTestFixtures {
    
    /// Creates scenarios for testing notification scheduling across time zones.
    /// Note: This is a placeholder for future timezone-aware testing.
    static func timezoneTestingScenario() -> NotificationScenario {
        let habit = TestHabit.simpleBinaryHabit()
            .withName("Timezone Test Habit")
            .withReminders([ReminderTime(hour: 12, minute: 0)])
            .build()
        
        return NotificationScenario(
            habits: [habit],
            expectedNotificationCount: 1,
            description: "Basic timezone notification handling",
            testFocus: .boundaryTimes
        )
    }
}