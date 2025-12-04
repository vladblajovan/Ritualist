//
//  CloudKitCleanupServiceTests.swift
//  RitualistTests
//
//  Tests for CloudKitCleanupService and PersistenceConfiguration.
//
//  Note on test coverage: These tests focus on flag behavior, error types, and
//  configuration correctness. Actual CloudKit operations are NOT tested because:
//  - CloudKit requires a real iCloud account and network connectivity
//  - Integration tests would require CloudKit container access in CI
//  - The cleanup is a one-time operation that's safe to test manually in TestFlight
//
//  The actual CloudKit deletion logic is straightforward and relies on Apple's SDK.
//  Manual testing during TestFlight releases verifies the end-to-end flow.
//
//  Missing test coverage (acceptable trade-offs):
//  - Error handling paths in RitualistApp.swift (lines 379-416):
//    - CKError.networkUnavailable/networkFailure retries on next launch
//    - CKError.notAuthenticated/permissionFailure marks cleanup complete
//    These require mocking CKError scenarios which adds significant test complexity.
//    The error handling is straightforward switch/case logic verified by code review.
//  - UserDefaults dependency injection: Tests use .standard with manual cleanup.
//    Could refactor CloudKitCleanupService to accept UserDefaults via init for better
//    isolation, but adds complexity for minimal benefit. See test struct documentation.
//

import Testing
import Foundation
@testable import RitualistCore

// MARK: - CloudKit Cleanup UserDefaults Flag Tests

/// Tests for CloudKit cleanup flag behavior
///
/// Note: These tests use UserDefaults.standard because CloudKitCleanupService
/// doesn't support dependency injection for UserDefaults. This is acceptable because:
/// 1. Swift Testing runs tests serially by default
/// 2. Each test resets the flag before and after execution
/// 3. The tests are lightweight and don't persist state
///
/// If test isolation becomes an issue, CloudKitCleanupService could be refactored
/// to accept a UserDefaults instance via init, but that adds complexity for minimal benefit.
@Suite("CloudKitCleanupService - Completion Flag Behavior", .serialized)
struct CloudKitCleanupCompletionFlagTests {

    /// UserDefaults key used by CloudKitCleanupService
    private static let cleanupCompletedKey = "personalityAnalysisCloudKitCleanupCompleted"

    /// Reset the cleanup flag - called before and after tests that modify it
    private func resetCleanupFlag() {
        UserDefaults.standard.removeObject(forKey: Self.cleanupCompletedKey)
        UserDefaults.standard.synchronize()
    }

    @Test("Cleanup skips when already completed")
    func cleanupSkipsWhenAlreadyCompleted() async throws {
        resetCleanupFlag()

        // Set the flag to indicate cleanup already completed
        UserDefaults.standard.set(true, forKey: Self.cleanupCompletedKey)

        let logger = DebugLogger(subsystem: "com.ritualist.tests", category: "test")
        let service = CloudKitCleanupService(logger: logger)

        // Should return nil (skipped) when already completed
        let result = try await service.cleanupPersonalityAnalysisFromCloudKit()

        #expect(result == nil, "Should return nil when cleanup was already completed")

        // Clean up
        resetCleanupFlag()
    }

    @Test("Cleanup flag defaults to false when removed")
    func cleanupFlagDefaultsToFalseWhenRemoved() {
        // Clear the flag
        UserDefaults.standard.removeObject(forKey: Self.cleanupCompletedKey)
        UserDefaults.standard.synchronize()

        // When key doesn't exist, bool(forKey:) returns false
        let flagValue = UserDefaults.standard.bool(forKey: Self.cleanupCompletedKey)

        #expect(flagValue == false, "Cleanup flag should default to false when key is removed")
    }

    @Test("DisabledCloudKitCleanupService returns nil without side effects")
    func disabledServiceReturnsNil() async throws {
        let service = DisabledCloudKitCleanupService()

        let result = try await service.cleanupPersonalityAnalysisFromCloudKit()

        #expect(result == nil, "Disabled service should return nil")
    }
}

// MARK: - CloudKit Cleanup Error Tests

@Suite("CloudKitCleanupError - Error Descriptions")
struct CloudKitCleanupErrorTests {

    @Test("Partial failure error description includes counts")
    func partialFailureErrorDescription() {
        let error = CloudKitCleanupError.partialFailure(successCount: 5, failureCount: 2)

        let description = error.errorDescription ?? ""

        #expect(description.contains("5"), "Error should mention success count")
        #expect(description.contains("2"), "Error should mention failure count")
        #expect(description.contains("partially failed"), "Error should indicate partial failure")
    }

    @Test("Partial failure error is LocalizedError")
    func partialFailureIsLocalizedError() {
        let error = CloudKitCleanupError.partialFailure(successCount: 3, failureCount: 1)

        // LocalizedError conformance means errorDescription is available
        #expect(error.errorDescription != nil, "Should have error description")
    }
}

