import Foundation

// MARK: - User Management Use Case Implementations

// UserService-based subscription update
public final class UpdateProfileSubscription: UpdateProfileSubscriptionUseCase {
    // NOTE: This UseCase is now obsolete since subscription data is no longer stored in the database.
    // Subscription status is managed entirely by SecureSubscriptionService (via StoreKit transactions).
    // This implementation is kept as a no-op for backward compatibility.

    public init() {
        // No dependencies needed
    }

    public func execute(product: Product) async throws {
        // No-op: Subscription is managed by SubscriptionService via StoreKit, not database
    }
}

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

public final class UpdateUserSubscription: UpdateUserSubscriptionUseCase {
    // NOTE: This UseCase is now obsolete since subscription data is no longer stored in the database.
    // Subscription status is managed entirely by SecureSubscriptionService (UserDefaults in mock, StoreKit in production).
    // This implementation is kept as a no-op for backward compatibility.

    public init() {
        // No dependencies needed
    }

    public func execute(plan: SubscriptionPlan, expiryDate: Date?) async throws {
        // No-op: Subscription is managed by SubscriptionService, not database
    }
}