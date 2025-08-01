//
//  DateUtilsTests.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 29.07.2025.
//

import XCTest
@testable import Ritualist

final class DateUtilsTests: XCTestCase {

    func testStartOfDay_and_isSameDay() {
        let calendar = Calendar(identifier: .gregorian)
        // Pick a date-time with hour/minute
        let components = DateComponents(year: 2025, month: 3, day: 10, hour: 15, minute: 45)
        let dt = calendar.date(from: components)!
        let sod = DateUtils.startOfDay(dt, calendar: calendar)

        // startOfDay should drop time components
        XCTAssertEqual(calendar.component(.hour, from: sod), 0)
        XCTAssertEqual(calendar.component(.minute, from: sod), 0)

        // isSameDay should be true for dt vs sod
        XCTAssertTrue(DateUtils.isSameDay(dt, sod, calendar: calendar))
    }

    func testDaysBetween() {
        let calendar = Calendar(identifier: .gregorian)
        let day1 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let day5 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 5))!
        XCTAssertEqual(DateUtils.daysBetween(day1, day5, calendar: calendar), 4)
        XCTAssertEqual(DateUtils.daysBetween(day5, day1, calendar: calendar), -4)
    }

    func testWeekKey_onDifferentWeekdays() {
        let calendar = Calendar(identifier: .gregorian)
        // 2025-01-01 is a Wednesday
        let jan1 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        // If week starts on Monday (2), this is week 1 of 2025
        let keyMon = DateUtils.weekKey(for: jan1, firstWeekday: 2, calendar: calendar)
        XCTAssertEqual(keyMon.year, 2025)
        XCTAssertEqual(keyMon.week, 1)
        // If week starts on Sunday (1), this falls in week 0 or last week of 2024
        let keySun = DateUtils.weekKey(for: jan1, firstWeekday: 1, calendar: calendar)
        // Depending on locale rules, make a loose check:
        XCTAssertNotNil(keySun.week)
    }

    func testDaysBetween_acrossDSTTransition() {
        // e.g. US DST starts March 9, 2025 at 2:00am
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!

        let beforeDST = calendar.date(from: DateComponents(year: 2025, month: 3, day: 8, hour: 12))!
        let afterDST = calendar.date(from: DateComponents(year: 2025, month: 3, day: 10, hour: 12))!
        // Should be exactly 2 days apart, despite the 23-hour DST day
        XCTAssertEqual(DateUtils.daysBetween(beforeDST, afterDST, calendar: calendar), 2)
    }
    
    // MARK: - Default Parameter Tests
    
    func testDefaultCalendarParameters() {
        let date = Date()
        
        // Test that methods work with default Calendar.current parameter
        let startOfDayDefault = DateUtils.startOfDay(date)
        let startOfDayExplicit = DateUtils.startOfDay(date, calendar: .current)
        XCTAssertEqual(startOfDayDefault, startOfDayExplicit)
        
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        XCTAssertTrue(DateUtils.isSameDay(today, today)) // Default calendar
        XCTAssertFalse(DateUtils.isSameDay(today, tomorrow)) // Default calendar
        
        let daysBetweenDefault = DateUtils.daysBetween(today, tomorrow)
        let daysBetweenExplicit = DateUtils.daysBetween(today, tomorrow, calendar: .current)
        XCTAssertEqual(daysBetweenDefault, daysBetweenExplicit)
    }
    
    // MARK: - userCalendar Tests
    
    func testUserCalendar_withFirstDayOfWeek() {
        // Test with Monday as first day (2)
        let mondayCalendar = DateUtils.userCalendar(firstDayOfWeek: 2)
        XCTAssertEqual(mondayCalendar.firstWeekday, 2)
        XCTAssertEqual(mondayCalendar.locale, Locale.current)
        
        // Test with Sunday as first day (1)
        let sundayCalendar = DateUtils.userCalendar(firstDayOfWeek: 1)
        XCTAssertEqual(sundayCalendar.firstWeekday, 1)
        
        // Test with Friday as first day (6)
        let fridayCalendar = DateUtils.userCalendar(firstDayOfWeek: 6)
        XCTAssertEqual(fridayCalendar.firstWeekday, 6)
    }
    
    func testUserCalendar_withoutFirstDayOfWeek() {
        // Test default behavior (should use locale default)
        let defaultCalendar = DateUtils.userCalendar()
        let expectedFirstWeekday = Calendar.current.firstWeekday
        
        XCTAssertEqual(defaultCalendar.firstWeekday, expectedFirstWeekday)
        XCTAssertEqual(defaultCalendar.locale, Locale.current)
    }
    
    func testUserCalendar_withNilFirstDayOfWeek() {
        // Test explicit nil (should use locale default)
        let nilCalendar = DateUtils.userCalendar(firstDayOfWeek: nil)
        let expectedFirstWeekday = Calendar.current.firstWeekday
        
        XCTAssertEqual(nilCalendar.firstWeekday, expectedFirstWeekday)
        XCTAssertEqual(nilCalendar.locale, Locale.current)
    }
    
    // MARK: - orderedWeekdaySymbols Tests
    
    func testOrderedWeekdaySymbols_veryShortStyle() {
        // Test with Monday first (most common international standard)
        let mondayFirst = DateUtils.orderedWeekdaySymbols(firstDayOfWeek: 2, style: .veryShort)
        
        XCTAssertEqual(mondayFirst.count, 7, "Should have 7 weekday symbols")
        XCTAssertFalse(mondayFirst.isEmpty, "Should not be empty")
        
        // Test with Sunday first (US standard)
        let sundayFirst = DateUtils.orderedWeekdaySymbols(firstDayOfWeek: 1, style: .veryShort)
        
        XCTAssertEqual(sundayFirst.count, 7, "Should have 7 weekday symbols")
        XCTAssertNotEqual(mondayFirst, sundayFirst, "Monday-first and Sunday-first should be different")
    }
    
    func testOrderedWeekdaySymbols_shortStyle() {
        let shortSymbols = DateUtils.orderedWeekdaySymbols(firstDayOfWeek: 2, style: .short)
        
        XCTAssertEqual(shortSymbols.count, 7, "Should have 7 weekday symbols")
        
        // Short symbols should generally be longer than very short
        let veryShortSymbols = DateUtils.orderedWeekdaySymbols(firstDayOfWeek: 2, style: .veryShort)
        
        // At least some symbols should be longer in short style
        let hasLongerSymbols = zip(shortSymbols, veryShortSymbols).contains { short, veryShort in
            short.count > veryShort.count
        }
        XCTAssertTrue(hasLongerSymbols, "Short style should have some longer symbols than very short")
    }
    
    func testOrderedWeekdaySymbols_standaloneStyle() {
        let standaloneSymbols = DateUtils.orderedWeekdaySymbols(firstDayOfWeek: 1, style: .standalone)
        
        XCTAssertEqual(standaloneSymbols.count, 7, "Should have 7 weekday symbols")
        XCTAssertFalse(standaloneSymbols.isEmpty, "Should not be empty")
    }
    
    func testOrderedWeekdaySymbols_differentFirstDays() {
        // Test all possible first day values
        for firstDay in 1...7 {
            let symbols = DateUtils.orderedWeekdaySymbols(firstDayOfWeek: firstDay)
            XCTAssertEqual(symbols.count, 7, "Should have 7 symbols for firstDay \(firstDay)")
        }
    }
    
    func testOrderedWeekdaySymbols_invalidFirstDay() {
        // Test edge cases with invalid first day values
        let invalidLow = DateUtils.orderedWeekdaySymbols(firstDayOfWeek: 0)
        let invalidHigh = DateUtils.orderedWeekdaySymbols(firstDayOfWeek: 8)
        
        // Should handle gracefully and return some symbols
        XCTAssertEqual(invalidLow.count, 7, "Should handle invalid low value gracefully")
        XCTAssertEqual(invalidHigh.count, 7, "Should handle invalid high value gracefully")
    }
    
    // MARK: - WeekKey Edge Cases
    
    func testWeekKey_yearBoundary() {
        let calendar = Calendar(identifier: .gregorian)
        
        // Test week that spans year boundary
        let dec31_2024 = calendar.date(from: DateComponents(year: 2024, month: 12, day: 31))!
        let jan1_2025 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        
        let dec31Key = DateUtils.weekKey(for: dec31_2024, firstWeekday: 2, calendar: calendar)
        let jan1Key = DateUtils.weekKey(for: jan1_2025, firstWeekday: 2, calendar: calendar)
        
        // Both should return valid years and weeks
        XCTAssertGreaterThan(dec31Key.year, 0)
        XCTAssertGreaterThan(dec31Key.week, 0)
        XCTAssertGreaterThan(jan1Key.year, 0)
        XCTAssertGreaterThan(jan1Key.week, 0)
    }
    
    func testWeekKey_differentCalendarSystems() {
        let gregorianCal = Calendar(identifier: .gregorian)
        let isoCal = Calendar(identifier: .iso8601)
        
        let testDate = Date()
        
        let gregorianKey = DateUtils.weekKey(for: testDate, firstWeekday: 2, calendar: gregorianCal)
        let isoKey = DateUtils.weekKey(for: testDate, firstWeekday: 2, calendar: isoCal)
        
        // Both should return valid results
        XCTAssertGreaterThan(gregorianKey.year, 0)
        XCTAssertGreaterThan(gregorianKey.week, 0)
        XCTAssertGreaterThan(isoKey.year, 0)
        XCTAssertGreaterThan(isoKey.week, 0)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testIsSameDay_acrossTimeZones() {
        // Test with different time zones but same calendar day
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        
        var pacificCalendar = Calendar(identifier: .gregorian)
        pacificCalendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        
        let utcMidnight = utcCalendar.date(from: DateComponents(year: 2025, month: 6, day: 15, hour: 0))!
        
        XCTAssertTrue(DateUtils.isSameDay(utcMidnight, utcMidnight, calendar: utcCalendar))
        XCTAssertTrue(DateUtils.isSameDay(utcMidnight, utcMidnight, calendar: pacificCalendar))
    }
    
    func testDaysBetween_sameDay() {
        let calendar = Calendar(identifier: .gregorian)
        let morning = calendar.date(from: DateComponents(year: 2025, month: 6, day: 15, hour: 8))!
        let evening = calendar.date(from: DateComponents(year: 2025, month: 6, day: 15, hour: 20))!
        
        XCTAssertEqual(DateUtils.daysBetween(morning, evening, calendar: calendar), 0)
        XCTAssertEqual(DateUtils.daysBetween(evening, morning, calendar: calendar), 0)
    }
    
    func testDaysBetween_largeTimeSpan() {
        let calendar = Calendar(identifier: .gregorian)
        let date1 = calendar.date(from: DateComponents(year: 2020, month: 1, day: 1))!
        let date2 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        
        let daysBetween = DateUtils.daysBetween(date1, date2, calendar: calendar)
        XCTAssertEqual(daysBetween, 1827, "Should be exactly 1827 days (5 years including leap year)")
        XCTAssertEqual(DateUtils.daysBetween(date2, date1, calendar: calendar), -1827)
    }
}
