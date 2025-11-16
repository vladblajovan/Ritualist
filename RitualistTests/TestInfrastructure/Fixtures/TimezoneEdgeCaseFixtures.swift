import Foundation
@testable import RitualistCore

/// Pre-built test scenarios for timezone edge cases
///
/// **Purpose:** Provide ready-to-use test scenarios that combine realistic data with edge case conditions
///
/// **Why This Exists:**
/// - Timezone bugs are hard to catch manually
/// - Edge cases (late-night logging, DST, timezone transitions) need thorough testing
/// - Reusable scenarios ensure consistency across tests
///
/// **Usage:**
/// ```swift
/// @Test("Late-night logging counts for correct day")
/// func testLateNightLogging() async throws {
///     let scenario = TimezoneEdgeCaseFixtures.lateNightLoggingScenario()
///     let container = try TestModelContainer.withHabitAndLogs(scenario.habit, logs: scenario.logs)
///
///     // Run assertions on scenario...
///     #expect(scenario.logs.count == 3)
/// }
/// ```
public enum TimezoneEdgeCaseFixtures {

    // MARK: - Test Scenario Type

    /// Container for a complete test scenario
    public struct TestScenario {
        /// The habit being tested
        public let habit: Habit

        /// Logs associated with the habit
        public let logs: [HabitLog]

        /// Description of what this scenario tests
        public let description: String

        /// Additional metadata for assertions
        public let metadata: [String: Any]

        public init(
            habit: Habit,
            logs: [HabitLog],
            description: String,
            metadata: [String: Any] = [:]
        ) {
            self.habit = habit
            self.logs = logs
            self.description = description
            self.metadata = metadata
        }
    }

    // MARK: - Scenario 1: Late-Night Logging

    /// User logs habit at 11:30 PM local time (should count for same day, not next day)
    ///
    /// **Test Case:**
    /// - User in Tokyo logs habit at 11:30 PM on Friday, November 8, 2025
    /// - Expected: Log counts for Friday (not Saturday)
    ///
    /// **Why This Matters:**
    /// If we use UTC instead of local time, the log might incorrectly count for the next day
    ///
    /// - Parameter timezone: Timezone for the late-night logging (default: Tokyo)
    /// - Returns: Test scenario with habit and 3 late-night logs
    public static func lateNightLoggingScenario(timezone: TimeZone = TimezoneTestHelpers.tokyo) -> TestScenario {
        let habit = HabitBuilder.binary(
            name: "Late Night Meditation",
            emoji: "🧘",
            schedule: .daily
        )

        let logs = HabitLogBuilder.lateNightLogs(
            habitId: habit.id,
            timezone: timezone,
            count: 3
        )

        return TestScenario(
            habit: habit,
            logs: logs,
            description: "User logs habit at 11:30 PM local time - should count for same day",
            metadata: [
                "timezone": timezone.identifier,
                "timeOfDay": "23:30",
                "expectedDates": [
                    "2025-11-08",  // Friday
                    "2025-11-09",  // Saturday
                    "2025-11-10"   // Sunday
                ]
            ]
        )
    }

    // MARK: - Scenario 2: Timezone Transition (Travel)

    /// User travels across timezones mid-week (Tokyo → New York)
    ///
    /// **Test Case:**
    /// - User logs habit in Tokyo on Nov 8 at 10:00 AM
    /// - User travels to New York
    /// - User logs habit in NYC on Nov 9 at 10:00 AM
    ///
    /// **Why This Matters:**
    /// Both logs should count for their respective days in their respective timezones
    ///
    /// - Returns: Test scenario with habit and logs in different timezones
    public static func timezoneTransitionScenario() -> TestScenario {
        let habit = HabitBuilder.binary(
            name: "Daily Journal",
            emoji: "📔",
            schedule: .daily
        )

        let (tokyoDate, newYorkDate) = TimezoneTestHelpers.timezoneTransitionDates()

        let logs = [
            HabitLog(
                id: UUID(),
                habitID: habit.id,
                date: tokyoDate,
                value: 1.0,
                timezone: TimezoneTestHelpers.tokyo.identifier
            ),
            HabitLog(
                id: UUID(),
                habitID: habit.id,
                date: newYorkDate,
                value: 1.0,
                timezone: TimezoneTestHelpers.newYork.identifier
            )
        ]

        return TestScenario(
            habit: habit,
            logs: logs,
            description: "User travels from Tokyo to New York - logs should count for correct days in each timezone",
            metadata: [
                "fromTimezone": TimezoneTestHelpers.tokyo.identifier,
                "toTimezone": TimezoneTestHelpers.newYork.identifier,
                "travelDate": "2025-11-08 to 2025-11-09"
            ]
        )
    }

