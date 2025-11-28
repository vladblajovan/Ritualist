//
//  RootTabViewModelTests.swift
//  RitualistTests
//
//  Created by Claude on 28.11.2025.
//
//  Unit tests for RootTabViewModel focusing on onboarding status logic.
//  Tests the three main user scenarios:
//  1. New user - show full onboarding
//  2. Existing user (local completed) - skip onboarding
//  3. Returning user (iCloud completed, local not) - show returning user welcome
//
//  Note: These tests focus on the onboarding status logic and returning user
//  detection which doesn't require real database access or complex mocking.
//

import Testing
import Foundation
@testable import Ritualist
@testable import RitualistCore

#if swift(>=6.1)
@Suite(
    "RootTabViewModel Tests",
    .tags(.isolated, .fast, .ui)
)
#else
@Suite("RootTabViewModel Tests")
#endif
struct RootTabViewModelTests {

    // MARK: - Test Dependencies

    /// Create a test instance with configurable mock dependencies
    @MainActor
    private func createViewModel(
        iCloudCompleted: Bool = false,
        localCompleted: Bool = false
    ) -> (RootTabViewModel, MockiCloudKeyValueServiceForViewModel) {
        let mockiCloud = MockiCloudKeyValueServiceForViewModel()
        mockiCloud.iCloudOnboardingCompleted = iCloudCompleted
        mockiCloud.localOnboardingCompleted = localCompleted

        // Create a mock profile repository that returns an empty profile
        let mockProfileRepo = MockProfileRepository()
        let mockLoadProfile = LoadProfile(repo: mockProfileRepo, iCloudKeyValueService: mockiCloud)

        let appearanceManager = AppearanceManager()
        let navigationService = NavigationService()
        let personalityCoordinator = PersonalityDeepLinkCoordinator(logger: DebugLogger(subsystem: "test", category: "coordinator"))
        let logger = DebugLogger(subsystem: "test", category: "viewmodel")

        let viewModel = RootTabViewModel(
            loadProfile: mockLoadProfile,
            iCloudKeyValueService: mockiCloud,
            appearanceManager: appearanceManager,
            navigationService: navigationService,
            personalityDeepLinkCoordinator: personalityCoordinator,
            logger: logger
        )

        return (viewModel, mockiCloud)
    }

    // MARK: - Initial State Tests

    @Test("Initial state is checking onboarding")
    @MainActor
    func initialStateIsCheckingOnboarding() {
        let (viewModel, _) = createViewModel()

        #expect(viewModel.isCheckingOnboarding == true)
        #expect(viewModel.showOnboarding == false)
        #expect(viewModel.pendingReturningUserWelcome == false)
        #expect(viewModel.showReturningUserWelcome == false)
    }

    // MARK: - New User Scenario Tests

    @Test("New user sees onboarding (neither flag set)")
    @MainActor
    func newUserSeesOnboarding() async {
        let (viewModel, _) = createViewModel(iCloudCompleted: false, localCompleted: false)

        await viewModel.checkOnboardingStatus()

        #expect(viewModel.showOnboarding == true)
        #expect(viewModel.isCheckingOnboarding == false)
        #expect(viewModel.pendingReturningUserWelcome == false)
    }

    // MARK: - Existing User Scenario Tests

    @Test("Existing user skips onboarding (local flag set)")
    @MainActor
    func existingUserSkipsOnboarding() async {
        let (viewModel, _) = createViewModel(iCloudCompleted: true, localCompleted: true)

        await viewModel.checkOnboardingStatus()

        #expect(viewModel.showOnboarding == false)
        #expect(viewModel.isCheckingOnboarding == false)
        #expect(viewModel.pendingReturningUserWelcome == false)
    }

    @Test("Local flag alone is enough to skip (even if iCloud false)")
    @MainActor
    func localFlagAloneSkipsOnboarding() async {
        let (viewModel, _) = createViewModel(iCloudCompleted: false, localCompleted: true)

        await viewModel.checkOnboardingStatus()

        #expect(viewModel.showOnboarding == false)
        #expect(viewModel.isCheckingOnboarding == false)
        #expect(viewModel.pendingReturningUserWelcome == false)
    }

