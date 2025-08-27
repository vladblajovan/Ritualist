//
//  PaywallService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//

import Foundation

public protocol PaywallService {
    var purchaseState: PurchaseState { get }
    
    /// Load available products from the App Store
    func loadProducts() async throws -> [Product]
    
    /// Purchase a product
    func purchase(_ product: Product) async throws -> Bool
    
    /// Restore previous purchases
    func restorePurchases() async throws -> Bool
    
    /// Check if a specific product is purchased
    func isProductPurchased(_ productId: String) async -> Bool
    
    /// Reset purchase state to idle (useful for UI state management)
    func resetPurchaseState()
    
    /// Clear all purchases for a user (useful when subscription is cancelled)
    func clearPurchases()
}

// MARK: - Mock Implementation

@Observable
public final class MockPaywallService: PaywallService {
    public var purchaseState: PurchaseState = .idle
    
    // MARK: - Dependencies
    private let subscriptionService: SecureSubscriptionService
    
    // Enhanced mock products with realistic pricing and features
    private let mockProducts: [Product] = [
        Product(
            id: "ritualist_weekly",
            name: "Ritualist Pro",
            description: "Weekly trial - Perfect to get started",
            price: "$2.99",
            localizedPrice: "$2.99/week",
            subscriptionPlan: .monthly, // Using monthly for now as there's no weekly enum
            duration: .monthly,
            features: [
                "Unlimited habits",
                "Basic analytics",
                "Custom reminders"
            ],
            isPopular: false
        ),
        Product(
            id: "ritualist_monthly",
            name: "Ritualist Pro",
            description: "Most flexible option",
            price: "$9.99",
            localizedPrice: "$9.99/month",
            subscriptionPlan: .monthly,
            duration: .monthly,
            features: [
                "Unlimited habits",
                "Advanced analytics & insights",
                "Custom reminders & notifications",
                "Data export (CSV, PDF)",
                "Dark mode & themes",
                "Priority support"
            ],
            isPopular: false
        ),
        Product(
            id: "ritualist_annual",
            name: "Ritualist Pro",
            description: "Best value - Save 58%!",
            price: "$49.99",
            localizedPrice: "$49.99/year",
            subscriptionPlan: .annual,
            duration: .annual,
            features: [
                "Unlimited habits",
                "Advanced analytics & insights",
                "Custom reminders & notifications",
                "Data export (CSV, PDF)",
                "Dark mode & premium themes",
                "Priority support",
                "Early access to new features",
                "Cloud backup & sync"
            ],
            isPopular: true,
            discount: "Save 58%"
        ),
        Product(
            id: "ritualist_lifetime",
            name: "Ritualist Pro Lifetime",
            description: "One-time purchase, lifetime access",
            price: "$149.99",
            localizedPrice: "$149.99 once",
            subscriptionPlan: .monthly, // Using monthly as there's no lifetime enum
            duration: .monthly,
            features: [
                "Everything in Pro",
                "Lifetime updates",
                "No recurring charges",
                "Premium support forever",
                "Exclusive lifetime features"
            ],
            isPopular: false,
            discount: "Best Deal"
        )
    ]
    
    // Enhanced testing configuration
    public var simulatePurchaseDelay: TimeInterval = 2.0
    public var simulateFailureRate: Double = 0.2 // 20% failure rate by default
    public var simulateNetworkError: Bool = false
    public var simulateUserCancellation: Bool = false
    
    // Testing scenarios
    public enum TestingScenario {
        case alwaysSucceed
        case alwaysFail
        case randomResults
        case networkError
        case userCancellation
    }
    
    public var currentTestingScenario: TestingScenario = .randomResults
    
    public init(subscriptionService: SecureSubscriptionService, testingScenario: TestingScenario = .randomResults) {
        self.subscriptionService = subscriptionService
        self.currentTestingScenario = testingScenario
    }
    
    public func loadProducts() async throws -> [Product] {
        // If all features are enabled at build time, return empty products
        #if ALL_FEATURES_ENABLED
        return []
        #else
        return mockProducts
        #endif
    }
    
