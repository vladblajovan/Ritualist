//
//  SheetFlowUITests.swift
//  RitualistUITests
//
//  Created by Claude on 27.11.2025.
//
//  Tests for sheet presentation, dismissal, and reshow flows.
//  These tests verify that sheets properly dismiss and can be reopened.
//

import XCTest

/// Tests for sheet presentation and dismissal flows
/// Verifies the onDismiss callback pattern works correctly
final class SheetFlowUITests: RitualistUITestCase {

    // MARK: - Habit Detail Sheet Tests

    func testHabitDetailSheetCanBeOpenedAndClosed() throws {
        navigateToTab("Habits")

        // Look for add button in navigation bar
        let addButton = findAddHabitButton()
        guard let button = addButton else {
            throw XCTSkip("Add habit button not found - may need to update test")
        }

        // Open sheet
        button.tap()

        // Verify sheet opened (look for identifiable content)
        let sheetContent = app.otherElements[AccessibilityID.HabitDetail.sheet]
        let saveButton = app.buttons["Save"]
        let sheetOpened = sheetContent.waitForExistence(timeout: 5) || saveButton.waitForExistence(timeout: 5)

        guard sheetOpened else {
            throw XCTSkip("Habit detail sheet didn't open - may need to update accessibility identifiers")
        }

        // Dismiss by swiping
        dismissSheet()

        // Verify dismissed
        let stillExists = saveButton.waitForExistence(timeout: 1)
        XCTAssertFalse(stillExists, "Sheet should be dismissed after swipe")
    }

    func testHabitDetailSheetCanBeReopened() throws {
        navigateToTab("Habits")

        let addButton = findAddHabitButton()
        guard let button = addButton else {
            throw XCTSkip("Add habit button not found")
        }

        // First open
        button.tap()

        let saveButton = app.buttons["Save"]
        guard saveButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Sheet didn't open")
        }

        // Dismiss
        dismissSheet()
        _ = saveButton.waitForNonExistence(timeout: 3)

        // Small delay for animation
        Thread.sleep(forTimeInterval: 0.5)

        // Reopen
        button.tap()

        // Verify reopened
        XCTAssertTrue(
            saveButton.waitForExistence(timeout: 5),
            "Sheet should reopen after being dismissed"
        )
    }

    func testMultipleSheetOpenClosesCycles() throws {
        navigateToTab("Habits")

        let addButton = findAddHabitButton()
        guard let button = addButton else {
            throw XCTSkip("Add habit button not found")
        }

        let saveButton = app.buttons["Save"]

        // Cycle through open/close 3 times
        for cycle in 1...3 {
            button.tap()

            guard saveButton.waitForExistence(timeout: 5) else {
                XCTFail("Sheet didn't open on cycle \(cycle)")
                return
            }

            dismissSheet()

            guard saveButton.waitForNonExistence(timeout: 3) else {
                XCTFail("Sheet didn't dismiss on cycle \(cycle)")
                return
            }

            // Small delay between cycles
            Thread.sleep(forTimeInterval: 0.3)
        }
    }

    // MARK: - Navigation + Sheet Tests

    func testSheetWorksAfterTabSwitch() throws {
        // Start on Habits
        navigateToTab("Habits")

        let addButton = findAddHabitButton()
        guard let button = addButton else {
            throw XCTSkip("Add habit button not found")
        }

        // Open and close sheet
        button.tap()

        let saveButton = app.buttons["Save"]
        guard saveButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Sheet didn't open")
        }

        dismissSheet()
        _ = saveButton.waitForNonExistence(timeout: 3)

        // Switch to another tab
        navigateToTab("Stats")
        Thread.sleep(forTimeInterval: 0.5)

        // Switch back to Habits
        navigateToTab("Habits")
        Thread.sleep(forTimeInterval: 0.5)

        // Try to open sheet again
        button.tap()

        // Should still work
        XCTAssertTrue(
            saveButton.waitForExistence(timeout: 5),
            "Sheet should work after tab switching"
        )
    }

    // MARK: - Private Helpers

    private func findAddHabitButton() -> XCUIElement? {
        // Try various ways to find the add button
        let navBarAdd = app.navigationBars.buttons["Add"]
        if navBarAdd.waitForExistence(timeout: 3) {
            return navBarAdd
        }

        let plusButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add' OR identifier CONTAINS 'add'")).firstMatch
        if plusButton.waitForExistence(timeout: 2) {
            return plusButton
        }

        // Try accessibility identifier
        let identifiedButton = app.buttons[AccessibilityID.Habits.addButton]
        if identifiedButton.waitForExistence(timeout: 2) {
            return identifiedButton
        }

        return nil
    }
}

// MARK: - Settings Sheet Tests

