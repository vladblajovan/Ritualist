//
//  LocalizationPerformanceTests.swift
//  RitualistUITests
//
//  Created by Claude on 01.08.2025.
//

import XCTest

/// Performance tests for app launch time across different locales
/// Tests ensure localization doesn't significantly impact startup performance
final class LocalizationPerformanceTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }
    
    // MARK: - Localization Performance Tests
    // Note: Split by locale because XCTest only allows one measure() call per test method
    
    func testLocalizationPerformance_English() throws {
        measureLocalizationPerformance(locale: "en")
    }
    
    func testLocalizationPerformance_German() throws {
        measureLocalizationPerformance(locale: "de")
    }
    
    func testLocalizationPerformance_French() throws {
        measureLocalizationPerformance(locale: "fr")
    }
    
    func testLocalizationPerformance_Spanish() throws {
        measureLocalizationPerformance(locale: "es")
    }
    
    func testLocalizationPerformance_Japanese() throws {
        measureLocalizationPerformance(locale: "ja")
    }
    
    func testLocalizationPerformance_Arabic() throws {
        measureLocalizationPerformance(locale: "ar")
    }
    
    // MARK: - Helper Methods
    
    private func measureLocalizationPerformance(locale: String) {
        let options = XCTMeasureOptions()
        options.iterationCount = 3 // Reduce iterations for faster tests
        
        measure(options: options) {
            app.launchArguments = [
                "-AppleLanguages", "(\(locale))",
                "-TESTING_SKIP_AUTH", "YES",
                "-TESTING_SKIP_ONBOARDING", "YES",
                "-TESTING_MODE", "YES"
            ]
            app.launch()
            
            // Wait for app to fully load with timeout
            let loaded = app.tabBars.firstMatch.waitForExistence(timeout: 10)
            XCTAssertTrue(loaded, "App should load successfully for locale: \(locale)")
            
            app.terminate()
        }
    }
}