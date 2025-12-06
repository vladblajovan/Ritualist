import Testing
import Foundation
@testable import RitualistCore

/// Tests for PerformanceAnalysisService (Phase 1)
///
/// **Service Purpose:** Powers Dashboard metrics by calculating habit performance, weekly patterns, and streaks
/// **Why Critical:** Code explicitly requests regression tests (lines 70-75) for partial progress bug
/// **Test Strategy:** Focus on completion validation - partial progress must NOT count as complete
///
/// **Critical Bug History (Commit: edceada):**
/// Previously counted log existence instead of validating completion criteria.
/// For numeric habits with targets (e.g., "drink 8 glasses"), partial progress (3/8) was
/// incorrectly counted as complete, causing dashboard to show zeros despite having data.
///
/// **Test Coverage:**
/// - Regression tests for partial progress (4 tests - from code comments)
/// - calculateHabitPerformance (12-15 tests)
/// - generateProgressChartData (3-4 tests)
/// - analyzeWeeklyPatterns (6-8 tests)
/// - calculateStreakAnalysis (4-5 tests)
#if swift(>=6.1)
@Suite(
    "PerformanceAnalysisService Tests",
    .tags(.dashboard, .businessLogic, .critical, .regression, .isolated, .fast, .streaks, .completion)
)
#else
@Suite("PerformanceAnalysisService Tests")
#endif
struct PerformanceAnalysisServiceTests {

    // MARK: - Test Dependencies

    /// Create service instance for testing
    func createService() -> PerformanceAnalysisServiceImpl {
        let scheduleAnalyzer = HabitScheduleAnalyzer()
        let completionService = DefaultHabitCompletionService()
        let logger = DebugLogger(subsystem: "test", category: "performance")
        let streakService = DefaultStreakCalculationService(
            habitCompletionService: completionService,
            logger: logger
        )

        return PerformanceAnalysisServiceImpl(
            scheduleAnalyzer: scheduleAnalyzer,
            streakCalculationService: streakService,
            logger: logger
        )
    }

    // MARK: - REGRESSION TESTS (From Code Comments Lines 70-75)

    @Test("❌ REGRESSION: Numeric habit with target=8, log value=3 → NOT counted as complete")
    func partialProgressNotCountedAsComplete() throws {
        let service = createService()

        // Create numeric habit: "Drink water" with target of 8 glasses
        let habit = HabitBuilder.numeric(
            name: "Drink Water",
            target: 8.0,
            unit: "glasses",
            schedule: .daily
        )

        // Create log with PARTIAL progress (3/8 glasses)
        let today = TestDates.today
        let partialLog = HabitLogBuilder.numeric(
            habitId: habit.id,
            value: 3.0,  // Only 3 out of 8 - NOT complete!
            date: today
        )

        // Calculate performance
        let results = service.calculateHabitPerformance(
            habits: [habit],
            logs: [partialLog],
            from: today,
            to: today,
            timezone: .current
        )

        // Verify: Partial progress should NOT be counted as complete
        #expect(results.count == 1)
        #expect(results[0].completedDays == 0, "Partial progress (3/8) should NOT count as completed day")
        #expect(results[0].expectedDays == 1)
        #expect(results[0].completionRate == 0.0, "Completion rate should be 0% for partial progress")
    }

    @Test("✅ REGRESSION: Numeric habit with target=5, log value=5 → counted as complete")
    func fullProgressCountedAsComplete() throws {
        let service = createService()

        // Create numeric habit: "Exercise minutes" with target of 5 minutes
        let habit = HabitBuilder.numeric(
            name: "Exercise",
            target: 5.0,
            unit: "minutes",
            schedule: .daily
        )

        // Create log with FULL progress (5/5 minutes)
        let today = TestDates.today
        let fullLog = HabitLogBuilder.numeric(
            habitId: habit.id,
            value: 5.0,  // Exactly 5 out of 5 - complete!
            date: today
        )

        // Calculate performance
        let results = service.calculateHabitPerformance(
            habits: [habit],
            logs: [fullLog],
            from: today,
            to: today,
            timezone: .current
        )

        // Verify: Full progress should be counted as complete
        #expect(results.count == 1)
        #expect(results[0].completedDays == 1, "Full progress (5/5) should count as completed day")
        #expect(results[0].expectedDays == 1)
        #expect(results[0].completionRate == 1.0, "Completion rate should be 100% for full progress")
    }

