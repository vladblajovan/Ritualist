//
//  OnboardingViewModelTests.swift
//  RitualistTests
//
//  Created by Claude on 28.11.2025.
//
//  Unit tests for OnboardingViewModel covering:
//  - UserGender and UserAgeGroup enums
//  - Page navigation logic
//  - canProceedFromCurrentPage validation
//  - Skip and finish onboarding flows (using mock repositories)
//

import Testing
import Foundation
@testable import Ritualist
@testable import RitualistCore

// MARK: - UserGender Enum Tests

#if swift(>=6.1)
@Suite("UserGender Enum Tests", .tags(.isolated, .fast))
#else
@Suite("UserGender Enum Tests")
#endif
struct UserGenderTests {

    @Test("All cases have correct raw values")
    func rawValues() {
        #expect(UserGender.preferNotToSay.rawValue == "prefer_not_to_say")
        #expect(UserGender.male.rawValue == "male")
        #expect(UserGender.female.rawValue == "female")
        #expect(UserGender.other.rawValue == "other")
    }

    @Test("All cases have correct display names")
    func displayNames() {
        #expect(UserGender.preferNotToSay.displayName == "Prefer not to say")
        #expect(UserGender.male.displayName == "Male")
        #expect(UserGender.female.displayName == "Female")
        #expect(UserGender.other.displayName == "Other")
    }

    @Test("CaseIterable returns all 4 cases")
    func caseIterable() {
        #expect(UserGender.allCases.count == 4)
        #expect(UserGender.allCases.contains(.preferNotToSay))
        #expect(UserGender.allCases.contains(.male))
        #expect(UserGender.allCases.contains(.female))
        #expect(UserGender.allCases.contains(.other))
    }

    @Test("Identifiable id matches rawValue")
    func identifiable() {
        for gender in UserGender.allCases {
            #expect(gender.id == gender.rawValue)
        }
    }
}

// MARK: - UserAgeGroup Enum Tests

#if swift(>=6.1)
@Suite("UserAgeGroup Enum Tests", .tags(.isolated, .fast))
#else
@Suite("UserAgeGroup Enum Tests")
#endif
struct UserAgeGroupTests {

    @Test("All cases have correct raw values")
    func rawValues() {
        #expect(UserAgeGroup.preferNotToSay.rawValue == "prefer_not_to_say")
        #expect(UserAgeGroup.under18.rawValue == "under_18")
        #expect(UserAgeGroup.age18to24.rawValue == "18_24")
        #expect(UserAgeGroup.age25to34.rawValue == "25_34")
        #expect(UserAgeGroup.age35to44.rawValue == "35_44")
        #expect(UserAgeGroup.age45to54.rawValue == "45_54")
        #expect(UserAgeGroup.age55plus.rawValue == "55_plus")
    }

    @Test("All cases have correct display names")
    func displayNames() {
        #expect(UserAgeGroup.preferNotToSay.displayName == "Prefer not to say")
        #expect(UserAgeGroup.under18.displayName == "Under 18")
        #expect(UserAgeGroup.age18to24.displayName == "18-24")
        #expect(UserAgeGroup.age25to34.displayName == "25-34")
        #expect(UserAgeGroup.age35to44.displayName == "35-44")
        #expect(UserAgeGroup.age45to54.displayName == "45-54")
        #expect(UserAgeGroup.age55plus.displayName == "55+")
    }

    @Test("CaseIterable returns all 7 cases")
    func caseIterable() {
        #expect(UserAgeGroup.allCases.count == 7)
    }

    @Test("Identifiable id matches rawValue")
    func identifiable() {
        for ageGroup in UserAgeGroup.allCases {
            #expect(ageGroup.id == ageGroup.rawValue)
        }
    }
}

// MARK: - OnboardingViewModel Tests

#if swift(>=6.1)
@Suite("OnboardingViewModel Tests", .tags(.isolated, .fast, .ui))
#else
@Suite("OnboardingViewModel Tests")
#endif
struct OnboardingViewModelTests {

    // MARK: - Test Setup