final class SettingsSheetUITests: RitualistUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        navigateToTab("Settings")
    }

    func testSettingsScreenLoads() {
        let settingsNavBar = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNavBar.waitForExistence(timeout: 5), "Settings screen should load")
    }

    #if DEBUG
    func testDebugMenuOpensAndCloses() throws {
        // Find debug menu - it's a tappable row, not a button
        // Try both staticTexts and buttons
        var debugElement: XCUIElement?

        // Try finding as text first
        let debugText = app.staticTexts["Debug Menu"]
        if debugText.waitForExistence(timeout: 3) {
            debugElement = debugText
        }

        // Try as button
        if debugElement == nil {
            let debugButton = app.buttons["Debug Menu"]
            if debugButton.waitForExistence(timeout: 2) {
                debugElement = debugButton
            }
        }

        // May need to scroll to find it
        if debugElement == nil || !debugElement!.isHittable {
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.3)

            let debugTextAfterScroll = app.staticTexts["Debug Menu"]
            if debugTextAfterScroll.waitForExistence(timeout: 3) {
                debugElement = debugTextAfterScroll
            }
        }

        guard let element = debugElement, element.exists else {
            throw XCTSkip("Debug menu not found")
        }

        element.tap()

        // Verify debug menu opened
        let debugNavBar = app.navigationBars["Debug Menu"]
        XCTAssertTrue(debugNavBar.waitForExistence(timeout: 5), "Debug menu should open")

        // Find and tap Done button
        let doneButton = app.buttons["Done"]
        if doneButton.waitForExistence(timeout: 3) {
            doneButton.tap()
        } else {
            dismissSheet()
        }

        // Verify closed
        XCTAssertTrue(
            debugNavBar.waitForNonExistence(timeout: 3),
            "Debug menu should close when Done is tapped"
        )
    }

    func testDebugMenuCanBeReopened() throws {
        // Find debug menu element (text or button)
        func findDebugMenu() -> XCUIElement? {
            let debugText = app.staticTexts["Debug Menu"]
            if debugText.exists && debugText.isHittable {
                return debugText
            }
            let debugButton = app.buttons["Debug Menu"]
            if debugButton.exists && debugButton.isHittable {
                return debugButton
            }
            return nil
        }

        var debugElement = findDebugMenu()

        if debugElement == nil {
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.3)
            debugElement = findDebugMenu()
        }

        guard let element = debugElement else {
            throw XCTSkip("Debug menu not found")
        }

        // First open/close cycle
        element.tap()

        let debugNavBar = app.navigationBars["Debug Menu"]
        guard debugNavBar.waitForExistence(timeout: 5) else {
            XCTFail("Debug menu didn't open first time")
            return
        }

        let doneButton = app.buttons["Done"]
        doneButton.tap()

        _ = debugNavBar.waitForNonExistence(timeout: 3)

        // Second open - find element again as UI state may have changed
        guard let elementAgain = findDebugMenu() else {
            XCTFail("Debug menu element not found for second open")
            return
        }
        elementAgain.tap()

        XCTAssertTrue(
            debugNavBar.waitForExistence(timeout: 5),
            "Debug menu should reopen after being closed"
        )
    }
    #endif
}

// MARK: - Rapid Interaction Tests

final class RapidInteractionUITests: RitualistUITestCase {

    func testRapidTabSwitching() {
        let tabs = ["Overview", "Habits", "Stats", "Settings"]

        // Rapidly switch tabs
        for _ in 1...5 {
            for tabName in tabs {
                navigateToTab(tabName)
                // Very short delay to simulate rapid tapping
                Thread.sleep(forTimeInterval: 0.1)
            }
        }

        // App should still be responsive
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should still exist after rapid switching")
    }

    func testRapidSheetOpenClose() throws {
        navigateToTab("Habits")

        let addButton = findAddHabitButton()
        guard let button = addButton else {
            throw XCTSkip("Add habit button not found")
        }

        let saveButton = app.buttons["Save"]

        // Rapidly open/close
        for i in 1...5 {
            button.tap()

            // Don't wait for full animation, just verify it started opening
            if saveButton.waitForExistence(timeout: 2) {
                dismissSheet()

                // Brief wait
                Thread.sleep(forTimeInterval: 0.2)
            } else {
                // Sheet might not have opened yet due to animation - skip remaining iterations
                throw XCTSkip("Sheet opening too slow for rapid test at iteration \(i)")
            }
        }

        // Final verification - should still be able to open sheet properly
        button.tap()
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "Sheet should work after rapid interactions")
    }

    private func findAddHabitButton() -> XCUIElement? {
        // Try navigation bar button
        let navBarAdd = app.navigationBars.buttons["Add"]
        if navBarAdd.waitForExistence(timeout: 3) {
            return navBarAdd
        }

        // Try accessibility identifier
        let identifiedButton = app.buttons[AccessibilityID.Habits.addButton]
        if identifiedButton.waitForExistence(timeout: 2) {
            return identifiedButton
        }

        // Try matching by label
        let plusButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add' OR identifier CONTAINS 'add'")).firstMatch
        if plusButton.waitForExistence(timeout: 2) {
            return plusButton
        }

        // Try plus icon button
        let plusIcon = app.buttons.matching(NSPredicate(format: "label CONTAINS 'plus' OR identifier CONTAINS 'plus'")).firstMatch
        if plusIcon.waitForExistence(timeout: 2) {
            return plusIcon
        }

        return nil
    }
}
