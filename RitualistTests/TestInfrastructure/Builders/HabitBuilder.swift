//
//  HabitBuilder.swift
//  RitualistTests
//
//  Created by Claude on 21.08.2025.
//

import Foundation
@testable import RitualistCore

/// A fluent builder for creating Habit test instances with sensible defaults.
///
/// Usage:
/// ```swift
/// let habit = HabitBuilder()
///     .withName("Morning Workout")
///     .withSchedule(.daysOfWeek([1, 3, 5])) // Mon, Wed, Fri
///     .withKind(.numeric)
///     .withDailyTarget(30.0)
///     .withUnitLabel("minutes")
///     .build()
/// ```
public class HabitBuilder {
    private var id = UUID()
    private var name = "Test Habit"
    private var colorHex = "#2DA9E3"
    private var emoji: String? = "⭐️"
    private var kind: HabitKind = .binary
    private var unitLabel: String? = nil
    private var dailyTarget: Double? = nil
    private var schedule: HabitSchedule = .daily
    private var reminders: [ReminderTime] = []
    private var startDate = Date()
    private var endDate: Date? = nil
    private var isActive = true
    private var displayOrder = 0
    private var categoryId: String? = nil
    private var suggestionId: String? = nil
    
    public init() {}
    
    // MARK: - Fluent API
    
    /// Sets a custom UUID for the habit. If not called, a random UUID is generated.
    @discardableResult
    public func withId(_ id: UUID) -> HabitBuilder {
        self.id = id
        return self
    }
    
    /// Sets the habit name.
    @discardableResult
    public func withName(_ name: String) -> HabitBuilder {
        self.name = name
        return self
    }
    
    /// Sets the habit color as a hex string (e.g., "#FF0000").
    @discardableResult
    public func withColor(_ colorHex: String) -> HabitBuilder {
        self.colorHex = colorHex
        return self
    }
    
    /// Sets the habit emoji.
    @discardableResult
    public func withEmoji(_ emoji: String?) -> HabitBuilder {
        self.emoji = emoji
        return self
    }
    
    /// Sets the habit kind (binary or numeric).
    @discardableResult
    public func withKind(_ kind: HabitKind) -> HabitBuilder {
        self.kind = kind
        return self
    }
    
    /// Sets the unit label for numeric habits (e.g., "minutes", "glasses", "pages").
    @discardableResult
    public func withUnitLabel(_ unitLabel: String?) -> HabitBuilder {
        self.unitLabel = unitLabel
        return self
    }
    
    /// Sets the daily target value for numeric habits.
    @discardableResult
    public func withDailyTarget(_ target: Double?) -> HabitBuilder {
        self.dailyTarget = target
        return self
    }
    
    /// Sets the habit schedule.
    @discardableResult
    public func withSchedule(_ schedule: HabitSchedule) -> HabitBuilder {
        self.schedule = schedule
        return self
    }
    
    /// Sets reminder times for the habit.
    @discardableResult
    public func withReminders(_ reminders: [ReminderTime]) -> HabitBuilder {
        self.reminders = reminders
        return self
    }
    
    /// Sets the habit start date.
    @discardableResult
    public func withStartDate(_ startDate: Date) -> HabitBuilder {
        self.startDate = startDate
        return self
    }
    
    /// Sets the habit end date (nil for indefinite habits).
    @discardableResult
    public func withEndDate(_ endDate: Date?) -> HabitBuilder {
        self.endDate = endDate
        return self
    }
    
    /// Sets whether the habit is active.
    @discardableResult
    public func withIsActive(_ isActive: Bool) -> HabitBuilder {
        self.isActive = isActive
        return self
    }
    
    /// Sets the display order for the habit.
    @discardableResult
    public func withDisplayOrder(_ displayOrder: Int) -> HabitBuilder {
        self.displayOrder = displayOrder
        return self
    }
    
    /// Sets the category ID for the habit.
    @discardableResult
    public func withCategoryId(_ categoryId: String?) -> HabitBuilder {
        self.categoryId = categoryId
        return self
    }
    
    /// Sets the habit category using a Category instance.
    @discardableResult
    public func withCategory(_ category: HabitCategory?) -> HabitBuilder {
        self.categoryId = category?.id
        return self
    }
    
    /// Sets the suggestion ID that this habit was created from.
    @discardableResult
    public func withSuggestionId(_ suggestionId: String?) -> HabitBuilder {
        self.suggestionId = suggestionId
        return self
    }
    
    // MARK: - Convenience Methods
    
    /// Creates a numeric habit with standard configuration.
    @discardableResult
    public func asNumeric(target: Double = 1.0, unit: String = "times") -> HabitBuilder {
        return self
            .withKind(.numeric)
            .withDailyTarget(target)
            .withUnitLabel(unit)
    }
    
