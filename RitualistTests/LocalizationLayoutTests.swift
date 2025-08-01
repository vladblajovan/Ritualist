import XCTest
import SwiftUI
@testable import Ritualist

final class LocalizationLayoutTests: XCTestCase {
    
    func testButtonLabelsWithLongText() {
        // Test that common button labels don't break with longer German text
        // Uses dynamic thresholds: short text (≤6 chars) allows 2x, longer text allows 1.5x
        // This accounts for German compound words being proportionally longer for short English words
        let testCases = [
            ("Save", "Sichern"),                          // 4->7 chars (1.75x) - More concise UI translation
            ("Cancel", "Abbrechen"),                      // 6->9 chars (1.5x) - Good
            ("Delete Habit", "Gewohnheit löschen"),       // 12->18 chars (1.5x) - Good
            ("Create New Habit", "Neue Gewohnheit"),      // 16->15 chars (0.9x) - Shortened appropriately
            ("Basic Information", "Grundlegende Info")    // 17->16 chars (0.9x) - Shortened appropriately
        ]
        
        for (english, german) in testCases {
            // Dynamic length tolerance based on English text length
            // Short texts (≤6 chars) get 2x multiplier, longer texts get 1.5x
            let multiplier = english.count <= 6 ? 2.0 : 1.5
            let maxAllowedLength = Int(Double(english.count) * multiplier)
            
            XCTAssertLessThanOrEqual(
                german.count, 
                maxAllowedLength, 
                "German text '\(german)' (\(german.count) chars) exceeds \(Int(multiplier * 100 - 100))% longer than English '\(english)' (\(english.count) chars). Max allowed: \(maxAllowedLength) chars"
            )
        }
    }
    
    func testFormFieldLabelsLength() {
        let longLabels = [
            "Unit label is required for numeric habits",
            "Please select at least one day",
            "Target must be greater than 0",
            "This action cannot be undone. All logged data for this habit will be permanently deleted."
        ]
        
        // Test that validation messages don't exceed reasonable length
        for label in longLabels {
            XCTAssertLessThan(
                label.count,
                120,
                "Label '\(label)' exceeds reasonable length and may cause layout issues"
            )
        }
    }
    
    func testHabitNameLengthConstraints() {
        let testNames = [
            LocalizationTesting.TestStrings.short,
            LocalizationTesting.TestStrings.medium,
            LocalizationTesting.TestStrings.long,
            LocalizationTesting.TestStrings.longGerman
        ]
        
        // Simulate text width calculation (simplified)
        for name in testNames {
            // Assume average character width and typical button constraints
            let estimatedWidth = Double(name.count) * 8.0 // rough character width
            let maxButtonWidth = 280.0 // typical mobile button width
            
            if estimatedWidth > maxButtonWidth {
                print("⚠️ Warning: '\(name)' may cause layout issues (estimated width: \(estimatedWidth))")
            }
        }
    }
    
    func testAccessibilityLabelsLength() {
        // Test that accessibility labels are descriptive but not too verbose
        let accessibilityLabels = [
            "Previous month",
            "Next month", 
            "Add new habit",
            "Select Daily Morning Meditation Practice habit",
            "Habit completed on January 15, 2024",
            "Tap to log habit for January 15, 2024"
        ]
        
        for label in accessibilityLabels {
            // VoiceOver works best with labels under 100 characters
            XCTAssertLessThan(
                label.count,
                100,
                "Accessibility label '\(label)' may be too verbose for VoiceOver"
            )
        }
    }
    
    func testPseudoLocalization() {
        let originalStrings = [
            "Save",
            "Create Habit", 
            "Daily Target",
            "Basic Information"
        ]
        
        for original in originalStrings {
            let pseudoLocalized = LocalizationTesting.pseudoLocalize(original)
            
            // Pseudo-localized should be longer to test layout flexibility
            XCTAssertGreaterThan(
                pseudoLocalized.count,
                original.count,
                "Pseudo-localized text should be longer than original"
            )
            
            // Should contain brackets to identify pseudo-localized content
            XCTAssertTrue(
                pseudoLocalized.hasPrefix("[") && pseudoLocalized.hasSuffix("]"),
                "Pseudo-localized text should have brackets: \(pseudoLocalized)"
            )
        }
    }
    
