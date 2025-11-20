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
@Suite("HistoricalDateValidationService Tests")
struct HistoricalDateValidationServiceTests {

    // MARK: - Boundary Tests

    @Test("Date within bounds is valid")
    func dateWithinBoundsIsValid() throws {
        let service = DefaultHistoricalDateValidationService()

        // Test date 15 days ago (well within 30-day limit)
        let fifteenDaysAgo = CalendarUtils.addDays(-15, to: Date())

        // Should not throw
        let validatedDate = try service.validateHistoricalDate(fifteenDaysAgo)

        // Should return normalized (start of day)
        let expected = CalendarUtils.startOfDayLocal(for: fifteenDaysAgo)
        #expect(validatedDate == expected)
    }

    @Test("Future date throws futureDate error")
    func futureDateThrowsError() throws {
        let service = DefaultHistoricalDateValidationService()

        // Test date tomorrow
        let tomorrow = CalendarUtils.addDays(1, to: Date())

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

        // Test date 31 days ago (beyond 30-day limit)
        let thirtyOneDaysAgo = CalendarUtils.addDays(-31, to: Date())

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

        // Test exactly 30 days ago
        let thirtyDaysAgo = CalendarUtils.addDays(-30, to: Date())

        // Should not throw (boundary is inclusive)
        let validatedDate = try service.validateHistoricalDate(thirtyDaysAgo)

        // Should return normalized date
        let expected = CalendarUtils.startOfDayLocal(for: thirtyDaysAgo)
        #expect(validatedDate == expected)
    }

    @Test("Date 31 days ago is invalid")
    func thirtyOneDaysAgoIsInvalid() throws {
        let service = DefaultHistoricalDateValidationService()

        // Test 31 days ago (just beyond boundary)
        let thirtyOneDaysAgo = CalendarUtils.addDays(-31, to: Date())

        // Should throw
        #expect(throws: HistoricalDateValidationError.self) {
            try service.validateHistoricalDate(thirtyOneDaysAgo)
        }
    }

    // MARK: - API Tests

    @Test("isDateWithinBounds returns correct boolean for valid date")
    func isDateWithinBoundsReturnsTrueForValidDate() {
        let service = DefaultHistoricalDateValidationService()

        // Test date 15 days ago (valid)
        let fifteenDaysAgo = CalendarUtils.addDays(-15, to: Date())

        #expect(service.isDateWithinBounds(fifteenDaysAgo) == true)
    }

    @Test("isDateWithinBounds returns false for future date")
    func isDateWithinBoundsReturnsFalseForFutureDate() {
        let service = DefaultHistoricalDateValidationService()

        // Test tomorrow (invalid)
        let tomorrow = CalendarUtils.addDays(1, to: Date())

        #expect(service.isDateWithinBounds(tomorrow) == false)
    }

    @Test("isDateWithinBounds returns false for date beyond limit")
    func isDateWithinBoundsReturnsFalseForDateBeyondLimit() {
        let service = DefaultHistoricalDateValidationService()

        // Test 31 days ago (invalid)
        let thirtyOneDaysAgo = CalendarUtils.addDays(-31, to: Date())

        #expect(service.isDateWithinBounds(thirtyOneDaysAgo) == false)
    }

    @Test("getEarliestAllowedDate returns correct date")
    func getEarliestAllowedDateReturnsCorrectDate() {
        let service = DefaultHistoricalDateValidationService()

        // Get earliest allowed date
        let earliest = service.getEarliestAllowedDate()

        // Should match production logic: startOfDay first, then addDays
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

        // Test date 5 days ago (valid)
        let fiveDaysAgo = CalendarUtils.addDays(-5, to: Date())
        let validatedDate = try service.validateHistoricalDate(fiveDaysAgo)
        #expect(validatedDate == CalendarUtils.startOfDayLocal(for: fiveDaysAgo))

        // Test date 8 days ago (invalid with 7-day limit)
        let eightDaysAgo = CalendarUtils.addDays(-8, to: Date())
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
        let expected = CalendarUtils.addDays(-14, to: today)

        #expect(earliest == expected)
    }

    // MARK: - Date String Validation

    @Test("Valid ISO8601 date string is parsed and validated")
    func validISO8601StringIsParsedAndValidated() throws {
        let service = DefaultHistoricalDateValidationService()

        // Create ISO8601 date string for 10 days ago
        let tenDaysAgo = CalendarUtils.addDays(-10, to: Date())
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = formatter.string(from: tenDaysAgo)

        // Should parse and validate successfully
        let validatedDate = try service.validateHistoricalDateString(dateString)

        // Should be normalized to start of day
        let expected = CalendarUtils.startOfDayLocal(for: tenDaysAgo)
        #expect(validatedDate == expected)
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
