//
//  TestViewModelContainer.swift
//  RitualistTests
//
//  Provides mock use case implementations and factory methods for ViewModel testing.
//  Follows the same pattern as TestModelContainer for SwiftData testing.
//

import Foundation
@testable import Ritualist
@testable import RitualistCore

// MARK: - Mock Use Cases for ViewModel Testing

/// Mock implementation of GetEarliestLogDateUseCase
/// Use this to test start date validation without database queries
public final class MockGetEarliestLogDate: GetEarliestLogDateUseCase {
    public var dateToReturn: Date?
    public var shouldFail = false
    public var failureError: Error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    public private(set) var executeCallCount = 0
    public private(set) var lastRequestedHabitID: UUID?

    public init(dateToReturn: Date? = nil) {
        self.dateToReturn = dateToReturn
    }

    public func execute(for habitID: UUID) async throws -> Date? {
        executeCallCount += 1
        lastRequestedHabitID = habitID
        if shouldFail {
            throw failureError
        }
        return dateToReturn
    }
}

/// Mock implementation of ValidateHabitUniquenessUseCase
/// Use this to test duplicate habit validation
public final class MockValidateHabitUniqueness: ValidateHabitUniquenessUseCase {
    public var isUnique = true
    public var shouldFail = false
    public var failureError: Error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    public private(set) var executeCallCount = 0
    public private(set) var lastValidatedName: String?
    public private(set) var lastValidatedCategoryId: String?

    public init(isUnique: Bool = true) {
        self.isUnique = isUnique
    }

    public func execute(name: String, categoryId: String?, excludeId: UUID?) async throws -> Bool {
        executeCallCount += 1
        lastValidatedName = name
        lastValidatedCategoryId = categoryId
        if shouldFail {
            throw failureError
        }
        return isUnique
    }
}

/// Mock implementation of GetActiveCategoriesUseCase
/// Use this to provide test categories without database queries
public final class MockGetActiveCategories: GetActiveCategoriesUseCase {
    public var categories: [HabitCategory] = []
    public var shouldFail = false
    public var failureError: Error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    public private(set) var executeCallCount = 0

    public init(categories: [HabitCategory] = []) {
        self.categories = categories
    }

    public func execute() async throws -> [HabitCategory] {
        executeCallCount += 1
        if shouldFail {
            throw failureError
        }
        return categories
    }
}

/// Mock implementation of GetLocationAuthStatusUseCase for HabitDetail testing
/// Use this to simulate location permission states
public final class MockGetLocationAuthStatusForHabitDetail: GetLocationAuthStatusUseCase {
    public var statusToReturn: LocationAuthorizationStatus = .notDetermined
    public private(set) var executeCallCount = 0

    public init(status: LocationAuthorizationStatus = .notDetermined) {
        self.statusToReturn = status
    }

    public func execute() async -> LocationAuthorizationStatus {
        executeCallCount += 1
        return statusToReturn
    }
}

// MARK: - Test ViewModel Container

/// Factory for creating ViewModels with mock dependencies for testing
///
/// **Purpose:** Provide isolated test environment for ViewModels without real database or network calls
///
/// **Key Features:**
/// - Pre-configured mock use cases
/// - Easy customization of mock behavior
/// - Follows same pattern as TestModelContainer
///
/// **Usage:**
/// ```swift
/// @Test("Start date validation")
/// @MainActor
/// func testStartDateValidation() async throws {
///     let (viewModel, mocks) = TestViewModelContainer.habitDetailViewModel(
///         habit: HabitBuilder.binary(),
///         earliestLogDate: TestDates.yesterday
///     )
///
///     // Wait for async initialization
///     try await Task.sleep(for: .milliseconds(100))
///
///     // Test assertions
///     #expect(viewModel.isStartDateValid == true)
/// }
/// ```
public enum TestViewModelContainer {

    // MARK: - Mock Configuration

    /// Container for all mocks used by HabitDetailViewModel
    public struct HabitDetailMocks {
        public let getEarliestLogDate: MockGetEarliestLogDate
        public let validateHabitUniqueness: MockValidateHabitUniqueness
        public let getActiveCategories: MockGetActiveCategories
        public let getLocationAuthStatus: MockGetLocationAuthStatusForHabitDetail
    }

    // MARK: - HabitDetailViewModel Factory

    /// Creates a HabitDetailViewModel with mock dependencies for testing
    ///
    /// - Parameters:
    ///   - habit: The habit to edit (nil for new habit creation)
    ///   - earliestLogDate: The earliest log date to return (nil means no logs exist)
    ///   - isUnique: Whether the habit name should be considered unique
    ///   - categories: Categories to return from the mock
    ///   - locationAuthStatus: Location authorization status to return
    /// - Returns: Tuple of (viewModel, mocks) for testing and verification
    @MainActor
    public static func habitDetailViewModel(
        habit: Habit? = nil,
        earliestLogDate: Date? = nil,
        isUnique: Bool = true,
        categories: [HabitCategory] = [],
        locationAuthStatus: LocationAuthorizationStatus = .notDetermined
    ) -> (viewModel: HabitDetailViewModel, mocks: HabitDetailMocks) {
        let mockGetEarliestLogDate = MockGetEarliestLogDate(dateToReturn: earliestLogDate)
        let mockValidateUniqueness = MockValidateHabitUniqueness(isUnique: isUnique)
        let mockGetCategories = MockGetActiveCategories(categories: categories)
        let mockGetLocationAuth = MockGetLocationAuthStatusForHabitDetail(status: locationAuthStatus)

        let viewModel = HabitDetailViewModel(
            habit: habit,
            getEarliestLogDate: mockGetEarliestLogDate,
            validateHabitUniqueness: mockValidateUniqueness,
            getActiveCategories: mockGetCategories,
            getLocationAuthStatus: mockGetLocationAuth
        )

        let mocks = HabitDetailMocks(
            getEarliestLogDate: mockGetEarliestLogDate,
            validateHabitUniqueness: mockValidateUniqueness,
            getActiveCategories: mockGetCategories,
            getLocationAuthStatus: mockGetLocationAuth
        )

        return (viewModel, mocks)
    }

    /// Creates a HabitDetailViewModel with custom mock instances for advanced testing
    ///
    /// Use this when you need fine-grained control over mock behavior
    @MainActor
    public static func habitDetailViewModel(
        habit: Habit? = nil,
        mocks: HabitDetailMocks
    ) -> HabitDetailViewModel {
        return HabitDetailViewModel(
            habit: habit,
            getEarliestLogDate: mocks.getEarliestLogDate,
            validateHabitUniqueness: mocks.validateHabitUniqueness,
            getActiveCategories: mocks.getActiveCategories,
            getLocationAuthStatus: mocks.getLocationAuthStatus
        )
    }
}