    // MARK: - Returning User Scenario Tests

    @Test("Returning user gets pending welcome (iCloud set, local not)")
    @MainActor
    func returningUserGetsPendingWelcome() async {
        let (viewModel, _) = createViewModel(iCloudCompleted: true, localCompleted: false)

        await viewModel.checkOnboardingStatus()

        #expect(viewModel.showOnboarding == false)
        #expect(viewModel.isCheckingOnboarding == false)
        #expect(viewModel.pendingReturningUserWelcome == true)
    }

    // MARK: - Returning User Welcome Tests

    @Test("Returning user welcome shows with complete data")
    @MainActor
    func returningUserWelcomeShowsWithCompleteData() async {
        let (viewModel, _) = createViewModel(iCloudCompleted: true, localCompleted: false)

        // Simulate returning user detection
        await viewModel.checkOnboardingStatus()
        #expect(viewModel.pendingReturningUserWelcome == true)

        // Simulate data loading with complete data
        let habits = [createTestHabit()]
        let profile = createTestProfile(name: "Test User")

        viewModel.showReturningUserWelcomeIfNeeded(habits: habits, profile: profile)

        #expect(viewModel.showReturningUserWelcome == true)
        #expect(viewModel.pendingReturningUserWelcome == false)
        #expect(viewModel.syncedDataSummary != nil)
        #expect(viewModel.syncedDataSummary?.habitsCount == 1)
        #expect(viewModel.syncedDataSummary?.hasProfile == true)
    }

    @Test("Returning user welcome waits for incomplete data (no habits)")
    @MainActor
    func returningUserWelcomeWaitsForHabits() async {
        let (viewModel, _) = createViewModel(iCloudCompleted: true, localCompleted: false)

        await viewModel.checkOnboardingStatus()
        #expect(viewModel.pendingReturningUserWelcome == true)

        // No habits yet
        let habits: [Habit] = []
        let profile = createTestProfile(name: "Test User")

        viewModel.showReturningUserWelcomeIfNeeded(habits: habits, profile: profile)

        // Should still be pending - waiting for habits
        #expect(viewModel.showReturningUserWelcome == false)
        #expect(viewModel.pendingReturningUserWelcome == true)
    }

    @Test("Returning user welcome waits for incomplete data (no profile name)")
    @MainActor
    func returningUserWelcomeWaitsForProfileName() async {
        let (viewModel, _) = createViewModel(iCloudCompleted: true, localCompleted: false)

        await viewModel.checkOnboardingStatus()
        #expect(viewModel.pendingReturningUserWelcome == true)

        // Has habits but no profile name
        let habits = [createTestHabit()]
        let profile = createTestProfile(name: "")

        viewModel.showReturningUserWelcomeIfNeeded(habits: habits, profile: profile)

        // Should still be pending - waiting for profile name
        #expect(viewModel.showReturningUserWelcome == false)
        #expect(viewModel.pendingReturningUserWelcome == true)
    }

    @Test("Returning user welcome waits for nil profile")
    @MainActor
    func returningUserWelcomeWaitsForProfile() async {
        let (viewModel, _) = createViewModel(iCloudCompleted: true, localCompleted: false)

        await viewModel.checkOnboardingStatus()
        #expect(viewModel.pendingReturningUserWelcome == true)

        // Has habits but no profile
        let habits = [createTestHabit()]

        viewModel.showReturningUserWelcomeIfNeeded(habits: habits, profile: nil)

        // Should still be pending - waiting for profile
        #expect(viewModel.showReturningUserWelcome == false)
        #expect(viewModel.pendingReturningUserWelcome == true)
    }

