//
//  HabitLogBuilder.swift
//  RitualistTests
//
//  Created by Claude on 21.08.2025.
//

import Foundation
@testable import RitualistCore

/// A fluent builder for creating HabitLog test instances with sensible defaults.
///
/// Usage:
/// ```swift
/// let log = HabitLogBuilder()
///     .withHabit(habit)
///     .withDate(Date())
///     .withValue(25.0)
///     .build()
/// ```
public class HabitLogBuilder {
    private var id = UUID()
    private var habitID = UUID()
    private var date = Date()
    private var value: Double? = nil
    
    public init() {}
    
    // MARK: - Fluent API
    
    /// Sets a custom UUID for the log. If not called, a random UUID is generated.
    @discardableResult
    public func withId(_ id: UUID) -> HabitLogBuilder {
        self.id = id
        return self
    }
    
    /// Sets the habit ID that this log belongs to.
    @discardableResult
    public func withHabitId(_ habitID: UUID) -> HabitLogBuilder {
        self.habitID = habitID
        return self
    }
    
    /// Sets the habit that this log belongs to.
    @discardableResult
    public func withHabit(_ habit: Habit) -> HabitLogBuilder {
        self.habitID = habit.id
        return self
    }
    
    /// Sets the date for this log entry.
    @discardableResult
    public func withDate(_ date: Date) -> HabitLogBuilder {
        self.date = date
        return self
    }
    
    /// Sets the numeric value for this log entry (for numeric habits).
    @discardableResult
    public func withValue(_ value: Double?) -> HabitLogBuilder {
        self.value = value
        return self
    }
    
    // MARK: - Date Convenience Methods
    
    /// Sets the log date to today.
    @discardableResult
    public func forToday() -> HabitLogBuilder {
        return self.withDate(Date())
    }
    
    /// Sets the log date to yesterday.
    @discardableResult
    public func forYesterday() -> HabitLogBuilder {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return self.withDate(yesterday)
    }
    
    /// Sets the log date to a specific number of days ago.
    @discardableResult
    public func forDaysAgo(_ days: Int) -> HabitLogBuilder {
        let pastDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return self.withDate(pastDate)
    }
    
    /// Sets the log date to a specific number of days from now.
    @discardableResult
    public func forDaysFromNow(_ days: Int) -> HabitLogBuilder {
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return self.withDate(futureDate)
    }
    
    /// Sets the log date using year, month, and day components.
    @discardableResult
    public func forDate(year: Int, month: Int, day: Int) -> HabitLogBuilder {
        let components = DateComponents(year: year, month: month, day: day)
        let date = Calendar.current.date(from: components) ?? Date()
        return self.withDate(date)
    }
    
    /// Sets the log date to the start of the current week.
    @discardableResult
    public func forStartOfWeek() -> HabitLogBuilder {
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return self.withDate(startOfWeek)
    }
    
    /// Sets the log date to the end of the current week.
    @discardableResult
    public func forEndOfWeek() -> HabitLogBuilder {
        let endOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.end ?? Date()
        return self.withDate(endOfWeek)
    }
    
    // MARK: - Value Convenience Methods
    
    /// Sets the value to nil (appropriate for binary habits or incomplete numeric entries).
    @discardableResult
    public func withNoValue() -> HabitLogBuilder {
        return self.withValue(nil)
    }
    
    /// Sets a random value between the specified min and max for testing.
    @discardableResult
    public func withRandomValue(min: Double = 1.0, max: Double = 100.0) -> HabitLogBuilder {
        let randomValue = Double.random(in: min...max)
        return self.withValue(randomValue)
    }
    
    /// Sets the value to exactly match a habit's daily target (if available).
    @discardableResult
    public func withTargetValue(for habit: Habit) -> HabitLogBuilder {
        return self.withValue(habit.dailyTarget)
    }
    
    /// Sets the value to be 50% of a habit's daily target.
    @discardableResult
    public func withHalfTargetValue(for habit: Habit) -> HabitLogBuilder {
        let halfTarget = habit.dailyTarget.map { $0 * 0.5 }
        return self.withValue(halfTarget)
    }
    
    /// Sets the value to exceed a habit's daily target by 20%.
    @discardableResult
    public func withExceedingTargetValue(for habit: Habit) -> HabitLogBuilder {
        let exceedingTarget = habit.dailyTarget.map { $0 * 1.2 }
        return self.withValue(exceedingTarget)
    }
    
    // MARK: - Type-Specific Methods
    
    /// Configures the log for a binary habit with completion value (1.0 = completed).
    @discardableResult
    public func forBinaryHabit() -> HabitLogBuilder {
        return self.withValue(1.0)
    }
    
    /// Configures the log for an incomplete binary habit (no value = not completed).
    @discardableResult
    public func forIncompleteBinaryHabit() -> HabitLogBuilder {
        return self.withNoValue()
    }
    
    /// Configures the log for a numeric habit with a specific value.
    @discardableResult
    public func forNumericHabit(value: Double) -> HabitLogBuilder {
        return self.withValue(value)
    }
    
    // MARK: - Build
    
    /// Creates the HabitLog instance with all configured properties.
    public func build() -> HabitLog {
        return HabitLog(
            id: id,
            habitID: habitID,
            date: date,
            value: value
        )
    }
}

// MARK: - Batch Creation Methods