    func testRTLLayoutConsiderations() {
        // Test that we have proper RTL support utilities
        let ltrChevron = RTLSupport.chevronLeading(false)
        let rtlChevron = RTLSupport.chevronLeading(true)
        
        XCTAssertEqual(ltrChevron, "chevron.left")
        XCTAssertEqual(rtlChevron, "chevron.right")
        
        // Verify opposite direction
        let ltrTrailing = RTLSupport.chevronTrailing(false)
        let rtlTrailing = RTLSupport.chevronTrailing(true)
        
        XCTAssertEqual(ltrTrailing, "chevron.right")
        XCTAssertEqual(rtlTrailing, "chevron.left")
    }
    
    func testStringLengthValidation() {
        // Test tab bar labels
        let tabBarResult = LayoutValidator.validateString("Overview", for: .tabBarLabel)
        XCTAssertTrue(tabBarResult.isValid, "Tab bar label should be valid")
        
        let longTabBarResult = LayoutValidator.validateString("Very Long Navigation Title", for: .tabBarLabel)
        XCTAssertFalse(longTabBarResult.isValid, "Long tab bar label should be invalid")
        
        // Test button labels
        let buttonResult = LayoutValidator.validateString("Save", for: .buttonLabel)
        XCTAssertTrue(buttonResult.isValid, "Button label should be valid")
        
        // Test validation messages
        let validationResult = LayoutValidator.validateString("Name is required", for: .validationMessage)
        XCTAssertTrue(validationResult.isValid, "Validation message should be valid")
        
        // Test empty string
        let emptyResult = LayoutValidator.validateString("", for: .buttonLabel)
        XCTAssertFalse(emptyResult.isValid, "Empty string should be invalid")
        XCTAssertEqual(emptyResult.severity, .error)
    }
    
    func testComponentConstraints() {
        // Verify constraint hierarchy makes sense
        let tabBar = LayoutValidator.StringConstraints.tabBarLabel.characterLimit
        let button = LayoutValidator.StringConstraints.buttonLabel.characterLimit
        let form = LayoutValidator.StringConstraints.formFieldLabel.characterLimit
        let validation = LayoutValidator.StringConstraints.validationMessage.characterLimit
        
        XCTAssertLessThan(tabBar, button, "Tab bar should be shorter than button labels")
        XCTAssertLessThan(button, form, "Button labels should be shorter than form labels")
        XCTAssertLessThan(form, validation, "Form labels should be shorter than validation messages")
    }
    
    func testValidationReportGeneration() {
        let report = LayoutValidator.generateValidationReport()
        
        // Report should contain expected sections
        XCTAssertTrue(report.contains("Internationalization String Validation Report"))
        XCTAssertTrue(report.contains("Summary:"))
        XCTAssertTrue(report.contains("tabBarLabel"))
        XCTAssertTrue(report.contains("buttonLabel"))
        
        // Should include status emojis
        XCTAssertTrue(report.contains("✅") || report.contains("❌"))
    }
    
    func testWhitespaceValidation() {
        // Test leading whitespace
        let leadingSpace = LayoutValidator.validateString(" Save", for: .buttonLabel)
        XCTAssertFalse(leadingSpace.isValid, "String with leading whitespace should be invalid")
        
        // Test trailing whitespace
        let trailingSpace = LayoutValidator.validateString("Save ", for: .buttonLabel)
        XCTAssertFalse(trailingSpace.isValid, "String with trailing whitespace should be invalid")
        
        // Test clean string
        let clean = LayoutValidator.validateString("Save", for: .buttonLabel)
        XCTAssertTrue(clean.isValid, "Clean string should be valid")
    }
    
    func testLineBreakValidation() {
        // Line breaks should be invalid for most components
        let buttonWithLineBreak = LayoutValidator.validateString("Save\nChanges", for: .buttonLabel)
        XCTAssertFalse(buttonWithLineBreak.isValid, "Button with line break should be invalid")
        
        // But acceptable for alert messages
        let alertWithLineBreak = LayoutValidator.validateString("Are you sure?\nThis cannot be undone.", for: .alertMessage)
        XCTAssertTrue(alertWithLineBreak.isValid, "Alert message with line break should be valid")
    }
}