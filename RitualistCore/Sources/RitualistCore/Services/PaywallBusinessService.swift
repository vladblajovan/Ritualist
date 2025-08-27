//
//  PaywallBusinessService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//

import Foundation

public protocol PaywallBusinessService {
    /// Load available products from the App Store
    func loadProducts() async throws -> [Product]
    
    /// Purchase a product
    func purchase(_ product: Product) async throws -> Bool
    
    /// Restore previous purchases
    func restorePurchases() async throws -> Bool
    
    /// Check if a specific product is purchased
    func isProductPurchased(_ productId: String) async -> Bool
    
    /// Clear all purchases for a user (useful when subscription is cancelled)
    func clearPurchases() async throws
}

// MARK: - Mock Implementation for Testing

public final class MockPaywallBusinessService: PaywallBusinessService {
    public enum TestScenario {
        case allSuccess
        case allFailure
        case randomResults
    }
    
    private var scenario: TestScenario = .randomResults
    private var delay: Double = 1.0
    private var failureRate: Double = 0.15
    
    public init(testingScenario: TestScenario = .randomResults) {
        self.scenario = testingScenario
    }
    
    public func configure(scenario: TestScenario, delay: Double = 1.0, failureRate: Double = 0.15) {
        self.scenario = scenario
        self.delay = delay
        self.failureRate = failureRate
    }
    
    public func loadProducts() async throws -> [Product] {
        try await Task.sleep(for: .seconds(delay))
        
        switch scenario {
        case .allSuccess:
            return mockProducts()
        case .allFailure:
            throw PaywallBusinessError.loadFailed("Mock failure")
        case .randomResults:
            if Double.random(in: 0...1) < failureRate {
                throw PaywallBusinessError.loadFailed("Random mock failure")
            }
            return mockProducts()
        }
    }
    
    public func purchase(_ product: Product) async throws -> Bool {
        try await Task.sleep(for: .seconds(delay))
        
        switch scenario {
        case .allSuccess:
            return true
        case .allFailure:
            throw PaywallBusinessError.purchaseFailed("Mock purchase failure")
        case .randomResults:
            if Double.random(in: 0...1) < failureRate {
                throw PaywallBusinessError.purchaseFailed("Random mock purchase failure")
            }
            return true
        }
    }
    
    public func restorePurchases() async throws -> Bool {
        try await Task.sleep(for: .seconds(delay))
        
        switch scenario {
        case .allSuccess:
            return true
        case .allFailure:
            throw PaywallBusinessError.restoreFailed("Mock restore failure")
        case .randomResults:
            if Double.random(in: 0...1) < failureRate {
                throw PaywallBusinessError.restoreFailed("Random mock restore failure")
            }
            return true
        }
    }
    
    public func isProductPurchased(_ productId: String) async -> Bool {
        // Simple mock: assume some products are "purchased"
        return ["premium_monthly", "premium_yearly"].contains(productId)
    }
    
    public func clearPurchases() async throws {
        try await Task.sleep(for: .seconds(0.1))
        // Mock implementation - no actual clearing needed
    }
    
    // MARK: - Helper Methods
    
    private func mockProducts() -> [Product] {
        return [
            Product(
                id: "premium_monthly",
                name: "Premium Monthly",
                description: "Premium features for one month",
                price: "$4.99",
                localizedPrice: "$4.99",
                subscriptionPlan: .monthly,
                duration: .monthly,
                features: ["Unlimited habits", "Advanced analytics", "Widgets"]
            ),
            Product(
                id: "premium_yearly", 
                name: "Premium Yearly",
                description: "Premium features for one year",
                price: "$39.99",
                localizedPrice: "$39.99",
                subscriptionPlan: .annual,
                duration: .annual,
                features: ["Unlimited habits", "Advanced analytics", "Widgets", "Save 50%"],
                isPopular: true
            )
        ]
    }
}

// MARK: - Error Types

public enum PaywallBusinessError: LocalizedError {
    case loadFailed(String)
    case purchaseFailed(String)  
    case restoreFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .loadFailed(let message):
            return "Failed to load products: \(message)"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .restoreFailed(let message):
            return "Restore failed: \(message)"
        }
    }
}

// MARK: - No-Op Implementation

public final class NoOpPaywallBusinessService: PaywallBusinessService {
    public init() {}
    
    public func loadProducts() async throws -> [Product] {
        return []
    }
    
    public func purchase(_ product: Product) async throws -> Bool {
        return false
    }
    
    public func restorePurchases() async throws -> Bool {
        return false
    }
    
    public func isProductPurchased(_ productId: String) async -> Bool {
        return false
    }
    
    public func clearPurchases() async throws {
        // No-op
    }
}
