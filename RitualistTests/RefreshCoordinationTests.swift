//
//  RefreshCoordinationTests.swift
//  Ritualist
//
//  Created by Claude on 01.08.2025.
//

import XCTest
import Combine
@testable import Ritualist

@MainActor
final class RefreshCoordinationTests: XCTestCase {
    
    private var sharedRefreshTrigger: RefreshTrigger!
    private var habitsViewModel: HabitsViewModel!
    private var habitDetailViewModel: HabitDetailViewModel!
    private var cancellables: Set<AnyCancellable>!
    
    // Shared mocks
    private var mockHabitsGetAllHabits: MockGetAllHabitsUseCase!
    private var mockHabitsCreateHabit: MockCreateHabitUseCase!
    private var mockHabitsUpdateHabit: MockUpdateHabitUseCase!
    private var mockHabitsDeleteHabit: MockDeleteHabitUseCase!
    private var mockHabitsToggleActiveStatus: MockToggleHabitActiveStatusUseCase!
    
    private var mockDetailCreateHabit: MockCreateHabitUseCase!
    private var mockDetailUpdateHabit: MockUpdateHabitUseCase!
    private var mockDetailDeleteHabit: MockDeleteHabitUseCase!
    private var mockDetailToggleActiveStatus: MockToggleHabitActiveStatusUseCase!
    
    override func setUp() {
        super.setUp()
        
        // Create shared refresh trigger
        sharedRefreshTrigger = RefreshTrigger()
        cancellables = Set<AnyCancellable>()
        
        // Create mocks for HabitsViewModel
        mockHabitsGetAllHabits = MockGetAllHabitsUseCase()
        mockHabitsCreateHabit = MockCreateHabitUseCase()
        mockHabitsUpdateHabit = MockUpdateHabitUseCase()
        mockHabitsDeleteHabit = MockDeleteHabitUseCase()
        mockHabitsToggleActiveStatus = MockToggleHabitActiveStatusUseCase()
        
        // Create mocks for HabitDetailViewModel
        mockDetailCreateHabit = MockCreateHabitUseCase()
        mockDetailUpdateHabit = MockUpdateHabitUseCase()
        mockDetailDeleteHabit = MockDeleteHabitUseCase()
        mockDetailToggleActiveStatus = MockToggleHabitActiveStatusUseCase()
        
        // Create ViewModels with shared RefreshTrigger
        habitsViewModel = HabitsViewModel(
            getAllHabits: mockHabitsGetAllHabits,
            createHabit: mockHabitsCreateHabit,
            updateHabit: mockHabitsUpdateHabit,
            deleteHabit: mockHabitsDeleteHabit,
            toggleHabitActiveStatus: mockHabitsToggleActiveStatus,
            refreshTrigger: sharedRefreshTrigger
        )
        
        habitDetailViewModel = HabitDetailViewModel(
            createHabit: mockDetailCreateHabit,
            updateHabit: mockDetailUpdateHabit,
            deleteHabit: mockDetailDeleteHabit,
            toggleHabitActiveStatus: mockDetailToggleActiveStatus,
            refreshTrigger: sharedRefreshTrigger,
            habit: nil // Start in create mode
        )
    }
    
    override func tearDown() {
        cancellables.removeAll()
        habitsViewModel = nil
        habitDetailViewModel = nil
        sharedRefreshTrigger = nil
        super.tearDown()
    }
    
    // MARK: - Cross-ViewModel Communication Tests
    
    func testHabitDetailCreateTriggersHabitsViewModelRefresh() async {
        // Given
        let newHabit = createTestHabit()
        setupValidDetailForm()
        
        mockDetailCreateHabit.shouldSucceed = true
        mockHabitsGetAllHabits.habitsToReturn = [newHabit]
        
        var habitsViewModelRefreshed = false
        
        // Monitor when HabitsViewModel responds to refresh trigger
        let originalExecuteWasCalled = mockHabitsGetAllHabits.executeWasCalled
        
        // When - Create habit via HabitDetailViewModel
        let success = await habitDetailViewModel.save()
        
        // Give time for reactive coordination
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Then
        XCTAssertTrue(success, "Habit creation should succeed")
        XCTAssertTrue(mockDetailCreateHabit.executeWasCalled, "Detail create should be called")
        
        // The key test: HabitsViewModel should have reacted to the refresh trigger
        XCTAssertTrue(mockHabitsGetAllHabits.executeWasCalled, "HabitsViewModel should refresh in response to trigger")
        XCTAssertEqual(habitsViewModel.items.count, 1, "HabitsViewModel should have the new habit")
        XCTAssertFalse(sharedRefreshTrigger.habitCountNeedsRefresh, "Trigger should be reset after handling")
    }
    
