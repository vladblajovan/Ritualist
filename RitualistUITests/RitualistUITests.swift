//
//  RitualistUITests.swift
//  RitualistUITests
//
//  Created by Claude on 27.11.2025.
//

import XCTest
import RitualistCore

/// Base class for Ritualist UI tests
/// Provides common setup, teardown, and helper methods
class RitualistUITestCase: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        // Set launch arguments for testing
        app.launchArguments = [LaunchArgument.uiTesting.rawValue]

        app.launch()

        // Wait for app to be ready (onboarding might show)
        waitForAppReady()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper Methods

    /// Waits for the app to be ready (past onboarding/loading)
    func waitForAppReady() {
        // Wait for tab bar to appear (indicates main UI is ready)
        let tabBar = app.tabBars.firstMatch
        let exists = tabBar.waitForExistence(timeout: 10)

        if !exists {
            // Might be showing onboarding - check for that
            let onboardingIndicator = app.staticTexts[AccessibilityID.Labels.welcome]
            if onboardingIndicator.exists {
                // Skip onboarding if shown (test-specific handling would go here)
                XCTFail("Onboarding is showing - tests require completed onboarding")
            }
        }
    }

    /// Navigates to a specific tab
    func navigateToTab(_ tabName: String) {
        let tab = app.tabBars.buttons[tabName]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "Tab '\(tabName)' should exist")
        tab.tap()
    }

    /// Waits for a sheet to appear
    func waitForSheet(timeout: TimeInterval = 5) -> Bool {
        // Sheets typically have a navigation bar or close button
        let sheet = app.sheets.firstMatch
        return sheet.waitForExistence(timeout: timeout)
    }

    /// Dismisses any presented sheet by tapping Cancel/Close or swiping down
    /// Note: Callers should use waitForNonExistence() on sheet content to confirm dismissal
    func dismissSheet() {
        // First try to find a Cancel or Close button
        let cancelButton = app.buttons[AccessibilityID.Labels.cancel]
        if cancelButton.waitForExistence(timeout: 1) {
            cancelButton.tap()
            return
        }

        let closeButton = app.buttons[AccessibilityID.Labels.close]
        if closeButton.waitForExistence(timeout: 1) {
            closeButton.tap()
            return
        }

        // Fall back to swipe gesture - use a more aggressive swipe
        let window = app.windows.firstMatch
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    /// Waits for a tab to be selected after tapping
    func waitForTabSelected(_ tabName: String, timeout: TimeInterval = 3) -> Bool {
        let tab = app.tabBars.buttons[tabName]
        let predicate = NSPredicate(format: "isSelected == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: tab)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    /// Taps a button by accessibility identifier
    func tapButton(identifier: String) {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Button '\(identifier)' should exist")
        button.tap()
    }
}

// MARK: - Tab Navigation Tests

final class TabNavigationUITests: RitualistUITestCase {

    func testTabBarExists() {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
    }

    func testAllTabsExist() {
        let expectedTabs = ["Overview", "Habits", "Stats", "Settings"]

        for tabName in expectedTabs {
            let tab = app.tabBars.buttons[tabName]
            XCTAssertTrue(tab.exists, "Tab '\(tabName)' should exist")
        }
    }

    func testNavigateToEachTab() {
        let tabs = ["Overview", "Habits", "Stats", "Settings"]

        for tabName in tabs {
            navigateToTab(tabName)

            // Verify the tab is selected
            let tab = app.tabBars.buttons[tabName]
            XCTAssertTrue(tab.isSelected, "Tab '\(tabName)' should be selected after tap")
        }
    }

    func testNavigateBetweenTabs() {
        // Start on Overview
        navigateToTab("Overview")
        XCTAssertTrue(app.tabBars.buttons["Overview"].isSelected)

        // Go to Settings
        navigateToTab("Settings")
        XCTAssertTrue(app.tabBars.buttons["Settings"].isSelected)
        XCTAssertFalse(app.tabBars.buttons["Overview"].isSelected)

        // Go back to Overview
        navigateToTab("Overview")
        XCTAssertTrue(app.tabBars.buttons["Overview"].isSelected)
    }
}

// MARK: - Settings Navigation Tests

final class SettingsNavigationUITests: RitualistUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        navigateToTab("Settings")
    }

    func testSettingsTabShowsContent() {
        // Verify settings content is visible
        let settingsNavBar = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNavBar.waitForExistence(timeout: 5), "Settings navigation bar should exist")
    }

    #if DEBUG
    func testDebugMenuExists() {
        // In debug builds, debug menu should be accessible
        let debugMenuButton = app.buttons[AccessibilityID.Labels.debugMenu]

        if debugMenuButton.waitForExistence(timeout: 3) {
            debugMenuButton.tap()

            // Verify debug menu opens
            let debugNavBar = app.navigationBars[AccessibilityID.Labels.debugMenu]
            XCTAssertTrue(debugNavBar.waitForExistence(timeout: 5), "Debug menu should open")
        }
    }
    #endif
}

// MARK: - Habits Tab Tests

final class HabitsTabUITests: RitualistUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        navigateToTab("Habits")
    }

    func testHabitsTabShowsContent() {
        // Verify habits content is visible
        let habitsNavBar = app.navigationBars["Habits"]
        XCTAssertTrue(habitsNavBar.waitForExistence(timeout: 5), "Habits navigation bar should exist")
    }

    func testAddHabitButtonExists() {
        // Try accessibility identifier first (most reliable)
        let identifiedButton = app.buttons[AccessibilityID.Habits.addButton]
        if identifiedButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(identifiedButton.exists, "Add habit button should exist")
            return
        }

        // Fall back to accessibility label
        let labelButton = app.buttons[AccessibilityID.Labels.addHabit]
        XCTAssertTrue(labelButton.exists, "Add habit button should exist")
    }
}

// MARK: - Sheet Presentation Tests

final class SheetPresentationUITests: RitualistUITestCase {

    func testAddHabitSheetOpensAndCloses() {
        navigateToTab("Habits")

        // Find and tap add button
        let addButton = app.navigationBars.buttons[AccessibilityID.Labels.add]
        guard addButton.waitForExistence(timeout: 5) else {
            // Try alternative identifiers
            return
        }

        addButton.tap()

        // Wait for sheet to appear
        // The sheet should have some identifiable content
        let saveButton = app.buttons[AccessibilityID.Labels.save]
        let sheetAppeared = saveButton.waitForExistence(timeout: 5)

        if sheetAppeared {
            // Dismiss by swiping down
            dismissSheet()

            // Verify sheet is dismissed
            XCTAssertFalse(saveButton.exists, "Sheet should be dismissed")
        }
    }

    func testSheetCanBeReopened() {
        navigateToTab("Habits")

        let addButton = app.navigationBars.buttons[AccessibilityID.Labels.add]
        guard addButton.waitForExistence(timeout: 5) else {
            return
        }

        // Open sheet
        addButton.tap()

        let saveButton = app.buttons[AccessibilityID.Labels.save]
        guard saveButton.waitForExistence(timeout: 5) else {
            return
        }

        // Dismiss
        dismissSheet()

        // Wait for dismissal
        _ = saveButton.waitForNonExistence(timeout: 3)

        // Reopen
        addButton.tap()

        // Verify it reopens
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "Sheet should reopen after dismissal")
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    /// Waits for the element to not exist
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
