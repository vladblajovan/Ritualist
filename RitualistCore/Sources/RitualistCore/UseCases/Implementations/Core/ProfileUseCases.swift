import Foundation

// MARK: - Profile Use Case Implementations

public final class LoadProfile: LoadProfileUseCase {
    private let repo: ProfileRepository
    public init(repo: ProfileRepository) { self.repo = repo }
    public func execute() async throws -> UserProfile {
        // Load profile or create default with system settings (business logic)
        if let profile = try await repo.loadProfile() {
            return profile
        } else {
            // Create profile with system defaults using three-timezone model
            // All timezones initialize to device timezone, display mode defaults to .current
            let defaultProfile = UserProfile(
                appearance: AppearanceManager.getSystemAppearance()
                // currentTimezoneIdentifier, homeTimezoneIdentifier, and displayTimezoneMode
                // use default values from UserProfile init
            )
            try await repo.saveProfile(defaultProfile)
            return defaultProfile
        }
    }
}

public final class SaveProfile: SaveProfileUseCase {
    private let repo: ProfileRepository
    public init(repo: ProfileRepository) { self.repo = repo }
    public func execute(_ profile: UserProfile) async throws { try await repo.saveProfile(profile) }
}