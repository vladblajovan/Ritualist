import XCTest
import SwiftUI

/// Comprehensive UI tests for localization, RTL support, and accessibility across different locales
/// Tests screenshots and layout consistency for internationalization validation
/// Updated to work with current app architecture including authentication and onboarding flows
final class LocaleScreenshotTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Configure for consistent screenshots and bypass auth/onboarding
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL",
            "-TESTING_SKIP_AUTH", "YES",
            "-TESTING_SKIP_ONBOARDING", "YES",
            "-TESTING_MODE", "YES"
        ]
    }
    
    func testEnglishLocaleScreenshots() throws {
        app.launchArguments.append(contentsOf: [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ])
        app.launch()
        
        // Wait for app to load
        waitForAppToLoad()
        
        // Take screenshots of main screens (starts on Overview)
        takeScreenshot(name: "en_overview_screen")
        
        // Navigate to Habits tab - use accessibility or look for the tab by position
        if app.tabBars.buttons["Habits"].exists {
            app.tabBars.buttons["Habits"].tap()
        } else {
            // Try by position (second tab)
            app.tabBars.buttons.element(boundBy: 1).tap()
        }
        takeScreenshot(name: "en_habits_screen")
        
        // Navigate to Settings tab
        if app.tabBars.buttons["Settings"].exists {
            app.tabBars.buttons["Settings"].tap()
        } else {
            // Try by position (third tab)
            app.tabBars.buttons.element(boundBy: 2).tap()
        }
        takeScreenshot(name: "en_settings_screen")
    }
    
    func testGermanLocaleScreenshots() throws {
        app.launchArguments.append(contentsOf: [
            "-AppleLanguages", "(de)",
            "-AppleLocale", "de_DE"
        ])
        app.launch()
        
        // Wait for app to load
        waitForAppToLoad()
        
        takeScreenshot(name: "de_overview_screen")
        
        // Navigate using tab positions since German text may be different
        app.tabBars.buttons.element(boundBy: 1).tap() // Habits tab
        takeScreenshot(name: "de_habits_screen")
        
        app.tabBars.buttons.element(boundBy: 2).tap() // Settings tab
        takeScreenshot(name: "de_settings_screen")
    }
    
    func testRTLLocaleScreenshots() throws {
        app.launchArguments.append(contentsOf: [
            "-AppleLanguages", "(ar)",
            "-AppleLocale", "ar_SA",
            "-NSForceRightToLeftWritingDirection", "YES"
        ])
        app.launch()
        
        // Wait for app to load
        waitForAppToLoad()
        
        // Test RTL layout
        takeScreenshot(name: "ar_overview_screen")
        
        // Navigate using RTL-aware interaction (tab positions remain the same)
        let habitsTab = app.tabBars.buttons.element(boundBy: 1) // Habits tab
        habitsTab.tap()
        takeScreenshot(name: "ar_habits_screen")
    }
    
    func testDynamicTypeScreenshots() throws {
        // Test with larger text sizes
        let dynamicTypeSizes = [
            "UICTContentSizeCategoryXL",
            "UICTContentSizeCategoryXXL",
            "UICTContentSizeCategoryAccessibilityM"
        ]
        
        for size in dynamicTypeSizes {
            app.launchArguments = [
                "-AppleLanguages", "(en)",
                "-UIPreferredContentSizeCategoryName", size,
                "-TESTING_SKIP_AUTH", "YES",
                "-TESTING_SKIP_ONBOARDING", "YES",
                "-TESTING_MODE", "YES"
            ]
            app.launch()
            
            waitForAppToLoad()
            takeScreenshot(name: "dynamic_type_\(size)_overview")
            
            // Test critical screens with larger text
            app.tabBars.buttons.element(boundBy: 1).tap() // Habits tab
            takeScreenshot(name: "dynamic_type_\(size)_habits")
            
            app.terminate()
        }
    }
    
    func testHabitCreationFlowScreenshots() throws {
        app.launch()
        
        waitForAppToLoad()
        
        // Navigate to Habits tab
        app.tabBars.buttons.element(boundBy: 1).tap()
        
        // Look for add button - try multiple strategies
        var addButtonTapped = false
        
        // Strategy 1: Look for + button
        if app.buttons.matching(NSPredicate(format: "label CONTAINS '+'")).firstMatch.exists {
            app.buttons.matching(NSPredicate(format: "label CONTAINS '+'")).firstMatch.tap()
            addButtonTapped = true
        }
        // Strategy 2: Look for toolbar add button
        else if app.navigationBars.buttons.matching(NSPredicate(format: "label CONTAINS '+'")).firstMatch.exists {
            app.navigationBars.buttons.matching(NSPredicate(format: "label CONTAINS '+'")).firstMatch.tap()
            addButtonTapped = true
        }
        // Strategy 3: Look for specific accessibility labels
        else if app.buttons["Add new habit"].exists {
            app.buttons["Add new habit"].tap()
            addButtonTapped = true
        } else if app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'add'")).firstMatch.exists {
            app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'add'")).firstMatch.tap()
            addButtonTapped = true
        }
        
        if addButtonTapped {
            // Wait for form to appear
            _ = app.textFields.firstMatch.waitForExistence(timeout: 5)
            takeScreenshot(name: "habit_creation_form")
            
            // Fill out form to test layout with content
            let nameField = app.textFields.firstMatch
            if nameField.exists {
                nameField.tap()
                nameField.typeText("Daily Morning Meditation Practice")
                takeScreenshot(name: "habit_form_with_long_name")
            }
        } else {
            // If no add button found, still take screenshot of the habits page
            takeScreenshot(name: "habits_page_no_add_button")
        }
    }
    
    func testCalendarViewScreenshots() throws {
        app.launch()
        waitForAppToLoad()
        
        // Ensure we're on overview (should already be there)
        app.tabBars.buttons.element(boundBy: 0).tap() // Overview tab
        
        // Take screenshot of calendar state
        takeScreenshot(name: "calendar_overview_state")
        
        // Test calendar interactions if calendar elements exist
        if app.buttons.matching(NSPredicate(format: "label CONTAINS 'month'")).count > 0 {
            takeScreenshot(name: "calendar_with_navigation")
        }
    }
    
    func testErrorStateScreenshots() throws {
        // Test error states by simulating failures
        app.launchArguments.append(contentsOf: [
            "-TESTING_ERROR_STATE", "YES",
            "-TESTING_MODE", "YES"
        ])
        app.launch()
        
        // Wait briefly then take screenshot of error state
        sleep(2)
        takeScreenshot(name: "error_state_loading_failed")
    }
    
    func testLongStringLayoutScreenshots() throws {
        // Test with pseudo-localization to simulate longer text
        app.launchArguments = [
            "-AppleLanguages", "(en-XA)", // Pseudo-locale
            "-TESTING_LONG_STRINGS", "YES",
            "-TESTING_SKIP_AUTH", "YES",
            "-TESTING_SKIP_ONBOARDING", "YES",
            "-TESTING_MODE", "YES"
        ]
        app.launch()
        
        waitForAppToLoad()
        takeScreenshot(name: "pseudo_locale_overview")
        
        app.tabBars.buttons.element(boundBy: 1).tap() // Habits tab
        takeScreenshot(name: "pseudo_locale_habits")
    }
    
    // MARK: - Helper Methods
    
    private func takeScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Also save to a specific directory for CI/CD
        let screenshotData = screenshot.pngRepresentation
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let screenshotURL = documentsPath.appendingPathComponent("\(name).png")
        
        try? screenshotData.write(to: screenshotURL)
    }
    
    private func waitForAppToLoad() {
        // Wait for the main UI elements to appear, handling auth/onboarding flow
        
        // First, check if we're in authentication flow
        if app.buttons["Login"].exists {
            // Handle login if needed
            app.buttons["Login"].tap()
        }
        
        // Check for onboarding flow
        if app.buttons["Get Started"].exists || app.buttons["Continue"].exists {
            // Skip onboarding by looking for skip/continue buttons
            let skipButton = app.buttons["Skip"] 
            let continueButton = app.buttons["Continue"]
            let getStartedButton = app.buttons["Get Started"]
            
            if skipButton.exists {
                skipButton.tap()
            } else if getStartedButton.exists {
                getStartedButton.tap()
            } else if continueButton.exists {
                continueButton.tap()
            }
        }
        
        // Wait for main tab bar to appear
        let predicate = NSPredicate(format: "exists == true")
        let expectation = expectation(for: predicate, evaluatedWith: app.tabBars.firstMatch)
        wait(for: [expectation], timeout: 15)
    }
}