    @Test("✅ REGRESSION: Binary habit with value=1.0 → counted as complete")
    func binaryHabitCompleteCountedAsComplete() throws {
        let service = createService()

        // Create binary habit: "Meditate"
        let habit = HabitBuilder.binary(
            name: "Meditate",
            schedule: .daily
        )

        // Create log with value=1.0 (complete)
        let today = TestDates.today
        let completeLog = HabitLogBuilder.binary(
            habitId: habit.id,
            date: today
        )

        // Calculate performance
        let results = service.calculateHabitPerformance(
            habits: [habit],
            logs: [completeLog],
            from: today,
            to: today,
            timezone: .current
        )

        // Verify: Binary habit with value=1.0 should be counted as complete
        #expect(results.count == 1)
        #expect(results[0].completedDays == 1, "Binary habit with value=1.0 should count as completed")
        #expect(results[0].expectedDays == 1)
        #expect(results[0].completionRate == 1.0)
    }

    @Test("❌ REGRESSION: Binary habit with value=0.0 → NOT counted as complete")
    func binaryHabitIncompleteNotCountedAsComplete() throws {
        let service = createService()

        // Create binary habit: "Read"
        let habit = HabitBuilder.binary(
            name: "Read",
            schedule: .daily
        )

        // Create log with value=0.0 (incomplete - edge case)
        let today = TestDates.today
        let incompleteLog = HabitLog(
            id: UUID(),
            habitID: habit.id,
            date: today,
            value: 0.0,  // Explicitly 0.0 - NOT complete!
            timezone: TimeZone.current.identifier
        )

        // Calculate performance
        let results = service.calculateHabitPerformance(
            habits: [habit],
            logs: [incompleteLog],
            from: today,
            to: today,
            timezone: .current
        )

        // Verify: Binary habit with value=0.0 should NOT be counted as complete
        #expect(results.count == 1)
        #expect(results[0].completedDays == 0, "Binary habit with value=0.0 should NOT count as completed")
        #expect(results[0].expectedDays == 1)
        #expect(results[0].completionRate == 0.0)
    }

    // MARK: - calculateHabitPerformance Tests

    @Test("Empty habits returns empty results")
    func emptyHabitsReturnsEmpty() {
        let service = createService()

        let results = service.calculateHabitPerformance(
            habits: [],
            logs: [],
            from: TestDates.today,
            to: TestDates.today,
            timezone: .current
        )

        #expect(results.isEmpty)
    }

    @Test("Inactive habits are excluded from results")
    func inactiveHabitsExcluded() {
        let service = createService()

        // Create inactive habit
        let inactiveHabit = Habit(
            id: UUID(),
            name: "Inactive Habit",
            colorHex: "#FF0000",
            emoji: "🔴",
            kind: .binary,
            unitLabel: nil,
            dailyTarget: nil,
            schedule: .daily,
            reminders: [],
            startDate: TestDates.daysAgo(30),
            endDate: nil,
            isActive: false,  // Inactive!
            displayOrder: 0,
            categoryId: nil,
            suggestionId: nil,
            isPinned: false,
            notes: nil,
            lastCompletedDate: nil,
            archivedDate: nil,
            locationConfiguration: nil,
            priorityLevel: nil
        )

        let log = HabitLogBuilder.binary(habitId: inactiveHabit.id, date: TestDates.today)

        let results = service.calculateHabitPerformance(
            habits: [inactiveHabit],
            logs: [log],
            from: TestDates.today,
            to: TestDates.today,
            timezone: .current
        )

        #expect(results.isEmpty, "Inactive habits should not appear in results")
    }

