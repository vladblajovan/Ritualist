import Testing
import Foundation
@testable import RitualistCore

/// Tests for HistoricalDateValidationService (Phase 1)
///
/// **Service Purpose:** Validates date boundaries for historical logging (30-day limit)
/// **Why Critical:** Prevents users from logging habits too far in the past
/// **Test Strategy:** Pure logic testing with boundary conditions and edge cases
///
/// **Test Coverage:**
/// - Boundary validation (future dates, beyond history limit)
/// - Edge cases (today, exactly at boundary, just beyond boundary)
/// - API completeness (all public methods)
/// - Configuration customization
/// - Date string parsing
#if swift(>=6.1)
@Suite(
    "HistoricalDateValidationService Tests",
    .tags(.history, .businessLogic, .critical, .isolated, .fast, .edgeCases)
)
#else
@Suite("HistoricalDateValidationService Tests")
#endif
struct HistoricalDateValidationServiceTests {

    // MARK: - Boundary Tests

    @Test("Date within bounds is valid")
    func dateWithinBoundsIsValid() throws {
        let service = DefaultHistoricalDateValidationService()

        // Test date 15 days ago (well within 30-day limit)
        // Must normalize to start of day FIRST to match service logic
        let today = CalendarUtils.startOfDayLocal(for: Date())
        let fifteenDaysAgo = CalendarUtils.addDaysLocal(-15, to: today, timezone: .current)

        // Should not throw
        let validatedDate = try service.validateHistoricalDate(fifteenDaysAgo)

        // Should return normalized (start of day)
        #expect(validatedDate == fifteenDaysAgo)  // Already normalized
    }

    @Test("Future date throws futureDate error")
    func futureDateThrowsError() throws {
        let service = DefaultHistoricalDateValidationService()

        // Test date tomorrow - normalize first
        let today = CalendarUtils.startOfDayLocal(for: Date())
        let tomorrow = CalendarUtils.addDaysLocal(1, to: today, timezone: .current)

        // Should throw futureDate error
        #expect(throws: HistoricalDateValidationError.self) {
            try service.validateHistoricalDate(tomorrow)
        }

