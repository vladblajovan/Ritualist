//
//  HabitsViewModelTests.swift
//  Ritualist
//
//  Created by Claude on 01.08.2025.
//

import XCTest
import Combine
@testable import Ritualist

@MainActor
final class HabitsViewModelTests: XCTestCase {
    
    private var viewModel: HabitsViewModel!
    private var mockGetAllHabits: MockGetAllHabitsUseCase!
    private var mockCreateHabit: MockCreateHabitUseCase!
    private var mockUpdateHabit: MockUpdateHabitUseCase!
    private var mockDeleteHabit: MockDeleteHabitUseCase!
    private var mockToggleHabitActiveStatus: MockToggleHabitActiveStatusUseCase!
    private var refreshTrigger: RefreshTrigger!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        
        // Create mocks
        mockGetAllHabits = MockGetAllHabitsUseCase()
        mockCreateHabit = MockCreateHabitUseCase()
        mockUpdateHabit = MockUpdateHabitUseCase()
        mockDeleteHabit = MockDeleteHabitUseCase()
        mockToggleHabitActiveStatus = MockToggleHabitActiveStatusUseCase()
        refreshTrigger = RefreshTrigger()
        cancellables = Set<AnyCancellable>()
        
        // Create view model
        viewModel = HabitsViewModel(
            getAllHabits: mockGetAllHabits,
            createHabit: mockCreateHabit,
            updateHabit: mockUpdateHabit,
            deleteHabit: mockDeleteHabit,
            toggleHabitActiveStatus: mockToggleHabitActiveStatus,
            refreshTrigger: refreshTrigger
        )
    }
    
    override func tearDown() {
        cancellables.removeAll()
        viewModel = nil
        refreshTrigger = nil
        mockGetAllHabits = nil
        mockCreateHabit = nil
        mockUpdateHabit = nil
        mockDeleteHabit = nil
        mockToggleHabitActiveStatus = nil
        super.tearDown()
    }
    
    // MARK: - Create Habit Tests
    
    func testCreateHabitTriggersHabitCountRefresh() async {
        // Given
        let habit = createTestHabit()
        mockCreateHabit.shouldSucceed = true
        mockGetAllHabits.habitsToReturn = [habit]
        
        var habitCountRefreshTriggered = false
        refreshTrigger.$habitCountNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh {
                    habitCountRefreshTriggered = true
                }
            }
            .store(in: &cancellables)
        
        // When
        let success = await viewModel.create(habit)
        
        // Then
        XCTAssertTrue(success, "Create should succeed")
        XCTAssertTrue(habitCountRefreshTriggered, "Create habit should trigger habit count refresh")
        XCTAssertTrue(mockCreateHabit.executeWasCalled, "Create use case should be called")
        XCTAssertTrue(mockGetAllHabits.executeWasCalled, "Get all habits should be called for refresh")
    }
    
    func testCreateHabitFailureDoesNotTriggerRefresh() async {
        // Given
        let habit = createTestHabit()
        mockCreateHabit.shouldSucceed = false
        
        var habitCountRefreshTriggered = false
        refreshTrigger.$habitCountNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh {
                    habitCountRefreshTriggered = true
                }
            }
            .store(in: &cancellables)
        
        // When
        let success = await viewModel.create(habit)
        
        // Then
        XCTAssertFalse(success, "Create should fail")
        XCTAssertFalse(habitCountRefreshTriggered, "Failed create should not trigger refresh")
        XCTAssertTrue(mockCreateHabit.executeWasCalled, "Create use case should be called")
        XCTAssertFalse(mockGetAllHabits.executeWasCalled, "Get all habits should not be called on failure")
    }
    
    // MARK: - Delete Habit Tests
    
    func testDeleteHabitTriggersHabitCountRefresh() async {
        // Given
        let habitId = UUID()
        mockDeleteHabit.shouldSucceed = true
        mockGetAllHabits.habitsToReturn = []
        
        var habitCountRefreshTriggered = false
        refreshTrigger.$habitCountNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh {
                    habitCountRefreshTriggered = true
                }
            }
            .store(in: &cancellables)
        
        // When
        let success = await viewModel.delete(id: habitId)
        
        // Then
        XCTAssertTrue(success, "Delete should succeed")
        XCTAssertTrue(habitCountRefreshTriggered, "Delete habit should trigger habit count refresh")
        XCTAssertTrue(mockDeleteHabit.executeWasCalled, "Delete use case should be called")
        XCTAssertEqual(mockDeleteHabit.lastDeletedId, habitId, "Correct habit ID should be deleted")
        XCTAssertTrue(mockGetAllHabits.executeWasCalled, "Get all habits should be called for refresh")
    }
    
    func testDeleteHabitFailureDoesNotTriggerRefresh() async {
        // Given
        let habitId = UUID()
        mockDeleteHabit.shouldSucceed = false
        
        var habitCountRefreshTriggered = false
        refreshTrigger.$habitCountNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh {
                    habitCountRefreshTriggered = true
                }
            }
            .store(in: &cancellables)
        
        // When
        let success = await viewModel.delete(id: habitId)
        
        // Then
        XCTAssertFalse(success, "Delete should fail")
        XCTAssertFalse(habitCountRefreshTriggered, "Failed delete should not trigger refresh")
        XCTAssertTrue(mockDeleteHabit.executeWasCalled, "Delete use case should be called")
    }
    
    // MARK: - Toggle Active Status Tests
    
    func testToggleActiveStatusDoesNotTriggerHabitCountRefresh() async {
        // Given - Toggle should not trigger habit count refresh (count doesn't change)
        let habitId = UUID()
        let toggledHabit = createTestHabit(id: habitId, isActive: false)
        mockToggleHabitActiveStatus.habitToReturn = toggledHabit
        mockGetAllHabits.habitsToReturn = [toggledHabit]
        
        var habitCountRefreshTriggered = false
        refreshTrigger.$habitCountNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh {
                    habitCountRefreshTriggered = true
                }
            }
            .store(in: &cancellables)
        
        // When
        let success = await viewModel.toggleActiveStatus(id: habitId)
        
        // Then
        XCTAssertTrue(success, "Toggle should succeed")
        XCTAssertFalse(habitCountRefreshTriggered, "Toggle active status should not trigger habit count refresh")
        XCTAssertTrue(mockToggleHabitActiveStatus.executeWasCalled, "Toggle use case should be called")
        XCTAssertTrue(mockGetAllHabits.executeWasCalled, "Get all habits should be called for refresh")
    }
    
    // MARK: - Update Habit Tests
    
    func testUpdateHabitDoesNotTriggerHabitCountRefresh() async {
        // Given - Update should not trigger habit count refresh (count doesn't change)
        let habit = createTestHabit()
        mockUpdateHabit.shouldSucceed = true
        mockGetAllHabits.habitsToReturn = [habit]
        
        var habitCountRefreshTriggered = false
        refreshTrigger.$habitCountNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh {
                    habitCountRefreshTriggered = true
                }
            }
            .store(in: &cancellables)
        
        // When
        let success = await viewModel.update(habit)
        
        // Then
        XCTAssertTrue(success, "Update should succeed")
        XCTAssertFalse(habitCountRefreshTriggered, "Update habit should not trigger habit count refresh")
        XCTAssertTrue(mockUpdateHabit.executeWasCalled, "Update use case should be called")
        XCTAssertTrue(mockGetAllHabits.executeWasCalled, "Get all habits should be called for refresh")
    }
    
    // MARK: - Refresh Trigger Observation Tests
    
    func testViewModelRespondsToHabitCountRefreshTrigger() async {
        // Given
        let habits = [createTestHabit(), createTestHabit()]
        mockGetAllHabits.habitsToReturn = habits
        
        // When - External trigger (simulating another component triggering refresh)
        refreshTrigger.triggerHabitCountRefresh()
        
        // Give the async observation time to process
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Then
        XCTAssertTrue(mockGetAllHabits.executeWasCalled, "ViewModel should respond to external habit count refresh trigger")
        XCTAssertEqual(viewModel.items.count, habits.count, "Items should be updated from the refresh")
        XCTAssertFalse(refreshTrigger.habitCountNeedsRefresh, "Refresh trigger should be reset after handling")
    }
    
    // MARK: - State Management Tests
    
    func testLoadingStatesWork() async {
        // Given
        mockGetAllHabits.habitsToReturn = [createTestHabit()]
        mockGetAllHabits.simulateDelay = true
        XCTAssertFalse(viewModel.isLoading)
        
        // When
        let loadTask = Task {
            await viewModel.load()
        }
        
        // Give the task a moment to start and set isLoading = true
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 second
        
        // Then - loading state should be true during load
        XCTAssertTrue(viewModel.isLoading, "Should be loading during load operation")
        
        await loadTask.value
        
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after load completes")
        XCTAssertEqual(viewModel.items.count, 1, "Should have loaded items")
    }
    
    // MARK: - Helper Methods
    
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

