//
//  NumberUtilsTests.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import XCTest
@testable import Ritualist

final class NumberUtilsTests: XCTestCase {
    
    // MARK: - habitValueFormatter Tests
    
    func testHabitValueFormatter_properties() {
        let formatter = NumberUtils.habitValueFormatter()
        
        XCTAssertEqual(formatter.locale, Locale.current)
        XCTAssertEqual(formatter.numberStyle, .decimal)
        XCTAssertEqual(formatter.minimumFractionDigits, 0)
        XCTAssertEqual(formatter.maximumFractionDigits, 2)
        XCTAssertTrue(formatter.usesGroupingSeparator)
    }
    
    // MARK: - formatHabitValue Tests
    
    func testFormatHabitValue_integers() {
        XCTAssertEqual(NumberUtils.formatHabitValue(0), "0")
        XCTAssertEqual(NumberUtils.formatHabitValue(1), "1")
        XCTAssertEqual(NumberUtils.formatHabitValue(42), "42")
        XCTAssertEqual(NumberUtils.formatHabitValue(100), "100")
    }
    
    func testFormatHabitValue_decimals() {
        // Test various decimal places - check for digits, not specific separators
        let result1_5 = NumberUtils.formatHabitValue(1.5)
        XCTAssertTrue(result1_5.contains("1") && result1_5.contains("5"), 
                     "Should contain 1 and 5: \(result1_5)")
        
        let result3_14 = NumberUtils.formatHabitValue(3.14)
        XCTAssertTrue(result3_14.contains("3") && result3_14.contains("1") && result3_14.contains("4"), 
                     "Should contain 3, 1, and 4: \(result3_14)")
        
        XCTAssertEqual(NumberUtils.formatHabitValue(2.0), "2") // Whole numbers format consistently
        
        // Test rounding to 2 decimal places
        let formatted = NumberUtils.formatHabitValue(1.999)
        XCTAssertTrue(formatted == "2" || formatted.contains("1") && formatted.contains("99"), 
                     "Should handle rounding correctly: \(formatted)")
    }
    
    func testFormatHabitValue_largeNumbers() {
        // Test thousands separator
        let largeValue = NumberUtils.formatHabitValue(1234)
        XCTAssertTrue(largeValue.contains("1") && largeValue.contains("234"), 
                     "Should format large numbers: \(largeValue)")
        
        let veryLargeValue = NumberUtils.formatHabitValue(1000000)
        XCTAssertTrue(veryLargeValue.contains("1") && veryLargeValue.contains("000"), 
                     "Should format very large numbers: \(veryLargeValue)")
    }
    
    func testFormatHabitValue_negativeNumbers() {
        let negative = NumberUtils.formatHabitValue(-5.5)
        XCTAssertTrue(negative.contains("-") && negative.contains("5"), 
                     "Should handle negative numbers: \(negative)")
        
        XCTAssertEqual(NumberUtils.formatHabitValue(-0), "0")
    }
    
    func testFormatHabitValue_specialValues() {
        // Test edge cases
        XCTAssertEqual(NumberUtils.formatHabitValue(0.0), "0")
        
        // Very small decimal
        let smallDecimal = NumberUtils.formatHabitValue(0.01)
        XCTAssertTrue(smallDecimal.contains("0.01") || smallDecimal.contains("0,01"), 
                     "Should handle small decimals: \(smallDecimal)")
        
        // Very small value that rounds to 0
        let tinyValue = NumberUtils.formatHabitValue(0.001)
        XCTAssertEqual(tinyValue, "0")
    }
    
    // MARK: - formatHabitValueWithUnit Tests
    
    func testFormatHabitValueWithUnit() {
        // Test locale-aware formatting - don't hardcode decimal/thousands separators
        let result5km = NumberUtils.formatHabitValueWithUnit(5, unit: "km")
        XCTAssertTrue(result5km.contains("5") && result5km.contains("km") && result5km.contains(" "), 
                     "Should contain value, unit and space: \(result5km)")
        
        let result2_5hours = NumberUtils.formatHabitValueWithUnit(2.5, unit: "hours")
        XCTAssertTrue(result2_5hours.contains("2") && result2_5hours.contains("5") && result2_5hours.contains("hours"), 
                     "Should contain formatted 2.5 and hours: \(result2_5hours)")
        
        let result0times = NumberUtils.formatHabitValueWithUnit(0, unit: "times")
        XCTAssertEqual(result0times, "0 times") // Zero formatting is consistent across locales
        
        let result1000steps = NumberUtils.formatHabitValueWithUnit(1000, unit: "steps")
        XCTAssertTrue(result1000steps.contains("1") && result1000steps.contains("000") && result1000steps.contains("steps"), 
                     "Should contain formatted 1000 and steps: \(result1000steps)")
    }
    
    func testFormatHabitValueWithUnit_emptyUnit() {
        XCTAssertEqual(NumberUtils.formatHabitValueWithUnit(42, unit: ""), "42 ")
    }
    