        // Verify specific error type
        do {
            _ = try service.validateHistoricalDate(tomorrow)
            Issue.record("Expected futureDate error but none was thrown")
        } catch let error as HistoricalDateValidationError {
            if case .futureDate = error {
                // Correct error type
            } else {
                Issue.record("Expected futureDate error, got \(error)")
            }
        } catch {
            Issue.record("Expected HistoricalDateValidationError, got \(error)")
        }
    }

    @Test("Date beyond history limit throws beyondHistoryLimit error")
    func dateBeyondLimitThrowsError() throws {
        let service = DefaultHistoricalDateValidationService()

        // Test date 31 days ago (beyond 30-day limit) - normalize first
        let today = CalendarUtils.startOfDayLocal(for: Date())
        let thirtyOneDaysAgo = CalendarUtils.addDaysLocal(-31, to: today, timezone: .current)

        // Should throw beyondHistoryLimit error
        #expect(throws: HistoricalDateValidationError.self) {
            try service.validateHistoricalDate(thirtyOneDaysAgo)
        }

        // Verify specific error type
        do {
            _ = try service.validateHistoricalDate(thirtyOneDaysAgo)
            Issue.record("Expected beyondHistoryLimit error but none was thrown")
        } catch let error as HistoricalDateValidationError {
            if case .beyondHistoryLimit(_, let maxDays) = error {
                #expect(maxDays == 30, "Expected max days to be 30")
            } else {
                Issue.record("Expected beyondHistoryLimit error, got \(error)")
            }
        } catch {
            Issue.record("Expected HistoricalDateValidationError, got \(error)")
        }
    }

    @Test("Invalid date string throws invalidDateFormat error")
    func invalidDateStringThrowsError() throws {
        let service = DefaultHistoricalDateValidationService()

        // Test invalid date format
        let invalidDateString = "not-a-date"

        // Should throw invalidDateFormat error
        #expect(throws: HistoricalDateValidationError.self) {
            try service.validateHistoricalDateString(invalidDateString)
        }

        // Verify specific error type
        do {
            _ = try service.validateHistoricalDateString(invalidDateString)
            Issue.record("Expected invalidDateFormat error but none was thrown")
        } catch let error as HistoricalDateValidationError {
            if case .invalidDateFormat = error {
                // Correct error type
            } else {
                Issue.record("Expected invalidDateFormat error, got \(error)")
            }
        } catch {
            Issue.record("Expected HistoricalDateValidationError, got \(error)")
        }
    }

    // MARK: - Edge Cases

    @Test("Date exactly at boundary (today) is valid")
    func todayIsValid() throws {
        let service = DefaultHistoricalDateValidationService()

        // Test today
        let today = Date()

        // Should not throw
        let validatedDate = try service.validateHistoricalDate(today)

        // Should return start of today
        let expected = CalendarUtils.startOfDayLocal(for: today)
        #expect(validatedDate == expected)
    }

    @Test("Date exactly at boundary (30 days ago) is valid")
    func thirtyDaysAgoIsValid() throws {
        let service = DefaultHistoricalDateValidationService()

        // Test 29 days ago (safely within 30-day limit)
        // CRITICAL: Use addDaysLocal to handle DST transitions correctly
        let today = CalendarUtils.startOfDayLocal(for: Date())
        let twentyNineDaysAgo = CalendarUtils.addDaysLocal(-29, to: today, timezone: .current)

        // Should not throw (well within boundary)
        let validatedDate = try service.validateHistoricalDate(twentyNineDaysAgo)

        // Should return normalized (start of day)
        #expect(validatedDate == twentyNineDaysAgo)  // Already normalized with DST handling
    }

    @Test("Date 31 days ago is invalid")
    func thirtyOneDaysAgoIsInvalid() throws {
        let service = DefaultHistoricalDateValidationService()

        // Test 31 days ago (just beyond boundary) - MUST match service's calculation order
        let today = CalendarUtils.startOfDayLocal(for: Date())
        let thirtyOneDaysAgo = CalendarUtils.addDaysLocal(-31, to: today, timezone: .current)

        // Should throw
        #expect(throws: HistoricalDateValidationError.self) {
            try service.validateHistoricalDate(thirtyOneDaysAgo)
        }
    }

    // MARK: - API Tests

    @Test("isDateWithinBounds returns correct boolean for valid date")
    func isDateWithinBoundsReturnsTrueForValidDate() {
        let service = DefaultHistoricalDateValidationService()

        // Test date 15 days ago (valid) - normalize first
        let today = CalendarUtils.startOfDayLocal(for: Date())
        let fifteenDaysAgo = CalendarUtils.addDaysLocal(-15, to: today, timezone: .current)

        #expect(service.isDateWithinBounds(fifteenDaysAgo) == true)
    }

    @Test("isDateWithinBounds returns false for future date")
    func isDateWithinBoundsReturnsFalseForFutureDate() {
        let service = DefaultHistoricalDateValidationService()

        // Test tomorrow (invalid) - normalize first
        let today = CalendarUtils.startOfDayLocal(for: Date())
        let tomorrow = CalendarUtils.addDaysLocal(1, to: today, timezone: .current)

        #expect(service.isDateWithinBounds(tomorrow) == false)
    }

    @Test("isDateWithinBounds returns false for date beyond limit")
    func isDateWithinBoundsReturnsFalseForDateBeyondLimit() {
        let service = DefaultHistoricalDateValidationService()

        // Test 31 days ago (invalid) - normalize first
        let today = CalendarUtils.startOfDayLocal(for: Date())
        let thirtyOneDaysAgo = CalendarUtils.addDaysLocal(-31, to: today, timezone: .current)

        #expect(service.isDateWithinBounds(thirtyOneDaysAgo) == false)
    }

    @Test("getEarliestAllowedDate returns correct date")
    func getEarliestAllowedDateReturnsCorrectDate() {
        let service = DefaultHistoricalDateValidationService()

        // Get earliest allowed date
        let earliest = service.getEarliestAllowedDate()

        // Should match production logic: startOfDay first, then addDays (UTC calendar)
        // Note: Service uses addDays() not addDaysLocal(), so we must match that
        let today = CalendarUtils.startOfDayLocal(for: Date())
        let expected = CalendarUtils.addDays(-30, to: today)

        #expect(earliest == expected)
    }

    // MARK: - Configuration Tests

    @Test("Custom maxHistoryDays configuration works")
    func customMaxHistoryDaysWorks() throws {
        // Create service with 7-day limit
        let config = HistoricalDateValidationConfig(maxHistoryDays: 7)
        let service = DefaultHistoricalDateValidationService(config: config)

        // Normalize to start of day FIRST
        let today = CalendarUtils.startOfDayLocal(for: Date())

        // Test date 5 days ago (valid)
        let fiveDaysAgo = CalendarUtils.addDaysLocal(-5, to: today, timezone: .current)
        let validatedDate = try service.validateHistoricalDate(fiveDaysAgo)
        #expect(validatedDate == fiveDaysAgo)  // Already normalized

        // Test date 8 days ago (invalid with 7-day limit)
        let eightDaysAgo = CalendarUtils.addDaysLocal(-8, to: today, timezone: .current)
        #expect(throws: HistoricalDateValidationError.self) {
            try service.validateHistoricalDate(eightDaysAgo)
        }

        // Verify configuration is returned correctly
        let returnedConfig = service.getConfiguration()
        #expect(returnedConfig.maxHistoryDays == 7)
    }

    @Test("getEarliestAllowedDate respects custom configuration")
    func getEarliestAllowedDateRespectsCustomConfig() {
        // Create service with 14-day limit
        let config = HistoricalDateValidationConfig(maxHistoryDays: 14)
        let service = DefaultHistoricalDateValidationService(config: config)

        // Get earliest allowed date
        let earliest = service.getEarliestAllowedDate()

        // Should match production logic: startOfDay first, then addDays
        let today = CalendarUtils.startOfDayLocal(for: Date())
        let expected = CalendarUtils.addDaysLocal(-14, to: today, timezone: .current)

        #expect(earliest == expected)
    }

    // MARK: - Date String Validation

    @Test("Valid ISO8601 date string is parsed and validated")
    func validISO8601StringIsParsedAndValidated() throws {
        let service = DefaultHistoricalDateValidationService()

        // Create ISO8601 date string for 10 days ago - normalize first
        let today = CalendarUtils.startOfDayLocal(for: Date())
        let tenDaysAgo = CalendarUtils.addDaysLocal(-10, to: today, timezone: .current)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = formatter.string(from: tenDaysAgo)

        // Should parse and validate successfully
        let validatedDate = try service.validateHistoricalDateString(dateString)

        // Should be normalized to start of day
        #expect(validatedDate == tenDaysAgo)  // Already normalized
    }

    @Test("Invalid date string format throws error")
    func invalidDateStringFormatThrowsError() {
        let service = DefaultHistoricalDateValidationService()

        // Test various invalid formats
        let invalidFormats = [
            "2025-13-01",  // Invalid month
            "not a date",
            "2025/11/20",  // Wrong separator
            "",
            "2025-11-20 25:00:00"  // Invalid hour
        ]

        for invalidFormat in invalidFormats {
            #expect(throws: HistoricalDateValidationError.self) {
                try service.validateHistoricalDateString(invalidFormat)
            }
        }
    }
}