    @Test("No welcome shown without pending flag")
    @MainActor
    func noWelcomeWithoutPendingFlag() async {
        let (viewModel, _) = createViewModel(iCloudCompleted: false, localCompleted: false)

        // New user, no pending welcome
        await viewModel.checkOnboardingStatus()
        #expect(viewModel.pendingReturningUserWelcome == false)

        // Try to show welcome
        let habits = [createTestHabit()]
        let profile = createTestProfile(name: "Test User")

        viewModel.showReturningUserWelcomeIfNeeded(habits: habits, profile: profile)

        // Should not show welcome
        #expect(viewModel.showReturningUserWelcome == false)
    }

    // MARK: - Dismiss Returning User Welcome Tests

    @Test("Dismiss returning user welcome clears state")
    @MainActor
    func dismissReturningUserWelcomeClearsState() async {
        let (viewModel, mockiCloud) = createViewModel(iCloudCompleted: true, localCompleted: false)

        // Setup returning user welcome
        await viewModel.checkOnboardingStatus()
        let habits = [createTestHabit()]
        let profile = createTestProfile(name: "Test User")
        viewModel.showReturningUserWelcomeIfNeeded(habits: habits, profile: profile)

        #expect(viewModel.showReturningUserWelcome == true)

        // Dismiss
        viewModel.dismissReturningUserWelcome()

        #expect(viewModel.showReturningUserWelcome == false)
        #expect(viewModel.syncedDataSummary == nil)
    }

    @Test("Dismiss returning user welcome sets local completed flag")
    @MainActor
    func dismissSetsLocalCompletedFlag() async {
        let (viewModel, mockiCloud) = createViewModel(iCloudCompleted: true, localCompleted: false)

        // Setup returning user welcome
        await viewModel.checkOnboardingStatus()
        let habits = [createTestHabit()]
        let profile = createTestProfile(name: "Test User")
        viewModel.showReturningUserWelcomeIfNeeded(habits: habits, profile: profile)

        // Dismiss
        viewModel.dismissReturningUserWelcome()

        // Local flag should be set
        #expect(mockiCloud.localOnboardingCompleted == true)
    }

    // MARK: - iCloud Synchronization Tests

    @Test("checkOnboardingStatus calls synchronize")
    @MainActor
    func checkOnboardingStatusCallsSynchronize() async {
        let (viewModel, mockiCloud) = createViewModel()

        await viewModel.checkOnboardingStatus()

        #expect(mockiCloud.synchronizeCallCount == 1)
    }

    // MARK: - Helper Methods

    private func createTestHabit() -> Habit {
        HabitBuilder.binary(name: "Test Habit")
    }

    private func createTestProfile(name: String) -> UserProfile {
        var profile = UserProfile()
        profile.name = name
        return profile
    }
}

// MARK: - Mocks

/// Mock iCloudKeyValueService for testing RootTabViewModel
final class MockiCloudKeyValueServiceForViewModel: iCloudKeyValueService {
    var iCloudOnboardingCompleted = false
    var localOnboardingCompleted = false
    var synchronizeCallCount = 0

    func hasCompletedOnboarding() -> Bool {
        return iCloudOnboardingCompleted
    }

    func setOnboardingCompleted() {
        iCloudOnboardingCompleted = true
    }

    func synchronize() {
        synchronizeCallCount += 1
    }

    func resetOnboardingFlag() {
        iCloudOnboardingCompleted = false
    }

    func hasCompletedOnboardingLocally() -> Bool {
        return localOnboardingCompleted
    }

    func setOnboardingCompletedLocally() {
        localOnboardingCompleted = true
    }

    func resetLocalOnboardingFlag() {
        localOnboardingCompleted = false
    }
}

/// Mock ProfileRepository for testing
final class MockProfileRepository: ProfileRepository {
    var profileToReturn: UserProfile?
    var savedProfile: UserProfile?
    var shouldThrowError = false

    func loadProfile() async throws -> UserProfile? {
        if shouldThrowError {
            throw NSError(domain: "test", code: 1, userInfo: nil)
        }
        return profileToReturn
    }

    func saveProfile(_ profile: UserProfile) async throws {
        if shouldThrowError {
            throw NSError(domain: "test", code: 1, userInfo: nil)
        }
        savedProfile = profile
    }
}
