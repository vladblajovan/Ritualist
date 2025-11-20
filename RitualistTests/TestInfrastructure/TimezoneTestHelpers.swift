import Foundation
@testable import RitualistCore

/// Timezone-specific test helpers for edge case scenarios
///
/// **Purpose:** Test habit tracking across different timezones to ensure:
/// - Late-night logging (11:30 PM) uses LOCAL timezone, not UTC
/// - Week boundaries respect user's timezone
/// - DST transitions don't cause bugs
/// - Timezone transitions (travel) work correctly
///
/// **Usage:**
/// ```swift
/// let lateNightDate = TimezoneTestHelpers.createLateNightDate(timezone: .tokyo)
/// let habit = HabitBuilder.binary()
/// let log = HabitLogBuilder.binary(habitId: habit.id, date: lateNightDate)
/// ```
public enum TimezoneTestHelpers {

    // MARK: - Test Timezones

    /// Standard test timezones representing different UTC offsets
    /// - UTC: Baseline (GMT+0)
    /// - New York: Eastern Time (GMT-5)
    /// - Tokyo: Japan Standard Time (GMT+9)
    /// - Sydney: Australian Eastern Time (GMT+11)
    public static let testTimezones: [TimeZone] = [
        TimeZone(identifier: "UTC")!,
        TimeZone(identifier: "America/New_York")!,
        TimeZone(identifier: "Asia/Tokyo")!,
        TimeZone(identifier: "Australia/Sydney")!
    ]

    /// Convenient access to specific timezones
    public static let utc = TimeZone(identifier: "UTC")!
    public static let newYork = TimeZone(identifier: "America/New_York")!
    public static let tokyo = TimeZone(identifier: "Asia/Tokyo")!
    public static let sydney = TimeZone(identifier: "Australia/Sydney")!
    public static let london = TimeZone(identifier: "Europe/London")!
    public static let losAngeles = TimeZone(identifier: "America/Los_Angeles")!

    // MARK: - Date Creation in Specific Timezone

