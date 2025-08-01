//
//  RefreshTriggerTests.swift
//  Ritualist
//
//  Created by Claude on 01.08.2025.
//

import XCTest
import Combine
@testable import Ritualist

@MainActor
final class RefreshTriggerTests: XCTestCase {
    
    private var refreshTrigger: RefreshTrigger!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        refreshTrigger = RefreshTrigger()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        refreshTrigger = nil
        super.tearDown()
    }
    
    // MARK: - Overview Refresh Tests
    
    func testOverviewRefreshInitialState() {
        XCTAssertFalse(refreshTrigger.overviewNeedsRefresh, "Initial overview refresh state should be false")
    }
    
    func testTriggerOverviewRefresh() {
        // When
        refreshTrigger.triggerOverviewRefresh()
        
        // Then
        XCTAssertTrue(refreshTrigger.overviewNeedsRefresh, "Overview refresh should be triggered")
    }
    
    func testResetOverviewRefresh() {
        // Given
        refreshTrigger.triggerOverviewRefresh()
        XCTAssertTrue(refreshTrigger.overviewNeedsRefresh)
        
        // When
        refreshTrigger.resetOverviewRefresh()
        
        // Then
        XCTAssertFalse(refreshTrigger.overviewNeedsRefresh, "Overview refresh should be reset")
    }
    
    func testOverviewRefreshPublishedUpdates() {
        var receivedValues: [Bool] = []
        let expectation = expectation(description: "Published values received")
        expectation.expectedFulfillmentCount = 3 // Initial + trigger + reset
        
        // Subscribe to published changes
        refreshTrigger.$overviewNeedsRefresh
            .sink { value in
                receivedValues.append(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Trigger actions
        refreshTrigger.triggerOverviewRefresh()
        refreshTrigger.resetOverviewRefresh()
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(receivedValues, [false, true, false], "Published updates should follow expected sequence")
    }
    
    // MARK: - Habit Count Refresh Tests
    
    func testHabitCountRefreshInitialState() {
        XCTAssertFalse(refreshTrigger.habitCountNeedsRefresh, "Initial habit count refresh state should be false")
    }
    
    func testTriggerHabitCountRefresh() {
        // When
        refreshTrigger.triggerHabitCountRefresh()
        
        // Then
        XCTAssertTrue(refreshTrigger.habitCountNeedsRefresh, "Habit count refresh should be triggered")
    }
    
    func testResetHabitCountRefresh() {
        // Given
        refreshTrigger.triggerHabitCountRefresh()
        XCTAssertTrue(refreshTrigger.habitCountNeedsRefresh)
        
        // When
        refreshTrigger.resetHabitCountRefresh()
        
        // Then
        XCTAssertFalse(refreshTrigger.habitCountNeedsRefresh, "Habit count refresh should be reset")
    }
    
    func testHabitCountRefreshPublishedUpdates() {
        var receivedValues: [Bool] = []
        let expectation = expectation(description: "Published values received")
        expectation.expectedFulfillmentCount = 3 // Initial + trigger + reset
        
        // Subscribe to published changes
        refreshTrigger.$habitCountNeedsRefresh
            .sink { value in
                receivedValues.append(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Trigger actions
        refreshTrigger.triggerHabitCountRefresh()
        refreshTrigger.resetHabitCountRefresh()
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(receivedValues, [false, true, false], "Published updates should follow expected sequence")
    }
    
    // MARK: - Independent Operation Tests
    
    func testBothRefreshTriggersOperateIndependently() {
        // When - trigger overview only
        refreshTrigger.triggerOverviewRefresh()
        
        // Then
        XCTAssertTrue(refreshTrigger.overviewNeedsRefresh, "Overview refresh should be triggered")
        XCTAssertFalse(refreshTrigger.habitCountNeedsRefresh, "Habit count refresh should remain false")
        
        // When - trigger habit count only
        refreshTrigger.resetOverviewRefresh()
        refreshTrigger.triggerHabitCountRefresh()
        
        // Then
        XCTAssertFalse(refreshTrigger.overviewNeedsRefresh, "Overview refresh should remain reset")
        XCTAssertTrue(refreshTrigger.habitCountNeedsRefresh, "Habit count refresh should be triggered")
    }
    
    func testMultipleTriggersOnSameFlag() {
        // Given
        refreshTrigger.triggerOverviewRefresh()
        XCTAssertTrue(refreshTrigger.overviewNeedsRefresh)
        
        // When - trigger again
        refreshTrigger.triggerOverviewRefresh()
        
        // Then - should remain true
        XCTAssertTrue(refreshTrigger.overviewNeedsRefresh, "Multiple triggers should not affect state")
        
        // When - reset once
        refreshTrigger.resetOverviewRefresh()
        
        // Then - should be false
        XCTAssertFalse(refreshTrigger.overviewNeedsRefresh, "Single reset should clear state")
    }
    
    func testSimultaneousTriggers() {
        // When - trigger both simultaneously
        refreshTrigger.triggerOverviewRefresh()
        refreshTrigger.triggerHabitCountRefresh()
        
        // Then
        XCTAssertTrue(refreshTrigger.overviewNeedsRefresh, "Overview refresh should be triggered")
        XCTAssertTrue(refreshTrigger.habitCountNeedsRefresh, "Habit count refresh should be triggered")
        
        // When - reset one
        refreshTrigger.resetOverviewRefresh()
        
        // Then - other should remain
        XCTAssertFalse(refreshTrigger.overviewNeedsRefresh, "Overview refresh should be reset")
        XCTAssertTrue(refreshTrigger.habitCountNeedsRefresh, "Habit count refresh should remain triggered")
    }
    
    // MARK: - Reactive Flow Tests
    
    func testTypicalRefreshFlow() {
        var overviewUpdates: [Bool] = []
        var habitCountUpdates: [Bool] = []
        
        let overviewExpectation = expectation(description: "Overview updates")
        overviewExpectation.expectedFulfillmentCount = 3
        
        let habitCountExpectation = expectation(description: "Habit count updates")
        habitCountExpectation.expectedFulfillmentCount = 3
        
        // Set up subscribers
        refreshTrigger.$overviewNeedsRefresh
            .sink { value in
                overviewUpdates.append(value)
                overviewExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        refreshTrigger.$habitCountNeedsRefresh
            .sink { value in
                habitCountUpdates.append(value)
                habitCountExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Simulate typical flow: trigger -> handle -> reset
        refreshTrigger.triggerOverviewRefresh()
        refreshTrigger.triggerHabitCountRefresh()
        
        // Simulate handling the refresh
        refreshTrigger.resetOverviewRefresh()
        refreshTrigger.resetHabitCountRefresh()
        
        wait(for: [overviewExpectation, habitCountExpectation], timeout: 1.0)
        
        XCTAssertEqual(overviewUpdates, [false, true, false], "Overview should follow trigger-reset cycle")
        XCTAssertEqual(habitCountUpdates, [false, true, false], "Habit count should follow trigger-reset cycle")
    }
    
    // MARK: - Thread Safety Tests
    
    func testMainActorCompliance() {
        // This test ensures all methods run on MainActor
        // The @MainActor annotation on the class ensures this
        // We can verify by checking that we can access published properties directly
        
        refreshTrigger.triggerOverviewRefresh()
        let overviewState = refreshTrigger.overviewNeedsRefresh
        
        refreshTrigger.triggerHabitCountRefresh()
        let habitCountState = refreshTrigger.habitCountNeedsRefresh
        
        XCTAssertTrue(overviewState, "Should be able to access state on MainActor")
        XCTAssertTrue(habitCountState, "Should be able to access state on MainActor")
    }
}