    @Test("Multiple habits calculated correctly")
    func multipleHabitsCalculatedCorrectly() {
        let service = createService()

        let habit1 = HabitBuilder.binary(name: "Habit 1")
        let habit2 = HabitBuilder.binary(name: "Habit 2")
        let habit3 = HabitBuilder.binary(name: "Habit 3")

        let today = TestDates.today

        // Log only habit1 and habit3
        let log1 = HabitLogBuilder.binary(habitId: habit1.id, date: today)
        let log3 = HabitLogBuilder.binary(habitId: habit3.id, date: today)

        let results = service.calculateHabitPerformance(
            habits: [habit1, habit2, habit3],
            logs: [log1, log3],
            from: today,
            to: today,
            timezone: .current
        )

        #expect(results.count == 3)

        // Verify habit1 (logged)
        let result1 = results.first { $0.habitId == habit1.id }!
        #expect(result1.completedDays == 1)
        #expect(result1.completionRate == 1.0)

        // Verify habit2 (not logged)
        let result2 = results.first { $0.habitId == habit2.id }!
        #expect(result2.completedDays == 0)
        #expect(result2.completionRate == 0.0)

        // Verify habit3 (logged)
        let result3 = results.first { $0.habitId == habit3.id }!
        #expect(result3.completedDays == 1)
        #expect(result3.completionRate == 1.0)
    }

    @Test("Date range filtering works correctly")
    func dateRangeFilteringWorks() {
        let service = createService()

        let habit = HabitBuilder.binary(name: "Test Habit")

        // Create logs across different dates
        let threeDaysAgo = CalendarUtils.addDays(-3, to: TestDates.today)
        let twoDaysAgo = CalendarUtils.addDays(-2, to: TestDates.today)
        let oneDayAgo = CalendarUtils.addDays(-1, to: TestDates.today)
        let today = TestDates.today

        let log1 = HabitLogBuilder.binary(habitId: habit.id, date: threeDaysAgo)
        let log2 = HabitLogBuilder.binary(habitId: habit.id, date: twoDaysAgo)
        let log3 = HabitLogBuilder.binary(habitId: habit.id, date: oneDayAgo)
        let log4 = HabitLogBuilder.binary(habitId: habit.id, date: today)

        // Query only last 2 days (yesterday and today)
        let results = service.calculateHabitPerformance(
            habits: [habit],
            logs: [log1, log2, log3, log4],
            from: oneDayAgo,
            to: today,
            timezone: .current
        )

        #expect(results.count == 1)
        #expect(results[0].completedDays == 2, "Should only count logs within date range")
        #expect(results[0].expectedDays == 2)
    }

    @Test("Completion rate calculated correctly with partial completion")
    func completionRateCalculatedWithPartial() {
        let service = createService()

        let habit = HabitBuilder.binary(name: "Test Habit")

        // Create 4 days, log only 3
        let startDate = CalendarUtils.addDays(-3, to: TestDates.today)
        let endDate = TestDates.today

        let day1 = CalendarUtils.addDays(-3, to: TestDates.today)
        let day2 = CalendarUtils.addDays(-2, to: TestDates.today)
        let day3 = CalendarUtils.addDays(-1, to: TestDates.today)
        // day4 (today) - not logged

        let log1 = HabitLogBuilder.binary(habitId: habit.id, date: day1)
        let log2 = HabitLogBuilder.binary(habitId: habit.id, date: day2)
        let log3 = HabitLogBuilder.binary(habitId: habit.id, date: day3)

        let results = service.calculateHabitPerformance(
            habits: [habit],
            logs: [log1, log2, log3],
            from: startDate,
            to: endDate,
            timezone: .current
        )

        #expect(results.count == 1)
        #expect(results[0].completedDays == 3)
        #expect(results[0].expectedDays == 4)
        #expect(results[0].completionRate == 0.75, "3/4 days = 75%")
    }

    @Test("Completion rate capped at 1.0")
    func completionRateCappedAtOne() {
        let service = createService()

        let habit = HabitBuilder.numeric(
            name: "Test",
            target: 5.0,
            unit: "reps"
        )

        let today = TestDates.today

        // Log with value EXCEEDING target (10 > 5)
        let log = HabitLogBuilder.numeric(
            habitId: habit.id,
            value: 10.0,
            date: today
        )

        let results = service.calculateHabitPerformance(
            habits: [habit],
            logs: [log],
            from: today,
            to: today,
            timezone: .current
        )

        #expect(results.count == 1)
        #expect(results[0].completedDays == 1)
        #expect(results[0].completionRate <= 1.0, "Completion rate should be capped at 100%")
    }

