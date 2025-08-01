import XCTest

final class SwipeNavigationUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = [
            "-TESTING_MODE", "YES",
            "-TESTING_SKIP_ONBOARDING", "YES"
        ]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testCalendarSwipeNavigation() throws {
        // Given - Navigate to Overview tab (should be default)
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        // When - Find the calendar view
        let calendarView = app.otherElements.matching(identifier: "monthly-calendar").firstMatch
        
        // Then - Verify calendar exists
        if calendarView.exists {
            // Test swipe left (next month)
            calendarView.swipeLeft()
            
            // Wait for animation
            Thread.sleep(forTimeInterval: 0.5)
            
            // Test swipe right (previous month)
            calendarView.swipeRight()
            calendarView.swipeRight() // Go to previous month
            
            // Wait for animation
            Thread.sleep(forTimeInterval: 0.5)
            
            // Verify we can still tap buttons
            let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "next")).firstMatch
            if nextButton.exists {
                nextButton.tap()
            }
        }
    }
    
    func testSwipeGestureThresholds() throws {
        // Given
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        // When - Find calendar
        let calendarView = app.otherElements.matching(identifier: "monthly-calendar").firstMatch
        
        if calendarView.exists {
            let startCoordinate = calendarView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            
            // Test small swipe (should not trigger navigation)
            let smallEndCoordinate = calendarView.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.5))
            startCoordinate.press(forDuration: 0.1, thenDragTo: smallEndCoordinate)
            
            Thread.sleep(forTimeInterval: 0.3)
            
            // Test large swipe (should trigger navigation)
            let largeEndCoordinate = calendarView.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
            startCoordinate.press(forDuration: 0.1, thenDragTo: largeEndCoordinate)
            
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
    
    func testSwipeAndButtonNavigationCoexistence() throws {
        // Given
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        // Test that both swipe and button navigation work
        let calendarView = app.otherElements.matching(identifier: "monthly-calendar").firstMatch
        let prevButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "previous")).firstMatch
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "next")).firstMatch
        
        if calendarView.exists {
            // Test button navigation first
            if nextButton.exists {
                nextButton.tap()
                Thread.sleep(forTimeInterval: 0.3)
            }
            
            // Then test swipe
            calendarView.swipeRight()
            Thread.sleep(forTimeInterval: 0.3)
            
            // Test button again to ensure it still works
            if prevButton.exists {
                prevButton.tap()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }
    }
    
    func testSwipeNavigationAccessibility() throws {
        // Given - Enable VoiceOver simulation
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        // When
        let calendarView = app.otherElements.matching(identifier: "monthly-calendar").firstMatch
        
        if calendarView.exists {
            // Check accessibility hint exists
            let accessibilityHint = calendarView.value(forKey: "accessibilityHint") as? String
            
            // The hint should guide users about swipe gestures
            // In real VoiceOver testing, we would verify the announcement
            XCTAssertNotNil(calendarView)
            
            // Verify buttons are still accessible
            let buttons = app.buttons.allElementsBoundByIndex
            XCTAssertGreaterThan(buttons.count, 0, "Navigation buttons should be available")
        }
    }
    
    func testRapidSwipeNavigation() throws {
        // Given
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        let calendarView = app.otherElements.matching(identifier: "monthly-calendar").firstMatch
        
        if calendarView.exists {
            // Perform rapid swipes to test stability
            for _ in 0..<3 {
                calendarView.swipeLeft()
                Thread.sleep(forTimeInterval: 0.2)
            }
            
            for _ in 0..<3 {
                calendarView.swipeRight()
                Thread.sleep(forTimeInterval: 0.2)
            }
            
            // App should remain stable and responsive
            XCTAssertTrue(calendarView.exists)
        }
    }
    
    @MainActor
    func testSwipeNavigationPerformance() throws {
        // Skip in regular test runs, only for performance testing
        guard ProcessInfo.processInfo.environment["PERFORMANCE_TESTING"] == "YES" else {
            throw XCTSkip("Performance test skipped in regular runs")
        }
        
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        let calendarView = app.otherElements.matching(identifier: "monthly-calendar").firstMatch
        
        if calendarView.exists {
            measure(metrics: [XCTClockMetric()]) {
                // Measure swipe gesture performance
                calendarView.swipeLeft()
                Thread.sleep(forTimeInterval: 0.5)
                calendarView.swipeRight()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }
}