import Foundation
@testable import RitualistCore

/// Convenience constructors for creating real test entities
/// NO MOCKS - these create actual Habit, HabitLog, and OverviewData instances

// MARK: - Habit Builder

enum HabitBuilder {

    /// Create a binary habit with sensible defaults
    static func binary(
        id: UUID = UUID(),
        name: String = "Test Habit",
        emoji: String = "🎯",
        categoryId: String? = nil,
        schedule: HabitSchedule = .daily,
        isActive: Bool = true,
        displayOrder: Int = 0
    ) -> Habit {
        return Habit(
            id: id,
            name: name,
            colorHex: "#2DA9E3",
            emoji: emoji,
            kind: .binary,
            unitLabel: nil,
            dailyTarget: nil,
            schedule: schedule,
            reminders: [],
            startDate: Date(),
            endDate: nil,
            isActive: isActive,
            displayOrder: displayOrder,
            categoryId: categoryId,
            suggestionId: nil,
            isPinned: false,
            notes: nil,
            lastCompletedDate: nil,
            archivedDate: nil,
            locationConfiguration: nil,
            priorityLevel: nil
        )
    }

    /// Create a numeric habit with sensible defaults
    static func numeric(
        id: UUID = UUID(),
        name: String = "Test Numeric",
        emoji: String = "📊",
        target: Double = 10.0,
        unit: String = "times",
        categoryId: String? = nil,
        schedule: HabitSchedule = .daily,
        isActive: Bool = true,
        displayOrder: Int = 0
    ) -> Habit {
        return Habit(
            id: id,
            name: name,
            colorHex: "#2DA9E3",
            emoji: emoji,
            kind: .numeric,
            unitLabel: unit,
            dailyTarget: target,
            schedule: schedule,
            reminders: [],
            startDate: Date(),
            endDate: nil,
            isActive: isActive,
            displayOrder: displayOrder,
            categoryId: categoryId,
            suggestionId: nil,
            isPinned: false,
            notes: nil,
            lastCompletedDate: nil,
            archivedDate: nil,
            locationConfiguration: nil,
            priorityLevel: nil
        )
    }

    /// Create multiple binary habits with sequential names
    static func multipleBinary(count: Int, baseName: String = "Habit") -> [Habit] {
        return (0..<count).map { index in
            binary(
                id: UUID(),
                name: "\(baseName) \(index + 1)",
                displayOrder: index
            )
        }
    }
}

// MARK: - HabitLog Builder

enum HabitLogBuilder {

    /// Create a binary habit log (value = 1.0)
    static func binary(
        id: UUID = UUID(),
        habitId: UUID,
        date: Date = Date(),
        timezone: String = TimeZone.current.identifier
    ) -> HabitLog {
        return HabitLog(
            id: id,
            habitID: habitId,
            date: CalendarUtils.startOfDayLocal(for: date),
            value: 1.0,
            timezone: timezone
        )
    }

    /// Create a numeric habit log with specified value
    static func numeric(
        id: UUID = UUID(),
        habitId: UUID,
        value: Double,
        date: Date = Date(),
        timezone: String = TimeZone.current.identifier
    ) -> HabitLog {
        return HabitLog(
            id: id,
            habitID: habitId,
            date: CalendarUtils.startOfDayLocal(for: date),
            value: value,
            timezone: timezone
        )
    }

    /// Create multiple logs for the same habit across different dates
    static func multipleLogs(
        habitId: UUID,
        dates: [Date],
        value: Double = 1.0
    ) -> [HabitLog] {
        return dates.map { date in
            HabitLog(
                id: UUID(),
                habitID: habitId,
                date: CalendarUtils.startOfDayLocal(for: date),
                value: value,
                timezone: TimeZone.current.identifier
            )
        }
    }
}

// MARK: - OverviewData Builder

enum OverviewDataBuilder {

    /// Create empty overview data with default 30-day range
    static func empty(
        startDate: Date = TestDates.today
    ) -> OverviewData {
        let endDate = CalendarUtils.addDays(29, to: startDate)
        return OverviewData(
            habits: [],
            habitLogs: [:],
            dateRange: CalendarUtils.startOfDayLocal(for: startDate)...CalendarUtils.startOfDayLocal(for: endDate)
        )
    }

    /// Create overview data with habits but no logs
    static func withHabits(
        _ habits: [Habit],
        startDate: Date = TestDates.today
    ) -> OverviewData {
        let endDate = CalendarUtils.addDays(29, to: startDate)
        return OverviewData(
            habits: habits,
            habitLogs: [:],
            dateRange: CalendarUtils.startOfDayLocal(for: startDate)...CalendarUtils.startOfDayLocal(for: endDate)
        )
    }

    /// Create overview data with habits and logs
    static func with(
        habits: [Habit],
        logs: [HabitLog],
        startDate: Date = TestDates.today
    ) -> OverviewData {
        // Group logs by habit ID
        var habitLogs: [UUID: [HabitLog]] = [:]
        for log in logs {
            if habitLogs[log.habitID] == nil {
                habitLogs[log.habitID] = []
            }
            habitLogs[log.habitID]?.append(log)
        }

        let endDate = CalendarUtils.addDays(29, to: startDate)
        return OverviewData(
            habits: habits,
            habitLogs: habitLogs,
            dateRange: CalendarUtils.startOfDayLocal(for: startDate)...CalendarUtils.startOfDayLocal(for: endDate)
        )
    }

    /// Create overview data with specific date range
    static func withDateRange(
        habits: [Habit] = [],
        logs: [HabitLog] = [],
        dateRange: ClosedRange<Date>
    ) -> OverviewData {
        // Group logs by habit ID
        var habitLogs: [UUID: [HabitLog]] = [:]
        for log in logs {
            if habitLogs[log.habitID] == nil {
                habitLogs[log.habitID] = []
            }
            habitLogs[log.habitID]?.append(log)
        }

        return OverviewData(
            habits: habits,
            habitLogs: habitLogs,
            dateRange: dateRange
        )
    }
}