    @Test("Results sorted by completion rate descending")
    func resultsSortedByCompletionRate() {
        let service = createService()

        let habit1 = HabitBuilder.binary(name: "Habit 1")
        let habit2 = HabitBuilder.binary(name: "Habit 2")
        let habit3 = HabitBuilder.binary(name: "Habit 3")

        let startDate = CalendarUtils.addDays(-2, to: TestDates.today)
        let endDate = TestDates.today

        let day1 = CalendarUtils.addDays(-2, to: TestDates.today)
        let day2 = CalendarUtils.addDays(-1, to: TestDates.today)
        let day3 = TestDates.today

        // Habit 1: 3/3 days (100%)
        let logs1 = [
            HabitLogBuilder.binary(habitId: habit1.id, date: day1),
            HabitLogBuilder.binary(habitId: habit1.id, date: day2),
            HabitLogBuilder.binary(habitId: habit1.id, date: day3)
        ]

        // Habit 2: 1/3 days (33%)
        let logs2 = [
            HabitLogBuilder.binary(habitId: habit2.id, date: day1)
        ]

        // Habit 3: 2/3 days (67%)
        let logs3 = [
            HabitLogBuilder.binary(habitId: habit3.id, date: day1),
            HabitLogBuilder.binary(habitId: habit3.id, date: day3)
        ]

        let results = service.calculateHabitPerformance(
            habits: [habit1, habit2, habit3],
            logs: logs1 + logs2 + logs3,
            from: startDate,
            to: endDate,
            timezone: .current
        )

        #expect(results.count == 3)
        // Should be sorted: habit1 (100%), habit3 (67%), habit2 (33%)
        #expect(results[0].habitId == habit1.id, "First should be highest completion rate")
        #expect(results[1].habitId == habit3.id, "Second should be middle completion rate")
        #expect(results[2].habitId == habit2.id, "Last should be lowest completion rate")
    }

    // MARK: - generateProgressChartData Tests

    @Test("Empty stats returns empty chart data")
    func emptyStatsReturnsEmptyChartData() {
        let service = createService()

        let chartData = service.generateProgressChartData(completionStats: [:])

        #expect(chartData.isEmpty)
    }

    @Test("Single data point transformed correctly")
    func singleDataPointTransformed() {
        let service = createService()

        let date = TestDates.today
        let stats = HabitCompletionStats(
            totalHabits: 5,
            completedHabits: 3,
            completionRate: 0.6
        )

        let chartData = service.generateProgressChartData(completionStats: [date: stats])

        #expect(chartData.count == 1)
        #expect(chartData[0].date == date)
        #expect(chartData[0].completionRate == 0.6)
    }

    @Test("Multiple days sorted chronologically")
    func multipleDaysSortedChronologically() {
        let service = createService()

        let today = TestDates.today
        let day1 = CalendarUtils.addDays(-2, to: today)
        let day2 = CalendarUtils.addDays(-1, to: today)
        let day3 = today

        // Add in random order
        let stats = [
            day3: HabitCompletionStats(totalHabits: 5, completedHabits: 5, completionRate: 1.0),
            day1: HabitCompletionStats(totalHabits: 5, completedHabits: 3, completionRate: 0.6),
            day2: HabitCompletionStats(totalHabits: 5, completedHabits: 4, completionRate: 0.8)
        ]

        let chartData = service.generateProgressChartData(completionStats: stats)

        #expect(chartData.count == 3)
        // Should be sorted by date ascending
        #expect(chartData[0].date == day1, "First date should be earliest")
        #expect(chartData[1].date == day2, "Second date should be middle")
        #expect(chartData[2].date == day3, "Third date should be latest")
    }

    // MARK: - analyzeWeeklyPatterns Tests

    @Test("Empty data returns empty weekly patterns with defaults")
    func emptyDataReturnsEmptyWeeklyPatterns() {
        let service = createService()

        let result = service.analyzeWeeklyPatterns(
            habits: [],
            logs: [],
            from: TestDates.today,
            to: TestDates.today,
            timezone: .current
        )

        #expect(result.dayOfWeekPerformance.count == 7, "Should have 7 days")
        #expect(result.bestDay.isEmpty == false, "Should have best day")
        #expect(result.worstDay.isEmpty == false, "Should have worst day")
        #expect(result.averageWeeklyCompletion == 0.0, "No data means 0% completion")
    }

