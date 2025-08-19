//
//  HistoricalDateValidationServiceTests.swift
//  RitualistCoreTests
//
//  Created by Claude on 19.08.2025.
//

import Testing
import Foundation
@testable import RitualistCore

@Suite("Historical Date Validation Service Tests")
struct HistoricalDateValidationServiceTests {
    
    private let service = DefaultHistoricalDateValidationService()
    private let calendar = Calendar.current
    
    @Test("Validate today's date succeeds")
    func validateTodaysDate() throws {
        let today = Date()
        let validatedDate = try service.validateHistoricalDate(today)
        let expectedDate = calendar.startOfDay(for: today)
        
        #expect(calendar.isDate(validatedDate, inSameDayAs: expectedDate))
    }
    
    @Test("Validate date within bounds succeeds")
    func validateDateWithinBounds() throws {
        let tenDaysAgo = calendar.date(byAdding: .day, value: -10, to: Date())!
        let validatedDate = try service.validateHistoricalDate(tenDaysAgo)
        let expectedDate = calendar.startOfDay(for: tenDaysAgo)
        
        #expect(calendar.isDate(validatedDate, inSameDayAs: expectedDate))
    }
    
    @Test("Validate future date throws error")
    func validateFutureDateThrowsError() {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        
        #expect(throws: HistoricalDateValidationError.self) {
            _ = try service.validateHistoricalDate(tomorrow)
        }
    }
    
    @Test("Validate date beyond history limit throws error")
    func validateDateBeyondLimitThrowsError() {
        let fortyDaysAgo = calendar.date(byAdding: .day, value: -40, to: Date())!
        
        #expect(throws: HistoricalDateValidationError.self) {
            _ = try service.validateHistoricalDate(fortyDaysAgo)
        }
    }
    
    @Test("Validate ISO8601 date string succeeds")
    func validateISO8601DateString() throws {
        let tenDaysAgo = calendar.date(byAdding: .day, value: -10, to: Date())!
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = formatter.string(from: tenDaysAgo)
        
        let validatedDate = try service.validateHistoricalDateString(dateString)
        
        #expect(calendar.isDate(validatedDate, inSameDayAs: tenDaysAgo))
    }
    
    @Test("Validate invalid date string throws error")
    func validateInvalidDateStringThrowsError() {
        let invalidDateString = "invalid-date-format"
        
        #expect(throws: HistoricalDateValidationError.self) {
            _ = try service.validateHistoricalDateString(invalidDateString)
        }
    }
    
    @Test("Check if date is within bounds")
    func checkDateWithinBounds() {
        let tenDaysAgo = calendar.date(byAdding: .day, value: -10, to: Date())!
        let fortyDaysAgo = calendar.date(byAdding: .day, value: -40, to: Date())!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        
        #expect(service.isDateWithinBounds(tenDaysAgo) == true)
        #expect(service.isDateWithinBounds(fortyDaysAgo) == false)
        #expect(service.isDateWithinBounds(tomorrow) == false)
        #expect(service.isDateWithinBounds(Date()) == true)
    }
    
    @Test("Get earliest allowed date")
    func getEarliestAllowedDate() {
        let earliestDate = service.getEarliestAllowedDate()
        let expectedDate = calendar.date(byAdding: .day, value: -30, to: Date())!
        let expectedNormalized = calendar.startOfDay(for: expectedDate)
        
        #expect(calendar.isDate(earliestDate, inSameDayAs: expectedNormalized))
    }
    
    @Test("Custom configuration with different max history days")
    func customConfiguration() throws {
        let customConfig = HistoricalDateValidationConfig(maxHistoryDays: 15)
        let customService = DefaultHistoricalDateValidationService(config: customConfig)
        
        let twentyDaysAgo = calendar.date(byAdding: .day, value: -20, to: Date())!
        let tenDaysAgo = calendar.date(byAdding: .day, value: -10, to: Date())!
        
        // 20 days ago should be invalid with 15-day limit
        #expect(customService.isDateWithinBounds(twentyDaysAgo) == false)
        
        // 10 days ago should be valid with 15-day limit
        #expect(customService.isDateWithinBounds(tenDaysAgo) == true)
        
        // Verify configuration
        #expect(customService.getConfiguration().maxHistoryDays == 15)
    }
}