    /// Creates a ViewModel with mock repositories for testing
    @MainActor
    private func createViewModel(
        onboardingRepoShouldFail: Bool = false,
        profileRepoShouldFail: Bool = false,
        existingOnboardingState: OnboardingState? = nil
    ) -> OnboardingViewModel {
        let mockOnboardingRepo = MockOnboardingRepository()
        mockOnboardingRepo.shouldFail = onboardingRepoShouldFail
        mockOnboardingRepo.stateToReturn = existingOnboardingState

        let mockProfileRepo = MockProfileRepositoryForOnboarding()
        mockProfileRepo.shouldFail = profileRepoShouldFail

        let mockiCloudService = MockiCloudKeyValueServiceForOnboarding()

        // Create real use cases with mock repositories
        let getOnboardingState = GetOnboardingState(repo: mockOnboardingRepo)
        let saveOnboardingState = SaveOnboardingState(repo: mockOnboardingRepo)
        let completeOnboarding = CompleteOnboarding(
            repo: mockOnboardingRepo,
            profileRepo: mockProfileRepo,
            iCloudKeyValueService: mockiCloudService
        )

        return OnboardingViewModel(
            getOnboardingState: getOnboardingState,
            saveOnboardingState: saveOnboardingState,
            completeOnboarding: completeOnboarding,
            requestNotificationPermission: MockRequestNotificationPermission(),
            checkNotificationStatus: MockCheckNotificationStatus(),
            requestLocationPermissions: MockRequestLocationPermissions(),
            getLocationAuthStatus: MockGetLocationAuthStatus()
        )
    }

    // MARK: - Initial State Tests

    @Test("Initial state has correct defaults")
    @MainActor
    func initialState() {
        let viewModel = createViewModel()

        #expect(viewModel.currentPage == 0)
        #expect(viewModel.userName == "")
        #expect(viewModel.gender == .preferNotToSay)
        #expect(viewModel.ageGroup == .preferNotToSay)
        #expect(viewModel.hasGrantedNotifications == false)
        #expect(viewModel.hasGrantedLocation == false)
        #expect(viewModel.isCompleted == false)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.totalPages == 6)
    }

    // MARK: - Page Navigation Tests

    @Test("nextPage increments currentPage")
    @MainActor
    func nextPageIncrements() {
        let viewModel = createViewModel()

        #expect(viewModel.currentPage == 0)
        viewModel.nextPage()
        #expect(viewModel.currentPage == 1)
        viewModel.nextPage()
        #expect(viewModel.currentPage == 2)
    }

    @Test("nextPage stops at last page")
    @MainActor
    func nextPageStopsAtEnd() {
        let viewModel = createViewModel()

        // Go to last page
        for _ in 0..<10 {
            viewModel.nextPage()
        }

        #expect(viewModel.currentPage == viewModel.totalPages - 1)
    }

    @Test("previousPage decrements currentPage")
    @MainActor
    func previousPageDecrements() {
        let viewModel = createViewModel()

        viewModel.currentPage = 3
        viewModel.previousPage()
        #expect(viewModel.currentPage == 2)
        viewModel.previousPage()
        #expect(viewModel.currentPage == 1)
    }

    @Test("previousPage stops at first page")
    @MainActor
    func previousPageStopsAtStart() {
        let viewModel = createViewModel()

        viewModel.currentPage = 1
        viewModel.previousPage()
        #expect(viewModel.currentPage == 0)
        viewModel.previousPage()
        #expect(viewModel.currentPage == 0)
    }

    @Test("goToPage sets valid page")
    @MainActor
    func goToPageValid() {
        let viewModel = createViewModel()

        viewModel.goToPage(3)
        #expect(viewModel.currentPage == 3)

        viewModel.goToPage(0)
        #expect(viewModel.currentPage == 0)

        viewModel.goToPage(5)
        #expect(viewModel.currentPage == 5)
    }

    @Test("goToPage ignores invalid pages")
    @MainActor
    func goToPageInvalid() {
        let viewModel = createViewModel()

        viewModel.currentPage = 2

        viewModel.goToPage(-1)
        #expect(viewModel.currentPage == 2)

        viewModel.goToPage(100)
        #expect(viewModel.currentPage == 2)

        viewModel.goToPage(6) // totalPages is 6, so 6 is invalid
        #expect(viewModel.currentPage == 2)
    }

