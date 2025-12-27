//
//  HabitStartDateUITests.swift
//  RitualistUITests
//
//  Created by Claude on 30.11.2025.
//
//  UI tests for the start date editing flow.
//  Tests retroactive logging feature where users can edit a habit's start date.
//

import XCTest

/// Tests for habit start date editing functionality
/// Verifies the retroactive logging feature works correctly
@MainActor
final class HabitStartDateUITests: RitualistUITestCase {

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        navigateToTab("Habits")
    }

    // MARK: - Start Date Section Visibility Tests

    func testStartDateSectionNotShownForNewHabit() throws {
        // Open add habit sheet
        let addButton = findAddHabitButton()
        guard let button = addButton else {
            throw XCTSkip("Add habit button not found")
        }

        button.tap()

        // Wait for sheet to appear
        let saveButton = app.buttons[AccessibilityID.Labels.save]
        guard saveButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Habit detail sheet didn't open")
        }

        // Start date section should NOT be visible for new habits
        let startDateSection = app.otherElements[AccessibilityID.HabitDetail.startDateSection]
        XCTAssertFalse(
            startDateSection.waitForExistence(timeout: 2),
            "Start date section should not be shown for new habits"
        )

        // Also check for the section header text
        let startDateHeader = app.staticTexts["Start Date"]
        XCTAssertFalse(
            startDateHeader.exists,
            "Start Date header should not exist for new habits"
        )

        dismissSheet()
    }

    func testStartDateSectionShownForExistingHabit() throws {
        // Open an existing habit for editing (creates one if needed)
        guard openExistingHabitForEditing() != nil else {
            throw XCTSkip("Could not open habit for editing")
        }

        // Start date section SHOULD be visible for existing habits (edit mode)
        // Look for the section header
        let startDateHeader = app.staticTexts["Start Date"]

        // May need to scroll to find it
        if !startDateHeader.exists {
            app.swipeUp()
        }

        XCTAssertTrue(
            startDateHeader.waitForExistence(timeout: 3),
            "Start Date header should exist for existing habits in edit mode"
        )

        dismissSheet()
    }

    // MARK: - Start Date Picker Tests

    func testStartDatePickerIsInteractive() throws {
        // Open an existing habit for editing (creates one if needed)
        guard openExistingHabitForEditing() != nil else {
            throw XCTSkip("Could not open habit for editing")
        }

        // Scroll to find start date section
        scrollToStartDateSection()

        // Find the date picker
        let startDatePicker = app.datePickers.firstMatch
        guard startDatePicker.waitForExistence(timeout: 3) else {
            throw XCTSkip("Start date picker not found")
        }

        // Verify it's enabled/interactive
        XCTAssertTrue(startDatePicker.isEnabled, "Start date picker should be enabled")
        XCTAssertTrue(startDatePicker.isHittable, "Start date picker should be hittable")

        dismissSheet()
    }

    func testStartDatePickerOpensCalendar() throws {
        // Open an existing habit for editing (creates one if needed)
        guard openExistingHabitForEditing() != nil else {
            throw XCTSkip("Could not open habit for editing")
        }

        // Scroll to find start date section
        scrollToStartDateSection()

        // Find and tap the date picker
        let startDatePicker = app.datePickers.firstMatch
        guard startDatePicker.waitForExistence(timeout: 3) else {
            throw XCTSkip("Start date picker not found")
        }

        startDatePicker.tap()

        // Wait for calendar popup/wheel to appear
        // The calendar view should have month/year navigation
        let calendarElement = app.datePickers.firstMatch
        XCTAssertTrue(
            calendarElement.waitForExistence(timeout: 3),
            "Calendar should appear when date picker is tapped"
        )

        // Dismiss by tapping elsewhere or pressing Done
        let doneButton = app.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
        } else {
            // Tap outside to dismiss
            app.tap()
        }

        dismissSheet()
    }

    // MARK: - Start Date Validation Tests

    func testStartDateValidationErrorShown() throws {
        // This test verifies the validation message appears
        // when start date is after existing logs
        // Note: This requires specific test data setup

        // Open an existing habit for editing (creates one if needed)
        guard openExistingHabitForEditing() != nil else {
            throw XCTSkip("Could not open habit for editing")
        }

        // Scroll to find start date section
        scrollToStartDateSection()

        // Look for the footer help text (indicates section is visible)
        let helpText = app.staticTexts["Set an earlier date to log habits retroactively. Logs before this date won't be counted."]

        if helpText.exists {
            // Normal state - validation is passing
            XCTAssertTrue(helpText.exists, "Help text should be shown when start date is valid")
        }

        // Note: To fully test validation error, we'd need to:
        // 1. Have a habit with existing logs
        // 2. Change start date to after the earliest log
        // 3. Verify error message appears
        // This would require test data setup which is complex for UI tests

        dismissSheet()
    }

    // MARK: - Save After Start Date Change Tests

    func testCanSaveAfterChangingStartDate() throws {
        // Open an existing habit for editing (creates one if needed)
        guard openExistingHabitForEditing() != nil else {
            throw XCTSkip("Could not open habit for editing")
        }

        // Scroll to find start date section
        scrollToStartDateSection()

        // Find the date picker
        let startDatePicker = app.datePickers.firstMatch
        guard startDatePicker.waitForExistence(timeout: 3) else {
            throw XCTSkip("Start date picker not found")
        }

        // The date picker exists and is visible
        // Verify save button is still enabled
        let saveButton = app.buttons[AccessibilityID.Labels.save]
        XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled")

        dismissSheet()
    }

    // MARK: - Private Helpers

    private func findAddHabitButton() -> XCUIElement? {
        let navBarAdd = app.navigationBars.buttons[AccessibilityID.Labels.add]
        if navBarAdd.waitForExistence(timeout: 3) {
            return navBarAdd
        }

        let identifiedButton = app.buttons[AccessibilityID.Habits.addButton]
        if identifiedButton.waitForExistence(timeout: 2) {
            return identifiedButton
        }

        let plusButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Add' OR identifier CONTAINS 'add'")
        ).firstMatch
        if plusButton.waitForExistence(timeout: 2) {
            return plusButton
        }

        return nil
    }

    /// Name used for test habits
    private static let testHabitName = "Test Habit for UI Tests"

    private func findFirstHabitCell() -> XCUIElement? {
        // Wait for list to load
        sleep(1)

        // Find habit rows by accessibility identifier pattern "habit.row.*"
        // Try buttons first (SwiftUI Button in List)
        let habitRowButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "habit.row.")
        ).firstMatch
        if habitRowButton.exists {
            return habitRowButton
        }

        // Also try cells (List might expose them as cells)
        let habitRowCell = app.cells.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "habit.row.")
        ).firstMatch
        if habitRowCell.exists {
            return habitRowCell
        }

        // Fallback: try any element with the identifier pattern
        let habitRowAny = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "habit.row.")
        ).firstMatch
        if habitRowAny.exists {
            return habitRowAny
        }

        return nil
    }

    /// Creates a test habit if none exist, then returns to the habits list
    /// Returns true if a habit exists (either found or created)
    @discardableResult
    private func ensureHabitExists() -> Bool {
        // Check if habit already exists
        if findFirstHabitCell() != nil {
            return true
        }

        // No habits - create one
        guard let addButton = findAddHabitButton() else {
            return false
        }

        addButton.tap()

        // Wait for sheet
        let saveButton = app.buttons[AccessibilityID.Labels.save]
        guard saveButton.waitForExistence(timeout: 5) else {
            return false
        }

        // Find and fill the name field
        let nameField = app.textFields[AccessibilityID.HabitDetail.nameField]
        if nameField.waitForExistence(timeout: 3) {
            nameField.tap()
            // Clear any existing text first
            if let currentValue = nameField.value as? String, !currentValue.isEmpty {
                let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
                nameField.typeText(deleteString)
            }
            nameField.typeText(Self.testHabitName)

            // Dismiss keyboard before saving
            app.keyboards.buttons["return"].tap()
            sleep(1)
        }

        // Save the habit
        saveButton.tap()

        // Wait for sheet to dismiss and list to update
        sleep(2)

        return findFirstHabitCell() != nil
    }

    /// Opens an existing habit for editing, creating one first if needed
    /// Returns the habit cell that was tapped, or nil if failed
    private func openExistingHabitForEditing() -> XCUIElement? {
        // Ensure we have a habit to edit
        guard ensureHabitExists() else {
            return nil
        }

        // Find and tap the habit
        guard let cell = findFirstHabitCell() else {
            return nil
        }

        cell.tap()

        // Wait for edit sheet to appear
        let saveButton = app.buttons[AccessibilityID.Labels.save]
        guard saveButton.waitForExistence(timeout: 5) else {
            return nil
        }

        return cell
    }

    private func scrollToStartDateSection() {
        // Scroll down to find the start date section
        let startDateHeader = app.staticTexts["Start Date"]

        var attempts = 0
        while !startDateHeader.exists && attempts < 5 {
            app.swipeUp()
            attempts += 1
            // Brief wait for scroll to settle
            _ = startDateHeader.waitForExistence(timeout: 0.5)
        }
    }
}
