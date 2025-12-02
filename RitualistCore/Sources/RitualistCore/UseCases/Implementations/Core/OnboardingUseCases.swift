import Foundation

// MARK: - Onboarding Use Case Implementations

public final class GetOnboardingState: GetOnboardingStateUseCase {
    private let repo: OnboardingRepository
    public init(repo: OnboardingRepository) { self.repo = repo }
    public func execute() async throws -> OnboardingState {
        // Return existing state or create new default state (business logic)
        if let state = try await repo.getOnboardingState() {
            return state
        } else {
            return OnboardingState()
        }
    }
}

public final class SaveOnboardingState: SaveOnboardingStateUseCase {
    private let repo: OnboardingRepository
    public init(repo: OnboardingRepository) { self.repo = repo }
    public func execute(_ state: OnboardingState) async throws { try await repo.saveOnboardingState(state) }
}

public final class CompleteOnboarding: CompleteOnboardingUseCase {
    private let onboardingRepo: OnboardingRepository
    private let profileRepo: ProfileRepository
    private let iCloudKeyValueService: iCloudKeyValueService?
    private let logger: DebugLogger

    public init(
        repo: OnboardingRepository,
        profileRepo: ProfileRepository,
        iCloudKeyValueService: iCloudKeyValueService? = nil,
        logger: DebugLogger = DebugLogger(subsystem: "com.vladblajovan.Ritualist", category: "onboarding")
    ) {
        self.onboardingRepo = repo
        self.profileRepo = profileRepo
        self.iCloudKeyValueService = iCloudKeyValueService
        self.logger = logger
    }

    public func execute(userName: String?, hasNotifications: Bool, hasLocation: Bool, gender: String?, ageGroup: String?) async throws {
        // Validate demographic values are valid enum cases (defensive check)
        if let gender = gender, UserGender(rawValue: gender) == nil {
            logger.log(
                "Invalid gender value passed to CompleteOnboarding",
                level: .warning,
                category: .dataIntegrity,
                metadata: ["raw_value": gender]
            )
        }
        if let ageGroup = ageGroup, UserAgeGroup(rawValue: ageGroup) == nil {
            logger.log(
                "Invalid ageGroup value passed to CompleteOnboarding",
                level: .warning,
                category: .dataIntegrity,
                metadata: ["raw_value": ageGroup]
            )
        }
        // Note: hasLocation is passed for completeness but not persisted - location permissions are checked at runtime
        // Create completed onboarding state (business logic moved from repository)
        let completedState = OnboardingState(
            isCompleted: true,
            completedDate: Date(),
            userName: userName,
            hasGrantedNotifications: hasNotifications
        )
        try await onboardingRepo.saveOnboardingState(completedState)

        // Set iCloud flag so other devices know onboarding was completed
        // This syncs almost instantly via NSUbiquitousKeyValueStore
        iCloudKeyValueService?.setOnboardingCompleted()

        // Also set local device flag so THIS device knows onboarding is done
        // This prevents showing returning user welcome on reinstall of same device
        iCloudKeyValueService?.setOnboardingCompletedLocally()

        // Update user profile with name, gender, and ageGroup
        // Load profile or create default if not exists (business logic)
        var profile: UserProfile
        if let existingProfile = try await profileRepo.loadProfile() {
            profile = existingProfile
        } else {
            // Create new profile with three-timezone model defaults
            // All timezones initialize to device timezone (safe default)
            profile = UserProfile(
                appearance: AppearanceManager.getSystemAppearance()
                // currentTimezoneIdentifier, homeTimezoneIdentifier, and displayTimezoneMode
                // use default values (device timezone and .current mode)
            )
        }

        // Update profile fields from onboarding
        if let userName = userName, !userName.isEmpty {
            profile.name = userName
        }
        if let gender = gender {
            profile.gender = gender
        }
        if let ageGroup = ageGroup {
            profile.ageGroup = ageGroup
        }
        profile.updatedAt = Date()

        try await profileRepo.saveProfile(profile)

        // No need to sync to UserService - it uses ProfileRepository as single source of truth
    }
}