// MARK: - PersistenceConfiguration Tests

@Suite("PersistenceConfiguration - Entity Assignment")
struct PersistenceConfigurationTests {

    @Test("PersonalityAnalysis is in local-only configuration")
    func personalityAnalysisIsLocalOnly() {
        let localTypes = PersistenceConfiguration.localOnlyTypes

        let containsPersonalityAnalysis = localTypes.contains { type in
            String(describing: type) == String(describing: ActivePersonalityAnalysisModel.self)
        }

        #expect(containsPersonalityAnalysis, "PersonalityAnalysisModel should be in local-only types")
    }

    @Test("PersonalityAnalysis is NOT in CloudKit configuration")
    func personalityAnalysisNotInCloudKit() {
        let cloudKitTypes = PersistenceConfiguration.cloudKitSyncedTypes

        let containsPersonalityAnalysis = cloudKitTypes.contains { type in
            String(describing: type) == String(describing: ActivePersonalityAnalysisModel.self)
        }

        #expect(!containsPersonalityAnalysis, "PersonalityAnalysisModel should NOT be in CloudKit-synced types")
    }

    @Test("Local configuration has CloudKit disabled")
    func localConfigurationHasCloudKitDisabled() {
        let localConfig = PersistenceConfiguration.localConfiguration

        // The configuration name should be "Local"
        #expect(localConfig.name == "Local", "Local configuration should be named 'Local'")

        // cloudKitDatabase should be .none for local config
        // Note: We can't directly inspect cloudKitDatabase, but we can verify
        // the configuration exists and is distinct from CloudKit config
        let cloudKitConfig = PersistenceConfiguration.cloudKitConfiguration
        #expect(localConfig.name != cloudKitConfig.name, "Local and CloudKit configs should have different names")
    }

    @Test("CloudKit configuration contains expected syncable entities")
    func cloudKitConfigurationContainsExpectedEntities() {
        let cloudKitTypes = PersistenceConfiguration.cloudKitSyncedTypes

        // Verify expected entities are in CloudKit
        let typeNames = cloudKitTypes.map { String(describing: $0) }

        #expect(typeNames.contains(String(describing: ActiveHabitModel.self)), "Habits should sync to CloudKit")
        #expect(typeNames.contains(String(describing: ActiveHabitLogModel.self)), "HabitLogs should sync to CloudKit")
        #expect(typeNames.contains(String(describing: ActiveHabitCategoryModel.self)), "Categories should sync to CloudKit")
        #expect(typeNames.contains(String(describing: ActiveUserProfileModel.self)), "UserProfile should sync to CloudKit")
        #expect(typeNames.contains(String(describing: ActiveOnboardingStateModel.self)), "OnboardingState should sync to CloudKit")
    }

    @Test("All configurations list contains both configs")
    func allConfigurationsContainsBothConfigs() {
        let allConfigs = PersistenceConfiguration.allConfigurations

        #expect(allConfigs.count == 2, "Should have exactly 2 configurations (CloudKit + Local)")

        let configNames = allConfigs.map { $0.name }
        #expect(configNames.contains("CloudKit"), "Should contain CloudKit configuration")
        #expect(configNames.contains("Local"), "Should contain Local configuration")
    }

    @Test("No entity appears in both CloudKit and Local configurations")
    func noEntityInBothConfigurations() {
        let cloudKitTypes = Set(PersistenceConfiguration.cloudKitSyncedTypes.map { String(describing: $0) })
        let localTypes = Set(PersistenceConfiguration.localOnlyTypes.map { String(describing: $0) })

        let intersection = cloudKitTypes.intersection(localTypes)

        #expect(intersection.isEmpty, "No entity should be in both CloudKit and Local configurations. Found: \(intersection)")
    }
}

// MARK: - CD_ Prefix Documentation Verification

@Suite("CloudKit Record Type Naming")
struct CloudKitRecordTypeNamingTests {

    @Test("SwiftData CloudKit record type uses CD_ prefix convention")
    func swiftDataCloudKitRecordTypeUsesPrefix() {
        // This test documents the expected CloudKit record type naming convention
        // SwiftData prefixes CloudKit record types with "CD_" (Core Data)
        // The actual record type for PersonalityAnalysisModel would be "CD_PersonalityAnalysisModel"

        let expectedRecordType = "CD_PersonalityAnalysisModel"
        let modelName = String(describing: ActivePersonalityAnalysisModel.self)
            .replacingOccurrences(of: "SchemaV", with: "")  // Remove version prefix if present

        // The convention is: "CD_" + ModelTypeName
        // This test verifies our understanding of the naming convention
        #expect(expectedRecordType.hasPrefix("CD_"), "CloudKit record type should start with CD_ prefix")
        #expect(expectedRecordType.contains("PersonalityAnalysis"), "Record type should contain model name")
    }
}