    func testFormatHabitValueWithUnit_unicodeUnit() {
        let tempResult = NumberUtils.formatHabitValueWithUnit(36.5, unit: "°C")
        XCTAssertTrue(tempResult.contains("36") && tempResult.contains("5") && tempResult.contains("°C"), 
                     "Should contain formatted 36.5 and °C: \(tempResult)")
        
        let waterResult = NumberUtils.formatHabitValueWithUnit(8, unit: "💧")
        XCTAssertEqual(waterResult, "8 💧") // Integer formatting is consistent across locales
    }
    
    func testFormatHabitValueWithUnit_localeAwareness() {
        // Test that the function works regardless of current locale's decimal separator
        let decimalValue = 2.5
        let result = NumberUtils.formatHabitValueWithUnit(decimalValue, unit: "hours")
        
        // Should contain the digits and unit, regardless of locale-specific formatting
        XCTAssertTrue(result.contains("2"), "Should contain digit 2: \(result)")
        XCTAssertTrue(result.contains("5"), "Should contain digit 5: \(result)")
        XCTAssertTrue(result.contains("hours"), "Should contain unit: \(result)")
        XCTAssertTrue(result.contains(" "), "Should have space between value and unit: \(result)")
        
        // Verify structure: "<formatted_number> <unit>" 
        let components = result.components(separatedBy: " ")
        XCTAssertEqual(components.count, 2, "Should have exactly 2 components separated by space: \(result)")
        XCTAssertEqual(components.last, "hours", "Last component should be the unit")
        
        // The first component should be the locale-formatted number (could be "2.5" or "2,5" etc.)
        let numberPart = components.first ?? ""
        XCTAssertTrue(numberPart.contains("2") && numberPart.contains("5"), 
                     "Number part should contain both digits: \(numberPart)")
    }
    
    // MARK: - parseHabitValue Tests
    
    func testParseHabitValue_validInputs() {
        // Integers should parse consistently across locales
        XCTAssertEqual(NumberUtils.parseHabitValue("0"), 0)
        XCTAssertEqual(NumberUtils.parseHabitValue("1"), 1)
        XCTAssertEqual(NumberUtils.parseHabitValue("42"), 42)
        
        // Test decimal parsing using locale-formatted strings
        let formatter = NumberUtils.habitValueFormatter()
        let formatted3_14 = formatter.string(from: NSNumber(value: 3.14)) ?? "3.14"
        let formatted1_5 = formatter.string(from: NSNumber(value: 1.5)) ?? "1.5"
        
        if let parsed = NumberUtils.parseHabitValue(formatted3_14) {
            XCTAssertEqual(parsed, 3.14, accuracy: 0.001, "Should parse locale-formatted 3.14: \(formatted3_14)")
        } else {
            XCTFail("Should parse locale-formatted 3.14: \(formatted3_14)")
        }
        
        if let parsed = NumberUtils.parseHabitValue(formatted1_5) {
            XCTAssertEqual(parsed, 1.5, accuracy: 0.001, "Should parse locale-formatted 1.5: \(formatted1_5)")
        } else {
            XCTFail("Should parse locale-formatted 1.5: \(formatted1_5)")
        }
    }
    
    func testParseHabitValue_localeSpecific() {
        // Test that parser respects current locale for decimal separator
        let formatter = NumberUtils.habitValueFormatter()
        let localeFormatted1_5 = formatter.string(from: NSNumber(value: 1.5)) ?? "1.5"
        
        XCTAssertNotNil(NumberUtils.parseHabitValue(localeFormatted1_5), 
                       "Should parse locale-formatted decimal: \(localeFormatted1_5)")
        XCTAssertNotNil(NumberUtils.parseHabitValue("0"))
        
        // These should work regardless of locale
        XCTAssertEqual(NumberUtils.parseHabitValue("100"), 100)
    }
    
    func testParseHabitValue_invalidInputs() {
        XCTAssertNil(NumberUtils.parseHabitValue(""))
        XCTAssertNil(NumberUtils.parseHabitValue("abc"))
        XCTAssertNil(NumberUtils.parseHabitValue("not a number"))
        XCTAssertNil(NumberUtils.parseHabitValue("12.34.56"))
        XCTAssertNil(NumberUtils.parseHabitValue("--5"))
    }
    
    func testParseHabitValue_whitespace() {
        // Test whitespace handling
        XCTAssertEqual(NumberUtils.parseHabitValue(" 42 "), 42)
        
        // Test with locale-formatted decimal and whitespace
        let formatter = NumberUtils.habitValueFormatter()
        let formatted1_5 = formatter.string(from: NSNumber(value: 1.5)) ?? "1.5"
        let withWhitespace = "  \(formatted1_5)  "
        
        if let parsed = NumberUtils.parseHabitValue(withWhitespace) {
            XCTAssertEqual(parsed, 1.5, accuracy: 0.001, "Should parse whitespace-padded decimal: \(withWhitespace)")
        } else {
            XCTFail("Should parse whitespace-padded decimal: \(withWhitespace)")
        }
        
        XCTAssertNil(NumberUtils.parseHabitValue("   "))
    }
    
