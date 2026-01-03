//
//  iCloudKeyValueServiceTests.swift
//  RitualistTests
//
//  Created by Vlad Blajovan on 28.11.2025.
//
//  Unit tests for iCloudKeyValueService.
//  Note: NSUbiquitousKeyValueStore requires iCloud entitlements and can't be easily
//  unit tested. These tests focus on the local device flag logic using UserDefaults,
//  which is the critical path for detecting returning users on new devices.
//

import Testing
import Foundation
@testable import RitualistCore

@Suite(
    "iCloudKeyValueService Tests",
    .tags(.isolated, .fast)
)
@MainActor
struct iCloudKeyValueServiceTests {

    // MARK: - Test Setup

    /// Create a fresh UserDefaults suite for testing
    private func createTestUserDefaults() -> UserDefaults {
        let suiteName = "com.ritualist.tests.icloud.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    /// Create service with test UserDefaults
    private func createService(userDefaults: UserDefaults) -> DefaultiCloudKeyValueService {
        let logger = DebugLogger(subsystem: "test", category: "icloud")
        return DefaultiCloudKeyValueService(logger: logger, userDefaults: userDefaults)
    }

    // MARK: - Local Onboarding Flag Tests

    @Test("Fresh user defaults returns false for local onboarding")
    func freshUserDefaultsReturnsFalse() throws {
        let defaults = createTestUserDefaults()
        let service = createService(userDefaults: defaults)

        #expect(service.hasCompletedOnboardingLocally() == false)
    }

    @Test("setOnboardingCompletedLocally sets flag to true")
    func setLocalOnboardingCompleted() throws {
        let defaults = createTestUserDefaults()
        let service = createService(userDefaults: defaults)

        // Initially false
        #expect(service.hasCompletedOnboardingLocally() == false)

        // Set to completed
        service.setOnboardingCompletedLocally()

        // Now should be true
        #expect(service.hasCompletedOnboardingLocally() == true)
    }

    @Test("resetLocalOnboardingFlag resets to false")
    func resetLocalOnboardingFlag() throws {
        let defaults = createTestUserDefaults()
        let service = createService(userDefaults: defaults)

        // Set completed first
        service.setOnboardingCompletedLocally()
        #expect(service.hasCompletedOnboardingLocally() == true)

        // Reset
        service.resetLocalOnboardingFlag()

        // Should be false again
        #expect(service.hasCompletedOnboardingLocally() == false)
    }

    @Test("Local flag persists across service instances")
    func localFlagPersistsAcrossInstances() throws {
        let defaults = createTestUserDefaults()

        // Create first service and set flag
        let service1 = createService(userDefaults: defaults)
        service1.setOnboardingCompletedLocally()
        #expect(service1.hasCompletedOnboardingLocally() == true)

        // Create second service with same defaults
        let service2 = createService(userDefaults: defaults)
        #expect(service2.hasCompletedOnboardingLocally() == true)
    }

    @Test("Different user defaults suites are isolated")
    func differentSuitesAreIsolated() throws {
        let defaults1 = createTestUserDefaults()
        let defaults2 = createTestUserDefaults()

        let service1 = createService(userDefaults: defaults1)
        let service2 = createService(userDefaults: defaults2)

        // Set flag only on service1
        service1.setOnboardingCompletedLocally()

        // service1 should be true
        #expect(service1.hasCompletedOnboardingLocally() == true)

        // service2 should still be false (different suite)
        #expect(service2.hasCompletedOnboardingLocally() == false)
    }

    // MARK: - Synchronize Tests

    @Test("synchronize doesn't crash")
    func synchronizeDoesntCrash() throws {
        let defaults = createTestUserDefaults()
        let service = createService(userDefaults: defaults)

        // Just verify it doesn't throw
        service.synchronize()
    }

    // MARK: - iCloud Flag Tests (Limited - requires real iCloud)
    // Note: These test the API but can't verify actual iCloud sync without entitlements

    @Test("hasCompletedOnboarding returns a value")
    func hasCompletedOnboardingReturnsValue() throws {
        let defaults = createTestUserDefaults()
        let service = createService(userDefaults: defaults)

        // Just verify it returns without crashing
        // In tests without iCloud, this will return false
        let _ = service.hasCompletedOnboarding()
    }

    @Test("setOnboardingCompleted doesn't crash")
    func setOnboardingCompletedDoesntCrash() throws {
        let defaults = createTestUserDefaults()
        let service = createService(userDefaults: defaults)

        // Just verify it doesn't throw
        // Note: Won't actually sync to iCloud in unit tests
        service.setOnboardingCompleted()
    }

    @Test("resetOnboardingFlag doesn't crash")
    func resetOnboardingFlagDoesntCrash() throws {
        let defaults = createTestUserDefaults()
        let service = createService(userDefaults: defaults)

        // Just verify it doesn't throw
        service.resetOnboardingFlag()
    }

    // MARK: - Returning User Detection Logic Tests

    @Test("New user scenario: both flags false")
    func newUserScenario() throws {
        let defaults = createTestUserDefaults()
        let service = createService(userDefaults: defaults)

        // New user has neither flag set
        let localCompleted = service.hasCompletedOnboardingLocally()
        // iCloud flag would be checked via hasCompletedOnboarding() in real scenario

        #expect(localCompleted == false)
        // Expected behavior: Show full onboarding
    }

    @Test("Existing user scenario: local flag true")
    func existingUserScenario() throws {
        let defaults = createTestUserDefaults()
        let service = createService(userDefaults: defaults)

        // Simulate existing user who completed onboarding on this device
        service.setOnboardingCompletedLocally()

        let localCompleted = service.hasCompletedOnboardingLocally()

        #expect(localCompleted == true)
        // Expected behavior: Skip onboarding entirely
    }

    @Test("Returning user scenario simulation")
    func returningUserScenarioSimulation() throws {
        // This tests the logic flow, not actual iCloud sync
        // Returning user = iCloud says completed, but local says not

        let defaults = createTestUserDefaults()
        let service = createService(userDefaults: defaults)

        // Local flag is false (new device)
        #expect(service.hasCompletedOnboardingLocally() == false)

        // In real scenario, iCloud hasCompletedOnboarding() would return true
        // This would trigger the returning user welcome flow

        // After completing returning user flow, both should be set
        service.setOnboardingCompletedLocally()
        #expect(service.hasCompletedOnboardingLocally() == true)
    }
}

// MARK: - Notification Name Tests

@Suite("iCloudKeyValueService Notifications")
struct iCloudKeyValueNotificationTests {

