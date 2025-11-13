import Foundation

// MARK: - User Management Use Case Implementations

public final class CheckPremiumStatus: CheckPremiumStatusUseCase {
    private let subscriptionService: SecureSubscriptionService

    public init(subscriptionService: SecureSubscriptionService) {
        self.subscriptionService = subscriptionService
    }

    public func execute() async -> Bool {
        subscriptionService.isPremiumUser()
    }
}

public final class GetCurrentSubscriptionPlan: GetCurrentSubscriptionPlanUseCase {
    private let subscriptionService: SecureSubscriptionService

    public init(subscriptionService: SecureSubscriptionService) {
        self.subscriptionService = subscriptionService
    }

    public func execute() async -> SubscriptionPlan {
        await subscriptionService.getCurrentSubscriptionPlan()
    }
}

public final class GetSubscriptionExpiryDate: GetSubscriptionExpiryDateUseCase {
    private let subscriptionService: SecureSubscriptionService

    public init(subscriptionService: SecureSubscriptionService) {
        self.subscriptionService = subscriptionService
    }

    public func execute() async -> Date? {
        await subscriptionService.getSubscriptionExpiryDate()
    }
}

public final class GetCurrentUserProfile: GetCurrentUserProfileUseCase {
    private let userService: UserService

    public init(userService: UserService) {
        self.userService = userService
    }

    public func execute() async -> UserProfile {
        userService.currentProfile
    }
}