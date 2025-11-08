import Testing
import Foundation
@testable import RitualistCore
@testable import Ritualist

/// Tests for cache sync logic - verifies cache update, removal, and range detection
/// Uses REAL entities (no mocks) to test actual cache behavior
@Suite("Cache Sync Logic Tests")
struct CacheSyncLogicTests {

    // MARK: - OverviewData Helper Tests

    @Test("logs(for:on:) returns logs for specific habit and date")
    func logsForHabitAndDate() {
        // Arrange
        let habit = HabitBuilder.binary(name: "Read")
        let log1 = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)
        let log2 = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.yesterday)

        let data = OverviewDataBuilder.with(habits: [habit], logs: [log1, log2])

        // Act
        let todayLogs = data.logs(for: habit.id, on: TestDates.today)
        let yesterdayLogs = data.logs(for: habit.id, on: TestDates.yesterday)

        // Assert
        #expect(todayLogs.count == 1, "Should find one log for today")
        #expect(yesterdayLogs.count == 1, "Should find one log for yesterday")
        #expect(todayLogs.first?.id == log1.id, "Should return correct log for today")
        #expect(yesterdayLogs.first?.id == log2.id, "Should return correct log for yesterday")
    }

    @Test("logs(for:) returns all logs for date across habits")
    func logsForDate() {
        // Arrange
        let habit1 = HabitBuilder.binary(name: "Read")
        let habit2 = HabitBuilder.binary(name: "Exercise")

        let log1 = HabitLogBuilder.binary(habitId: habit1.id, date: TestDates.today)
        let log2 = HabitLogBuilder.binary(habitId: habit2.id, date: TestDates.today)
        let log3 = HabitLogBuilder.binary(habitId: habit1.id, date: TestDates.yesterday)

        let data = OverviewDataBuilder.with(habits: [habit1, habit2], logs: [log1, log2, log3])

        // Act
        let todayLogs = data.logs(for: TestDates.today)
        let yesterdayLogs = data.logs(for: TestDates.yesterday)

        // Assert
        #expect(todayLogs.count == 2, "Should find 2 logs for today across all habits")
        #expect(yesterdayLogs.count == 1, "Should find 1 log for yesterday")
    }

    @Test("logs(for:on:) returns empty array for habit with no logs")
    func logsForHabitWithNoLogs() {
        // Arrange
        let habit = HabitBuilder.binary(name: "Read")
        let data = OverviewDataBuilder.withHabits([habit])

        // Act
        let logs = data.logs(for: habit.id, on: TestDates.today)

        // Assert
        #expect(logs.isEmpty, "Should return empty array for habit with no logs")
    }

    // MARK: - Date Range Tests

    @Test("Date in cached range returns false for needsReload")
    func dateInRangeDoesNotNeedReload() {
        // Arrange: 30-day cache from today
        let data = OverviewDataBuilder.empty(startDate: TestDates.today)

        // Act & Assert: Test dates within 30-day range
        let testDates = [
            TestDates.today,           // Day 0
            TestDates.daysFromNow(5),  // Day 5
            TestDates.daysFromNow(15), // Day 15
            TestDates.daysFromNow(29)  // Day 29 (last day)
        ]

        for date in testDates {
            let dateStart = CalendarUtils.startOfDayUTC(for: date)
            let needsReload = !data.dateRange.contains(dateStart)
            #expect(!needsReload, "Date \(date) should be in cache range")
        }
    }

    @Test("Date before cached range returns true for needsReload")
    func dateBeforeRangeNeedsReload() {
        // Arrange: Cache starts at today
        let data = OverviewDataBuilder.empty(startDate: TestDates.today)

        // Act: Test date before cache start
        let dateBeforeRange = TestDates.yesterday
        let dateStart = CalendarUtils.startOfDayUTC(for: dateBeforeRange)
        let needsReload = !data.dateRange.contains(dateStart)

        // Assert
        #expect(needsReload, "Date before cache range should need reload")
    }

    @Test("Date after cached range returns true for needsReload")
    func dateAfterRangeNeedsReload() {
        // Arrange: Cache covers 30 days from today
        let data = OverviewDataBuilder.empty(startDate: TestDates.today)

        // Act: Test date after cache end (day 30, outside 0-29 range)
        let dateAfterRange = TestDates.daysFromNow(30)
        let dateStart = CalendarUtils.startOfDayUTC(for: dateAfterRange)
        let needsReload = !data.dateRange.contains(dateStart)

        // Assert
        #expect(needsReload, "Date after cache range should need reload")
    }

    @Test("30-day cache boundary - first day is valid")
    func cacheBoundaryFirstDay() {
        // Arrange
        let startDate = TestDates.today
        let data = OverviewDataBuilder.empty(startDate: startDate)

        // Act
        let dateStart = CalendarUtils.startOfDayUTC(for: startDate)
        let isInRange = data.dateRange.contains(dateStart)

        // Assert
        #expect(isInRange, "First day of cache should be valid")
    }

    @Test("30-day cache boundary - last day (day 29) is valid")
    func cacheBoundaryLastDay() {
        // Arrange
        let startDate = TestDates.today
        let data = OverviewDataBuilder.empty(startDate: startDate)

        // Act: Day 29 (0-indexed, so 30 days total)
        let lastDay = TestDates.daysFromNow(29)
        let dateStart = CalendarUtils.startOfDayUTC(for: lastDay)
        let isInRange = data.dateRange.contains(dateStart)

        // Assert
        #expect(isInRange, "Last day (day 29) of cache should be valid")
    }

    @Test("30-day cache boundary - day 30 triggers reload")
    func cacheBoundaryDay30() {
        // Arrange
        let startDate = TestDates.today
        let data = OverviewDataBuilder.empty(startDate: startDate)

        // Act: Day 30 (outside 0-29 range)
        let day30 = TestDates.daysFromNow(30)
        let dateStart = CalendarUtils.startOfDayUTC(for: day30)
        let needsReload = !data.dateRange.contains(dateStart)

        // Assert
        #expect(needsReload, "Day 30 should be outside cache and need reload")
    }

    // MARK: - Cache Update Simulation Tests
    // Note: These test the logic that updateCachedLog() would use

    @Test("Adding new log to empty cache works correctly")
    func addLogToEmptyCache() {
        // Arrange
        let habit = HabitBuilder.binary(name: "Read")
        let log = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)
        let data = OverviewDataBuilder.withHabits([habit])

        // Act: Simulate adding log to cache
        var habitLogs = data.habitLogs[habit.id] ?? []
        habitLogs.append(log)

        var updatedHabitLogs = data.habitLogs
        updatedHabitLogs[habit.id] = habitLogs

        let updatedData = OverviewData(
            habits: data.habits,
            habitLogs: updatedHabitLogs,
            dateRange: data.dateRange
        )

        // Assert
        #expect(updatedData.habitLogs[habit.id]?.count == 1, "Should have one log after adding")
        #expect(updatedData.habitLogs[habit.id]?.first?.id == log.id, "Should contain the added log")
    }

    @Test("Adding new log to existing habit logs works correctly")
    func addLogToExistingLogs() {
        // Arrange
        let habit = HabitBuilder.binary(name: "Read")
        let existingLog = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.yesterday)
        let newLog = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)

        let data = OverviewDataBuilder.with(habits: [habit], logs: [existingLog])

        // Act: Simulate adding new log
        var habitLogs = data.habitLogs[habit.id] ?? []
        habitLogs.append(newLog)

        var updatedHabitLogs = data.habitLogs
        updatedHabitLogs[habit.id] = habitLogs

        let updatedData = OverviewData(
            habits: data.habits,
            habitLogs: updatedHabitLogs,
            dateRange: data.dateRange
        )

        // Assert
        #expect(updatedData.habitLogs[habit.id]?.count == 2, "Should have 2 logs after adding")
        let logIds = updatedData.habitLogs[habit.id]?.map { $0.id } ?? []
        #expect(logIds.contains(existingLog.id), "Should preserve existing log")
        #expect(logIds.contains(newLog.id), "Should contain new log")
    }

    @Test("Updating existing log preserves log ID")
    func updateExistingLog() {
        // Arrange
        let habit = HabitBuilder.numeric(name: "Water", target: 8.0, unit: "cups")
        let originalLog = HabitLogBuilder.numeric(habitId: habit.id, value: 5.0, date: TestDates.today)

        let data = OverviewDataBuilder.with(habits: [habit], logs: [originalLog])

        // Act: Simulate updating log value
        var habitLogs = data.habitLogs[habit.id] ?? []

        if let existingIndex = habitLogs.firstIndex(where: { $0.id == originalLog.id }) {
            var updatedLog = habitLogs[existingIndex]
            updatedLog.value = 8.0
            habitLogs[existingIndex] = updatedLog
        }

        var updatedHabitLogs = data.habitLogs
        updatedHabitLogs[habit.id] = habitLogs

        let updatedData = OverviewData(
            habits: data.habits,
            habitLogs: updatedHabitLogs,
            dateRange: data.dateRange
        )

        // Assert
        #expect(updatedData.habitLogs[habit.id]?.count == 1, "Should still have one log")
        let updatedLog = updatedData.habitLogs[habit.id]?.first
        #expect(updatedLog?.id == originalLog.id, "Should preserve log ID")
        #expect(updatedLog?.value == 8.0, "Should update log value")
    }

    @Test("Adding log preserves other habit logs")
    func addLogPreservesOtherHabits() {
        // Arrange
        let habit1 = HabitBuilder.binary(name: "Read")
        let habit2 = HabitBuilder.binary(name: "Exercise")

        let log1 = HabitLogBuilder.binary(habitId: habit1.id, date: TestDates.today)
        let log2 = HabitLogBuilder.binary(habitId: habit2.id, date: TestDates.today)

        let data = OverviewDataBuilder.with(habits: [habit1, habit2], logs: [log1])

        // Act: Add log for habit2
        var habitLogs = data.habitLogs[habit2.id] ?? []
        habitLogs.append(log2)

        var updatedHabitLogs = data.habitLogs
        updatedHabitLogs[habit2.id] = habitLogs

        let updatedData = OverviewData(
            habits: data.habits,
            habitLogs: updatedHabitLogs,
            dateRange: data.dateRange
        )

        // Assert
        #expect(updatedData.habitLogs[habit1.id]?.count == 1, "habit1 logs should be preserved")
        #expect(updatedData.habitLogs[habit2.id]?.count == 1, "habit2 should have new log")
        #expect(updatedData.habitLogs[habit1.id]?.first?.id == log1.id, "habit1 log should be unchanged")
    }

    // MARK: - Cache Removal Simulation Tests

    @Test("Removing logs for specific date works correctly")
    func removeLogsForDate() {
        // Arrange
        let habit = HabitBuilder.binary(name: "Read")
        let todayLog = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)
        let yesterdayLog = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.yesterday)

        let data = OverviewDataBuilder.with(habits: [habit], logs: [todayLog, yesterdayLog])

        // Act: Simulate removing logs for today
        var habitLogs = data.habitLogs[habit.id] ?? []
        habitLogs.removeAll { log in
            CalendarUtils.areSameDayUTC(log.date, TestDates.today)
        }

        var updatedHabitLogs = data.habitLogs
        updatedHabitLogs[habit.id] = habitLogs

        let updatedData = OverviewData(
            habits: data.habits,
            habitLogs: updatedHabitLogs,
            dateRange: data.dateRange
        )

        // Assert
        #expect(updatedData.habitLogs[habit.id]?.count == 1, "Should have 1 log remaining")
        #expect(updatedData.habitLogs[habit.id]?.first?.id == yesterdayLog.id, "Should preserve yesterday's log")
    }

    @Test("Removing logs preserves logs from other dates")
    func removeLogsPreservesOtherDates() {
        // Arrange
        let habit = HabitBuilder.binary(name: "Read")
        let dates = TestDates.pastDays(7)
        let logs = HabitLogBuilder.multipleLogs(habitId: habit.id, dates: dates)

        let data = OverviewDataBuilder.with(habits: [habit], logs: logs)

        // Act: Remove only today's log
        var habitLogs = data.habitLogs[habit.id] ?? []
        habitLogs.removeAll { log in
            CalendarUtils.areSameDayUTC(log.date, TestDates.today)
        }

        var updatedHabitLogs = data.habitLogs
        updatedHabitLogs[habit.id] = habitLogs

        let updatedData = OverviewData(
            habits: data.habits,
            habitLogs: updatedHabitLogs,
            dateRange: data.dateRange
        )

        // Assert
        #expect(updatedData.habitLogs[habit.id]?.count == 6, "Should have 6 logs remaining (removed 1 of 7)")

        // Verify today's log is gone
        let todayLogs = updatedData.logs(for: habit.id, on: TestDates.today)
        #expect(todayLogs.isEmpty, "Today's log should be removed")

        // Verify other logs preserved
        let yesterdayLogs = updatedData.logs(for: habit.id, on: TestDates.yesterday)
        #expect(!yesterdayLogs.isEmpty, "Yesterday's log should be preserved")
    }

    @Test("Removing logs from empty cache handles gracefully")
    func removeLogsFromEmptyCache() {
        // Arrange
        let habit = HabitBuilder.binary(name: "Read")
        let data = OverviewDataBuilder.withHabits([habit])

        // Act: Try to remove logs when none exist
        var habitLogs = data.habitLogs[habit.id] ?? []
        let beforeCount = habitLogs.count
        habitLogs.removeAll { log in
            CalendarUtils.areSameDayUTC(log.date, TestDates.today)
        }

        // Assert
        #expect(beforeCount == 0, "Should start with no logs")
        #expect(habitLogs.isEmpty, "Should remain empty after removal attempt")
    }

    // MARK: - Migration Detection Logic Tests

    @Test("Migration detection: true→false transition detected")
    func migrationTrueToFalseTransition() {
        // Arrange
        var wasMigrating = true
        let currentlyMigrating = false

        // Act: Simulate checkMigrationAndInvalidateCache logic
        let justCompletedMigration = wasMigrating && !currentlyMigrating
        wasMigrating = currentlyMigrating

        // Assert
        #expect(justCompletedMigration == true, "Should detect migration completion")
        #expect(wasMigrating == false, "Should update tracking state")
    }

    @Test("Migration detection: false→false ignored (no change)")
    func migrationFalseToFalse() {
        // Arrange
        var wasMigrating = false
        let currentlyMigrating = false

        // Act
        let justCompletedMigration = wasMigrating && !currentlyMigrating
        wasMigrating = currentlyMigrating

        // Assert
        #expect(justCompletedMigration == false, "Should not detect migration when none occurred")
        #expect(wasMigrating == false, "Should remain false")
    }

    @Test("Migration detection: true→true ignored (still migrating)")
    func migrationTrueToTrue() {
        // Arrange
        var wasMigrating = true
        let currentlyMigrating = true

        // Act
        let justCompletedMigration = wasMigrating && !currentlyMigrating
        wasMigrating = currentlyMigrating

        // Assert
        #expect(justCompletedMigration == false, "Should not detect completion while still migrating")
        #expect(wasMigrating == true, "Should remain true")
    }

    @Test("Migration detection: false→true (migration starts)")
    func migrationFalseToTrue() {
        // Arrange
        var wasMigrating = false
        let currentlyMigrating = true

        // Act
        let justCompletedMigration = wasMigrating && !currentlyMigrating
        wasMigrating = currentlyMigrating

        // Assert
        #expect(justCompletedMigration == false, "Migration starting is not completion")
        #expect(wasMigrating == true, "Should update to track active migration")
    }
}
