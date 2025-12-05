import Foundation

// MARK: - Profile Use Case Implementations

public final class LoadProfile: LoadProfileUseCase {
    private let repo: ProfileRepository
    private let iCloudKeyValueService: iCloudKeyValueService?

    public init(repo: ProfileRepository, iCloudKeyValueService: iCloudKeyValueService? = nil) {
        self.repo = repo
        self.iCloudKeyValueService = iCloudKeyValueService
    }

    public func execute() async throws -> UserProfile {
        // Load profile if it exists in local database
        if let profile = try await repo.loadProfile() {
            return profile
        }

        // No local profile found - check if this is a returning user
        // Returning user = iCloud flag set (completed onboarding on another device)
        //                  but local device flag NOT set (this device is fresh)
        let iCloudOnboardingCompleted = iCloudKeyValueService?.hasCompletedOnboarding() ?? false
        let localDeviceCompleted = iCloudKeyValueService?.hasCompletedOnboardingLocally() ?? false
        let isReturningUser = iCloudOnboardingCompleted && !localDeviceCompleted

        // Create default profile with system settings
        let defaultProfile = UserProfile(
            appearance: AppearanceManager.getSystemAppearance()
            // currentTimezoneIdentifier, homeTimezoneIdentifier, and displayTimezoneMode
            // use default values from UserProfile init
        )

        if isReturningUser {
            // DON'T save for returning users - wait for CloudKit to sync the real profile
            // Saving an empty profile here would conflict with the incoming iCloud data
            return defaultProfile
        }

        // New user - create and save default profile
        try await repo.saveProfile(defaultProfile)
        return defaultProfile
    }
}

public final class SaveProfile: SaveProfileUseCase {
    private let repo: ProfileRepository
    public init(repo: ProfileRepository) { self.repo = repo }
    public func execute(_ profile: UserProfile) async throws { try await repo.saveProfile(profile) }
}