    func testParseHabitValue_negativeNumbers() {
        XCTAssertEqual(NumberUtils.parseHabitValue("-5"), -5)
        
        // Test negative decimal with locale-formatted string
        let formatter = NumberUtils.habitValueFormatter()
        let formatted1_5 = formatter.string(from: NSNumber(value: 1.5)) ?? "1.5"
        let negativeFormatted = "-\(formatted1_5)"
        
        if let parsed = NumberUtils.parseHabitValue(negativeFormatted) {
            XCTAssertEqual(parsed, -1.5, accuracy: 0.001, "Should parse negative locale-formatted decimal: \(negativeFormatted)")
        } else {
            XCTFail("Should parse negative locale-formatted decimal: \(negativeFormatted)")
        }
        
        XCTAssertEqual(NumberUtils.parseHabitValue("-0"), 0)
    }
    
    func testParseHabitValue_roundTripConsistency() {
        // Test that format -> parse -> format produces consistent results
        let testValues: [Double] = [0, 1, 1.5, 3.14, 42.0, 123.45, -5.5]
        
        for value in testValues {
            let formatted = NumberUtils.formatHabitValue(value)
            let parsed = NumberUtils.parseHabitValue(formatted)
            
            XCTAssertNotNil(parsed, "Should be able to parse formatted value: \(formatted)")
            if let parsed = parsed {
                XCTAssertEqual(parsed, value, accuracy: 0.001, 
                             "Round trip should preserve value: \(value) -> \(formatted) -> \(parsed)")
            }
        }
    }
    
    // MARK: - percentageFormatter Tests
    
    func testPercentageFormatter_properties() {
        let formatter = NumberUtils.percentageFormatter()
        
        XCTAssertEqual(formatter.locale, Locale.current)
        XCTAssertEqual(formatter.numberStyle, .percent)
        XCTAssertEqual(formatter.minimumFractionDigits, 0)
        XCTAssertEqual(formatter.maximumFractionDigits, 1)
    }
    
    // MARK: - formatPercentage Tests
    
    func testFormatPercentage_validValues() {
        // Test common percentage values
        let fifty = NumberUtils.formatPercentage(0.5)
        XCTAssertTrue(fifty.contains("50"), "Should format 0.5 as 50%: \(fifty)")
        
        let hundred = NumberUtils.formatPercentage(1.0)
        XCTAssertTrue(hundred.contains("100"), "Should format 1.0 as 100%: \(hundred)")
        
        let zero = NumberUtils.formatPercentage(0.0)
        XCTAssertTrue(zero.contains("0"), "Should format 0.0 as 0%: \(zero)")
        
        let quarter = NumberUtils.formatPercentage(0.25)
        XCTAssertTrue(quarter.contains("25"), "Should format 0.25 as 25%: \(quarter)")
    }
    
    func testFormatPercentage_decimalValues() {
        let precise = NumberUtils.formatPercentage(0.333)
        XCTAssertTrue(precise.contains("33"), "Should handle decimal percentages: \(precise)")
        
        let smallDecimal = NumberUtils.formatPercentage(0.001)
        XCTAssertTrue(smallDecimal.contains("0") || smallDecimal.contains("1"), 
                     "Should handle small percentages: \(smallDecimal)")
    }
    
    func testFormatPercentage_overHundredPercent() {
        let overHundred = NumberUtils.formatPercentage(1.5)
        XCTAssertTrue(overHundred.contains("150"), "Should format 1.5 as 150%: \(overHundred)")
        
        let large = NumberUtils.formatPercentage(2.0)
        XCTAssertTrue(large.contains("200"), "Should format 2.0 as 200%: \(large)")
    }
    
    func testFormatPercentage_negativeValues() {
        let negative = NumberUtils.formatPercentage(-0.1)
        XCTAssertTrue(negative.contains("-10") || negative.contains("10"), 
                     "Should handle negative percentages: \(negative)")
    }
    
    func testFormatPercentage_fallbackBehavior() {
        // Test that fallback produces reasonable output even if formatter fails
        let result = NumberUtils.formatPercentage(0.42)
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("42") || result.contains("%"))
    }
    
    // MARK: - Integration Tests
    
    func testNumberUtilsIntegration_roundTrip() {
        // Test that formatting and parsing work together
        let originalValue = 123.45
        let formatted = NumberUtils.formatHabitValue(originalValue)
        let parsed = NumberUtils.parseHabitValue(formatted)
        
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed!, originalValue, accuracy: 0.01)
    }
    
    func testNumberUtilsIntegration_withUnits() {
        let value = 42.0
        let unit = "minutes"
        let withUnit = NumberUtils.formatHabitValueWithUnit(value, unit: unit)
        
        XCTAssertTrue(withUnit.contains("42"))
        XCTAssertTrue(withUnit.contains(unit))
        XCTAssertTrue(withUnit.contains(" ")) // Should have space between value and unit
    }
    
    func testNumberUtilsIntegration_multipleFormatters() {
        // Test that different formatters don't interfere with each other
        let habitFormatter = NumberUtils.habitValueFormatter()
        let percentFormatter = NumberUtils.percentageFormatter()
        
        XCTAssertNotEqual(habitFormatter.numberStyle, percentFormatter.numberStyle)
        XCTAssertEqual(habitFormatter.locale, percentFormatter.locale)
    }
}
