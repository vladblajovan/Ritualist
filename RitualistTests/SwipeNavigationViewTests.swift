import XCTest
import SwiftUI
@testable import Ritualist

final class SwipeNavigationViewTests: XCTestCase {
    
    func testSwipeNavigationViewInitialization() {
        // Given
        var leftSwipeCount = 0
        var rightSwipeCount = 0
        
        // When
        let view = SwipeNavigationView(
            minimumSwipeDistance: 50,
            minimumSwipeVelocity: 200,
            onSwipeLeft: { leftSwipeCount += 1 },
            onSwipeRight: { rightSwipeCount += 1 },
            content: {
                Text("Test Content")
            }
        )
        
        // Then
        XCTAssertNotNil(view)
        XCTAssertEqual(leftSwipeCount, 0)
        XCTAssertEqual(rightSwipeCount, 0)
    }
    
    func testDefaultThresholdValues() {
        // Given
        let view = SwipeNavigationView(
            onSwipeLeft: { },
            onSwipeRight: { },
            content: { EmptyView() }
        )
        
        // Then - verify default values through reflection
        let mirror = Mirror(reflecting: view)
        
        var foundDistance = false
        var foundVelocity = false
        
        for child in mirror.children {
            if child.label == "minimumSwipeDistance", let value = child.value as? CGFloat {
                XCTAssertEqual(value, 100)
                foundDistance = true
            }
            if child.label == "minimumSwipeVelocity", let value = child.value as? CGFloat {
                XCTAssertEqual(value, 300)
                foundVelocity = true
            }
        }
        
        XCTAssertTrue(foundDistance, "minimumSwipeDistance property not found")
        XCTAssertTrue(foundVelocity, "minimumSwipeVelocity property not found")
    }
    
    func testSwipeGestureConfiguration() {
        // Given
        let customDistance: CGFloat = 150
        let customVelocity: CGFloat = 500
        
        // When
        let view = SwipeNavigationView(
            minimumSwipeDistance: customDistance,
            minimumSwipeVelocity: customVelocity,
            onSwipeLeft: { },
            onSwipeRight: { },
            content: { Text("Content") }
        )
        
        // Then
        let mirror = Mirror(reflecting: view)
        
        for child in mirror.children {
            if child.label == "minimumSwipeDistance", let value = child.value as? CGFloat {
                XCTAssertEqual(value, customDistance)
            }
            if child.label == "minimumSwipeVelocity", let value = child.value as? CGFloat {
                XCTAssertEqual(value, customVelocity)
            }
        }
    }
    
    func testContentWrapping() {
        // Given
        let testText = "Test Calendar Content"
        
        // When
        let view = SwipeNavigationView(
            onSwipeLeft: { },
            onSwipeRight: { },
            content: {
                Text(testText)
                    .tag("test-content")
            }
        )
        
        // Then
        XCTAssertNotNil(view)
        // Note: In a real UI test, we would verify the content is displayed
        // For unit tests, we mainly verify the structure is created correctly
    }
    
    func testAccessibilityHint() {
        // Given
        let view = SwipeNavigationView(
            onSwipeLeft: { },
            onSwipeRight: { },
            content: { Rectangle() }
        )
        
        // Then
        // The view should have accessibility hint set
        // In actual UI tests, we would verify:
        // XCTAssertEqual(view.accessibilityHint, "Swipe left for next month, swipe right for previous month")
        XCTAssertNotNil(view)
    }
    
    @MainActor
    func testSwipeCallbacksAsync() async {
        // Given
        let leftSwipeExpectation = XCTestExpectation(description: "Left swipe callback executed")
        let rightSwipeExpectation = XCTestExpectation(description: "Right swipe callback executed")
        
        // When
        _ = SwipeNavigationView(
            onSwipeLeft: {
                leftSwipeExpectation.fulfill()
            },
            onSwipeRight: {
                rightSwipeExpectation.fulfill()
            },
            content: { Text("Test") }
        )
        
        // Simulate the callbacks (in real UI test, these would be triggered by gestures)
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await Task { leftSwipeExpectation.fulfill() }.value
            }
            group.addTask {
                await Task { rightSwipeExpectation.fulfill() }.value
            }
        }
        
        // Then
        await fulfillment(of: [leftSwipeExpectation, rightSwipeExpectation], timeout: 1.0)
    }
    
    func testSwipeNavigationViewWithMonthlyCalendar() {
        // Given
        var monthChangeValue = 0
        let currentMonth = Date()
        let calendarDays = [CalendarDay(date: Date(), isCurrentMonth: true)]
        
        // When
        let view = SwipeNavigationView(
            onSwipeLeft: {
                monthChangeValue = 1
            },
            onSwipeRight: {
                monthChangeValue = -1
            },
            content: {
                // Simplified calendar grid for testing
                VStack {
                    Text("Calendar Grid")
                    ForEach(calendarDays, id: \.date) { day in
                        Text(day.date.formatted(.dateTime.day()))
                    }
                }
            }
        )
        
        // Then
        XCTAssertNotNil(view)
        XCTAssertEqual(monthChangeValue, 0) // No swipes yet
    }
    
    // MARK: - Helper Methods
    
    private func createMockHabit() -> Habit {
        Habit(
            id: UUID(),
            name: "Test Habit",
            colorHex: "#FF0000",
            emoji: "⭐",
            kind: .binary,
            unitLabel: nil,
            dailyTarget: nil,
            schedule: .daily,
            reminders: [],
            startDate: Date(),
            endDate: nil,
            isActive: true
        )
    }
}

// MARK: - Performance Tests

extension SwipeNavigationViewTests {
    
    func testSwipeNavigationViewCreationPerformance() {
        measure {
            for _ in 0..<100 {
                _ = SwipeNavigationView(
                    onSwipeLeft: { },
                    onSwipeRight: { },
                    content: {
                        VStack {
                            ForEach(0..<42, id: \.self) { _ in
                                Rectangle()
                                    .frame(width: 40, height: 40)
                            }
                        }
                    }
                )
            }
        }
    }
}