    /// Create a date at a specific time in a specific timezone
    ///
    /// - Parameters:
    ///   - year: Year component
    ///   - month: Month component (1-12)
    ///   - day: Day component (1-31)
    ///   - hour: Hour component (0-23)
    ///   - minute: Minute component (0-59)
    ///   - timezone: The timezone to use for interpretation
    /// - Returns: Date representing the specified moment in the specified timezone
    ///
    /// **Example:**
    /// ```swift
    /// // Create "November 8, 2025 at 11:30 PM Tokyo time"
    /// let date = createDate(year: 2025, month: 11, day: 8, hour: 23, minute: 30, timezone: .tokyo)
    /// ```
    public static func createDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        timezone: TimeZone
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        components.timeZone = timezone

        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: components)!
    }

    // MARK: - Edge Case Scenarios

    /// Create a late-night date (11:30 PM) in the specified timezone
    ///
    /// **Use Case:** Testing that logging a habit at 11:30 PM counts for THAT day (not the next day)
    ///
    /// **Example Scenario:**
    /// User in Tokyo logs habit at 11:30 PM on Friday, November 8, 2025.
    /// Expected: Log should count for Friday (not Saturday)
    ///
    /// - Parameter timezone: Timezone for the date
    /// - Returns: Date representing 11:30 PM on November 8, 2025 in the given timezone
    public static func createLateNightDate(timezone: TimeZone) -> Date {
        return createDate(
            year: 2025,
            month: 11,
            day: 8,
            hour: 23,
            minute: 30,
            timezone: timezone
        )
    }

    /// Create a midnight boundary date (11:59:59 PM) in the specified timezone
    ///
    /// **Use Case:** Testing the exact moment before day boundary
    ///
    /// - Parameter timezone: Timezone for the date
    /// - Returns: Date representing 11:59:59 PM on November 8, 2025 in the given timezone
    public static func createMidnightBoundaryDate(timezone: TimeZone) -> Date {
        var components = DateComponents()
        components.year = 2025
        components.month = 11
        components.day = 8
        components.hour = 23
        components.minute = 59
        components.second = 59
        components.timeZone = timezone

        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: components)!
    }

    /// Create a week boundary date (Sunday 11:59 PM) in the specified timezone
    ///
    /// **Use Case:** Testing week calculations near week boundaries
    ///
    /// **Example Scenario:**
    /// User logs habit on Sunday at 11:59 PM. Should count for that week, not next week.
    ///
    /// - Parameter timezone: Timezone for the date
    /// - Returns: Date representing Sunday, November 10, 2025 at 11:59 PM in the given timezone
    public static func createWeekBoundaryDate(timezone: TimeZone) -> Date {
        var components = DateComponents()
        components.year = 2025
        components.month = 11
        components.day = 10  // Sunday
        components.hour = 23
        components.minute = 59
        components.second = 59
        components.timeZone = timezone

        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: components)!
    }

    /// Create an early morning date (12:01 AM) in the specified timezone
    ///
    /// **Use Case:** Testing that logging just after midnight counts for the NEW day
    ///
    /// - Parameter timezone: Timezone for the date
    /// - Returns: Date representing 12:01 AM on November 9, 2025 in the given timezone
    public static func createEarlyMorningDate(timezone: TimeZone) -> Date {
        return createDate(
            year: 2025,
            month: 11,
            day: 9,
            hour: 0,
            minute: 1,
            timezone: timezone
        )
    }

    // MARK: - DST Transition Helpers

    /// Create a date during DST spring forward transition (loses an hour)
    ///
    /// **Use Case:** Testing that habits logged during DST transition work correctly
    ///
    /// **Note:** In US/Eastern, DST spring forward happens on March 9, 2025 at 2:00 AM
    /// Clock jumps from 1:59 AM → 3:00 AM (2:00 AM - 2:59 AM don't exist)
    ///
    /// - Returns: Date just before DST spring forward in America/New_York timezone
    public static func dstSpringForwardDate() -> Date {
        return createDate(
            year: 2025,
            month: 3,
            day: 9,
            hour: 1,
            minute: 30,
            timezone: newYork
        )
    }

    /// Create a date during DST fall back transition (gains an hour)
    ///
    /// **Use Case:** Testing that habits logged during DST transition work correctly
    ///
    /// **Note:** In US/Eastern, DST fall back happens on November 2, 2025 at 2:00 AM
    /// Clock jumps from 1:59 AM → 1:00 AM (1:00 AM - 1:59 AM happen twice)
    ///
    /// - Returns: Date just before DST fall back in America/New_York timezone
    public static func dstFallBackDate() -> Date {
        return createDate(
            year: 2025,
            month: 11,
            day: 2,
            hour: 1,
            minute: 30,
            timezone: newYork
        )
    }

    // MARK: - Timezone Transition Scenarios

    /// Create a pair of dates representing timezone transition (e.g., travel from Tokyo to New York)
    ///
    /// **Use Case:** Testing that habits work correctly when user travels
    ///
    /// **Example Scenario:**
    /// User logs habit in Tokyo on Nov 8 at 10:00 AM, then travels to NYC and logs on Nov 9 at 10:00 AM.
    /// Both logs should count for their respective days in their respective timezones.
    ///
    /// - Returns: Tuple of (beforeTravel: Tokyo date, afterTravel: NYC date)
    public static func timezoneTransitionDates() -> (beforeTravel: Date, afterTravel: Date) {
        let tokyoDate = createDate(
            year: 2025,
            month: 11,
            day: 8,
            hour: 10,
            minute: 0,
            timezone: tokyo
        )

        let newYorkDate = createDate(
            year: 2025,
            month: 11,
            day: 9,
            hour: 10,
            minute: 0,
            timezone: newYork
        )

        return (beforeTravel: tokyoDate, afterTravel: newYorkDate)
    }

    // MARK: - Week Schedule Test Dates

    /// Create dates for a Mon/Wed/Fri habit in a specific timezone
    ///
    /// **Use Case:** Testing weekly schedule habits across timezones
    ///
    /// - Parameter timezone: Timezone for the dates
    /// - Returns: Array of dates representing Mon, Wed, Fri in the given week
    public static func monWedFriDates(timezone: TimeZone) -> [Date] {
        return [
            createDate(year: 2025, month: 11, day: 3, hour: 12, minute: 0, timezone: timezone),  // Monday
            createDate(year: 2025, month: 11, day: 5, hour: 12, minute: 0, timezone: timezone),  // Wednesday
            createDate(year: 2025, month: 11, day: 7, hour: 12, minute: 0, timezone: timezone)   // Friday
        ]
    }

    /// Create dates for a full week (Mon-Sun) in a specific timezone
    ///
    /// - Parameter timezone: Timezone for the dates
    /// - Returns: Array of 7 dates representing a full week
    public static func fullWeekDates(timezone: TimeZone) -> [Date] {
        return (3...9).map { day in
            createDate(year: 2025, month: 11, day: day, hour: 12, minute: 0, timezone: timezone)
        }
    }

    // MARK: - Timezone Comparison Helpers

    /// Compare if two dates are the same calendar day in their respective timezones
    ///
    /// **Use Case:** Validating that "same day" logic works correctly across timezones
    ///
    /// - Parameters:
    ///   - date1: First date
    ///   - timezone1: Timezone for first date
    ///   - date2: Second date
    ///   - timezone2: Timezone for second date
    /// - Returns: `true` if both dates represent the same calendar day in their timezones
    public static func areSameCalendarDay(
        date1: Date,
        timezone1: TimeZone,
        date2: Date,
        timezone2: TimeZone
    ) -> Bool {
        let calendar1 = Calendar(identifier: .gregorian)
        let calendar2 = Calendar(identifier: .gregorian)

        var cal1 = calendar1
        cal1.timeZone = timezone1
        let components1 = cal1.dateComponents([.year, .month, .day], from: date1)

        var cal2 = calendar2
        cal2.timeZone = timezone2
        let components2 = cal2.dateComponents([.year, .month, .day], from: date2)

        return components1.year == components2.year &&
               components1.month == components2.month &&
               components1.day == components2.day
    }

    /// Get the calendar day components (year, month, day) for a date in a specific timezone
    ///
    /// - Parameters:
    ///   - date: Date to analyze
    ///   - timezone: Timezone to interpret the date in
    /// - Returns: Date components (year, month, day)
    public static func calendarDay(for date: Date, in timezone: TimeZone) -> (year: Int, month: Int, day: Int) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone

        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return (
            year: components.year!,
            month: components.month!,
            day: components.day!
        )
    }
}