// MARK: - Mock Use Cases

class MockGetAllHabitsUseCase: GetAllHabitsUseCase {
    var executeWasCalled = false
    var habitsToReturn: [Habit] = []
    var shouldThrowError = false
    var simulateDelay = false
    var delayNanoseconds: UInt64 = 100_000_000 // 0.1 second
    
    func execute() async throws -> [Habit] {
        executeWasCalled = true
        
        if simulateDelay {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }
        
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: nil)
        }
        return habitsToReturn
    }
}

class MockCreateHabitUseCase: CreateHabitUseCase {
    var executeWasCalled = false
    var lastCreatedHabit: Habit?
    var shouldSucceed = true
    
    func execute(_ habit: Habit) async throws {
        executeWasCalled = true
        lastCreatedHabit = habit
        if !shouldSucceed {
            throw NSError(domain: "MockError", code: 1, userInfo: nil)
        }
    }
}

class MockUpdateHabitUseCase: UpdateHabitUseCase {
    var executeWasCalled = false
    var lastUpdatedHabit: Habit?
    var shouldSucceed = true
    
    func execute(_ habit: Habit) async throws {
        executeWasCalled = true
        lastUpdatedHabit = habit
        if !shouldSucceed {
            throw NSError(domain: "MockError", code: 1, userInfo: nil)
        }
    }
}

class MockDeleteHabitUseCase: DeleteHabitUseCase {
    var executeWasCalled = false
    var lastDeletedId: UUID?
    var shouldSucceed = true
    
    func execute(id: UUID) async throws {
        executeWasCalled = true
        lastDeletedId = id
        if !shouldSucceed {
            throw NSError(domain: "MockError", code: 1, userInfo: nil)
        }
    }
}

class MockToggleHabitActiveStatusUseCase: ToggleHabitActiveStatusUseCase {
    var executeWasCalled = false
    var lastToggledId: UUID?
    var habitToReturn: Habit?
    var shouldSucceed = true
    
    func execute(id: UUID) async throws -> Habit {
        executeWasCalled = true
        lastToggledId = id
        if !shouldSucceed {
            throw NSError(domain: "MockError", code: 1, userInfo: nil)
        }
        guard let habit = habitToReturn else {
            throw NSError(domain: "MockError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No habit configured to return"])
        }
        return habit
    }
}