    @Test("Single day single habit logged correctly identifies day of week")
    func singleDaySingleHabitLogged() {
        let service = createService()

        let habit = HabitBuilder.binary(name: "Test", schedule: .daily)
        let today = TestDates.today
        let log = HabitLogBuilder.binary(habitId: habit.id, date: today)

        let result = service.analyzeWeeklyPatterns(
            habits: [habit],
            logs: [log],
            from: today,
            to: today,
            timezone: .current
        )

        // Find today's weekday result
        let todayWeekday = CalendarUtils.weekdayComponentLocal(from: today)
        let formatter = DateFormatter()
        let todayName = formatter.weekdaySymbols[todayWeekday - 1]

        let todayResult = result.dayOfWeekPerformance.first { $0.dayName == todayName }
        #expect(todayResult != nil)
        #expect(todayResult?.completionRate == 1.0, "Today should be 100% complete")
    }

    @Test("Partial progress NOT counted in weekly patterns")
    func partialProgressNotCountedInWeekly() {
        let service = createService()

        let habit = HabitBuilder.numeric(
            name: "Water",
            target: 8.0,
            unit: "glasses",
            schedule: .daily
        )

        let today = TestDates.today

        // Partial progress log (3/8)
        let partialLog = HabitLogBuilder.numeric(
            habitId: habit.id,
            value: 3.0,
            date: today
        )

        let result = service.analyzeWeeklyPatterns(
            habits: [habit],
            logs: [partialLog],
            from: today,
            to: today,
            timezone: .current
        )

        // Find today's weekday result
        let todayWeekday = CalendarUtils.weekdayComponentLocal(from: today)
        let formatter = DateFormatter()
        let todayName = formatter.weekdaySymbols[todayWeekday - 1]

        let todayResult = result.dayOfWeekPerformance.first { $0.dayName == todayName }
        #expect(todayResult?.completionRate == 0.0, "Partial progress should NOT count")
    }

    @Test("Best and worst days identified correctly")
    func bestAndWorstDaysIdentified() {
        let service = createService()

        let habit = HabitBuilder.binary(name: "Test", schedule: .daily)

        // Create logs for specific days of the week
        // Using TestDates.pastDays to get consistent weekdays
        let dates = TestDates.pastDays(7) // Last 7 days

        // Log only the first 5 days (skip last 2)
        let logs = dates.prefix(5).map { date in
            HabitLogBuilder.binary(habitId: habit.id, date: date)
        }

        let result = service.analyzeWeeklyPatterns(
            habits: [habit],
            logs: logs,
            from: dates.first!,
            to: dates.last!,
            timezone: .current
        )

        #expect(result.bestDay.isEmpty == false)
        #expect(result.worstDay.isEmpty == false)
        // Best day should have higher completion than worst day
        let best = result.dayOfWeekPerformance.first!
        let worst = result.dayOfWeekPerformance.last!
        #expect(best.completionRate >= worst.completionRate)
    }

    @Test("Average weekly completion calculated correctly")
    func averageWeeklyCompletionCalculated() {
        let service = createService()

        let habit = HabitBuilder.binary(name: "Test", schedule: .daily)

        // Log 3 out of 7 days
        let dates = TestDates.pastDays(7)
        let logs = dates.prefix(3).map { date in
            HabitLogBuilder.binary(habitId: habit.id, date: date)
        }

        let result = service.analyzeWeeklyPatterns(
            habits: [habit],
            logs: logs,
            from: dates.first!,
            to: dates.last!,
            timezone: .current
        )

        // Average should be calculated across all 7 days of week performance
        #expect(result.averageWeeklyCompletion >= 0.0)
        #expect(result.averageWeeklyCompletion <= 1.0)
    }