    public func purchase(_ product: Product) async throws -> Bool {
        purchaseState = .purchasing(product.id)
        
        // Simulate realistic purchase delay
        let delayNanoseconds = UInt64(simulatePurchaseDelay * 1_000_000_000)
        try await Task.sleep(nanoseconds: delayNanoseconds)
        
        // Determine outcome based on testing scenario
        let shouldSucceed: Bool
        switch currentTestingScenario {
        case .alwaysSucceed:
            shouldSucceed = true
        case .alwaysFail:
            shouldSucceed = false
        case .randomResults:
            shouldSucceed = Double.random(in: 0...1) > simulateFailureRate
        case .networkError:
            purchaseState = .failed("Network connection failed. Please check your internet and try again.")
            throw PaywallError.networkError
        case .userCancellation:
            purchaseState = .idle
            throw PaywallError.userCancelled
        }
        
        if shouldSucceed {
            // Use secure subscription service to validate purchase
            try await subscriptionService.mockPurchase(product.id)
            purchaseState = .success(product)
            
            return true
        } else {
            let errorMessages = [
                "Purchase failed. Please try again.",
                "Payment processing failed. Please verify your payment method.",
                "App Store connection timeout. Please try again later.",
                "Insufficient funds. Please check your payment method.",
                "Purchase cannot be completed at this time."
            ]
            purchaseState = .failed(errorMessages.randomElement() ?? "Purchase failed")
            return false
        }
    }
    
    public func restorePurchases() async throws -> Bool {
        purchaseState = .purchasing("restore")
        
        // Simulate restore delay (typically faster than purchase)
        let restoreDelay = simulatePurchaseDelay * 0.75
        let delayNanoseconds = UInt64(restoreDelay * 1_000_000_000)
        try await Task.sleep(nanoseconds: delayNanoseconds)
        
        // Handle different testing scenarios for restore
        switch currentTestingScenario {
        case .networkError:
            purchaseState = .failed("Unable to connect to App Store. Please check your internet connection.")
            throw PaywallError.networkError
        case .alwaysFail:
            purchaseState = .failed("Unable to restore purchases. Please try again later.")
            return false
        default:
            // Restore using secure subscription service
            let restoredPurchases = await subscriptionService.restorePurchases()
            
            purchaseState = .idle
            return !restoredPurchases.isEmpty
        }
    }
    
    public func isProductPurchased(_ productId: String) async -> Bool {
        return await subscriptionService.validatePurchase(productId)
    }
    
    public func resetPurchaseState() {
        purchaseState = .idle
    }
    
    public func clearPurchases() {
        Task {
            try await subscriptionService.clearPurchases()
        }
        purchaseState = .idle
    }
    
    // MARK: - Enhanced Testing Methods
    
    /// Configure mock service for specific testing needs
    public func configure(scenario: TestingScenario, delay: TimeInterval = 2.0, failureRate: Double = 0.2) {
        currentTestingScenario = scenario
        simulatePurchaseDelay = delay
        simulateFailureRate = failureRate
    }
    
    /// Simulate purchasing a specific product (for testing)
    public func simulatePurchase(productId: String) {
        Task {
            try await subscriptionService.mockPurchase(productId)
        }
    }
    
    /// Get current product catalog for testing
    public func getTestProducts() -> [Product] {
        mockProducts
    }
    
    /// Check if any premium product is purchased (useful for testing subscription status)
    public var hasPremiumPurchase: Bool {
        subscriptionService.isPremiumUser()
    }
}

// MARK: - NoOp Implementation

@Observable
public final class NoOpPaywallService: PaywallService {
    public var purchaseState: PurchaseState = .idle
    
    public init() {}
    
    public func loadProducts() async throws -> [Product] {
        []
    }
    
    public func purchase(_ product: Product) async throws -> Bool {
        false
    }
    
    public func restorePurchases() async throws -> Bool {
        false
    }
    
    public func isProductPurchased(_ productId: String) async -> Bool {
        false
    }
    
    public func resetPurchaseState() {
        purchaseState = .idle
    }
    
    public func clearPurchases() {
        // No-op implementation
    }
}