    // MARK: - Scenario 3: Weekly Schedule (Mon/Wed/Fri)

    /// Mon/Wed/Fri habit with logs in specific timezone
    ///
    /// **Test Case:**
    /// - Habit scheduled for Mon/Wed/Fri
    /// - User logs on all 3 scheduled days in Tokyo timezone
    ///
    /// **Why This Matters:**
    /// Weekly schedules must respect timezone boundaries (e.g., Monday in Tokyo vs Monday in UTC)
    ///
    /// - Parameter timezone: Timezone for the weekly schedule (default: Tokyo)
    /// - Returns: Test scenario with Mon/Wed/Fri habit and matching logs
    public static func weeklyScheduleScenario(timezone: TimeZone = TimezoneTestHelpers.tokyo) -> TestScenario {
        let habit = HabitBuilder.binary(
            name: "Gym Workout",
            emoji: "💪",
            schedule: .daysOfWeek([1, 3, 5])  // Mon/Wed/Fri
        )

        let completedDays = TimezoneTestHelpers.monWedFriDates(timezone: timezone)

        let logs = completedDays.map { date in
            HabitLog(
                id: UUID(),
                habitID: habit.id,
                date: date,
                value: 1.0,
                timezone: timezone.identifier
            )
        }

        return TestScenario(
            habit: habit,
            logs: logs,
            description: "Mon/Wed/Fri habit logged on all scheduled days in specific timezone",
            metadata: [
                "timezone": timezone.identifier,
                "scheduledDays": ["Monday", "Wednesday", "Friday"],
                "completedCount": logs.count
            ]
        )
    }

    // MARK: - Scenario 4: Week Boundary

    /// Week boundary scenario (Sunday 11:59 PM → Monday 12:00 AM)
    ///
    /// **Test Case:**
    /// - User logs habit on Sunday at 11:59 PM
    /// - Expected: Log counts for that week (not next week)
    ///
    /// **Why This Matters:**
    /// Week calculations must use local timezone, not UTC, to determine week boundaries
    ///
    /// - Parameter timezone: Timezone for the week boundary test (default: New York)
    /// - Returns: Test scenario with logs near week boundary
    public static func weekBoundaryScenario(timezone: TimeZone = TimezoneTestHelpers.newYork) -> TestScenario {
        // Create logs for the full week leading up to the boundary
        let fullWeek = TimezoneTestHelpers.fullWeekDates(timezone: timezone)

        // Add a late Sunday night log (11:59 PM)
        let sundayNight = TimezoneTestHelpers.createWeekBoundaryDate(timezone: timezone)

        // Start habit on the first day of the week to avoid gap
        let habit = HabitBuilder.binary(
            name: "Weekly Review",
            emoji: "📊",
            schedule: .daily,
            startDate: fullWeek.first ?? sundayNight
        )

        var logs = fullWeek.map { date in
            HabitLog(
                id: UUID(),
                habitID: habit.id,
                date: date,
                value: 1.0,
                timezone: timezone.identifier
            )
        }

        // Add the critical Sunday 11:59 PM log
        logs.append(HabitLog(
            id: UUID(),
            habitID: habit.id,
            date: sundayNight,
            value: 1.0,
            timezone: timezone.identifier
        ))

        return TestScenario(
            habit: habit,
            logs: logs,
            description: "Week boundary test - Sunday 11:59 PM should count for current week",
            metadata: [
                "timezone": timezone.identifier,
                "boundaryTime": "Sunday 23:59:59",
                "weekCount": 1
            ]
        )
    }

    // MARK: - Scenario 5: DST Transitions

