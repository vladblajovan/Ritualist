//
//  RitualistUITests.swift
//  RitualistUITests
//
//  Created by Vlad Blajovan on 29.07.2025.
//

import XCTest

final class RitualistUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        // Target: App should launch within 10 seconds on simulator
        let launchTimeThreshold: TimeInterval = 10.0
        let iterationCount: Int = 5
        
        let options = XCTMeasureOptions()
        options.iterationCount = iterationCount
        
        measure(metrics: [XCTApplicationLaunchMetric()], options: options) {
            let app = XCUIApplication()
            
            // Configure for consistent testing
            app.launchArguments = [
                "-TESTING_SKIP_AUTH", "YES",
                "-TESTING_SKIP_ONBOARDING", "YES",
                "-TESTING_MODE", "YES"
            ]
            
            let startTime = CFAbsoluteTimeGetCurrent()
            app.launch()
            
            // Wait for main UI to be ready
            _ = app.tabBars.firstMatch.waitForExistence(timeout: 10)
            
            let launchTime = CFAbsoluteTimeGetCurrent() - startTime
            
            // Explicit threshold check with descriptive failure
            XCTAssertLessThan(
                launchTime, 
                launchTimeThreshold,
                "App launch took \(String(format: "%.2f", launchTime))s, exceeding threshold of \(launchTimeThreshold)s"
            )
            
            app.terminate()
        }
    }
}
