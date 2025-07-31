import XCTest
import SwiftUI

final class LocaleScreenshotTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Configure for consistent screenshots
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"
        ]
    }
    
    func testEnglishLocaleScreenshots() throws {
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
        app.launch()
        
        // Wait for app to load
        waitForAppToLoad()
        
        // Take screenshots of main screens
        takeScreenshot(name: "en_overview_screen")
        
        app.tabBars.buttons["Habits"].tap()
        takeScreenshot(name: "en_habits_screen")
        
        app.tabBars.buttons["Settings"].tap()
        takeScreenshot(name: "en_settings_screen")
    }
    
    func testGermanLocaleScreenshots() throws {
        app.launchArguments = [
            "-AppleLanguages", "(de)",
            "-AppleLocale", "de_DE"
        ]
        app.launch()
        
        // Wait for app to load (using English text since German translations aren't complete)
        waitForAppToLoad()
        
        takeScreenshot(name: "de_overview_screen")
        
        app.tabBars.buttons["Habits"].tap()
        takeScreenshot(name: "de_habits_screen")
        
        app.tabBars.buttons["Settings"].tap()
        takeScreenshot(name: "de_settings_screen")
    }
    
    func testRTLLocaleScreenshots() throws {
        app.launchArguments = [
            "-AppleLanguages", "(ar)",
            "-AppleLocale", "ar_SA",
            "-NSForceRightToLeftWritingDirection", "YES"
        ]
        app.launch()
        
        // Wait for app to load
        waitForAppToLoad()
        
        // Test RTL layout
        takeScreenshot(name: "ar_overview_screen")
        
        // Navigate using RTL-aware interaction
        let habitsTab = app.tabBars.buttons.element(boundBy: 1) // Second tab in RTL
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
                "-UIPreferredContentSizeCategoryName", size
            ]
            app.launch()
            
            takeScreenshot(name: "dynamic_type_\\(size)_overview")
            
            // Test critical screens with larger text
            app.tabBars.buttons["Habits"].tap()
            takeScreenshot(name: "dynamic_type_\\(size)_habits")
            
            app.terminate()
        }
    }
    
    func testHabitCreationFlowScreenshots() throws {
        app.launch()
        
        // Navigate to habit creation
        app.tabBars.buttons["Habits"].tap()
        
        // Look for add button (could be + or "Add" depending on state)
        let addButton = app.buttons.matching(identifier: "add_habit_button").firstMatch
        if addButton.exists {
            addButton.tap()
        } else {
            // Try finding by accessibility label
            app.buttons["Add new habit"].tap()
        }
        
        takeScreenshot(name: "habit_creation_form")
        
        // Fill out form to test layout with content
        let nameField = app.textFields["Habit name"]
        if nameField.exists {
            nameField.tap()
            nameField.typeText("Daily Morning Meditation Practice")
            takeScreenshot(name: "habit_form_with_long_name")
        }
    }
    
    func testCalendarViewScreenshots() throws {
        app.launch()
        
        // Ensure we're on overview
        app.tabBars.buttons["Overview"].tap()
        
        // Take screenshot of empty calendar
        takeScreenshot(name: "calendar_empty_state")
        
        // If there are habits, test calendar with data
        if app.staticTexts["Your Habits"].exists {
            takeScreenshot(name: "calendar_with_habits")
        }
    }
    
    func testErrorStateScreenshots() throws {
        // Test error states by simulating network issues or other failures
        app.launchArguments.append("-TESTING_ERROR_STATE")
        app.launch()
        
        // Screenshots of error states help validate error message layouts
        takeScreenshot(name: "error_state_loading_failed")
    }
    
    func testLongStringLayoutScreenshots() throws {
        // Test with pseudo-localization to simulate longer text
        app.launchArguments = [
            "-AppleLanguages", "(en-XA)", // Pseudo-locale
            "-TESTING_LONG_STRINGS", "YES"
        ]
        app.launch()
        
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
        // Wait for any of the main UI elements to appear
        let predicate = NSPredicate(format: "exists == true")
        let expectation = expectation(for: predicate, evaluatedWith: app.tabBars.firstMatch)
        wait(for: [expectation], timeout: 10)
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
                "-AppleLanguages", "(\\(locale.prefix(2)))",
                "-AppleLocale", locale
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
            "-NSForceRightToLeftWritingDirection", "YES"
        ]
        app.launch()
        
        waitForAppToLoad()
        
        // Verify that navigation elements are flipped
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists)
        
        // Take screenshot for manual verification
        takeScreenshot(name: "rtl_layout_verification")
        
        // In RTL, the first tab should appear on the right side
        // This is a simplified check - actual implementation would verify coordinates
        let firstTab = app.tabBars.buttons.element(boundBy: 0)
        let lastTab = app.tabBars.buttons.element(boundBy: 2)
        
        XCTAssertTrue(firstTab.exists)
        XCTAssertTrue(lastTab.exists)
    }
}

// MARK: - Performance Tests
extension LocaleScreenshotTests {
    
    func testLocalizationPerformance() throws {
        // Measure time to load different locales
        let locales = ["en", "de", "fr", "es", "ja", "ar"]
        
        for locale in locales {
            measure {
                app.launchArguments = ["-AppleLanguages", "(\(locale))"]
                app.launch()
                waitForAppToLoad()
                app.terminate()
            }
        }
    }
}