    /// DST transition scenarios (Spring Forward & Fall Back)
    ///
    /// **Test Case:**
    /// - Spring Forward: March 9, 2025 at 2:00 AM (clock jumps to 3:00 AM)
    /// - Fall Back: November 2, 2025 at 2:00 AM (clock jumps back to 1:00 AM)
    ///
    /// **Why This Matters:**
    /// Habits logged during DST transitions should still count correctly
    ///
    /// - Returns: Test scenario with logs during DST transitions
    public static func dstTransitionScenario() -> TestScenario {
        let habit = HabitBuilder.binary(
            name: "Morning Coffee",
            emoji: "☕",
            schedule: .daily
        )

        let springForward = TimezoneTestHelpers.dstSpringForwardDate()
        let fallBack = TimezoneTestHelpers.dstFallBackDate()

        let logs = [
            HabitLog(
                id: UUID(),
                habitID: habit.id,
                date: springForward,
                value: 1.0,
                timezone: TimezoneTestHelpers.newYork.identifier
            ),
            HabitLog(
                id: UUID(),
                habitID: habit.id,
                date: fallBack,
                value: 1.0,
                timezone: TimezoneTestHelpers.newYork.identifier
            )
        ]

        return TestScenario(
            habit: habit,
            logs: logs,
            description: "DST transition test - logs during spring forward and fall back",
            metadata: [
                "timezone": TimezoneTestHelpers.newYork.identifier,
                "springForwardDate": "2025-03-09 01:30 EST",
                "fallBackDate": "2025-11-02 01:30 EST",
                "dstTransitions": 2
            ]
        )
    }

    // MARK: - Scenario 6: Numeric Habit with Timezone

    /// Numeric habit with daily progress across different timezones
    ///
    /// **Test Case:**
    /// - User has "Drink Water" habit with target of 8 glasses
    /// - User logs partial progress throughout the day
    /// - User travels to different timezone mid-week
    ///
    /// **Why This Matters:**
    /// Numeric habits must aggregate daily values correctly regardless of timezone
    ///
    /// - Returns: Test scenario with numeric habit and progressive logs
    public static func numericHabitTimezoneScenario() -> TestScenario {
        let habit = HabitBuilder.numeric(
            name: "Drink Water",
            emoji: "💧",
            target: 8.0,
            unit: "glasses",
            schedule: .daily
        )

        // Day 1: 6 glasses in Tokyo
        let day1 = TimezoneTestHelpers.createDate(
            year: 2025,
            month: 11,
            day: 8,
            hour: 14,
            minute: 0,
            timezone: TimezoneTestHelpers.tokyo
        )

        // Day 2: 8 glasses in New York (after travel)
        let day2 = TimezoneTestHelpers.createDate(
            year: 2025,
            month: 11,
            day: 9,
            hour: 14,
            minute: 0,
            timezone: TimezoneTestHelpers.newYork
        )

        // Day 3: 10 glasses in New York (overachieved!)
        let day3 = TimezoneTestHelpers.createDate(
            year: 2025,
            month: 11,
            day: 10,
            hour: 14,
            minute: 0,
            timezone: TimezoneTestHelpers.newYork
        )

        let logs = [
            HabitLog(
                id: UUID(),
                habitID: habit.id,
                date: day1,
                value: 6.0,
                timezone: TimezoneTestHelpers.tokyo.identifier
            ),
            HabitLog(
                id: UUID(),
                habitID: habit.id,
                date: day2,
                value: 8.0,
                timezone: TimezoneTestHelpers.newYork.identifier
            ),
            HabitLog(
                id: UUID(),
                habitID: habit.id,
                date: day3,
                value: 10.0,
                timezone: TimezoneTestHelpers.newYork.identifier
            )
        ]

        return TestScenario(
            habit: habit,
            logs: logs,
            description: "Numeric habit with timezone transition - daily values should aggregate correctly",
            metadata: [
                "habitType": "numeric",
                "dailyTarget": 8.0,
                "unit": "glasses",
                "day1Progress": 6.0,
                "day2Progress": 8.0,
                "day3Progress": 10.0,
                "completedDays": 2  // Day 2 and 3 met target
            ]
        )
    }

    // MARK: - Scenario 7: Multi-Timezone Full Week