    /// Creates a binary habit (default).
    @discardableResult
    public func asBinary() -> HabitBuilder {
        return self
            .withKind(.binary)
            .withDailyTarget(nil)
            .withUnitLabel(nil)
    }
    
    /// Creates a daily habit (default).
    @discardableResult
    public func asDaily() -> HabitBuilder {
        return self.withSchedule(.daily)
    }
    
    /// Creates a habit for specific days of the week.
    /// - Parameter days: Array of weekday numbers (1=Monday, 7=Sunday)
    @discardableResult
    public func forDaysOfWeek(_ days: [Int]) -> HabitBuilder {
        return self.withSchedule(.daysOfWeek(Set(days)))
    }
    
    /// Creates a habit for specific days of the week.
    /// - Parameter days: Set of weekday numbers (1=Monday, 7=Sunday)
    @discardableResult
    public func forDaysOfWeek(_ days: Set<Int>) -> HabitBuilder {
        return self.withSchedule(.daysOfWeek(days))
    }
    
    /// Creates a habit for a certain number of times per week.
    @discardableResult
    public func forTimesPerWeek(_ times: Int) -> HabitBuilder {
        return self.withSchedule(.timesPerWeek(times))
    }
    
    /// Adds a single reminder time.
    @discardableResult
    public func withReminder(hour: Int, minute: Int = 0) -> HabitBuilder {
        let newReminder = ReminderTime(hour: hour, minute: minute)
        var currentReminders = self.reminders
        currentReminders.append(newReminder)
        return self.withReminders(currentReminders)
    }
    
    /// Sets the habit as inactive (completed or cancelled).
    @discardableResult
    public func asInactive() -> HabitBuilder {
        return self.withIsActive(false)
    }
    
    /// Sets a start date relative to today.
    @discardableResult
    public func startingDaysAgo(_ days: Int) -> HabitBuilder {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return self.withStartDate(startDate)
    }
    
    /// Sets a start date relative to today.
    @discardableResult
    public func startingDaysFromNow(_ days: Int) -> HabitBuilder {
        let startDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return self.withStartDate(startDate)
    }
    
    // MARK: - Build
    
    /// Creates the Habit instance with all configured properties.
    public func build() -> Habit {
        return Habit(
            id: id,
            name: name,
            colorHex: colorHex,
            emoji: emoji,
            kind: kind,
            unitLabel: unitLabel,
            dailyTarget: dailyTarget,
            schedule: schedule,
            reminders: reminders,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            displayOrder: displayOrder,
            categoryId: categoryId,
            suggestionId: suggestionId
        )
    }
}

// MARK: - Predefined Builders

public extension HabitBuilder {
    /// Creates a basic daily reading habit.
    static func readingHabit() -> HabitBuilder {
        return HabitBuilder()
            .withName("Daily Reading")
            .withEmoji("📚")
            .withColor("#8B5A2B")
            .asNumeric(target: 30, unit: "minutes")
            .withReminder(hour: 20, minute: 0)
    }
    
    /// Creates a workout habit for weekdays.
    static func workoutHabit() -> HabitBuilder {
        return HabitBuilder()
            .withName("Morning Workout")
            .withEmoji("💪")
            .withColor("#FF6B35")
            .asBinary()
            .forDaysOfWeek([1, 2, 3, 4, 5]) // Monday-Friday
            .withReminder(hour: 7, minute: 0)
    }
    
    /// Creates a water intake tracking habit.
    static func waterIntakeHabit() -> HabitBuilder {
        return HabitBuilder()
            .withName("Water Intake")
            .withEmoji("💧")
            .withColor("#4A90E2")
            .asNumeric(target: 8, unit: "glasses")
    }
    
    /// Creates a meditation habit.
    static func meditationHabit() -> HabitBuilder {
        return HabitBuilder()
            .withName("Meditation")
            .withEmoji("🧘")
            .withColor("#9B59B6")
            .asNumeric(target: 10, unit: "minutes")
            .withReminder(hour: 8, minute: 0)
    }
    
    /// Creates a simple binary habit for testing.
    static func simpleBinaryHabit() -> HabitBuilder {
        return HabitBuilder()
            .withName("Simple Task")
            .withEmoji("✅")
            .asBinary()
    }
    
    /// Creates a 3-times-per-week habit for testing flexibility.
    static func flexibleHabit() -> HabitBuilder {
        return HabitBuilder()
            .withName("Flexible Activity")
            .withEmoji("🎯")
            .forTimesPerWeek(3)
    }
}