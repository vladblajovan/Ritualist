import Foundation

// MARK: - User Management Use Case Implementations

// UserService-based subscription update
public final class UpdateProfileSubscription: UpdateProfileSubscriptionUseCase {
    private let userService: UserService
    private let paywallService: PaywallService
    
    public init(userService: UserService, paywallService: PaywallService) {
        self.userService = userService
        self.paywallService = paywallService
    }
    
    public func execute(product: Product) async throws {
        // Calculate expiry date based on product duration
        let calendar = Calendar.current
        let expiryDate: Date?
        
        switch product.duration {
        case .monthly:
            expiryDate = calendar.date(byAdding: .month, value: 1, to: Date())
        case .annual:
            expiryDate = calendar.date(byAdding: .year, value: 1, to: Date())
        }
        
        // Update subscription through user service (single source of truth)
        try await userService.updateSubscription(plan: product.subscriptionPlan, expiryDate: expiryDate)
        
        // Update purchase state in paywall service
        if let mockService = paywallService as? MockPaywallService {
            mockService.purchaseState = .success(product)
        }
    }
}

public final class CheckPremiumStatus: CheckPremiumStatusUseCase {
    private let userService: UserService
    
    public init(userService: UserService) {
        self.userService = userService
    }
    
    public func execute() async -> Bool {
        userService.isPremiumUser
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
    private let userService: UserService
    
    public init(userService: UserService) {
        self.userService = userService
    }
    
    public func execute(plan: SubscriptionPlan, expiryDate: Date?) async throws {
        try await userService.updateSubscription(plan: plan, expiryDate: expiryDate)
    }
}