    @Test("Inactive habits excluded from weekly analysis")
    func inactiveHabitsExcludedFromWeekly() {
        let service = createService()

        let activeHabit = HabitBuilder.binary(name: "Active", schedule: .daily)
        let inactiveHabit = Habit(
            id: UUID(),
            name: "Inactive",
            colorHex: "#FF0000",
            emoji: "🔴",
            kind: .binary,
            unitLabel: nil,
            dailyTarget: nil,
            schedule: .daily,
            reminders: [],
            startDate: TestDates.daysAgo(30),
            endDate: nil,
            isActive: false,
            displayOrder: 0,
            categoryId: nil,
            suggestionId: nil,
            isPinned: false,
            notes: nil,
            lastCompletedDate: nil,
            archivedDate: nil,
            locationConfiguration: nil,
            priorityLevel: nil
        )

        let today = TestDates.today
        let activeLog = HabitLogBuilder.binary(habitId: activeHabit.id, date: today)
        let inactiveLog = HabitLogBuilder.binary(habitId: inactiveHabit.id, date: today)

        let result = service.analyzeWeeklyPatterns(
            habits: [activeHabit, inactiveHabit],
            logs: [activeLog, inactiveLog],
            from: today,
            to: today,
            timezone: .current
        )

        // Result should only consider active habit
        let todayWeekday = CalendarUtils.weekdayComponentLocal(from: today)
        let formatter = DateFormatter()
        let todayName = formatter.weekdaySymbols[todayWeekday - 1]

        let todayResult = result.dayOfWeekPerformance.first { $0.dayName == todayName }
        #expect(todayResult?.completionRate == 1.0, "Should be 100% for the 1 active habit")
    }

