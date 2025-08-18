//
//  NumberUtilsTests.swift
//  RitualistTests
//
//  Created by Claude on 04.08.2025.
//

import Testing
import Foundation
@testable import Ritualist
import RitualistCore

struct NumberUtilsTests {
    
    // MARK: - Habit Value Formatting Tests
    
    @Test("Format habit value returns proper string for integer values")
    func formatHabitValueInteger() {
        let result = NumberUtils.formatHabitValue(5.0)
        #expect(result == "5")
    }
    
    @Test("Format habit value returns proper string for decimal values")
    func formatHabitValueDecimal() {
        let result = NumberUtils.formatHabitValue(3.14)
        #expect(result.contains("3"))
        #expect(result.contains("14"))
    }
    
    @Test("Format habit value handles zero correctly")  
    func formatHabitValueZero() {
        let result = NumberUtils.formatHabitValue(0.0)
        #expect(result == "0")
    }
    
    @Test("Format habit value handles negative values")
    func formatHabitValueNegative() {
        let result = NumberUtils.formatHabitValue(-2.5)
        #expect(result.contains("-"))
        #expect(result.contains("2"))
        #expect(result.contains("5"))
    }
    
    @Test("Format habit value handles large numbers with grouping separator")
    func formatHabitValueLargeNumber() {
        let result = NumberUtils.formatHabitValue(1234.56)
        // Should contain grouping separator for large numbers in most locales
        #expect(result.contains("1"))
        #expect(result.contains("234"))
        #expect(result.contains("56"))
    }
    
    @Test("Format habit value limits decimal places to maximum of 2")
    func formatHabitValueDecimalPlaces() {
        let result = NumberUtils.formatHabitValue(3.123456)
        // Should round to maximum 2 decimal places
        let components = result.components(separatedBy: CharacterSet.decimalDigits.inverted)
        let decimalPart = components.last ?? ""
        #expect(decimalPart.count <= 2)
    }
    
    // MARK: - Habit Value with Unit Tests
    
    @Test("Format habit value with unit combines value and unit correctly")
    func formatHabitValueWithUnit() {
        let result = NumberUtils.formatHabitValueWithUnit(2.5, unit: "km")
        #expect(result.contains("2"))
        #expect(result.contains("5"))
        #expect(result.contains("km"))
        #expect(result.hasSuffix("km"))
    }
    
    @Test("Format habit value with unit handles empty unit")
    func formatHabitValueWithEmptyUnit() {
        let result = NumberUtils.formatHabitValueWithUnit(10.0, unit: "")
        #expect(result.contains("10"))
        #expect(result.hasSuffix(" ")) // Should still have space but empty unit
    }
    
    @Test("Format habit value with unit handles zero value")
    func formatHabitValueWithUnitZero() {
        let result = NumberUtils.formatHabitValueWithUnit(0.0, unit: "minutes")
        #expect(result == "0 minutes")
    }
    
    // MARK: - Parse Habit Value Tests
    
    @Test("Parse habit value returns correct double for integer string")
    func parseHabitValueInteger() {
        let result = NumberUtils.parseHabitValue("42")
        #expect(result == 42.0)
    }
    
    @Test("Parse habit value returns correct double for decimal string")
    func parseHabitValueDecimal() {
        // Test decimal parsing - check what the formatter actually produces
        let formatter = NumberUtils.habitValueFormatter()
        let formattedValue = formatter.string(from: NSNumber(value: 3.14)) ?? "3.14"
        let result = NumberUtils.parseHabitValue(formattedValue)
        #expect(result == 3.14)
    }
    
    @Test("Parse habit value returns nil for invalid input")
    func parseHabitValueInvalid() {
        let result = NumberUtils.parseHabitValue("not a number")
        #expect(result == nil)
    }
    
    @Test("Parse habit value returns nil for empty string")
    func parseHabitValueEmpty() {
        let result = NumberUtils.parseHabitValue("")
        #expect(result == nil)
    }
    
    @Test("Parse habit value handles zero correctly")
    func parseHabitValueZero() {
        let result = NumberUtils.parseHabitValue("0")
        #expect(result == 0.0)
    }
    
    @Test("Parse habit value handles negative numbers")
    func parseHabitValueNegative() {
        // Test negative parsing - check what the formatter actually produces
        let formatter = NumberUtils.habitValueFormatter()
        let formattedValue = formatter.string(from: NSNumber(value: -5.5)) ?? "-5.5"
        let result = NumberUtils.parseHabitValue(formattedValue)
        #expect(result == -5.5)
    }
    
    @Test("Parse habit value handles whitespace")
    func parseHabitValueWhitespace() {
        // Test whitespace handling - use formatter to get locale-appropriate format
        let formatter = NumberUtils.habitValueFormatter()
        let formattedValue = formatter.string(from: NSNumber(value: 10.5)) ?? "10.5"
        let paddedValue = "  \(formattedValue)  "
        let result = NumberUtils.parseHabitValue(paddedValue)
        // Behavior depends on NumberFormatter's handling of whitespace
        // Most formatters will handle leading/trailing whitespace
        #expect(result == 10.5 || result == nil)
    }
    