    /// Full week of logging across multiple timezones
    ///
    /// **Test Case:**
    /// - User travels internationally throughout the week
    /// - Logs habit in 4 different timezones (UTC, Tokyo, New York, Sydney)
    ///
    /// **Why This Matters:**
    /// Ensures streak calculations work correctly when user moves between timezones
    ///
    /// - Returns: Test scenario with logs in multiple timezones
    public static func multiTimezoneWeekScenario() -> TestScenario {
        let habit = HabitBuilder.binary(
            name: "Read for 30 min",
            emoji: "📚",
            schedule: .daily
        )

        let logs = [
            // Day 1: UTC
            HabitLog(
                id: UUID(),
                habitID: habit.id,
                date: TimezoneTestHelpers.createDate(
                    year: 2025, month: 11, day: 3,
                    hour: 10, minute: 0,
                    timezone: TimezoneTestHelpers.utc
                ),
                value: 1.0,
                timezone: TimezoneTestHelpers.utc.identifier
            ),
            // Day 2: Tokyo
            HabitLog(
                id: UUID(),
                habitID: habit.id,
                date: TimezoneTestHelpers.createDate(
                    year: 2025, month: 11, day: 4,
                    hour: 10, minute: 0,
                    timezone: TimezoneTestHelpers.tokyo
                ),
                value: 1.0,
                timezone: TimezoneTestHelpers.tokyo.identifier
            ),
            // Day 3: New York
            HabitLog(
                id: UUID(),
                habitID: habit.id,
                date: TimezoneTestHelpers.createDate(
                    year: 2025, month: 11, day: 5,
                    hour: 10, minute: 0,
                    timezone: TimezoneTestHelpers.newYork
                ),
                value: 1.0,
                timezone: TimezoneTestHelpers.newYork.identifier
            ),
            // Day 4: Sydney
            HabitLog(
                id: UUID(),
                habitID: habit.id,
                date: TimezoneTestHelpers.createDate(
                    year: 2025, month: 11, day: 6,
                    hour: 10, minute: 0,
                    timezone: TimezoneTestHelpers.sydney
                ),
                value: 1.0,
                timezone: TimezoneTestHelpers.sydney.identifier
            )
        ]

        return TestScenario(
            habit: habit,
            logs: logs,
            description: "User travels across 4 timezones in one week - streak should remain unbroken",
            metadata: [
                "timezones": ["UTC", "Asia/Tokyo", "America/New_York", "Australia/Sydney"],
                "consecutiveDays": 4,
                "expectedStreak": 4
            ]
        )
    }

    // MARK: - Scenario 8: Midnight Boundary Edge Case

    /// Logging at exact midnight boundary (11:59:59 PM → 12:00:00 AM)
    ///
    /// **Test Case:**
    /// - User logs habit at 11:59:59 PM on Friday
    /// - User logs habit at 12:00:00 AM on Saturday
    ///
    /// **Why This Matters:**
    /// These should count as two separate days, not the same day
    ///
    /// - Parameter timezone: Timezone for the boundary test (default: New York)
    /// - Returns: Test scenario with logs at exact midnight boundary
    public static func midnightBoundaryScenario(timezone: TimeZone = TimezoneTestHelpers.newYork) -> TestScenario {
        // 11:59:59 PM Friday
        let beforeMidnight = TimezoneTestHelpers.createMidnightBoundaryDate(timezone: timezone)

        // 12:01 AM Saturday (just after midnight)
        let afterMidnight = TimezoneTestHelpers.createEarlyMorningDate(timezone: timezone)

        // Start habit on Friday (day of first log) to avoid gap
        let habit = HabitBuilder.binary(
            name: "Gratitude Log",
            emoji: "🙏",
            schedule: .daily,
            startDate: beforeMidnight
        )

        let logs = [
            HabitLog(
                id: UUID(),
                habitID: habit.id,
                date: beforeMidnight,
                value: 1.0,
                timezone: timezone.identifier
            ),
            HabitLog(
                id: UUID(),
                habitID: habit.id,
                date: afterMidnight,
                value: 1.0,
                timezone: timezone.identifier
            )
        ]

        return TestScenario(
            habit: habit,
            logs: logs,
            description: "Midnight boundary test - 11:59:59 PM and 12:01 AM should count as different days",
            metadata: [
                "timezone": timezone.identifier,
                "beforeMidnight": "2025-11-08 23:59:59",
                "afterMidnight": "2025-11-09 00:01:00",
                "expectedDayCount": 2
            ]
        )
    }
}
