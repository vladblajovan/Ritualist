import Foundation

// MARK: - Onboarding Use Case Implementations

public final class GetOnboardingState: GetOnboardingStateUseCase {
    private let repo: OnboardingRepository
    public init(repo: OnboardingRepository) { self.repo = repo }
    public func execute() async throws -> OnboardingState { try await repo.getOnboardingState() }
}

public final class SaveOnboardingState: SaveOnboardingStateUseCase {
    private let repo: OnboardingRepository
    public init(repo: OnboardingRepository) { self.repo = repo }
    public func execute(_ state: OnboardingState) async throws { try await repo.saveOnboardingState(state) }
}

public final class CompleteOnboarding: CompleteOnboardingUseCase {
    private let onboardingRepo: OnboardingRepository
    private let profileRepo: ProfileRepository
    
    public init(repo: OnboardingRepository, profileRepo: ProfileRepository) { 
        self.onboardingRepo = repo 
        self.profileRepo = profileRepo
    }
    
    public func execute(userName: String?, hasNotifications: Bool) async throws {
        // Mark onboarding as completed
        try await onboardingRepo.markOnboardingCompleted(userName: userName, hasNotifications: hasNotifications)
        
        // Update user profile with the name if provided
        if let userName = userName, !userName.isEmpty {
            var profile = try await profileRepo.loadProfile()
            profile.name = userName
            profile.updatedAt = Date()
            try await profileRepo.saveProfile(profile)
            
            // No need to sync to UserService - it uses ProfileRepository as single source of truth
        }
    }
}