// MARK: - Mock TimezoneService for Testing

/// Mock TimezoneService that returns a fixed timezone for testing
///
/// **Purpose:** Test implementation of TimezoneService protocol for use in service tests
/// that need timezone coordination (e.g., HabitCompletionCheckService, NotificationScheduler)
///
/// **NOT A MOCK:** This is a real test implementation providing actual behavior,
/// not a mock with stubbed returns. It follows the "NO MOCKS" testing philosophy.
///
/// **Usage:**
/// ```swift
/// let tokyo = TimeZone(identifier: "Asia/Tokyo")!
/// let timezoneService = MockTimezoneService(displayTimezone: tokyo)
/// let service = DefaultHabitCompletionCheckService(
///     habitRepository: habitRepo,
///     logRepository: logRepo,
///     habitCompletionService: completionService,
///     timezoneService: timezoneService
/// )
/// ```
public final class MockTimezoneService: TimezoneService {
    private let displayTimezone: TimeZone
    private let shouldThrowError: Bool

    /// Initialize mock timezone service
    /// - Parameters:
    ///   - displayTimezone: The timezone to return from getDisplayTimezone()
    ///   - shouldThrowError: If true, getDisplayTimezone() will throw an error (for testing error handling)
    public init(displayTimezone: TimeZone = .current, shouldThrowError: Bool = false) {
        self.displayTimezone = displayTimezone
        self.shouldThrowError = shouldThrowError
    }

    public func getCurrentTimezone() -> TimeZone {
        return .current
    }

    public func getHomeTimezone() async throws -> TimeZone {
        return displayTimezone
    }

    public func getDisplayTimezone() async throws -> TimeZone {
        if shouldThrowError {
            throw NSError(domain: "MockTimezoneService", code: 1, userInfo: nil)
        }
        return displayTimezone
    }

    public func getDisplayTimezoneMode() async throws -> DisplayTimezoneMode {
        return .current
    }

    public func updateHomeTimezone(_ timezone: TimeZone) async throws {
        // Not needed for tests
    }

    public func updateDisplayTimezoneMode(_ mode: DisplayTimezoneMode) async throws {
        // Not needed for tests
    }

    public func detectTimezoneChange() async throws -> TimezoneChangeDetection? {
        return nil
    }

    public func detectTravelStatus() async throws -> TravelStatus? {
        return nil
    }

    public func updateCurrentTimezone() async throws {
        // Not needed for tests
    }
}