    @Test("iCloudKeyValueDidChange notification name is properly defined")
    func notificationNameExists() {
        // Verify the notification name matches expected value
        let name = Notification.Name.iCloudKeyValueDidChange
        #expect(name.rawValue == "iCloudKeyValueDidChange")
    }
}

// MARK: - Mock for Integration Tests

/// Mock implementation for testing code that depends on iCloudKeyValueService
public final class MockiCloudKeyValueService: iCloudKeyValueService, @unchecked Sendable {
    public var iCloudOnboardingCompleted = false
    public var localOnboardingCompleted = false
    public var synchronizeCallCount = 0

    public init() {}

    public func hasCompletedOnboarding() -> Bool {
        return iCloudOnboardingCompleted
    }

    public func setOnboardingCompleted() {
        iCloudOnboardingCompleted = true
    }

    public func synchronize() {
        synchronizeCallCount += 1
    }

    public func synchronizeAndWait(timeout: TimeInterval) async -> Bool {
        synchronizeCallCount += 1
        return true // Mock always succeeds immediately
    }

    public func resetOnboardingFlag() {
        iCloudOnboardingCompleted = false
    }

    public func hasCompletedOnboardingLocally() -> Bool {
        return localOnboardingCompleted
    }

    public func setOnboardingCompletedLocally() {
        localOnboardingCompleted = true
    }

    public func resetLocalOnboardingFlag() {
        localOnboardingCompleted = false
    }
}