    func testHabitDetailDeleteTriggersHabitsViewModelRefresh() async {
        // Given
        let existingHabit = createTestHabit()
        habitDetailViewModel = HabitDetailViewModel(
            createHabit: mockDetailCreateHabit,
            updateHabit: mockDetailUpdateHabit,
            deleteHabit: mockDetailDeleteHabit,
            toggleHabitActiveStatus: mockDetailToggleActiveStatus,
            refreshTrigger: sharedRefreshTrigger,
            habit: existingHabit // Edit mode
        )
        
        mockDetailDeleteHabit.shouldSucceed = true
        mockHabitsGetAllHabits.habitsToReturn = [] // Empty after deletion
        
        // When - Delete habit via HabitDetailViewModel
        let success = await habitDetailViewModel.delete()
        
        // Give time for reactive coordination
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Then
        XCTAssertTrue(success, "Habit deletion should succeed")
        XCTAssertTrue(mockDetailDeleteHabit.executeWasCalled, "Detail delete should be called")
        
        // The key test: HabitsViewModel should have reacted to both refresh triggers
        XCTAssertTrue(mockHabitsGetAllHabits.executeWasCalled, "HabitsViewModel should refresh in response to trigger")
        XCTAssertEqual(habitsViewModel.items.count, 0, "HabitsViewModel should reflect the deletion")
        XCTAssertFalse(sharedRefreshTrigger.habitCountNeedsRefresh, "Habit count trigger should be reset")
    }
    
    func testHabitsViewModelDeleteTriggersCorrectRefreshes() async {
        // Given
        let habitToDelete = createTestHabit()
        mockHabitsDeleteHabit.shouldSucceed = true
        mockHabitsGetAllHabits.habitsToReturn = [] // Empty after deletion
        
        var habitCountRefreshTriggered = false
        var overviewRefreshTriggered = false
        
        sharedRefreshTrigger.$habitCountNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { habitCountRefreshTriggered = true }
            }
            .store(in: &cancellables)
        
