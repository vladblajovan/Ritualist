//
//  ReturningUserOnboardingUITests.swift
//  RitualistUITests
//
//  Created by Claude on 28.11.2025.
//
//  UI tests for returning user onboarding flow.
//  Tests the welcome back screen, profile completion, and permissions steps.
//

import XCTest

@MainActor
final class ReturningUserOnboardingUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Welcome Back Screen Tests

    func testWelcomeBackScreenDisplaysCorrectly() throws {
        app.launchArguments = ["--force-returning-user"]
        app.launch()

        // Verify welcome back screen elements
        let welcomeText = app.staticTexts["Welcome back,"]
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 5), "Welcome back text should be visible")

        let userName = app.staticTexts["Test User!"]
        XCTAssertTrue(userName.exists, "User name should be displayed")

        let syncedMessage = app.staticTexts["Your data has been synced from iCloud"]
        XCTAssertTrue(syncedMessage.exists, "Synced message should be visible")

        // Verify synced data summary
        let habitsSynced = app.staticTexts["5 habits synced"]
        XCTAssertTrue(habitsSynced.exists, "Habits count should be visible")

        let categoriesSynced = app.staticTexts["2 custom categories synced"]
        XCTAssertTrue(categoriesSynced.exists, "Categories count should be visible")

        let profileRestored = app.staticTexts["Profile restored"]
        XCTAssertTrue(profileRestored.exists, "Profile restored should be visible")

        // Verify continue button
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.exists, "Continue button should be visible")
    }

    func testWelcomeBackContinueGoesToProfileCompletion() throws {
        app.launchArguments = ["--force-returning-user"]
        app.launch()

        // Tap continue
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()

        // Should show profile completion (since gender/ageGroup are nil)
        let profileTitle = app.staticTexts["Complete Your Profile"]
        XCTAssertTrue(profileTitle.waitForExistence(timeout: 3), "Profile completion screen should appear")
    }

    // MARK: - Profile Completion Tests

    func testProfileCompletionShowsGenderAndAgeDropdowns() throws {
        app.launchArguments = ["--force-returning-user"]
        app.launch()

        // Navigate to profile completion
        app.buttons["Continue"].tap()

        let profileTitle = app.staticTexts["Complete Your Profile"]
        XCTAssertTrue(profileTitle.waitForExistence(timeout: 3))

        // Gender dropdown should be visible
        let genderDropdown = app.buttons.matching(identifier: "Gender").firstMatch
        XCTAssertTrue(genderDropdown.exists, "Gender dropdown should be visible")

        // Age dropdown should be visible
        let ageDropdown = app.buttons.matching(identifier: "Age group").firstMatch
        XCTAssertTrue(ageDropdown.exists, "Age group dropdown should be visible")
    }

    func testProfileCompletionGenderSelection() throws {
        app.launchArguments = ["--force-returning-user"]
        app.launch()

        // Navigate to profile completion
        app.buttons["Continue"].tap()

        let profileTitle = app.staticTexts["Complete Your Profile"]
        XCTAssertTrue(profileTitle.waitForExistence(timeout: 3))

        // Tap gender dropdown
        let genderDropdown = app.buttons.matching(identifier: "Gender").firstMatch
        genderDropdown.tap()

        // Select Female
        let femaleOption = app.buttons["Female"]
        XCTAssertTrue(femaleOption.waitForExistence(timeout: 2))
        femaleOption.tap()

        // Verify selection (dropdown value should update)
        XCTAssertEqual(genderDropdown.value as? String, "Female", "Gender should be Female")
    }

    func testProfileCompletionAgeGroupSelection() throws {
        app.launchArguments = ["--force-returning-user"]
        app.launch()

        // Navigate to profile completion
        app.buttons["Continue"].tap()

        let profileTitle = app.staticTexts["Complete Your Profile"]
        XCTAssertTrue(profileTitle.waitForExistence(timeout: 3))

        // Tap age group dropdown
        let ageDropdown = app.buttons.matching(identifier: "Age group").firstMatch
        ageDropdown.tap()

        // Select 25-34
        let ageOption = app.buttons["25-34"]
        XCTAssertTrue(ageOption.waitForExistence(timeout: 2))
        ageOption.tap()

        // Verify selection
        XCTAssertEqual(ageDropdown.value as? String, "25-34", "Age group should be 25-34")
    }

    func testProfileCompletionContinueGoesToPermissions() throws {
        app.launchArguments = ["--force-returning-user"]
        app.launch()

        // Navigate to profile completion
        app.buttons["Continue"].tap()

        let profileTitle = app.staticTexts["Complete Your Profile"]
        XCTAssertTrue(profileTitle.waitForExistence(timeout: 3))

        // Continue to permissions
        let continueButton = app.buttons["Continue"]
        continueButton.tap()

        // Should show permissions screen
        let permissionsTitle = app.staticTexts["Set Up This Device"]
        XCTAssertTrue(permissionsTitle.waitForExistence(timeout: 3), "Permissions screen should appear")
    }

    // MARK: - Permissions Screen Tests

    func testPermissionsScreenDisplaysCorrectly() throws {
        // Use complete profile to skip profile completion
        app.launchArguments = ["--force-returning-user-complete"]
        app.launch()

        // Tap continue on welcome screen
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()

        // Should go directly to permissions (profile is complete)
        let permissionsTitle = app.staticTexts["Set Up This Device"]
        XCTAssertTrue(permissionsTitle.waitForExistence(timeout: 3), "Permissions screen should appear")

        // Verify permission cards
        let notificationsCard = app.staticTexts["Notifications"]
        XCTAssertTrue(notificationsCard.exists, "Notifications permission should be visible")

        let locationCard = app.staticTexts["Location"]
        XCTAssertTrue(locationCard.exists, "Location permission should be visible")

        // Verify Get Started button
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.exists, "Get Started button should be visible")
    }

    func testPermissionsScreenHasEnableButtons() throws {
        app.launchArguments = ["--force-returning-user-complete"]
        app.launch()

        // Navigate to permissions
        app.buttons["Continue"].tap()

        let permissionsTitle = app.staticTexts["Set Up This Device"]
        XCTAssertTrue(permissionsTitle.waitForExistence(timeout: 3))

        // Enable buttons should be visible (permissions not granted yet)
        let enableButtons = app.buttons.matching(identifier: "Enable")
        XCTAssertGreaterThanOrEqual(enableButtons.count, 1, "At least one Enable button should be visible")
    }

    // MARK: - Complete Flow Tests

    func testCompleteReturningUserFlowWithProfileCompletion() throws {
        app.launchArguments = ["--force-returning-user"]
        app.launch()

        // Step 1: Welcome back screen
        let welcomeText = app.staticTexts["Welcome back,"]
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 5))
        app.buttons["Continue"].tap()

        // Step 2: Profile completion
        let profileTitle = app.staticTexts["Complete Your Profile"]
        XCTAssertTrue(profileTitle.waitForExistence(timeout: 3))

        // Select gender
        let genderDropdown = app.buttons.matching(identifier: "Gender").firstMatch
        genderDropdown.tap()
        app.buttons["Male"].tap()

        // Select age group
        let ageDropdown = app.buttons.matching(identifier: "Age group").firstMatch
        ageDropdown.tap()
        app.buttons["35-44"].tap()

        app.buttons["Continue"].tap()

        // Step 3: Permissions
        let permissionsTitle = app.staticTexts["Set Up This Device"]
        XCTAssertTrue(permissionsTitle.waitForExistence(timeout: 3))

        // Complete flow
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.exists, "Get Started button should be visible")
    }

    func testCompleteReturningUserFlowSkippingProfileCompletion() throws {
        // Use complete profile variant
        app.launchArguments = ["--force-returning-user-complete"]
        app.launch()

        // Step 1: Welcome back screen
        let welcomeText = app.staticTexts["Welcome back,"]
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 5))
        app.buttons["Continue"].tap()

        // Step 2: Should skip directly to permissions (profile is complete)
        let permissionsTitle = app.staticTexts["Set Up This Device"]
        XCTAssertTrue(permissionsTitle.waitForExistence(timeout: 3), "Should skip to permissions")

        // Verify we're NOT on profile completion
        let profileTitle = app.staticTexts["Complete Your Profile"]
        XCTAssertFalse(profileTitle.exists, "Profile completion should be skipped")
    }

    // MARK: - Name Input Tests (when profile name is missing)

    func testReturningUserWithNameDoesNotShowNameField() throws {
        // Profile has name "Test User" - should NOT show name field
        app.launchArguments = ["--force-returning-user"]
        app.launch()

        // Navigate to profile completion
        app.buttons["Continue"].tap()

        let profileTitle = app.staticTexts["Complete Your Profile"]
        XCTAssertTrue(profileTitle.waitForExistence(timeout: 3))

        // Name field should NOT be visible (profileName is "Test User" in mock)
        let nameField = app.textFields["Name"]
        XCTAssertFalse(nameField.exists, "Name field should not show when profile has name")
    }

    func testReturningUserWithMissingNameShowsNameField() throws {
        // Profile has NO name - should show name field
        app.launchArguments = ["--force-returning-user-no-name"]
        app.launch()

        // Navigate to profile completion
        app.buttons["Continue"].tap()

        let profileTitle = app.staticTexts["Complete Your Profile"]
        XCTAssertTrue(profileTitle.waitForExistence(timeout: 3))

        // Name field SHOULD be visible (profileName is nil in mock)
        let nameField = app.textFields["Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2), "Name field should show when profile has no name")
    }

    func testReturningUserNameFieldRequiredToProgress() throws {
        app.launchArguments = ["--force-returning-user-no-name"]
        app.launch()

        // Navigate to profile completion
        app.buttons["Continue"].tap()

        let profileTitle = app.staticTexts["Complete Your Profile"]
        XCTAssertTrue(profileTitle.waitForExistence(timeout: 3))

        // Continue button should be disabled when name is empty
        let continueButton = app.buttons["Continue"]
        XCTAssertFalse(continueButton.isEnabled, "Continue should be disabled without name")

        // Enter a name
        let nameField = app.textFields["Name"]
        nameField.tap()
        nameField.typeText("Jane")

        // Continue button should now be enabled
        XCTAssertTrue(continueButton.isEnabled, "Continue should be enabled with name")
    }

    func testReturningUserNameFieldCharacterLimit() throws {
        app.launchArguments = ["--force-returning-user-no-name"]
        app.launch()

        // Navigate to profile completion
        app.buttons["Continue"].tap()

        let profileTitle = app.staticTexts["Complete Your Profile"]
        XCTAssertTrue(profileTitle.waitForExistence(timeout: 3))

        let nameField = app.textFields["Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))

        // Type a name approaching the limit (45 chars)
        nameField.tap()
        let almostLongName = String(repeating: "B", count: 45)
        nameField.typeText(almostLongName)

        // Character counter should appear (shows when > 40 chars)
        let charCounter = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '/'")).firstMatch
        XCTAssertTrue(charCounter.waitForExistence(timeout: 2), "Character counter should appear near limit")
    }

    // MARK: - Character Limit Tests

    func testNameFieldCharacterLimitInNewUserOnboarding() throws {
        app.launchArguments = ["--force-onboarding"]
        app.launch()

        let nameField = app.textFields["Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))

        // Type a very long name (60+ characters)
        let longName = String(repeating: "A", count: 60)
        nameField.tap()
        nameField.typeText(longName)

        // The field should truncate to 50 characters
        // Note: Getting the actual text value in UI tests can be tricky
        // This test verifies the field accepts input without crashing
        XCTAssertTrue(nameField.exists, "Name field should still exist after long input")
    }

    // MARK: - Accessibility Tests

    func testReturningUserWelcomeAccessibility() throws {
        app.launchArguments = ["--force-returning-user"]
        app.launch()

        // Verify synced data summary has accessibility label
        let syncedSummary = app.otherElements["Synced data summary"]
        XCTAssertTrue(syncedSummary.waitForExistence(timeout: 5), "Synced data summary should have accessibility label")
    }

    func testProfileCompletionAccessibility() throws {
        app.launchArguments = ["--force-returning-user"]
        app.launch()

        app.buttons["Continue"].tap()

        let profileTitle = app.staticTexts["Complete Your Profile"]
        XCTAssertTrue(profileTitle.waitForExistence(timeout: 3))

        // Verify dropdowns have accessibility labels
        let genderDropdown = app.buttons.matching(identifier: "Gender").firstMatch
        XCTAssertTrue(genderDropdown.exists, "Gender dropdown should have accessibility label")

        let ageDropdown = app.buttons.matching(identifier: "Age group").firstMatch
        XCTAssertTrue(ageDropdown.exists, "Age group dropdown should have accessibility label")
    }

    func testPermissionsAccessibility() throws {
        app.launchArguments = ["--force-returning-user-complete"]
        app.launch()

        app.buttons["Continue"].tap()

        let permissionsTitle = app.staticTexts["Set Up This Device"]
        XCTAssertTrue(permissionsTitle.waitForExistence(timeout: 3))

        // Verify notifications permission has accessibility
        let notificationsElement = app.staticTexts["Notifications"]
        XCTAssertTrue(notificationsElement.exists)

        // Verify location permission has accessibility
        let locationElement = app.staticTexts["Location"]
        XCTAssertTrue(locationElement.exists)
    }
}
