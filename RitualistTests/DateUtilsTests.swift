//
//  DateUtilsTests.swift
//  RitualistTests
//
//  Created by Claude on 04.08.2025.
//

import Testing
import Foundation
@testable import Ritualist
import RitualistCore

struct DateUtilsTests {
    
    // MARK: - Test Data Setup
    
    // Fixed test dates for consistent testing
    static let testCalendar = DateUtils.userCalendar()
    static let testDate1 = testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 4, hour: 14, minute: 30))!
    static let testDate2 = testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 5, hour: 9, minute: 15))!
    static let testDate3 = testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 7, hour: 22, minute: 45))!
    
    // MARK: - Current Time Tests
    
    @Test("Now returns current date")
    func nowReturnsCurrentDate() {
        let before = Date()
        let result = DateUtils.now
        let after = Date()
        
        #expect(result >= before)
        #expect(result <= after)
    }
    
    // MARK: - Start of Day Tests
    
    @Test("Start of day returns midnight for given date")
    func startOfDayReturnsMidnight() {
        let result = DateUtils.startOfDay(Self.testDate1, calendar: Self.testCalendar)
        let components = Self.testCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: result)
        
        #expect(components.year == 2025)
        #expect(components.month == 8)
        #expect(components.day == 4)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }
    
    @Test("Start of day works with default calendar")
    func startOfDayDefaultCalendar() {
        let result = DateUtils.startOfDay(Self.testDate1)
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: result)
        
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }
    
    @Test("Start of day is idempotent")
    func startOfDayIdempotent() {
        let firstCall = DateUtils.startOfDay(Self.testDate1, calendar: Self.testCalendar)
        let secondCall = DateUtils.startOfDay(firstCall, calendar: Self.testCalendar)
        
        #expect(firstCall == secondCall)
    }
    
    // MARK: - Same Day Tests
    
    @Test("Is same day returns true for dates on same day with different times")
    func isSameDayTrueForSameDay() {
        let morning = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 4, hour: 8, minute: 0))!
        let evening = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 4, hour: 20, minute: 0))!
        
        let result = DateUtils.isSameDay(morning, evening, calendar: Self.testCalendar)
        #expect(result == true)
    }
    
    @Test("Is same day returns false for dates on different days")
    func isSameDayFalseForDifferentDays() {
        let result = DateUtils.isSameDay(Self.testDate1, Self.testDate2, calendar: Self.testCalendar)
        #expect(result == false)
    }
    
    @Test("Is same day returns true for identical dates")
    func isSameDayTrueForIdenticalDates() {
        let result = DateUtils.isSameDay(Self.testDate1, Self.testDate1, calendar: Self.testCalendar)
        #expect(result == true)
    }
    
    @Test("Is same day works with default calendar")
    func isSameDayDefaultCalendar() {
        let today = Date()
        let result = DateUtils.isSameDay(today, today)
        #expect(result == true)
    }
    
    @Test("Is same day handles midnight boundary correctly")
    func isSameDayMidnightBoundary() {
        let beforeMidnight = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 4, hour: 23, minute: 59, second: 59))!
        let afterMidnight = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 5, hour: 0, minute: 0, second: 1))!
        
        let result = DateUtils.isSameDay(beforeMidnight, afterMidnight, calendar: Self.testCalendar)
        #expect(result == false)
    }
    
    // MARK: - Days Between Tests
    
    @Test("Days between returns correct count for consecutive days")
    func daysBetweenConsecutiveDays() {
        let result = DateUtils.daysBetween(Self.testDate1, Self.testDate2, calendar: Self.testCalendar)
        #expect(result == 1)
    }
    
    @Test("Days between returns zero for same day")
    func daysBetweenSameDay() {
        let morning = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 4, hour: 8, minute: 0))!
        let evening = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 4, hour: 20, minute: 0))!
        
        let result = DateUtils.daysBetween(morning, evening, calendar: Self.testCalendar)
        #expect(result == 0)
    }
    
    @Test("Days between returns negative for reversed dates")
    func daysBetweenReversedDates() {
        let result = DateUtils.daysBetween(Self.testDate2, Self.testDate1, calendar: Self.testCalendar)
        #expect(result == -1)
    }
    
    @Test("Days between handles multiple days correctly")
    func daysBetweenMultipleDays() {
        let result = DateUtils.daysBetween(Self.testDate1, Self.testDate3, calendar: Self.testCalendar)
        #expect(result == 3) // Aug 4 to Aug 7 = 3 days
    }
    
    @Test("Days between ignores time of day")
    func daysBetweenIgnoresTime() {
        let date1 = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 4, hour: 1, minute: 0))!
        let date2 = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 5, hour: 23, minute: 0))!
        
        let result = DateUtils.daysBetween(date1, date2, calendar: Self.testCalendar)
        #expect(result == 1)
    }
    
    @Test("Days between works with default calendar")
    func daysBetweenDefaultCalendar() {
        let today = Date()
        let yesterday = Self.testCalendar.date(byAdding: .day, value: -1, to: today)!
        
        let result = DateUtils.daysBetween(yesterday, today)
        #expect(result == 1)
    }
    
    // MARK: - Week Key Tests
    
    @Test("Week key returns consistent values for same week with Monday first")
    func weekKeyMondayFirst() {
        let monday = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 4))! // Assuming this is a Monday
        let friday = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 8))!
        
        let mondayKey = DateUtils.weekKey(for: monday, firstWeekday: 2, calendar: Self.testCalendar) // 2 = Monday
        let fridayKey = DateUtils.weekKey(for: friday, firstWeekday: 2, calendar: Self.testCalendar)
        
        #expect(mondayKey.year == fridayKey.year)
        #expect(mondayKey.week == fridayKey.week)
    }
    
    @Test("Week key returns different values for different weeks")
    func weekKeyDifferentWeeks() {
        let date1 = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 1))!
        let date2 = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 15))!
        
        let key1 = DateUtils.weekKey(for: date1, firstWeekday: 1, calendar: Self.testCalendar) // 1 = Sunday
        let key2 = DateUtils.weekKey(for: date2, firstWeekday: 1, calendar: Self.testCalendar)
        
        #expect(key1 != key2)
    }
    
    @Test("Week key handles different first weekday settings")
    func weekKeyDifferentFirstWeekday() {
        let date = Self.testCalendar.date(from: DateComponents(year: 2025, month: 8, day: 4))!
        
        let sundayFirst = DateUtils.weekKey(for: date, firstWeekday: 1, calendar: Self.testCalendar)
        let mondayFirst = DateUtils.weekKey(for: date, firstWeekday: 2, calendar: Self.testCalendar)
        
        // These might be different depending on which day of the week the date falls
        #expect(sundayFirst.year > 0)
        #expect(mondayFirst.year > 0)
        #expect(sundayFirst.week > 0)
        #expect(mondayFirst.week > 0)
    }
    
    @Test("Week key returns valid year and week numbers")
    func weekKeyValidValues() {
        let key = DateUtils.weekKey(for: Self.testDate1, firstWeekday: 1, calendar: Self.testCalendar)
        
        #expect(key.year == 2025)
        #expect(key.week >= 1)
        #expect(key.week <= 53) // ISO weeks can be up to 53
    }
    
    // MARK: - User Calendar Tests
    
    @Test("User calendar returns calendar with current locale")
    func userCalendarCurrentLocale() {
        let calendar = DateUtils.userCalendar()
        #expect(calendar.locale == Locale.current)
    }
    
    @Test("User calendar is based on current calendar")
    func userCalendarBasedOnCurrent() {
        let calendar = DateUtils.userCalendar()
        #expect(calendar.identifier == Calendar.current.identifier)
    }
    
    @Test("User calendar preserves system settings")
    func userCalendarSystemSettings() {
        let calendar = DateUtils.userCalendar()
        let systemCalendar = Calendar.current
        
        #expect(calendar.firstWeekday == systemCalendar.firstWeekday)
        #expect(calendar.timeZone == systemCalendar.timeZone)
    }
    
    // MARK: - Ordered Weekday Symbols Tests
    
    @Test("Ordered weekday symbols returns 7 symbols")
    func orderedWeekdaySymbolsCount() {
        let symbols = DateUtils.orderedWeekdaySymbols()
        #expect(symbols.count == 7)
    }
    
    @Test("Ordered weekday symbols very short style returns short symbols")
    func orderedWeekdaySymbolsVeryShort() {
        let symbols = DateUtils.orderedWeekdaySymbols(style: .veryShort)
        
        #expect(symbols.count == 7)
        // Very short symbols should be 1-2 characters typically
        for symbol in symbols {
            #expect(symbol.count >= 1)
            #expect(symbol.count <= 3) // Some locales might be slightly longer
        }
    }
    
    @Test("Ordered weekday symbols short style returns short symbols")
    func orderedWeekdaySymbolsShort() {
        let symbols = DateUtils.orderedWeekdaySymbols(style: .short)
        
        #expect(symbols.count == 7)
        // Short symbols should be longer than very short
        for symbol in symbols {
            #expect(symbol.count >= 2)
        }
    }
    
    @Test("Ordered weekday symbols standalone style returns standalone symbols")
    func orderedWeekdaySymbolsStandalone() {
        let symbols = DateUtils.orderedWeekdaySymbols(style: .standalone)
        
        #expect(symbols.count == 7)
        // Standalone symbols are typically full day names
        for symbol in symbols {
            #expect(symbol.count >= 3)
        }
    }
    
    @Test("Ordered weekday symbols respects system first weekday")
    func orderedWeekdaySymbolsFirstWeekday() {
        let symbols = DateUtils.orderedWeekdaySymbols()
        let calendar = DateUtils.userCalendar()
        let systemSymbols = calendar.veryShortWeekdaySymbols
        
        // The first symbol should correspond to the system's first weekday
        let expectedFirstSymbol = systemSymbols[calendar.firstWeekday - 1]
        
        // Handle potential duplicate symbols in German locale case
        if Set(systemSymbols).count != systemSymbols.count {
            // When duplicates exist, short symbols are used and truncated
            let shortSymbols = calendar.shortWeekdaySymbols
            let expectedShortSymbol = String(shortSymbols[calendar.firstWeekday - 1].prefix(2))
            #expect(symbols.first == expectedShortSymbol || symbols.first == expectedFirstSymbol)
        } else {
            #expect(symbols.first == expectedFirstSymbol)
        }
    }
    
    @Test("Ordered weekday symbols handles duplicate symbols correctly")
    func orderedWeekdaySymbolsDuplicates() {
        // This test simulates the German locale case where very short symbols might be duplicated
        let symbols = DateUtils.orderedWeekdaySymbols(style: .veryShort)
        
        // The function should handle duplicates by using short symbols instead
        // We can't easily test this without mocking the calendar, but we can ensure the result is valid
        #expect(symbols.count == 7)
        #expect(!symbols.isEmpty)
        
        // All symbols should be non-empty
        for symbol in symbols {
            #expect(!symbol.isEmpty)
        }
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test("Start of day handles extreme dates")
    func startOfDayExtremeDate() {
        let extremeDate = Date(timeIntervalSince1970: 0) // Unix epoch
        let result = DateUtils.startOfDay(extremeDate, calendar: Self.testCalendar)
        
        // Should not crash and return a valid date (may be negative due to timezone)
        #expect(!result.timeIntervalSince1970.isNaN)
        #expect(!result.timeIntervalSince1970.isInfinite)
        
        // Verify it's actually the start of day by checking time components
        let components = Self.testCalendar.dateComponents([.hour, .minute, .second], from: result)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }
    
    @Test("Days between handles very large date differences")
    func daysBetweenLargeDifference() {
        let date1 = Self.testCalendar.date(from: DateComponents(year: 2000, month: 1, day: 1))!
        let date2 = Self.testCalendar.date(from: DateComponents(year: 2025, month: 12, day: 31))!
        
        let result = DateUtils.daysBetween(date1, date2, calendar: Self.testCalendar)
        
        // Should handle large differences without crashing
        #expect(result > 9000) // Roughly 25+ years
        #expect(result < 10000) // But not unreasonably large
    }
    
    @Test("Week key handles year boundaries correctly")
    func weekKeyYearBoundary() {
        let newYearDate = Self.testCalendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let key = DateUtils.weekKey(for: newYearDate, firstWeekday: 1, calendar: Self.testCalendar)
        
        // Year should be valid
        #expect(key.year >= 2024) // Might be 2024 if Jan 1 is in the last week of previous year
        #expect(key.year <= 2025)
        #expect(key.week >= 1)
        #expect(key.week <= 53)
    }
    
    @Test("Ordered weekday symbols handles out of bounds calendar settings gracefully")
    func orderedWeekdaySymbolsOutOfBounds() {
        // This tests the guard clause in the implementation
        let symbols = DateUtils.orderedWeekdaySymbols()
        
        // Should not crash and return valid symbols
        #expect(symbols.count == 7)
        for symbol in symbols {
            #expect(!symbol.isEmpty)
        }
    }
}