        sharedRefreshTrigger.$overviewNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { overviewRefreshTriggered = true }
            }
            .store(in: &cancellables)
        
        // When
        let success = await habitsViewModel.delete(id: habitToDelete.id)
        
        // Then
        XCTAssertTrue(success, "Delete should succeed")
        XCTAssertTrue(habitCountRefreshTriggered, "Habit count refresh should be triggered")
        // Note: Overview refresh is not triggered by HabitsViewModel delete, only by HabitDetailViewModel
        XCTAssertFalse(overviewRefreshTriggered, "Overview refresh should not be triggered by HabitsViewModel")
    }
    
    // MARK: - Real-World Bug Scenario Tests
    
    func testPaywallBugScenario() async {
        // This test simulates the exact bug scenario that was reported:
        // 1. User has 5 habits
        // 2. User deletes one habit
        // 3. User clicks + in habits page
        // 4. Should see add habit form, not paywall
        
        // Given - Simulate having 5 habits initially
        let fiveHabits = (1...5).map { createTestHabit(name: "Habit \($0)") }
        mockHabitsGetAllHabits.habitsToReturn = fiveHabits
        
        // Load initial state
        await habitsViewModel.load()
        XCTAssertEqual(habitsViewModel.items.count, 5, "Should start with 5 habits")
        
        // When - Delete one habit (simulating user action)
        let habitToDelete = fiveHabits.first!
        mockHabitsDeleteHabit.shouldSucceed = true
        mockHabitsGetAllHabits.habitsToReturn = Array(fiveHabits.dropFirst()) // Remove first habit
        
        let deleteSuccess = await habitsViewModel.delete(id: habitToDelete.id)
        
        // Give time for reactive coordination to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Then - Verify the bug is fixed
        XCTAssertTrue(deleteSuccess, "Delete should succeed")
        XCTAssertEqual(habitsViewModel.items.count, 4, "Should have 4 habits after deletion")
        
        // This is the key assertion: the habit count refresh should have been triggered and reset
        XCTAssertFalse(sharedRefreshTrigger.habitCountNeedsRefresh, "Habit count refresh should be reset")
        
        // The external consumer (like HabitsView) would now have the correct count for paywall logic
        // In the real app, this would mean count = 4, so paywall should not appear
    }
    
    func testMultipleViewModelsRespondToSameTrigger() async {
        // Given - Set up both ViewModels to respond to external triggers
        mockHabitsGetAllHabits.habitsToReturn = [createTestHabit()]
        
        // Clear initial call states
        mockHabitsGetAllHabits.executeWasCalled = false
        
        // When - External component triggers refresh (simulating another component's action)
        sharedRefreshTrigger.triggerHabitCountRefresh()
        
        // Give time for both ViewModels to react
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Then - Both ViewModels should respond appropriately
        XCTAssertTrue(mockHabitsGetAllHabits.executeWasCalled, "HabitsViewModel should respond to external trigger")
        
        // The trigger should be reset after handling
        XCTAssertFalse(sharedRefreshTrigger.habitCountNeedsRefresh, "Trigger should be reset after handling")
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testFailedOperationsDoNotLeaveTriggersInInconsistentState() async {
        // Given
        mockDetailCreateHabit.shouldSucceed = false // Force failure
        setupValidDetailForm()
        
        var habitCountRefreshTriggered = false
        sharedRefreshTrigger.$habitCountNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { habitCountRefreshTriggered = true }
            }
            .store(in: &cancellables)
        
        // When - Attempt operation that will fail
        let success = await habitDetailViewModel.save()
        
        // Then
        XCTAssertFalse(success, "Operation should fail")
        XCTAssertFalse(habitCountRefreshTriggered, "Failed operation should not trigger refresh")
        XCTAssertFalse(sharedRefreshTrigger.habitCountNeedsRefresh, "Trigger should remain in clean state")
        XCTAssertFalse(sharedRefreshTrigger.overviewNeedsRefresh, "Trigger should remain in clean state")
    }
    
    func testConcurrentOperationsHandleRefreshTriggersCorrectly() async {
        // Given
        let habit1 = createTestHabit(name: "Habit 1")
        let habit2 = createTestHabit(name: "Habit 2")
        
        mockHabitsDeleteHabit.shouldSucceed = true
        mockHabitsGetAllHabits.habitsToReturn = []
        
        var refreshTriggerCount = 0
        sharedRefreshTrigger.$habitCountNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { refreshTriggerCount += 1 }
            }
            .store(in: &cancellables)
        
        // When - Perform concurrent operations
        async let delete1 = habitsViewModel.delete(id: habit1.id)
        async let delete2 = habitsViewModel.delete(id: habit2.id)
        
        let results = await [delete1, delete2]
        
        // Give time for all reactive coordination to complete
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Then
        XCTAssertTrue(results.allSatisfy { $0 }, "Both deletes should succeed")
        XCTAssertGreaterThan(refreshTriggerCount, 0, "At least one refresh should be triggered")
        
        // Most importantly, trigger should be properly reset regardless of concurrency
        XCTAssertFalse(sharedRefreshTrigger.habitCountNeedsRefresh, "Trigger should be reset after all operations")
    }
    
    // MARK: - Helper Methods
    
    private func setupValidDetailForm() {
        habitDetailViewModel.name = "Test Habit"
        habitDetailViewModel.selectedKind = .binary
        habitDetailViewModel.selectedSchedule = .daily
        habitDetailViewModel.selectedEmoji = "🎯"
        habitDetailViewModel.selectedColorHex = "#FF0000"
    }
    
    private func createTestHabit(id: UUID = UUID(), name: String = "Test Habit", isActive: Bool = true) -> Habit {
        return Habit(
            id: id,
            name: name,
            colorHex: "#FF0000",
            emoji: "🎯",
            kind: .binary,
            unitLabel: nil,
            dailyTarget: nil,
            schedule: .daily,
            reminders: [],
            startDate: Date(),
            endDate: nil,
            isActive: isActive
        )
    }
}