    // MARK: - isFirstPage / isLastPage Tests

    @Test("isFirstPage is true only on page 0")
    @MainActor
    func isFirstPage() {
        let viewModel = createViewModel()

        #expect(viewModel.isFirstPage == true)

        viewModel.currentPage = 1
        #expect(viewModel.isFirstPage == false)

        viewModel.currentPage = 5
        #expect(viewModel.isFirstPage == false)
    }

    @Test("isLastPage is true only on last page")
    @MainActor
    func isLastPage() {
        let viewModel = createViewModel()

        #expect(viewModel.isLastPage == false)

        viewModel.currentPage = 4
        #expect(viewModel.isLastPage == false)

        viewModel.currentPage = 5
        #expect(viewModel.isLastPage == true)
    }

    // MARK: - canProceedFromCurrentPage Tests

    @Test("Page 0 requires non-empty userName (whitespace rejected)")
    @MainActor
    func canProceedPage0RequiresName() {
        let viewModel = createViewModel()

        viewModel.currentPage = 0
        viewModel.userName = ""
        #expect(viewModel.canProceedFromCurrentPage == false)

        viewModel.userName = "   " // Whitespace only - should be rejected
        #expect(viewModel.canProceedFromCurrentPage == false)

        viewModel.userName = "\t\n" // Tabs and newlines only - should be rejected
        #expect(viewModel.canProceedFromCurrentPage == false)

        viewModel.userName = "John"
        #expect(viewModel.canProceedFromCurrentPage == true)

        viewModel.userName = "  John  " // Leading/trailing whitespace OK if there's content
        #expect(viewModel.canProceedFromCurrentPage == true)
    }

    @Test("Information pages (1-4) can always proceed")
    @MainActor
    func canProceedInformationPages() {
        let viewModel = createViewModel()

        for page in 1...4 {
            viewModel.currentPage = page
            viewModel.userName = "" // Even without name
            #expect(viewModel.canProceedFromCurrentPage == true, "Page \(page) should allow proceed")
        }
    }

    @Test("Final page (5) can always proceed")
    @MainActor
    func canProceedFinalPage() {
        let viewModel = createViewModel()

        viewModel.currentPage = 5
        viewModel.userName = ""
        #expect(viewModel.canProceedFromCurrentPage == true)
    }

    // MARK: - updateUserName Tests

    @Test("updateUserName trims whitespace")
    @MainActor
    func updateUserNameTrimsWhitespace() {
        let viewModel = createViewModel()

        viewModel.updateUserName("  John  ")
        #expect(viewModel.userName == "John")

        viewModel.updateUserName("\n\tJane\n\t")
        #expect(viewModel.userName == "Jane")
    }

    // MARK: - Name Length Validation Tests

    @Test("userName enforces maximum length")
    @MainActor
    func userNameEnforcesMaxLength() {
        let viewModel = createViewModel()

        // Set a name that exceeds the max length
        let longName = String(repeating: "A", count: OnboardingViewModel.maxNameLength + 20)
        viewModel.userName = longName

        #expect(viewModel.userName.count == OnboardingViewModel.maxNameLength)
        #expect(viewModel.userName == String(repeating: "A", count: OnboardingViewModel.maxNameLength))
    }

    @Test("userName allows names at max length")
    @MainActor
    func userNameAllowsMaxLength() {
        let viewModel = createViewModel()

        let exactName = String(repeating: "B", count: OnboardingViewModel.maxNameLength)
        viewModel.userName = exactName

        #expect(viewModel.userName.count == OnboardingViewModel.maxNameLength)
        #expect(viewModel.userName == exactName)
    }

    @Test("userName allows names under max length")
    @MainActor
    func userNameAllowsUnderMaxLength() {
        let viewModel = createViewModel()

        viewModel.userName = "John Doe"

        #expect(viewModel.userName == "John Doe")
        #expect(viewModel.userName.count < OnboardingViewModel.maxNameLength)
    }

    @Test("maxNameLength constant is 50")
    func maxNameLengthIs50() {
        #expect(OnboardingViewModel.maxNameLength == 50)
    }

