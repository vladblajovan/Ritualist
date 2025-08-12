import Foundation
import RitualistCore

// MARK: - Business Service Protocol (Thread-Agnostic)

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

// MARK: - Legacy PaywallService Protocol (Deprecated)

@available(*, deprecated, message: "Use PaywallBusinessService + PaywallUIService instead")
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

// MARK: - Business Service Implementations

public final class MockPaywallBusinessService: PaywallBusinessService {
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
            throw PaywallError.networkError
        case .userCancellation:
            throw PaywallError.userCancelled
        }
        
        if shouldSucceed {
            // Use secure subscription service to validate purchase
            try await subscriptionService.mockPurchase(product.id)
            return true
        } else {
            throw PaywallError.purchaseFailed("Purchase failed")
        }
    }
    
    public func restorePurchases() async throws -> Bool {
        // Simulate restore delay (typically faster than purchase)
        let restoreDelay = simulatePurchaseDelay * 0.75
        let delayNanoseconds = UInt64(restoreDelay * 1_000_000_000)
        try await Task.sleep(nanoseconds: delayNanoseconds)
        
        // Handle different testing scenarios for restore
        switch currentTestingScenario {
        case .networkError:
            throw PaywallError.networkError
        case .alwaysFail:
            return false
        default:
            // Restore using secure subscription service
            let restoredPurchases = await subscriptionService.restorePurchases()
            return !restoredPurchases.isEmpty
        }
    }
    
    public func isProductPurchased(_ productId: String) async -> Bool {
        return await subscriptionService.validatePurchase(productId)
    }
    
    public func clearPurchases() async throws {
        try await subscriptionService.clearPurchases()
    }
    
    // MARK: - Enhanced Testing Methods
    
    /// Configure mock service for specific testing needs
    public func configure(scenario: TestingScenario, delay: TimeInterval = 2.0, failureRate: Double = 0.2) {
        currentTestingScenario = scenario
        simulatePurchaseDelay = delay
        simulateFailureRate = failureRate
    }
    
    /// Simulate purchasing a specific product (for testing)
    public func simulatePurchase(productId: String) async throws {
        try await subscriptionService.mockPurchase(productId)
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

public final class NoOpPaywallBusinessService: PaywallBusinessService {
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
    
    public func clearPurchases() async throws {
        // No-op implementation
    }
}

// MARK: - UI Service Layer Removed
//
// The PaywallUIService layer has been removed to maintain architectural consistency.
// UI state management now belongs in PaywallViewModel which directly uses PaywallBusinessService.
// This follows Clean Architecture: View → ViewModel → BusinessService → Repository

// MARK: - Legacy Mock PaywallService (Deprecated)

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

// MARK: - NoOp PaywallService (for minimal container)

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

// MARK: - StoreKit PaywallService (Stub for Future Implementation)

@MainActor @Observable
public final class StoreKitPaywallService: PaywallService {
    public var purchaseState: PurchaseState = .idle
    
    // StoreKit product identifiers - these should match App Store Connect configuration
    private let productIdentifiers = [
        "com.vladblajovan.ritualist.weekly",
        "com.vladblajovan.ritualist.monthly", 
        "com.vladblajovan.ritualist.annual",
        "com.vladblajovan.ritualist.lifetime"
    ]
    
    public init() {
        // TODO: Initialize StoreKit 2 transaction listener
        // Task { await startTransactionListener() }
    }
    
    public func loadProducts() async throws -> [Product] {
        // TODO: Replace with StoreKit 2 product loading
        /*
        import StoreKit
        
        do {
            let storeProducts = try await StoreKit.Product.products(for: productIdentifiers)
            return storeProducts.map { storeProduct in
                mapStoreKitProductToDomainProduct(storeProduct)
            }
        } catch {
            throw PaywallError.productsNotAvailable
        }
        */
        
        // Temporary stub - return empty until StoreKit integration
        throw PaywallError.productsNotAvailable
    }
    
    public func purchase(_ product: Product) async throws -> Bool {
        purchaseState = .purchasing(product.id)
        
        // TODO: Replace with StoreKit 2 purchase flow
        /*
        import StoreKit
        
        guard let storeProduct = await findStoreKitProduct(productId: product.id) else {
            purchaseState = .failed("Product not found")
            return false
        }
        
        do {
            let result = try await storeProduct.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                
                purchaseState = .success(product)
                return true
                
            case .userCancelled:
                purchaseState = .idle
                throw PaywallError.userCancelled
                
            case .pending:
                purchaseState = .idle
                throw PaywallError.purchaseFailed("Purchase is pending approval")
                
            @unknown default:
                purchaseState = .failed("Unknown purchase result")
                return false
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
            throw PaywallError.purchaseFailed(error.localizedDescription)
        }
        */
        
        // Temporary stub
        purchaseState = .failed("StoreKit integration not implemented")
        throw PaywallError.purchaseFailed("StoreKit integration not implemented")
    }
    
    public func restorePurchases() async throws -> Bool {
        purchaseState = .purchasing("restore")
        
        // TODO: Replace with StoreKit 2 restore flow
        /*
        import StoreKit
        
        do {
            try await AppStore.sync()
            
            var hasValidPurchases = false
            for await result in Transaction.currentEntitlements {
                let transaction = try checkVerified(result)
                
                if productIdentifiers.contains(transaction.productID) {
                    hasValidPurchases = true
                }
            }
            
            purchaseState = .idle
            return hasValidPurchases
        } catch {
            purchaseState = .failed("Failed to restore purchases")
            throw PaywallError.purchaseFailed("Failed to restore purchases: \(error.localizedDescription)")
        }
        */
        
        // Temporary stub
        purchaseState = .failed("StoreKit integration not implemented")
        throw PaywallError.purchaseFailed("StoreKit integration not implemented")
    }
    
    public func isProductPurchased(_ productId: String) async -> Bool {
        // TODO: Replace with StoreKit 2 entitlement checking
        /*
        import StoreKit
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productID == productId {
                    return true
                }
            } catch {
                // Invalid transaction, continue checking
                continue
            }
        }
        return false
        */
        
        // Temporary stub
        return false
    }
    
    public func resetPurchaseState() {
        purchaseState = .idle
    }
    
    public func clearPurchases() {
        // TODO: Handle subscription cancellation
        // For StoreKit, this might involve updating local state
        // The actual cancellation happens through App Store Connect
        purchaseState = .idle
    }
    
    // MARK: - Private StoreKit Helper Methods (Stubs)
    
    /*
    private func startTransactionListener() async {
        for await result in Transaction.updates {
            do {
                let transaction = try checkVerified(result)
                // Handle transaction updates
                await transaction.finish()
            } catch {
                // Handle verification failure
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PaywallError.purchaseFailed("Transaction verification failed")
        case .verified(let safe):
            return safe
        }
    }
    
    private func findStoreKitProduct(productId: String) async -> StoreKit.Product? {
        do {
            let products = try await StoreKit.Product.products(for: [productId])
            return products.first
        } catch {
            return nil
        }
    }
    
    private func mapStoreKitProductToDomainProduct(_ storeProduct: StoreKit.Product) -> Product {
        let subscriptionPlan: SubscriptionPlan
        let duration: ProductDuration
        
        // Map based on product identifier
        switch storeProduct.id {
        case "com.vladblajovan.ritualist.weekly":
            subscriptionPlan = .monthly // No weekly enum, use monthly
            duration = .monthly
        case "com.vladblajovan.ritualist.monthly":
            subscriptionPlan = .monthly
            duration = .monthly
        case "com.vladblajovan.ritualist.annual":
            subscriptionPlan = .annual
            duration = .annual
        default:
            subscriptionPlan = .monthly
            duration = .monthly
        }
        
        let features: [String]
        let isPopular: Bool
        let discount: String?
        
        // Configure features based on product
        switch storeProduct.id {
        case "com.vladblajovan.ritualist.weekly":
            features = ["Unlimited habits", "Basic analytics", "Custom reminders"]
            isPopular = false
            discount = nil
        case "com.vladblajovan.ritualist.monthly":
            features = ["Unlimited habits", "Advanced analytics", "Custom reminders", "Data export", "Priority support"]
            isPopular = false
            discount = nil
        case "com.vladblajovan.ritualist.annual":
            features = ["Unlimited habits", "Advanced analytics", "Custom reminders", "Data export", "Priority support", "Cloud sync", "Early access"]
            isPopular = true
            discount = "Save 58%"
        case "com.vladblajovan.ritualist.lifetime":
            features = ["Everything in Pro", "Lifetime updates", "No recurring charges", "Premium support forever"]
            isPopular = false
            discount = "Best Deal"
        default:
            features = ["Unlimited habits"]
            isPopular = false
            discount = nil
        }
        
        return Product(
            id: storeProduct.id,
            name: storeProduct.displayName,
            description: storeProduct.description,
            price: storeProduct.displayPrice,
            localizedPrice: storeProduct.displayPrice,
            subscriptionPlan: subscriptionPlan,
            duration: duration,
            features: features,
            isPopular: isPopular,
            discount: discount
        )
    }
    */
}

// MARK: - Simple PaywallService (nonisolated for previews)

@MainActor @Observable
public final class SimplePaywallService: PaywallService {
    public var purchaseState: PurchaseState = .idle
    
    public init() {}
    
    public func loadProducts() async throws -> [Product] {
        [
            Product(
                id: "premium_monthly",
                name: "Premium Monthly",
                description: "Premium features for one month",
                price: "$4.99",
                localizedPrice: "$4.99",
                subscriptionPlan: .monthly,
                duration: .monthly,
                features: ["Unlimited habits", "Advanced analytics", "Custom themes"],
                isPopular: false
            ),
            Product(
                id: "premium_annual", 
                name: "Premium Annual",
                description: "Premium features for one year",
                price: "$49.99",
                localizedPrice: "$49.99",
                subscriptionPlan: .annual,
                duration: .annual,
                features: ["Unlimited habits", "Advanced analytics", "Custom themes", "Priority support"],
                isPopular: true,
                discount: "Save 17%"
            )
        ]
    }
    
    public func purchase(_ product: Product) async throws -> Bool {
        purchaseState = .purchasing(product.id)
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        purchaseState = .success(product)
        return true
    }
    
    public func restorePurchases() async throws -> Bool {
        purchaseState = .purchasing("restore")
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        purchaseState = .idle
        return false
    }
    
    public func isProductPurchased(_ productId: String) async -> Bool {
        false
    }
    
    public func resetPurchaseState() {
        purchaseState = .idle
    }
    
    public func clearPurchases() {
        purchaseState = .idle
    }
}

