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
            // Create profile with system defaults including timezone preferences
            let defaultProfile = UserProfile(
                appearance: AppearanceManager.getSystemAppearance(),
                homeTimezone: nil, // No home timezone set initially
                displayTimezoneMode: "original" // Default to showing logs as originally experienced
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