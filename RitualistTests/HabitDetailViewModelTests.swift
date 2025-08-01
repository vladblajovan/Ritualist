//
//  HabitDetailViewModelTests.swift
//  Ritualist
//
//  Created by Claude on 01.08.2025.
//

import XCTest
import Combine
@testable import Ritualist

@MainActor
final class HabitDetailViewModelTests: XCTestCase {
    
    private var viewModel: HabitDetailViewModel!
    private var mockCreateHabit: MockCreateHabitUseCase!
    private var mockUpdateHabit: MockUpdateHabitUseCase!
    private var mockDeleteHabit: MockDeleteHabitUseCase!
    private var mockToggleHabitActiveStatus: MockToggleHabitActiveStatusUseCase!
    private var refreshTrigger: RefreshTrigger!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        
        // Create mocks
        mockCreateHabit = MockCreateHabitUseCase()
        mockUpdateHabit = MockUpdateHabitUseCase()
        mockDeleteHabit = MockDeleteHabitUseCase()
        mockToggleHabitActiveStatus = MockToggleHabitActiveStatusUseCase()
        refreshTrigger = RefreshTrigger()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        viewModel = nil
        refreshTrigger = nil
        mockCreateHabit = nil
        mockUpdateHabit = nil
        mockDeleteHabit = nil
        mockToggleHabitActiveStatus = nil
        super.tearDown()
    }
    
    // MARK: - Create Mode Tests
    
    func testSaveNewHabitTriggersBothRefreshes() async {
        // Given - Create mode (no existing habit)
        createViewModel(existingHabit: nil)
        setupValidForm()
        mockCreateHabit.shouldSucceed = true
        
        var overviewRefreshTriggered = false
        var habitCountRefreshTriggered = false
        
        refreshTrigger.$overviewNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { overviewRefreshTriggered = true }
            }
            .store(in: &cancellables)
        
        refreshTrigger.$habitCountNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { habitCountRefreshTriggered = true }
            }
            .store(in: &cancellables)
        
        // When
        let success = await viewModel.save()
        
        // Then
        XCTAssertTrue(success, "Save should succeed")
        XCTAssertTrue(overviewRefreshTriggered, "Creating new habit should trigger overview refresh")
        XCTAssertTrue(habitCountRefreshTriggered, "Creating new habit should trigger habit count refresh")
        XCTAssertTrue(mockCreateHabit.executeWasCalled, "Create use case should be called")
        XCTAssertFalse(mockUpdateHabit.executeWasCalled, "Update use case should not be called")
    }
    
    func testSaveNewHabitFailureDoesNotTriggerRefreshes() async {
        // Given
        createViewModel(existingHabit: nil)
        setupValidForm()
        mockCreateHabit.shouldSucceed = false
        
        var overviewRefreshTriggered = false
        var habitCountRefreshTriggered = false
        
        refreshTrigger.$overviewNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { overviewRefreshTriggered = true }
            }
            .store(in: &cancellables)
        
        refreshTrigger.$habitCountNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { habitCountRefreshTriggered = true }
            }
            .store(in: &cancellables)
        
        // When
        let success = await viewModel.save()
        
        // Then
        XCTAssertFalse(success, "Save should fail")
        XCTAssertFalse(overviewRefreshTriggered, "Failed create should not trigger overview refresh")
        XCTAssertFalse(habitCountRefreshTriggered, "Failed create should not trigger habit count refresh")
        XCTAssertTrue(mockCreateHabit.executeWasCalled, "Create use case should be called")
    }
    
    // MARK: - Edit Mode Tests
    
    func testSaveExistingHabitTriggersOnlyOverviewRefresh() async {
        // Given - Edit mode (existing habit)
        let existingHabit = createTestHabit()
        createViewModel(existingHabit: existingHabit)
        mockUpdateHabit.shouldSucceed = true
        
        var overviewRefreshTriggered = false
        var habitCountRefreshTriggered = false
        
        refreshTrigger.$overviewNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { overviewRefreshTriggered = true }
            }
            .store(in: &cancellables)
        
        refreshTrigger.$habitCountNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { habitCountRefreshTriggered = true }
            }
            .store(in: &cancellables)
        
        // When
        let success = await viewModel.save()
        
        // Then
        XCTAssertTrue(success, "Save should succeed")
        XCTAssertTrue(overviewRefreshTriggered, "Updating habit should trigger overview refresh")
        XCTAssertFalse(habitCountRefreshTriggered, "Updating habit should not trigger habit count refresh")
        XCTAssertFalse(mockCreateHabit.executeWasCalled, "Create use case should not be called")
        XCTAssertTrue(mockUpdateHabit.executeWasCalled, "Update use case should be called")
    }
    
    func testSaveExistingHabitFailureDoesNotTriggerRefreshes() async {
        // Given
        let existingHabit = createTestHabit()
        createViewModel(existingHabit: existingHabit)
        mockUpdateHabit.shouldSucceed = false
        
        var overviewRefreshTriggered = false
        var habitCountRefreshTriggered = false
        
        refreshTrigger.$overviewNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { overviewRefreshTriggered = true }
            }
            .store(in: &cancellables)
        
        refreshTrigger.$habitCountNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { habitCountRefreshTriggered = true }
            }
            .store(in: &cancellables)
        
        // When
        let success = await viewModel.save()
        
        // Then
        XCTAssertFalse(success, "Save should fail")
        XCTAssertFalse(overviewRefreshTriggered, "Failed update should not trigger overview refresh")
        XCTAssertFalse(habitCountRefreshTriggered, "Failed update should not trigger habit count refresh")
        XCTAssertTrue(mockUpdateHabit.executeWasCalled, "Update use case should be called")
    }
    
    // MARK: - Delete Tests
    
    func testDeleteHabitTriggersBothRefreshes() async {
        // Given
        let existingHabit = createTestHabit()
        createViewModel(existingHabit: existingHabit)
        mockDeleteHabit.shouldSucceed = true
        
        var overviewRefreshTriggered = false
        var habitCountRefreshTriggered = false
        
        refreshTrigger.$overviewNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { overviewRefreshTriggered = true }
            }
            .store(in: &cancellables)
        
        refreshTrigger.$habitCountNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { habitCountRefreshTriggered = true }
            }
            .store(in: &cancellables)
        
        // When
        let success = await viewModel.delete()
        
        // Then
        XCTAssertTrue(success, "Delete should succeed")
        XCTAssertTrue(overviewRefreshTriggered, "Deleting habit should trigger overview refresh")
        XCTAssertTrue(habitCountRefreshTriggered, "Deleting habit should trigger habit count refresh")
        XCTAssertTrue(mockDeleteHabit.executeWasCalled, "Delete use case should be called")
        XCTAssertEqual(mockDeleteHabit.lastDeletedId, existingHabit.id, "Correct habit should be deleted")
    }
    
    func testDeleteHabitFailureDoesNotTriggerRefreshes() async {
        // Given
        let existingHabit = createTestHabit()
        createViewModel(existingHabit: existingHabit)
        mockDeleteHabit.shouldSucceed = false
        
        var overviewRefreshTriggered = false
        var habitCountRefreshTriggered = false
        
        refreshTrigger.$overviewNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { overviewRefreshTriggered = true }
            }
            .store(in: &cancellables)
        
        refreshTrigger.$habitCountNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { habitCountRefreshTriggered = true }
            }
            .store(in: &cancellables)
        
        // When
        let success = await viewModel.delete()
        
        // Then
        XCTAssertFalse(success, "Delete should fail")
        XCTAssertFalse(overviewRefreshTriggered, "Failed delete should not trigger overview refresh")
        XCTAssertFalse(habitCountRefreshTriggered, "Failed delete should not trigger habit count refresh")
        XCTAssertTrue(mockDeleteHabit.executeWasCalled, "Delete use case should be called")
    }
    
    func testDeleteWithoutOriginalHabitReturnsFalse() async {
        // Given - No original habit
        createViewModel(existingHabit: nil)
        
        // When
        let success = await viewModel.delete()
        
        // Then
        XCTAssertFalse(success, "Delete without original habit should return false")
        XCTAssertFalse(mockDeleteHabit.executeWasCalled, "Delete use case should not be called")
    }
    
    // MARK: - Toggle Active Status Tests
    
    func testToggleActiveStatusTriggersOnlyOverviewRefresh() async {
        // Given
        let existingHabit = createTestHabit()
        createViewModel(existingHabit: existingHabit)
        let toggledHabit = createTestHabit(id: existingHabit.id, isActive: false)
        mockToggleHabitActiveStatus.habitToReturn = toggledHabit
        
        var overviewRefreshTriggered = false
        var habitCountRefreshTriggered = false
        
        refreshTrigger.$overviewNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { overviewRefreshTriggered = true }
            }
            .store(in: &cancellables)
        
        refreshTrigger.$habitCountNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { habitCountRefreshTriggered = true }
            }
            .store(in: &cancellables)
        
        // When
        let success = await viewModel.toggleActiveStatus()
        
        // Then
        XCTAssertTrue(success, "Toggle should succeed")
        XCTAssertTrue(overviewRefreshTriggered, "Toggle active status should trigger overview refresh")
        XCTAssertFalse(habitCountRefreshTriggered, "Toggle active status should not trigger habit count refresh")
        XCTAssertTrue(mockToggleHabitActiveStatus.executeWasCalled, "Toggle use case should be called")
        XCTAssertEqual(viewModel.isActive, false, "ViewModel state should be updated")
    }
    
    func testToggleActiveStatusFailureDoesNotTriggerRefreshes() async {
        // Given
        let existingHabit = createTestHabit()
        createViewModel(existingHabit: existingHabit)
        mockToggleHabitActiveStatus.shouldSucceed = false
        
        var overviewRefreshTriggered = false
        var habitCountRefreshTriggered = false
        
        refreshTrigger.$overviewNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { overviewRefreshTriggered = true }
            }
            .store(in: &cancellables)
        
        refreshTrigger.$habitCountNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { habitCountRefreshTriggered = true }
            }
            .store(in: &cancellables)
        
        // When
        let success = await viewModel.toggleActiveStatus()
        
        // Then
        XCTAssertFalse(success, "Toggle should fail")
        XCTAssertFalse(overviewRefreshTriggered, "Failed toggle should not trigger overview refresh")
        XCTAssertFalse(habitCountRefreshTriggered, "Failed toggle should not trigger habit count refresh")
        XCTAssertTrue(mockToggleHabitActiveStatus.executeWasCalled, "Toggle use case should be called")
    }
    
    func testToggleWithoutOriginalHabitReturnsFalse() async {
        // Given - No original habit
        createViewModel(existingHabit: nil)
        
        // When
        let success = await viewModel.toggleActiveStatus()
        
        // Then
        XCTAssertFalse(success, "Toggle without original habit should return false")
        XCTAssertFalse(mockToggleHabitActiveStatus.executeWasCalled, "Toggle use case should not be called")
    }
    
    // MARK: - Form Validation Tests
    
    func testSaveWithInvalidFormReturnsFalse() async {
        // Given
        createViewModel(existingHabit: nil)
        // Don't set up valid form - name will be empty
        
        var overviewRefreshTriggered = false
        var habitCountRefreshTriggered = false
        
        refreshTrigger.$overviewNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { overviewRefreshTriggered = true }
            }
            .store(in: &cancellables)
        
        refreshTrigger.$habitCountNeedsRefresh
            .sink { needsRefresh in
                if needsRefresh { habitCountRefreshTriggered = true }
            }
            .store(in: &cancellables)
        
        // When
        let success = await viewModel.save()
        
        // Then
        XCTAssertFalse(success, "Save with invalid form should return false")
        XCTAssertFalse(overviewRefreshTriggered, "Invalid form should not trigger overview refresh")
        XCTAssertFalse(habitCountRefreshTriggered, "Invalid form should not trigger habit count refresh")
        XCTAssertFalse(mockCreateHabit.executeWasCalled, "Create use case should not be called")
        XCTAssertFalse(mockUpdateHabit.executeWasCalled, "Update use case should not be called")
    }
    
    // MARK: - Helper Methods
    
    private func createViewModel(existingHabit: Habit?) {
        viewModel = HabitDetailViewModel(
            createHabit: mockCreateHabit,
            updateHabit: mockUpdateHabit,
            deleteHabit: mockDeleteHabit,
            toggleHabitActiveStatus: mockToggleHabitActiveStatus,
            refreshTrigger: refreshTrigger,
            habit: existingHabit
        )
    }
    
    private func setupValidForm() {
        viewModel.name = "Test Habit"
        viewModel.selectedKind = .binary
        viewModel.selectedSchedule = .daily
        viewModel.selectedEmoji = "🎯"
        viewModel.selectedColorHex = "#FF0000"
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