public extension HabitLogBuilder {
    /// Creates multiple log entries for consecutive days.
    /// - Parameters:
    ///   - habit: The habit to create logs for
    ///   - days: Number of consecutive days
    ///   - startDate: Starting date (defaults to today)
    /// - Returns: Array of HabitLog instances
    static func createConsecutiveLogs(
        for habit: Habit,
        days: Int,
        startDate: Date = Date()
    ) -> [HabitLog] {
        var logs: [HabitLog] = []
        
        for dayOffset in 0..<days {
            let logDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: startDate) ?? startDate
            
            let log = HabitLogBuilder()
                .withHabit(habit)
                .withDate(logDate)
                .withTargetValue(for: habit)
                .build()
            
            logs.append(log)
        }
        
        return logs
    }
    
    /// Creates log entries for the past week with varying completion rates.
    /// - Parameters:
    ///   - habit: The habit to create logs for
    ///   - completionRate: Percentage of days completed (0.0 to 1.0)
    /// - Returns: Array of HabitLog instances
    static func createWeeklyLogs(
        for habit: Habit,
        completionRate: Double = 0.7
    ) -> [HabitLog] {
        var logs: [HabitLog] = []
        let today = Date()
        
        for dayOffset in -6...0 {
            // Randomly decide if this day should have a log based on completion rate
            if Double.random(in: 0...1) <= completionRate {
                let logDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: today) ?? today
                
                let log = HabitLogBuilder()
                    .withHabit(habit)
                    .withDate(logDate)
                    .withTargetValue(for: habit)
                    .build()
                
                logs.append(log)
            }
        }
        
        return logs
    }
    
    /// Creates log entries for the past month with realistic patterns.
    /// - Parameters:
    ///   - habit: The habit to create logs for
    ///   - pattern: Pattern type for log creation
    /// - Returns: Array of HabitLog instances
    static func createMonthlyLogs(
        for habit: Habit,
        pattern: LogPattern = .consistent
    ) -> [HabitLog] {
        var logs: [HabitLog] = []
        let today = Date()
        
        for dayOffset in -29...0 {
            let logDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: today) ?? today
            let shouldCreateLog = pattern.shouldCreateLog(for: dayOffset, habit: habit, date: logDate)
            
            if shouldCreateLog {
                let value = pattern.getValue(for: dayOffset, habit: habit)
                
                let log = HabitLogBuilder()
                    .withHabit(habit)
                    .withDate(logDate)
                    .withValue(value)
                    .build()
                
                logs.append(log)
            }
        }
        
        return logs
    }
}

// MARK: - Log Patterns

public enum LogPattern {
    case consistent        // High completion rate (~90%)
    case declining         // Starts high, decreases over time
    case improving         // Starts low, improves over time
    case sporadic         // Random gaps
    case weekendsOnly     // Only weekends
    case weekdaysOnly     // Only weekdays
    case perfect          // Every single day
    
    func shouldCreateLog(for dayOffset: Int, habit: Habit, date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let isWeekend = weekday == 1 || weekday == 7 // Sunday or Saturday
        
        switch self {
        case .consistent:
            return Double.random(in: 0...1) <= 0.9
        case .declining:
            let completionRate = max(0.2, 1.0 + Double(dayOffset) * 0.02) // Decreases from 1.0 to ~0.4
            return Double.random(in: 0...1) <= completionRate
        case .improving:
            let completionRate = min(0.9, 0.2 - Double(dayOffset) * 0.02) // Increases from 0.2 to ~0.8
            return Double.random(in: 0...1) <= completionRate
        case .sporadic:
            return Double.random(in: 0...1) <= 0.4
        case .weekendsOnly:
            return isWeekend
        case .weekdaysOnly:
            return !isWeekend
        case .perfect:
            // Use existing domain service - no code duplication, single source of truth
            return habit.schedule.isActiveOn(date: date)
        }
    }
    
    func getValue(for dayOffset: Int, habit: Habit) -> Double? {
        switch habit.kind {
        case .binary:
            // Binary habits always use 1.0 for completion
            return 1.0
        case .numeric:
            guard let target = habit.dailyTarget else { return 1.0 }
            
            switch self {
            case .declining:
                let efficiency = max(0.5, 1.0 + Double(dayOffset) * 0.01)
                return target * efficiency
            case .improving:
                let efficiency = min(1.2, 0.6 - Double(dayOffset) * 0.015)
                return target * efficiency
            default:
                // Add some realistic variation
                let variation = Double.random(in: 0.8...1.2)
                return target * variation
            }
        }
    }
}

// MARK: - Predefined Log Builders

public extension HabitLogBuilder {
    /// Creates a completed log entry for today.
    static func todayCompleted() -> HabitLogBuilder {
        return HabitLogBuilder()
            .forToday()
            .withNoValue()
    }
    
    /// Creates a log entry with a specific numeric value for today.
    static func todayWithValue(_ value: Double) -> HabitLogBuilder {
        return HabitLogBuilder()
            .forToday()
            .withValue(value)
    }
    
    /// Creates a log entry for yesterday.
    static func yesterdayCompleted() -> HabitLogBuilder {
        return HabitLogBuilder()
            .forYesterday()
            .withNoValue()
    }
    
    /// Creates a log entry from a week ago.
    static func weekAgoCompleted() -> HabitLogBuilder {
        return HabitLogBuilder()
            .forDaysAgo(7)
            .withNoValue()
    }
}