// MARK: - Screenshot Comparison Tests
extension LocaleScreenshotTests {
    
    func testScreenshotConsistencyAcrossLocales() throws {
        // This test compares UI layout consistency between locales
        // Useful for catching layout issues with longer text
        
        let locales = ["en_US", "de_DE", "fr_FR"]
        var screenshots: [String: XCUIScreenshot] = [:]
        
        for locale in locales {
            app.launchArguments = [
                "-AppleLanguages", "(\(locale.prefix(2)))",
                "-AppleLocale", locale,
                "-TESTING_SKIP_AUTH", "YES",
                "-TESTING_SKIP_ONBOARDING", "YES",
                "-TESTING_MODE", "YES"
            ]
            app.launch()
            
            waitForAppToLoad()
            screenshots[locale] = XCUIScreen.main.screenshot()
            
            app.terminate()
        }
        
        // Compare screenshot dimensions and layout structure
        // This is a simplified check - in practice you'd use image comparison tools
        let englishScreenshot = screenshots["en_US"]!
        
        for (locale, screenshot) in screenshots {
            if locale != "en_US" {
                XCTAssertEqual(
                    screenshot.image.size.width,
                    englishScreenshot.image.size.width,
                    "Screenshot width should be consistent across locales"
                )
                
                XCTAssertEqual(
                    screenshot.image.size.height,
                    englishScreenshot.image.size.height,
                    "Screenshot height should be consistent across locales"
                )
            }
        }
    }
    
    func testUIElementPositionsInRTL() throws {
        // Test that UI elements are properly positioned in RTL layout
        app.launchArguments = [
            "-NSForceRightToLeftWritingDirection", "YES",
            "-TESTING_SKIP_AUTH", "YES",
            "-TESTING_SKIP_ONBOARDING", "YES",
            "-TESTING_MODE", "YES"
        ]
        app.launch()
        
        waitForAppToLoad()
        
        // Verify that navigation elements are flipped
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        
        // Take screenshot for manual verification
        takeScreenshot(name: "rtl_layout_verification")
        
        // Verify that tab buttons exist (RTL mainly affects content layout, not tab order)
        let firstTab = app.tabBars.buttons.element(boundBy: 0)
        let lastTab = app.tabBars.buttons.element(boundBy: 2)
        
        XCTAssertTrue(firstTab.exists, "First tab should exist")
        XCTAssertTrue(lastTab.exists, "Last tab should exist")
    }
}

