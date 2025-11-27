//
//  AccessibilityIdentifiersSyncTests.swift
//  RitualistTests
//
//  Created by Claude on 27.11.2025.
//
//  Validates that AccessibilityIdentifiers are consistent between app and UI test targets.
//  This prevents identifier drift that would cause UI tests to fail.
//

import XCTest
@testable import Ritualist

/// Tests to ensure AccessibilityIdentifiers stay in sync between app and UI tests.
///
/// The app and UI test targets each have their own copy of AccessibilityIdentifiers
/// because UI tests cannot import the app module directly. These tests verify
/// that key identifiers have the expected values.
final class AccessibilityIdentifiersSyncTests: XCTestCase {

    // MARK: - Tab Bar Identifiers

    func testTabBarIdentifiersHaveExpectedValues() {
        XCTAssertEqual(AccessibilityID.TabBar.overview, "tab.overview")
        XCTAssertEqual(AccessibilityID.TabBar.habits, "tab.habits")
        XCTAssertEqual(AccessibilityID.TabBar.stats, "tab.stats")
        XCTAssertEqual(AccessibilityID.TabBar.settings, "tab.settings")
    }

    // MARK: - Navigation Identifiers

    func testNavigationIdentifiersHaveExpectedValues() {
        XCTAssertEqual(AccessibilityID.Navigation.backButton, "navigation.back")
        XCTAssertEqual(AccessibilityID.Navigation.closeButton, "navigation.close")
        XCTAssertEqual(AccessibilityID.Navigation.doneButton, "navigation.done")
        XCTAssertEqual(AccessibilityID.Navigation.cancelButton, "navigation.cancel")
    }

    // MARK: - Habits Identifiers

    func testHabitsIdentifiersHaveExpectedValues() {
        XCTAssertEqual(AccessibilityID.Habits.root, "habits.root")
        XCTAssertEqual(AccessibilityID.Habits.habitsList, "habits.list")
        XCTAssertEqual(AccessibilityID.Habits.addButton, "habits.add")
        XCTAssertEqual(AccessibilityID.Habits.assistantButton, "habits.assistant")
        XCTAssertEqual(AccessibilityID.Habits.emptyState, "habits.emptyState")
    }

    // MARK: - Habit Detail Identifiers

    func testHabitDetailIdentifiersHaveExpectedValues() {
        XCTAssertEqual(AccessibilityID.HabitDetail.sheet, "habitDetail.sheet")
        XCTAssertEqual(AccessibilityID.HabitDetail.nameField, "habitDetail.name")
        XCTAssertEqual(AccessibilityID.HabitDetail.saveButton, "habitDetail.save")
        XCTAssertEqual(AccessibilityID.HabitDetail.cancelButton, "habitDetail.cancel")
        XCTAssertEqual(AccessibilityID.HabitDetail.deleteButton, "habitDetail.delete")
    }

    // MARK: - Settings Identifiers

    func testSettingsIdentifiersHaveExpectedValues() {
        XCTAssertEqual(AccessibilityID.Settings.root, "settings.root")
        XCTAssertEqual(AccessibilityID.Settings.debugMenuButton, "settings.debugMenu")
    }

    // MARK: - Debug Menu Identifiers

    func testDebugMenuIdentifiersHaveExpectedValues() {
        XCTAssertEqual(AccessibilityID.DebugMenu.sheet, "debugMenu.sheet")
        XCTAssertEqual(AccessibilityID.DebugMenu.clearBadgeButton, "debugMenu.clearBadge")
    }

    // MARK: - Personality Analysis Identifiers

    func testPersonalityAnalysisIdentifiersHaveExpectedValues() {
        XCTAssertEqual(AccessibilityID.PersonalityAnalysis.sheet, "personalityAnalysis.sheet")
        XCTAssertEqual(AccessibilityID.PersonalityAnalysis.closeButton, "personalityAnalysis.close")
    }

    // MARK: - Habits Assistant Identifiers

    func testHabitsAssistantIdentifiersHaveExpectedValues() {
        XCTAssertEqual(AccessibilityID.HabitsAssistant.sheet, "habitsAssistant.sheet")
        XCTAssertEqual(AccessibilityID.HabitsAssistant.closeButton, "habitsAssistant.close")
    }
}