    // MARK: - dismissError Tests

    @Test("dismissError clears errorMessage")
    @MainActor
    func dismissErrorClearsMessage() {
        let viewModel = createViewModel()

        viewModel.errorMessage = "Some error"
        #expect(viewModel.errorMessage != nil)

        viewModel.dismissError()
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - User Profile State Tests

    @Test("gender can be changed")
    @MainActor
    func genderCanBeChanged() {
        let viewModel = createViewModel()

        #expect(viewModel.gender == .preferNotToSay)

        viewModel.gender = .female
        #expect(viewModel.gender == .female)

        viewModel.gender = .male
        #expect(viewModel.gender == .male)
    }

    @Test("ageGroup can be changed")
    @MainActor
    func ageGroupCanBeChanged() {
        let viewModel = createViewModel()

        #expect(viewModel.ageGroup == .preferNotToSay)

        viewModel.ageGroup = .age25to34
        #expect(viewModel.ageGroup == .age25to34)

        viewModel.ageGroup = .age55plus
        #expect(viewModel.ageGroup == .age55plus)
    }

    // MARK: - Skip Onboarding Tests

    @Test("skipOnboarding sets isCompleted on success")
    @MainActor
    func skipOnboardingSuccess() async {
        let viewModel = createViewModel()

        #expect(viewModel.isCompleted == false)

        let result = await viewModel.skipOnboarding()

        #expect(result == true)
        #expect(viewModel.isCompleted == true)
        #expect(viewModel.isLoading == false)
    }

    @Test("skipOnboarding sets error on failure")
    @MainActor
    func skipOnboardingFailure() async {
        let viewModel = createViewModel(onboardingRepoShouldFail: true)

        let result = await viewModel.skipOnboarding()

        #expect(result == false)
        #expect(viewModel.isCompleted == false)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }

    // MARK: - Finish Onboarding Tests

    @Test("finishOnboarding sets isCompleted on success")
    @MainActor
    func finishOnboardingSuccess() async {
        let viewModel = createViewModel()
        viewModel.userName = "Test User"

        let result = await viewModel.finishOnboarding()

        #expect(result == true)
        #expect(viewModel.isCompleted == true)
        #expect(viewModel.isLoading == false)
    }

    @Test("finishOnboarding sets error on failure")
    @MainActor
    func finishOnboardingFailure() async {
        let viewModel = createViewModel(onboardingRepoShouldFail: true)

        let result = await viewModel.finishOnboarding()

        #expect(result == false)
        #expect(viewModel.isCompleted == false)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("finishOnboarding saves gender and ageGroup to profile")
    @MainActor
    func finishOnboardingSavesGenderAgeGroup() async {
        let mockOnboardingRepo = MockOnboardingRepository()
        let mockProfileRepo = MockProfileRepositoryForOnboarding()
        let mockiCloudService = MockiCloudKeyValueServiceForOnboarding()

        let getOnboardingState = GetOnboardingState(repo: mockOnboardingRepo)
        let saveOnboardingState = SaveOnboardingState(repo: mockOnboardingRepo)
        let completeOnboarding = CompleteOnboarding(
            repo: mockOnboardingRepo,
            profileRepo: mockProfileRepo,
            iCloudKeyValueService: mockiCloudService
        )

        let viewModel = OnboardingViewModel(
            getOnboardingState: getOnboardingState,
            saveOnboardingState: saveOnboardingState,
            completeOnboarding: completeOnboarding,
            requestNotificationPermission: MockRequestNotificationPermission(),
            checkNotificationStatus: MockCheckNotificationStatus(),
            requestLocationPermissions: MockRequestLocationPermissions(),
            getLocationAuthStatus: MockGetLocationAuthStatus()
        )

        viewModel.userName = "Test User"
        viewModel.gender = .female
        viewModel.ageGroup = .age25to34

        let result = await viewModel.finishOnboarding()

        #expect(result == true)
        #expect(mockProfileRepo.savedProfile?.name == "Test User")
        #expect(mockProfileRepo.savedProfile?.gender == "female")
        #expect(mockProfileRepo.savedProfile?.ageGroup == "25_34")
    }

    @Test("finishOnboarding saves preferNotToSay values (not nil)")
    @MainActor
    func finishOnboardingSavesPreferNotToSay() async {
        let mockOnboardingRepo = MockOnboardingRepository()
        let mockProfileRepo = MockProfileRepositoryForOnboarding()
        let mockiCloudService = MockiCloudKeyValueServiceForOnboarding()

        let getOnboardingState = GetOnboardingState(repo: mockOnboardingRepo)
        let saveOnboardingState = SaveOnboardingState(repo: mockOnboardingRepo)
        let completeOnboarding = CompleteOnboarding(
            repo: mockOnboardingRepo,
            profileRepo: mockProfileRepo,
            iCloudKeyValueService: mockiCloudService
        )

        let viewModel = OnboardingViewModel(
            getOnboardingState: getOnboardingState,
            saveOnboardingState: saveOnboardingState,
            completeOnboarding: completeOnboarding,
            requestNotificationPermission: MockRequestNotificationPermission(),
            checkNotificationStatus: MockCheckNotificationStatus(),
            requestLocationPermissions: MockRequestLocationPermissions(),
            getLocationAuthStatus: MockGetLocationAuthStatus()
        )

        viewModel.userName = "Test User"
        // Leave defaults (preferNotToSay)
        #expect(viewModel.gender == .preferNotToSay)
        #expect(viewModel.ageGroup == .preferNotToSay)

        let result = await viewModel.finishOnboarding()

        #expect(result == true)
        // preferNotToSay is saved as actual value (not nil) to distinguish from "never asked"
        // This prevents infinite prompt loops for returning users
        #expect(mockProfileRepo.savedProfile?.gender == "prefer_not_to_say")
        #expect(mockProfileRepo.savedProfile?.ageGroup == "prefer_not_to_say")
    }

    @Test("skipOnboarding saves prefer_not_to_say for gender and ageGroup")
    @MainActor
    func skipOnboardingSavesPreferNotToSayGenderAgeGroup() async {
        let mockOnboardingRepo = MockOnboardingRepository()
        let mockProfileRepo = MockProfileRepositoryForOnboarding()
        let mockiCloudService = MockiCloudKeyValueServiceForOnboarding()

        let getOnboardingState = GetOnboardingState(repo: mockOnboardingRepo)
        let saveOnboardingState = SaveOnboardingState(repo: mockOnboardingRepo)
        let completeOnboarding = CompleteOnboarding(
            repo: mockOnboardingRepo,
            profileRepo: mockProfileRepo,
            iCloudKeyValueService: mockiCloudService
        )

        let viewModel = OnboardingViewModel(
            getOnboardingState: getOnboardingState,
            saveOnboardingState: saveOnboardingState,
            completeOnboarding: completeOnboarding,
            requestNotificationPermission: MockRequestNotificationPermission(),
            checkNotificationStatus: MockCheckNotificationStatus(),
            requestLocationPermissions: MockRequestLocationPermissions(),
            getLocationAuthStatus: MockGetLocationAuthStatus()
        )

        let result = await viewModel.skipOnboarding()

        #expect(result == true)
        // skipOnboarding passes prefer_not_to_say for gender/ageGroup to ensure
        // returning user detection works even when user skips onboarding
        #expect(mockProfileRepo.savedProfile?.gender == "prefer_not_to_say")
        #expect(mockProfileRepo.savedProfile?.ageGroup == "prefer_not_to_say")
    }

    // MARK: - Load Onboarding State Tests

    @Test("loadOnboardingState restores saved state")
    @MainActor
    func loadOnboardingStateSuccess() async {
        // Create a saved state to restore (OnboardingState only has these fields)
        let savedState = OnboardingState(
            isCompleted: false,
            userName: "Restored User",
            hasGrantedNotifications: true
        )

        let viewModel = createViewModel(existingOnboardingState: savedState)

        await viewModel.loadOnboardingState()

        #expect(viewModel.userName == "Restored User")
        #expect(viewModel.hasGrantedNotifications == true)
        #expect(viewModel.isLoading == false)
    }

    @Test("loadOnboardingState handles nil state gracefully")
    @MainActor
    func loadOnboardingStateNilState() async {
        // No saved state (nil)
        let viewModel = createViewModel(existingOnboardingState: nil)

        await viewModel.loadOnboardingState()

        // Should keep defaults when no state exists
        #expect(viewModel.userName == "")
        #expect(viewModel.hasGrantedNotifications == false)
        #expect(viewModel.isLoading == false)
    }

    @Test("loadOnboardingState sets error on failure")
    @MainActor
    func loadOnboardingStateFailure() async {
        let viewModel = createViewModel(onboardingRepoShouldFail: true)

        await viewModel.loadOnboardingState()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }
}

// MARK: - SyncedDataSummary Tests

#if swift(>=6.1)
@Suite("SyncedDataSummary Tests", .tags(.isolated, .fast))
#else
@Suite("SyncedDataSummary Tests")
#endif
struct SyncedDataSummaryTests {

    @Test("needsProfileCompletion returns false when name is nil but demographics present")
    func noCompletionNeededWithNilName() {
        // Name is optional - user may have skipped entering it during onboarding
        // Only gender and ageGroup are required for profile completion
        let summary = SyncedDataSummary(
            habitsCount: 5,
            categoriesCount: 2,
            hasProfile: true,
            profileName: nil,
            profileAvatar: nil,
            profileGender: "male",
            profileAgeGroup: "25_34"
        )

        #expect(summary.needsProfileCompletion == false)
    }

    @Test("needsProfileCompletion returns false when name is empty but demographics present")
    func noCompletionNeededWithEmptyName() {
        // Name is optional - user may have skipped entering it during onboarding
        // Only gender and ageGroup are required for profile completion
        let summary = SyncedDataSummary(
            habitsCount: 5,
            categoriesCount: 2,
            hasProfile: true,
            profileName: "",
            profileAvatar: nil,
            profileGender: "male",
            profileAgeGroup: "25_34"
        )

        #expect(summary.needsProfileCompletion == false)
    }

    @Test("needsProfileCompletion returns true when gender is nil")
    func needsCompletionWithNilGender() {
        let summary = SyncedDataSummary(
            habitsCount: 5,
            categoriesCount: 2,
            hasProfile: true,
            profileName: "Test User",
            profileAvatar: nil,
            profileGender: nil,
            profileAgeGroup: "25_34"
        )

        #expect(summary.needsProfileCompletion == true)
    }

    @Test("needsProfileCompletion returns true when ageGroup is nil")
    func needsCompletionWithNilAgeGroup() {
        let summary = SyncedDataSummary(
            habitsCount: 5,
            categoriesCount: 2,
            hasProfile: true,
            profileName: "Test User",
            profileAvatar: nil,
            profileGender: "female",
            profileAgeGroup: nil
        )

        #expect(summary.needsProfileCompletion == true)
    }

    @Test("needsProfileCompletion returns true when all profile fields are nil")
    func needsCompletionWithAllNil() {
        let summary = SyncedDataSummary(
            habitsCount: 5,
            categoriesCount: 2,
            hasProfile: true,
            profileName: nil,
            profileAvatar: nil,
            profileGender: nil,
            profileAgeGroup: nil
        )

        #expect(summary.needsProfileCompletion == true)
    }

    @Test("needsProfileCompletion returns false when all fields present")
    func noCompletionNeededWhenAllPresent() {
        let summary = SyncedDataSummary(
            habitsCount: 5,
            categoriesCount: 2,
            hasProfile: true,
            profileName: "Test User",
            profileAvatar: nil,
            profileGender: "male",
            profileAgeGroup: "25_34"
        )

        #expect(summary.needsProfileCompletion == false)
    }

    @Test("needsProfileCompletion with prefer_not_to_say values counts as present")
    func preferNotToSayCountsAsPresent() {
        let summary = SyncedDataSummary(
            habitsCount: 5,
            categoriesCount: 2,
            hasProfile: true,
            profileName: "Test User",
            profileAvatar: nil,
            profileGender: "prefer_not_to_say",
            profileAgeGroup: "prefer_not_to_say"
        )

        #expect(summary.needsProfileCompletion == false)
    }

    @Test("empty summary needs profile completion")
    func emptySummaryNeedsCompletion() {
        #expect(SyncedDataSummary.empty.needsProfileCompletion == true)
    }

    @Test("hasData returns true when habitsCount > 0")
    func hasDataWithHabits() {
        let summary = SyncedDataSummary(
            habitsCount: 5,
            categoriesCount: 0,
            hasProfile: false,
            profileName: nil,
            profileAvatar: nil
        )

        #expect(summary.hasData == true)
    }

    @Test("hasData returns true when hasProfile is true")
    func hasDataWithProfile() {
        let summary = SyncedDataSummary(
            habitsCount: 0,
            categoriesCount: 2,
            hasProfile: true,
            profileName: "Test",
            profileAvatar: nil
        )

        #expect(summary.hasData == true)
    }

    @Test("hasData returns false when no habits and no profile")
    func hasDataReturnsFalse() {
        let summary = SyncedDataSummary(
            habitsCount: 0,
            categoriesCount: 2,
            hasProfile: false,
            profileName: nil,
            profileAvatar: nil
        )

        #expect(summary.hasData == false)
    }
}

// MARK: - Mock Repositories

final class MockOnboardingRepository: OnboardingRepository, @unchecked Sendable {
    var savedState: OnboardingState?
    var stateToReturn: OnboardingState?
    var shouldFail = false

    func getOnboardingState() async throws -> OnboardingState? {
        if shouldFail {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        return stateToReturn
    }

    func saveOnboardingState(_ state: OnboardingState) async throws {
        if shouldFail {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        savedState = state
    }
}

final class MockProfileRepositoryForOnboarding: ProfileRepository, @unchecked Sendable {
    var savedProfile: UserProfile?
    var profileToReturn: UserProfile?
    var shouldFail = false

    func loadProfile() async throws -> UserProfile? {
        if shouldFail {
            throw NSError(domain: "test", code: 1, userInfo: nil)
        }
        return profileToReturn
    }

    func saveProfile(_ profile: UserProfile) async throws {
        if shouldFail {
            throw NSError(domain: "test", code: 1, userInfo: nil)
        }
        savedProfile = profile
    }
}

final class MockiCloudKeyValueServiceForOnboarding: iCloudKeyValueService, @unchecked Sendable {
    var iCloudOnboardingCompleted = false
    var localOnboardingCompleted = false

    func hasCompletedOnboarding() -> Bool { iCloudOnboardingCompleted }
    func setOnboardingCompleted() { iCloudOnboardingCompleted = true }
    func synchronize() {}
    func synchronizeAndWait(timeout: TimeInterval) async -> Bool { true }
    func resetOnboardingFlag() { iCloudOnboardingCompleted = false }
    func hasCompletedOnboardingLocally() -> Bool { localOnboardingCompleted }
    func setOnboardingCompletedLocally() { localOnboardingCompleted = true }
    func resetLocalOnboardingFlag() { localOnboardingCompleted = false }
}

// MARK: - Mock Use Cases (for notification/location)

final class MockRequestNotificationPermission: RequestNotificationPermissionUseCase, @unchecked Sendable {
    var shouldGrant = true
    var shouldFail = false

    func execute() async throws -> Bool {
        if shouldFail {
            throw NSError(domain: "test", code: 1, userInfo: nil)
        }
        return shouldGrant
    }
}

final class MockCheckNotificationStatus: CheckNotificationStatusUseCase, @unchecked Sendable {
    var isGranted = false

    func execute() async -> Bool {
        return isGranted
    }
}

final class MockRequestLocationPermissions: RequestLocationPermissionsUseCase, @unchecked Sendable {
    var resultToReturn: LocationPermissionResult = .granted(.authorizedWhenInUse)

    func execute(requestAlways: Bool) async -> LocationPermissionResult {
        return resultToReturn
    }
}

final class MockGetLocationAuthStatus: GetLocationAuthStatusUseCase, @unchecked Sendable {
    var statusToReturn: LocationAuthorizationStatus = .notDetermined

    func execute() async -> LocationAuthorizationStatus {
        return statusToReturn
    }
}
