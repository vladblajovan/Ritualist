//
//  iCloudSyncUseCasesTests.swift
//  RitualistTests
//
//  Tests for iCloud sync use cases, status enums, and error handling.
//
//  Note: Actual CloudKit operations cannot be unit tested without a real iCloud account.
//  These tests focus on status mapping, error handling, and use case logic that can be
//  tested with mocks.
//

import Foundation
import Testing
@testable import RitualistCore

// MARK: - iCloudSyncStatus Tests

@Suite("iCloudSyncStatus - Display Messages")
@MainActor
struct iCloudSyncStatusDisplayTests {

    @Test("available status has correct display message")
    func availableDisplayMessage() {
        let status = iCloudSyncStatus.available
        #expect(status.displayMessage == "Enabled")
    }

    @Test("notSignedIn status has correct display message")
    func notSignedInDisplayMessage() {
        let status = iCloudSyncStatus.notSignedIn
        #expect(status.displayMessage == "Not signed in")
    }

    @Test("restricted status has correct display message")
    func restrictedDisplayMessage() {
        let status = iCloudSyncStatus.restricted
        #expect(status.displayMessage == "Restricted")
    }

    @Test("temporarilyUnavailable status has correct display message")
    func temporarilyUnavailableDisplayMessage() {
        let status = iCloudSyncStatus.temporarilyUnavailable
        #expect(status.displayMessage == "Temporarily unavailable")
    }

    @Test("timeout status has correct display message")
    func timeoutDisplayMessage() {
        let status = iCloudSyncStatus.timeout
        #expect(status.displayMessage == "Connection timed out")
    }

    @Test("notConfigured status has correct display message")
    func notConfiguredDisplayMessage() {
        let status = iCloudSyncStatus.notConfigured
        #expect(status.displayMessage == "Not configured")
    }

    @Test("unknown status has correct display message")
    func unknownDisplayMessage() {
        let status = iCloudSyncStatus.unknown
        #expect(status.displayMessage == "Unknown")
    }
}

@Suite("iCloudSyncStatus - Sync Capability")
@MainActor
struct iCloudSyncStatusCapabilityTests {

    @Test("only available status can sync")
    func onlyAvailableCanSync() {
        #expect(iCloudSyncStatus.available.canSync == true, "Available should be able to sync")
        #expect(iCloudSyncStatus.notSignedIn.canSync == false, "Not signed in should not sync")
        #expect(iCloudSyncStatus.restricted.canSync == false, "Restricted should not sync")
        #expect(iCloudSyncStatus.temporarilyUnavailable.canSync == false, "Temporarily unavailable should not sync")
        #expect(iCloudSyncStatus.timeout.canSync == false, "Timeout should not sync")
        #expect(iCloudSyncStatus.notConfigured.canSync == false, "Not configured should not sync")
        #expect(iCloudSyncStatus.unknown.canSync == false, "Unknown should not sync")
    }

    @Test("all statuses are covered")
    func allStatusesCovered() {
        // Verify all enum cases are tested for canSync
        let allStatuses: [iCloudSyncStatus] = [
            .available,
            .notSignedIn,
            .restricted,
            .temporarilyUnavailable,
            .timeout,
            .notConfigured,
            .unknown
        ]

        // Only .available should allow sync
        let syncableCount = allStatuses.filter(\.canSync).count
        #expect(syncableCount == 1, "Only one status should allow sync")
    }
}

// MARK: - iCloudSyncError Tests

@Suite("iCloudSyncError - Error Descriptions")
@MainActor
struct iCloudSyncErrorTests {

    @Test("syncNotAvailable error includes status message")
    func syncNotAvailableErrorDescription() {
        let error = iCloudSyncError.syncNotAvailable(status: .notSignedIn)

        let description = error.errorDescription
        #expect(description?.contains("iCloud sync not available") == true)
        #expect(description?.contains("Not signed in") == true)
    }

    @Test("syncNotAvailable error for each status")
    func syncNotAvailableForAllStatuses() {
        let statuses: [iCloudSyncStatus] = [
            .notSignedIn,
            .restricted,
            .temporarilyUnavailable,
            .timeout,
            .notConfigured,
            .unknown
        ]

        for status in statuses {
            let error = iCloudSyncError.syncNotAvailable(status: status)
            let description = error.errorDescription

            #expect(description != nil, "Error for \(status) should have description")
            #expect(description?.contains(status.displayMessage) == true,
                   "Error should include status display message for \(status)")
        }
    }
}

// MARK: - DisabledCheckiCloudStatusUseCase Tests

@Suite("DisabledCheckiCloudStatusUseCase - Behavior")
@MainActor
struct DisabledCheckiCloudStatusUseCaseTests {

    @Test("always returns unknown status")
    func alwaysReturnsUnknown() async {
        // Arrange
        let useCase = DisabledCheckiCloudStatusUseCase()

        // Act
        let status = await useCase.execute()

        // Assert
        #expect(status == .unknown, "Disabled use case should return unknown")
    }

    @Test("multiple calls return same result")
    func consistentBehavior() async {
        // Arrange
        let useCase = DisabledCheckiCloudStatusUseCase()

        // Act
        let status1 = await useCase.execute()
        let status2 = await useCase.execute()
        let status3 = await useCase.execute()

        // Assert
        #expect(status1 == status2 && status2 == status3, "Should consistently return unknown")
    }
}

// MARK: - DefaultSyncWithiCloudUseCase Tests

@Suite("DefaultSyncWithiCloudUseCase - Sync Logic")
@MainActor
struct DefaultSyncWithiCloudUseCaseTests {