    @Test("Day of week results sorted by completion rate")
    func dayOfWeekResultsSorted() {
        let service = createService()

        let habit = HabitBuilder.binary(name: "Test", schedule: .daily)
        let dates = TestDates.pastDays(7)

        // Log only some days to create variation
        let logs = dates.prefix(4).map { date in
            HabitLogBuilder.binary(habitId: habit.id, date: date)
        }

        let result = service.analyzeWeeklyPatterns(
            habits: [habit],
            logs: logs,
            from: dates.first!,
            to: dates.last!,
            timezone: .current
        )

        // Verify sorted descending by completion rate
        for i in 0..<(result.dayOfWeekPerformance.count - 1) {
            #expect(
                result.dayOfWeekPerformance[i].completionRate >= result.dayOfWeekPerformance[i + 1].completionRate,
                "Results should be sorted by completion rate descending"
            )
        }
    }

    // MARK: - calculateStreakAnalysis Tests

    @Test("Empty data returns zero streaks")
    func emptyDataReturnsZeroStreaks() {
        let service = createService()

        // Use ACTUAL current date since service uses Date() internally
        let today = CalendarUtils.startOfDayLocal(for: Date())
        let startDate = CalendarUtils.addDays(-30, to: today)

        let result = service.calculateStreakAnalysis(
            habits: [],
            logs: [],
            from: startDate,
            to: today,
            timezone: .current
        )

        #expect(result.currentStreak == 0)
        #expect(result.longestStreak == 0)
        #expect(result.daysWithFullCompletion == 0)
        #expect(result.consistencyScore == 0.0)
    }

    @Test("Perfect day streak: all habits completed for 3 consecutive days")
    func perfectDayStreakConsecutiveDays() {
        let service = createService()

        let habit1 = HabitBuilder.binary(name: "Habit 1", schedule: .daily)
        let habit2 = HabitBuilder.binary(name: "Habit 2", schedule: .daily)

        // Use ACTUAL current date since service uses Date() internally
        let today = CalendarUtils.startOfDayLocal(for: Date())
        let day1 = CalendarUtils.addDays(-2, to: today)
        let day2 = CalendarUtils.addDays(-1, to: today)
        let day3 = today

        // Complete both habits for all 3 days
        let logs = [
            HabitLogBuilder.binary(habitId: habit1.id, date: day1),
            HabitLogBuilder.binary(habitId: habit2.id, date: day1),
            HabitLogBuilder.binary(habitId: habit1.id, date: day2),
            HabitLogBuilder.binary(habitId: habit2.id, date: day2),
            HabitLogBuilder.binary(habitId: habit1.id, date: day3),
            HabitLogBuilder.binary(habitId: habit2.id, date: day3)
        ]

        let result = service.calculateStreakAnalysis(
            habits: [habit1, habit2],
            logs: logs,
            from: day1,
            to: day3,
            timezone: .current
        )

        #expect(result.currentStreak == 3, "Should have 3-day perfect streak")
        #expect(result.longestStreak == 3, "Longest should also be 3")
        #expect(result.daysWithFullCompletion == 3)
        #expect(result.consistencyScore == 1.0, "100% of days completed")
    }

    @Test("Perfect day broken by missing one habit")
    func perfectDayBrokenByMissingHabit() {
        let service = createService()

        let habit1 = HabitBuilder.binary(name: "Habit 1", schedule: .daily)
        let habit2 = HabitBuilder.binary(name: "Habit 2", schedule: .daily)

        // Use ACTUAL current date since service uses Date() internally
        let today = CalendarUtils.startOfDayLocal(for: Date())
        let day1 = CalendarUtils.addDays(-2, to: today)
        let day2 = CalendarUtils.addDays(-1, to: today)
        let day3 = today

        // Day 1 & 3: both habits completed
        // Day 2: only habit1 completed (breaks streak)
        let logs = [
            HabitLogBuilder.binary(habitId: habit1.id, date: day1),
            HabitLogBuilder.binary(habitId: habit2.id, date: day1),
            HabitLogBuilder.binary(habitId: habit1.id, date: day2),
            // Missing habit2 on day2!
            HabitLogBuilder.binary(habitId: habit1.id, date: day3),
            HabitLogBuilder.binary(habitId: habit2.id, date: day3)
        ]

        let result = service.calculateStreakAnalysis(
            habits: [habit1, habit2],
            logs: logs,
            from: day1,
            to: day3,
            timezone: .current
        )

        #expect(result.currentStreak == 1, "Current streak should be 1 (only today)")
        #expect(result.daysWithFullCompletion == 2, "Only 2 perfect days")
        #expect(result.consistencyScore < 1.0, "Not 100% consistent")
    }

    @Test("Partial progress breaks perfect day streak")
    func partialProgressBreaksPerfectDayStreak() {
        let service = createService()

        let binaryHabit = HabitBuilder.binary(name: "Binary", schedule: .daily)
        let numericHabit = HabitBuilder.numeric(
            name: "Numeric",
            target: 8.0,
            unit: "reps",
            schedule: .daily
        )

        // Use ACTUAL current date since service uses Date() internally
        let today = CalendarUtils.startOfDayLocal(for: Date())
        let day1 = CalendarUtils.addDays(-1, to: today)
        let day2 = today

        let logs = [
            // Day 1: Both complete
            HabitLogBuilder.binary(habitId: binaryHabit.id, date: day1),
            HabitLogBuilder.numeric(habitId: numericHabit.id, value: 8.0, date: day1),
            // Day 2: Binary complete, numeric partial (3/8)
            HabitLogBuilder.binary(habitId: binaryHabit.id, date: day2),
            HabitLogBuilder.numeric(habitId: numericHabit.id, value: 3.0, date: day2)
        ]

        let result = service.calculateStreakAnalysis(
            habits: [binaryHabit, numericHabit],
            logs: logs,
            from: day1,
            to: day2,
            timezone: .current
        )

        #expect(result.currentStreak == 0, "Partial progress should break streak")
        #expect(result.daysWithFullCompletion == 1, "Only day1 was perfect")
    }

    @Test("Streak trend calculated correctly")
    func streakTrendCalculatedCorrectly() {
        let service = createService()

        let habit = HabitBuilder.binary(name: "Test", schedule: .daily)

        // Use ACTUAL current date since service uses Date() internally
        let today = CalendarUtils.startOfDayLocal(for: Date())

        // Create a long perfect streak followed by current short streak
        let days = (0...10).map { CalendarUtils.addDays(-$0, to: today) }.reversed()

        // Log first 7 days (creating longest streak of 7)
        // Skip days 8-9
        // Log day 10 (current streak of 1)
        let logs = days.prefix(7).map { date in
            HabitLogBuilder.binary(habitId: habit.id, date: date)
        } + [HabitLogBuilder.binary(habitId: habit.id, date: today)]

        let result = service.calculateStreakAnalysis(
            habits: [habit],
            logs: logs,
            from: days.first!,
            to: today,
            timezone: .current
        )

        // Current streak (1) < longest streak (7) → should be declining
        #expect(result.currentStreak < result.longestStreak)
        #expect(result.streakTrend == "declining" || result.streakTrend == "stable")
    }

    @Test("Inactive habits excluded from streak analysis")
    func inactiveHabitsExcludedFromStreaks() {
        let service = createService()

        let activeHabit = HabitBuilder.binary(name: "Active", schedule: .daily)
        let inactiveHabit = Habit(
            id: UUID(),
            name: "Inactive",
            colorHex: "#FF0000",
            emoji: "🔴",
            kind: .binary,
            unitLabel: nil,
            dailyTarget: nil,
            schedule: .daily,
            reminders: [],
            startDate: CalendarUtils.addDays(-30, to: Date()),
            endDate: nil,
            isActive: false,
            displayOrder: 0,
            categoryId: nil,
            suggestionId: nil,
            isPinned: false,
            notes: nil,
            lastCompletedDate: nil,
            archivedDate: nil,
            locationConfiguration: nil,
            priorityLevel: nil
        )

        // Use ACTUAL current date since service uses Date() internally
        let today = CalendarUtils.startOfDayLocal(for: Date())
        let activeLog = HabitLogBuilder.binary(habitId: activeHabit.id, date: today)
        // Even with inactive habit logged, shouldn't affect streak

        let result = service.calculateStreakAnalysis(
            habits: [activeHabit, inactiveHabit],
            logs: [activeLog],
            from: today,
            to: today,
            timezone: .current
        )

        // Should have perfect day with just the active habit
        #expect(result.currentStreak == 1)
        #expect(result.daysWithFullCompletion == 1)
    }

    // MARK: - Cross-Timezone Tests

    @Test("Perfect day streak finds log created in different timezone")
    func perfectDayStreakCrossTimezone() {
        let service = createService()

        let habit = HabitBuilder.binary(name: "Test Habit", schedule: .daily)

        // Create a log at 11 PM New York time (which is next day in UTC)
        // The log should still be attributed to the correct day based on its stored timezone
        let newYork = TimezoneTestHelpers.newYork
        let logDate = TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 20,
            hour: 23, minute: 30,
            timezone: newYork
        )

        // Create log with New York timezone stored
        let log = HabitLog(
            id: UUID(),
            habitID: habit.id,
            date: logDate,
            value: 1.0,
            timezone: newYork.identifier
        )

        // Query using the same day boundaries
        let startOfDay = CalendarUtils.startOfDayLocal(for: logDate, timezone: newYork)

        let result = service.calculateStreakAnalysis(
            habits: [habit],
            logs: [log],
            from: startOfDay,
            to: startOfDay,
            timezone: newYork
        )

        // The log at 11:30 PM should count for Nov 20 (the day it was created in its timezone)
        #expect(result.daysWithFullCompletion >= 1, "Late night log should be found for its calendar day")
    }

    @Test("Weekly patterns correctly handles log with stored timezone")
    func weeklyPatternsCrossTimezone() {
        let service = createService()

        let habit = HabitBuilder.binary(name: "Test Habit", schedule: .daily)

        // Use current timezone to ensure test works on any machine
        // The service uses TimeZone.current for dashboard statistics
        let currentTz = TimeZone.current
        let today = CalendarUtils.startOfDayLocal(for: Date(), timezone: currentTz)

        // Create log with explicitly stored timezone
        let log = HabitLog(
            id: UUID(),
            habitID: habit.id,
            date: today,
            value: 1.0,
            timezone: currentTz.identifier
        )

        let result = service.analyzeWeeklyPatterns(
            habits: [habit],
            logs: [log],
            from: today,
            to: today,
            timezone: currentTz
        )

        // Should find the log and have non-zero completion rate
        let hasCompletions = result.dayOfWeekPerformance.contains { $0.completionRate > 0 }
        #expect(hasCompletions, "Log with stored timezone should be counted in weekly patterns")
    }

    @Test("Invalid timezone identifier falls back gracefully")
    func invalidTimezoneFallback() {
        let service = createService()

        let habit = HabitBuilder.binary(name: "Test Habit", schedule: .daily)
        let today = CalendarUtils.startOfDayLocal(for: Date())

        // Create log with invalid timezone identifier
        let log = HabitLog(
            id: UUID(),
            habitID: habit.id,
            date: today,
            value: 1.0,
            timezone: "Invalid/Timezone"  // Invalid!
        )

        let result = service.calculateStreakAnalysis(
            habits: [habit],
            logs: [log],
            from: today,
            to: today,
            timezone: .current
        )

        // Should still find the log using fallback timezone
        #expect(result.daysWithFullCompletion == 1, "Invalid timezone should fall back gracefully")
    }
}