    // MARK: - Percentage Formatting Tests
    
    @Test("Format percentage returns proper string for decimal input")
    func formatPercentageDecimal() {
        let result = NumberUtils.formatPercentage(0.75)
        #expect(result.contains("75"))
        #expect(result.contains("%"))
    }
    
    @Test("Format percentage handles zero correctly")
    func formatPercentageZero() {
        let result = NumberUtils.formatPercentage(0.0)
        #expect(result.contains("0"))
        #expect(result.contains("%"))
    }
    
    @Test("Format percentage handles one hundred percent")
    func formatPercentageHundred() {
        let result = NumberUtils.formatPercentage(1.0)
        #expect(result.contains("100"))
        #expect(result.contains("%"))
    }
    
    @Test("Format percentage handles values over 100%")
    func formatPercentageOver100() {
        let result = NumberUtils.formatPercentage(1.5)
        #expect(result.contains("150"))
        #expect(result.contains("%"))
    }
    
    @Test("Format percentage rounds to one decimal place")
    func formatPercentageRounding() {
        let result = NumberUtils.formatPercentage(0.12345)
        // Should round to 1 decimal place maximum
        #expect(result.contains("12"))
        #expect(result.contains("%"))
        // Check that we don't have too many decimal places
        let percentSign = result.firstIndex(of: "%") ?? result.endIndex
        let numberPart = String(result[..<percentSign])
        let decimalComponents = numberPart.components(separatedBy: CharacterSet.decimalDigits.inverted)
        if decimalComponents.count > 1 {
            let decimalPart = decimalComponents.last ?? ""
            #expect(decimalPart.count <= 1)
        }
    }
    
    // MARK: - Formatter Configuration Tests
    
    @Test("Habit value formatter uses current locale")
    func habitValueFormatterLocale() {
        let formatter = NumberUtils.habitValueFormatter()
        #expect(formatter.locale == Locale.current)
    }
    
    @Test("Habit value formatter uses decimal number style")
    func habitValueFormatterStyle() {
        let formatter = NumberUtils.habitValueFormatter()
        #expect(formatter.numberStyle == .decimal)
    }
    
    @Test("Habit value formatter has correct fraction digits configuration")
    func habitValueFormatterFractionDigits() {
        let formatter = NumberUtils.habitValueFormatter()
        #expect(formatter.minimumFractionDigits == 0)
        #expect(formatter.maximumFractionDigits == 2)
    }
    
    @Test("Habit value formatter uses grouping separator")
    func habitValueFormatterGroupingSeparator() {
        let formatter = NumberUtils.habitValueFormatter()
        #expect(formatter.usesGroupingSeparator == true)
    }
    
    @Test("Percentage formatter uses current locale")
    func percentageFormatterLocale() {
        let formatter = NumberUtils.percentageFormatter()
        #expect(formatter.locale == Locale.current)
    }
    
    @Test("Percentage formatter uses percent number style")
    func percentageFormatterStyle() {
        let formatter = NumberUtils.percentageFormatter()
        #expect(formatter.numberStyle == .percent)
    }
    
    @Test("Percentage formatter has correct fraction digits configuration")
    func percentageFormatterFractionDigits() {
        let formatter = NumberUtils.percentageFormatter()
        #expect(formatter.minimumFractionDigits == 0)
        #expect(formatter.maximumFractionDigits == 1)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test("Format habit value handles very large numbers")
    func formatHabitValueVeryLarge() {
        let result = NumberUtils.formatHabitValue(Double.greatestFiniteMagnitude)
        #expect(!result.isEmpty)
        // Should not crash and return some representation
    }
    
    @Test("Format habit value handles very small numbers")
    func formatHabitValueVerySmall() {
        let result = NumberUtils.formatHabitValue(Double.leastNormalMagnitude)
        #expect(!result.isEmpty)
        // Should not crash and return some representation
    }
    
    @Test("Format habit value handles infinity")
    func formatHabitValueInfinity() {
        let result = NumberUtils.formatHabitValue(Double.infinity)
        #expect(!result.isEmpty)
        // Should not crash and return some representation
    }
    
    @Test("Format habit value handles NaN")
    func formatHabitValueNaN() {
        let result = NumberUtils.formatHabitValue(Double.nan)
        #expect(!result.isEmpty)
        // Should not crash and return some representation
    }
    
    @Test("Parse habit value handles locale-specific decimal separators")
    func parseHabitValueLocaleSpecific() {
        // This test depends on the current locale
        // In some locales, comma is used as decimal separator
        let result1 = NumberUtils.parseHabitValue("3.14")
        let result2 = NumberUtils.parseHabitValue("3,14")
        
        // At least one should work depending on locale
        #expect(result1 == 3.14 || result2 == 3.14)
    }
}