    @Test("succeeds when iCloud is available")
    func succeedsWhenAvailable() async throws {
        // Arrange
        let mockStatusUseCase = MockCheckiCloudStatusUseCase(returnStatus: .available)
        let useCase = DefaultSyncWithiCloudUseCase(checkiCloudStatus: mockStatusUseCase)

        // Act & Assert - should not throw
        try await useCase.execute()
    }

    @Test("throws when not signed in")
    func throwsWhenNotSignedIn() async {
        // Arrange
        let mockStatusUseCase = MockCheckiCloudStatusUseCase(returnStatus: .notSignedIn)
        let useCase = DefaultSyncWithiCloudUseCase(checkiCloudStatus: mockStatusUseCase)

        // Act & Assert
        await #expect(throws: iCloudSyncError.self) {
            try await useCase.execute()
        }
    }

    @Test("throws when restricted")
    func throwsWhenRestricted() async {
        // Arrange
        let mockStatusUseCase = MockCheckiCloudStatusUseCase(returnStatus: .restricted)
        let useCase = DefaultSyncWithiCloudUseCase(checkiCloudStatus: mockStatusUseCase)

        // Act & Assert
        await #expect(throws: iCloudSyncError.self) {
            try await useCase.execute()
        }
    }

    @Test("throws for all unavailable statuses")
    func throwsForAllUnavailableStatuses() async {
        let unavailableStatuses: [iCloudSyncStatus] = [
            .notSignedIn,
            .restricted,
            .temporarilyUnavailable,
            .timeout,
            .notConfigured,
            .unknown
        ]

        for status in unavailableStatuses {
            let mockStatusUseCase = MockCheckiCloudStatusUseCase(returnStatus: status)
            let useCase = DefaultSyncWithiCloudUseCase(checkiCloudStatus: mockStatusUseCase)

            var didThrow = false
            do {
                try await useCase.execute()
            } catch {
                didThrow = true
            }

            #expect(didThrow, "Should throw for status: \(status)")
        }
    }
}

// MARK: - Last Sync Date Use Cases Tests

@Suite("DefaultGetLastSyncDateUseCase")
@MainActor
struct GetLastSyncDateUseCaseTests {

    @Test("returns nil when no date stored")
    func returnsNilWhenNoDate() async {
        // Arrange
        let mockDefaults = MockUserDefaultsService()
        let useCase = DefaultGetLastSyncDateUseCase(userDefaults: mockDefaults)

        // Act
        let date = await useCase.execute()

        // Assert
        #expect(date == nil, "Should return nil when no date stored")
    }

    @Test("returns stored date")
    func returnsStoredDate() async {
        // Arrange
        let mockDefaults = MockUserDefaultsService()
        let expectedDate = Date(timeIntervalSince1970: 1700000000) // Fixed date
        mockDefaults.set(expectedDate, forKey: UserDefaultsKeys.lastSyncDate)

        let useCase = DefaultGetLastSyncDateUseCase(userDefaults: mockDefaults)

        // Act
        let date = await useCase.execute()

        // Assert
        #expect(date == expectedDate, "Should return the stored date")
    }
}

@Suite("DefaultUpdateLastSyncDateUseCase")
@MainActor
struct UpdateLastSyncDateUseCaseTests {

    @Test("stores date in UserDefaults")
    func storesDate() async {
        // Arrange
        let mockDefaults = MockUserDefaultsService()
        let useCase = DefaultUpdateLastSyncDateUseCase(userDefaults: mockDefaults)
        let dateToStore = Date(timeIntervalSince1970: 1700000000)

        // Act
        await useCase.execute(dateToStore)

        // Assert
        let storedDate = mockDefaults.date(forKey: UserDefaultsKeys.lastSyncDate)
        #expect(storedDate == dateToStore, "Should store the date")
    }

    @Test("update overwrites previous date")
    func overwritesPreviousDate() async {
        // Arrange
        let mockDefaults = MockUserDefaultsService()
        let useCase = DefaultUpdateLastSyncDateUseCase(userDefaults: mockDefaults)
        let firstDate = Date(timeIntervalSince1970: 1700000000)
        let secondDate = Date(timeIntervalSince1970: 1800000000)

        // Act
        await useCase.execute(firstDate)
        await useCase.execute(secondDate)

        // Assert
        let storedDate = mockDefaults.date(forKey: UserDefaultsKeys.lastSyncDate)
        #expect(storedDate == secondDate, "Should store the most recent date")
    }
}

// MARK: - Integration Tests (Get + Update)

@Suite("Sync Date UseCases Integration")
@MainActor
struct SyncDateIntegrationTests {

    @Test("get and update work together")
    func getAndUpdateIntegration() async {
        // Arrange
        let mockDefaults = MockUserDefaultsService()
        let getUseCase = DefaultGetLastSyncDateUseCase(userDefaults: mockDefaults)
        let updateUseCase = DefaultUpdateLastSyncDateUseCase(userDefaults: mockDefaults)

        // Initial state - no date
        let initialDate = await getUseCase.execute()
        #expect(initialDate == nil)

        // Update with new date
        let newDate = Date()
        await updateUseCase.execute(newDate)

        // Get should return the new date
        let retrievedDate = await getUseCase.execute()
        #expect(retrievedDate == newDate)
    }
}

// MARK: - Test Doubles

/// Mock implementation for testing sync use cases
private final class MockCheckiCloudStatusUseCase: CheckiCloudStatusUseCase, @unchecked Sendable {
    private let returnStatus: iCloudSyncStatus

    init(returnStatus: iCloudSyncStatus) {
        self.returnStatus = returnStatus
    }

    func execute() async -> iCloudSyncStatus {
        returnStatus
    }
}
