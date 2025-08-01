import Foundation
import Combine

// MARK: - PaywallService Protocol

public protocol PaywallService {
    var purchaseState: PurchaseState { get }
    var purchaseStatePublisher: AnyPublisher<PurchaseState, Never> { get }
    
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

// MARK: - Mock PaywallService

public final class MockPaywallService: PaywallService, ObservableObject {
    @Published public var purchaseState: PurchaseState = .idle
    
    public var purchaseStatePublisher: AnyPublisher<PurchaseState, Never> {
        $purchaseState.eraseToAnyPublisher()
    }
    
    // Mock products
    private let mockProducts: [Product] = [
        Product(
            id: "ritualist_monthly",
            name: "Ritualist Pro",
            description: "Monthly subscription",
            price: "$9.99",
            localizedPrice: "$9.99/month",
            subscriptionPlan: .monthly,
            duration: .monthly,
            features: [
                "Unlimited habits",
                "Advanced analytics",
                "Custom reminders",
                "Data export",
                "Priority support"
            ],
            isPopular: false
        ),
        Product(
            id: "ritualist_annual",
            name: "Ritualist Pro",
            description: "Annual subscription (2 months free!)",
            price: "$39.99",
            localizedPrice: "$39.99/year",
            subscriptionPlan: .annual,
            duration: .annual,
            features: [
                "Unlimited habits",
                "Advanced analytics",
                "Custom reminders",
                "Data export",
                "Priority support",
                "Save 67% vs monthly"
            ],
            isPopular: true,
            discount: "Save 67%"
        )
    ]
    
    // Track purchased products
    private var purchasedProductIds: Set<String> = []
    
    public init() {}
    
    public func loadProducts() async throws -> [Product] {
        mockProducts
    }
    
    public func purchase(_ product: Product) async throws -> Bool {
        purchaseState = .purchasing(product.id)
        
        // Simulate purchase delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Simulate random success/failure for testing
        let shouldSucceed = Int.random(in: 1...10) <= 8 // 80% success rate
        
        if shouldSucceed {
            purchasedProductIds.insert(product.id)
            purchaseState = .success(product)
            
            // Store purchase in UserDefaults for persistence
            var purchased = UserDefaults.standard.stringArray(forKey: "purchased_products") ?? []
            if !purchased.contains(product.id) {
                purchased.append(product.id)
                UserDefaults.standard.set(purchased, forKey: "purchased_products")
            }
            
            return true
        } else {
            purchaseState = .failed("Purchase failed. Please try again.")
            return false
        }
    }
    
    public func restorePurchases() async throws -> Bool {
        purchaseState = .purchasing("restore")
        
        // Simulate restore delay
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Restore from UserDefaults
        let purchased = UserDefaults.standard.stringArray(forKey: "purchased_products") ?? []
        purchasedProductIds = Set(purchased)
        
        purchaseState = .idle
        return !purchasedProductIds.isEmpty
    }
    
    public func isProductPurchased(_ productId: String) async -> Bool {
        // Also check UserDefaults for persistence
        let purchased = UserDefaults.standard.stringArray(forKey: "purchased_products") ?? []
        return purchasedProductIds.contains(productId) || purchased.contains(productId)
    }
    
    public func resetPurchaseState() {
        purchaseState = .idle
    }
    
    public func clearPurchases() {
        purchasedProductIds.removeAll()
        UserDefaults.standard.removeObject(forKey: "purchased_products")
        purchaseState = .idle
    }
}

// MARK: - NoOp PaywallService (for minimal container)

public final class NoOpPaywallService: PaywallService, ObservableObject {
    @Published public var purchaseState: PurchaseState = .idle
    
    public var purchaseStatePublisher: AnyPublisher<PurchaseState, Never> {
        $purchaseState.eraseToAnyPublisher()
    }
    
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

// MARK: - Production PaywallService (Placeholder)

@MainActor
public final class ProductionPaywallService: PaywallService, ObservableObject {
    @Published public var purchaseState: PurchaseState = .idle
    
    public var purchaseStatePublisher: AnyPublisher<PurchaseState, Never> {
        $purchaseState.eraseToAnyPublisher()
    }
    
    public init() {}
    
    public func loadProducts() async throws -> [Product] {
        // TODO: Implement StoreKit integration
        throw PaywallError.productsNotAvailable
    }
    
    public func purchase(_ product: Product) async throws -> Bool {
        // TODO: Implement StoreKit purchase flow
        throw PaywallError.purchaseFailed("StoreKit integration not implemented")
    }
    
    public func restorePurchases() async throws -> Bool {
        // TODO: Implement StoreKit restore purchases
        throw PaywallError.purchaseFailed("StoreKit integration not implemented")
    }
    
    public func isProductPurchased(_ productId: String) async -> Bool {
        // TODO: Check StoreKit transaction history
        false
    }
    
    public func resetPurchaseState() {
        purchaseState = .idle
    }
    
    public func clearPurchases() {
        // TODO: Clear StoreKit purchases when subscription is cancelled
    }
}

